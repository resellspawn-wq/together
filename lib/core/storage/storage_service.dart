import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alphabet.dart';
import '../models/app_settings.dart';
import '../models/message.dart';
import '../models/user_profile.dart';

/// Everything the app persists lives locally on the device, via
/// shared_preferences (backed by localStorage in the web/PWA build). The
/// user's own alphabet and settings are fully local-first by design: the
/// MVP must work offline. Conversations/messages are cached here too,
/// purely as a "last known state" fallback for when a conversation is
/// opened without a network connection — the source of truth for those is
/// Supabase (see SessionState / repositories).
///
/// Alphabet/settings/user keys are namespaced by the signed-in user's id
/// (see [useNamespace]) so two different accounts opened on the same
/// browser/device never see each other's local data — each gets its own
/// slot in shared_preferences.
class StorageService {
  static const _kAlphabetKey = 'together.alphabet.v1';
  static const _kSettingsKey = 'together.settings.v1';
  static const _kUserKey = 'together.user.v1';
  static const _kMessagesCachePrefix = 'together.messages_cache.v1.';

  final SharedPreferences _prefs;
  String? _namespace;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  /// Switches which account's local data subsequent reads/writes use.
  /// Call this whenever the signed-in user changes (login, logout,
  /// switching accounts on the same device). `null` is the "nobody signed
  /// in yet" slot.
  void useNamespace(String? userId) {
    _namespace = userId;
  }

  String _key(String base) => _namespace == null ? base : '$base.$_namespace';

  Future<void> saveAlphabet(Alphabet alphabet) async {
    await _prefs.setString(_key(_kAlphabetKey), jsonEncode(alphabet.toJson()));
  }

  Alphabet loadAlphabet() {
    final raw = _prefs.getString(_key(_kAlphabetKey));
    if (raw == null) return Alphabet.blank();
    try {
      return Alphabet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return Alphabet.blank();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_key(_kSettingsKey), jsonEncode(settings.toJson()));
  }

  AppSettings loadSettings() {
    final raw = _prefs.getString(_key(_kSettingsKey));
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveUser(UserProfile user) async {
    await _prefs.setString(_key(_kUserKey), jsonEncode(user.toJson()));
  }

  UserProfile loadUser() {
    final raw = _prefs.getString(_key(_kUserKey));
    if (raw == null) return UserProfile.local();
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProfile.local();
    }
  }

  Future<void> cacheMessages(String conversationId, List<Message> messages) async {
    await _prefs.setString(
      _key(_kMessagesCachePrefix + conversationId),
      jsonEncode(messages.map((m) => m.toCacheJson()).toList()),
    );
  }

  List<Message> loadCachedMessages(String conversationId) {
    final raw = _prefs.getString(_key(_kMessagesCachePrefix + conversationId));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((m) => Message.fromCacheJson((m as Map).cast<String, dynamic>())).toList();
    } catch (_) {
      return [];
    }
  }
}
