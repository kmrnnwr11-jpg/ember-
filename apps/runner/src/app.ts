import Fastify, { type FastifyInstance, type FastifyRequest } from 'fastify';
import cors from '@fastify/cors';
import websocket from '@fastify/websocket';
import { z } from 'zod';
import { Authenticator, bearer, type AuthUser } from './auth.js';
import type { Config } from './config.js';
import { errorPayload, httpStatus } from './errors.js';
import { WatchHub } from './fs.js';
import { JobManager, jobPublic } from './jobs.js';
import { Services, TEMPLATES } from './services.js';
import { JsonStore, SupabaseStore, type Store } from './store.js';
import { DockerDriver } from './workspaces/docker.js';
import type { WorkspaceDriver } from './workspaces/driver.js';
import { LocalDriver } from './workspaces/local.js';
import { Session } from './ws.js';

declare module 'fastify' {
  interface FastifyRequest {
    user: AuthUser;
  }
}

export interface AppDeps {
  store?: Store;
  driver?: WorkspaceDriver;
}

export async function buildApp(cfg: Config, deps: AppDeps = {}): Promise<{ app: FastifyInstance; services: Services }> {
  const app = Fastify({
    logger: {
      level: cfg.LOG_LEVEL,
      // Never log credentials (§4).
      redact: ['req.headers.authorization', 'req.query.token', 'req.headers["x-provider-key"]'],
    },
    bodyLimit: cfg.MAX_WS_FILE_BYTES + 1024 * 64,
  });
  const store = deps.store ?? (cfg.supabaseEnabled ? new SupabaseStore(cfg) : new JsonStore(cfg.DATA_DIR));
  const driver = deps.driver ?? (cfg.WORKSPACE_DRIVER === 'docker' ? new DockerDriver(cfg) : new LocalDriver(cfg));
  const jobs = new JobManager(driver, cfg.JOB_TIMEOUT_SECONDS);
  const services = new Services(cfg, store, driver, jobs);
  const auth = new Authenticator(cfg);
  const hub = new WatchHub();

  await app.register(cors, {
    origin: cfg.CORS_ORIGINS === '*' ? true : cfg.CORS_ORIGINS.split(',').map((s) => s.trim()),
  });
  await app.register(websocket, { options: { maxPayload: cfg.MAX_WS_FILE_BYTES + 1024 * 64 } });

  app.decorateRequest('user', null as unknown as AuthUser);

  app.setErrorHandler((err, req, reply) => {
    if (err instanceof z.ZodError) {
      return reply.status(400).send({ code: 'bad_request', message: err.issues.map((i) => i.message).join('; ') });
    }
    const fastifyStatus = (err as { statusCode?: number }).statusCode;
    if (fastifyStatus && fastifyStatus < 500 && !(err as { code?: string }).code?.match(/^[a-z_]+$/)) {
      return reply.status(fastifyStatus).send({ code: 'bad_request', message: (err as Error).message });
    }
    const payload = errorPayload(err);
    if (payload.code === 'internal') req.log.error({ err }, 'request failed');
    return reply.status(httpStatus(payload.code)).send(payload);
  });

  const authenticate = async (req: FastifyRequest) => {
    req.user = await auth.verify(bearer(req.headers.authorization));
  };

  app.addHook('onClose', async () => {
    await hub.closeAll();
  });

  // ---------------- public ----------------

  app.get('/v1/health', async () => ({
    ok: true,
    driver: driver.kind,
    store: cfg.supabaseEnabled ? 'supabase' : 'json',
    devAuth: cfg.DEV_AUTH,
    version: '0.1.0',
  }));

  app.post('/v1/auth/dev-login', async (req, reply) => {
    if (!cfg.DEV_AUTH) return reply.status(404).send({ code: 'not_found', message: 'dev auth disabled' });
    const { email } = z.object({ email: z.string().email() }).parse(req.body);
    return auth.issueDevToken(email);
  });

  // ---------------- authenticated REST ----------------

  await app.register(async (r) => {
    r.addHook('preHandler', authenticate);

    r.get('/v1/me', async (req) => req.user);

    r.get('/v1/templates', async () => ({ templates: TEMPLATES }));

    r.get('/v1/workspaces', async (req) => ({ workspaces: (await services.listWorkspaces(req.user.id)).map(publicWorkspace) }));

    r.post('/v1/workspaces', async (req, reply) => {
      const { name } = z.object({ name: z.string().max(64).default('default') }).parse(req.body ?? {});
      const ws = await services.createWorkspace(req.user.id, name);
      return reply.status(201).send(publicWorkspace(ws));
    });

    r.get('/v1/workspaces/:workspaceId/projects', async (req) => {
      const { workspaceId } = req.params as { workspaceId: string };
      return { projects: await services.listProjects(req.user.id, workspaceId) };
    });

    r.post('/v1/workspaces/:workspaceId/projects', async (req, reply) => {
      const { workspaceId } = req.params as { workspaceId: string };
      const body = z.object({ name: z.string(), template: z.string().default('empty') }).parse(req.body);
      const { project, job } = await services.createProject(req.user.id, workspaceId, body.name, body.template);
      return reply.status(202).send({ project, job: jobPublic(job) });
    });

    r.get('/v1/projects/:projectId', async (req) => {
      const { projectId } = req.params as { projectId: string };
      return (await services.ownedProject(req.user.id, projectId)).project;
    });

    r.delete('/v1/projects/:projectId', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      await services.deleteProject(req.user.id, projectId);
      return reply.status(204).send();
    });

    r.get('/v1/jobs/:jobId', async (req) => {
      const { jobId } = req.params as { jobId: string };
      const job = services.ownedJob(req.user.id, jobId);
      return { ...jobPublic(job), log: job.log.join(''), createdAt: job.createdAt, finishedAt: job.finishedAt };
    });

    r.post('/v1/jobs/:jobId/cancel', async (req) => {
      const { jobId } = req.params as { jobId: string };
      const job = services.ownedJob(req.user.id, jobId);
      return { cancelled: jobs.cancel(job.id) };
    });
  });

  // ---------------- WebSocket ----------------

  app.get('/v1/ws', { websocket: true }, async (socket, req) => {
    const token = (req.query as { token?: string }).token ?? bearer(req.headers.authorization);
    let user: AuthUser;
    try {
      user = await auth.verify(token);
    } catch {
      socket.close(4401, 'unauthorized');
      return;
    }
    new Session(socket, user, services, hub, req.log);
  });

  return { app, services };
}

function publicWorkspace(w: { id: string; name: string; status: string; createdAt: string }) {
  return { id: w.id, name: w.name, status: w.status, createdAt: w.createdAt };
}
