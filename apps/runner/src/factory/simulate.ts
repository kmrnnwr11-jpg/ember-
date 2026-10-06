import type { Ops, StageOp } from './engine.js';
import { NeedsOwner, RateLimited, STAGES, type Stage } from './types.js';

/**
 * Pretend operations, for trying the interface with a hundred apps without
 * spending a subscription or building anything. Each stage takes a few seconds,
 * some fail once, some need the owner, an engine now and then reaches its
 * limit. Switched on with EMBER_FACTORY_SIMULATE=1.
 */

/** A small deterministic generator, so the same app always behaves the same. */
function hash(text: string): number {
  let h = 2166136261;
  for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 16777619);
  return (h >>> 0) / 2 ** 32;
}

const SECONDS: Record<Stage, [number, number]> = {
  create: [0.5, 1],
  code: [4, 9],
  verify: [1.5, 3],
  preview: [2, 4],
  logo: [2, 4],
  listing: [2, 4],
  shots: [1.5, 3],
  android: [3, 6],
  play: [1.5, 3],
  ios: [3, 6],
  appstore: [1.5, 3],
};

const DOING: Partial<Record<Stage, string[]>> = {
  code: ['Writes lib/main.dart', 'Writes lib/home_screen.dart', 'Writes lib/settings.dart', 'Writes pubspec.yaml'],
  verify: ['flutter pub get', 'flutter analyze'],
  preview: ['flutter build web'],
  android: ['gradle bundleRelease'],
  ios: ['xcodebuild archive'],
};

export function simulatedOps(opts: { speed?: number; mac?: boolean } = {}): Ops {
  const speed = Math.max(0.01, opts.speed ?? 1);
  const attemptsSeen = new Map<string, number>();
  const stages: Partial<Record<Stage, StageOp>> = {};
  for (const stage of STAGES) {
    stages[stage] = async (ctx) => {
      const key = `${ctx.app.id}:${stage}`;
      const seen = (attemptsSeen.get(key) ?? 0) + 1;
      attemptsSeen.set(key, seen);
      const roll = hash(key);
      const [lo, hi] = SECONDS[stage];
      const total = (lo + (hi - lo) * hash(`${key}:t`)) * 1000 * speed;
      const steps = DOING[stage] ?? [stage];
      for (let i = 0; i < steps.length; i++) {
        ctx.doing(steps[i]!);
        await wait(total / steps.length, ctx.signal);
      }
      if (stage === 'create') ctx.update({ packageName: `com.emberapps.${ctx.app.folder}` });
      if (stage === 'code') {
        ctx.addCost(0.1 + hash(`${key}:c`) * 0.6);
        // An engine now and then reaches its limit; the Factory moves on to another.
        if (roll < 0.02 && seen === 1) throw new RateLimited(`${ctx.app.engine} usage limit`, 20_000 * speed, `agent:${ctx.app.engine}`);
      }
      if ((stage === 'code' || stage === 'verify' || stage === 'android') && roll < 0.07 && seen === 1) throw new Error(`${stage}: simulated error, the second attempt works`);
      if (stage === 'logo' && roll > 0.97 && seen <= ctx.recipe.maxAttempts) throw new Error('logo: simulated failure');
      if (stage === 'play' && roll < 0.2 && seen === 1) {
        throw new NeedsOwner({
          kind: 'play_console_app',
          title: `Create "${ctx.app.name}" in Play Console`,
          detail: 'Google Play cannot create an app by itself.',
          data: { name: ctx.app.name, package: ctx.app.packageName ?? ctx.app.folder, shortDescription: ctx.app.summary.slice(0, 80), category: ctx.app.category || 'tools' },
        });
      }
      if (stage === 'ios' && !opts.mac) {
        throw new NeedsOwner({ kind: 'mac', title: 'A Mac is needed for the iPhone file', detail: 'Apple only allows building the iPhone app on a Mac.', data: {} });
      }
      if (stage === 'appstore' && roll > 0.85 && seen === 1) {
        throw new NeedsOwner({ kind: 'apple_app_record', title: `Create "${ctx.app.name}" in App Store Connect`, detail: 'The app record must exist first.', data: { name: ctx.app.name, bundleId: ctx.app.packageName ?? ctx.app.folder, sku: ctx.app.folder } });
      }
      ctx.log(`${stage} ok`);
      return { message: `${stage} ok (simulated)` };
    };
  }
  return { stages, freeDiskGb: async () => 500 };
}

function wait(ms: number, signal: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal.aborted) return reject(new Error('aborted'));
    const t = setTimeout(() => {
      signal.removeEventListener('abort', onAbort);
      resolve();
    }, ms);
    const onAbort = () => {
      clearTimeout(t);
      reject(new Error('aborted'));
    };
    signal.addEventListener('abort', onAbort, { once: true });
  });
}

/** A made-up supervisor: turns a theme into cards without any AI. */
export function simulatedComplete(): (system: string, prompt: string) => Promise<string> {
  const nouns = ['Planner', 'Tracker', 'Coach', 'Timer', 'Journal', 'Quiz', 'Scanner', 'Helper', 'Mixer', 'Guide', 'Log', 'Buddy'];
  const topics = ['garden soil', 'guitar chords', 'receipts', 'sleep sounds', 'running pace', 'pantry recipes', 'flashcards', 'bird sightings', 'budget envelopes', 'breathing', 'chess openings', 'plant health', 'train alerts', 'pet vaccines', 'cycling routes', 'language idioms', 'tea brewing', 'stretching', 'star gazing', 'coin collecting'];
  const audiences = ['beginners', 'busy families', 'frequent travellers', 'keen athletes', 'university students'];
  const features = ['weekly charts', 'gentle reminders', 'a shareable summary', 'a dark theme', 'a streak counter', 'quick notes', 'offline backups'];
  let n = 0;
  return async (_system, prompt) => {
    const asked = Number(/Invent (\d+)/.exec(prompt)?.[1] ?? 0);
    if (!asked) return '[]';
    const cards = Array.from({ length: asked }, () => {
      const i = n++;
      const topic = topics[i % topics.length]!;
      const name = `${topic.split(' ')[0]!.replace(/^./, (c) => c.toUpperCase())} ${nouns[(i * 7) % nouns.length]}${i >= topics.length ? ` ${Math.floor(i / topics.length) + 1}` : ''}`;
      const noun = nouns[(i * 7) % nouns.length]!;
      const audience = audiences[i % audiences.length]!;
      const feature = features[Math.floor(i / topics.length) % features.length]!;
      return {
        name,
        summary: `A ${noun.toLowerCase()} for ${topic} aimed at ${audience}, with ${feature}`,
        brief: `Build a polished ${topic} app for ${audience} with a home screen, a detail screen and a settings screen, featuring ${feature}. Data stays on the phone.`,
        size: i % 6 === 0 ? 'big' : 'small',
        category: 'tools',
      };
    });
    return JSON.stringify(cards);
  };
}
