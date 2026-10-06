import { statfs } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { FACTORY_ENGINES, type FactorySettings } from './types.js';

/**
 * What this machine can carry. A Gradle build needs about 3 GB and four cores;
 * an AI agent process about half a GB. The Factory starts from these numbers
 * and the owner can change them.
 */
export interface Capacity {
  cpus: number;
  totalRamMb: number;
  freeRamMb: number;
  freeDiskGb: number | null;
  buildSlots: number;
  agentSlots: number;
  suggested: { lanes: Record<string, number>; maxInFlight: number };
}

const BUILD_MB = 3000;
const AGENT_MB = 500;

export async function freeDiskGb(dir: string): Promise<number | null> {
  try {
    const s = await statfs(path.resolve(dir));
    return Math.round(((s.bavail * s.bsize) / 1024 ** 3) * 10) / 10;
  } catch {
    return null;
  }
}

/** Pure part of [capacity]: the numbers in, the suggestion out. */
export function suggest(cpus: number, totalRamMb: number): Pick<Capacity, 'buildSlots' | 'agentSlots' | 'suggested'> {
  const buildSlots = Math.max(1, Math.min(8, Math.floor(Math.min(cpus / 4, (totalRamMb * 0.7) / BUILD_MB))));
  const agentSlots = Math.max(2, Math.min(16, Math.floor((totalRamMb * 0.5) / AGENT_MB)));
  const perEngine = Math.max(1, Math.round(agentSlots / 2));
  const lanes: FactorySettings['lanes'] = {
    light: Math.max(2, Math.min(6, Math.floor(cpus / 3))),
    text: Math.max(2, Math.min(4, perEngine)),
    build: buildSlots,
    image: 2,
    shots: 1,
    store: 2,
    ...Object.fromEntries(FACTORY_ENGINES.map((e) => [`agent:${e}`, e === 'codex' ? Math.max(1, perEngine - 1) : perEngine])),
  };
  return { buildSlots, agentSlots, suggested: { lanes, maxInFlight: Math.max(4, Math.min(24, buildSlots * 4 + agentSlots)) } };
}

export async function capacity(workspacesRoot: string): Promise<Capacity> {
  const cpus = os.cpus().length;
  const totalRamMb = Math.round(os.totalmem() / 1024 ** 2);
  return {
    cpus,
    totalRamMb,
    freeRamMb: Math.round(os.freemem() / 1024 ** 2),
    freeDiskGb: await freeDiskGb(workspacesRoot),
    ...suggest(cpus, totalRamMb),
  };
}
