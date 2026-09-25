import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth (email + password for this MVP).
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<bool> isUsernameAvailable(String username) async {
    final rows = await _client.from('profiles').select('id').eq('username', username).limit(1);
    return rows.isEmpty;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'display_name': displayName},
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();
}
