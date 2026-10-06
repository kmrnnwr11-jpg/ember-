/**
 * The Factory: many apps, from idea to the stores, worked on at the same time.
 *
 * One app moves through the stages below. Each stage belongs to a lane (a pool
 * with its own limit, see scheduler.ts), so the machine is never asked to do
 * more than it can: AI agents run a handful at a time, Gradle builds one or
 * two, and everything else waits its turn in an ordered queue.
 *
 * Decisions taken by the owner (docs/FABBRICA_PIANO.md): everything is left as
 * a draft in testing (Google Play internal track + draft release, TestFlight),
 * nothing is ever published to production or sent for review, and uploads to
 * each store have a daily cap so the stores fill over days.
 */

export const STAGES = ['create', 'code', 'verify', 'preview', 'logo', 'listing', 'shots', 'android', 'play', 'ios', 'appstore'] as const;
export type Stage = (typeof STAGES)[number];

/**
 * What each stage needs finished first. After `verify` the road forks: the
 * logo, the web preview and the store texts are independent of each other, and
 * the iPhone side never waits for the Android side.
 */
export const DEPS: Record<Stage, readonly Stage[]> = {
  create: [],
  code: ['create'],
  verify: ['code'],
  preview: ['verify'],
  logo: ['verify'],
  listing: ['verify'],
  shots: ['preview'],
  android: ['logo', 'listing'],
  play: ['android', 'shots'],
  ios: ['logo', 'listing'],
  appstore: ['ios', 'shots'],
};

/** [stage] and every stage that (directly or not) needs it. */
export function withDependents(stage: Stage): Stage[] {
  const out = new Set<Stage>([stage]);
  let grew = true;
  while (grew) {
    grew = false;
    for (const s of STAGES) {
      if (!out.has(s) && DEPS[s].some((d) => out.has(d))) {
        out.add(s);
        grew = true;
      }
    }
  }
  return STAGES.filter((s) => out.has(s));
}

export type StageState = 'pending' | 'queued' | 'running' | 'done' | 'skipped' | 'blocked' | 'failed';

/** Where an app is as a whole. `needs_you` waits for the owner and holds no slot. */
export type AppState = 'queued' | 'running' | 'needs_you' | 'done' | 'failed' | 'cancelled';

/** AI engines that write the code (subscriptions logged in on the Runner machine). */
export const FACTORY_ENGINES = ['claude-code', 'codex', 'gemini-cli', 'qwen-code'] as const;
export type FactoryEngine = (typeof FACTORY_ENGINES)[number];

/** How far the Factory takes every app of a batch. Each goal includes the ones before it. */
export const GOALS = ['app', 'assets', 'android', 'ios'] as const;
export type Goal = (typeof GOALS)[number];

/** The stages each goal includes. */
export const GOAL_STAGES: Record<Goal, readonly Stage[]> = {
  app: ['create', 'code', 'verify', 'preview'],
  assets: ['create', 'code', 'verify', 'preview', 'logo', 'listing', 'shots'],
  android: ['create', 'code', 'verify', 'preview', 'logo', 'listing', 'shots', 'android', 'play'],
  ios: STAGES,
};

/** Where the stores get the apps. Fixed on purpose: drafts in testing, never production, never a review. */
export const STORE_TARGET = { playTrack: 'internal', playStatus: 'draft', appleMode: 'testflight' } as const;

/** Stages that upload to a store and count against its daily cap. */
export type StoreStage = 'play' | 'appstore';
export const isStoreStage = (s: Stage): s is StoreStage => s === 'play' || s === 'appstore';

export type LogoBy = 'codex' | 'claude_code' | 'gemini_runner' | 'auto';
export type AppSize = 'small' | 'big';

export interface Recipe {
  /** How many parts of the batch each engine writes (weights); big apps go to the strongest first. */
  engines: Partial<Record<FactoryEngine, number>>;
  quality: 'fast' | 'best';
  logoBy: LogoBy;
  goal: Goal;
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
  /** A stage that steps aside (a daily cap, a rate limit) does not start before this time; ISO string. */
  until?: string;
}

export type NeedsKind = 'play_console_app' | 'apple_app_record' | 'mac' | 'play_key' | 'apple_key' | 'login' | 'other';

/** Something only the owner can do, with what is needed to do it. */
export interface NeedsYou {
  id: string;
  kind: NeedsKind;
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
  summary: string;
  /** The full request for the coding agent; the summary when the supervisor wrote none. */
  brief: string;
  size: AppSize;
  category: string;
  /** Project folder name (unique), also the Flutter package name. */
  folder: string;
  workspaceId?: string;
  projectId?: string;
  packageName?: string;
  engine: FactoryEngine;
  state: AppState;
  stages: Record<Stage, StageRun>;
  needs: NeedsYou[];
  error?: string;
  errorStage?: Stage;
  /** Latest lines of what happened, newest last. */
  log: string[];
  /** What the app is doing right now, for its card. */
  doing?: string;
  costUsd: number;
  /** Not before this time (waiting for a daily cap or a rate limit); ISO string. */
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
  /** Parallel work per lane. Keys: light, text, build, image, shots, store, agent:<engine>. */
  lanes: Record<string, number>;
  /** Apps being worked on at once, from `create` to the last stage. */
  maxInFlight: number;
  /** Uploads to each store per local day. The rest waits, ready, for the next day. */
  dailyStoreCap: Record<StoreStage, number>;
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
  /** Uploads started today (local date) per store; a failed or blocked one gives its place back. */
  storeDay: { date: string; play: number; appstore: number };
}

/** One app idea: what the owner wrote or the supervisor made of it. */
export interface Idea {
  name: string;
  summary: string;
  brief?: string;
  size?: AppSize;
  category?: string;
  /** Fixed engine for this app; otherwise the batch's weights decide. */
  engine?: FactoryEngine;
}

export interface Summary {
  total: number;
  queued: number;
  running: number;
  needsYou: number;
  done: number;
  failed: number;
  cancelled: number;
  /** Apps whose upload to Google Play / App Store Connect is done. */
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
    /** The lane that rests; without one only this app steps aside. */
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
    engines: { 'claude-code': 1 },
    quality: 'fast',
    logoBy: 'codex',
    goal: 'android',
    languages: [...DEFAULT_LANGUAGES],
    maxAttempts: 2,
    extra: '',
  };
}

export function emptyStages(): Record<Stage, StageRun> {
  return Object.fromEntries(STAGES.map((s) => [s, { state: 'pending', attempts: 0 } satisfies StageRun])) as Record<Stage, StageRun>;
}

/** Local calendar day, the unit of the daily upload cap. */
export function dayKey(ms: number): string {
  const d = new Date(ms);
  const p = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

/** The next local midnight after [ms]: when the daily cap starts over. */
export function nextMidnight(ms: number): number {
  const d = new Date(ms);
  return new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1).getTime();
}
