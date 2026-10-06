import { readFile, rm, stat } from 'node:fs/promises';
import path from 'node:path';
import type { AgentEvent, AgentRun, ClaudeCodeEngine } from '../agent_cli.js';
import type { Config } from '../config.js';
import type { Job } from '../jobs.js';
import { packageName as derivePackage } from '../publish_prep.js';
import type { PreviewService } from '../preview.js';
import type { Services } from '../services.js';
import type { StageContext, StageOp, StageOutcome, Ops } from './engine.js';
import { listingBody, translate, writeKit, type Complete, type Page } from './listing.js';
import { analyzerErrors, codePrompt, declaredFromReply, fixPrompt, needsFromReply, restAfterLimit, USAGE_LIMIT } from './prompts.js';
import { AbortedError } from './scheduler.js';
import { NeedsOwner, RateLimited, type FactoryEngine, type Stage } from './types.js';

/** Everything the real operations need from the running Runner. */
export interface OpsHost {
  cfg: Config;
  services: Services;
  claudeCode: ClaudeCodeEngine;
  preview: PreviewService;
  /** Calls one of this Runner's own routes as [ownerId]. */
  call(ownerId: string, method: 'GET' | 'POST' | 'PUT' | 'DELETE', url: string, body?: unknown): Promise<{ status: number; json: Record<string, unknown> }>;
  /** One answer from the best engine that is connected (listing texts). */
  complete(ownerId: string, system: string, prompt: string): Promise<string>;
  readSettings(ownerId: string): Promise<Record<string, string>>;
  writeSettings(ownerId: string, patch: Record<string, string | null>): Promise<unknown>;
  hasAppleKey(): Promise<boolean>;
  findBrowser(): string | null;
  hasScreenshotMode(root: string): Promise<boolean>;
  freeDiskGb(): Promise<number | null>;
  platform: NodeJS.Platform;
}

/** The name the IDE's session record uses for each engine. */
const SESSION_ENGINE: Record<FactoryEngine, string> = { 'claude-code': 'claudeCode', codex: 'codex', 'gemini-cli': 'geminiCli', 'qwen-code': 'qwenCode' };

/** How many jobs of the Factory's workspace may run at once (the lanes decide the real limit). */
export const WORKSPACE_JOBS = 8;

const tail = (job: Job, lines = 14) => job.log.join('').split(/\r?\n/).filter((l) => l.trim()).slice(-lines).join('\n');

const exists = (p: string) => stat(p).then(() => true, () => false);

const appleCategory = (c: string): string | undefined =>
  ({ productivity: 'PRODUCTIVITY', health: 'HEALTH_AND_FITNESS', finance: 'FINANCE', education: 'EDUCATION', games: 'GAMES', tools: 'UTILITIES', lifestyle: 'LIFESTYLE', travel: 'TRAVEL', music: 'MUSIC', food: 'FOOD_AND_DRINK' })[c.toLowerCase()];

/** The real stage operations for one owner. */
export function realOps(host: OpsHost, ownerId: string, email = ''): Ops {
  const { services } = host;
  let workspace: Promise<string> | null = null;

  /** The owner's first workspace (the one their app list shows), made if it is missing. */
  const workspaceId = (): Promise<string> => {
    workspace ??= (async () => {
      const all = await services.listWorkspaces(ownerId);
      const ws = all[0] ?? (await services.createWorkspace(ownerId, 'default'));
      // Jobs of one workspace run one at a time; the Factory's lanes already limit the real work.
      services.jobs.setWorkspaceLimit(ws.id, WORKSPACE_JOBS);
      return ws.id;
    })();
    return workspace;
  };

  const project = async (ctx: StageContext) => {
    if (!ctx.app.projectId) throw new Error('the app has no project yet');
    return services.ownedProject(ownerId, ctx.app.projectId);
  };
  const rootOf = async (ctx: StageContext) => services.projectRoot((await project(ctx)).project);

  /** Runs a project job (pub get, analyze, a build) and waits for it, stopping it if the app is cancelled. */
  const runJob = async (ctx: StageContext, kind: Parameters<Services['startJob']>[2]): Promise<Job> => {
    const job = await services.startJob(ownerId, ctx.app.projectId!, kind);
    const stop = () => services.jobs.cancel(job.id);
    ctx.signal.addEventListener('abort', stop, { once: true });
    try {
      return await services.jobs.wait(job.id);
    } finally {
      ctx.signal.removeEventListener('abort', stop);
      if (ctx.signal.aborted) throw new AbortedError();
    }
  };

  /** One run of a coding engine in the app's folder, until it finishes. Returns what it said last. */
  const agent = async (ctx: StageContext, prompt: string, resume: boolean): Promise<string> => {
    const engine = ctx.app.engine;
    if (!(await host.claudeCode.isEngineAvailable(engine))) {
      throw new NeedsOwner({ kind: 'login', title: `Sign in to ${engine}`, detail: `${engine} is not connected on this computer.`, data: { engine } });
    }
    const { project: row } = await project(ctx);
    const events: AgentEvent[] = [];
    let files = 0;
    let current: AgentRun | undefined;
    let settle: (run: AgentRun) => void = () => {};
    const finished = new Promise<AgentRun>((resolve) => (settle = resolve));
    // Only this run's events: the engine is shared with every other app and screen.
    const onEvent = (run: AgentRun, ev: AgentEvent) => {
      if (run.id !== current?.id) return;
      events.push(ev);
      if (ev.kind === 'tool') {
        if (ev.name === 'Write' || ev.name === 'Edit' || ev.name === 'MultiEdit') files++;
        ctx.doing(ev.summary ? `${ev.name} ${ev.summary}` : ev.name);
      }
    };
    const onStatus = (run: AgentRun) => {
      if (run.id === current?.id && run.status !== 'running') settle(run);
    };
    const detach = () => {
      host.claudeCode.off('event', onEvent);
      host.claudeCode.off('status', onStatus);
    };
    host.claudeCode.on('event', onEvent);
    host.claudeCode.on('status', onStatus);
    try {
      current = host.claudeCode.start({ ownerId, projectId: row.id, cwd: services.projectRoot(row), prompt, resume, quality: ctx.recipe.quality, engine });
    } catch (e) {
      detach();
      throw e;
    }
    const stop = () => {
      if (!current) return;
      host.claudeCode.cancel(current.id);
      // A process that is already gone sends no last word: do not wait for it for ever.
      const gone = current;
      setTimeout(() => settle(gone), 5000).unref?.();
    };
    ctx.signal.addEventListener('abort', stop, { once: true });
    const run = await finished.finally(detach);
    ctx.signal.removeEventListener('abort', stop);
    if (ctx.signal.aborted) throw new AbortedError();
    const result = [...events].reverse().find((e): e is Extract<AgentEvent, { kind: 'result' }> => e.kind === 'result');
    if (result?.costUsd) ctx.addCost(result.costUsd);
    if (run.status !== 'succeeded' || (result && !result.ok)) {
      const said = events
        .filter((e) => e.kind === 'error' || (e.kind === 'result' && !e.ok))
        .map((e) => (e.kind === 'error' ? e.message : e.kind === 'result' ? e.message : ''))
        .join('\n');
      if (USAGE_LIMIT.test(said)) throw new RateLimited(said.slice(0, 200), restAfterLimit(said), `agent:${engine}`);
      throw new Error(`${engine} did not finish: ${said.slice(0, 400) || run.status}`);
    }
    ctx.log(`${engine}: ${files} files written`);
    const lastText = [...events].reverse().find((e): e is Extract<AgentEvent, { kind: 'text' }> => e.kind === 'text')?.text;
    return result?.message ?? lastText ?? '';
  };

  const create: StageOp = async (ctx) => {
    const ws = await workspaceId();
    // A retry finds its project again; a half-made one is thrown away and made anew.
    if (ctx.app.projectId) {
      const row = await services.store.getProject(ctx.app.projectId);
      if (row?.status === 'ready') return { skipped: 'exists' };
      if (row) await services.deleteProject(ownerId, row.id).catch(() => {});
    }
    let folder = ctx.app.folder;
    for (let n = 2; n < 40; n++) {
      try {
        const { project: row, job } = await services.createProject(ownerId, ws, folder);
        ctx.update({ workspaceId: ws, projectId: row.id, folder, packageName: derivePackage(ctx.app.name, host.cfg.PACKAGE_PREFIX) });
        ctx.doing('flutter create');
        const stop = () => services.jobs.cancel(job.id);
        ctx.signal.addEventListener('abort', stop, { once: true });
        const done = await services.jobs.wait(job.id).finally(() => ctx.signal.removeEventListener('abort', stop));
        if (ctx.signal.aborted) throw new AbortedError();
        if (done.status !== 'succeeded') throw new Error(`flutter create failed:\n${tail(done)}`);
        return { message: folder };
      } catch (e) {
        if ((e as { code?: string }).code !== 'exists') throw e;
        folder = `${ctx.app.folder.slice(0, 36)}_${n}`;
      }
    }
    throw new Error('no free project name');
  };

  const code: StageOp = async (ctx) => {
    ctx.doing(`${ctx.app.engine} is writing the app`);
    const { project: row } = await project(ctx);
    const prompt = codePrompt(ctx.app, ctx.recipe);
    const reply = await agent(ctx, prompt, false);
    const declared = declaredFromReply(reply);
    const needs = needsFromReply(reply);
    for (const n of needs) ctx.log(`needs you: ${n}`);
    // The same record the IDE keeps for an app built by hand, so the app opens with its history.
    await host
      .writeSettings(ownerId, {
        [`ember_session_${row.id}`]: JSON.stringify({
          prompt: ctx.app.brief,
          engine: SESSION_ENGINE[ctx.app.engine],
          quality: ctx.recipe.quality,
          status: 'done',
          products: declared.products,
          ads: declared.ads,
          pending: null,
          needsYou: needs,
          conversation: [
            { role: 'user', text: ctx.app.brief },
            { role: 'assistant', text: declared.text },
          ],
        }),
      })
      .catch(() => {});
    return { message: declared.text.split('\n').find((l) => l.trim() && !l.startsWith('#'))?.slice(0, 160) };
  };

  const verify: StageOp = async (ctx) => {
    for (let round = 0; round <= 2; round++) {
      ctx.doing('flutter pub get');
      const pub = await runJob(ctx, 'pub_get');
      if (pub.status !== 'succeeded') throw new Error(`pub get failed:\n${tail(pub)}`);
      ctx.doing('flutter analyze');
      const job = await runJob(ctx, 'analyze');
      const errors = analyzerErrors(job.log.join(''));
      if (job.status === 'succeeded' && errors.length === 0) return { message: round === 0 ? 'analyze clean' : `analyze clean after ${round} fix${round > 1 ? 'es' : ''}` };
      if (errors.length === 0) throw new Error(`analyze failed:\n${tail(job)}`);
      if (round === 2) throw new Error(`analyze still reports ${errors.length} errors:\n${errors.slice(0, 5).join('\n')}`);
      ctx.doing(`fixing ${errors.length} analyzer errors`);
      await agent(ctx, fixPrompt(errors.slice(0, 40).join('\n')), true);
    }
    throw new Error('unreachable');
  };

  const preview: StageOp = async (ctx) => {
    ctx.doing('flutter build web');
    const { job } = await host.preview.start(ownerId, ctx.app.projectId!, false);
    const stop = () => services.jobs.cancel(job.id);
    ctx.signal.addEventListener('abort', stop, { once: true });
    const done = await services.jobs.wait(job.id).finally(() => ctx.signal.removeEventListener('abort', stop));
    if (ctx.signal.aborted) throw new AbortedError();
    if (done.status !== 'succeeded') throw new Error(`web build failed:\n${tail(done)}`);
    return { message: 'web preview built' };
  };

  const logo: StageOp = async (ctx) => {
    const id = ctx.app.projectId!;
    ctx.doing('drawing logos');
    const only = ctx.recipe.logoBy === 'auto' ? undefined : [ctx.recipe.logoBy];
    const res = await host.call(ownerId, 'POST', `/v1/projects/${id}/logos`, { about: ctx.app.summary, appName: ctx.app.name, count: 3, ...(only ? { only } : {}) });
    const logos = (res.json.logos as Array<{ id: string }> | undefined) ?? [];
    if (res.status !== 200 || logos.length === 0) throw new Error(`no logo: ${String(res.json.message ?? res.status)}`);
    ctx.doing('applying the logo');
    const applied = await host.call(ownerId, 'POST', `/v1/projects/${id}/logos/${logos[0]!.id}/apply`);
    if (applied.status !== 200) throw new Error(`the logo could not be applied: ${String(applied.json.message ?? applied.status)}`);
    return { message: `${logos.length} drawn, first applied` };
  };

  const listing: StageOp = async (ctx) => {
    const { project: row } = await project(ctx);
    const complete: Complete = (system, prompt) => host.complete(ownerId, system, prompt);
    ctx.doing('writing the store page');
    const kit = await writeKit({ complete, name: ctx.app.name, packageName: ctx.app.packageName, description: `${ctx.app.summary}\n\n${ctx.app.brief}`.slice(0, 4000) });
    ctx.doing(`translating into ${ctx.recipe.languages.length - 1} languages`);
    const { pages, failed } = await translate({ complete, kit, languages: ctx.recipe.languages });
    if (failed.length) ctx.log(`no translation for: ${failed.join(', ')}`);
    let privacyUrl = '';
    if (kit.privacyPolicyMarkdown.length >= 50) {
      const p = await host.call(ownerId, 'PUT', `/v1/projects/${row.id}/store/privacy`, { markdown: kit.privacyPolicyMarkdown, appName: ctx.app.name, email });
      privacyUrl = typeof p.json.publicUrl === 'string' ? p.json.publicUrl : '';
    }
    const body = listingBody({ kit, pages, languages: ctx.recipe.languages, email, privacyUrl });
    const saved = await host.call(ownerId, 'PUT', `/v1/projects/${row.id}/store/listing`, body);
    if (saved.status !== 200) throw new Error(`the listing could not be saved: ${String(saved.json.message ?? saved.status)}`);
    return { message: `${Object.keys(pages).length + 1} languages` };
  };

  const shots: StageOp = async (ctx) => {
    const id = ctx.app.projectId!;
    ctx.doing('taking store screenshots');
    let res = await host.call(ownerId, 'POST', `/v1/projects/${id}/screenshots`);
    if (res.status === 409 && res.json.code === 'needs_screenshot_mode') {
      // The engine forgot the screenshot mode: ask for it once, rebuild the preview, try again.
      ctx.doing('adding the screenshot mode');
      await agent(ctx, String(res.json.request ?? 'Add a screenshot mode to this app.'), true);
      await preview(ctx);
      res = await host.call(ownerId, 'POST', `/v1/projects/${id}/screenshots`);
    }
    const list = (res.json.shots as unknown[] | undefined) ?? [];
    if (res.status !== 200 || list.length === 0) throw new Error(`no screenshots: ${String(res.json.message ?? res.status)}`);
    return { message: `${list.length} screenshots` };
  };

  const android: StageOp = async (ctx) => {
    ctx.doing('building the signed bundle');
    const job = await runJob(ctx, 'build_aab');
    if (job.status !== 'succeeded') throw new Error(`android build failed:\n${tail(job)}`);
    const root = await rootOf(ctx);
    if (!(await exists(path.join(root, 'build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab')))) throw new Error('the build finished but there is no app-release.aab');
    return { message: 'app-release.aab' };
  };

  const savedListing = async (ctx: StageContext) => {
    const root = await rootOf(ctx);
    const raw = JSON.parse(await readFile(path.join(root, 'store', 'listing.json'), 'utf8').catch(() => '{}')) as Record<string, string>;
    const t = JSON.parse(raw.translations || '{}') as { pages?: Record<string, Page> };
    return { listing: raw, pages: t.pages ?? {} };
  };

  const play: StageOp = async (ctx) => {
    const id = ctx.app.projectId!;
    const key = (await host.readSettings(ownerId))['play_service_account'];
    if (!key) {
      throw new NeedsOwner({ kind: 'play_key', title: 'Connect Google Play', detail: 'Save the Google Play service account key once; every app then uses it.', data: {} });
    }
    const { listing: l, pages } = await savedListing(ctx);
    const info = await host.call(ownerId, 'GET', `/v1/projects/${id}/android-info`);
    const applicationId = String(info.json.applicationId ?? '');
    ctx.doing('uploading to Google Play (internal testing, draft)');
    const res = await host.call(ownerId, 'POST', `/v1/projects/${id}/play/publish`, {
      serviceAccount: key,
      track: 'internal',
      status: 'draft',
      listing: { language: 'en-US', title: l.title, shortDescription: l.shortDescription, fullDescription: l.fullDescription },
      translations: Object.entries(pages).map(([language, p]) => ({ language, title: p.title, shortDescription: p.shortDescription, fullDescription: p.fullDescription })),
      releaseNotes: { language: 'en-US', text: l.releaseNotes || 'First release.' },
      ...(l.contactEmail || email ? { contactEmail: l.contactEmail || email } : {}),
    });
    if (res.status === 200) return { message: `version ${String(res.json.versionCode ?? '?')} in internal testing` };
    if (res.json.code === 'play_app_not_found') {
      throw new NeedsOwner({
        kind: 'play_console_app',
        title: `Create "${ctx.app.name}" in Play Console`,
        detail: 'Google Play cannot create an app by itself: create it once with this exact package name, then continue.',
        data: { name: ctx.app.name, package: applicationId, shortDescription: l.shortDescription ?? '', category: ctx.app.category || 'tools', language: 'en-US' },
      });
    }
    throw new Error(`Google Play: ${String(res.json.message ?? res.status)}`);
  };

  const ios: StageOp = async (ctx) => {
    if (host.platform !== 'darwin') {
      throw new NeedsOwner({
        kind: 'mac',
        title: 'A Mac is needed for the iPhone file',
        detail: 'Apple only allows building the iPhone app on a Mac. The code is saved: open Ember on your Mac, restore the app from GitHub and continue there.',
        data: { name: ctx.app.name },
      });
    }
    ctx.doing('building the iPhone file');
    const job = await runJob(ctx, 'build_ipa');
    if (job.status !== 'succeeded') throw new Error(`iPhone build failed:\n${tail(job)}`);
    return { message: 'ipa built' };
  };

  const appstore: StageOp = async (ctx) => {
    const id = ctx.app.projectId!;
    if (!(await host.hasAppleKey())) {
      throw new NeedsOwner({ kind: 'apple_key', title: 'Connect App Store Connect', detail: 'Save the App Store Connect key (Key ID, Issuer ID and the .p8 file) once; every app then uses it.', data: {} });
    }
    const { listing: l, pages } = await savedListing(ctx);
    const apple = (language: string, p: { title?: string; shortDescription?: string; fullDescription?: string; releaseNotes?: string }) => ({
      language,
      title: p.title,
      subtitle: (p.shortDescription ?? '').slice(0, 30),
      description: p.fullDescription,
      ...(p.releaseNotes ? { releaseNotes: p.releaseNotes } : {}),
    });
    const category = appleCategory(ctx.app.category);
    const start = await host.call(ownerId, 'POST', `/v1/projects/${id}/appstore/autopublish`, {
      uploadBuild: true,
      // Always TestFlight: nothing is ever sent to Apple's reviewers by the Factory.
      submit: false,
      free: true,
      screenshots: true,
      ...(category ? { category } : {}),
      ...(l.privacyUrl ? { privacyPolicyUrl: l.privacyUrl } : {}),
      listing: apple('en-US', l),
      translations: Object.entries(pages).map(([language, p]) => apple(language, p)),
    });
    if (start.status !== 200) throw new Error(`App Store Connect: ${String(start.json.message ?? start.status)}`);
    // The one-press publish runs in the background on the Runner; follow it until it is done.
    for (let waited = 0; waited < 120 * 60_000; waited += 15_000) {
      if (ctx.signal.aborted) throw new AbortedError();
      await new Promise((r) => setTimeout(r, 15_000));
      const st = (await host.call(ownerId, 'GET', `/v1/projects/${id}/appstore/autopublish`)).json as { phase?: string; message?: string; error?: string };
      if (st.message) ctx.doing(st.message.slice(0, 120));
      if (st.phase === 'done' || st.phase === 'submitted') return { message: 'in TestFlight' };
      if (st.phase === 'failed') {
        const why = st.error ?? st.message ?? 'failed';
        if (/non ha ancora un'app|app_not_found/i.test(why)) {
          throw new NeedsOwner({
            kind: 'apple_app_record',
            title: `Create "${ctx.app.name}" in App Store Connect`,
            detail: 'Apple does not let an app be created by a program: create the app record once, then continue.',
            data: { name: ctx.app.name, bundleId: ctx.app.packageName ?? '', sku: ctx.app.folder },
          });
        }
        throw new Error(`App Store Connect: ${why.slice(0, 400)}`);
      }
    }
    throw new Error('App Store Connect did not finish in two hours');
  };

  const stages: Partial<Record<Stage, StageOp>> = { create, code, verify, preview, logo, listing, shots, android, play, ios, appstore };

  /** What an app no longer needs once it is finished: the big build folders (the web preview stays). */
  const cleanup = async (app: { projectId?: string }) => {
    if (!app.projectId) return;
    const row = await services.store.getProject(app.projectId);
    if (!row) return;
    const root = services.projectRoot(row);
    for (const rel of [['build', 'app'], ['build', 'ios'], ['android', '.gradle'], ['ios', 'Pods'], ['.dart_tool']]) await rm(path.join(root, ...rel), { recursive: true, force: true }).catch(() => {});
  };

  return {
    stages,
    freeDiskGb: async () => (await host.freeDiskGb()) ?? Infinity,
    cleanup,
    remove: async (app) => {
      if (app.projectId) await services.deleteProject(ownerId, app.projectId).catch(() => {});
    },
  };
}
