import { MAX_IDEAS, dedupeReport, parseIdeas, type DroppedIdea } from './ideas.js';
import type { AppSize, Idea } from './types.js';

/**
 * The supervisor: turns whatever the owner pasted into the big box — an
 * elenco, a business plan, a pile of prompts, a theme — into at most a hundred
 * distinct app cards (name, what it does, small or big, a brief for the coding
 * agent). The owner sees the cards and approves them before anything is built.
 */

export type Complete = (system: string, prompt: string) => Promise<string>;

export const SUPERVISOR_SYSTEM = `You are the supervisor of a studio that builds many mobile apps at once. You read whatever the owner pasted and turn it into app cards.
Reply with ONE JSON array only (no markdown fences, no comments). Each item:
{"name": "...", "summary": "...", "brief": "...", "size": "small" | "big", "category": "..."}
- "name": the store name, short, memorable, original, max 24 characters. Keep a name the owner gave; never use a famous brand.
- "summary": one or two sentences in English: who it is for and what it does.
- "brief": the request for the programmer (max 1200 characters, English): the screens, the features, what is stored on the phone, what makes it useful. Concrete, buildable by one developer in one go. Keep the owner's own requirements word for word where they gave any.
- "size": "small" for a simple utility (a few screens, data on the phone, no accounts); "big" for a product (accounts, realtime, many features, payments, maps, chat).
- "category": one store category word (e.g. productivity, health, finance, education, games, tools, lifestyle, travel, music, food).
Rules:
- One card per DISTINCT app. If the text describes one single app, return ONE card: never split one app into several, never merge two different apps into one.
- If the text asks for a number of apps, or gives only a theme, invent that many different apps. Each must differ from the others in problem, audience or mechanic: never reword the same app.
- Real apps only: nothing that needs hardware the phone lacks, a team of people behind it, or copyrighted characters.`;

/** The owner's words, cut at paragraph ends into pieces one answer can handle. */
export function chunkText(text: string, size = 14_000): string[] {
  const paragraphs = text.replace(/\r\n/g, '\n').split(/\n{2,}/);
  const chunks: string[] = [];
  let current = '';
  const push = () => {
    if (current.trim()) chunks.push(current.trim());
    current = '';
  };
  for (const p of paragraphs) {
    if (p.length > size) {
      push();
      for (let i = 0; i < p.length; i += size) chunks.push(p.slice(i, i + size));
      continue;
    }
    if (current.length + p.length + 2 > size) push();
    current += `${current ? '\n\n' : ''}${p}`;
  }
  push();
  return chunks;
}

const asSize = (v: unknown): AppSize => (v === 'big' ? 'big' : 'small');

/** The cards a supervisor answer carries, whatever it wrote around the JSON. */
export function cardsFromAnswer(answer: string): Idea[] {
  const start = answer.indexOf('[');
  const end = answer.lastIndexOf(']');
  if (start < 0 || end <= start) return [];
  try {
    const arr = JSON.parse(answer.slice(start, end + 1)) as unknown;
    if (!Array.isArray(arr)) return [];
    const out: Idea[] = [];
    for (const item of arr) {
      if (!item || typeof item !== 'object') continue;
      const o = item as Record<string, unknown>;
      const name = typeof o.name === 'string' ? o.name.trim().slice(0, 30) : '';
      const summary = typeof o.summary === 'string' ? o.summary.trim().slice(0, 600) : typeof o.idea === 'string' ? o.idea.trim().slice(0, 600) : '';
      if (!name || !summary) continue;
      const brief = typeof o.brief === 'string' ? o.brief.trim().slice(0, 2000) : '';
      out.push({
        name,
        summary,
        ...(brief ? { brief } : {}),
        size: asSize(o.size),
        ...(typeof o.category === 'string' && o.category.trim() ? { category: o.category.trim().toLowerCase().slice(0, 30) } : {}),
      });
    }
    return out;
  } catch {
    return [];
  }
}

export interface PlanOptions {
  /** How many apps to invent when the text is only a theme (or says "make me N apps"). */
  count?: number;
  /** Most apps in the plan. */
  max?: number;
}

export interface Plan {
  apps: Idea[];
  dropped: DroppedIdea[];
  /** `list`: read as written; `supervisor`: made or completed by the AI. */
  source: 'list' | 'supervisor';
  /** The AI could not be reached and the list was read as written. */
  withoutAi: boolean;
}

/** Whether the text is a plain list (most lines read as "Name — what it does"). */
export function isPlainList(text: string): boolean {
  const lines = text.split(/\r?\n/).map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
  if (lines.length < 2) return false;
  const shaped = lines.filter((l) => /^(?:[-*•]|\d{1,3}[.)])?\s*.{2,40}?\s*(?:—|–|\s-\s|\s\|\s|:\s)\s*.{4,}$/.test(l)).length;
  return shaped / lines.length >= 0.7;
}

const taken = (apps: readonly Idea[]) => apps.map((a) => `${a.name}: ${a.summary.slice(0, 70)}`);

/**
 * Turns the owner's text into cards. A theme (or a request for N apps) is
 * invented in groups, each told what the earlier ones used; a document is read
 * in pieces; a plain list keeps the owner's names and gets its briefs written.
 * Cards that repeat a name or an idea are left out and reported.
 */
export async function planApps(text: string, complete: Complete, opts: PlanOptions = {}): Promise<Plan> {
  const max = Math.min(opts.max ?? MAX_IDEAS, MAX_IDEAS);
  const body = text.trim();
  if (!body) return { apps: [], dropped: [], source: 'list', withoutAi: false };
  const list = isPlainList(body) ? parseIdeas(body) : [];
  const theme = list.length === 0 && body.length < 500 && body.split(/\n/).length <= 3;
  let cards: Idea[] = [];
  const dropped: DroppedIdea[] = [];
  let withoutAi = false;
  /** Adds new cards to the ones kept so far, leaving out (and reporting) repeats. */
  const merge = (more: readonly Idea[]) => {
    const r = dedupeReport([...cards, ...more], 10_000);
    cards = r.kept;
    for (const d of r.dropped) if (!dropped.some((x) => x.name === d.name && x.reason === d.reason && x.keptInstead === d.keptInstead)) dropped.push(d);
  };

  try {
    if (theme) {
      const want = Math.min(Math.max(1, Math.floor(opts.count ?? 10)), max);
      let empty = 0;
      while (cards.length < want && empty < 2) {
        const ask = Math.min(20, want - cards.length + 3);
        const answer = await complete(
          SUPERVISOR_SYSTEM,
          [`Theme: ${body}`, `Invent ${ask} different apps for this theme.`, cards.length ? `Already taken, do not repeat or imitate: ${taken(cards).slice(-120).join(' | ')}` : ''].filter(Boolean).join('\n'),
        );
        const before = cards.length;
        merge(cardsFromAnswer(answer));
        empty = cards.length === before ? empty + 1 : 0;
      }
      cards = cards.slice(0, want);
    } else if (list.length > 0) {
      // Keep the owner's names; the AI writes the brief and sizes each one.
      for (let i = 0; i < list.length; i += 25) {
        const part = list.slice(i, i + 25);
        const answer = await complete(
          SUPERVISOR_SYSTEM,
          `The owner wrote this list of apps. Return one card per line, in the same order, keeping each name exactly as written and building the summary and brief from the owner's words:\n${part.map((p) => `${p.name} — ${p.summary}`).join('\n')}`,
        );
        const got = cardsFromAnswer(answer);
        for (const p of part) {
          const match = got.find((g) => g.name.toLowerCase() === p.name.toLowerCase());
          cards.push(match ? { ...match, name: p.name } : p);
        }
      }
    } else {
      const pieces = chunkText(body);
      for (const [i, piece] of pieces.entries()) {
        const answer = await complete(
          SUPERVISOR_SYSTEM,
          [
            `Part ${i + 1} of ${pieces.length} of what the owner pasted:`,
            piece,
            opts.count ? `The owner wants ${opts.count} apps in total.` : '',
            cards.length ? `Already made from earlier parts, do not repeat: ${taken(cards).slice(-120).join(' | ')}` : '',
          ]
            .filter(Boolean)
            .join('\n'),
        );
        merge(cardsFromAnswer(answer));
      }
    }
  } catch (e) {
    // No AI to ask: a plain list can still be read as written, anything else cannot.
    if (list.length === 0) throw e;
    withoutAi = true;
    cards = list;
  }

  const last = dedupeReport(cards, max);
  dropped.push(...last.dropped);
  return { apps: last.kept, dropped, source: withoutAi ? 'list' : 'supervisor', withoutAi };
}
