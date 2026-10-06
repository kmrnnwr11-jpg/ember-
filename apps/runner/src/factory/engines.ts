import { FACTORY_ENGINES, type AppSize, type FactoryEngine } from './types.js';

/** Strongest first: big apps are given to these before the others get a turn. */
export const STRENGTH: readonly FactoryEngine[] = ['claude-code', 'codex', 'gemini-cli', 'qwen-code'];

/**
 * Decides which engine writes each app: the batch is split in the proportion of
 * the weights (largest remainder, so the shares always add up), the big apps take
 * the strongest engines first and the small ones the weakest, so a subscription
 * that is good at big work is not spent on a calculator.
 * [fixed] holds engines chosen by hand for some apps; they are kept and counted.
 */
export function assignEngines(sizes: readonly AppSize[], weights: Partial<Record<FactoryEngine, number>>, fixed: ReadonlyArray<FactoryEngine | undefined> = []): FactoryEngine[] {
  let entries = FACTORY_ENGINES.map((e) => [e, Math.max(0, weights[e] ?? 0)] as const).filter(([, w]) => w > 0);
  if (entries.length === 0) entries = [['claude-code', 1]];
  const n = sizes.length;
  const free = sizes.map((_, i) => i).filter((i) => !fixed[i]);
  const total = entries.reduce((sum, [, w]) => sum + w, 0);
  const quota = new Map<FactoryEngine, number>();
  const fractions: Array<{ engine: FactoryEngine; frac: number }> = [];
  let given = 0;
  for (const [engine, w] of entries) {
    const raw = (free.length * w) / total;
    quota.set(engine, Math.floor(raw));
    given += Math.floor(raw);
    fractions.push({ engine, frac: raw - Math.floor(raw) });
  }
  fractions.sort((a, b) => b.frac - a.frac || STRENGTH.indexOf(a.engine) - STRENGTH.indexOf(b.engine));
  for (let i = 0; i < free.length - given; i++) {
    const engine = fractions[i % fractions.length]!.engine;
    quota.set(engine, (quota.get(engine) ?? 0) + 1);
  }

  const strongestFirst = STRENGTH.filter((e) => quota.has(e));
  const take = (order: readonly FactoryEngine[]): FactoryEngine => {
    const engine = order.find((e) => (quota.get(e) ?? 0) > 0) ?? order[0]!;
    quota.set(engine, (quota.get(engine) ?? 0) - 1);
    return engine;
  };
  const out = new Array<FactoryEngine>(n);
  for (let i = 0; i < n; i++) if (fixed[i]) out[i] = fixed[i]!;
  for (const i of free) if (sizes[i] === 'big') out[i] = take(strongestFirst);
  const weakestFirst = [...strongestFirst].reverse();
  for (const i of free) if (sizes[i] !== 'big') out[i] = take(weakestFirst);
  return out;
}
