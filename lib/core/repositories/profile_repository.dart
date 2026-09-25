import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<Profile> fetchProfile(String userId) async {
    final row = await _client.from('profiles').select().eq('id', userId).single();
    return Profile.fromRow(row);
  }

  /// Looks up a profile by exact @username (case-insensitive). Returns
  /// null if nobody has that username.
  Future<Profile?> findByUsername(String username) async {
    final rows = await _client
        .from('profiles')
        .select()
        .ilike('username', username)
        .limit(1);
    if (rows.isEmpty) return null;
    return Profile.fromRow(rows.first);
  }
}
