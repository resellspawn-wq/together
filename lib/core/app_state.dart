import 'package:flutter/foundation.dart';

import 'models/alphabet.dart';
import 'models/app_settings.dart';
import 'models/glyph.dart';
import 'models/user_profile.dart';
import 'storage/storage_service.dart';

/// Single source of truth for everything local: the user's own alphabet,
/// app settings, and the local user record. Every screen that shows a
/// glyph (editor, keyboard, preview, chat) reads from the same
/// [alphabet] instance held here, so saving a redrawn letter updates all
/// of them at once — there is no separate copy of glyph data anywhere
/// else. Online concerns (auth, conversations, other users' alphabets)
/// live in SessionState instead — this class works the same whether or
/// not the user is signed in.
class AppState extends ChangeNotifier {
  final StorageService _storage;

  late Alphabet alphabet;
  late AppSettings settings;
  late UserProfile user;

  AppState(this._storage) {
    _load();
  }

  void _load() {
    alphabet = _storage.loadAlphabet();
    settings = _storage.loadSettings();
    user = _storage.loadUser();
  }

  /// Re-reads local data from storage. Called after [StorageService.useNamespace]
  /// switches to a different signed-in user, so this device's data for
  /// *that* account (not whoever was using it before) is what the rest of
  /// the app sees.
  void reload() {
    _load();
    notifyListeners();
  }

  Future<void> saveGlyph(Glyph glyph) async {
    alphabet = alphabet.withGlyph(glyph);
    notifyListeners();
    await _storage.saveAlphabet(alphabet);
  }

  Future<void> updateSettings(AppSettings Function(AppSettings) update) async {
    settings = update(settings);
    notifyListeners();
    await _storage.saveSettings(settings);
  }

  Future<void> completeOnboarding() async {
    await updateSettings((s) => s.copyWith(onboardingComplete: true));
  }
}
