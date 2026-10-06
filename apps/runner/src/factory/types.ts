/**
 * The Factory: many apps, from idea to the stores, worked on at the same time.
 *
 * One app moves through the stages below. Each stage belongs to a lane (a pool
 * with its own limit, see scheduler.ts), so the machine is never asked to do
 * more than it can: AI agents run a handful at a time, Gradle builds one or
 * two, and everything else waits its turn in an ordered queue.
 */

export const STAGES = ['create', 'code', 'verify', 'preview', 'logo', 'shots', 'listing', 'android', 'play', 'ios', 'appstore'] as const;
export type Stage = (typeof STAGES)[number];

export type StageState = 'pending' | 'queued' | 'running' | 'done' | 'skipped' | 'blocked' | 'failed';

/** Where an app is as a whole. `needs_you` waits for the owner and holds no slot. */
export type AppState = 'queued' | 'running' | 'needs_you' | 'done' | 'failed' | 'cancelled';

/** AI engines that write the code (subscriptions logged in on the Runner machine). */
export const FACTORY_ENGINES = ['claude-code', 'qwen-code', 'gemini-cli', 'codex'] as const;
export type FactoryEngine = (typeof FACTORY_ENGINES)[number];

/** How far the Factory takes every app of a batch. */
export type Reach = 'app' | 'assets' | 'android' | 'both';

/** The stages each reach includes. */
export const REACH_STAGES: Record<Reach, readonly Stage[]> = {
  app: ['create', 'code', 'verify', 'preview'],
  assets: ['create', 'code', 'verify', 'preview', 'logo', 'shots', 'listing'],
  android: ['create', 'code', 'verify', 'preview', 'logo', 'shots', 'listing', 'android', 'play'],
  both: STAGES,
};

export type LogoBy = 'auto' | 'codex' | 'claude_code' | 'gemini_runner';

export interface Recipe {
  /** Who writes the code, with weights: apps are shared out in that proportion. */
  engines: Array<{ engine: FactoryEngine; weight: number }>;
  quality: 'fast' | 'best';
  logoBy: LogoBy;
  reach: Reach;
  play: { track: 'internal' | 'alpha' | 'beta' | 'production'; status: 'draft' | 'completed' };
  appstore: { submit: boolean };
  /** Sending for review is only ever done when the owner confirmed it for this batch. */
  confirmSubmit: boolean;
  /** Store listing languages (Google Play codes), the English one is always first. */
  languages: string[];
  maxAttempts: number;
  /** Extra instructions added to every app of the batch (e.g. "no sign-in, offline only"). */
  extra: string;
}

export interface StageRun {
  state: StageState;
  attempts: number;
  startedAt?: string;
  finishedAt?: string;
  /** What happened, in one line (why it failed, why it was skipped, what it made). */
  message?: string;
}

/** Something only the owner can do, with what is needed to do it. */
export interface NeedsYou {
  id: string;
  kind: 'play_console_app' | 'apple_app_record' | 'mac' | 'play_key' | 'apple_key' | 'login' | 'confirm' | 'other';
  stage: Stage;
  title: string;
  detail: string;
  /** Values to copy (name, package, bundle id, short description…). */
  data: Record<string, string>;
  createdAt: string;
}

export interface FactoryApp {
  id: string;
  batchId: string;
  /** Position in the batch: earlier apps are served first. */
  order: number;
  name: string;
  idea: string;
  /** Project folder name (unique), also the Flutter package name. */
  folder: string;
  projectId?: string;
  packageName?: string;
  engine: FactoryEngine;
  state: AppState;
  stages: Record<Stage, StageRun>;
  /** Stage being worked on or waited for right now. */
  current?: Stage;
  needs: NeedsYou[];
  error?: string;
  errorStage?: Stage;
  /** Latest lines of what happened, newest last. */
  log: string[];
  costUsd: number;
  /** Not before this time (a rate limit or a daily cap); ISO string. */
  notBefore?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Batch {
  id: string;
  name: string;
  createdAt: string;
  recipe: Recipe;
  appIds: string[];
}

export interface FactorySettings {
  /** Parallel work per lane. Keys: light, build, image, shots, store, agent:<engine>. */
  lanes: Record<string, number>;
  /** Apps being worked on at once, from `create` to the last stage. */
  maxInFlight: number;
  /** Applications sent for review per day, across the stores. */
  dailySubmitLimit: number;
  /** Below this much free disk the Factory stops starting apps and clears build folders. */
  minFreeDiskGb: number;
}

export interface FactoryState {
  /** Rises with every change: clients ask "anything newer than N?". */
  rev: number;
  paused: boolean;
  /** Set when the Runner restarted while work was running. */
  interrupted: boolean;
  batches: Batch[];
  apps: Record<string, FactoryApp>;
  settings: FactorySettings;
  /** When reviews were sent (ISO), for the daily cap. */
  submitLog: string[];
}

/** One line per idea the owner gave. */
export interface Idea {
  name: string;
  idea: string;
}

export interface Summary {
  total: number;
  queued: number;
  running: number;
  needsYou: number;
  done: number;
  failed: number;
  cancelled: number;
  /** Apps whose Google Play stage is done / whose App Store stage is done. */
  onPlay: number;
  onAppStore: number;
  /** Share of all stages (not skipped) that are finished, 0..1. */
  progress: number;
  /** Seconds left at the speed so far, when it can be told. */
  etaSeconds: number | null;
}

/** Thrown by an operation when the engine says its usage limit is reached. */
export class RateLimited extends Error {
  constructor(
    message: string,
    readonly retryAfterMs: number,
    readonly lane?: string,
  ) {
    super(message);
    this.name = 'RateLimited';
  }
}

/** Thrown by an operation when the owner must do something before it can go on. */
export class NeedsOwner extends Error {
  constructor(readonly need: Omit<NeedsYou, 'id' | 'createdAt' | 'stage'> & { stage?: Stage }) {
    super(need.title);
    this.name = 'NeedsOwner';
  }
}

/** The lane (pool of parallel slots) a stage runs in. */
export function laneOf(stage: Stage, engine: FactoryEngine): string {
  switch (stage) {
    case 'create':
    case 'verify':
      return 'light';
    case 'code':
      return `agent:${engine}`;
    case 'listing':
      return 'text';
    case 'preview':
    case 'android':
    case 'ios':
      return 'build';
    case 'logo':
      return 'image';
    case 'shots':
      return 'shots';
    case 'play':
    case 'appstore':
      return 'store';
  }
}

export const DEFAULT_LANGUAGES = ['en-US', 'it-IT', 'es-ES', 'fr-FR', 'de-DE', 'pt-BR', 'hi-IN', 'ar', 'id', 'ru-RU'];

export function defaultRecipe(): Recipe {
  return {
    engines: [{ engine: 'claude-code', weight: 1 }],
    quality: 'fast',
    logoBy: 'auto',
    reach: 'assets',
    play: { track: 'internal', status: 'completed' },
    appstore: { submit: false },
    confirmSubmit: false,
    languages: [...DEFAULT_LANGUAGES],
    maxAttempts: 2,
    extra: '',
  };
}

export function emptyStages(): Record<Stage, StageRun> {
  return Object.fromEntries(STAGES.map((s) => [s, { state: 'pending', attempts: 0 } satisfies StageRun])) as Record<Stage, StageRun>;
}
