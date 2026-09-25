import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { reviewApp, type ReviewerSpec } from './ai_review.js';

let root = '';

const reviewer = (id: string): ReviewerSpec => ({
  id,
  label: id.toUpperCase(),
  baseUrl: 'https://example.test/v1',
  apiKey: 'k',
  model: 'm',
});

/** Answers as an OpenAI-compatible service would, with the text given per key. */
const fakeAi = (byKey: Record<string, string>) =>
  (async (_url: string | URL | Request, init?: RequestInit) => {
    const body = JSON.parse(String(init?.body ?? '{}')) as { model: string };
    const text = byKey[body.model] ?? '[]';
    return new Response(JSON.stringify({ choices: [{ message: { content: text } }] }), {
      status: 200,
      headers: { 'content-type': 'application/json' },
    });
  }) as typeof fetch;

describe('AI review', () => {
  beforeAll(async () => {
    root = await mkdtemp(path.join(os.tmpdir(), 'fc-review-'));
    await mkdir(path.join(root, 'lib', 'screens'), { recursive: true });
    await writeFile(path.join(root, 'pubspec.yaml'), 'name: demo\n');
    await writeFile(path.join(root, 'lib', 'main.dart'), 'void main() {}\n');
    await writeFile(path.join(root, 'lib', 'screens', 'home.dart'), 'class Home {}\n');
  });
  afterAll(() => rm(root, { recursive: true, force: true }));

  it('reads the app and reports what each reviewer found', async () => {
    const one = JSON.stringify([{ title: 'Record button does nothing', detail: 'No microphone.', ask: 'Add real recording' }]);
    const r = await reviewApp(root, [{ ...reviewer('a'), model: 'A' }], fakeAi({ A: one }));
    expect(r.files).toBeGreaterThan(0);
    expect(r.reports[0].ok).toBe(true);
    expect(r.findings).toHaveLength(1);
    expect(r.findings[0].ask).toBe('Add real recording');
    expect(r.findings[0].detail).toContain('A'); // says who saw it
  });

  it('merges the same problem seen by two reviewers and puts it first', async () => {
    const a = JSON.stringify([
      { title: 'Playback has no sound engine', detail: 'x' },
      { title: 'Only one reviewer saw this', detail: 'y' },
    ]);
    const b = JSON.stringify([{ title: 'The playback sound engine is missing', detail: 'z' }]);
    const r = await reviewApp(root, [{ ...reviewer('a'), model: 'A' }, { ...reviewer('b'), model: 'B' }], fakeAi({ A: a, B: b }));
    expect(r.findings).toHaveLength(2);
    expect(r.findings[0].detail).toContain('2 revisori');
  });

  it('keeps going when one reviewer is down', async () => {
    const down = (async () => new Response('nope', { status: 500 })) as typeof fetch;
    const r = await reviewApp(root, [reviewer('a')], down);
    expect(r.reports[0].ok).toBe(false);
    expect(r.reports[0].error).toContain('500');
    expect(r.findings).toEqual([]);
  });

  it('ignores an answer that is not JSON', async () => {
    const r = await reviewApp(root, [{ ...reviewer('a'), model: 'A' }], fakeAi({ A: 'I could not review it, sorry.' }));
    expect(r.reports[0].ok).toBe(true);
    expect(r.findings).toEqual([]);
  });
});
