import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import path from 'node:path';
import type { FactorySettings, FactoryState } from './types.js';

/** What a Runner without a configuration starts with; capacity.ts refines it from the machine. */
export function defaultSettings(): FactorySettings {
  return {
    lanes: { light: 3, text: 3, build: 2, image: 2, shots: 1, store: 2, 'agent:claude-code': 3, 'agent:qwen-code': 3, 'agent:gemini-cli': 3, 'agent:codex': 2 },
    maxInFlight: 12,
    dailySubmitLimit: 5,
    minFreeDiskGb: 10,
  };
}

export function emptyState(settings: FactorySettings = defaultSettings()): FactoryState {
  return { rev: 0, paused: false, interrupted: false, batches: [], apps: {}, settings, submitLog: [] };
}

/** Where the Factory keeps its state between runs. */
export interface StateStore {
  load(): Promise<FactoryState | null>;
  save(state: FactoryState): Promise<void>;
}

/** One JSON file per user, written atomically; saves are serialised and the last one wins. */
export class FileStateStore implements StateStore {
  private chain: Promise<void> = Promise.resolve();
  private pending: string | null = null;

  constructor(private readonly file: string) {}

  static forOwner(dataDir: string, ownerId: string): FileStateStore {
    return new FileStateStore(path.resolve(dataDir, 'factory', `${ownerId.replace(/[^A-Za-z0-9_-]/g, '_')}.json`));
  }

  async load(): Promise<FactoryState | null> {
    try {
      const raw = JSON.parse(await readFile(this.file, 'utf8')) as Partial<FactoryState>;
      if (!raw || typeof raw !== 'object' || !raw.apps || !Array.isArray(raw.batches)) return null;
      return { ...emptyState(), ...raw, settings: { ...defaultSettings(), ...(raw.settings ?? {}), lanes: { ...defaultSettings().lanes, ...(raw.settings?.lanes ?? {}) } } } as FactoryState;
    } catch (e) {
      if ((e as NodeJS.ErrnoException).code === 'ENOENT') return null;
      // A damaged file must not stop the Runner: keep it for inspection and start clean.
      await rename(this.file, `${this.file}.damaged-${Date.now()}`).catch(() => {});
      return null;
    }
  }

  save(state: FactoryState): Promise<void> {
    // Only the newest state matters: a burst of changes becomes one write.
    this.pending = JSON.stringify(state);
    const next = this.chain.then(async () => {
      const text = this.pending;
      if (text === null) return;
      this.pending = null;
      await mkdir(path.dirname(this.file), { recursive: true });
      const tmp = `${this.file}.${process.pid}.tmp`;
      await writeFile(tmp, text);
      await rename(tmp, this.file);
    });
    this.chain = next.catch(() => undefined);
    return next;
  }
}

/** Keeps the state in memory only (tests, simulation without disk). */
export class MemoryStateStore implements StateStore {
  saved: FactoryState | null = null;
  async load() {
    return this.saved ? (JSON.parse(JSON.stringify(this.saved)) as FactoryState) : null;
  }
  async save(state: FactoryState) {
    this.saved = JSON.parse(JSON.stringify(state)) as FactoryState;
  }
}
