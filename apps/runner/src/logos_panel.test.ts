import { mkdtemp, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { generateLogosPanel, logosDir, parseLogoCritique, type LogoPanelMember } from './logos.js';

const SQUARE = (color: string) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512"><rect width="512" height="512" fill="${color}"/><circle cx="256" cy="256" r="220" fill="#fff"/></svg>`;

/** A member that draws one colour and always scores the same way. */
function member(id: string, color: string, critique: string): LogoPanelMember & { calls: string[] } {
  const calls: string[] = [];
  return {
    id,
    label: id.toUpperCase(),
    calls,
    complete: async (_system: string, prompt: string) => {
      calls.push(prompt);
      return prompt.includes('Score every icon') ? critique : SQUARE(color);
    },
  };
}

const scores = (n: number, score: number, fix: string) =>
  JSON.stringify(Array.from({ length: n }, (_, i) => ({ n: i + 1, score, fix })));

describe('parseLogoCritique', () => {
  it('reads the scores out of an answer wrapped in prose', () => {
    const got = parseLogoCritique('Sure! Here you go:\n[{"n":1,"score":8,"fix":"make it bigger"}]\nHope this helps.');
    expect(got).toEqual([{ n: 1, score: 8, fix: 'make it bigger' }]);
  });

  it('keeps scores inside 1-10 and ignores entries without a number', () => {
    const got = parseLogoCritique('[{"n":1,"score":99,"fix":"x"},{"score":5,"fix":"no n"}]');
    expect(got).toEqual([{ n: 1, score: 10, fix: 'x' }]);
  });

  it('returns nothing for an answer that is not JSON', () => {
    expect(parseLogoCritique('I am sorry, I cannot do that.')).toEqual([]);
  });
});

describe('generateLogosPanel', () => {
  it('shares the drawing, has each member judge, and redraws with the notes', async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'logos-'));
    const a = member('a', '#c00', scores(4, 6, 'make the mark fill the canvas'));
    const b = member('b', '#0c0', scores(4, 8, 'drop the thin ring'));

    const out = await generateLogosPanel({ projectRoot: root, appName: 'Test', about: 'an app', count: 4, members: [a, b] });

    expect(out).toHaveLength(4);
    // Round-robin: both members drew, neither drew the whole set.
    expect(out.filter((p) => p.authorLabel === 'A')).toHaveLength(2);
    expect(out.filter((p) => p.authorLabel === 'B')).toHaveLength(2);
    // Scored by both, so the average of 6 and 8.
    expect(out.every((p) => p.score === 7)).toBe(true);
    // A note counts only when it comes from a different model.
    expect(out.find((p) => p.authorLabel === 'A')!.notes).toEqual(['B: drop the thin ring']);
    expect(out.find((p) => p.authorLabel === 'B')!.notes).toEqual(['A: make the mark fill the canvas']);
    // Draw (2) + critique (1) + redraw (2) for each member.
    expect(a.calls.filter((c) => c.includes('design panel scored it'))).toHaveLength(2);
    // The winning drawing is on disk and its verdict was saved with it.
    const meta = JSON.parse(await readFile(path.join(logosDir(root), `${out[0]!.id}.json`), 'utf8')) as { score: number };
    expect(meta.score).toBe(7);
  });

  it('still returns the drawings when every critic is down', async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'logos-'));
    const down: LogoPanelMember = {
      id: 'down',
      label: 'Down',
      complete: async (_s, p) => {
        if (p.includes('Score every icon')) throw new Error('503');
        return SQUARE('#00c');
      },
    };
    const ok = member('ok', '#c0c', 'not json at all');

    const out = await generateLogosPanel({ projectRoot: root, appName: 'Test', about: 'an app', count: 2, members: [down, ok] });

    expect(out).toHaveLength(2);
    expect(out.every((p) => p.score === undefined)).toBe(true);
    expect(out.every((p) => p.notes?.length === 0)).toBe(true);
  });

  it('skips a member that cannot draw instead of failing the set', async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'logos-'));
    const broken: LogoPanelMember = { id: 'broken', label: 'Broken', complete: async () => 'I cannot draw SVG.' };
    const good = member('good', '#123', scores(2, 9, 'fine'));

    const out = await generateLogosPanel({ projectRoot: root, appName: 'Test', about: 'an app', count: 4, members: [broken, good] });

    expect(out).toHaveLength(2);
    expect(out.every((p) => p.authorLabel === 'GOOD')).toBe(true);
  });
});
