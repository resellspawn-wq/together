import 'dart:typed_data';

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

  Future<void> updateDisplayName(String userId, String displayName) async {
    await _client.from('profiles').update({'display_name': displayName}).eq('id', userId);
  }

  /// Uploads a new avatar image and saves its public URL on the profile.
  /// Always stored at the same path per user (upsert) so old images don't
  /// pile up in the bucket. Returns the public URL.
  Future<String> uploadAvatar(String userId, Uint8List bytes, {required String extension}) async {
    final path = '$userId/avatar.$extension';
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    // Cache-bust so the new image shows immediately even though the path
    // (and therefore the previously-cached URL) never changes.
    final url = '${_client.storage.from('avatars').getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}';
    await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
    return url;
  }
}
