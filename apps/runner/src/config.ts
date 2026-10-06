import { z } from 'zod';

const bool = z
  .string()
  .optional()
  .transform((v) => v === 'true' || v === '1');

const schema = z.object({
  PORT: z.coerce.number().int().default(8787),
  HOST: z.string().default('0.0.0.0'),
  LOG_LEVEL: z.string().default('info'),
  CORS_ORIGINS: z.string().default('*'),

  /** `docker` (production, one container per workspace) or `local` (dev). */
  WORKSPACE_DRIVER: z.enum(['docker', 'local']).default('local'),
  /** Host directory holding every workspace's files (bind-mounted in docker mode). */
  WORKSPACES_ROOT: z.string().default('./data/workspaces'),
  /** Where the JSON store lives when Supabase is not configured. */
  DATA_DIR: z.string().default('./data'),
  WORKSPACE_IMAGE: z.string().default('ember/workspace:latest'),
  WORKSPACE_CPU: z.coerce.number().default(2),
  WORKSPACE_RAM_MB: z.coerce.number().int().default(4096),
  WORKSPACE_IDLE_MINUTES: z.coerce.number().int().default(30),
  /** Flutter executable used by the local driver. */
  FLUTTER_BIN: z.string().default(process.platform === 'win32' ? 'flutter.bat' : 'flutter'),

  SUPABASE_URL: z.string().default(''),
  SUPABASE_SERVICE_ROLE_KEY: z.string().default(''),
  SUPABASE_JWT_SECRET: z.string().default(''),

  /** Enables POST /v1/auth/dev-login. Never enable in production. */
  DEV_AUTH: bool,
  DEV_JWT_SECRET: z.string().default('dev-only-secret-change-me-please-32b'),

  JOB_TIMEOUT_SECONDS: z.coerce.number().int().default(900),
  MAX_WS_FILE_BYTES: z.coerce.number().int().default(5 * 1024 * 1024),

  PREVIEW_BASE_DOMAIN: z.string().default(''),

  /** Remote JSON model catalog (falls back to bundled ai-catalog.json). */
  AI_CATALOG_URL: z.string().default(''),
  AI_RATE_LIMIT_PER_MINUTE: z.coerce.number().int().default(120),
  /** Allow http:// and private/loopback OpenAI-compatible base URLs (e.g. local Ollama). Dev only. */
  AI_ALLOW_PRIVATE_BASE_URLS: bool,

  /** Server-side Gemini key for the free home assistant (users need no key). */
  GEMINI_API_KEY: z.string().default(''),
  // Who publishes the apps: the start of every package name, and the owner in privacy policies.
  PACKAGE_PREFIX: z.string().regex(/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/).default('com.emberapps'),
  STUDIO_NAME: z.string().max(80).default(''),
  ASSISTANT_MODEL: z.string().default('gemini-2.5-flash'),
  ASSISTANT_DAILY_LIMIT: z.coerce.number().int().default(100),
  /** Gemini requests per user per day when building apps on the server key. */
  BUILDER_DAILY_LIMIT: z.coerce.number().int().default(200),

  /** Claude Code CLI engine for "Crea App" (local driver only). */
  CLAUDE_CODE_ENABLED: z
    .string()
    .optional()
    .transform((v) => v !== 'false' && v !== '0'),
  CLAUDE_BIN: z.string().default(''),
  KEYTOOL_BIN: z.string().default(''),
  CLAUDE_CODE_MAX_TURNS: z.coerce.number().int().default(150),
  CLAUDE_CODE_MODEL_FAST: z.string().default('sonnet'),
  CLAUDE_CODE_MODEL_BEST: z.string().default('opus'),
  VAULT_MASTER_KEY: z.string().default(''),

  /** Fake Factory operations (a few seconds each, no engine used), to try the interface with a hundred apps. */
  EMBER_FACTORY_SIMULATE: bool,
  /** How fast pretend Factory stages go: 1 is a few seconds each, 0.05 is twenty times quicker. */
  EMBER_FACTORY_SIM_SPEED: z.coerce.number().min(0.001).max(10).default(1),
});

export type Config = z.infer<typeof schema> & { supabaseEnabled: boolean };

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const parsed = schema.parse(env);
  const supabaseEnabled = parsed.SUPABASE_URL !== '' && parsed.SUPABASE_SERVICE_ROLE_KEY !== '';
  if (!supabaseEnabled && !parsed.DEV_AUTH) {
    throw new Error('Configure SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY, or set DEV_AUTH=true for local development.');
  }
  return { ...parsed, supabaseEnabled };
}
