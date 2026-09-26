import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/alphabet.dart';
import 'models/conversation.dart';
import 'models/glyph.dart';
import 'models/message.dart';
import 'models/profile.dart';
import 'push/push_service.dart';
import 'repositories/alphabet_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/conversation_repository.dart';
import 'repositories/message_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/push_repository.dart';
import 'storage/storage_service.dart';

/// Everything that depends on being online/signed-in: auth, the current
/// user's cloud profile, conversations, and a small cache of *other*
/// users' alphabets (needed to render their messages with their own
/// handwriting). The local-only editor/keyboard/CustomText keep working
/// entirely off [AppState] and StorageService, untouched — this class
/// only adds the sync on top.
class SessionState extends ChangeNotifier {
  final SupabaseClient client;
  final AuthRepository auth;
  final ProfileRepository profiles;
  final RemoteAlphabetRepository alphabets;
  final ConversationRepository conversations;
  final MessageRepository messages;
  final PushRepository push;
  final StorageService _storage;

  Profile? myProfile;
  String? myAlphabetId;

  final Map<String, Alphabet> _otherAlphabets = {};
  final Map<String, StreamSubscription<Glyph>> _alphabetWatches = {};
  StreamSubscription<Glyph>? _myAlphabetWatch;

  StreamSubscription<AuthState>? _authSub;

  SessionState(this.client, this._storage)
      : auth = AuthRepository(client),
        profiles = ProfileRepository(client),
        alphabets = RemoteAlphabetRepository(client),
        conversations = ConversationRepository(client),
        messages = MessageRepository(client),
        push = PushRepository(client) {
    _authSub = auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _onSignedIn();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _onSignedOut();
      }
    });
    if (auth.currentUser != null) _onSignedIn();
  }

  bool get isSignedIn => auth.currentUser != null;

  Future<void> _onSignedIn() async {
    final user = auth.currentUser;
    if (user == null) return;
    try {
      // Independent reads — no reason to wait for the profile before
      // starting the alphabet lookup (was costing a needless extra
      // round trip on every sign-in / cold start).
      final results = await Future.wait([
        profiles.fetchProfile(user.id),
        alphabets.ensureAlphabetId(user.id),
      ]);
      myProfile = results[0] as Profile;
      myAlphabetId = results[1] as String;
    } catch (_) {
      // Offline or the profile row isn't there yet (trigger lag) — the
      // rest of the app still works from local data either way.
    }
    notifyListeners();
  }

  void _onSignedOut() {
    myProfile = null;
    myAlphabetId = null;
    _otherAlphabets.clear();
    for (final sub in _alphabetWatches.values) {
      sub.cancel();
    }
    _alphabetWatches.clear();
    _myAlphabetWatch?.cancel();
    _myAlphabetWatch = null;
    notifyListeners();
  }

  /// Keeps this device's own alphabet in sync with edits made on *another*
  /// device signed into the same account — without this, a letter redrawn
  /// on one phone never showed up on the other until the app was
  /// reinstalled/reloaded, since the alphabet is otherwise local-first.
  /// [onGlyph] should just write the glyph to local storage (e.g.
  /// `AppState.saveGlyph`), not push it back out — it already came from
  /// the network.
  Future<void> watchMyAlphabet(void Function(Glyph glyph) onGlyph) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _myAlphabetWatch?.cancel();
    myAlphabetId ??= await alphabets.ensureAlphabetId(user.id);
    _myAlphabetWatch = alphabets.watchGlyphs(myAlphabetId!).listen(onGlyph);
  }

  /// Pushes one saved glyph to the cloud. Called right after the editor
  /// saves it locally. Best-effort: failures (offline, etc.) are
  /// swallowed — the local copy is already safe, and the next successful
  /// save will push again.
  Future<void> pushGlyph(Glyph glyph) async {
    if (!isSignedIn) return;
    try {
      myAlphabetId ??= await alphabets.ensureAlphabetId(auth.currentUser!.id);
      await alphabets.pushGlyph(myAlphabetId!, glyph);
    } catch (_) {
      // Left for the next save to retry; see class doc.
    }
  }

  /// The alphabet to render a given sender's messages with. Cached, and
  /// kept live for the duration of the session so an edit the sender
  /// makes mid-conversation shows up without reopening the chat.
  Alphabet? cachedAlphabetFor(String userId) => _otherAlphabets[userId];

  Future<Alphabet> alphabetFor(String userId) async {
    final cached = _otherAlphabets[userId];
    if (cached != null) return cached;

    final fetched = await alphabets.fetchAlphabet(userId);
    _otherAlphabets[userId] = fetched;
    notifyListeners();
    _watchAlphabet(userId, fetched.id);
    return fetched;
  }

  void _watchAlphabet(String userId, String alphabetId) {
    if (_alphabetWatches.containsKey(userId)) return;
    _alphabetWatches[userId] = alphabets.watchGlyphs(alphabetId).listen((glyph) {
      final current = _otherAlphabets[userId];
      if (current == null) return;
      _otherAlphabets[userId] = current.withGlyph(glyph);
      notifyListeners();
    });
  }

  List<Message> loadCachedMessages(String conversationId) => _storage.loadCachedMessages(conversationId);

  Future<void> cacheMessages(String conversationId, List<Message> messages) =>
      _storage.cacheMessages(conversationId, messages);

  Future<List<Conversation>> loadConversations() {
    final user = auth.currentUser;
    if (user == null) return Future.value(const []);
    return conversations.listConversations(user.id);
  }

  Future<void> renameConversation(String conversationId, String nickname) {
    final user = auth.currentUser!;
    return conversations.renameConversation(
      conversationId: conversationId,
      currentUserId: user.id,
      nickname: nickname,
    );
  }

  Future<void> clearChat(String conversationId) async {
    await messages.clearMessages(conversationId);
    await _storage.cacheMessages(conversationId, const []);
  }

  Future<void> deleteConversation(String conversationId) => conversations.deleteConversation(conversationId);

  /// Asks for notification permission and, once granted, registers this
  /// browser for Web Push and saves the subscription server-side.
  /// Returns whether it ended up subscribed.
  Future<bool> enablePush(String vapidPublicKey) async {
    final user = auth.currentUser;
    if (user == null || vapidPublicKey.isEmpty) return false;
    final sub = await PushService.subscribe(vapidPublicKey);
    if (sub == null) return false;
    try {
      await push.saveSubscription(user.id, sub);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disablePush() async {
    final endpoint = await PushService.unsubscribe();
    if (endpoint == null) return;
    try {
      await push.removeSubscription(endpoint);
    } catch (_) {
      // Best-effort — a stale row here just means one wasted send-push
      // attempt later, which self-cleans on the first failed delivery.
    }
  }

  /// Renames the signed-in user's own profile (shown to everyone they
  /// chat with, unless a contact gave them a local nickname instead).
  Future<void> updateMyDisplayName(String displayName) async {
    final user = auth.currentUser;
    if (user == null) return;
    await profiles.updateDisplayName(user.id, displayName);
    myProfile = Profile(id: user.id, username: myProfile!.username, displayName: displayName, avatarUrl: myProfile!.avatarUrl);
    notifyListeners();
  }

  Future<void> updateMyAvatar(Uint8List bytes, {required String extension}) async {
    final user = auth.currentUser;
    if (user == null) return;
    final url = await profiles.uploadAvatar(user.id, bytes, extension: extension);
    myProfile = Profile(id: user.id, username: myProfile!.username, displayName: myProfile!.displayName, avatarUrl: url);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    for (final sub in _alphabetWatches.values) {
      sub.cancel();
    }
    _myAlphabetWatch?.cancel();
    super.dispose();
  }
}
