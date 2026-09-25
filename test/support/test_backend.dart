import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:together/core/session_state.dart';
import 'package:together/core/storage/storage_service.dart';

/// A signed-out [SessionState] for widget tests that need a BackendScope
/// ancestor (e.g. anything reaching the editor, which best-effort pushes
/// saved glyphs to the cloud) but aren't testing auth/network themselves.
/// No real network call happens: constructing a bare [SupabaseClient]
/// does not contact the server, and every SessionState method that talks
/// to Supabase is only reached when signed in.
SessionState buildTestSession(StorageService storage) {
  final client = SupabaseClient(
    'https://test.supabase.co',
    'test-anon-key',
    // No real auth ever happens in these tests; disabling auto-refresh
    // avoids leaving a periodic timer running past the test's lifetime.
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  return SessionState(client, storage);
}
