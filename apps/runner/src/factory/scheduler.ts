/**
 * Lanes: pools of parallel slots with an ordered waiting line.
 *
 * A hundred apps want the same few scarce things — an AI engine's attention,
 * a Gradle build, a store's API — so each of those is a lane with its own
 * limit. Whoever asks for a lane waits in a line ordered by priority (lower
 * first) and then by arrival; when a slot frees, the next in line starts.
 * A lane can be paused for a while (the engine said its usage limit is
 * reached) and everything can be paused at once; work already running is left
 * to finish.
 */

export class AbortedError extends Error {
  constructor(message = 'aborted') {
    super(message);
    this.name = 'AbortedError';
  }
}

interface Waiter {
  seq: number;
  lane: string;
  priority: number;
  start: () => void;
  reject: (e: Error) => void;
  signal?: AbortSignal;
  onAbort?: () => void;
}

export interface LaneInfo {
  limit: number;
  running: number;
  waiting: number;
  /** ISO time until which the lane is paused, when it is. */
  pausedUntil?: string;
}

export class Lanes {
  private readonly limits = new Map<string, number>();
  private readonly running = new Map<string, number>();
  private readonly pausedUntil = new Map<string, number>();
  private readonly timers = new Map<string, NodeJS.Timeout>();
  private waiters: Waiter[] = [];
  private allPaused = false;
  private seq = 0;

  constructor(
    limits: Record<string, number> = {},
    private readonly now: () => number = Date.now,
  ) {
    this.setLimits(limits);
  }

  /** Lanes nobody configured allow one at a time. */
  limitOf(lane: string): number {
    return this.limits.get(lane) ?? 1;
  }

  setLimits(limits: Record<string, number>): void {
    for (const [lane, n] of Object.entries(limits)) this.limits.set(lane, Math.max(0, Math.floor(n)));
    this.pump();
  }

  /** Stops (or lets go) every lane. Work already running is not interrupted. */
  setPaused(paused: boolean): void {
    this.allPaused = paused;
    if (!paused) this.pump();
  }

  /** One lane takes no new work for [ms]. */
  pauseLane(lane: string, ms: number): void {
    const until = this.now() + Math.max(0, ms);
    if (until <= (this.pausedUntil.get(lane) ?? 0)) return;
    this.pausedUntil.set(lane, until);
    clearTimeout(this.timers.get(lane));
    const t = setTimeout(() => {
      this.pausedUntil.delete(lane);
      this.timers.delete(lane);
      this.pump();
    }, ms);
    t.unref?.();
    this.timers.set(lane, t);
  }

  isLanePaused(lane: string): boolean {
    return (this.pausedUntil.get(lane) ?? 0) > this.now();
  }

  /** Runs [fn] in [lane] as soon as there is a slot and it is this one's turn. */
  run<T>(lane: string, priority: number, fn: () => Promise<T>, signal?: AbortSignal): Promise<T> {
    if (signal?.aborted) return Promise.reject(new AbortedError());
    return new Promise<T>((resolve, reject) => {
      const waiter: Waiter = {
        seq: this.seq++,
        lane,
        priority,
        signal,
        reject,
        start: () => {
          if (waiter.onAbort) signal?.removeEventListener('abort', waiter.onAbort);
          this.running.set(lane, (this.running.get(lane) ?? 0) + 1);
          Promise.resolve().then(fn).then(resolve, reject).finally(() => {
            this.running.set(lane, Math.max(0, (this.running.get(lane) ?? 1) - 1));
            this.pump();
          });
        },
      };
      if (signal) {
        waiter.onAbort = () => {
          this.waiters = this.waiters.filter((w) => w !== waiter);
          reject(new AbortedError());
        };
        signal.addEventListener('abort', waiter.onAbort, { once: true });
      }
      this.waiters.push(waiter);
      this.pump();
    });
  }

  snapshot(): Record<string, LaneInfo> {
    const lanes = new Set<string>([...this.limits.keys(), ...this.running.keys(), ...this.waiters.map((w) => w.lane)]);
    const out: Record<string, LaneInfo> = {};
    for (const lane of [...lanes].sort()) {
      const until = this.pausedUntil.get(lane) ?? 0;
      out[lane] = {
        limit: this.limitOf(lane),
        running: this.running.get(lane) ?? 0,
        waiting: this.waiters.filter((w) => w.lane === lane).length,
        ...(until > this.now() ? { pausedUntil: new Date(until).toISOString() } : {}),
      };
    }
    return out;
  }

  private pump(): void {
    if (this.allPaused || this.waiters.length === 0) return;
    this.waiters.sort((a, b) => a.priority - b.priority || a.seq - b.seq);
    const started: Waiter[] = [];
    for (const w of this.waiters) {
      if (this.isLanePaused(w.lane)) continue;
      const taken = (this.running.get(w.lane) ?? 0) + started.filter((s) => s.lane === w.lane).length;
      if (taken >= this.limitOf(w.lane)) continue;
      started.push(w);
    }
    if (started.length === 0) return;
    this.waiters = this.waiters.filter((w) => !started.includes(w));
    for (const w of started) w.start();
  }
}
