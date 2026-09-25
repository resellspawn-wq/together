/// Supabase project credentials, read at build/run time via
/// `--dart-define-from-file=supabase.env.json` (see
/// supabase.env.example.json in the project root). Never hard-code real
/// values here — the anon key is safe to ship in a client app (it only
/// grants what Row Level Security allows), but it still belongs in
/// per-developer config, not source control.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
