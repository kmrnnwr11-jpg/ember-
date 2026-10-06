import type { Idea } from './types.js';

/**
 * Ideas in, distinct ideas out.
 *
 * A hundred apps made in one go are only worth publishing if they are
 * different from each other: the stores turn away near-copies. So the list is
 * read, cleaned and checked here before anything is built.
 */

export const MAX_IDEAS = 100;

const DART_RESERVED = new Set(['flutter', 'test', 'async', 'class', 'import', 'void', 'dart']);

/** A project folder name: lower-case ascii, digits and `_`, starting with a letter, not a Dart keyword. */
export function slugFolder(name: string, max = 40): string {
  let slug = name
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, max)
    .replace(/_+$/g, '');
  if (!slug) return 'app';
  if (!/^[a-z]/.test(slug)) slug = `app_${slug}`.slice(0, max);
  if (DART_RESERVED.has(slug)) slug = `${slug}_app`;
  return slug;
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
    if (m) out.push({ name: m[1]!.trim(), summary: m[2]!.trim() });
    else out.push({ name: nameFromDescription(line), summary: line });
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
    if (idea.summary.trim().length < 8) issues.push({ index: i, kind: 'too_short' });
    const key = slugFolder(idea.name);
    const first = seen.get(key);
    if (first !== undefined) {
      issues.push({ index: i, kind: 'duplicate_name', other: first });
      return;
    }
    seen.set(key, i);
    for (let j = 0; j < i; j++) {
      if (similarity(idea.summary, ideas[j]!.summary) >= 0.8 && idea.summary.split(/\s+/).length >= 4) {
        issues.push({ index: i, kind: 'similar_idea', other: j });
        break;
      }
    }
  });
  return issues;
}

export interface DroppedIdea {
  name: string;
  reason: 'duplicate_name' | 'similar_idea' | 'too_many';
  /** Name of the idea kept instead. */
  keptInstead?: string;
}

/** Drops what [analyzeIdeas] calls a duplicate or a near-copy, keeping the first of each, and says what went. */
export function dedupeReport(ideas: readonly Idea[], max = MAX_IDEAS): { kept: Idea[]; dropped: DroppedIdea[] } {
  const issues = analyzeIdeas(ideas, max).filter((i) => i.kind !== 'too_short');
  const bad = new Set(issues.map((i) => i.index));
  return {
    kept: ideas.filter((_, i) => !bad.has(i)),
    dropped: issues.map((i) => ({ name: ideas[i.index]!.name, reason: i.kind as DroppedIdea['reason'], ...(i.other !== undefined ? { keptInstead: ideas[i.other]!.name } : {}) })),
  };
}

export function dedupeIdeas(ideas: readonly Idea[], max = MAX_IDEAS): Idea[] {
  return dedupeReport(ideas, max).kept;
}
