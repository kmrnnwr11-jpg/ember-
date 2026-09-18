import Fastify, { type FastifyInstance, type FastifyRequest } from 'fastify';
import { syncProducts } from './play_products.js';
import { appContentAnswers } from './app_content.js';
import { backupKey } from './drive.js';
import { installAndRun, listDevices } from './devices.js';
import { fix as fixFinding, inspectCloud, inspectProject, inspectRunning } from './doctor.js';
import { GitHubError, saveToGitHub } from './github.js';
import { fillAppContent } from './play_console.js';
import { detectDataFacts, fillCsv, findExportedCsv, uploadDataSafety, validateFilledCsv } from './data_safety.js';
import { createServiceAccountKey, gcloudStatus, invitePlayUser, storeImages } from './play_setup.js';
import { cliLogins, cliModels } from './subscription_clis.js';
import { mkdir, stat } from 'node:fs/promises';
import path from 'node:path';
import cors from '@fastify/cors';
import fastifyStatic from '@fastify/static';
import websocket from '@fastify/websocket';
import { PathError, safeResolve } from './paths.js';
import { PreviewService } from './preview.js';
import { DEFAULT_UPSTREAMS, GEMINI_FALLBACKS, registerAiRoutes } from './ai.js';
import { applyLogo, generateLogos, storeState } from './logos.js';
import { captureScreenshots, findBrowser, hasScreenshotMode, SCREENSHOT_UPGRADE_REQUEST } from './screenshots.js';
import { registerResearchRoutes } from './research.js';
import { ClaudeCodeEngine, detectClis } from './agent_cli.js';
import { z } from 'zod';
import { Authenticator, bearer, type AuthUser } from './auth.js';
import type { Config } from './config.js';
import { errorPayload, httpStatus } from './errors.js';
import { WatchHub } from './fs.js';
import { JobManager, jobPublic } from './jobs.js';
import { ARTIFACTS, Services, TEMPLATES, type SignedBuildPreparer } from './services.js';
import { androidAppInfo, ensureUploadKey, rememberPublishedVersionCode } from './signing.js';
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

/**
 * What to call an app, in the order a person would: the name on the store, the
 * name on the phone's home screen, the name the app calls itself in its own
 * config. Only when all three are missing does the folder name show through.
 */
async function storeTitle(projectRoot: string): Promise<{ title?: string }> {
  const read = (...rel: string[]) => readFileAsync(path.join(projectRoot, ...rel), 'utf8').catch(() => '');

  const listing = await read('store', 'listing.json');
  const fromListing = `${(JSON.parse(listing || 'null') as { title?: string } | null)?.title ?? ''}`.trim();
  if (fromListing) return { title: fromListing };

  const manifest = await read('android', 'app', 'src', 'main', 'AndroidManifest.xml');
  const label = /android:label\s*=\s*"([^"@]{2,60})"/.exec(manifest)?.[1]?.trim();
  if (label) return { title: label };

  const config = await read('lib', 'config', 'app_config.dart');
  const appName = /static const String appName\s*=\s*'([^']{2,60})'/.exec(config)?.[1]?.trim();
  return appName ? { title: appName } : {};
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
  backupKey?: typeof backupKey;
  saveToGitHub?: typeof saveToGitHub;
  fillAppContent?: typeof fillAppContent;
}

export async function buildApp(
  cfg: Config,
  deps: AppDeps = {},
): Promise<{ app: FastifyInstance; services: Services; preview: PreviewService }> {
  const app = Fastify({
    logger: {
      level: cfg.LOG_LEVEL,
      // Never log credentials (Ãƒâ€šÃ‚Â§4).
      redact: ['req.headers.authorization', 'req.query.token', 'req.headers["x-provider-key"]', 'req.headers["x-provider-base-url"]', 'req.body.serviceAccount'],
    },
    bodyLimit: cfg.MAX_WS_FILE_BYTES + 1024 * 64,
    // preview.<domain>/<ws>/<project>/ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ is served by the /preview route.
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

  /**
   * What the browser helper needs to know about the app being published.
   * Ember puts it here with one button; the extension reads it from the Play
   * Console tab. Only the facts that decide the answers, and only for a browser
   * extension: a web page cannot read this response.
   */
  let helperApp: Record<string, unknown> | null = null;

  app.get('/helper/app', async (req, reply) => {
    const origin = req.headers.origin ?? '';
    if (origin.startsWith('chrome-extension://')) reply.header('access-control-allow-origin', origin);
    reply.header('cache-control', 'no-store');
    if (!helperApp) return reply.status(404).send({ code: 'no_app', message: 'Open the app in Ember and press "Copy for the browser helper"' });
    return helperApp;
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
    return reply.type('text/html; charset=utf-8').send(privacyHtml(`Privacy Policy ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ ${appName}`, raw.replace(/^<!-- .* -->\n/, '')));
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

  // ---------------- preview (public by unguessable ids, Ãƒâ€šÃ‚Â§2) ----------------

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
          .send(previewPlaceholder(building ? 'BuildingÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ this page refreshes automatically.' : 'Not built yet. Press Run Web in FlutterCursor.'));
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
      const projects = await services.listProjects(req.user.id, workspaceId);
      return {
        projects: await Promise.all(projects.map(async (project) => ({ ...project, ...(await storeTitle(services.projectRoot(project))) }))),
      };
    });

    r.post('/v1/workspaces/:workspaceId/projects', async (req, reply) => {
      const { workspaceId } = req.params as { workspaceId: string };
      const body = z.object({ name: z.string(), template: z.string().default('empty') }).parse(req.body);
      const { project, job } = await services.createProject(req.user.id, workspaceId, body.name, body.template);
      return reply.status(202).send({ project, job: jobPublic(job) });
    });

    r.get('/v1/projects/:projectId', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      return { ...project, ...(await storeTitle(services.projectRoot(project))) };
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

    // Answer the App content questions in Play Console, which has no API for them.
    r.post('/v1/projects/:projectId/play/app-content', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const body = z
        .object({
          developerId: z.string().regex(/^\d{5,25}$/),
          appId: z.string().regex(/^\d{5,25}$/),
          userIndex: z.number().int().min(0).max(20).default(0),
          save: z.boolean().default(true),
        })
        .parse(req.body);
      const root = services.projectRoot(project);
      const { facts, email } = await appContentAnswers(root);
      const { title } = await storeTitle(root);
      try {
        return await (deps.fillAppContent ?? fillAppContent)({
          ...body,
          app: { ...facts, email, name: title || project.name },
          profileDir: path.resolve(cfg.WORKSPACES_ROOT, '.play-console-profile'),
        });
      } catch (e) {
        return reply.status(502).send({ code: 'console_failed', message: (e as Error).message });
      }
    });

    // Push the app's source to a GitHub repository the user owns.
    r.post('/v1/projects/:projectId/github', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const body = z
        .object({
          token: z.string().min(20).max(400),
          repo: z.string().max(100).optional(),
          private: z.boolean().default(true),
          message: z.string().max(200).optional(),
        })
        .parse(req.body);
      const root = services.projectRoot(project);
      const { title } = await storeTitle(root);
      try {
        return await (deps.saveToGitHub ?? saveToGitHub)({ ...body, projectRoot: root, appName: title || project.name });
      } catch (e) {
        if (e instanceof GitHubError) return reply.status(422).send({ code: e.code, message: e.message });
        throw e;
      }
    });

    // Copy the upload key and its password to the user's Google Drive: it cannot be recreated.
    r.post('/v1/projects/:projectId/signing/backup', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const root = services.projectRoot(project);
      const key = await ensureKey(cfg, project.id, project.name);
      const info = await (deps.androidInfo ?? androidAppInfo)(cfg, project.id, root, project.name);
      const listing = JSON.parse(await readFileAsync(path.join(root, 'store', 'listing.json'), 'utf8').catch(() => '{}')) as { title?: string };
      try {
        return await (deps.backupKey ?? backupKey)({
          appName: listing.title?.trim() || project.name,
          packageName: info.applicationId,
          keystorePath: key.keystorePath,
          alias: key.alias,
          password: key.storePassword,
        });
      } catch (e) {
        return reply.status(502).send({ code: 'drive_failed', message: (e as Error).message });
      }
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
            images: await storeImages(root),
          },
          deps.playFetch ?? fetch,
        );
        // Remembering the version must never turn a successful upload into an error.
        await rememberPublishedVersionCode(root, result.versionCode).catch(() => {});
        return { ...result, packageName: info.applicationId };
      } catch (e) {
        if (e instanceof PlayError) {
          return reply.status(e.code === 'bad_request' ? 400 : e.status && e.status < 500 ? 422 : 502).send({ code: e.code, message: e.message });
        }
        throw e;
      }
    });

    // Logo proposals drawn by the AI (SVG ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ PNG); "more logos" just calls again.
    r.post('/v1/projects/:projectId/logos', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const body = z
        .object({
          about: z.string().max(4000).default(''),
          appName: z.string().max(80).optional(),
          hint: z.string().max(500).optional(),
          count: z.number().int().min(1).max(6).default(6),
          engine: z.enum(['auto', 'claude', 'gemini']).default('auto'),
        })
        .parse(req.body);
      const claudeOk = await claudeCode.isAvailable();
      const viaClaude = async (system: string, prompt: string) => (await claudeCode.complete({ system, prompt, quality: 'fast' })).text;
      const viaGemini = async (system: string, prompt: string) => {
        if (!cfg.GEMINI_API_KEY) throw new Error('Gemini not configured');
        for (const model of GEMINI_FALLBACKS) {
          const res = await fetch(`${DEFAULT_UPSTREAMS.gemini}/v1beta/models/${model}:generateContent`, {
            method: 'POST',
            headers: { 'content-type': 'application/json', 'x-goog-api-key': cfg.GEMINI_API_KEY },
            body: JSON.stringify({ systemInstruction: { parts: [{ text: system }] }, contents: [{ role: 'user', parts: [{ text: prompt }] }], generationConfig: { maxOutputTokens: 16000, temperature: 1 } }),
          });
          if (!res.ok) continue;
          const j = (await res.json()) as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
          const text = j.candidates?.[0]?.content?.parts?.map((p) => p.text ?? '').join('') ?? '';
          if (text.includes('</svg>')) return text;
        }
        throw new Error('Gemini could not draw the logo (quota or overload)');
      };
      // Preferred engine first, the other one as fallback (free Gemini quota runs out quickly).
      const order =
        body.engine === 'gemini' ? [viaGemini, ...(claudeOk ? [viaClaude] : [])] : claudeOk ? [viaClaude, ...(cfg.GEMINI_API_KEY ? [viaGemini] : [])] : [viaGemini];
      const complete = async (system: string, prompt: string) => {
        let last: unknown;
        for (const fn of order) {
          try {
            return await fn(system, prompt);
          } catch (e) {
            last = e;
          }
        }
        throw last instanceof Error ? last : new Error('no AI available for logos');
      };
      const logos = await generateLogos({
        projectRoot: services.projectRoot(project),
        appName: body.appName ?? project.name.replace(/_\d+$/, '').replace(/_/g, ' '),
        about: body.about,
        hint: body.hint,
        count: body.count,
        complete,
      });
      if (logos.length === 0) return reply.status(502).send({ code: 'logo_failed', message: 'The AI could not draw logos right now, try again' });
      return { logos };
    });

    // Saved logos, applied logo, screenshots and store listing of a project.
    r.get('/v1/projects/:projectId/store', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      return storeState(services.projectRoot(project));
    });

    // Hands this app's facts to the browser helper waiting on the Play Console tab.
    r.post('/v1/projects/:projectId/helper', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const root = services.projectRoot(project);
      const { facts, email } = await appContentAnswers(root);
      const { title } = await storeTitle(root);
      helperApp = { ...facts, email, name: title || project.name, at: new Date().toISOString() };
      return { ok: true, name: helperApp.name };
    });

    // The phones plugged into this computer, so an app can be tried where it counts.
    r.get('/v1/devices', async () => ({ devices: await listDevices() }));

    r.post('/v1/projects/:projectId/run-on-device', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const { deviceId } = z.object({ deviceId: z.string().max(80).optional() }).parse(req.body ?? {});
      const root = services.projectRoot(project);
      const apkPath = path.join(root, ARTIFACTS['app-release.apk']!.rel);
      if (!(await stat(apkPath).catch(() => null))) {
        return reply.status(409).send({ code: 'not_ready', message: 'Build the APK first: Ember installs the file it has built.' });
      }
      const info = await (deps.androidInfo ?? androidAppInfo)(cfg, project.id, root, project.name);
      if (!info.applicationId) return reply.status(409).send({ code: 'not_ready', message: 'Android package name not found' });
      try {
        return { message: await installAndRun({ apkPath, packageName: info.applicationId, deviceId }) };
      } catch (e) {
        return reply.status(422).send({ code: 'device_refused', message: (e as Error).message });
      }
    });

    // What is missing for this app to work, and what Ember can put right by itself.
    r.get('/v1/projects/:projectId/check', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const root = services.projectRoot(project);
      const { previewUrl } = z.object({ previewUrl: z.string().url().max(500).optional() }).parse(req.query ?? {});
      const checked = await inspectProject(root);
      const [cloud, running] = await Promise.all([inspectCloud(checked.firebaseProject), inspectRunning(previewUrl ?? null)]);
      return { ...checked, findings: [...checked.findings, ...cloud, ...running] };
    });

    r.post('/v1/projects/:projectId/check/fix', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const { ids } = z.object({ ids: z.array(z.string().max(60)).min(1).max(20) }).parse(req.body);
      const root = services.projectRoot(project);
      const { firebaseProject } = await inspectProject(root);
      const done: Array<{ id: string; ok: boolean; message: string }> = [];
      for (const id of ids) {
        try {
          done.push({ id, ok: true, message: await fixFinding(id, { projectRoot: root, firebaseProject }) });
        } catch (e) {
          done.push({ id, ok: false, message: (e as Error).message });
        }
      }
      return reply.send({ done });
    });

    // Play Console "App content": the answer for every declaration Google asks for.
    r.get('/v1/projects/:projectId/app-content', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      return appContentAnswers(services.projectRoot(project));
    });

    // Store listing texts written/edited by the user, reused for every new version.
    r.put('/v1/projects/:projectId/store/listing', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const listing = z
        .object({
          title: z.string().max(30).default(''),
          shortDescription: z.string().max(80).default(''),
          fullDescription: z.string().max(4000).default(''),
          releaseNotes: z.string().max(500).default(''),
          contactEmail: z.string().max(200).default(''),
          privacyUrl: z.string().max(500).default(''),
          dataSafety: z.string().max(20000).default(''),
          contentRating: z.string().max(20000).default(''),
          otherDeclarations: z.string().max(20000).default(''),
        })
        .parse(req.body);
      const dir = path.join(services.projectRoot(project), 'store');
      await mkdirAsync(dir, { recursive: true });
      await writeFileAsync(path.join(dir, 'listing.json'), JSON.stringify({ ...listing, savedAt: new Date().toISOString() }, null, 2));
      return { ok: true };
    });

    r.post('/v1/projects/:projectId/logos/:logoId/apply', async (req) => {
      const { projectId, logoId } = req.params as { projectId: string; logoId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      return applyLogo(services.projectRoot(project), logoId);
    });

    // Play Store phone screenshots from the web preview (headless Chrome, screenshot mode).
    r.post('/v1/projects/:projectId/screenshots', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const root = services.projectRoot(project);
      if (!(await hasScreenshotMode(root))) {
        return reply.status(409).send({ code: 'needs_screenshot_mode', message: 'The app needs a screenshot mode first', request: SCREENSHOT_UPGRADE_REQUEST });
      }
      const info = await preview.info(project);
      if (!info.built || info.building) return reply.status(409).send({ code: 'not_built', message: 'Wait for the web preview to finish building, then try again' });
      const browser = findBrowser();
      if (!browser) return reply.status(501).send({ code: 'no_browser', message: 'Install Google Chrome or Microsoft Edge on the Runner machine to take screenshots' });
      const shots = await captureScreenshots({ previewUrl: `http://127.0.0.1:${cfg.PORT}${info.path}`, projectRoot: root, browser });
      if (shots.length === 0) return reply.status(502).send({ code: 'screenshots_failed', message: 'No screen could be captured' });
      return { shots };
    });

    // Automatic Google Play connection on the Runner PC (gcloud): key creation and Play Console invite.
    r.get('/v1/play/setup/status', async () => gcloudStatus());
    r.post('/v1/play/setup/service-account', async (req, reply) => {
      if (driver.kind !== 'local') return reply.status(501).send({ code: 'unsupported', message: 'Only available on a local Runner' });
      try {
        return await createServiceAccountKey(path.join(cfg.WORKSPACES_ROOT, '.play'));
      } catch (e) {
        return reply.status(502).send({ code: 'setup_failed', message: (e as Error).message });
      }
    });
    r.post('/v1/play/setup/invite', async (req, reply) => {
      if (driver.kind !== 'local') return reply.status(501).send({ code: 'unsupported', message: 'Only available on a local Runner' });
      const body = z.object({ developerId: z.string().regex(/^\d{5,25}$/), serviceAccountEmail: z.string().email().max(200) }).parse(req.body);
      try {
        return await invitePlayUser(body.developerId, body.serviceAccountEmail, deps.playFetch ?? fetch, path.join(cfg.WORKSPACES_ROOT, '.play'));
      } catch (e) {
        return reply.status(502).send({ code: 'invite_failed', message: (e as Error).message });
      }
    });

    // Data safety: the AI fills the CSV exported from Play Console and the Runner uploads it.
    r.post('/v1/projects/:projectId/play/data-safety', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const body = z.object({ serviceAccount: z.string().min(50).max(20000), csv: z.string().max(500_000).optional() }).parse(req.body);
      const root = services.projectRoot(project);
      const csvPath = body.csv ? null : await findExportedCsv();
      const csv = body.csv ?? (csvPath ? await readFileAsync(csvPath, 'utf8') : null);
      if (!csv || !/Question ID|PSL_/i.test(csv)) {
        return reply.status(409).send({ code: 'needs_csv', message: 'Export the Data safety CSV from Play Console first (Data safety ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ Export to CSV), then try again' });
      }
      const info = await (deps.androidInfo ?? androidAppInfo)(cfg, project.id, root, project.name);
      if (!info.applicationId) return reply.status(409).send({ code: 'not_ready', message: 'Android package name not found' });
      const facts = await detectDataFacts(root);
      try {
        // The form has ~800 rows with stable ids: filled from the app's own facts, no AI, no waiting.
        const listing = JSON.parse(await readFileAsync(path.join(root, 'store', 'listing.json'), 'utf8').catch(() => '{}')) as { privacyUrl?: string };
        const filled = validateFilledCsv(csv, fillCsv(csv, facts, listing.privacyUrl ?? ''));
        await uploadDataSafety({ serviceAccount: parseServiceAccount(body.serviceAccount), packageName: info.applicationId, csv: filled }, deps.playFetch ?? fetch);
        return { ok: true, source: csvPath ?? 'pasted', facts };
      } catch (e) {
        if (e instanceof PlayError) return reply.status(422).send({ code: e.code, message: e.message });
        throw e;
      }
    });

    // Create/activate in-app products and subscriptions for the app on Google Play.
    r.post('/v1/projects/:projectId/play/products', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const body = z
        .object({
          serviceAccount: z.string().min(50).max(20000),
          products: z
            .array(
              z.object({
                id: z.string().min(1).max(139),
                type: z.enum(['inapp', 'subscription']),
                title: z.string().min(1).max(55),
                description: z.string().max(200).default(''),
                price: z.string().min(1).max(12),
                currency: z.string().length(3).default('EUR'),
                period: z.string().max(5).optional(),
                freeTrialDays: z.number().int().min(0).max(90).optional(),
                language: z.string().max(10).optional(),
              }),
            )
            .min(1)
            .max(30),
        })
        .parse(req.body);
      const info = await (deps.androidInfo ?? androidAppInfo)(cfg, project.id, services.projectRoot(project), project.name);
      if (!info.applicationId) return reply.status(409).send({ code: 'not_ready', message: 'Android package name not found' });
      try {
        const results = await syncProducts(
          { serviceAccount: parseServiceAccount(body.serviceAccount), packageName: info.applicationId, products: body.products },
          deps.playFetch ?? fetch,
        );
        return { packageName: info.applicationId, results };
      } catch (e) {
        if (e instanceof PlayError) return reply.status(e.code === 'bad_request' ? 400 : 422).send({ code: e.code, message: e.message });
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

  // ---------------- AI (Ãƒâ€šÃ‚Â§5B) ----------------

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
