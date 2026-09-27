library supabase_config;

/// Supabase project credentials. The anon key is safe to ship in the client
/// by design (Supabase's security boundary is Row Level Security, not
/// secrecy of this key) — override at build time with
/// `--dart-define=SUPABASE_URL=...` / `--dart-define=SUPABASE_ANON_KEY=...`.
/// Never put the service-role key here — it must stay backend-only.
const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://zxutekojdyrdwddmexhs.supabase.co',
);

const String kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_ltTNF55jiBwoiFSA7OWN4w_zXjBRioA',
);
