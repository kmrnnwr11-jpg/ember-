import { describe, expect, it } from 'vitest';
import { Factory, type Ops, type StageOp } from './engine.js';
import { MemoryStateStore } from './state_store.js';
import { DEPS, NeedsOwner, RateLimited, STAGES, dayKey, laneOf, type Idea, type Recipe, type Stage } from './types.js';

const tick = (ms = 2) => new Promise((r) => setTimeout(r, ms));
const ideas = (n: number): Idea[] => Array.from({ length: n }, (_, i) => ({ name: `App ${i + 1}`, summary: `Does thing number ${i + 1} for people` }));

interface Probe {
  /** Every start and finish, in order. */
  events: Array<{ app: string; stage: Stage; what: 'start' | 'end' }>;
  peak: Record<string, number>;
  live: Record<string, number>;
}

/** Fake operations that take a few milliseconds and record how many ran together per lane. */
function fakeOps(over: Partial<Record<Stage, StageOp>> = {}, ms = 3): { ops: Ops; probe: Probe } {
  const probe: Probe = { events: [], peak: {}, live: {} };
  const stages: Partial<Record<Stage, StageOp>> = {};
  for (const stage of STAGES) {
    stages[stage] =
      over[stage] ??
      (async (ctx) => {
        const lane = laneOf(stage, ctx.app.engine);
        probe.live[lane] = (probe.live[lane] ?? 0) + 1;
        probe.peak[lane] = Math.max(probe.peak[lane] ?? 0, probe.live[lane]!);
        probe.events.push({ app: ctx.app.name, stage, what: 'start' });
        await tick(ms);
        probe.live[lane]!--;
        probe.events.push({ app: ctx.app.name, stage, what: 'end' });
        return { message: `${stage} ok` };
      });
  }
  return { ops: { stages }, probe };
}

const starts = (probe: Probe, app?: string) => probe.events.filter((e) => e.what === 'start' && (!app || e.app === app)).map((e) => e.stage);

async function make(ops: Ops, recipe: Partial<Recipe> = {}, n = 3, store = new MemoryStateStore(), now?: () => number) {
  const factory = new Factory({ store, ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick, now });
  await factory.init();
  factory.updateSettings({ dailyStoreCap: { play: 1000, appstore: 1000 } });
  const batch = factory.addBatch({ name: 'Test', ideas: ideas(n), recipe: { goal: 'ios', ...recipe } });
  return { factory, batch, store };
}

describe('Factory', () => {
  it('takes every app through every stage', async () => {
    const { ops, probe } = fakeOps();
    const { factory } = await make(ops, {}, 4);
    await factory.idle();
    expect(factory.summary()).toMatchObject({ total: 4, done: 4, failed: 0, running: 0, queued: 0, progress: 1, onPlay: 4, onAppStore: 4 });
    for (const app of factory.apps()) {
      expect(STAGES.every((st) => app.stages[st].state === 'done')).toBe(true);
      expect([...starts(probe, app.name)].sort()).toEqual([...STAGES].sort());
    }
  });

  it('starts a stage only after everything it needs is finished', async () => {
    const { ops, probe } = fakeOps();
    const { factory } = await make(ops, {}, 3);
    await factory.idle();
    for (const app of factory.apps()) {
      const mine = probe.events.filter((e) => e.app === app.name);
      for (const stage of STAGES) {
        const start = mine.findIndex((e) => e.stage === stage && e.what === 'start');
        for (const dep of DEPS[stage]) {
          const end = mine.findIndex((e) => e.stage === dep && e.what === 'end');
          expect(end, `${app.name}: ${stage} needs ${dep}`).toBeGreaterThan(-1);
          expect(start, `${app.name}: ${stage} after ${dep}`).toBeGreaterThan(end);
        }
      }
    }
  });

  it('runs the logo, the preview and the store texts of one app side by side', async () => {
    const { ops, probe } = fakeOps({}, 15);
    const { factory } = await make(ops, {}, 1);
    await factory.idle();
    const e = probe.events;
    const at = (stage: Stage, what: 'start' | 'end') => e.findIndex((x) => x.stage === stage && x.what === what);
    // All three started before any of them ended.
    const firstEnd = Math.min(at('logo', 'end'), at('listing', 'end'), at('preview', 'end'));
    expect(Math.max(at('logo', 'start'), at('listing', 'start'), at('preview', 'start'))).toBeLessThan(firstEnd);
    // And the iPhone side runs while the Android side is still going on.
    expect(at('ios', 'start')).toBeLessThan(at('play', 'end'));
  });

  it('never exceeds the limit of a lane, however many apps wait', async () => {
    const { ops, probe } = fakeOps();
    const { factory } = await make(ops, {}, 20);
    factory.updateSettings({ lanes: { build: 2, 'agent:claude-code': 3 }, maxInFlight: 20 });
    await factory.idle();
    expect(factory.summary().done).toBe(20);
    expect(probe.peak.build).toBeLessThanOrEqual(2);
    expect(probe.peak['agent:claude-code']).toBeLessThanOrEqual(3);
    expect(probe.peak['agent:claude-code']).toBeGreaterThan(1);
  });

  it('keeps no more apps in flight than the limit', async () => {
    let inFlight = 0;
    let peak = 0;
    const { ops } = fakeOps({
      create: async () => {
        inFlight++;
        peak = Math.max(peak, inFlight);
        await tick(3);
      },
      appstore: async () => {
        inFlight--;
      },
    });
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await factory.init();
    factory.updateSettings({ maxInFlight: 3, dailyStoreCap: { play: 1000, appstore: 1000 } });
    factory.addBatch({ name: 'B', ideas: ideas(12), recipe: { goal: 'ios' } });
    await factory.idle();
    expect(factory.summary().done).toBe(12);
    expect(peak).toBeLessThanOrEqual(3);
  });

  it('finishes earlier apps first: deeper stages go before new apps are opened', async () => {
    const { ops, probe } = fakeOps({}, 4);
    const { factory } = await make(ops, {}, 6);
    factory.updateSettings({ lanes: { light: 1, build: 1, text: 1, image: 1, shots: 1, store: 1, 'agent:claude-code': 1 }, maxInFlight: 6 });
    await factory.idle();
    const idx = (app: string, stage: Stage, what: 'start' | 'end') => probe.events.findIndex((x) => x.app === app && x.stage === stage && x.what === what);
    expect(idx('App 1', 'appstore', 'end')).toBeGreaterThan(-1);
    expect(idx('App 1', 'appstore', 'end')).toBeLessThan(idx('App 6', 'appstore', 'end'));
    expect(factory.summary().done).toBe(6);
  });

  it('stops only the app that fails, after its attempts, and the others go on', async () => {
    let attempts = 0;
    const { ops } = fakeOps({
      code: async (ctx) => {
        if (ctx.app.name === 'App 2') {
          attempts++;
          throw new Error('flutter analyze: 3 errors');
        }
      },
    });
    const { factory } = await make(ops, { maxAttempts: 2 }, 4);
    await factory.idle();
    const bad = factory.apps().find((a) => a.name === 'App 2')!;
    expect(bad.state).toBe('failed');
    expect(bad.errorStage).toBe('code');
    expect(bad.error).toContain('3 errors');
    expect(attempts).toBe(2);
    expect(bad.stages.verify.state).toBe('pending');
    expect(factory.summary()).toMatchObject({ done: 3, failed: 1 });
  });

  it('lets the independent stages of an app finish when one of them fails', async () => {
    const { ops } = fakeOps({
      logo: async () => {
        throw new Error('no AI drew anything');
      },
    });
    const { factory } = await make(ops, { maxAttempts: 1 }, 1);
    await factory.idle();
    const app = factory.apps()[0]!;
    expect(app.state).toBe('failed');
    expect(app.errorStage).toBe('logo');
    // The preview, the screenshots and the store texts did not wait for the logo.
    expect(app.stages.preview.state).toBe('done');
    expect(app.stages.shots.state).toBe('done');
    expect(app.stages.listing.state).toBe('done');
    // What needs the logo did not start.
    expect(app.stages.android.state).toBe('pending');
    expect(app.stages.ios.state).toBe('pending');
  });

  it('tries again on its own when the second attempt works', async () => {
    let calls = 0;
    const { ops } = fakeOps({
      verify: async () => {
        if (++calls === 1) throw new Error('flaky');
      },
    });
    const { factory } = await make(ops, { maxAttempts: 2 }, 1);
    await factory.idle();
    expect(factory.summary().done).toBe(1);
    expect(factory.apps()[0]!.stages.verify.attempts).toBe(2);
  });

  it('retries a failed app from the stage that failed, not from the start', async () => {
    let broken = true;
    const { ops, probe } = fakeOps({
      logo: async () => {
        if (broken) throw new Error('no AI');
      },
    });
    const { factory } = await make(ops, { maxAttempts: 1 }, 1);
    await factory.idle();
    const app = factory.apps()[0]!;
    expect(app.state).toBe('failed');
    const before = probe.events.length;
    broken = false;
    expect(factory.retryApp(app.id)).toBe(true);
    await factory.idle();
    expect(factory.apps()[0]!.state).toBe('done');
    const again = probe.events.slice(before).filter((e) => e.what === 'start').map((e) => e.stage);
    expect(again).not.toContain('create');
    expect(again).not.toContain('code');
    expect(again).not.toContain('preview');
    expect(again).toContain('android');
    expect(again).toContain('ios');
  });

  it('puts an app that needs the owner aside without holding a slot, then goes on when told', async () => {
    let resolved = false;
    const { ops } = fakeOps({
      play: async (ctx) => {
        if (!resolved && ctx.app.name === 'App 1') {
          throw new NeedsOwner({ kind: 'play_console_app', title: 'Create the app in Play Console', detail: 'x', data: { name: ctx.app.name } });
        }
      },
    });
    const { factory } = await make(ops, { goal: 'android' }, 3);
    factory.updateSettings({ maxInFlight: 1 });
    await factory.idle();
    // maxInFlight is 1 and App 1 is waiting for the owner: the other two still got done.
    expect(factory.summary()).toMatchObject({ needsYou: 1, done: 2 });
    const open = factory.needsYou();
    expect(open).toHaveLength(1);
    expect(open[0]).toMatchObject({ kind: 'play_console_app', appName: 'App 1', stage: 'play' });
    resolved = true;
    expect(factory.resolveNeed(open[0]!.appId, open[0]!.id)).toBe(true);
    await factory.idle();
    expect(factory.summary()).toMatchObject({ needsYou: 0, done: 3 });
    expect(factory.apps()[0]!.stages.play.state).toBe('done');
  });

  it('does not let a Play problem hold the iPhone side back', async () => {
    const { ops } = fakeOps({
      play: async () => {
        throw new NeedsOwner({ kind: 'play_console_app', title: 'Create the app in Play Console', detail: '', data: {} });
      },
    });
    const { factory } = await make(ops, {}, 1);
    await factory.idle();
    const app = factory.apps()[0]!;
    expect(app.state).toBe('needs_you');
    expect(app.stages.play.state).toBe('blocked');
    expect(app.stages.ios.state).toBe('done');
    expect(app.stages.appstore.state).toBe('done');
  });

  it('counts a stage as skipped when the owner chooses to skip it', async () => {
    const { ops } = fakeOps({
      ios: async () => {
        throw new NeedsOwner({ kind: 'mac', title: 'A Mac is needed', detail: '', data: {} });
      },
    });
    const { factory } = await make(ops, {}, 1);
    await factory.idle();
    const [need] = factory.needsYou();
    expect(need!.kind).toBe('mac');
    factory.resolveNeed(need!.appId, need!.id, { skip: true });
    await factory.idle();
    const app = factory.apps()[0]!;
    expect(app.stages.ios.state).toBe('skipped');
    expect(app.stages.appstore.state).toBe('done');
    expect(app.state).toBe('done');
  });

  it('moves an app to another engine of the batch when one reaches its usage limit', async () => {
    const used: string[] = [];
    const { ops } = fakeOps({
      code: async (ctx) => {
        used.push(ctx.app.engine);
        if (ctx.app.engine === 'claude-code') throw new RateLimited('limit', 60_000, 'agent:claude-code');
      },
    });
    const { factory } = await make(ops, { engines: { 'claude-code': 1, 'qwen-code': 1 } }, 2);
    await factory.idle();
    expect(factory.summary().done).toBe(2);
    expect(factory.apps().every((a) => a.engine === 'qwen-code')).toBe(true);
    expect(used).toContain('claude-code');
    expect(factory.lanes.isLanePaused('agent:claude-code')).toBe(true);
  });

  it('shares apps among engines by weight, the big ones to the strongest', async () => {
    const { ops } = fakeOps();
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await factory.init();
    factory.setPaused(true);
    const list: Idea[] = Array.from({ length: 9 }, (_, i) => ({ name: `Big ${i}`, summary: 'a product with accounts', size: i < 3 ? 'big' : 'small' }));
    factory.addBatch({ name: 'B', ideas: list, recipe: { engines: { 'claude-code': 1, 'gemini-cli': 2 } } });
    const mine = factory.apps();
    expect(mine.filter((a) => a.engine === 'claude-code')).toHaveLength(3);
    expect(mine.filter((a) => a.engine === 'gemini-cli')).toHaveLength(6);
    // The three big apps are the ones Claude writes.
    expect(mine.filter((a) => a.size === 'big').every((a) => a.engine === 'claude-code')).toBe(true);
  });

  it('honours an engine chosen by hand for one app', async () => {
    const { ops } = fakeOps();
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await factory.init();
    factory.setPaused(true);
    factory.addBatch({ name: 'B', ideas: [{ name: 'A one', summary: 'does a', engine: 'qwen-code' }, { name: 'B two', summary: 'does b' }], recipe: { engines: { 'claude-code': 1 } } });
    expect(factory.apps().map((a) => a.engine)).toEqual(['qwen-code', 'claude-code']);
  });

  it('stops a running app when it is cancelled and leaves the others alone', async () => {
    const { ops } = fakeOps({
      code: (ctx) =>
        new Promise<void>((resolve, reject) => {
          if (ctx.app.name !== 'App 1') return void setTimeout(resolve, 3);
          ctx.signal.addEventListener('abort', () => reject(new Error('stopped')));
        }),
    });
    const { factory } = await make(ops, {}, 3);
    await tick(30);
    const first = factory.apps().find((a) => a.name === 'App 1')!;
    expect(first.stages.code.state).toBe('running');
    expect(factory.cancelApp(first.id)).toBe(true);
    await factory.idle();
    expect(factory.app(first.id)!.state).toBe('cancelled');
    expect(factory.app(first.id)!.stages.code.state).toBe('pending');
    expect(factory.summary()).toMatchObject({ done: 2, cancelled: 1 });
  });

  it('does not start new work while paused, and goes on when resumed', async () => {
    const { ops, probe } = fakeOps();
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await factory.init();
    factory.setPaused(true);
    factory.addBatch({ name: 'B', ideas: ideas(3), recipe: { goal: 'app' } });
    await tick(30);
    expect(probe.events).toHaveLength(0);
    expect(factory.summary().queued).toBe(3);
    factory.setPaused(false);
    await factory.idle();
    expect(factory.summary().done).toBe(3);
  });

  it('comes back after a restart paused, with interrupted work back in line', async () => {
    const store = new MemoryStateStore();
    let release!: () => void;
    const gate = new Promise<void>((r) => (release = r));
    const first = fakeOps({ code: () => gate });
    const a = new Factory({ store, ops: first.ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await a.init();
    a.addBatch({ name: 'B', ideas: ideas(2), recipe: { goal: 'app' } });
    await tick(30);
    expect(a.summary().running).toBe(2);
    await a.flush();
    // The Runner dies here: a new Factory reads what was saved.
    const second = fakeOps();
    const b = new Factory({ store, ops: second.ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await b.init();
    expect(b.paused).toBe(true);
    expect(b.interrupted).toBe(true);
    expect(b.summary()).toMatchObject({ total: 2, running: 0, queued: 2 });
    expect(b.apps().every((x) => x.stages.create.state === 'done' && x.stages.code.state === 'pending')).toBe(true);
    b.setPaused(false);
    await b.idle();
    expect(b.summary().done).toBe(2);
    release();
    await a.shutdown();
  });

  it('gives every app its own folder name, even for the same title', async () => {
    const { ops } = fakeOps();
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await factory.init();
    factory.setPaused(true);
    factory.addBatch({ name: 'A', ideas: [{ name: 'Tiny Timer', summary: 'Counts down small things' }, { name: 'Tiny Timer', summary: 'A kitchen timer with presets' }], recipe: { goal: 'app' } });
    factory.addBatch({ name: 'B', ideas: [{ name: 'Tiny Timer', summary: 'Another one for kids' }], recipe: { goal: 'app' } });
    expect(factory.apps().map((a) => a.folder)).toEqual(['tiny_timer', 'tiny_timer_2', 'tiny_timer_3']);
  });

  it('marks stages outside the goal as skipped and does not count them', async () => {
    const { ops } = fakeOps();
    const { factory } = await make(ops, { goal: 'assets' }, 2);
    await factory.idle();
    const app = factory.apps()[0]!;
    expect(app.stages.android.state).toBe('skipped');
    expect(app.stages.listing.state).toBe('done');
    expect(factory.summary()).toMatchObject({ done: 2, progress: 1, onPlay: 0 });
  });

  it('survives a stage that has no operation on this Runner', async () => {
    const { ops } = fakeOps();
    delete ops.stages.ios;
    const { factory } = await make(ops, {}, 1);
    await factory.idle();
    expect(factory.apps()[0]!.stages.ios).toMatchObject({ state: 'skipped', message: 'unavailable' });
    expect(factory.summary().done).toBe(1);
  });

  it('stops starting apps when the disk is nearly full', async () => {
    let free = 3;
    const { ops, probe } = fakeOps();
    ops.freeDiskGb = async () => free;
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await factory.init();
    factory.addBatch({ name: 'B', ideas: ideas(2), recipe: { goal: 'app' } });
    await tick(30);
    expect(probe.events).toHaveLength(0);
    expect(factory.isLowDisk).toBe(true);
    free = 50;
    factory.dispatch();
    await factory.idle();
    expect(factory.isLowDisk).toBe(false);
    expect(factory.summary().done).toBe(2);
  });

  it('removes an app and drops a batch that is left empty', async () => {
    const removed: string[] = [];
    const { ops } = fakeOps();
    ops.remove = async (a) => void removed.push(a.folder);
    const { factory } = await make(ops, { goal: 'app' }, 2);
    await factory.idle();
    const [a, b] = factory.apps();
    expect(await factory.removeApp(a!.id, true)).toBe(true);
    expect(removed).toEqual(['app_1']);
    expect(factory.batches()[0]!.appIds).toHaveLength(1);
    await factory.removeApp(b!.id);
    expect(factory.batches()).toHaveLength(0);
    expect(factory.apps()).toHaveLength(0);
  });

  it('saves its state and a new Factory reads it back', async () => {
    const { ops } = fakeOps();
    const { factory, store } = await make(ops, { goal: 'app' }, 3);
    await factory.idle();
    await factory.flush();
    const again = new Factory({ store, ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await again.init();
    expect(again.apps().map((a) => a.name)).toEqual(['App 1', 'App 2', 'App 3']);
    expect(again.summary().done).toBe(3);
    expect(again.paused).toBe(false);
  });
});

describe('daily cap on store uploads', () => {
  const noon = new Date(2026, 9, 6, 12, 0, 0).getTime();

  it('uploads up to the cap today, keeps the rest ready, and sends them the next day', async () => {
    let clock = noon;
    const uploaded: string[] = [];
    const { ops } = fakeOps({
      play: async (ctx) => void uploaded.push(ctx.app.name),
    });
    const store = new MemoryStateStore();
    const factory = new Factory({ store, ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick, now: () => clock });
    await factory.init();
    factory.updateSettings({ dailyStoreCap: { play: 2 } });
    factory.addBatch({ name: 'B', ideas: ideas(5), recipe: { goal: 'android' } });
    await factory.idle();
    expect(uploaded).toHaveLength(2);
    const s = factory.summary();
    expect(s).toMatchObject({ onPlay: 2, done: 2, queued: 3 });
    expect(factory.uploadsToday()).toMatchObject({ play: 2, appstore: 0, cap: { play: 2, appstore: 10 } });
    // Waiting apps have everything else done and say when they come back.
    const waiting = factory.apps().filter((a) => a.state === 'queued');
    expect(waiting).toHaveLength(3);
    for (const a of waiting) {
      expect(a.stages.android.state).toBe('done');
      expect(a.stages.play.state).toBe('pending');
      expect(Date.parse(a.notBefore!)).toBe(new Date(2026, 9, 7).getTime());
    }
    // Tomorrow the count starts over: two more go.
    clock = new Date(2026, 9, 7, 0, 0, 5).getTime();
    expect(factory.uploadsToday()).toMatchObject({ play: 0, date: dayKey(clock) });
    factory.dispatch();
    await factory.idle();
    expect(uploaded).toHaveLength(4);
    expect(factory.summary()).toMatchObject({ onPlay: 4, done: 4, queued: 1 });
    await factory.shutdown();
  });

  it('counts each store on its own', async () => {
    const { ops } = fakeOps();
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick, now: () => noon });
    await factory.init();
    factory.updateSettings({ dailyStoreCap: { play: 1, appstore: 3 } });
    factory.addBatch({ name: 'B', ideas: ideas(3), recipe: { goal: 'ios' } });
    await factory.idle();
    expect(factory.summary()).toMatchObject({ onPlay: 1, onAppStore: 3 });
    // Two apps still wait for Google Play although their iPhone side is finished.
    expect(factory.apps().filter((a) => a.state === 'queued')).toHaveLength(2);
    await factory.shutdown();
  });

  it('gives the place back when an upload fails or needs the owner', async () => {
    const { ops } = fakeOps({
      play: async (ctx) => {
        if (ctx.app.name === 'App 1') throw new Error('Play said no');
        if (ctx.app.name === 'App 2') throw new NeedsOwner({ kind: 'play_console_app', title: 'Create it', detail: '', data: {} });
      },
    });
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick, now: () => noon });
    await factory.init();
    factory.updateSettings({ dailyStoreCap: { play: 1 } });
    factory.addBatch({ name: 'B', ideas: ideas(3), recipe: { goal: 'android', maxAttempts: 1 } });
    await factory.idle();
    const [one, two, three] = factory.apps();
    expect(one!.state).toBe('failed');
    expect(two!.state).toBe('needs_you');
    // The only place of the day went to the app that could really use it.
    expect(three!.stages.play.state).toBe('done');
    expect(factory.uploadsToday().play).toBe(1);
    await factory.shutdown();
  });

  it('wakes the apps sent to wait for tomorrow when a place comes back the same day', async () => {
    // Four apps reach Google Play together, the cap is two: the first two take the places and the
    // others are sent to wait for tomorrow. Then the first one turns out to need the owner, and
    // its place must not be wasted on a day when two ready apps are waiting.
    let calls = 0;
    const uploaded: string[] = [];
    const { ops } = fakeOps({
      play: async (ctx) => {
        const call = ++calls;
        await tick(40);
        if (call === 1) throw new NeedsOwner({ kind: 'play_console_app', title: 'Create it', detail: '', data: {} });
        uploaded.push(ctx.app.name);
      },
    });
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick, now: () => noon });
    await factory.init();
    factory.updateSettings({ dailyStoreCap: { play: 2 }, lanes: { store: 10 } });
    factory.addBatch({ name: 'B', ideas: ideas(4), recipe: { goal: 'android' } });
    await factory.idle();
    // One needs the owner, two uploaded today (the cap), one waits for tomorrow.
    expect(uploaded).toHaveLength(2);
    expect(factory.uploadsToday().play).toBe(2);
    const states = factory.apps().map((a) => a.state);
    expect(states.filter((s) => s === 'needs_you')).toHaveLength(1);
    expect(states.filter((s) => s === 'done')).toHaveLength(2);
    const waiting = factory.apps().filter((a) => a.state === 'queued');
    expect(waiting).toHaveLength(1);
    expect(Date.parse(waiting[0]!.notBefore!)).toBe(new Date(2026, 9, 7).getTime());
    await factory.shutdown();
  });

  it('does not wake more apps than there are free places', async () => {
    let calls = 0;
    const uploaded: string[] = [];
    const { ops } = fakeOps({
      play: async (ctx) => {
        const call = ++calls;
        await tick(40);
        if (call === 1) throw new NeedsOwner({ kind: 'play_console_app', title: 'Create it', detail: '', data: {} });
        uploaded.push(ctx.app.name);
      },
    });
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick, now: () => noon });
    await factory.init();
    factory.updateSettings({ dailyStoreCap: { play: 2 }, lanes: { store: 10 } });
    factory.addBatch({ name: 'B', ideas: ideas(6), recipe: { goal: 'android' } });
    await factory.idle();
    expect(uploaded).toHaveLength(2);
    expect(factory.uploadsToday().play).toBe(2);
    expect(factory.apps().filter((a) => a.state === 'queued')).toHaveLength(3);
    await factory.shutdown();
  });
});
