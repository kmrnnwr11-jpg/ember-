/**
 * Several models read the finished app, each on its own, and say what is
 * missing, what does not work and what is only pretending to work. Their
 * reports are then merged into one list of things to fix.
 *
 * Every reviewer speaks the OpenAI chat format, so one call shape serves
 * DeepSeek, Groq, GitHub Models, OpenRouter or a local Ollama alike: what
 * changes is the address, the key and the model name.
 */

import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import type { Finding } from './doctor.js';

export interface ReviewerSpec {
  id: string;
  label: string;
  baseUrl: string;
  apiKey: string;
  model: string;
}

export interface ReviewerReport {
  id: string;
  label: string;
  ok: boolean;
  /** Why it could not be used, when ok is false. */
  error?: string;
  findings: Finding[];
}

/**
 * One plain call to any OpenAI-compatible service. Shared with the logo design
 * panel, which uses the same reviewers to draw and to judge drawings.
 */
export async function openAiComplete(
  r: Pick<ReviewerSpec, 'baseUrl' | 'apiKey' | 'model'>,
  system: string,
  prompt: string,
  fetchImpl: typeof fetch = fetch,
  maxTokens = 4000,
): Promise<string> {
  const res = await fetchImpl(`${r.baseUrl.replace(/\/+$/, '')}/chat/completions`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${r.apiKey}`,
      // Groq refuses requests without one; the others do not mind.
      'user-agent': 'Ember/1.0',
    },
    body: JSON.stringify({
      model: r.model,
      temperature: 0.2,
      max_tokens: maxTokens,
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: prompt },
      ],
    }),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${(await res.text().catch(() => '')).slice(0, 200)}`);
  const j = (await res.json()) as { choices?: Array<{ message?: { content?: string } }> };
  return j.choices?.[0]?.message?.content ?? '';
}

/** Enough of the app for a model to judge it, small enough to send. */
const MAX_CODE_CHARS = 280_000;
const MAX_FILE_CHARS = 24_000;

/** Reads lib/ plus the files that say what the app promises to be. */
export async function collectCode(root: string): Promise<{ text: string; files: number; truncated: boolean }> {
  const parts: string[] = [];
  let total = 0;
  let files = 0;
  let truncated = false;

  const add = (rel: string, body: string) => {
    if (!body.trim()) return;
    const clipped = body.length > MAX_FILE_CHARS ? `${body.slice(0, MAX_FILE_CHARS)}\n// …(file cut)` : body;
    if (total + clipped.length > MAX_CODE_CHARS) {
      truncated = true;
      return;
    }
    parts.push(`\n===== ${rel} =====\n${clipped}`);
    total += clipped.length;
    files++;
  };

  for (const rel of ['pubspec.yaml', 'store/listing.json', 'android/app/src/main/AndroidManifest.xml']) {
    add(rel, await readFile(path.join(root, rel), 'utf8').catch(() => ''));
  }

  const walk = async (dir: string, rel: string): Promise<void> => {
    const entries = await readdir(dir, { withFileTypes: true }).catch(() => []);
    for (const e of entries) {
      if (total >= MAX_CODE_CHARS) {
        truncated = true;
        return;
      }
      const child = path.join(dir, e.name);
      const childRel = rel ? `${rel}/${e.name}` : e.name;
      if (e.isDirectory()) {
        await walk(child, childRel);
      } else if (e.name.endsWith('.dart')) {
        add(childRel, await readFile(child, 'utf8').catch(() => ''));
      }
    }
  };
  await walk(path.join(root, 'lib'), 'lib');

  return { text: parts.join('\n'), files, truncated };
}

const SYSTEM = `You review a finished Flutter app the way a demanding tester would, and you answer with JSON only.
You are looking for three things, in this order of importance:
1. FAKE: a screen or button that looks like it works but has nothing behind it — a record button that only animates, a player with no audio, a camera screen with no camera, a "save" that saves nothing. This is the worst defect an app can have.
2. MISSING: something the app promises (in its store listing, its menus or its own labels) that is nowhere in the code.
3. BROKEN: code that will fail, crash or do the wrong thing when a real person uses it.
Ignore style, formatting and personal taste. Do not invent problems to look useful: if the app is sound, return fewer findings.`;

const instruction = (listing: string) => `Read the whole app below and report what is wrong with it.
${listing.trim() ? `What the app promises its users:\n${listing.trim()}\n` : ''}
Answer with a JSON array only, no prose around it, at most 12 entries, worst first:
[{"title":"short title, max 70 chars","detail":"what is wrong and why it matters, 1-2 sentences","ask":"the exact instruction to give the developer to fix it"}]
If you find nothing worth fixing, answer [].`;

/** Pulls the JSON array out of a model's answer, however it wrapped it. */
function parseFindings(text: string): Array<{ title: string; detail: string; ask?: string }> {
  const start = text.indexOf('[');
  const end = text.lastIndexOf(']');
  if (start < 0 || end <= start) return [];
  try {
    const raw = JSON.parse(text.slice(start, end + 1)) as unknown;
    if (!Array.isArray(raw)) return [];
    const out: Array<{ title: string; detail: string; ask?: string }> = [];
    for (const e of raw) {
      if (!e || typeof e !== 'object') continue;
      const o = e as Record<string, unknown>;
      const title = `${o.title ?? ''}`.trim();
      if (!title) continue;
      out.push({
        title: title.slice(0, 120),
        detail: `${o.detail ?? ''}`.trim().slice(0, 600),
        ask: `${o.ask ?? ''}`.trim().slice(0, 900) || undefined,
      });
    }
    return out;
  } catch {
    return [];
  }
}

/**
 * A reviewer as the merge step needs it: a name and a way to ask it one
 * question. A service with a key becomes one of these through [fromSpec]; so
 * does Claude on the machine's login or Gemini on the Runner's key, neither of
 * which has a key the app could have sent.
 */
export interface ReviewerLike {
  id: string;
  label: string;
  complete: (system: string, prompt: string) => Promise<string>;
}

export const fromSpec = (r: ReviewerSpec, fetchImpl: typeof fetch = fetch): ReviewerLike => ({
  id: r.id,
  label: r.label,
  complete: (system, prompt) => openAiComplete(r, system, prompt, fetchImpl),
});

/** Asks one reviewer. Never throws: a reviewer that is down must not stop the others. */
async function askOne(r: ReviewerLike, code: string, listing: string): Promise<ReviewerReport> {
  try {
    const text = await r.complete(SYSTEM, `${instruction(listing)}\n\nTHE APP:\n${code}`);
    const findings: Finding[] = parseFindings(text).map((f, i) => ({
      id: `ai_${r.id}_${i}`,
      title: f.title,
      detail: `${f.detail}${f.detail ? ' ' : ''}(visto da ${r.label})`,
      fixable: false,
      ask: f.ask,
    }));
    return { id: r.id, label: r.label, ok: true, findings };
  } catch (e) {
    return { id: r.id, label: r.label, ok: false, error: (e as Error).message.slice(0, 200), findings: [] };
  }
}

/** The words that carry the meaning of a title. */
const keywords = (title: string) =>
  new Set(
    title
      .toLowerCase()
      .replace(/[^a-z0-9àèéìòù ]/g, ' ')
      .split(/\s+/)
      .filter((w) => w.length > 3),
  );

/**
 * Two reviewers describe the same defect in their own words ("playback has no
 * sound engine" / "the playback sound engine is missing"), so titles count as
 * the same when most of their meaningful words overlap, not when they match.
 */
function sameProblem(a: string, b: string): boolean {
  const A = keywords(a);
  const B = keywords(b);
  if (A.size === 0 || B.size === 0) return a.toLowerCase() === b.toLowerCase();
  let shared = 0;
  for (const w of A) if (B.has(w)) shared++;
  return shared / Math.min(A.size, B.size) >= 0.6;
}

/**
 * Runs every reviewer at once and merges what they found. A problem more than
 * one of them saw is listed first: agreement between models that never spoke to
 * each other is the strongest signal there is.
 */
export async function reviewApp(
  root: string,
  reviewers: ReviewerSpec[],
  fetchImpl: typeof fetch = fetch,
  /** Reviewers this machine provides itself: Claude's login, the Runner's Gemini. */
  extra: ReviewerLike[] = [],
): Promise<{ reports: ReviewerReport[]; findings: Finding[]; files: number; truncated: boolean }> {
  const { text, files, truncated } = await collectCode(root);
  const listing = await readFile(path.join(root, 'store', 'listing.json'), 'utf8').catch(() => '');
  const all = [...extra, ...reviewers.map((r) => fromSpec(r, fetchImpl))];
  const reports = await Promise.all(all.map((r) => askOne(r, text, listing)));

  const merged: Array<{ finding: Finding; seenBy: string[] }> = [];
  for (const rep of reports) {
    for (const f of rep.findings) {
      const hit = merged.find((m) => sameProblem(m.finding.title, f.title));
      if (hit) {
        if (!hit.seenBy.includes(rep.label)) hit.seenBy.push(rep.label);
      } else {
        merged.push({ finding: f, seenBy: [rep.label] });
      }
    }
  }

  const findings = merged
    .sort((a, b) => b.seenBy.length - a.seenBy.length)
    .map(({ finding, seenBy }) =>
      seenBy.length > 1
        ? { ...finding, title: `${finding.title}`, detail: `${finding.detail} — segnalato da ${seenBy.length} revisori: ${seenBy.join(', ')}` }
        : finding,
    );

  return { reports, findings, files, truncated };
}
