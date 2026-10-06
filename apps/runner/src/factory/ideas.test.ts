import { describe, expect, it } from 'vitest';
import { analyzeIdeas, dedupeIdeas, nameFromDescription, parseIdeas, similarity, slugFolder, uniqueSlug } from './ideas.js';

describe('slugFolder', () => {
  it('makes a safe Flutter package name from any title', () => {
    expect(slugFolder('Acqua di Oggi')).toBe('acqua_di_oggi');
    expect(slugFolder('Çafé Ñandú!')).toBe('cafe_nandu');
    expect(slugFolder('3D Planner')).toBe('app_3d_planner');
    expect(slugFolder('***')).toBe('app');
    expect(slugFolder('Test')).toBe('test_app');
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
      { name: 'Acqua di Oggi', summary: 'reminds me to drink water' },
      { name: 'Pocket Budget', summary: 'track daily spending with one tap' },
      { name: 'Run Log', summary: 'a simple running diary with weekly charts' },
      { name: 'Contare Calorie Dei', summary: 'Una app per contare le calorie dei pasti italiani' },
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
      { name: 'Water Reminder', summary: 'Reminds you to drink water every two hours' },
      { name: 'Water Reminder', summary: 'Something else entirely about gardening tips' },
      { name: 'Hydro', summary: 'Reminds you to drink water every two hours today' },
      { name: 'Tiny', summary: 'x' },
    ]);
    expect(issues).toContainEqual({ index: 1, kind: 'duplicate_name', other: 0 });
    expect(issues).toContainEqual({ index: 2, kind: 'similar_idea', other: 0 });
    expect(issues).toContainEqual({ index: 3, kind: 'too_short' });
    expect(analyzeIdeas(Array.from({ length: 3 }, (_, i) => ({ name: `n${i}`, summary: `idea ${i} for something` })), 2)).toContainEqual({ index: 2, kind: 'too_many' });
  });

  it('keeps the first of each copy', () => {
    const kept = dedupeIdeas([
      { name: 'A', summary: 'track my daily steps and show a chart' },
      { name: 'B', summary: 'track my daily steps and show a chart now' },
      { name: 'C', summary: 'learn guitar chords with a metronome' },
    ]);
    expect(kept.map((i) => i.name)).toEqual(['A', 'C']);
    expect(similarity('', 'x y z')).toBe(0);
  });
});
