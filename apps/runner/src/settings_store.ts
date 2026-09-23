import { chmod, mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

/**
 * What the user typed once in the IDE — GitHub token, Play service account, AI
 * keys, chat history, choices — kept on the Runner, not in the browser.
 *
 * The browser is the wrong place: `flutter run -d chrome` opens a throw-away
 * profile, so everything saved there vanished at every restart of the IDE, and
 * a second browser or computer never saw it. Here it lives in
 * ~/.ember/settings/<user>.json, 0600 like ~/.ssh keys and the Apple key, never
 * in git, and survives restarts, reboots and any browser.
 */

export const SETTING_KEY = /^[A-Za-z0-9_.:@-]{1,160}$/;
/** Chat histories are the biggest values (200 messages). */
export const MAX_VALUE = 2 * 1024 * 1024;

function home(): string {
  return process.env.EMBER_SETTINGS_DIR?.trim() || path.join(os.homedir(), '.ember', 'settings');
}

const fileOf = (owner: string) => path.join(home(), `${owner.replace(/[^A-Za-z0-9_-]/g, '_')}.json`);

/** One write at a time per user, so two quick saves never lose each other. */
const queues = new Map<string, Promise<unknown>>();

async function load(owner: string): Promise<Record<string, string>> {
  try {
    const raw = JSON.parse(await readFile(fileOf(owner), 'utf8')) as unknown;
    return raw && typeof raw === 'object' ? (raw as Record<string, string>) : {};
  } catch (e) {
    if ((e as NodeJS.ErrnoException).code === 'ENOENT') return {};
    throw e;
  }
}

async function save(owner: string, values: Record<string, string>): Promise<void> {
  const file = fileOf(owner);
  await mkdir(path.dirname(file), { recursive: true, mode: 0o700 });
  const tmp = `${file}.${process.pid}.tmp`;
  await writeFile(tmp, JSON.stringify(values, null, 1), { mode: 0o600 });
  await chmod(tmp, 0o600).catch(() => {});
  await rename(tmp, file); // atomic: a crash never leaves half a file
}

function serial<T>(owner: string, job: () => Promise<T>): Promise<T> {
  const next = (queues.get(owner) ?? Promise.resolve()).then(job, job);
  queues.set(owner, next.catch(() => {}));
  return next;
}

export const readSettings = (owner: string) => load(owner);

/** Sets several values at once (undefined/null removes a key). */
export function writeSettings(owner: string, patch: Record<string, string | null | undefined>): Promise<Record<string, string>> {
  return serial(owner, async () => {
    const values = await load(owner);
    for (const [k, v] of Object.entries(patch)) {
      if (!SETTING_KEY.test(k)) throw new Error(`bad setting key: ${k}`);
      if (v === null || v === undefined) delete values[k];
      else values[k] = v;
    }
    await save(owner, values);
    return values;
  });
}
