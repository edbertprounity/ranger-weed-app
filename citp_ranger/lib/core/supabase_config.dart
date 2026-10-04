/// Shared demo database. The URL and publishable key are supplied at build time:
/// `flutter run --dart-define-from-file=dart_defines.json`
/// or `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
/// Copy `dart_defines.example.json` to `dart_defines.json` and fill it in locally.
/// That file stays out of the repository.
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get enabled => url.isNotEmpty && anonKey.isNotEmpty;
}
