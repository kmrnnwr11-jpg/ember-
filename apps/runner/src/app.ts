import Fastify, { type FastifyInstance, type FastifyRequest } from 'fastify';
import { cliLogins, cliModels } from './subscription_clis.js';
import { mkdir, stat } from 'node:fs/promises';
import path from 'node:path';
import cors from '@fastify/cors';
import fastifyStatic from '@fastify/static';
import websocket from '@fastify/websocket';
import { PathError, safeResolve } from './paths.js';
import { PreviewService } from './preview.js';
import { DEFAULT_UPSTREAMS, registerAiRoutes } from './ai.js';
import { registerResearchRoutes } from './research.js';
import { ClaudeCodeEngine, detectClis } from './agent_cli.js';
import { z } from 'zod';
import { Authenticator, bearer, type AuthUser } from './auth.js';
import type { Config } from './config.js';
import { errorPayload, httpStatus } from './errors.js';
import { WatchHub } from './fs.js';
import { JobManager, jobPublic } from './jobs.js';
import { ARTIFACTS, Services, TEMPLATES, type SignedBuildPreparer } from './services.js';
import { androidAppInfo, ensureUploadKey } from './signing.js';
import { parseServiceAccount, PlayError, privacyHtml, publishToPlay } from './play.js';
import { readFile as readFileAsync, writeFile as writeFileAsync, mkdir as mkdirAsync } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
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
  aiUpstreams?: Partial<typeof DEFAULT_UPSTREAMS>;
  claudeCode?: ClaudeCodeEngine;
  prepareSigned?: SignedBuildPreparer;
  ensureKey?: typeof ensureUploadKey;
  androidInfo?: typeof androidAppInfo;
  playFetch?: typeof fetch;
}

export async function buildApp(
  cfg: Config,
  deps: AppDeps = {},
): Promise<{ app: FastifyInstance; services: Services; preview: PreviewService }> {
  const app = Fastify({
    logger: {
      level: cfg.LOG_LEVEL,
      // Never log credentials (§4).
      redact: ['req.headers.authorization', 'req.query.token', 'req.headers["x-provider-key"]', 'req.headers["x-provider-base-url"]', 'req.body.serviceAccount'],
    },
    bodyLimit: cfg.MAX_WS_FILE_BYTES + 1024 * 64,
    // preview.<domain>/<ws>/<project>/… is served by the /preview route.
    rewriteUrl: (req) => {
      const host = (req.headers.host ?? '').toLowerCase();
      const url = req.url ?? '/';
      return cfg.PREVIEW_BASE_DOMAIN && host.startsWith(`preview.${cfg.PREVIEW_BASE_DOMAIN}`) ? `/preview${url}` : url;
    },
  });
  const store = deps.store ?? (cfg.supabaseEnabled ? new SupabaseStore(cfg) : new JsonStore(cfg.DATA_DIR));
  const driver = deps.driver ?? (cfg.WORKSPACE_DRIVER === 'docker' ? new DockerDriver(cfg) : new LocalDriver(cfg));
  const jobs = new JobManager(driver, cfg.JOB_TIMEOUT_SECONDS);
  const services = new Services(cfg, store, driver, jobs, deps.prepareSigned);
  const ensureKey = deps.ensureKey ?? ensureUploadKey;
  const keyLinks = new Map<string, { keystorePath: string; fileName: string; expires: number }>();
  const auth = new Authenticator(cfg);
  const hub = new WatchHub();
  const preview = new PreviewService(cfg, services, hub);
  const claudeCode = deps.claudeCode ?? new ClaudeCodeEngine(cfg);

  await app.register(cors, {
    origin: cfg.CORS_ORIGINS === '*' ? true : cfg.CORS_ORIGINS.split(',').map((s) => s.trim()),
  });
  await app.register(websocket, { options: { maxPayload: cfg.MAX_WS_FILE_BYTES + 1024 * 64 } });
  await mkdir(path.resolve(cfg.WORKSPACES_ROOT), { recursive: true });
  await app.register(fastifyStatic, { root: path.resolve(cfg.WORKSPACES_ROOT), serve: false, cacheControl: false });

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
    preview.stopAll();
    claudeCode.cancelAll();
    await hub.closeAll();
  });

  app.get('/signing-download/:token', async (req, reply) => {
    const { token } = req.params as { token: string };
    const link = keyLinks.get(token);
    keyLinks.delete(token);
    if (!link || link.expires < Date.now()) return reply.status(404).send({ code: 'not_found', message: 'link expired' });
    reply.header('Content-Type', 'application/octet-stream');
    reply.header('Content-Disposition', `attachment; filename="${link.fileName}"`);
    reply.header('Cache-Control', 'no-store');
    return reply.sendFile(path.basename(link.keystorePath), path.dirname(link.keystorePath), { contentType: false });
  });

  // Public privacy policy page (the URL required by Google Play).
  app.get('/privacy/:workspaceId/:projectId', async (req, reply) => {
    const { workspaceId, projectId } = req.params as { workspaceId: string; projectId: string };
    const project = await store.getProject(projectId);
    if (!project || project.workspaceId !== workspaceId) return reply.status(404).type('text/html').send('<h1>Not found</h1>');
    const raw = await readFileAsync(path.join(services.projectRoot(project), 'store', 'privacy_policy.md'), 'utf8').catch(() => null);
    if (!raw) return reply.status(404).type('text/html').send('<h1>Privacy policy not published yet</h1>');
    const appName = /^<!-- (.*) -->/.exec(raw)?.[1] ?? project.name;
    reply.header('Cache-Control', 'public, max-age=300');
    return reply.type('text/html; charset=utf-8').send(privacyHtml(`Privacy Policy – ${appName}`, raw.replace(/^<!-- .* -->\n/, '')));
  });

  // ---------------- Android artifacts (same capability-link model as preview) ----------------

  app.get('/artifacts/:workspaceId/:projectId/:file', async (req, reply) => {
    const { workspaceId, projectId, file } = req.params as { workspaceId: string; projectId: string; file: string };
    const artifact = ARTIFACTS[file];
    const project = await store.getProject(projectId);
    if (!artifact || !project || project.workspaceId !== workspaceId) return reply.status(404).send({ code: 'not_found', message: 'artifact not found' });
    const root = services.projectRoot(project);
    const st = await stat(path.join(root, artifact.rel)).catch(() => null);
    if (!st) return reply.status(404).send({ code: 'not_found', message: 'not built yet' });
    reply.header('Content-Type', artifact.contentType);
    reply.header('Content-Disposition', `attachment; filename="${project.name}-${file.replace('app-', '')}"`);
    reply.header('Cache-Control', 'no-cache');
    return reply.sendFile(artifact.rel, root, { contentType: false });
  });

  // ---------------- preview (public by unguessable ids, §2) ----------------

  app.get('/preview/:workspaceId/:projectId', async (req, reply) => {
    return reply.redirect(`${req.url.split('?')[0]}/`, 301);
  });

  app.get('/preview/:workspaceId/:projectId/*', async (req, reply) => {
    const { workspaceId, projectId, '*': rest } = req.params as { workspaceId: string; projectId: string; '*': string };
    const project = await store.getProject(projectId);
    if (!project || project.workspaceId !== workspaceId) {
      return reply.status(404).type('text/html').send(previewPlaceholder('Preview not found'));
    }
    const root = preview.webRoot(project);
    let rel = rest || 'index.html';
    let abs: string;
    try {
      abs = safeResolve(root, rel);
    } catch (e) {
      if (e instanceof PathError) return reply.status(400).send({ code: e.code, message: e.message });
      throw e;
    }
    let st = await stat(abs).catch(() => null);
    if (!st || st.isDirectory()) {
      // SPA fallback for client-side routes without a file extension.
      if (path.extname(rel) !== '' && st === null) return reply.status(404).send();
      rel = 'index.html';
      abs = path.join(root, rel);
      st = await stat(abs).catch(() => null);
      if (!st) {
        const building = jobs.findActive((j) => j.projectId === project.id && j.kind === 'build_web');
        return reply
          .status(building ? 202 : 404)
          .header('Refresh', building ? '3' : '')
          .type('text/html')
          .send(previewPlaceholder(building ? 'Building… this page refreshes automatically.' : 'Not built yet. Press Run Web in FlutterCursor.'));
      }
    }
    const noCache = /(^|\/)(index\.html|flutter_bootstrap\.js|flutter_service_worker\.js|version\.json|manifest\.json)$/.test(rel);
    reply.header('Cache-Control', noCache ? 'no-cache, no-store, must-revalidate' : 'public, max-age=300');
    reply.header('X-Robots-Tag', 'noindex');
    return reply.sendFile(rel, root);
  });

  // ---------------- public ----------------

  app.get('/v1/health', async () => ({
    ok: true,
    driver: driver.kind,
    store: cfg.supabaseEnabled ? 'supabase' : 'json',
    devAuth: cfg.DEV_AUTH,
    version: '0.2.0',
    engines: { claudeCode: await claudeCode.isAvailable(), ...(driver.kind === 'local' ? await cliLogins().then((l) => ({ codex: l.codex, geminiCli: l['gemini-cli'] })) : { codex: false, geminiCli: false }), assistant: cfg.GEMINI_API_KEY !== '', serverGemini: cfg.GEMINI_API_KEY !== '' },
    // AI CLIs usable from the integrated terminal (local driver: host PATH).
    cli: driver.kind === 'local' ? await detectClis() : {},
    cliModels: driver.kind === 'local' ? cliModels() : {},
    shells: process.platform === 'win32' ? ['cmd', 'powershell'] : ['bash'],
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

    // Upload-key backup: returns alias + password and a one-time, 10-minute download link.
    r.post('/v1/projects/:projectId/signing/link', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const key = await ensureKey(cfg, project.id, project.name);
      const token = randomBytes(24).toString('base64url');
      const expires = Date.now() + 10 * 60_000;
      for (const [t, v] of keyLinks) if (v.expires < Date.now()) keyLinks.delete(t);
      keyLinks.set(token, { keystorePath: key.keystorePath, fileName: `${project.name}-upload-keystore.jks`, expires });
      return { path: `/signing-download/${token}`, alias: key.alias, password: key.storePassword, expiresAt: new Date(expires).toISOString() };
    });

    // Publish the signed AAB to Google Play with the user's service account (not stored).
    r.post('/v1/projects/:projectId/play/publish', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const body = z
        .object({
          serviceAccount: z.string().min(50).max(20000),
          track: z.enum(['internal', 'alpha', 'beta', 'production']).default('internal'),
          status: z.enum(['draft', 'completed']).default('completed'),
          listing: z
            .object({
              language: z.string().default('it-IT'),
              title: z.string().max(30).optional(),
              shortDescription: z.string().max(80).optional(),
              fullDescription: z.string().max(4000).optional(),
            })
            .optional(),
          releaseNotes: z.object({ language: z.string().default('it-IT'), text: z.string().max(500) }).optional(),
          contactEmail: z.string().email().optional(),
        })
        .parse(req.body);
      const root = services.projectRoot(project);
      const aabPath = path.join(root, ARTIFACTS['app-release.aab']!.rel);
      if (!(await stat(aabPath).catch(() => null))) {
        return reply.status(409).send({ code: 'not_ready', message: 'Generate the signed AAB first' });
      }
      const info = await (deps.androidInfo ?? androidAppInfo)(cfg, project.id, root, project.name);
      if (!info.applicationId) return reply.status(409).send({ code: 'not_ready', message: 'Android package name not found' });
      try {
        const result = await publishToPlay(
          {
            serviceAccount: parseServiceAccount(body.serviceAccount),
            packageName: info.applicationId,
            aabPath,
            track: body.track,
            status: body.status,
            listing: body.listing,
            releaseNotes: body.releaseNotes,
            contactEmail: body.contactEmail,
          },
          deps.playFetch ?? fetch,
        );
        return { ...result, packageName: info.applicationId };
      } catch (e) {
        if (e instanceof PlayError) {
          return reply.status(e.code === 'bad_request' ? 400 : e.status && e.status < 500 ? 422 : 502).send({ code: e.code, message: e.message });
        }
        throw e;
      }
    });

    // Save the AI-written privacy policy; served publicly at /privacy/<ws>/<project>.
    r.put('/v1/projects/:projectId/store/privacy', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const { markdown, appName } = z.object({ markdown: z.string().min(50).max(60000), appName: z.string().max(80).optional() }).parse(req.body);
      const dir = path.join(services.projectRoot(project), 'store');
      await mkdirAsync(dir, { recursive: true });
      await writeFileAsync(path.join(dir, 'privacy_policy.md'), `<!-- ${appName ?? project.name} -->\n${markdown}`);
      return { path: `/privacy/${project.workspaceId}/${project.id}` };
    });

    r.get('/v1/projects/:projectId/android-info', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      return (deps.androidInfo ?? androidAppInfo)(cfg, project.id, services.projectRoot(project), project.name);
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

  // ---------------- AI (§5B) ----------------

  await registerAiRoutes(app, { cfg, authenticate, upstreams: deps.aiUpstreams });
  await registerResearchRoutes(app, { authenticate, fetchImpl: deps.playFetch });

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
    new Session(socket, user, services, hub, preview, claudeCode, req.log);
  });

  return { app, services, preview };
}

function previewPlaceholder(message: string): string {
  const safe = message.replace(/[<>&]/g, (c) => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;' })[c]!);
  return `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>FlutterCursor preview</title><body style="font-family:system-ui;display:grid;place-items:center;height:100vh;margin:0;background:#111;color:#ddd"><p>${safe}</p></body>`;
}

function publicWorkspace(w: { id: string; name: string; status: string; createdAt: string }) {
  return { id: w.id, name: w.name, status: w.status, createdAt: w.createdAt };
}
