import { EventEmitter } from 'node:events';
import { nanoid } from 'nanoid';
import { slugFolder, uniqueSlug } from './ideas.js';
import { AbortedError, Lanes } from './scheduler.js';
import { emptyState, type StateStore } from './state_store.js';
import {
  REACH_STAGES,
  STAGES,
  NeedsOwner,
  RateLimited,
  defaultRecipe,
  emptyStages,
  laneOf,
  type AppState,
  type Batch,
  type FactoryApp,
  type FactoryEngine,
  type FactorySettings,
  type FactoryState,
  type Idea,
  type NeedsYou,
  type Recipe,
  type Stage,
  type Summary,
} from './types.js';

/** What a stage hands back: a line to show, or the reason it had nothing to do. */
export interface StageOutcome {
  message?: string;
  skipped?: string;
}

export interface StageContext {
  app: FactoryApp;
  batch: Batch;
  recipe: Recipe;
  settings: FactorySettings;
  /** Aborted when the app is cancelled: operations must stop what they started. */
  signal: AbortSignal;
  log(line: string): void;
  addCost(usd: number): void;
  /** Whether one more review may be sent today, and the note that one was. */
  canSubmit(): boolean;
  noteSubmit(): void;
}

export type StageOp = (ctx: StageContext) => Promise<StageOutcome | void>;

export interface Ops {
  stages: Partial<Record<Stage, StageOp>>;
  /** Free disk in GB, to stop starting apps when it runs low. */
  freeDiskGb?: () => Promise<number>;
  /** Clears what an app no longer needs once it is finished (build folders). */
  cleanup?: (app: FactoryApp) => Promise<void>;
  /** Deletes what the app made outside the state (its project). */
  remove?: (app: FactoryApp) => Promise<void>;
}

export interface FactoryOptions {
  store: StateStore;
  ops: Ops;
  now?: () => number;
  sleep?: (ms: number) => Promise<void>;
  /** Wait before an automatic second attempt, times the attempt number. */
  retryBackoffMs?: number;
  saveDelayMs?: number;
}

const MAX_LOG = 80;
const MAX_RATE_RETRIES = 12;
const TERMINAL: AppState[] = ['done', 'failed', 'cancelled'];

/**
 * Takes many apps from idea to the stores at once, within what the machine and
 * the engines can do. See docs/FABBRICA_PIANO.md.
 */
export class Factory extends EventEmitter<{ change: [rev: number] }> {
  readonly lanes: Lanes;
  private state: FactoryState = emptyState();
  private readonly drivers = new Map<string, AbortController>();
  private readonly finishedAt: number[] = [];
  private saveTimer: NodeJS.Timeout | null = null;
  private wakeTimer: NodeJS.Timeout | null = null;
  private lowDisk = false;
  private dispatching = 0;
  private readonly now: () => number;
  private readonly sleep: (ms: number) => Promise<void>;

  constructor(private readonly opts: FactoryOptions) {
    super();
    this.now = opts.now ?? Date.now;
    this.sleep = opts.sleep ?? ((ms) => new Promise((r) => setTimeout(r, ms)));
    this.lanes = new Lanes(this.state.settings.lanes, this.now);
  }

  // ---------------------------------------------------------------- loading

  /** Reads the saved state. Work that was running when the Runner stopped is put back in line, paused. */
  async init(): Promise<void> {
    const saved = await this.opts.store.load();
    if (saved) this.state = saved;
    let interrupted = false;
    for (const app of Object.values(this.state.apps)) {
      if (TERMINAL.includes(app.state) || app.state === 'needs_you') continue;
      for (const stage of STAGES) {
        const s = app.stages[stage];
        if (s.state === 'running' || s.state === 'queued') {
          s.state = 'pending';
          interrupted = true;
        }
      }
      app.state = 'queued';
      app.current = undefined;
    }
    if (interrupted) {
      this.state.interrupted = true;
      this.state.paused = true;
    }
    this.lanes.setLimits(this.state.settings.lanes);
    this.lanes.setPaused(this.state.paused);
  }

  // ---------------------------------------------------------------- reading

  get rev(): number {
    return this.state.rev;
  }

  get paused(): boolean {
    return this.state.paused;
  }

  get isLowDisk(): boolean {
    return this.lowDisk;
  }

  get interrupted(): boolean {
    return this.state.interrupted;
  }

  get settings(): FactorySettings {
    return this.state.settings;
  }

  batches(): Batch[] {
    return this.state.batches;
  }

  apps(): FactoryApp[] {
    return this.orderedApps();
  }

  app(id: string): FactoryApp | undefined {
    return this.state.apps[id];
  }

  batch(id: string): Batch | undefined {
    return this.state.batches.find((b) => b.id === id);
  }

  /** The open tasks only the owner can do, across all apps. */
  needsYou(): Array<NeedsYou & { appId: string; appName: string }> {
    return this.orderedApps().flatMap((a) => a.needs.map((n) => ({ ...n, appId: a.id, appName: a.name })));
  }

  summary(): Summary {
    const apps = Object.values(this.state.apps);
    const count = (s: AppState) => apps.filter((a) => a.state === s).length;
    let total = 0;
    let finished = 0;
    for (const a of apps) {
      const batch = this.batch(a.batchId);
      const inReach = new Set<Stage>(REACH_STAGES[batch?.recipe.reach ?? 'both']);
      for (const stage of STAGES) {
        if (!inReach.has(stage)) continue;
        total++;
        const st = a.stages[stage].state;
        if (st === 'done' || st === 'skipped') finished++;
      }
    }
    const recent = this.finishedAt.filter((t) => t > this.now() - 15 * 60_000);
    let eta: number | null = null;
    if (recent.length >= 3 && total > finished) {
      const span = Math.max(60_000, this.now() - Math.min(...recent));
      eta = Math.round(((total - finished) / (recent.length / span)) / 1000);
    }
    return {
      total: apps.length,
      queued: count('queued'),
      running: count('running'),
      needsYou: count('needs_you'),
      done: count('done'),
      failed: count('failed'),
      cancelled: count('cancelled'),
      onPlay: apps.filter((a) => a.stages.play.state === 'done').length,
      onAppStore: apps.filter((a) => a.stages.appstore.state === 'done').length,
      progress: total === 0 ? 0 : finished / total,
      etaSeconds: eta,
    };
  }

  // ---------------------------------------------------------------- batches

  /** Registers a batch of ideas as apps, in order, and starts working unless paused. */
  addBatch(input: { name: string; ideas: readonly Idea[]; recipe?: Partial<Recipe> }): Batch {
    const recipe: Recipe = { ...defaultRecipe(), ...(input.recipe ?? {}) };
    if (recipe.engines.length === 0) recipe.engines = defaultRecipe().engines;
    recipe.maxAttempts = Math.min(5, Math.max(1, Math.floor(recipe.maxAttempts)));
    if (!recipe.languages.includes('en-US')) recipe.languages = ['en-US', ...recipe.languages];
    const batch: Batch = { id: nanoid(10), name: input.name.trim().slice(0, 60) || 'Lotto', createdAt: new Date(this.now()).toISOString(), recipe, appIds: [] };
    const wheel = recipe.engines.flatMap((e) => Array<FactoryEngine>(Math.max(1, Math.floor(e.weight))).fill(e.engine));
    const taken = new Set(Object.values(this.state.apps).map((a) => a.folder));
    const inReach = new Set<Stage>(REACH_STAGES[recipe.reach]);
    input.ideas.forEach((idea, i) => {
      const folder = uniqueSlug(slugFolder(idea.name), taken);
      taken.add(folder);
      const stages = emptyStages();
      for (const stage of STAGES) if (!inReach.has(stage)) stages[stage] = { state: 'skipped', attempts: 0, message: 'outside' };
      const iso = new Date(this.now()).toISOString();
      const app: FactoryApp = {
        id: nanoid(10),
        batchId: batch.id,
        order: i,
        name: idea.name.trim().slice(0, 30) || folder,
        idea: idea.idea.trim(),
        folder,
        engine: wheel[i % wheel.length]!,
        state: 'queued',
        stages,
        needs: [],
        log: [],
        costUsd: 0,
        createdAt: iso,
        updatedAt: iso,
      };
      this.state.apps[app.id] = app;
      batch.appIds.push(app.id);
    });
    this.state.batches.push(batch);
    this.touch();
    this.dispatch();
    return batch;
  }

  // ---------------------------------------------------------------- control

  setPaused(paused: boolean): void {
    this.state.paused = paused;
    if (!paused) this.state.interrupted = false;
    this.lanes.setPaused(paused);
    this.touch();
    if (!paused) this.dispatch();
  }

  updateSettings(patch: Partial<FactorySettings>): void {
    const s = this.state.settings;
    if (patch.lanes) s.lanes = { ...s.lanes, ...Object.fromEntries(Object.entries(patch.lanes).map(([k, v]) => [k, Math.max(0, Math.min(32, Math.floor(v)))])) };
    if (patch.maxInFlight !== undefined) s.maxInFlight = Math.max(1, Math.min(100, Math.floor(patch.maxInFlight)));
    if (patch.dailySubmitLimit !== undefined) s.dailySubmitLimit = Math.max(0, Math.min(200, Math.floor(patch.dailySubmitLimit)));
    if (patch.minFreeDiskGb !== undefined) s.minFreeDiskGb = Math.max(0, Math.min(500, patch.minFreeDiskGb));
    this.lanes.setLimits(s.lanes);
    this.touch();
    this.dispatch();
  }

  /** Stops the app now (a running stage is aborted) and keeps it listed as cancelled. */
  cancelApp(id: string): boolean {
    const app = this.state.apps[id];
    if (!app || TERMINAL.includes(app.state)) return false;
    const ctrl = this.drivers.get(id);
    if (ctrl) {
      ctrl.abort();
    } else {
      this.setAppState(app, 'cancelled');
      this.resetOpenStages(app);
      this.touch();
    }
    return true;
  }

  cancelBatch(batchId: string): number {
    return (this.batch(batchId)?.appIds ?? []).filter((id) => this.cancelApp(id)).length;
  }

  /** Puts a failed, cancelled or waiting app back in line, from [from] (default: where it stopped). */
  retryApp(id: string, from?: Stage): boolean {
    const app = this.state.apps[id];
    if (!app || this.drivers.has(id) || app.state === 'running') return false;
    const batch = this.batch(app.batchId);
    const inReach = new Set<Stage>(REACH_STAGES[batch?.recipe.reach ?? 'both']);
    const start = from ?? app.errorStage ?? STAGES.find((s) => inReach.has(s) && !['done', 'skipped'].includes(app.stages[s].state));
    if (!start) return false;
    let reset = false;
    for (const stage of STAGES) {
      if (stage === start) reset = true;
      if (reset && inReach.has(stage)) app.stages[stage] = { state: 'pending', attempts: 0 };
    }
    app.error = undefined;
    app.errorStage = undefined;
    app.notBefore = undefined;
    app.needs = app.needs.filter((n) => STAGES.indexOf(n.stage) < STAGES.indexOf(start));
    this.setAppState(app, 'queued');
    this.addLog(app, `↻ ${start}`);
    this.touch();
    this.dispatch();
    return true;
  }

  retryFailed(batchId?: string): number {
    return this.orderedApps()
      .filter((a) => a.state === 'failed' && (!batchId || a.batchId === batchId))
      .filter((a) => this.retryApp(a.id)).length;
  }

  /**
   * The owner did what an app was waiting for (or chose to skip that stage).
   * The stage is tried again, or counted as skipped.
   */
  resolveNeed(appId: string, needId: string | null, opts: { skip?: boolean } = {}): boolean {
    const app = this.state.apps[appId];
    if (!app || app.state !== 'needs_you') return false;
    const need = needId ? app.needs.find((n) => n.id === needId) : app.needs[0];
    if (!need) return false;
    app.needs = app.needs.filter((n) => n !== need);
    const stage = app.stages[need.stage];
    if (opts.skip) {
      stage.state = 'skipped';
      stage.message = 'skipped_by_owner';
      stage.finishedAt = new Date(this.now()).toISOString();
    } else {
      app.stages[need.stage] = { state: 'pending', attempts: 0 };
    }
    // Several things can wait at once; the app goes on when none is left open.
    if (app.needs.length === 0) {
      this.setAppState(app, 'queued');
      this.dispatch();
    }
    this.addLog(app, opts.skip ? `⤼ ${need.stage}` : `✓ ${need.title}`);
    this.touch();
    return true;
  }

  /** Takes an app out of the Factory; [deleteProject] also removes what it built. */
  async removeApp(id: string, deleteProject = false): Promise<boolean> {
    const app = this.state.apps[id];
    if (!app) return false;
    const ctrl = this.drivers.get(id);
    if (ctrl) {
      ctrl.abort();
      for (let i = 0; i < 50 && this.drivers.has(id); i++) await this.sleep(20);
    }
    if (deleteProject) await this.opts.ops.remove?.(app);
    delete this.state.apps[id];
    for (const b of this.state.batches) b.appIds = b.appIds.filter((x) => x !== id);
    this.state.batches = this.state.batches.filter((b) => b.appIds.length > 0);
    this.touch();
    return true;
  }

  /** Waits until every driver has stopped (tests, shutdown). */
  async idle(): Promise<void> {
    while (this.drivers.size > 0 || this.dispatching > 0) await this.sleep(5);
  }

  /** Aborts everything running and writes the state now. */
  async shutdown(): Promise<void> {
    for (const ctrl of this.drivers.values()) ctrl.abort();
    clearTimeout(this.wakeTimer ?? undefined);
    await this.flush();
  }

  async flush(): Promise<void> {
    if (this.saveTimer) clearTimeout(this.saveTimer);
    this.saveTimer = null;
    await this.opts.store.save(this.state);
  }

  // ------------------------------------------------------------- dispatching

  private orderedApps(): FactoryApp[] {
    const rank = new Map(this.state.batches.map((b, i) => [b.id, i]));
    return Object.values(this.state.apps).sort((a, b) => (rank.get(a.batchId) ?? 0) - (rank.get(b.batchId) ?? 0) || a.order - b.order);
  }

  /** Starts as many waiting apps as the "in flight" limit and the disk allow. */
  dispatch(): void {
    if (this.state.paused) return;
    this.dispatching += 1;
    void this.dispatchAsync().finally(() => {
      this.dispatching -= 1;
    });
  }

  private async dispatchAsync(): Promise<void> {
    const free = await this.opts.ops.freeDiskGb?.().catch(() => Infinity);
    this.lowDisk = free !== undefined && free < this.state.settings.minFreeDiskGb;
    if (this.lowDisk) {
      // Make room: build folders of finished apps are the biggest thing to give back.
      for (const app of Object.values(this.state.apps)) if (app.state === 'done') await this.opts.ops.cleanup?.(app).catch(() => {});
      this.touch();
      return;
    }
    if (this.state.paused) return;
    const now = this.now();
    let wake: number | null = null;
    for (const app of this.orderedApps()) {
      if (this.drivers.size >= this.state.settings.maxInFlight) break;
      if (app.state !== 'queued' || this.drivers.has(app.id)) continue;
      const until = app.notBefore ? Date.parse(app.notBefore) : 0;
      if (until > now) {
        wake = wake === null ? until : Math.min(wake, until);
        continue;
      }
      this.startDriver(app);
    }
    clearTimeout(this.wakeTimer ?? undefined);
    this.wakeTimer = null;
    if (wake !== null) {
      this.wakeTimer = setTimeout(() => this.dispatch(), Math.max(50, wake - now));
      this.wakeTimer.unref?.();
    }
  }

  private startDriver(app: FactoryApp): void {
    const ctrl = new AbortController();
    this.drivers.set(app.id, ctrl);
    this.setAppState(app, 'running');
    this.touch();
    void this.drive(app, ctrl.signal)
      .catch((e: unknown) => {
        if (e instanceof AbortedError) {
          this.resetOpenStages(app);
          app.current = undefined;
          this.setAppState(app, 'cancelled');
        } else {
          app.error = (e as Error).message;
          this.setAppState(app, 'failed');
        }
      })
      .finally(() => {
        this.drivers.delete(app.id);
        this.touch();
        this.dispatch();
      });
  }

  /** The route of one app: stage after stage until done, failed, or waiting for the owner. */
  private async drive(app: FactoryApp, signal: AbortSignal): Promise<void> {
    for (;;) {
      if (signal.aborted) throw new AbortedError();
      const stage = this.nextStage(app);
      if (!stage) {
        app.current = undefined;
        this.setAppState(app, 'done');
        void this.opts.ops.cleanup?.(app).catch(() => {});
        return;
      }
      const go = await this.runStage(app, stage, signal);
      if (!go) return;
    }
  }

  private nextStage(app: FactoryApp): Stage | null {
    const batch = this.batch(app.batchId);
    const inReach = new Set<Stage>(REACH_STAGES[batch?.recipe.reach ?? 'both']);
    return STAGES.find((s) => inReach.has(s) && !['done', 'skipped'].includes(app.stages[s].state)) ?? null;
  }

  /** Runs one stage with retries. Returns whether the app can go on to the next. */
  private async runStage(app: FactoryApp, stage: Stage, signal: AbortSignal): Promise<boolean> {
    const batch = this.batch(app.batchId)!;
    const recipe = batch.recipe;
    const run = app.stages[stage];
    const op = this.opts.ops.stages[stage];
    app.current = stage;
    if (!op) {
      run.state = 'skipped';
      run.message = 'unavailable';
      this.touch();
      return true;
    }
    const rank = this.state.batches.indexOf(batch) * 10_000 + app.order;
    const priority = (STAGES.length - STAGES.indexOf(stage)) * 1_000_000 + rank;
    const ctx: StageContext = {
      app,
      batch,
      recipe,
      settings: this.state.settings,
      signal,
      log: (line) => this.addLog(app, line),
      addCost: (usd) => {
        app.costUsd += usd;
      },
      canSubmit: () => this.submitsToday() < this.state.settings.dailySubmitLimit,
      noteSubmit: () => {
        this.state.submitLog.push(new Date(this.now()).toISOString());
      },
    };
    let rateRetries = 0;
    for (;;) {
      run.state = 'queued';
      this.touch();
      try {
        const outcome = await this.lanes.run(
          laneOf(stage, app.engine),
          priority,
          async () => {
            if (signal.aborted) throw new AbortedError();
            run.state = 'running';
            run.attempts += 1;
            run.startedAt = new Date(this.now()).toISOString();
            run.finishedAt = undefined;
            this.touch();
            return op(ctx);
          },
          signal,
        );
        run.state = outcome && outcome.skipped ? 'skipped' : 'done';
        run.message = (outcome && (outcome.skipped ?? outcome.message)) || undefined;
        run.finishedAt = new Date(this.now()).toISOString();
        this.finishedAt.push(this.now());
        if (this.finishedAt.length > 200) this.finishedAt.splice(0, this.finishedAt.length - 200);
        this.touch();
        return true;
      } catch (e) {
        if (e instanceof AbortedError || signal.aborted) {
          run.state = 'pending';
          throw new AbortedError();
        }
        if (e instanceof NeedsOwner) {
          const need: NeedsYou = { ...e.need, stage, id: nanoid(8), createdAt: new Date(this.now()).toISOString() };
          app.needs = [...app.needs.filter((n) => !(n.stage === stage && n.kind === need.kind)), need];
          run.state = 'blocked';
          run.message = need.title;
          run.finishedAt = new Date(this.now()).toISOString();
          app.current = stage;
          this.addLog(app, `⏸ ${need.title}`);
          this.setAppState(app, 'needs_you');
          this.touch();
          return false;
        }
        if (e instanceof RateLimited) {
          run.attempts = Math.max(0, run.attempts - 1);
          this.addLog(app, `⏳ ${e.message}`);
          if (e.lane) {
            this.lanes.pauseLane(e.lane, e.retryAfterMs);
            // Another engine of the recipe may be free: the app moves there.
            const other = e.lane.startsWith('agent:') ? recipe.engines.map((x) => x.engine).find((x) => x !== app.engine && !this.lanes.isLanePaused(`agent:${x}`)) : undefined;
            if (other && stage === 'code') {
              this.addLog(app, `→ ${other}`);
              app.engine = other;
              continue;
            }
          } else {
            // Not an engine's limit but this app's turn (a daily cap): it steps aside and comes back.
            run.state = 'pending';
            app.notBefore = new Date(this.now() + e.retryAfterMs).toISOString();
            this.setAppState(app, 'queued');
            this.touch();
            return false;
          }
          if (++rateRetries > MAX_RATE_RETRIES) {
            run.state = 'failed';
            return this.fail(app, stage, e.message);
          }
          continue;
        }
        const message = e instanceof Error ? e.message : String(e);
        run.message = message.slice(0, 600);
        this.addLog(app, `✗ ${stage}: ${message.split('\n')[0]!.slice(0, 200)}`);
        if (run.attempts < recipe.maxAttempts) {
          run.state = 'queued';
          this.touch();
          await this.sleep((this.opts.retryBackoffMs ?? 5000) * run.attempts);
          continue;
        }
        run.state = 'failed';
        run.finishedAt = new Date(this.now()).toISOString();
        return this.fail(app, stage, message);
      }
    }
  }

  private fail(app: FactoryApp, stage: Stage, message: string): boolean {
    app.error = message.slice(0, 600);
    app.errorStage = stage;
    this.setAppState(app, 'failed');
    this.touch();
    return false;
  }

  private submitsToday(): number {
    const since = this.now() - 24 * 3600_000;
    this.state.submitLog = this.state.submitLog.filter((t) => Date.parse(t) > since);
    return this.state.submitLog.length;
  }

  private resetOpenStages(app: FactoryApp): void {
    for (const stage of STAGES) {
      const s = app.stages[stage];
      if (s.state === 'queued' || s.state === 'running') s.state = 'pending';
    }
  }

  // ----------------------------------------------------------------- changes

  private setAppState(app: FactoryApp, state: AppState): void {
    app.state = state;
    app.updatedAt = new Date(this.now()).toISOString();
  }

  private addLog(app: FactoryApp, line: string): void {
    const text = line.replace(/\s+$/g, '').slice(0, 300);
    if (!text) return;
    app.log.push(text);
    if (app.log.length > MAX_LOG) app.log.splice(0, app.log.length - MAX_LOG);
    this.touch();
  }

  private touch(): void {
    this.state.rev += 1;
    this.emit('change', this.state.rev);
    if (this.saveTimer) return;
    this.saveTimer = setTimeout(() => {
      this.saveTimer = null;
      void this.opts.store.save(this.state).catch(() => {});
    }, this.opts.saveDelayMs ?? 250);
    this.saveTimer.unref?.();
  }
}
