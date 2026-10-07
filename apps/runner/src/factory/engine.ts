import { EventEmitter } from 'node:events';
import { nanoid } from 'nanoid';
import { assignEngines } from './engines.js';
import { slugFolder, uniqueSlug } from './ideas.js';
import { AbortedError, Lanes } from './scheduler.js';
import { emptyState, type StateStore } from './state_store.js';
import {
  DEPS,
  GOAL_STAGES,
  STAGES,
  NeedsOwner,
  RateLimited,
  dayKey,
  defaultRecipe,
  emptyStages,
  isStoreStage,
  laneOf,
  nextMidnight,
  withDependents,
  type AppState,
  type Batch,
  type FactoryApp,
  type FactorySettings,
  type FactoryState,
  type Idea,
  type NeedsKind,
  type NeedsYou,
  type Recipe,
  type Stage,
  type StoreStage,
  type Summary,
} from './types.js';

/** What a stage hands back: a line to show, or the reason it had nothing to do. */
export interface StageOutcome {
  message?: string;
  skipped?: string;
}

/** What an operation may change about the app it works on. */
export type AppPatch = Partial<Pick<FactoryApp, 'name' | 'folder' | 'workspaceId' | 'projectId' | 'packageName' | 'engine'>>;

export interface StageContext {
  app: FactoryApp;
  batch: Batch;
  recipe: Recipe;
  settings: FactorySettings;
  /** Aborted when the app is cancelled: operations must stop what they started. */
  signal: AbortSignal;
  log(line: string): void;
  /** What the app is doing right now, for its card. */
  doing(text: string): void;
  update(patch: AppPatch): void;
  addCost(usd: number): void;
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
const satisfied = (s: { state: string }) => s.state === 'done' || s.state === 'skipped';

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
      app.doing = undefined;
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

  /** Uploads started today per store, with the cap and when the count starts over. */
  uploadsToday(): { date: string; play: number; appstore: number; cap: Record<StoreStage, number>; resetsAt: string } {
    this.rollDay();
    const { date, play, appstore } = this.state.storeDay;
    return { date, play, appstore, cap: { ...this.state.settings.dailyStoreCap }, resetsAt: new Date(nextMidnight(this.now())).toISOString() };
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
      const inGoal = new Set<Stage>(GOAL_STAGES[this.batch(a.batchId)?.recipe.goal ?? 'ios']);
      for (const stage of STAGES) {
        if (!inGoal.has(stage)) continue;
        total++;
        if (satisfied(a.stages[stage])) finished++;
      }
    }
    const recent = this.finishedAt.filter((t) => t > this.now() - 15 * 60_000);
    let eta: number | null = null;
    if (recent.length >= 3 && total > finished) {
      const span = Math.max(60_000, this.now() - Math.min(...recent));
      eta = Math.round((total - finished) / (recent.length / span) / 1000);
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
    if (Object.values(recipe.engines).every((w) => !w || w <= 0)) recipe.engines = defaultRecipe().engines;
    recipe.maxAttempts = Math.min(5, Math.max(1, Math.floor(recipe.maxAttempts)));
    if (!recipe.languages.includes('en-US')) recipe.languages = ['en-US', ...recipe.languages];
    const batch: Batch = { id: nanoid(10), name: input.name.trim().slice(0, 60) || 'Batch', createdAt: new Date(this.now()).toISOString(), recipe, appIds: [] };
    const engines = assignEngines(
      input.ideas.map((i) => i.size ?? 'small'),
      recipe.engines,
      input.ideas.map((i) => i.engine),
    );
    const taken = new Set(Object.values(this.state.apps).map((a) => a.folder));
    const inGoal = new Set<Stage>(GOAL_STAGES[recipe.goal]);
    input.ideas.forEach((idea, i) => {
      const folder = uniqueSlug(slugFolder(idea.name), taken);
      taken.add(folder);
      const stages = emptyStages();
      for (const stage of STAGES) if (!inGoal.has(stage)) stages[stage] = { state: 'skipped', attempts: 0, message: 'outside' };
      const iso = new Date(this.now()).toISOString();
      const summary = idea.summary.trim();
      const app: FactoryApp = {
        id: nanoid(10),
        batchId: batch.id,
        order: i,
        name: idea.name.trim().slice(0, 30) || folder,
        summary,
        brief: idea.brief?.trim() || summary,
        size: idea.size ?? 'small',
        category: idea.category?.trim() ?? '',
        folder,
        engine: engines[i]!,
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

  updateSettings(patch: Partial<Omit<FactorySettings, 'dailyStoreCap'>> & { dailyStoreCap?: Partial<Record<StoreStage, number>> }): void {
    const s = this.state.settings;
    const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, Math.floor(v)));
    if (patch.lanes) s.lanes = { ...s.lanes, ...Object.fromEntries(Object.entries(patch.lanes).map(([k, v]) => [k, clamp(v, 0, 32)])) };
    if (patch.maxInFlight !== undefined) s.maxInFlight = clamp(patch.maxInFlight, 1, 100);
    if (patch.dailyStoreCap?.play !== undefined) s.dailyStoreCap.play = clamp(patch.dailyStoreCap.play, 0, 500);
    if (patch.dailyStoreCap?.appstore !== undefined) s.dailyStoreCap.appstore = clamp(patch.dailyStoreCap.appstore, 0, 500);
    if (patch.minFreeDiskGb !== undefined) s.minFreeDiskGb = Math.max(0, Math.min(500, patch.minFreeDiskGb));
    this.lanes.setLimits(s.lanes);
    this.touch();
    this.dispatch();
  }

  /** Stops the app now (running stages are aborted) and keeps it listed as cancelled. */
  cancelApp(id: string): boolean {
    const app = this.state.apps[id];
    if (!app || TERMINAL.includes(app.state)) return false;
    const ctrl = this.drivers.get(id);
    if (ctrl) {
      ctrl.abort();
    } else {
      this.resetOpenStages(app);
      this.setAppState(app, 'cancelled');
      this.touch();
    }
    return true;
  }

  cancelBatch(batchId: string): number {
    return (this.batch(batchId)?.appIds ?? []).filter((id) => this.cancelApp(id)).length;
  }

  /**
   * Puts a failed, cancelled or waiting app back in line. [from] restarts that
   * stage and everything after it; without it, the stages that failed or are
   * blocked restart (or, for a cancelled app, whatever is not finished).
   */
  retryApp(id: string, from?: Stage): boolean {
    const app = this.state.apps[id];
    if (!app || this.drivers.has(id) || app.state === 'running') return false;
    const inGoal = new Set<Stage>(GOAL_STAGES[this.batch(app.batchId)?.recipe.goal ?? 'ios']);
    let starts: Stage[] = from ? [from] : STAGES.filter((s) => inGoal.has(s) && (app.stages[s].state === 'failed' || app.stages[s].state === 'blocked'));
    if (starts.length === 0) starts = STAGES.filter((s) => inGoal.has(s) && !satisfied(app.stages[s]));
    if (starts.length === 0) return false;
    const reset = new Set(starts.flatMap((s) => withDependents(s)));
    for (const stage of STAGES) if (reset.has(stage) && inGoal.has(stage)) app.stages[stage] = { state: 'pending', attempts: 0 };
    app.error = undefined;
    app.errorStage = undefined;
    app.notBefore = undefined;
    app.needs = app.needs.filter((n) => !reset.has(n.stage));
    this.setAppState(app, 'queued');
    this.addLog(app, `↻ ${starts.join(', ')}`);
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
   * Something the owner does once for every app was just done (a store account
   * was connected): every app waiting for exactly that goes on by itself.
   */
  resolveByKind(kinds: readonly NeedsKind[]): number {
    let n = 0;
    for (const app of this.orderedApps()) {
      if (app.state !== 'needs_you') continue;
      for (const need of [...app.needs]) if (kinds.includes(need.kind) && this.resolveNeed(app.id, need.id)) n++;
    }
    return n;
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
    if (opts.skip) {
      const stage = app.stages[need.stage];
      stage.state = 'skipped';
      stage.message = 'skipped_by_owner';
      stage.finishedAt = new Date(this.now()).toISOString();
    } else {
      app.stages[need.stage] = { state: 'pending', attempts: 0 };
    }
    // Several things can wait at once, each holding only its own stages: the app goes back in line so
    // whatever this one released runs now; what still waits for the owner stays blocked and parks it again.
    this.setAppState(app, 'queued');
    this.addLog(app, opts.skip ? `⤼ ${need.stage}` : `✓ ${need.title}`);
    this.touch();
    this.dispatch();
    return true;
  }

  /** Takes an app out of the Factory; [deleteProject] also removes what it built. */
  async removeApp(id: string, deleteProject = false): Promise<boolean> {
    const app = this.state.apps[id];
    if (!app) return false;
    const ctrl = this.drivers.get(id);
    if (ctrl) {
      ctrl.abort();
      for (let i = 0; i < 100 && this.drivers.has(id); i++) await this.sleep(20);
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
      if (app.state !== 'queued' || this.drivers.has(app.id)) continue;
      const until = app.notBefore ? Date.parse(app.notBefore) : 0;
      if (until > now) {
        wake = wake === null ? until : Math.min(wake, until);
        continue;
      }
      if (this.drivers.size >= this.state.settings.maxInFlight) continue;
      this.startDriver(app);
    }
    clearTimeout(this.wakeTimer ?? undefined);
    this.wakeTimer = null;
    if (wake !== null) {
      this.wakeTimer = setTimeout(() => this.dispatch(), Math.min(2 ** 31 - 1, Math.max(50, wake - now)));
      this.wakeTimer.unref?.();
    }
  }

  private startDriver(app: FactoryApp): void {
    const ctrl = new AbortController();
    this.drivers.set(app.id, ctrl);
    app.notBefore = undefined;
    this.setAppState(app, 'running');
    this.touch();
    void this.drive(app, ctrl.signal)
      .catch((e: unknown) => {
        if (e instanceof AbortedError) {
          this.resetOpenStages(app);
          app.doing = undefined;
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

  /** The stages of [app] that can start now: waiting, everything they need finished, and not told to wait. */
  private readyStages(app: FactoryApp): Stage[] {
    const now = this.now();
    const inGoal = new Set<Stage>(GOAL_STAGES[this.batch(app.batchId)?.recipe.goal ?? 'ios']);
    return STAGES.filter((s) => {
      const run = app.stages[s];
      if (!inGoal.has(s) || run.state !== 'pending') return false;
      if (run.until && Date.parse(run.until) > now) return false;
      return DEPS[s].every((d) => satisfied(app.stages[d]));
    });
  }

  /**
   * The route of one app. Every stage whose requirements are done starts at
   * once (each in its own lane), so the logo, the web preview and the store
   * texts go side by side and the iPhone side never waits for the Android side.
   * It ends when nothing is running and nothing can start.
   */
  private async drive(app: FactoryApp, signal: AbortSignal): Promise<void> {
    const running = new Map<Stage, Promise<void>>();
    let aborted = false;
    for (;;) {
      if (signal.aborted) break;
      for (const stage of this.readyStages(app)) {
        if (running.has(stage)) continue;
        app.stages[stage].state = 'queued';
        running.set(
          stage,
          this.runStage(app, stage, signal)
            .catch((e: unknown) => {
              if (e instanceof AbortedError) aborted = true;
              else {
                app.stages[stage].state = 'failed';
                this.fail(app, stage, e instanceof Error ? e.message : String(e));
              }
            })
            .finally(() => void running.delete(stage)),
        );
      }
      if (running.size === 0) break;
      await Promise.race(running.values());
    }
    await Promise.allSettled(running.values());
    if (signal.aborted || aborted) throw new AbortedError();
    this.settle(app);
  }

  /** Decides what the app is once nothing more can run: failed, waiting for the owner, waiting its turn, or done. */
  private settle(app: FactoryApp): void {
    app.doing = undefined;
    const inGoal = new Set<Stage>(GOAL_STAGES[this.batch(app.batchId)?.recipe.goal ?? 'ios']);
    const open = STAGES.filter((s) => inGoal.has(s));
    const failed = open.find((s) => app.stages[s].state === 'failed');
    if (failed) {
      app.error = app.error ?? app.stages[failed].message;
      app.errorStage = app.errorStage ?? failed;
      this.setAppState(app, 'failed');
    } else if (open.some((s) => app.stages[s].state === 'blocked')) {
      this.setAppState(app, 'needs_you');
    } else if (open.every((s) => satisfied(app.stages[s]))) {
      this.setAppState(app, 'done');
      void this.opts.ops.cleanup?.(app).catch(() => {});
    } else {
      const waits = open.map((s) => app.stages[s].until).filter((u): u is string => !!u);
      app.notBefore = waits.sort()[0];
      this.setAppState(app, 'queued');
    }
    this.touch();
  }

  /**
   * A place in today's cap came back (an upload failed, or needed the owner). Apps that were sent to
   * wait for tomorrow because the cap was full may try now: as many as there are free places, in
   * their usual order. Without this the place would be wasted on a day with ready apps waiting.
   */
  private wakeCapWaiters(store: StoreStage): void {
    let free = this.state.settings.dailyStoreCap[store] - this.state.storeDay[store];
    if (free <= 0) return;
    const now = this.now();
    let woke = false;
    for (const app of this.orderedApps()) {
      if (free <= 0) break;
      const run = app.stages[store];
      if (app.state !== 'queued' || this.drivers.has(app.id) || run.state !== 'pending' || !run.until || Date.parse(run.until) <= now) continue;
      run.until = undefined;
      run.message = undefined;
      // The app's own wait came from this stage alone, unless another stage is still told to wait.
      const others = STAGES.map((s) => app.stages[s].until).filter((u): u is string => !!u && Date.parse(u) > now);
      app.notBefore = others.sort()[0];
      free -= 1;
      woke = true;
    }
    if (woke) {
      this.touch();
      this.dispatch();
    }
  }

  private rollDay(): void {
    const day = dayKey(this.now());
    if (this.state.storeDay.date !== day) this.state.storeDay = { date: day, play: 0, appstore: 0 };
  }

  /** Runs one stage with retries and leaves its state set. Throws only AbortedError. */
  private async runStage(app: FactoryApp, stage: Stage, signal: AbortSignal): Promise<void> {
    const batch = this.batch(app.batchId)!;
    const recipe = batch.recipe;
    const run = app.stages[stage];
    const op = this.opts.ops.stages[stage];
    if (!op) {
      run.state = 'skipped';
      run.message = 'unavailable';
      this.touch();
      return;
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
      doing: (text) => {
        app.doing = text.slice(0, 160);
        this.touch();
      },
      update: (patch) => {
        Object.assign(app, patch);
        this.touch();
      },
      addCost: (usd) => {
        app.costUsd += usd;
      },
    };
    const store = isStoreStage(stage) ? stage : null;
    let reserved = false;
    const giveBack = () => {
      if (reserved && store) {
        this.rollDay();
        this.state.storeDay[store] = Math.max(0, this.state.storeDay[store] - 1);
        this.wakeCapWaiters(store);
      }
      reserved = false;
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
            if (store) {
              // The place in today's cap is taken as the upload starts, given back if it does not happen.
              this.rollDay();
              if (this.state.storeDay[store] >= this.state.settings.dailyStoreCap[store]) throw new RateLimited(`daily cap of ${store} uploads reached`, nextMidnight(this.now()) - this.now());
              this.state.storeDay[store] += 1;
              reserved = true;
            }
            run.state = 'running';
            run.attempts += 1;
            run.startedAt = new Date(this.now()).toISOString();
            run.finishedAt = undefined;
            run.until = undefined;
            this.touch();
            return op(ctx);
          },
          signal,
        );
        run.state = outcome && outcome.skipped ? 'skipped' : 'done';
        if (run.state === 'skipped') giveBack();
        run.message = (outcome && (outcome.skipped ?? outcome.message)) || undefined;
        run.finishedAt = new Date(this.now()).toISOString();
        this.finishedAt.push(this.now());
        if (this.finishedAt.length > 200) this.finishedAt.splice(0, this.finishedAt.length - 200);
        // Stages go side by side: the card keeps what the others are doing and only goes quiet when none is left.
        if (!STAGES.some((s) => s !== stage && app.stages[s].state === 'running')) app.doing = undefined;
        this.touch();
        return;
      } catch (e) {
        giveBack();
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
          this.addLog(app, `⏸ ${need.title}`);
          this.touch();
          return;
        }
        if (e instanceof RateLimited) {
          run.attempts = Math.max(0, run.attempts - 1);
          this.addLog(app, `⏳ ${e.message}`);
          if (e.lane) {
            this.lanes.pauseLane(e.lane, e.retryAfterMs);
            // Another engine of the batch may be free: the app moves there.
            const others = Object.keys(recipe.engines).filter((x) => (recipe.engines as Record<string, number>)[x]! > 0 && x !== app.engine && !this.lanes.isLanePaused(`agent:${x}`));
            if (e.lane.startsWith('agent:') && stage === 'code' && others[0]) {
              this.addLog(app, `→ ${others[0]}`);
              app.engine = others[0] as typeof app.engine;
              continue;
            }
            if (++rateRetries > MAX_RATE_RETRIES) {
              run.state = 'failed';
              run.message = e.message;
              this.fail(app, stage, e.message);
              return;
            }
            continue;
          }
          // Not an engine's limit but this app's turn (a daily cap): the stage steps aside and comes back.
          run.state = 'pending';
          run.until = new Date(this.now() + e.retryAfterMs).toISOString();
          run.message = e.message;
          this.touch();
          return;
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
        this.fail(app, stage, message);
        return;
      }
    }
  }

  private fail(app: FactoryApp, stage: Stage, message: string): void {
    app.error = app.error ?? message.slice(0, 600);
    app.errorStage = app.errorStage ?? stage;
    this.touch();
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
