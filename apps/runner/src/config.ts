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
  WORKSPACE_IMAGE: z.string().default('fluttercursor/workspace:latest'),
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
  VAULT_MASTER_KEY: z.string().default(''),
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
