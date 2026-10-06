import type { Config } from '../config.js';
import { capacity, type Capacity } from './capacity.js';
import { Factory, type Ops } from './engine.js';
import { FileStateStore } from './state_store.js';
import type { FactoryEngine } from './types.js';

/** One readiness check: whether it works, and why not (a code, not a sentence). */
export interface Link {
  ready: boolean;
  detail: string;
}

export type LinkName = 'claude' | 'qwen' | 'gemini' | 'codex' | 'flutter' | 'android' | 'chrome' | 'playKey' | 'appleKey' | 'mac';
export type Links = Record<LinkName, Link>;

export interface Connections {
  links: Links;
  capacity: Capacity;
  simulated: boolean;
}

/** Which engine each connection name stands for. */
export const ENGINE_LINK: Record<FactoryEngine, LinkName> = { 'claude-code': 'claude', 'qwen-code': 'qwen', 'gemini-cli': 'gemini', codex: 'codex' };

/** Raised when no AI engine is connected to answer the supervisor. */
export class NoAi extends Error {
  readonly code = 'no_ai';
  constructor() {
    super('No AI engine is connected on this computer');
  }
}

export interface FactoryDeps {
  cfg: Config;
  /** The real stage operations for an owner (or pretend ones when simulating). */
  opsFor(ownerId: string, email?: string): Ops;
  /** One answer from the best engine that is connected; throws [NoAi] when there is none. */
  complete(ownerId: string, system: string, prompt: string): Promise<string>;
  links(ownerId: string): Promise<Links>;
  simulated: boolean;
}

/** One Factory per owner, started the first time it is asked for. */
export class FactoryService {
  private readonly factories = new Map<string, Promise<Factory>>();

  constructor(readonly deps: FactoryDeps) {}

  forOwner(ownerId: string, email?: string): Promise<Factory> {
    let f = this.factories.get(ownerId);
    if (!f) {
      f = this.start(ownerId, email);
      this.factories.set(ownerId, f);
    }
    return f;
  }

  private async start(ownerId: string, email?: string): Promise<Factory> {
    const ops = this.deps.opsFor(ownerId, email);
    const factory = new Factory({
      store: FileStateStore.forOwner(this.deps.cfg.DATA_DIR, `${ownerId}${this.deps.simulated ? '_sim' : ''}`),
      ops,
      // Pretend failures are retried as fast as pretend work goes.
      ...(this.deps.simulated ? { retryBackoffMs: Math.max(5, 5000 * this.deps.cfg.EMBER_FACTORY_SIM_SPEED) } : {}),
    });
    await factory.init();
    // A Factory seen for the first time starts from what this computer can carry.
    if (factory.rev === 0) {
      const cap = await capacity(this.deps.cfg.WORKSPACES_ROOT);
      // Pretend work uses nothing, so a demo gets wide lanes and moves fast.
      const lanes = this.deps.simulated ? Object.fromEntries(Object.entries(cap.suggested.lanes).map(([k, v]) => [k, k === 'build' ? 4 : k.startsWith('agent:') ? 6 : Math.max(v, 3)])) : cap.suggested.lanes;
      factory.updateSettings({ lanes, maxInFlight: this.deps.simulated ? 24 : cap.suggested.maxInFlight });
    }
    return factory;
  }

  async connections(ownerId: string): Promise<Connections> {
    const [links, cap] = await Promise.all([this.deps.links(ownerId), capacity(this.deps.cfg.WORKSPACES_ROOT)]);
    return { links, capacity: cap, simulated: this.deps.simulated };
  }

  /** The engines that are connected now, in order of strength. */
  async connectedEngines(ownerId: string): Promise<FactoryEngine[]> {
    const { links } = await this.connections(ownerId);
    const all: FactoryEngine[] = ['claude-code', 'codex', 'gemini-cli', 'qwen-code'];
    return all.filter((e) => links[ENGINE_LINK[e]].ready);
  }

  async shutdown(): Promise<void> {
    for (const p of this.factories.values()) await (await p).shutdown().catch(() => {});
  }
}
