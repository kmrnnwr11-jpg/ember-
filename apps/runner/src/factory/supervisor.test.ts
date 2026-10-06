import { describe, expect, it } from 'vitest';
import { assignEngines } from './engines.js';
import { cardsFromAnswer, chunkText, isPlainList, planApps } from './supervisor.js';
import type { AppSize } from './types.js';

const topics = ['gardening soil moisture', 'guitar chord practice', 'invoice scanning receipts', 'sleep sound mixing', 'marathon pacing splits', 'recipe pantry matching', 'language flashcards spacing', 'bird watching checklist', 'budget envelope saving', 'meditation breathing timer', 'chess opening drills', 'plant disease photo', 'train timetable alerts', 'pet vaccine reminders'];

/** A fake supervisor that invents [n] distinct cards per call. */
function inventor() {
  let next = 0;
  const prompts: string[] = [];
  const complete = async (_system: string, prompt: string) => {
    prompts.push(prompt);
    const cards = Array.from({ length: 4 }, () => {
      const i = next++;
      return { name: `Card${i}`, summary: `${topics[i % topics.length]} helper number ${i}`, brief: `Build ${topics[i % topics.length]}`, size: i % 5 === 0 ? 'big' : 'small', category: 'tools' };
    });
    return `Here are the cards:\n${JSON.stringify(cards)}`;
  };
  return { complete, prompts };
}

describe('cardsFromAnswer', () => {
  it('reads cards with text around the JSON and fills defaults', () => {
    const cards = cardsFromAnswer('ok [{"name":"A","summary":"does a","brief":"build a","size":"big","category":"Health"},{"name":"B","idea":"does b"},{"nope":1},"x"] bye');
    expect(cards).toEqual([
      { name: 'A', summary: 'does a', brief: 'build a', size: 'big', category: 'health' },
      { name: 'B', summary: 'does b', size: 'small' },
    ]);
    expect(cardsFromAnswer('no json')).toEqual([]);
    expect(cardsFromAnswer('[broken')).toEqual([]);
  });
});

describe('chunkText', () => {
  it('cuts at paragraph ends and never loses a word', () => {
    const text = Array.from({ length: 30 }, (_, i) => `Paragraph ${i} ${'word '.repeat(60)}`).join('\n\n');
    const chunks = chunkText(text, 2000);
    expect(chunks.length).toBeGreaterThan(3);
    expect(chunks.every((c) => c.length <= 2000)).toBe(true);
    expect(chunks.join('\n\n').replace(/\s+/g, ' ')).toBe(text.replace(/\s+/g, ' ').trim());
  });

  it('splits a single huge paragraph', () => {
    expect(chunkText('x'.repeat(5000), 2000)).toHaveLength(3);
  });
});

describe('planApps', () => {
  it('invents the asked number of distinct apps from a theme', async () => {
    const { complete, prompts } = inventor();
    const plan = await planApps('apps for people who garden', complete, { count: 10 });
    expect(plan.apps).toHaveLength(10);
    expect(new Set(plan.apps.map((a) => a.name)).size).toBe(10);
    expect(prompts.length).toBeGreaterThanOrEqual(2);
    expect(prompts[1]).toContain('Already taken');
    expect(plan.source).toBe('supervisor');
    expect(plan.apps.some((a) => a.size === 'big')).toBe(true);
  });

  it('never makes more than a hundred apps', async () => {
    const { complete } = inventor();
    const plan = await planApps('anything', complete, { count: 500 });
    expect(plan.apps.length).toBeLessThanOrEqual(100);
  });

  it('keeps the names of a plain list and takes briefs and sizes from the AI', async () => {
    const complete = async () => JSON.stringify([{ name: 'acqua di oggi', summary: 'water reminder', brief: 'Build a water reminder with notifications', size: 'small' }]);
    const list = 'Acqua di Oggi — reminds me to drink water\nRun Log — a running diary with weekly charts';
    expect(isPlainList(list)).toBe(true);
    const plan = await planApps(list, complete);
    expect(plan.apps.map((a) => a.name)).toEqual(['Acqua di Oggi', 'Run Log']);
    expect(plan.apps[0]!.brief).toBe('Build a water reminder with notifications');
    // The second line got no card from the AI: it stays as the owner wrote it.
    expect(plan.apps[1]).toEqual({ name: 'Run Log', summary: 'a running diary with weekly charts' });
  });

  it('still reads a plain list when the AI cannot be reached, and says so', async () => {
    const plan = await planApps('Water — drink reminders every two hours\nRun Log — a running diary with charts', async () => {
      throw new Error('offline');
    });
    expect(plan.withoutAi).toBe(true);
    expect(plan.apps).toHaveLength(2);
    expect(plan.source).toBe('list');
  });

  it('cannot read a document without an AI', async () => {
    await expect(
      planApps('This is a long business plan.\n\nIt describes a marketplace for local farmers. '.repeat(20), async () => {
        throw new Error('offline');
      }),
    ).rejects.toThrow('offline');
  });

  it('reads a document in pieces and drops cards that repeat', async () => {
    const seen: string[] = [];
    let call = 0;
    const complete = async (_s: string, prompt: string) => {
      seen.push(prompt);
      call++;
      return JSON.stringify([
        { name: 'Farm Market', summary: 'local farmers sell produce to neighbours', size: 'big' },
        { name: `Extra ${call}`, summary: `${topics[call]} companion`, size: 'small' },
      ]);
    };
    const doc = Array.from({ length: 6 }, (_, i) => `Section ${i}\n${'details '.repeat(900)}`).join('\n\n');
    const plan = await planApps(doc, complete);
    expect(seen.length).toBeGreaterThan(1);
    expect(plan.apps.filter((a) => a.name === 'Farm Market')).toHaveLength(1);
    expect(plan.apps.length).toBe(seen.length + 1);
  });

  it('reports what it leaves out', async () => {
    let asked = 0;
    const complete = async () =>
      asked++ > 0
        ? '[]'
        : JSON.stringify([
        { name: 'Water Reminder', summary: 'reminds you to drink water every two hours today' },
        { name: 'Hydro', summary: 'reminds you to drink water every two hours today now' },
        { name: 'Water Reminder', summary: 'something else about gardening tips for balconies' },
        { name: 'Chess Coach', summary: 'opening drills with spaced repetition and a board' },
      ]);
    const plan = await planApps('make some apps about daily habits, health and games', complete, { count: 4 });
    expect(plan.apps.map((a) => a.name)).toEqual(['Water Reminder', 'Chess Coach']);
    expect(plan.dropped).toEqual([
      { name: 'Hydro', reason: 'similar_idea', keptInstead: 'Water Reminder' },
      { name: 'Water Reminder', reason: 'duplicate_name', keptInstead: 'Water Reminder' },
    ]);
  });
});

describe('assignEngines', () => {
  const sizes = (n: number, big: number): AppSize[] => Array.from({ length: n }, (_, i) => (i < big ? 'big' : 'small'));

  it('shares the batch in the proportion of the weights', () => {
    const out = assignEngines(sizes(10, 0), { 'claude-code': 3, 'qwen-code': 2 });
    expect(out.filter((e) => e === 'claude-code')).toHaveLength(6);
    expect(out.filter((e) => e === 'qwen-code')).toHaveLength(4);
  });

  it('always adds up, whatever the weights', () => {
    for (const n of [1, 7, 33, 100]) {
      const out = assignEngines(sizes(n, n % 4), { 'claude-code': 1, codex: 1, 'gemini-cli': 1, 'qwen-code': 1 });
      expect(out).toHaveLength(n);
      expect(out.every(Boolean)).toBe(true);
    }
  });

  it('gives the big apps to the strongest engines', () => {
    const out = assignEngines(['big', 'small', 'big', 'small'], { 'claude-code': 1, 'qwen-code': 1 });
    expect(out).toEqual(['claude-code', 'qwen-code', 'claude-code', 'qwen-code']);
  });

  it('falls back to Claude when no weight is given', () => {
    expect(assignEngines(sizes(2, 0), {})).toEqual(['claude-code', 'claude-code']);
  });

  it('keeps engines fixed by hand and shares the rest', () => {
    const out = assignEngines(sizes(4, 0), { 'claude-code': 1, 'gemini-cli': 1 }, ['qwen-code', undefined, undefined, undefined]);
    expect(out[0]).toBe('qwen-code');
    expect(out.slice(1).sort()).toEqual(['claude-code', 'claude-code', 'gemini-cli']);
  });
});
