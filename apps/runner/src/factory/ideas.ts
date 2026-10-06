import type { Idea } from './types.js';

/**
 * Ideas in, distinct ideas out.
 *
 * A hundred apps made in one go are only worth publishing if they are
 * different from each other: the stores turn away near-copies. So the list is
 * read, cleaned and checked here before anything is built.
 */

export const MAX_IDEAS = 100;

/** A project folder name: lower-case ascii, digits and `_`, starting with a letter. */
export function slugFolder(name: string, max = 40): string {
  const ascii = name
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, max)
    .replace(/_+$/g, '');
  if (!ascii) return 'app';
  return /^[a-z]/.test(ascii) ? ascii : `app_${ascii}`.slice(0, max);
}

/** [slug], or [slug]_2, _3… until it is not in [taken]. */
export function uniqueSlug(slug: string, taken: ReadonlySet<string>): string {
  if (!taken.has(slug)) return slug;
  for (let n = 2; ; n++) {
    const candidate = `${slug.slice(0, 40 - String(n).length - 1)}_${n}`;
    if (!taken.has(candidate)) return candidate;
  }
}

const STOP = new Set(['the', 'a', 'an', 'app', 'for', 'and', 'of', 'to', 'il', 'lo', 'la', 'le', 'un', 'una', 'di', 'per', 'e', 'che', 'con', 'in', 'my', 'mio', 'mia']);

/** A name made of the first meaningful words of a description. */
export function nameFromDescription(text: string): string {
  const words = text
    .replace(/[^\p{L}\p{N}\s'-]+/gu, ' ')
    .split(/\s+/)
    .filter((w) => w.length > 1 && !STOP.has(w.toLowerCase()));
  const picked = words.slice(0, 3).map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase());
  return picked.join(' ').slice(0, 30) || 'App';
}

/**
 * Reads a list of ideas, one per line. Accepted shapes:
 *   `Name — what it does`, `Name - what it does`, `Name: what it does`,
 *   `Name | what it does`, or just `what it does` (the name is then made from it).
 * Blank lines, `#` comments and list bullets or numbers are ignored.
 */
export function parseIdeas(text: string): Idea[] {
  const out: Idea[] = [];
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.replace(/^\s*(?:[-*•]|\d{1,3}[.)])\s+/, '').trim();
    if (!line || line.startsWith('#')) continue;
    const m = /^(.{2,40}?)\s*(?:—|–|\s-\s|\s\|\s|:\s)\s*(.{4,})$/.exec(line);
    if (m) out.push({ name: m[1]!.trim(), idea: m[2]!.trim() });
    else out.push({ name: nameFromDescription(line), idea: line });
  }
  return out;
}

export interface IdeaIssue {
  index: number;
  kind: 'duplicate_name' | 'similar_idea' | 'too_short' | 'too_many';
  /** The other idea involved, when there is one. */
  other?: number;
}

const words = (s: string) => new Set(s.toLowerCase().split(/[^\p{L}\p{N}]+/u).filter((w) => w.length > 2 && !STOP.has(w)));

/** Share of words two descriptions have in common, 0..1. */
export function similarity(a: string, b: string): number {
  const x = words(a);
  const y = words(b);
  if (x.size === 0 || y.size === 0) return 0;
  let common = 0;
  for (const w of x) if (y.has(w)) common++;
  return common / Math.min(x.size, y.size);
}

/** What is wrong with a list of ideas before it is built: repeats, near-copies, empties, too many. */
export function analyzeIdeas(ideas: readonly Idea[], max = MAX_IDEAS): IdeaIssue[] {
  const issues: IdeaIssue[] = [];
  const seen = new Map<string, number>();
  ideas.forEach((idea, i) => {
    if (i >= max) issues.push({ index: i, kind: 'too_many' });
    if (idea.idea.trim().length < 8) issues.push({ index: i, kind: 'too_short' });
    const key = slugFolder(idea.name);
    const first = seen.get(key);
    if (first !== undefined) issues.push({ index: i, kind: 'duplicate_name', other: first });
    else seen.set(key, i);
    for (let j = 0; j < i; j++) {
      if (similarity(idea.idea, ideas[j]!.idea) >= 0.8 && idea.idea.split(/\s+/).length >= 4) {
        issues.push({ index: i, kind: 'similar_idea', other: j });
        break;
      }
    }
  });
  return issues;
}

/** Drops what [analyzeIdeas] calls a duplicate or a near-copy, keeping the first of each. */
export function dedupeIdeas(ideas: readonly Idea[], max = MAX_IDEAS): Idea[] {
  const bad = new Set(analyzeIdeas(ideas, max).filter((i) => i.kind !== 'too_short').map((i) => i.index));
  return ideas.filter((_, i) => !bad.has(i));
}

export const IDEAS_SYSTEM = `You invent app ideas for a studio that publishes many small, useful, DIFFERENT mobile apps.
Reply with ONE JSON array only (no markdown fences). Each item: {"name": "...", "idea": "..."}.
- "name": a short, memorable, original store name (max 24 characters), not an existing famous brand.
- "idea": 1-2 sentences in English: who it is for, what it does, and what makes it useful. Concrete features, no vague words.
- Every idea must be clearly different from the others: a different problem, audience or mechanic. Never reword the same app.
- Real, buildable apps: no hardware the phone does not have, no backend that needs a team, no copyrighted characters.`;

export function ideasPrompt(opts: { theme: string; count: number; avoid: readonly string[]; language?: string }): string {
  return [
    `Theme: ${opts.theme.trim()}`,
    `Invent ${opts.count} different app ideas for this theme.`,
    opts.language ? `Write the "idea" text in ${opts.language}.` : '',
    opts.avoid.length ? `Names and ideas already taken, do not repeat or imitate them: ${opts.avoid.slice(-120).join(' | ')}` : '',
  ]
    .filter(Boolean)
    .join('\n');
}

/** The JSON array an AI answer carries, whatever it wrote around it. */
export function ideasFromAnswer(answer: string): Idea[] {
  const start = answer.indexOf('[');
  const end = answer.lastIndexOf(']');
  if (start < 0 || end <= start) return [];
  try {
    const arr = JSON.parse(answer.slice(start, end + 1)) as unknown;
    if (!Array.isArray(arr)) return [];
    const out: Idea[] = [];
    for (const item of arr) {
      if (!item || typeof item !== 'object') continue;
      const { name, idea } = item as { name?: unknown; idea?: unknown };
      if (typeof name === 'string' && typeof idea === 'string' && name.trim() && idea.trim()) {
        out.push({ name: name.trim().slice(0, 30), idea: idea.trim().slice(0, 600) });
      }
    }
    return out;
  } catch {
    return [];
  }
}

export type Complete = (system: string, prompt: string) => Promise<string>;

/**
 * Asks an AI for [count] different ideas on a theme, in groups so that no single
 * answer is too long, telling each group what the earlier ones already used.
 * Stops early when the AI stops producing new ideas.
 */
export async function generateIdeas(opts: { theme: string; count: number; complete: Complete; language?: string; group?: number }): Promise<Idea[]> {
  const want = Math.min(Math.max(1, Math.floor(opts.count)), MAX_IDEAS);
  const group = opts.group ?? 20;
  let have: Idea[] = [];
  let empty = 0;
  while (have.length < want && empty < 2) {
    const ask = Math.min(group, want - have.length + 3);
    const answer = await opts.complete(IDEAS_SYSTEM, ideasPrompt({ theme: opts.theme, count: ask, avoid: have.map((i) => `${i.name}: ${i.idea.slice(0, 60)}`), language: opts.language }));
    const next = dedupeIdeas([...have, ...ideasFromAnswer(answer)], want);
    empty = next.length === have.length ? empty + 1 : 0;
    have = next;
  }
  return have.slice(0, want);
}
