/**
 * Cuts a text to the store's limit at a word where possible (the same rule as
 * fitStoreText in app.ts, copied here so this file does not import the server).
 */
export function fitStoreText(text: string, max: number): string {
  const t = text.trim();
  const chars = Array.from(t);
  if (chars.length <= max) return t;
  let cut = chars.slice(0, max).join('');
  const space = cut.lastIndexOf(' ');
  if (space > max * 0.6) cut = cut.slice(0, space);
  return cut.replace(/[\s,;:.\-–—·|]+$/u, '').trim();
}

/**
 * The store listing of one app, written and translated by an AI: the same
 * texts, limits and file format the IDE's publish screen produces, so an app
 * made by the Factory can be opened and edited like any other.
 */

export interface Page {
  title: string;
  shortDescription: string;
  fullDescription: string;
}

export interface Kit extends Page {
  releaseNotes: string;
  privacyPolicyMarkdown: string;
  dataSafetyGuide: string;
  contentRatingGuide: string;
  otherDeclarationsGuide: string;
}

export type Complete = (system: string, prompt: string) => Promise<string>;

export const KIT_SYSTEM = `You prepare everything needed to publish an Android app on Google Play, for a studio that publishes many apps.
Reply with ONE JSON object only (no markdown fences), with these keys.

THE STORE TEXTS ARE WRITTEN IN ENGLISH. The title, the short description, the full description and the release notes are English and nothing else: English is the listing's main language and what Google shows wherever there is no page in the reader's own language.
{
 "title": "max 30 chars",
 "shortDescription": "max 80 chars",
 "fullDescription": "max 4000 chars, engaging, with feature bullets using • and line breaks",
 "releaseNotes": "max 500 chars",
 "privacyPolicyMarkdown": "complete privacy policy in Markdown (who we are: use the placeholders [NOME TITOLARE] and [EMAIL], data collected, purposes, third-party services actually used by the app, retention, user rights under GDPR, contacts, date)",
 "dataSafetyGuide": "Markdown checklist answering Play Console 'Data safety' questions based on what the app really uses: data types collected/shared, purposes, encryption in transit, account deletion method",
 "contentRatingGuide": "Markdown list of suggested answers for the IARC content rating questionnaire",
 "otherDeclarationsGuide": "Markdown: target audience and content, ads (yes/no), app access instructions for reviewers if login is required, government/financial/health declarations if relevant"
}
Be accurate: only declare data the app actually handles, based on the description. Never invent certifications, awards, ratings, download counts or user numbers. Never promise features the description does not have.`;

export const TRANSLATE_SYSTEM = 'You translate app store listings for Google Play. You answer with JSON only.';

export function kitPrompt(opts: { name: string; packageName?: string; description: string }): string {
  return [
    `The app is called "${opts.name}". Use exactly this name in the title and wherever the listing names the app. Do not translate it, shorten it, or invent another one.`,
    `The store title is exactly "${opts.name}": return it unchanged as "title".`,
    opts.packageName ? `Package name: ${opts.packageName}` : '',
    '',
    `App description and features:\n${opts.description}`,
  ]
    .filter((l) => l !== '')
    .join('\n');
}

export function translatePrompt(opts: { langs: readonly string[]; title: string; short: string; full: string }): string {
  return [
    `Translate this Google Play store listing into these languages: ${opts.langs.join(', ')}.`,
    `The title is the app name: it stays exactly "${opts.title}" in every language. Translate only the descriptions.`,
    'Limits: shortDescription 80 characters, fullDescription 4000. Write naturally for each market, not word for word.',
    'Reply with JSON only: {"<language code>": {"shortDescription": "...", "fullDescription": "..."}}',
    '',
    `shortDescription: ${opts.short}`,
    'fullDescription:',
    opts.full,
  ].join('\n');
}

/** The JSON object inside an answer, whatever was written around it. */
export function jsonObject(answer: string): Record<string, unknown> {
  const start = answer.indexOf('{');
  const end = answer.lastIndexOf('}');
  if (start < 0 || end <= start) throw new Error('the AI did not answer with JSON');
  return JSON.parse(answer.slice(start, end + 1)) as Record<string, unknown>;
}

const str = (v: unknown) => (typeof v === 'string' ? v : '');

/** Google's limits are hard: a title of 31 characters stops the whole upload. */
export function fitPage(p: Page): Page {
  return { title: fitStoreText(p.title, 30), shortDescription: fitStoreText(p.shortDescription, 80), fullDescription: fitStoreText(p.fullDescription, 4000) };
}

export async function writeKit(opts: { complete: Complete; name: string; packageName?: string; description: string }): Promise<Kit> {
  const j = jsonObject(await opts.complete(KIT_SYSTEM, kitPrompt(opts)));
  const page = fitPage({ title: opts.name, shortDescription: str(j.shortDescription), fullDescription: str(j.fullDescription) });
  if (!page.shortDescription || !page.fullDescription) throw new Error('the AI wrote an empty listing');
  return {
    ...page,
    // The name is the owner's: the writer never gets to change it.
    title: fitStoreText(opts.name, 30),
    releaseNotes: fitStoreText(str(j.releaseNotes) || 'First release.', 500),
    privacyPolicyMarkdown: str(j.privacyPolicyMarkdown),
    dataSafetyGuide: str(j.dataSafetyGuide),
    contentRatingGuide: str(j.contentRatingGuide),
    otherDeclarationsGuide: str(j.otherDeclarationsGuide),
  };
}

/** A few languages per call: 25 full listings in one answer are far past what a model writes in one go. */
export const GROUP = 4;
const AT_ONCE = 3;

export function groupsOf<T>(items: readonly T[], size = GROUP): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

/**
 * The listing in every language asked, in groups, a few groups at a time.
 * A group that fails is skipped (the language simply has no page of its own and
 * Google shows the English one); [failed] says which.
 */
export async function translate(opts: { complete: Complete; kit: Page; languages: readonly string[] }): Promise<{ pages: Record<string, Page>; failed: string[] }> {
  const wanted = opts.languages.filter((l) => l !== 'en-US');
  const pages: Record<string, Page> = {};
  const failed: string[] = [];
  const groups = groupsOf(wanted);
  let next = 0;
  const worker = async () => {
    for (;;) {
      const i = next++;
      const langs = groups[i];
      if (!langs) return;
      try {
        const j = jsonObject(await opts.complete(TRANSLATE_SYSTEM, translatePrompt({ langs, title: opts.kit.title, short: opts.kit.shortDescription, full: opts.kit.fullDescription })));
        for (const lang of langs) {
          const v = j[lang] as Record<string, unknown> | undefined;
          if (!v) {
            failed.push(lang);
            continue;
          }
          // The name is the same on every store page: the one the owner chose.
          pages[lang] = fitPage({ title: opts.kit.title, shortDescription: str(v.shortDescription), fullDescription: str(v.fullDescription) });
        }
      } catch {
        failed.push(...langs);
      }
    }
  };
  await Promise.all(Array.from({ length: Math.min(AT_ONCE, groups.length) }, worker));
  return { pages, failed };
}

/** What `PUT /v1/projects/:id/store/listing` takes, in the shape the IDE reads back. */
export function listingBody(opts: { kit: Kit; pages: Record<string, Page>; languages: readonly string[]; email: string; privacyUrl: string }) {
  const { kit } = opts;
  return {
    title: kit.title,
    shortDescription: kit.shortDescription,
    fullDescription: kit.fullDescription,
    releaseNotes: kit.releaseNotes,
    contactEmail: opts.email,
    privacyUrl: opts.privacyUrl,
    dataSafety: kit.dataSafetyGuide,
    contentRating: kit.contentRatingGuide,
    otherDeclarations: kit.otherDeclarationsGuide,
    translations: JSON.stringify({
      languages: opts.languages.filter((l) => l !== 'en-US' && opts.pages[l]),
      pages: opts.pages,
      // The English text the translations were written from, so the IDE knows when they are old.
      from: `${kit.title}\u0001${kit.shortDescription}\u0001${kit.fullDescription}`,
    }),
  };
}
