import Fastify, { type FastifyInstance, type FastifyRequest } from 'fastify';
import { syncProducts } from './play_products.js';
import { appContentAnswers } from './app_content.js';
import { AppStore, AppStoreError, appleText, applePrivacyPlan, cutAtWord, finishWhenBuildReady, parseAppStoreKey, projectBuildNumber, projectVersion, publishToAppStore, type AppStoreListing, type AppStorePublishInput, type AppStorePublishResult } from './appstore.js';
import { AutoTracker, isRunning, needsFreshIpa, type AutoStatus } from './appstore_auto.js';
import { MAX_VALUE, readSettings, SETTING_KEY, writeSettings } from './settings_store.js';
import { appleProductsFrom, type AppleProduct, type DeclaredProduct } from './appstore_products.js';
import { appleFacts, readAppleSettings } from './apple_settings.js';
import { blocking, fixPreflight, preflightIos } from './ios_preflight.js';
import { deleteAppleCreds, readAppleCreds, readAppleCredsPublic, readAppleKey, readMarketingUrl, readReviewPhone, rememberMarketingUrl, rememberReviewPhone, rememberTeamId, saveAppleCreds } from './apple_creds.js';
import { teamFromAppStore } from './ios_signing.js';
import { backupKey } from './drive.js';
import { installAndRun, lanAddress, listDevices } from './devices.js';
import { fix as fixFinding, inspectCloud, inspectProject, inspectRunning } from './doctor.js';
import { openAiComplete, reviewApp } from './ai_review.js';
import { GitHubError, listEmberApps, restoreFromGitHub, saveToGitHub } from './github.js';
import { fillAppContent } from './play_console.js';
import { fillPolicy, publishPolicy } from './publish_prep.js';
import { detectDataFacts, fillCsv, findExportedCsv, uploadDataSafety, validateFilledCsv } from './data_safety.js';
import { createServiceAccountKey, gcloudStatus, invitePlayUser, storeImages } from './play_setup.js';
import { cliLogins, cliModels } from './subscription_clis.js';
import { mkdir, stat } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import os from 'node:os';
import path from 'node:path';
import cors from '@fastify/cors';
import fastifyStatic from '@fastify/static';
import websocket from '@fastify/websocket';
import { PathError, safeResolve } from './paths.js';
import { PreviewService } from './preview.js';
import { DEFAULT_UPSTREAMS, GEMINI_FALLBACKS, registerAiRoutes } from './ai.js';
import { applyLogo, generateLogos, generateLogosPanel, storeState } from './logos.js';
import { captureScreenshots, findBrowser, hasScreenshotMode, SCREENSHOT_UPGRADE_REQUEST } from './screenshots.js';
import { parseScreenshots, registerResearchRoutes, saveReferenceShots } from './research.js';
import { readSite, saveSiteShots } from './web_reference.js';
import { ClaudeCodeEngine, detectClis } from './agent_cli.js';
import { z } from 'zod';
import { Authenticator, bearer, type AuthUser } from './auth.js';
import type { Config } from './config.js';
import { errorPayload, httpStatus } from './errors.js';
import { WatchHub } from './fs.js';
import { JobManager, jobPublic } from './jobs.js';
import { ARTIFACTS, Services, TEMPLATES, type SignedBuildPreparer } from './services.js';
import { androidAppInfo, ensureUploadKey, rememberAppStoreBuildNumber, rememberPublishedVersionCode } from './signing.js';
import { parseServiceAccount, PlayError, privacyHtml, publishToPlay } from './play.js';
import { readFile as readFileAsync, writeFile as writeFileAsync, mkdir as mkdirAsync, unlink as unlinkAsync } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
import { JsonStore, SupabaseStore, type ProjectRow, type Store } from './store.js';
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

/** A repository name ("beauty-camera") as a project folder ("beauty_camera"). */
export function folderName(repo: string): string {
  const slug = repo
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 60);
  return /^[a-z]/.test(slug) ? slug : `app_${slug || 'ember'}`;
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
  /** Lets the tests answer for the AI reviewers. */
  reviewFetch?: typeof fetch;
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
      redact: ['req.headers.authorization', 'req.query.token', 'req.headers["x-provider-key"]', 'req.headers["x-provider-base-url"]', 'req.body.serviceAccount', 'req.body.privateKey'],
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

  /**
   * One answer from Gemini on the Runner's own key, walking the fallback models
   * until one replies. Shared by everything this machine offers Gemini for —
   * drawing icons, reviewing a finished app — so the user never fetches a key
   * for it. [accept] lets a caller demand more than a reply (an SVG, say) and
   * move on to the next model when it does not get it.
   */
  const geminiComplete = async (system: string, prompt: string, accept: (text: string) => boolean = (t) => t.trim().length > 0): Promise<string> => {
    if (!cfg.GEMINI_API_KEY) throw new Error('Gemini not configured');
    for (const model of GEMINI_FALLBACKS) {
      const res = await fetch(`${DEFAULT_UPSTREAMS.gemini}/v1beta/models/${model}:generateContent`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': cfg.GEMINI_API_KEY },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: system }] },
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: { maxOutputTokens: 16000, temperature: 1 },
        }),
      });
      if (!res.ok) continue;
      const j = (await res.json()) as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
      const text = j.candidates?.[0]?.content?.parts?.map((p) => p.text ?? '').join('') ?? '';
      if (accept(text)) return text;
    }
    throw new Error('Gemini non ha risposto (quota esaurita o servizio sovraccarico)');
  };

  await app.register(cors, {
    origin: cfg.CORS_ORIGINS === '*' ? true : cfg.CORS_ORIGINS.split(',').map((s) => s.trim()),
    // @fastify/cors allows only GET, HEAD and POST unless told: the IDE also saves
    // with PUT/PATCH and removes with DELETE (settings, Apple key, projects).
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
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

  /**
   * The same for App Store Connect: the app to create and its App Privacy
   * answers, one per Bundle ID, kept in ~/.ember/helper_apple.json so a
   * Runner restart forgets nothing. The extension asks for the app open in its
   * tab (?bundleId=), or for the last one prepared.
   */
  const helperAppleFile = () => path.join(os.homedir(), '.ember', 'helper_apple.json');
  type AppleHelpers = { last?: string; byBundle: Record<string, Record<string, unknown>> };
  const readAppleHelpers = async (): Promise<AppleHelpers> =>
    JSON.parse(await readFileAsync(helperAppleFile(), 'utf8').catch(() => '{"byBundle":{}}')) as AppleHelpers;
  const saveAppleHelper = async (plan: Record<string, unknown>) => {
    const all = await readAppleHelpers();
    const bundle = `${plan.bundleId ?? ''}`;
    if (!bundle) return;
    all.byBundle[bundle] = plan;
    all.last = bundle;
    await mkdirAsync(path.dirname(helperAppleFile()), { recursive: true }).catch(() => {});
    await writeFileAsync(helperAppleFile(), JSON.stringify(all, null, 1), { mode: 0o600 });
  };

  app.get('/helper/apple', async (req, reply) => {
    const origin = req.headers.origin ?? '';
    if (origin.startsWith('chrome-extension://')) reply.header('access-control-allow-origin', origin);
    reply.header('cache-control', 'no-store');
    const { bundleId } = (req.query ?? {}) as { bundleId?: string };
    const all = await readAppleHelpers();
    const plan = (bundleId && all.byBundle[bundleId]) || (!bundleId && all.last ? all.byBundle[all.last] : undefined);
    if (!plan) {
      return reply.status(404).send({
        code: 'no_app',
        message: bundleId
          ? `Ember non conosce ancora ${bundleId}: apri quell’app in Ember, scheda iPhone, e riprova.`
          : 'Apri l’app in Ember, scheda iPhone: da lì Ember prepara i dati per l’estensione.',
      });
    }
    // A provisional Bundle ID can never go on the App Store: the plan was made
    // before the app got its real one, so it is stale.
    if (`${plan.bundleId ?? ''}`.startsWith('dev.fluttercursor.app.')) {
      return reply.status(409).send({
        code: 'stale_plan',
        message: 'Questi dati sono vecchi (Bundle ID provvisorio): apri l’app in Ember, scheda iPhone, e riprova.',
      });
    }
    return plan;
  });

  // What the extension must put in the review with the version, read live from
  // Apple's public API (the website's own lists proved unreliable to read).
  app.get('/helper/apple/review', async (req, reply) => {
    const origin = req.headers.origin ?? '';
    if (origin.startsWith('chrome-extension://')) reply.header('access-control-allow-origin', origin);
    reply.header('cache-control', 'no-store');
    const { bundleId } = (req.query ?? {}) as { bundleId?: string };
    const key = await readAppleKey().catch(() => null);
    if (!bundleId || !key) return reply.status(404).send({ code: 'no_key', message: 'Ember non ha la chiave Apple o il Bundle ID.' });
    try {
      const store = await AppStore.open(key);
      const found = await store.call<{ data: Array<{ id: string }> }>('GET', `/apps?filter[bundleId]=${encodeURIComponent(bundleId)}&limit=1`);
      const appId = found.data?.[0]?.id;
      if (!appId) return reply.status(404).send({ code: 'no_app', message: 'L’app non c’è su App Store Connect.' });
      type R = { id: string; attributes?: Record<string, unknown> };
      const groups = (await store.call<{ data: R[] }>('GET', `/apps/${appId}/subscriptionGroups?limit=50`)).data ?? [];
      const groupIds: string[] = [];
      const subscriptionIds: string[] = [];
      const names: string[] = [];
      for (const g of groups) {
        const subs = ((await store.call<{ data: R[] }>('GET', `/subscriptionGroups/${g.id}/subscriptions?limit=50`)).data ?? []).filter((x) => x.attributes?.state === 'READY_TO_SUBMIT');
        if (subs.length) groupIds.push(g.id);
        for (const x of subs) (subscriptionIds.push(x.id), names.push(`${x.attributes?.productId}`));
      }
      const iaps = ((await store.call<{ data: R[] }>('GET', `/apps/${appId}/inAppPurchasesV2?limit=200`)).data ?? []).filter((x) => x.attributes?.state === 'READY_TO_SUBMIT');
      for (const x of iaps) names.push(`${x.attributes?.productId}`);
      return { appId, groupIds, subscriptionIds, purchaseIds: iaps.map((x) => x.id), names };
    } catch (e) {
      return reply.status(502).send({ code: 'apple_error', message: (e as Error).message });
    }
  });

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
    engines: { claudeCode: await claudeCode.isAvailable(), ...(driver.kind === 'local' ? await cliLogins().then((l) => ({ codex: l.codex, geminiCli: l['gemini-cli'] })) : { codex: false, geminiCli: false }), assistant: cfg.GEMINI_API_KEY !== '' || (await claudeCode.isAvailable()), serverGemini: cfg.GEMINI_API_KEY !== '' },
    // AI CLIs usable from the integrated terminal (local driver: host PATH).
    cli: driver.kind === 'local' ? await detectClis() : {},
    cliModels: driver.kind === 'local' ? cliModels() : {},
    shells: process.platform === 'win32' ? ['cmd', 'powershell'] : ['bash'],
  }));

  app.post('/v1/auth/dev-login', async (req, reply) => {
    if (!cfg.DEV_AUTH) return reply.status(404).send({ code: 'not_found', message: 'dev auth disabled' });
    const { email } = z.object({ email: z.string().email() }).parse(req.body);
    const issued = await auth.issueDevToken(email);
    await mkdirAsync(path.dirname(devLastFile()), { recursive: true }).catch(() => {});
    await writeFileAsync(devLastFile(), JSON.stringify({ email }), { mode: 0o600 }).catch(() => {});
    return issued;
  });

  // Local dev only: the IDE opened by `flutter run` starts with an empty browser,
  // so it asks this Mac who was signed in last and signs in again by itself.
  const devLastFile = () => path.join(os.homedir(), '.ember', 'dev_last.json');
  const fromThisMac = (ip: string) => ip === '127.0.0.1' || ip === '::1' || ip === '::ffff:127.0.0.1';

  app.get('/v1/auth/dev-last', async (req, reply) => {
    if (!cfg.DEV_AUTH || !fromThisMac(req.ip)) return reply.status(404).send({ code: 'not_found', message: 'not available' });
    const saved = JSON.parse(await readFileAsync(devLastFile(), 'utf8').catch(() => '{}')) as { email?: string };
    if (!saved.email) return reply.status(404).send({ code: 'not_found', message: 'nobody signed in yet' });
    return { email: saved.email };
  });

  app.delete('/v1/auth/dev-last', async (req, reply) => {
    if (!cfg.DEV_AUTH || !fromThisMac(req.ip)) return reply.status(404).send({ code: 'not_found', message: 'not available' });
    await unlinkAsync(devLastFile()).catch(() => {});
    return reply.status(204).send();
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
    // The GitHub repository an app is already linked to, so the card can show
    // "already saved on GitHub" with its name instead of only a Save button.
    r.get('/v1/projects/:projectId/github', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const root = services.projectRoot(project);
      const config = await readFileAsync(path.join(root, '.git', 'config'), 'utf8').catch(() => '');
      const url = /\[remote "origin"\][^[]*?url\s*=\s*(\S+)/.exec(config)?.[1] ?? '';
      const m = /github\.com[/:]([^/]+)\/([^/.]+)(?:\.git)?/.exec(url);
      if (!m) return { linked: false };
      return { linked: true, owner: m[1], repo: m[2], url: `https://github.com/${m[1]}/${m[2]}` };
    });

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

    // Apple's side of publishing: build upload, store page in every language,
    // privacy answers, and (when asked) sending the version for review.
    const publishSchema = z.object({
      // The key is optional here: it is normally the account key saved once
      // under ~/.ember/apple. The fields stay accepted as a fallback.
      keyId: z.string().max(40).optional(),
      issuerId: z.string().max(60).optional(),
      privateKey: z.string().max(8000).optional(),
      listing: z.record(z.string(), z.unknown()).optional(),
      translations: z.array(z.record(z.string(), z.unknown())).max(20).optional(),
      privacyPolicyUrl: z.string().max(500).optional(),
      uploadBuild: z.boolean().default(false),
      submit: z.boolean().default(false),
      // iOS submission chores Ember now fills automatically.
      category: z.string().max(40).optional(),
      secondaryCategory: z.string().max(40).optional(),
      free: z.boolean().default(false),
      screenshots: z.boolean().default(false),
      /** Send even when the preflight finds something Apple would reject. */
      skipChecks: z.boolean().default(false),
      /** Developer website (Marketing URL); remembered for the account. */
      marketingUrl: z.string().url().max(300).optional(),
      review: z
        .object({
          firstName: z.string().max(60).optional(),
          lastName: z.string().max(60).optional(),
          email: z.string().max(120).optional(),
          phone: z.string().max(40).optional(),
          demoUser: z.string().max(120).optional(),
          demoPassword: z.string().max(120).optional(),
          notes: z.string().max(4000).optional(),
        })
        .optional(),
    });
    type PublishBody = z.infer<typeof publishSchema>;

    /** Everything publishToAppStore needs, from the request and the project. */
    /**
     * The app's purchases for Apple: store/apple_products.json when the project
     * has one (exact Apple ids), else what the engine declared for Google Play.
     */
    const appleProductsOf = async (project: ProjectRow, ownerId: string): Promise<{ products: AppleProduct[]; screenshot?: Buffer }> => {
      const root = services.projectRoot(project);
      const own = JSON.parse(await readFileAsync(path.join(root, 'store', 'apple_products.json'), 'utf8').catch(() => 'null')) as AppleProduct[] | null;
      let products = Array.isArray(own) ? own : [];
      if (!products.length) {
        const session = JSON.parse((await readSettings(ownerId).catch(() => ({}) as Record<string, string>))[`ember_session_${project.id}`] ?? '{}') as { products?: DeclaredProduct[] };
        const name = /^name:\s*([a-z0-9_]+)/m.exec(await readFileAsync(path.join(root, 'pubspec.yaml'), 'utf8').catch(() => ''))?.[1] ?? project.name;
        products = appleProductsFrom(session.products ?? [], name);
      }
      if (!products.length) return { products };
      // The reviewer wants to see the purchase screen: the screenshot of the paywall when there is one.
      const labels = await readFileAsync(path.join(root, 'lib', 'config', 'screenshot_screens.dart'), 'utf8').catch(() => '');
      const order = /order\s*=\s*<\w+>\[([\s\S]*?)\]/.exec(labels)?.[1]?.split(',').map((x) => x.trim()).filter(Boolean) ?? [];
      const paywall = order.findIndex((x) => /premium|paywall|subscri|pro\b|upgrade|unlock|shop|store/i.test(x));
      const chosen = (await readAppleSettings(root)).reviewScreenshot;
      const file = path.join(root, 'store', 'screenshots', chosen || `phone_${paywall >= 0 ? paywall + 1 : 1}.png`);
      const screenshot = await readFileAsync(file).catch(() => undefined);
      return { products, screenshot };
    };

    const preparePublish = async (project: ProjectRow, body: PublishBody, email?: string, ownerId?: string): Promise<AppStorePublishInput> => {
      const root = services.projectRoot(project);
      // The main listing is the English one (as on Play). Older IDEs labelled it
      // Italian, so the Italian translation then overwrote it and English, the
      // app's primary language on Apple, stayed empty.
      if (body.listing && (!body.listing.language || (body.translations ?? []).some((t) => t.language === body.listing!.language))) {
        body.listing.language = 'en-US';
      }
      // Hand-picked App Store keywords per language (store/apple_keywords.json,
      // keyed by the listing's language) win over the ones made from the text.
      const keywords = JSON.parse(await readFileAsync(path.join(root, 'store', 'apple_keywords.json'), 'utf8').catch(() => '{}')) as Record<string, string>;
      for (const page of [body.listing, ...(body.translations ?? [])]) {
        const k = page && keywords[`${page.language ?? ''}`];
        if (page && k) page.keywords = k;
      }
      const gradle = await readFileAsync(path.join(root, 'android', 'app', 'build.gradle.kts'), 'utf8').catch(() => '');
      const bundleId = /applicationId\s*=\s*"([^"]+)"/.exec(gradle)?.[1] ?? '';
      if (!bundleId) throw new AppStoreError('no_bundle_id', 'Build the app once before publishing: its name is set at the first build.');
      // Always prefer the saved account key; fall back to any key sent in the body.
      const key = (await readAppleKey()) ?? parseAppStoreKey(body);
      const settings = await readAppleSettings(root);
      // Screenshots need the local web preview and a browser; only wire them up
      // when the app has a screenshot mode and the preview is ready.
      let screenshots: { previewUrl: string; browser: string } | undefined;
      if (body.screenshots) {
        const browser = findBrowser();
        const info = await preview.info(project);
        if (browser && info.built && !info.building && (await hasScreenshotMode(root))) {
          screenshots = { previewUrl: `http://127.0.0.1:${cfg.PORT}${info.path}`, browser };
        }
      }
      // Default the reviewer contact to the signed-in email so the form is never empty.
      // The phone is remembered for the account: typed once, reused by every app.
      const review = { ...(email ? { email } : {}), ...(body.review ?? {}) };
      if (review.phone) await rememberReviewPhone(review.phone).catch(() => {});
      else review.phone = (await readReviewPhone().catch(() => '')) || undefined;
      if (body.marketingUrl) await rememberMarketingUrl(body.marketingUrl).catch(() => {});
      const marketingUrl = body.marketingUrl || (await readMarketingUrl().catch(() => '')) || undefined;
      return {
        key,
        bundleId,
        versionString: await projectVersion(root),
        projectRoot: root,
        listing: body.listing as AppStoreListing | undefined,
        translations: body.translations as AppStoreListing[] | undefined,
        privacyPolicyUrl: body.privacyPolicyUrl,
        facts: appleFacts(await detectDataFacts(root), settings),
        kidsAgeBand: settings.kids ? (settings.kidsAgeBand ?? 'FIVE_AND_UNDER') : undefined,
        uploadBuild: body.uploadBuild,
        submit: body.submit,
        category: body.category,
        secondaryCategory: body.secondaryCategory,
        review,
        free: body.free,
        screenshots,
        marketingUrl,
        ...(ownerId ? await appleProductsOf(project, ownerId).then(({ products, screenshot }) => ({ products, productScreenshot: screenshot })) : {}),
      };
    };

    /** Remember what Apple now has, so the next build of either store starts above it. */
    const rememberUploaded = async (root: string, result: AppStorePublishResult) => {
      if (!result.buildUploaded) return;
      const build = await projectBuildNumber(root);
      if (build > 0) await rememberAppStoreBuildNumber(root, build).catch(() => {});
    };

    r.post('/v1/projects/:projectId/appstore/publish', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const body = publishSchema.parse(req.body);
      try {
        const input = await preparePublish(project, body, req.user.email, req.user.id);
        const result = await publishToAppStore(input);
        await rememberUploaded(input.projectRoot, result);
        return { ...result, bundleId: input.bundleId };
      } catch (e) {
        if (e instanceof AppStoreError) return reply.status(422).send({ code: e.code, message: e.message });
        throw e;
      }
    });

    // ---- Publish as one press: build → upload → store page → wait → review ----
    const autoRuns = new Map<string, Promise<void>>(); // project root → the run in progress

    /** Waits for Apple to process the build, then attaches it and sends it for review. */
    const finishAuto = async (tracker: AutoTracker, wait: NonNullable<AutoStatus['wait']>) => {
      const key = await readAppleKey();
      if (!key) return tracker.fail('La chiave Apple non è più salvata: caricala di nuovo e premi Publish.');
      const done = await finishWhenBuildReady({ key, ...wait, onProgress: (m) => void tracker.progress(m) });
      await tracker.phase(done.submitted ? 'submitted' : 'done', done.submitted ? 'Inviata in revisione ad Apple ✓' : `Build ${wait.buildNumber} collegata alla versione ✓`, { wait: undefined });
    };

    const runAuto = async (tracker: AutoTracker, project: ProjectRow, ownerId: string, body: PublishBody, email?: string) => {
      const root = services.projectRoot(project);
      try {
        if (!body.skipChecks && body.submit) {
          // What Apple would reject costs days: fix what Ember can, stop on the rest.
          const ctx = await preflightContext(root, body);
          let found = blocking(await preflightIos(ctx));
          const fixed: string[] = [];
          for (const f of found.filter((x) => x.fixable)) fixed.push(await fixPreflight(f.id, ctx).catch((e: unknown) => `${f.title}: ${(e as Error).message}`));
          if (fixed.length) {
            await tracker.progress(`Controllo prima dell’invio: ${fixed.join(', ')}`);
            found = blocking(await preflightIos(ctx));
          }
          if (found.length) {
            return tracker.fail(`Apple rifiuterebbe l’app, quindi non la invio:\n${found.map((f) => `• ${f.title} — ${f.detail}`).join('\n')}`);
          }
        }
        if (body.uploadBuild) {
          const fresh = await needsFreshIpa(root);
          if (fresh.build) {
            await tracker.phase('building', `Creo il file iPhone (${fresh.reason})`);
            let job = await jobs.wait((await services.startJob(ownerId, project.id, 'build_ipa')).id);
            // A new plugin can be newer than this Mac's list of CocoaPods: refresh it once and build again.
            if (job.status !== 'succeeded' && /specs repository is too out-of-date|pod repo update/.test(job.log.join(''))) {
              await tracker.progress('Aggiorno l’elenco delle librerie iPhone (CocoaPods) e riprovo');
              await new Promise<void>((resolve) => {
                const p = spawn('pod', ['install', '--repo-update'], { cwd: path.join(root, 'ios') });
                p.on('close', () => resolve());
                p.on('error', () => resolve());
              });
              job = await jobs.wait((await services.startJob(ownerId, project.id, 'build_ipa')).id);
            }
            if (job.status !== 'succeeded') {
              const tail = job.log.join('').split('\n').filter((l) => l.trim()).slice(-12).join('\n');
              return tracker.fail(`La build iPhone non è riuscita:\n${tail}`);
            }
          } else {
            await tracker.progress(`File iPhone già pronto: ${fresh.reason}`);
          }
          if (!fresh.upload) body.uploadBuild = false;
        }
        await tracker.phase('publishing', body.uploadBuild ? 'Carico su Apple, scrivo la scheda e gli screenshot' : 'Scrivo la scheda e gli screenshot');
        const input = await preparePublish(project, body, email, ownerId);
        const result = await publishToAppStore(input);
        await rememberUploaded(root, result);
        const extra = { result: { ...result, bundleId: input.bundleId } as Record<string, unknown>, notes: result.notes };
        if (body.submit && !result.submitted && result.waitingForBuild) {
          const wait = { appId: result.appId, versionId: result.versionId, buildNumber: result.waitingForBuild, submit: true };
          await tracker.phase('waiting', `Apple sta elaborando la build ${wait.buildNumber}`, { ...extra, wait });
          await finishAuto(tracker, wait);
        } else {
          await tracker.phase(result.submitted ? 'submitted' : 'done', result.submitted ? 'Inviata in revisione ad Apple ✓' : 'Scheda aggiornata su Apple ✓', extra);
        }
      } catch (e) {
        await tracker.fail(e instanceof Error ? e.message : String(e));
      }
    };

    /** The listing the checks read: what the IDE sent, else what the project saved. */
    const preflightContext = async (root: string, body?: Partial<PublishBody>) => {
      const saved = JSON.parse(await readFileAsync(path.join(root, 'store', 'listing.json'), 'utf8').catch(() => '{}')) as { title?: string; privacyUrl?: string };
      const review = body?.review?.phone || (await readReviewPhone().catch(() => ''));
      return {
        root,
        listing: { title: `${body?.listing?.title ?? saved.title ?? ''}`, privacyUrl: body?.privacyPolicyUrl || saved.privacyUrl || '' },
        reviewPhone: review || undefined,
        marketingUrl: body?.marketingUrl || (await readMarketingUrl().catch(() => '')) || undefined,
      };
    };

    /**
     * What the browser extension needs on App Store Connect for this app: the
     * names to create it with, and the App Privacy answers from the same table
     * as Google's Data safety. The Bundle ID is registered on the way.
     */
    const prepareAppleHelper = async (project: ProjectRow): Promise<Record<string, unknown>> => {
      const root = services.projectRoot(project);
      const gradle = await readFileAsync(path.join(root, 'android', 'app', 'build.gradle.kts'), 'utf8').catch(() => '');
      const bundleId = /applicationId\s*=\s*"([^"]+)"/.exec(gradle)?.[1] ?? '';
      const { title } = await storeTitle(root);
      const name = cutAtWord(appleText(title || project.name), 30);
      const plan = {
        name,
        bundleId,
        sku: bundleId.split('.').pop()?.replace(/[^a-z0-9]/gi, '').slice(0, 30) || project.id,
        primaryLocale: 'en-US',
        privacy: applePrivacyPlan(appleFacts(await detectDataFacts(root), await readAppleSettings(root))),
        bundleRegistered: false,
        at: new Date().toISOString(),
      };
      const key = await readAppleKey().catch(() => null);
      if (key && bundleId && !bundleId.startsWith('dev.fluttercursor.app.')) {
        plan.bundleRegistered = await (await AppStore.open(key)).ensureBundleId(bundleId, name).then(() => true, () => false);
      }
      await saveAppleHelper(plan).catch(() => {});
      return plan;
    };

    r.post('/v1/projects/:projectId/helper/apple', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      return prepareAppleHelper(project);
    });

    // What Apple would reject, checked before sending: blocks, warnings, and who fixes each.
    // Opening the App Store card also readies the browser extension for this app.
    r.get('/v1/projects/:projectId/appstore/preflight', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      await prepareAppleHelper(project).catch(() => null);
      return { findings: await preflightIos(await preflightContext(services.projectRoot(project))) };
    });

    r.post('/v1/projects/:projectId/appstore/preflight/fix', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const { ids } = z.object({ ids: z.array(z.string().max(80)).min(1).max(20) }).parse(req.body);
      const ctx = await preflightContext(services.projectRoot(project));
      const done: Array<{ id: string; ok: boolean; message: string }> = [];
      for (const id of ids) {
        try {
          done.push({ id, ok: true, message: await fixPreflight(id, ctx) });
        } catch (e) {
          done.push({ id, ok: false, message: (e as Error).message });
        }
      }
      return { done, findings: await preflightIos(ctx) };
    });

    r.post('/v1/projects/:projectId/appstore/autopublish', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const root = services.projectRoot(project);
      const body = publishSchema.parse(req.body);
      if (autoRuns.has(root)) return reply.status(409).send({ code: 'already_running', message: 'Una pubblicazione è già in corso per questa app.' });
      if (!(await readAppleKey()) && !body.privateKey) return reply.status(422).send({ code: 'no_key', message: 'Salva prima la chiave Apple (Key ID, Issuer ID e file .p8).' });
      const tracker = await AutoTracker.open(root);
      await tracker.start(body.uploadBuild ? 'building' : 'publishing', 'Parto');
      const run = runAuto(tracker, project, req.user.id, body, req.user.email).finally(() => autoRuns.delete(root));
      autoRuns.set(root, run);
      return tracker.status;
    });

    // Where the one-press publish is. A wait cut short by a Runner restart resumes here.
    r.get('/v1/projects/:projectId/appstore/autopublish', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const root = services.projectRoot(project);
      const tracker = await AutoTracker.open(root);
      const s = tracker.status;
      if (s && isRunning(s) && !autoRuns.has(root)) {
        if (s.phase === 'waiting' && s.wait) {
          const wait = s.wait;
          const run = finishAuto(tracker, wait)
            .catch((e: unknown) => tracker.fail(e instanceof Error ? e.message : String(e)))
            .finally(() => autoRuns.delete(root));
          autoRuns.set(root, run);
        } else {
          await tracker.fail('Il Runner si è riavviato durante la pubblicazione: premi di nuovo Publish.');
        }
      }
      return tracker.status ?? { phase: null };
    });

    // ---- Apple App Store Connect key, saved once for the whole account ----
    // Kept in ~/.ember/apple (0600), outside the repo and never in the browser,
    // so the Key ID / Issuer ID / .p8 come back filled for every project and
    // survive a reload, a closed browser, a Runner restart or a reboot.

    // What the user typed once in the IDE (tokens, keys, chats, choices): kept
    // here, per user, so a restarted or different browser still has it.
    r.get('/v1/settings', async (req) => ({ values: await readSettings(req.user.id) }));

    r.patch('/v1/settings', async (req, reply) => {
      const { values } = z
        .object({ values: z.record(z.string().regex(SETTING_KEY), z.string().max(MAX_VALUE).nullable()) })
        .parse(req.body);
      if (Object.keys(values).length > 200) return reply.status(400).send({ code: 'bad_request', message: 'too many settings at once' });
      await writeSettings(req.user.id, values);
      return { ok: true };
    });

    // The saved key, without ever revealing the .p8 contents.
    r.get('/v1/appstore/credentials', async () => readAppleCredsPublic());

    // Save or update the key. Send privateKey only when the .p8 itself changes.
    r.put('/v1/appstore/credentials', async (req, reply) => {
      const body = z
        .object({ keyId: z.string().max(40), issuerId: z.string().max(60), privateKey: z.string().max(8000).optional(), teamId: z.string().max(20).optional() })
        .parse(req.body);
      try {
        return await saveAppleCreds(body);
      } catch (e) {
        if (e instanceof AppStoreError) return reply.status(422).send({ code: e.code, message: e.message });
        throw e;
      }
    });

    // Forget the saved key.
    r.delete('/v1/appstore/credentials', async (_req, reply) => {
      await deleteAppleCreds();
      return reply.status(204).send();
    });

    // Check the saved key against App Store Connect (GET /v1/apps).
    r.post('/v1/appstore/credentials/verify', async (_req, reply) => {
      const key = await readAppleKey();
      if (!key) return reply.status(422).send({ code: 'no_key', message: 'Nessuna chiave Apple salvata: caricala prima di verificare.' });
      try {
        const store = await AppStore.open(key);
        const { data } = await store.call<{ data: unknown[] }>('GET', '/apps?limit=1', undefined, 'Verifica connessione');
        // The same key tells which Team signs the iPhone builds.
        let teamId = (await readAppleCreds())?.teamId || '';
        if (!teamId) {
          teamId = (await teamFromAppStore(key, '').catch(() => null)) ?? '';
          if (teamId) await rememberTeamId(teamId).catch(() => {});
        }
        return { ok: true, apps: Array.isArray(data) ? data.length : 0, teamId };
      } catch (e) {
        if (e instanceof AppStoreError) return reply.status(422).send({ code: e.code, message: e.message });
        throw e;
      }
    });

    // The apps this GitHub account saved from Ember, from any computer.
    r.post('/v1/github/apps', async (req, reply) => {
      const { token } = z.object({ token: z.string().min(20).max(400) }).parse(req.body);
      try {
        return { apps: await listEmberApps(token) };
      } catch (e) {
        if (e instanceof GitHubError) return reply.status(422).send({ code: e.code, message: e.message });
        throw e;
      }
    });

    // Bring one of those apps back onto this computer, ready to open.
    r.post('/v1/workspaces/:workspaceId/github/restore', async (req, reply) => {
      const { workspaceId } = req.params as { workspaceId: string };
      const body = z
        .object({ token: z.string().min(20).max(400), repo: z.string().min(1).max(100), owner: z.string().max(100).optional() })
        .parse(req.body);
      const folder = folderName(body.repo);
      const { project, root } = await services.importProject(req.user.id, workspaceId, folder);
      try {
        const { app } = await restoreFromGitHub({ ...body, dest: root });
        return { project: { ...project, title: app } };
      } catch (e) {
        // A half-restored app must not linger in the list.
        await services.deleteProject(req.user.id, project.id).catch(() => {});
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
          translations: z
            .array(
              z.object({
                language: z.string().min(2).max(10),
                title: z.string().max(30).optional(),
                shortDescription: z.string().max(80).optional(),
                fullDescription: z.string().max(4000).optional(),
              }),
            )
            .max(20)
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
            translations: body.translations,
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
          // When the user has configured reviewers, they draw the icons
          // together and then review each other instead of one model working
          // alone and nobody checking it.
          panel: z
            .array(
              z.object({
                id: z.string().min(1).max(40),
                label: z.string().min(1).max(40),
                baseUrl: z.string().url().max(200),
                apiKey: z.string().min(1).max(400),
                model: z.string().min(1).max(80),
              }),
            )
            .max(6)
            .default([]),
        })
        .parse(req.body);
      const claudeOk = await claudeCode.isAvailable();
      const viaClaude = async (system: string, prompt: string) => (await claudeCode.complete({ system, prompt, quality: 'fast' })).text;
      // Drawing a logo has one extra demand on top of a plain answer: what
      // comes back must actually be an SVG, so a model that chatted instead of
      // drawing counts as a miss and the next one is tried.
      const viaGemini = (system: string, prompt: string) => geminiComplete(system, prompt, (t) => t.includes('</svg>'));
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
      const appName = body.appName ?? project.name.replace(/_\d+$/, '').replace(/_/g, ' ');
      // Claude and Gemini join the table on what this machine already has — a
      // login and a key — so the user never fetches anything for them; the app
      // cannot send them, having no key to send.
      const members = [
        ...(claudeOk ? [{ id: 'claude_code', label: 'Claude', complete: viaClaude }] : []),
        ...body.panel.map((m) => ({ id: m.id, label: m.label, complete: (s: string, p: string) => openAiComplete(m, s, p, deps.reviewFetch ?? fetch) })),
        ...(cfg.GEMINI_API_KEY ? [{ id: 'gemini_runner', label: 'Gemini', complete: viaGemini }] : []),
      ];
      const logos =
        members.length > 1
          ? await generateLogosPanel({
              projectRoot: services.projectRoot(project),
              appName,
              about: body.about,
              hint: body.hint,
              count: body.count,
              members,
            })
          : await generateLogos({
              projectRoot: services.projectRoot(project),
              appName,
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

    // Puts the screenshots of a Play Store listing inside the project, as a model
    // for the engine: a described app and a seen app are not the same thing.
    r.post('/v1/projects/:projectId/reference-shots', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const { appId } = z.object({ appId: z.string().regex(/^[A-Za-z][\w]*(\.[\w]+)+$/) }).parse(req.body);
      const page = await fetch(`https://play.google.com/store/apps/details?id=${appId}&hl=en`, {
        headers: { 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/130 Safari/537.36' },
      }).catch(() => null);
      if (!page?.ok) return reply.status(502).send({ code: 'store_unreachable', message: 'Could not read that app page on the Play Store' });
      const shots = parseScreenshots(await page.text());
      return saveReferenceShots(services.projectRoot(project), shots);
    });

    // A website taken as the model for an app: what it offers, its other pages,
    // how it earns, and photographs of it as a phone sees it.
    r.post('/v1/projects/:projectId/site-reference', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const { url, shots } = z.object({ url: z.string().url().max(2000), shots: z.boolean().default(true) }).parse(req.body);
      try {
        const site = await readSite(url);
        let saved = 0;
        const browser = findBrowser();
        if (shots && browser) {
          const urls = [site.url, ...site.pages.slice(0, 3).map((p) => p.url)];
          saved = (await saveSiteShots({ projectRoot: services.projectRoot(project), urls, browser }).catch(() => ({ saved: 0 }))).saved;
        }
        return { site, shotsSaved: saved };
      } catch (e) {
        return reply.status(502).send({ code: 'site_unreachable', message: `Could not read that website: ${(e as Error).message}` });
      }
    });

    // The phones plugged into this computer, so an app can be tried where it counts.
    r.get('/v1/devices', async () => ({ devices: await listDevices(), lanAddress: lanAddress() }));

    r.post('/v1/projects/:projectId/run-on-device', async (req, reply) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const { deviceId } = z.object({ deviceId: z.string().max(80).optional() }).parse(req.body ?? {});
      const root = services.projectRoot(project);
      // Whichever APK was built last: the quick one for trying, the signed one after publishing.
      const candidates = await Promise.all(
        (['app-debug.apk', 'app-release.apk'] as const).map(async (name) => {
          const file = path.join(root, ARTIFACTS[name]!.rel);
          return { file, at: (await stat(file).catch(() => null))?.mtimeMs ?? 0 };
        }),
      );
      const newest = candidates.sort((a, b) => b.at - a.at)[0]!;
      if (newest.at === 0) {
        return reply.status(409).send({ code: 'not_ready', message: 'Build the APK first: Ember installs the file it has built.' });
      }
      const apkPath = newest.file;
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

    // Several models read the finished app, each on its own, and say what is
    // fake, missing or broken. Slow (seconds per model), so it has its own route
    // instead of weighing down the quick check above.
    r.post('/v1/projects/:projectId/review', async (req) => {
      const { projectId } = req.params as { projectId: string };
      const { project } = await services.ownedProject(req.user.id, projectId);
      const { reviewers } = z
        .object({
          reviewers: z
            .array(
              z.object({
                id: z.string().min(1).max(40),
                label: z.string().min(1).max(40),
                baseUrl: z.string().url().max(300),
                apiKey: z.string().min(1).max(400),
                model: z.string().min(1).max(120),
              }),
            )
            .min(0)
            .max(6),
        })
        .parse(req.body);
      // Claude and Gemini read the finished app too, on this machine's own
      // login and key: the app has no key for them to send, but they belong at
      // the table as much as the ones that do.
      const mine = [
        ...((await claudeCode.isAvailable())
          ? [{ id: 'claude_code', label: 'Claude', complete: async (system: string, prompt: string) => (await claudeCode.complete({ system, prompt, quality: 'fast', timeoutMs: 600_000 })).text }]
          : []),
        ...(cfg.GEMINI_API_KEY ? [{ id: 'gemini_runner', label: 'Gemini', complete: geminiComplete }] : []),
      ];
      return reviewApp(services.projectRoot(project), reviewers, deps.reviewFetch ?? fetch, mine);
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
          // The listing in other languages, kept as the JSON the app wrote it in.
          translations: z.string().max(80000).default(''),
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
      const { markdown, appName, email } = z
        .object({ markdown: z.string().min(50).max(60000), appName: z.string().max(80).optional(), email: z.string().max(200).optional() })
        .parse(req.body);
      const root = services.projectRoot(project);
      const dir = path.join(root, 'store');
      await mkdirAsync(dir, { recursive: true });
      const name = appName ?? project.name;
      // A policy with "[EMAIL]" left in it is refused at review: fill the blanks first.
      const listing = JSON.parse(await readFileAsync(path.join(dir, 'listing.json'), 'utf8').catch(() => '{}')) as { contactEmail?: string };
      const filled = fillPolicy(markdown, { name: cfg.STUDIO_NAME || name, email: email || listing.contactEmail || '' });
      await writeFileAsync(path.join(dir, 'privacy_policy.md'), `<!-- ${name} -->\n${filled}`);
      // Google needs an address anyone can open; this computer is not one.
      const publicUrl = await publishPolicy(filled, name).catch(() => null);
      return { path: `/privacy/${project.workspaceId}/${project.id}`, publicUrl };
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

  await registerAiRoutes(app, { cfg, authenticate, upstreams: deps.aiUpstreams, claude: claudeCode });
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
