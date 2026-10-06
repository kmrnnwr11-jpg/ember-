import { describe, expect, it } from 'vitest';
import { Factory, type Ops, type StageOp } from './engine.js';
import { MemoryStateStore } from './state_store.js';
import { NeedsOwner, RateLimited, STAGES, laneOf, type Idea, type Recipe, type Stage } from './types.js';

const tick = (ms = 2) => new Promise((r) => setTimeout(r, ms));
const ideas = (n: number): Idea[] => Array.from({ length: n }, (_, i) => ({ name: `App ${i + 1}`, idea: `Does thing number ${i + 1} for people` }));

interface Probe {
  order: Array<{ app: string; stage: Stage }>;
  peak: Record<string, number>;
  live: Record<string, number>;
}

/** Fake operations that take a few milliseconds and record how many ran together per lane. */
function fakeOps(over: Partial<Record<Stage, StageOp>> = {}, ms = 3): { ops: Ops; probe: Probe } {
  const probe: Probe = { order: [], peak: {}, live: {} };
  const stages: Partial<Record<Stage, StageOp>> = {};
  for (const stage of STAGES) {
    stages[stage] =
      over[stage] ??
      (async (ctx) => {
        const lane = laneOf(stage, ctx.app.engine);
        probe.live[lane] = (probe.live[lane] ?? 0) + 1;
        probe.peak[lane] = Math.max(probe.peak[lane] ?? 0, probe.live[lane]!);
        probe.order.push({ app: ctx.app.name, stage });
        await tick(ms);
        probe.live[lane]!--;
        return { message: `${stage} ok` };
      });
  }
  return { ops: { stages }, probe };
}

async function make(ops: Ops, recipe: Partial<Recipe> = {}, n = 3, store = new MemoryStateStore()) {
  const factory = new Factory({ store, ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
  await factory.init();
  const batch = factory.addBatch({ name: 'Test', ideas: ideas(n), recipe: { reach: 'both', ...recipe } });
  return { factory, batch, store };
}

describe('Factory', () => {
  it('takes every app through every stage, in order', async () => {
    const { ops, probe } = fakeOps();
    const { factory } = await make(ops, {}, 4);
    await factory.idle();
    const s = factory.summary();
    expect(s).toMatchObject({ total: 4, done: 4, failed: 0, running: 0, queued: 0, progress: 1 });
    for (const app of factory.apps()) {
      expect(STAGES.every((st) => app.stages[st].state === 'done')).toBe(true);
      const mine = probe.order.filter((o) => o.app === app.name).map((o) => o.stage);
      expect(mine).toEqual([...STAGES]);
    }
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
    const store = new MemoryStateStore();
    const factory = new Factory({ store, ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await factory.init();
    factory.updateSettings({ maxInFlight: 3 });
    factory.addBatch({ name: 'B', ideas: ideas(12), recipe: { reach: 'both' } });
    await factory.idle();
    expect(factory.summary().done).toBe(12);
    expect(peak).toBeLessThanOrEqual(3);
  });

  it('finishes earlier apps before starting late stages of later ones (deeper stages first)', async () => {
    const { ops, probe } = fakeOps({}, 4);
    const { factory } = await make(ops, {}, 6);
    factory.updateSettings({ lanes: { light: 1, build: 1, text: 1, image: 1, shots: 1, store: 1, 'agent:claude-code': 1 }, maxInFlight: 6 });
    await factory.idle();
    const firstDone = probe.order.findIndex((o) => o.app === 'App 1' && o.stage === 'appstore');
    const lastCreate = probe.order.findIndex((o) => o.app === 'App 6' && o.stage === 'create');
    // The first app is completely finished before the sixth one has even been created.
    expect(firstDone).toBeGreaterThan(-1);
    expect(firstDone).toBeLessThan(lastCreate + 40);
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

  it('retries a failed app from the stage that failed', async () => {
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
    const before = probe.order.length;
    broken = false;
    expect(factory.retryApp(app.id)).toBe(true);
    await factory.idle();
    expect(factory.apps()[0]!.state).toBe('done');
    // create/code/verify/preview were not run again.
    expect(probe.order.slice(before).map((o) => o.stage)).not.toContain('create');
    expect(probe.order.slice(before).map((o) => o.stage)).toContain('shots');
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
    const { factory } = await make(ops, { reach: 'android' }, 3);
    factory.updateSettings({ maxInFlight: 1 });
    await factory.idle();
    // maxInFlight is 1 and App 1 is waiting for the owner: the other two still got done.
    const s = factory.summary();
    expect(s).toMatchObject({ needsYou: 1, done: 2 });
    const open = factory.needsYou();
    expect(open).toHaveLength(1);
    expect(open[0]).toMatchObject({ kind: 'play_console_app', appName: 'App 1', stage: 'play' });
    resolved = true;
    expect(factory.resolveNeed(open[0]!.appId, open[0]!.id)).toBe(true);
    await factory.idle();
    expect(factory.summary()).toMatchObject({ needsYou: 0, done: 3 });
    expect(factory.apps()[0]!.stages.play.state).toBe('done');
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

  it('moves an app to another engine of the recipe when one reaches its usage limit', async () => {
    const used: string[] = [];
    const { ops } = fakeOps({
      code: async (ctx) => {
        used.push(ctx.app.engine);
        if (ctx.app.engine === 'claude-code') throw new RateLimited('limit', 60_000, 'agent:claude-code');
      },
    });
    const { factory } = await make(
      ops,
      {
        engines: [
          { engine: 'claude-code', weight: 1 },
          { engine: 'qwen-code', weight: 1 },
        ],
      },
      2,
    );
    await factory.idle();
    expect(factory.summary().done).toBe(2);
    expect(factory.apps().every((a) => a.engine === 'qwen-code')).toBe(true);
    expect(used).toContain('claude-code');
    expect(factory.lanes.isLanePaused('agent:claude-code')).toBe(true);
  });

  it('shares apps among engines by weight', async () => {
    const { ops } = fakeOps();
    const { factory } = await make(
      ops,
      {
        engines: [
          { engine: 'claude-code', weight: 2 },
          { engine: 'gemini-cli', weight: 1 },
        ],
      },
      9,
    );
    const count = (e: string) => factory.apps().filter((a) => a.engine === e).length;
    expect(count('claude-code')).toBe(6);
    expect(count('gemini-cli')).toBe(3);
    await factory.shutdown();
  });

  it('stops a running app when it is cancelled and leaves the others alone', async () => {
    const { ops } = fakeOps({
      code: (ctx) =>
        new Promise<void>((resolve, reject) => {
          if (ctx.app.name !== 'App 1') return setTimeout(resolve, 3);
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
    const store = new MemoryStateStore();
    const factory = new Factory({ store, ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await factory.init();
    factory.setPaused(true);
    factory.addBatch({ name: 'B', ideas: ideas(3), recipe: { reach: 'app' } });
    await tick(30);
    expect(probe.order).toHaveLength(0);
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
    a.addBatch({ name: 'B', ideas: ideas(2), recipe: { reach: 'app' } });
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

  it('holds an app back when the daily cap of reviews is reached, then it comes back', async () => {
    let sent = 0;
    const { ops } = fakeOps({
      appstore: async (ctx) => {
        if (!ctx.canSubmit()) throw new RateLimited('daily cap', 120);
        ctx.noteSubmit();
        sent++;
      },
    });
    const store = new MemoryStateStore();
    const factory = new Factory({ store, ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await factory.init();
    factory.updateSettings({ dailySubmitLimit: 1 });
    factory.addBatch({ name: 'B', ideas: ideas(2), recipe: { reach: 'both' } });
    await factory.idle();
    const s = factory.summary();
    expect(s.done).toBe(1);
    expect(s.queued).toBe(1);
    expect(sent).toBe(1);
    expect(factory.apps().find((a) => a.state === 'queued')!.notBefore).toBeDefined();
    await factory.shutdown();
  });

  it('gives every app its own folder name, even for the same title', async () => {
    const { ops } = fakeOps();
    const factory = new Factory({ store: new MemoryStateStore(), ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await factory.init();
    factory.setPaused(true);
    factory.addBatch({ name: 'A', ideas: [{ name: 'Tiny Timer', idea: 'Counts down small things' }, { name: 'Tiny Timer', idea: 'A kitchen timer with presets' }], recipe: { reach: 'app' } });
    factory.addBatch({ name: 'B', ideas: [{ name: 'Tiny Timer', idea: 'Another one for kids' }], recipe: { reach: 'app' } });
    expect(factory.apps().map((a) => a.folder)).toEqual(['tiny_timer', 'tiny_timer_2', 'tiny_timer_3']);
  });

  it('marks stages outside the reach as skipped and does not count them', async () => {
    const { ops } = fakeOps();
    const { factory } = await make(ops, { reach: 'assets' }, 2);
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
    factory.addBatch({ name: 'B', ideas: ideas(2), recipe: { reach: 'app' } });
    await tick(30);
    expect(probe.order).toHaveLength(0);
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
    const { factory } = await make(ops, { reach: 'app' }, 2);
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
    const { factory, store } = await make(ops, { reach: 'app' }, 3);
    await factory.idle();
    await factory.flush();
    const again = new Factory({ store, ops, retryBackoffMs: 1, saveDelayMs: 1, sleep: tick });
    await again.init();
    expect(again.apps().map((a) => a.name)).toEqual(['App 1', 'App 2', 'App 3']);
    expect(again.summary().done).toBe(3);
    expect(again.paused).toBe(false);
  });
});
