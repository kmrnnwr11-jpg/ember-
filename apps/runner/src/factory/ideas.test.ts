import { describe, expect, it } from 'vitest';
import { analyzeIdeas, dedupeIdeas, generateIdeas, ideasFromAnswer, nameFromDescription, parseIdeas, similarity, slugFolder, uniqueSlug } from './ideas.js';

describe('slugFolder', () => {
  it('makes a safe Flutter package name from any title', () => {
    expect(slugFolder('Acqua di Oggi')).toBe('acqua_di_oggi');
    expect(slugFolder('Çafé Ñandú!')).toBe('cafe_nandu');
    expect(slugFolder('3D Planner')).toBe('app_3d_planner');
    expect(slugFolder('***')).toBe('app');
    expect(slugFolder('x'.repeat(80)).length).toBeLessThanOrEqual(40);
  });

  it('numbers a name that is already taken', () => {
    expect(uniqueSlug('timer', new Set(['timer']))).toBe('timer_2');
    expect(uniqueSlug('timer', new Set(['timer', 'timer_2']))).toBe('timer_3');
    expect(uniqueSlug('free', new Set(['timer']))).toBe('free');
  });
});

describe('parseIdeas', () => {
  it('reads the shapes people actually write', () => {
    const list = parseIdeas(
      [
        '# my list',
        '1. Acqua di Oggi — reminds me to drink water',
        '- Pocket Budget: track daily spending with one tap',
        'Run Log - a simple running diary with weekly charts',
        'Una app per contare le calorie dei pasti italiani',
        '',
        '   ',
      ].join('\n'),
    );
    expect(list).toEqual([
      { name: 'Acqua di Oggi', idea: 'reminds me to drink water' },
      { name: 'Pocket Budget', idea: 'track daily spending with one tap' },
      { name: 'Run Log', idea: 'a simple running diary with weekly charts' },
      { name: 'Contare Calorie Dei', idea: 'Una app per contare le calorie dei pasti italiani' },
    ]);
  });

  it('makes a short name from a description', () => {
    expect(nameFromDescription('an app for tracking my plants watering')).toBe('Tracking Plants Watering');
    expect(nameFromDescription('!!!')).toBe('App');
  });
});

describe('analyzeIdeas', () => {
  it('flags repeated names, near-copies, empty ideas and too many', () => {
    const issues = analyzeIdeas([
      { name: 'Water Reminder', idea: 'Reminds you to drink water every two hours' },
      { name: 'Water Reminder', idea: 'Something else entirely about gardening tips' },
      { name: 'Hydro', idea: 'Reminds you to drink water every two hours today' },
      { name: 'Tiny', idea: 'x' },
    ]);
    expect(issues).toContainEqual({ index: 1, kind: 'duplicate_name', other: 0 });
    expect(issues).toContainEqual({ index: 2, kind: 'similar_idea', other: 0 });
    expect(issues).toContainEqual({ index: 3, kind: 'too_short' });
    expect(analyzeIdeas(Array.from({ length: 3 }, (_, i) => ({ name: `n${i}`, idea: `idea ${i} for something` })), 2)).toContainEqual({ index: 2, kind: 'too_many' });
  });

  it('keeps the first of each copy', () => {
    const kept = dedupeIdeas([
      { name: 'A', idea: 'track my daily steps and show a chart' },
      { name: 'B', idea: 'track my daily steps and show a chart now' },
      { name: 'C', idea: 'learn guitar chords with a metronome' },
    ]);
    expect(kept.map((i) => i.name)).toEqual(['A', 'C']);
    expect(similarity('', 'x y z')).toBe(0);
  });
});

describe('generateIdeas', () => {
  const topics = ['gardening soil moisture', 'guitar chord practice', 'invoice scanning receipts', 'sleep sound mixing', 'marathon pacing splits', 'recipe pantry matching', 'language flashcards spacing', 'bird watching checklist', 'budget envelope saving', 'meditation breathing timer', 'chess opening drills', 'plant disease photo'];
  let next = 0;
  const answer = (names: string[]) => JSON.stringify(names.map((n) => ({ name: n, idea: `${topics[next++ % topics.length]} companion called ${n}` })));

  it('asks in groups, tells the next group what is taken, and stops at the count', async () => {
    const prompts: string[] = [];
    let n = 0;
    const out = await generateIdeas({
      theme: 'productivity',
      count: 5,
      group: 3,
      complete: async (_system, prompt) => {
        prompts.push(prompt);
        const names = [1, 2, 3, 4].map((i) => `Alpha${++n}x${i}`);
        return `Here you go:\n${answer(names)}`;
      },
    });
    expect(out).toHaveLength(5);
    expect(prompts.length).toBeGreaterThanOrEqual(2);
    expect(prompts[1]).toContain('already taken');
    expect(new Set(out.map((o) => o.name)).size).toBe(5);
  });

  it('gives up when the AI keeps repeating itself', async () => {
    const out = await generateIdeas({ theme: 't', count: 10, complete: async () => answer(['Same', 'Same']) });
    expect(out.length).toBeLessThan(10);
    expect(out[0]!.name).toBe('Same');
  });

  it('reads an answer with text around the JSON and ignores broken items', () => {
    expect(ideasFromAnswer('ok [{"name":"A","idea":"does a"},{"nope":1},"x"] bye')).toEqual([{ name: 'A', idea: 'does a' }]);
    expect(ideasFromAnswer('no json here')).toEqual([]);
    expect(ideasFromAnswer('[not json]')).toEqual([]);
  });
});
