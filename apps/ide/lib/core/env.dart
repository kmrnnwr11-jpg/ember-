/// Build-time configuration (§5F): pass with `--dart-define`.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const runnerUrl = String.fromEnvironment(
    'RUNNER_URL',
    defaultValue: 'http://localhost:8787',
  );

  static bool get supabaseEnabled =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
