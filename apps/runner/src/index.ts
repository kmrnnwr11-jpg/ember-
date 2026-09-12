import { buildApp } from './app.js';
import { loadConfig } from './config.js';

const cfg = loadConfig();
const { app } = await buildApp(cfg);

const shutdown = async (signal: string) => {
  app.log.info({ signal }, 'shutting down');
  await app.close();
  process.exit(0);
};
process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));

await app.listen({ port: cfg.PORT, host: cfg.HOST });
app.log.info({ driver: cfg.WORKSPACE_DRIVER, supabase: cfg.supabaseEnabled, devAuth: cfg.DEV_AUTH }, 'runner ready');
