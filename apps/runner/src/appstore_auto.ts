import { readdir, readFile, stat, writeFile, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { findIpa, projectBuildNumber } from './appstore.js';
import { lastAppStoreBuildNumber } from './signing.js';

/**
 * "Publish" as one press: build the iPhone app when needed, upload it, write
 * the store page, wait for Apple to process the build, attach it and send it
 * for review. It runs in the background because the wait alone takes 5-20
 * minutes; the IDE polls the status, and the status survives a closed page.
 */

export type AutoPhase = 'building' | 'publishing' | 'waiting' | 'submitted' | 'done' | 'failed';

export interface AutoStatus {
  phase: AutoPhase;
  /** What is happening now, in the user's words. */
  message: string;
  startedAt: string;
  updatedAt: string;
  /** Steps already done, oldest first. */
  steps: string[];
  notes: string[];
  error?: string;
  /** What the publish step returned (store page, screenshots…). */
  result?: Record<string, unknown>;
  /** Enough to resume the wait after a Runner restart. */
  wait?: { appId: string; versionId: string; buildNumber: number; submit: boolean };
}

const RUNNING: AutoPhase[] = ['building', 'publishing', 'waiting'];

export const isRunning = (s: AutoStatus | null | undefined) => !!s && RUNNING.includes(s.phase);

const file = (root: string) => path.join(root, 'store', 'appstore_auto.json');

export async function readAutoStatus(root: string): Promise<AutoStatus | null> {
  try {
    return JSON.parse(await readFile(file(root), 'utf8')) as AutoStatus;
  } catch {
    return null;
  }
}

async function writeAutoStatus(root: string, s: AutoStatus): Promise<void> {
  await mkdir(path.dirname(file(root)), { recursive: true });
  await writeFile(file(root), JSON.stringify(s, null, 2));
}

/** One status per project, kept in memory and mirrored to store/appstore_auto.json. */
export class AutoTracker {
  private readonly live = new Map<string, AutoStatus>();

  constructor(private readonly root: string) {}

  static async open(root: string): Promise<AutoTracker> {
    const t = new AutoTracker(root);
    const saved = await readAutoStatus(root);
    if (saved) t.live.set(root, saved);
    return t;
  }

  get status(): AutoStatus | null {
    return this.live.get(this.root) ?? null;
  }

  async start(phase: AutoPhase, message: string): Promise<void> {
    const now = new Date().toISOString();
    await this.save({ phase, message, startedAt: now, updatedAt: now, steps: [], notes: [] });
  }

  /** Moves on: the previous message becomes a finished step. */
  async phase(phase: AutoPhase, message: string, extra: Partial<AutoStatus> = {}): Promise<void> {
    const s = this.status;
    if (!s) return;
    const steps = s.message && s.message !== message && s.phase !== phase ? [...s.steps, s.message] : s.steps;
    await this.save({ ...s, ...extra, phase, message, steps, updatedAt: new Date().toISOString() });
  }

  /** Same phase, new detail (e.g. "processing, 7 min"). */
  async progress(message: string): Promise<void> {
    const s = this.status;
    if (!s || s.message === message) return;
    await this.save({ ...s, message, updatedAt: new Date().toISOString() });
  }

  async fail(error: string): Promise<void> {
    const s = this.status;
    if (!s) return;
    await this.save({ ...s, phase: 'failed', error, message: error, updatedAt: new Date().toISOString() });
  }

  private async save(s: AutoStatus): Promise<void> {
    this.live.set(this.root, s);
    await writeAutoStatus(this.root, s).catch(() => {});
  }
}

/** Newest modification time of the files that end up in the iPhone app. */
async function newestSource(root: string): Promise<number> {
  let newest = 0;
  const walk = async (dir: string) => {
    for (const e of await readdir(dir, { withFileTypes: true }).catch(() => [])) {
      if (e.name.startsWith('.') || e.name === 'Pods' || e.name === 'build') continue;
      const p = path.join(dir, e.name);
      if (e.isDirectory()) await walk(p);
      else newest = Math.max(newest, (await stat(p).catch(() => null))?.mtimeMs ?? 0);
    }
  };
  for (const d of ['lib', 'assets', path.join('ios', 'Runner')]) await walk(path.join(root, d));
  for (const f of ['pubspec.yaml']) newest = Math.max(newest, (await stat(path.join(root, f)).catch(() => null))?.mtimeMs ?? 0);
  return newest;
}

/**
 * Whether Publish must build the iPhone app first: there is no .ipa yet, Apple
 * already has this build number, or the code changed after the .ipa was made.
 */
export async function needsFreshIpa(root: string): Promise<{ build: boolean; upload: boolean; reason: string }> {
  const ipa = await findIpa(root);
  if (!ipa) return { build: true, upload: true, reason: 'nessun file iPhone ancora' };
  const [current, onApple] = await Promise.all([projectBuildNumber(root), lastAppStoreBuildNumber(root)]);
  const made = (await stat(ipa).catch(() => null))?.mtimeMs ?? 0;
  const changed = (await newestSource(root)) > made;
  // The .ipa Apple already has, with no change since: nothing to build or
  // send again, the publish attaches the build that is on Apple.
  if (current === onApple && !changed) return { build: false, upload: false, reason: `Apple ha già questa build (${current})` };
  if (current <= onApple) return { build: true, upload: true, reason: `Apple ha già la build ${onApple}` };
  if (changed) return { build: true, upload: true, reason: 'il codice è cambiato dopo l’ultima build' };
  return { build: false, upload: true, reason: `uso la build ${current} già pronta` };
}
