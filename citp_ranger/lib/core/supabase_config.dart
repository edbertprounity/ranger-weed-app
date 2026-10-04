/// Shared demo database. Paste the project URL and anon key from Supabase,
/// or pass them at launch:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
class SupabaseConfig {
  static const pastedUrl = 'https://xzftqjhhedjmtodczxdf.supabase.co';
  static const pastedAnonKey = 'sb_publishable_kJJarbjsuY70DX7XnKTutQ_eQvOaMk7';

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: pastedUrl,
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: pastedAnonKey,
  );

  static bool get enabled => url.isNotEmpty && anonKey.isNotEmpty;
}
