import { EventEmitter } from 'node:events';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { AgentEvent, AgentRun } from '../agent_cli.js';
import type { Job } from '../jobs.js';
import type { StageContext } from './engine.js';
import { realOps, type OpsHost } from './ops.js';
import { NeedsOwner, RateLimited, defaultRecipe, emptyStages, type FactoryApp } from './types.js';

let dir: string;
beforeAll(async () => {
  dir = await mkdtemp(path.join(os.tmpdir(), 'factory-ops-'));
});
afterAll(async () => {
  await rm(dir, { recursive: true, force: true });
});

const job = (status: Job['status'], log = ''): Job => ({ id: 'j', kind: 'analyze', ownerId: 'u', workspaceId: 'w', projectId: 'p', cwd: '', cmd: '', args: [], id_: undefined, status, exitCode: status === 'succeeded' ? 0 : 1, createdAt: '', finishedAt: '', log: [log] }) as unknown as Job;

interface Scripted {
  /** What each analyze job says, in order. */
  analyze: Job[];
  agentRuns: Array<{ events: AgentEvent[]; status: AgentRun['status'] }>;
  calls: Array<{ method: string; url: string; body?: unknown }>;
  routes: Record<string, (body: unknown) => { status: number; json: Record<string, unknown> }>;
  jobsStarted: string[];
  settings: Record<string, string>;
  written: Record<string, string>;
  createCalls: string[];
  existing: Set<string>;
  prompts: string[];
}

function fake(over: Partial<{ platform: NodeJS.Platform; androidReady: boolean; appleKey: boolean; engineOk: boolean; complete: (s: string, p: string) => string }> = {}) {
  const scripted: Scripted = { analyze: [], agentRuns: [], calls: [], routes: {}, jobsStarted: [], settings: {}, written: {}, createCalls: [], existing: new Set(), prompts: [] };
  const claudeCode = Object.assign(new EventEmitter(), {
    isEngineAvailable: async () => over.engineOk ?? true,
    cancel: () => true,
    start(opts: { prompt: string }) {
      scripted.prompts.push(opts.prompt);
      const script = scripted.agentRuns.shift() ?? { events: [{ kind: 'result', ok: true, costUsd: 0.5, turns: 3, message: '## Fatto\n- ok\nEMBER_PRODUCTS: [{"id":"premium","type":"inapp"}]\nNEEDS YOU: paste the Firebase key' } as AgentEvent], status: 'succeeded' as const };
      const run = { id: `r${scripted.prompts.length}`, status: 'running' } as AgentRun;
      setTimeout(() => {
        for (const ev of script.events) claudeCode.emit('event', run, ev);
        run.status = script.status;
        claudeCode.emit('status', run);
      }, 1);
      return run;
    },
  });
  const jobs = Object.assign(new EventEmitter(), {
    setWorkspaceLimit: () => {},
    cancel: () => true,
    wait: async (id: string) => {
      const kind = id.split(':')[0]!;
      if (kind === 'analyze') return scripted.analyze.shift() ?? job('succeeded');
      return job('succeeded', 'ok');
    },
  });
  const services = {
    jobs,
    store: { getProject: async (id: string) => (scripted.existing.has(id) ? { id, status: 'ready' } : null) },
    listWorkspaces: async () => [{ id: 'w1' }],
    createWorkspace: async () => ({ id: 'w1' }),
    createProject: async (_o: string, _w: string, folder: string) => {
      scripted.createCalls.push(folder);
      if (folder === 'taken' || folder === 'taken_2') throw Object.assign(new Error('exists'), { code: 'exists' });
      return { project: { id: `p_${folder}`, name: folder, workspaceId: 'w1' }, job: { id: `create:${folder}` } };
    },
    ownedProject: async (_o: string, id: string) => ({ project: { id, name: id, workspaceId: 'w1' }, workspace: {} }),
    projectRoot: () => dir,
    deleteProject: async () => {},
    startJob: async (_o: string, _p: string, kind: string) => {
      scripted.jobsStarted.push(kind);
      return { id: `${kind}:1` };
    },
  };
  const host: OpsHost = {
    cfg: { PACKAGE_PREFIX: 'com.emberapps' } as OpsHost['cfg'],
    services: services as unknown as OpsHost['services'],
    claudeCode: claudeCode as unknown as OpsHost['claudeCode'],
    preview: { start: async () => ({ job: { id: 'build_web:1' }, info: {} }) } as unknown as OpsHost['preview'],
    call: async (_o, method, url, body) => {
      scripted.calls.push({ method, url, body });
      const key = Object.keys(scripted.routes).find((k) => `${method} ${url}`.endsWith(k));
      return key ? scripted.routes[key]!(body) : { status: 200, json: {} };
    },
    complete: async (_o, s, p) => (over.complete ? over.complete(s, p) : JSON.stringify({ title: 'X', shortDescription: 'Short text', fullDescription: 'Long text', releaseNotes: 'Notes', privacyPolicyMarkdown: 'p'.repeat(80), dataSafetyGuide: 'd', contentRatingGuide: 'c', otherDeclarationsGuide: 'o' })),
    readSettings: async () => scripted.settings,
    writeSettings: async (_o, patch) => void Object.assign(scripted.written, patch),
    hasAppleKey: async () => over.appleKey ?? true,
    findBrowser: () => 'chrome',
    androidReady: () => over.androidReady ?? true,
    hasScreenshotMode: async () => true,
    freeDiskGb: async () => 100,
    platform: over.platform ?? 'win32',
    pollMs: 5,
  };
  return { host, scripted };
}

function ctxFor(over: Partial<FactoryApp> = {}): StageContext & { logs: string[]; updates: Array<Record<string, unknown>>; doings: string[]; cost: number } {
  const app: FactoryApp = {
    id: 'a1', batchId: 'b1', order: 0, name: 'Water Today', summary: 'Reminds you to drink water', brief: 'Build a water reminder with notifications and a history chart', size: 'small', category: 'health',
    folder: 'water_today', engine: 'claude-code', state: 'running', stages: emptyStages(), needs: [], log: [], costUsd: 0, createdAt: '', updatedAt: '', projectId: 'p_water_today', workspaceId: 'w1', ...over,
  };
  const out = {
    app, batch: { id: 'b1', name: 'B', createdAt: '', recipe: defaultRecipe(), appIds: ['a1'] }, recipe: { ...defaultRecipe(), languages: ['en-US', 'it-IT', 'es-ES', 'fr-FR', 'de-DE'] }, settings: {} as never,
    signal: new AbortController().signal, logs: [] as string[], updates: [] as Array<Record<string, unknown>>, doings: [] as string[], cost: 0,
    log(l: string) { out.logs.push(l); }, doing(t: string) { out.doings.push(t); }, update(p: Record<string, unknown>) { out.updates.push(p); Object.assign(app, p); }, addCost(u: number) { out.cost += u; },
  };
  return out as unknown as ReturnType<typeof ctxFor>;
}

describe('real operations', () => {
  it('create: makes the project, and picks another folder when the name is taken', async () => {
    const { host, scripted } = fake();
    const ops = realOps(host, 'u', 'me@x.dev');
    const ctx = ctxFor({ folder: 'taken', projectId: undefined });
    await ops.stages.create!(ctx);
    expect(scripted.createCalls).toEqual(['taken', 'taken_2', 'taken_3']);
    expect(ctx.updates.at(-1)).toMatchObject({ folder: 'taken_3', projectId: 'p_taken_3', workspaceId: 'w1', packageName: 'com.emberapps.watertoday' });
  });

  it('create: a project that is already ready is kept', async () => {
    const { host, scripted } = fake();
    scripted.existing.add('p_water_today');
    const res = await realOps(host, 'u').stages.create!(ctxFor());
    expect(res).toEqual({ skipped: 'exists' });
    expect(scripted.createCalls).toEqual([]);
  });

  it('code: sends the brief with the studio rules, saves the session the IDE reads, and counts the cost', async () => {
    const { host, scripted } = fake();
    const ctx = ctxFor();
    await realOps(host, 'u').stages.code!(ctx);
    const prompt = scripted.prompts[0]!;
    expect(prompt).toContain('Build a water reminder');
    expect(prompt).toContain('APP NAME: "Water Today"');
    expect(prompt).toContain('NOBODY TO ANSWER QUESTIONS');
    expect(prompt).toContain('LANGUAGES');
    expect(ctx.cost).toBe(0.5);
    const session = JSON.parse(scripted.written['ember_session_p_water_today']!) as Record<string, unknown>;
    expect(session).toMatchObject({ engine: 'claudeCode', status: 'done', needsYou: ['paste the Firebase key'], products: [{ id: 'premium', type: 'inapp' }] });
    expect(JSON.stringify(session.conversation)).not.toContain('EMBER_PRODUCTS');
    expect(ctx.logs.some((l) => l.includes('needs you: paste the Firebase key'))).toBe(true);
  });

  it('code: asks the owner to sign in when the engine is not connected', async () => {
    const { host } = fake({ engineOk: false });
    await expect(realOps(host, 'u').stages.code!(ctxFor({ engine: 'qwen-code' }))).rejects.toMatchObject({ need: { kind: 'login', data: { engine: 'qwen-code' } } });
  });

  it('code: a usage limit rests that engine instead of failing the app', async () => {
    const { host, scripted } = fake();
    scripted.agentRuns.push({ events: [{ kind: 'error', message: 'Claude AI usage limit reached. Try again in 90 minutes.' }], status: 'failed' });
    const err = await realOps(host, 'u').stages.code!(ctxFor()).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(RateLimited);
    expect(err).toMatchObject({ lane: 'agent:claude-code', retryAfterMs: 91 * 60_000 });
  });

  it('code: another failure is an ordinary error', async () => {
    const { host, scripted } = fake();
    scripted.agentRuns.push({ events: [{ kind: 'error', message: 'segfault' }], status: 'failed' });
    await expect(realOps(host, 'u').stages.code!(ctxFor())).rejects.toThrow(/did not finish: segfault/);
  });

  it('verify: gives the analyzer errors back to the engine, then passes', async () => {
    const { host, scripted } = fake();
    scripted.analyze.push(job('failed', "  error • Undefined name 'x' • lib/main.dart:3:1 • undefined_identifier\n  error • Missing import • lib/a.dart:1:1 • uri_does_not_exist"), job('succeeded', 'No issues found!'));
    const res = await realOps(host, 'u').stages.verify!(ctxFor());
    expect(res).toMatchObject({ message: 'analyze clean after 1 fix' });
    expect(scripted.prompts).toHaveLength(1);
    expect(scripted.prompts[0]).toContain("Undefined name 'x'");
    expect(scripted.jobsStarted).toEqual(['pub_get', 'analyze', 'pub_get', 'analyze']);
  });

  it('verify: gives up after two rounds of fixes', async () => {
    const { host, scripted } = fake();
    for (let i = 0; i < 3; i++) scripted.analyze.push(job('failed', '  error • still broken • lib/main.dart:1:1 • x'));
    await expect(realOps(host, 'u').stages.verify!(ctxFor())).rejects.toThrow(/still reports 1 errors/);
    expect(scripted.prompts).toHaveLength(2);
  });

  it('logo: draws, then applies the first one, by the engine the batch chose', async () => {
    const { host, scripted } = fake();
    scripted.routes['/logos'] = () => ({ status: 200, json: { logos: [{ id: 'l1' }, { id: 'l2' }] } });
    const ctx = ctxFor();
    ctx.recipe.logoBy = 'codex';
    await realOps(host, 'u').stages.logo!(ctx);
    expect(scripted.calls[0]).toMatchObject({ method: 'POST', url: '/v1/projects/p_water_today/logos', body: { appName: 'Water Today', count: 3, only: ['codex'] } });
    expect(scripted.calls[1]).toMatchObject({ url: '/v1/projects/p_water_today/logos/l1/apply' });
  });

  it('listing: writes the page, translates it, publishes the privacy policy and saves in the IDE format', async () => {
    const { host, scripted } = fake({
      complete: (system, prompt) => {
        if (system.includes('translate')) {
          const langs = /into these languages: ([^.]+)\./.exec(prompt)![1]!.split(', ');
          return JSON.stringify(Object.fromEntries(langs.map((l) => [l, { shortDescription: `short ${l}`, fullDescription: `full ${l}` }])));
        }
        return JSON.stringify({ title: 'Wrong', shortDescription: 'Drink water on time', fullDescription: 'Never forget to drink.', releaseNotes: 'First', privacyPolicyMarkdown: 'p'.repeat(80), dataSafetyGuide: 'd', contentRatingGuide: 'c', otherDeclarationsGuide: 'o' });
      },
    });
    scripted.routes['/store/privacy'] = () => ({ status: 200, json: { publicUrl: 'https://example.org/p' } });
    const ctx = ctxFor();
    await realOps(host, 'u', 'me@x.dev').stages.listing!(ctx);
    const put = scripted.calls.find((c) => c.url.endsWith('/store/listing'))!.body as Record<string, string>;
    // The owner's name is kept whatever the writer proposed.
    expect(put).toMatchObject({ title: 'Water Today', shortDescription: 'Drink water on time', contactEmail: 'me@x.dev', privacyUrl: 'https://example.org/p' });
    const t = JSON.parse(put.translations!) as { languages: string[]; pages: Record<string, { title: string; shortDescription: string }>; from: string };
    expect(t.languages).toEqual(['it-IT', 'es-ES', 'fr-FR', 'de-DE']);
    expect(t.pages['it-IT']).toMatchObject({ title: 'Water Today', shortDescription: 'short it-IT' });
    expect(t.from).toBe('Water Today\u0001Drink water on time\u0001Never forget to drink.');
  });

  it('android: without the SDK the owner is told once, in words, instead of a Gradle failure', async () => {
    await expect(realOps(fake({ androidReady: false }).host, 'u').stages.android!(ctxFor())).rejects.toMatchObject({ need: { kind: 'android_sdk' } });
  });

  it('android: builds the bundle and checks the file exists', async () => {
    const { host } = fake();
    await expect(realOps(host, 'u').stages.android!(ctxFor())).rejects.toThrow(/no app-release.aab/);
    await mkdir(path.join(dir, 'build', 'app', 'outputs', 'bundle', 'release'), { recursive: true });
    await writeFile(path.join(dir, 'build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab'), 'x');
    await expect(realOps(host, 'u').stages.android!(ctxFor())).resolves.toMatchObject({ message: 'app-release.aab' });
  });

  describe('play', () => {
    const saveListing = async () => {
      await mkdir(path.join(dir, 'store'), { recursive: true });
      await writeFile(
        path.join(dir, 'store', 'listing.json'),
        JSON.stringify({ title: 'Water Today', shortDescription: 'Short', fullDescription: 'Full', releaseNotes: 'Notes', contactEmail: 'me@x.dev', translations: JSON.stringify({ pages: { 'it-IT': { title: 'Water Today', shortDescription: 'Corto', fullDescription: 'Lungo' } } }) }),
      );
    };

    it('asks for the Play key first', async () => {
      const { host } = fake();
      await expect(realOps(host, 'u').stages.play!(ctxFor())).rejects.toMatchObject({ need: { kind: 'play_key' } });
    });

    it('uploads to the internal track as a draft, never to production, with the saved texts', async () => {
      await saveListing();
      const { host, scripted } = fake();
      scripted.settings['play_service_account'] = '{"type":"service_account"}';
      scripted.routes['/android-info'] = () => ({ status: 200, json: { applicationId: 'com.emberapps.watertoday' } });
      scripted.routes['/play/publish'] = () => ({ status: 200, json: { versionCode: 7 } });
      const res = await realOps(host, 'u').stages.play!(ctxFor());
      expect(res).toMatchObject({ message: 'version 7 in internal testing' });
      const body = scripted.calls.find((c) => c.url.endsWith('/play/publish'))!.body as Record<string, any>;
      expect(body).toMatchObject({ track: 'internal', status: 'draft', listing: { language: 'en-US', title: 'Water Today' }, releaseNotes: { text: 'Notes' }, contactEmail: 'me@x.dev' });
      expect(body.translations).toEqual([{ language: 'it-IT', title: 'Water Today', shortDescription: 'Corto', fullDescription: 'Lungo' }]);
    });

    it('says what to create in Play Console when Google does not know the app yet', async () => {
      await saveListing();
      const { host, scripted } = fake();
      scripted.settings['play_service_account'] = '{"type":"service_account"}';
      scripted.routes['/android-info'] = () => ({ status: 200, json: { applicationId: 'com.emberapps.watertoday' } });
      scripted.routes['/play/publish'] = () => ({ status: 422, json: { code: 'play_app_not_found', message: 'app not found' } });
      const err = await realOps(host, 'u').stages.play!(ctxFor()).catch((e: unknown) => e);
      expect(err).toBeInstanceOf(NeedsOwner);
      expect((err as NeedsOwner).need).toMatchObject({ kind: 'play_console_app', data: { name: 'Water Today', package: 'com.emberapps.watertoday', shortDescription: 'Short', category: 'health' } });
    });

    it('any other answer from Google is an error', async () => {
      await saveListing();
      const { host, scripted } = fake();
      scripted.settings['play_service_account'] = '{"type":"service_account"}';
      scripted.routes['/play/publish'] = () => ({ status: 422, json: { code: 'x', message: 'APK too large' } });
      await expect(realOps(host, 'u').stages.play!(ctxFor())).rejects.toThrow('Google Play: APK too large');
    });
  });

  it('ios: on Windows the owner is told a Mac is needed; on a Mac it builds', async () => {
    await expect(realOps(fake().host, 'u').stages.ios!(ctxFor())).rejects.toMatchObject({ need: { kind: 'mac' } });
    const mac = fake({ platform: 'darwin' });
    await expect(realOps(mac.host, 'u').stages.ios!(ctxFor())).resolves.toMatchObject({ message: 'ipa built' });
    expect(mac.scripted.jobsStarted).toEqual(['build_ipa']);
  });

  describe('appstore', () => {
    it('asks for the Apple key first', async () => {
      await expect(realOps(fake({ appleKey: false }).host, 'u').stages.appstore!(ctxFor())).rejects.toMatchObject({ need: { kind: 'apple_key' } });
    });

    it('sends to TestFlight, never for review, and waits for the background publish', async () => {
      const { host, scripted } = fake();
      scripted.routes['/appstore/autopublish'] = (() => {
        let polls = 0;
        return (body: unknown) => (body ? { status: 200, json: { phase: 'building' } } : { status: 200, json: { phase: ++polls > 0 ? 'done' : 'building', message: 'ok' } });
      })();
      const res = await realOps(host, 'u').stages.appstore!(ctxFor());
      expect(res).toMatchObject({ message: 'in TestFlight' });
      const body = scripted.calls.find((c) => c.method === 'POST')!.body as Record<string, any>;
      expect(body).toMatchObject({ uploadBuild: true, submit: false, free: true, category: 'HEALTH_AND_FITNESS' });
    }, 30_000);

    it('says to create the app record when Apple does not know the app', async () => {
      const { host, scripted } = fake();
      scripted.routes['/appstore/autopublish'] = (body: unknown) => (body ? { status: 200, json: {} } : { status: 200, json: { phase: 'failed', error: "App Store Connect non ha ancora un'app con Bundle ID com.emberapps.watertoday." } });
      const err = await realOps(host, 'u').stages.appstore!(ctxFor({ packageName: 'com.emberapps.watertoday' })).catch((e: unknown) => e);
      expect((err as NeedsOwner).need).toMatchObject({ kind: 'apple_app_record', data: { name: 'Water Today', bundleId: 'com.emberapps.watertoday' } });
    }, 30_000);
  });

  it('cleanup: only the heavy build folders go, the web preview stays', async () => {
    const root = await mkdtemp(path.join(dir, 'clean-'));
    for (const rel of [['build', 'app'], ['build', 'web'], ['.dart_tool'], ['lib']]) await mkdir(path.join(root, ...rel), { recursive: true });
    await writeFile(path.join(root, 'build', 'web', 'index.html'), 'x');
    const { host } = fake();
    (host.services as unknown as { projectRoot: () => string }).projectRoot = () => root;
    (host.services.store as unknown as { getProject: () => Promise<unknown> }).getProject = async () => ({ id: 'p', name: 'x', workspaceId: 'w' });
    await realOps(host, 'u').cleanup!({ projectId: 'p' } as FactoryApp);
    await expect(readFile(path.join(root, 'build', 'web', 'index.html'), 'utf8')).resolves.toBe('x');
    await expect(readFile(path.join(root, 'lib'), 'utf8')).rejects.toThrow(/EISDIR/);
    await expect(readFile(path.join(root, 'build', 'app'), 'utf8')).rejects.toThrow(/ENOENT/);
  });
});
