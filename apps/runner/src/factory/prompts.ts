import type { FactoryApp, Recipe } from './types.js';

/**
 * What the coding engine is told for each app of a batch. The long build
 * instructions (what a complete app is, real services, screenshot mode, ads,
 * purchases) are the Runner's own CLAUDE_CODE_BUILD_PROMPT; this adds what is
 * specific to a factory run.
 */

/** Same words the app builder sends from the IDE: the engine must say what only the owner can do. */
export const NEEDS_YOU_BLOCK = `

WHEN YOU CANNOT DO SOMETHING YOURSELF:
Some steps need the owner: signing in to Firebase or Google, pasting a key, creating an account, giving a file you do not have.
When you hit one, write a line that starts exactly with \`NEEDS YOU:\` and then, in English, the one thing they must do — short and concrete.
Write one such line per thing, in your reply, and carry on with everything else that does not depend on it.
Never fake your way around a missing sign-in or key, and never report as working something that needs one.`;

/** The ten languages every app speaks, picked from the phone at startup. */
export const LANGUAGES_BLOCK = `

LANGUAGES — EVERY APP, NO EXCEPTIONS:
The app speaks these ten languages, and picks the phone's own language automatically at startup:
English (en, the default and the fallback), Italian (it), Spanish (es), Portuguese (pt-BR), French (fr),
German (de), Hindi (hi), Arabic (ar), Indonesian (id), Russian (ru).
- Use Flutter's own localisation: flutter_localizations, an l10n.yaml, and one .arb file per language under lib/l10n.
  Generate the strings with gen-l10n and read them through AppLocalizations.
- No user-facing text is written inline in a widget. Not one string, not a button label, not an error, not a snackbar, not a dialog. Every one comes from the .arb files.
- Every key exists in all ten files. A missing translation falls back to English rather than showing the key.
- If the phone is set to a language not in the list, the app opens in English.
- Arabic reads right to left: the layout must hold in RTL (use start/end padding and alignment, never left/right).
- A Settings screen lets the user pick a language by hand, overriding the phone's, and the choice is remembered.`;

/** Nobody is there to answer: the studio runs by itself. */
export const AUTONOMOUS_BLOCK = `

THIS APP IS BUILT BY AN AUTOMATED STUDIO, WITH NOBODY TO ANSWER QUESTIONS:
- Decide everything yourself and never ask the owner a question. Take the most sensible choice and go on.
- Keep the app self-contained: data stays on the phone, no sign-in and no server unless the request below clearly needs one.
- Make it complete and polished — a real product people would keep — and make it clearly its own: its own name, colours, icon idea, wording and flow. Do not copy other apps.
- Do not use the words "demo", "sample" or "TODO" anywhere in the app.`;

export function nameBlock(name: string): string {
  return `

APP NAME: "${name}". Use exactly this name everywhere the app names itself: AppConfig.appName, the android:label in AndroidManifest.xml, CFBundleDisplayName in ios/Runner/Info.plist, the title on the home screen and anywhere the app introduces itself. Never invent another name.`;
}

/** The first request: everything the engine needs to write the whole app. */
export function codePrompt(app: Pick<FactoryApp, 'name' | 'brief' | 'summary' | 'size' | 'category'>, recipe: Pick<Recipe, 'extra'>): string {
  const extra = recipe.extra.trim();
  return [
    app.brief.trim() || app.summary.trim() || app.name,
    app.category ? `Store category: ${app.category}.` : '',
    nameBlock(app.name),
    AUTONOMOUS_BLOCK,
    NEEDS_YOU_BLOCK,
    LANGUAGES_BLOCK,
    extra ? `\n\nINSTRUCTIONS FOR EVERY APP OF THIS BATCH:\n${extra}` : '',
  ]
    .filter(Boolean)
    .join('');
}

/** Second round: the analyzer found problems. */
export function fixPrompt(problems: string): string {
  return `The Flutter analyzer reported these errors in the app you wrote. Fix every one of them, keep everything that works, then run \`flutter analyze\` again until there are no errors.\n\n${problems}`;
}

/** Lines of `NEEDS YOU:` an engine wrote in its reply. */
export function needsFromReply(reply: string): string[] {
  return [...reply.matchAll(/^\s*NEEDS YOU:\s*(.+)$/gim)].map((m) => m[1]!.trim()).filter(Boolean);
}

/** The `EMBER_PRODUCTS:` and `EMBER_ADS:` lines the engine put at the end of its reply. */
export function declaredFromReply(reply: string): { products: Array<Record<string, unknown>>; ads: Record<string, unknown> | null; text: string } {
  let text = reply;
  let products: Array<Record<string, unknown>> = [];
  let ads: Record<string, unknown> | null = null;
  const p = /^\s*EMBER_PRODUCTS:\s*(\[.*\])\s*$/m.exec(text);
  if (p) {
    try {
      products = (JSON.parse(p[1]!) as unknown[]).filter((x): x is Record<string, unknown> => !!x && typeof x === 'object');
    } catch {
      // an unreadable line just means no products
    }
    text = text.replace(p[0], '').trim();
  }
  const a = /^\s*EMBER_ADS:\s*(\{.*\})\s*$/m.exec(text);
  if (a) {
    try {
      ads = JSON.parse(a[1]!) as Record<string, unknown>;
    } catch {
      // ignore
    }
    text = text.replace(a[0], '').trim();
  }
  return { products, ads, text };
}

/** Analyzer lines that are errors (not infos or warnings). */
export function analyzerErrors(output: string): string[] {
  return output.split(/\r?\n/).filter((l) => /^\s*error\s+[•-]/i.test(l) || /\berror\s+•/.test(l));
}

/** Words that mean an engine has no more to give for now. */
export const USAGE_LIMIT = /usage limit|rate limit|rate_limit|quota|credit balance|too many requests|resource exhausted|\b429\b|limit reached|try again (in|at|after)/i;

/** How long to rest an engine after a limit message: its own hint if it gave one, else half an hour. */
export function restAfterLimit(message: string, now = Date.now()): number {
  const minutes = /(\d+)\s*(?:minutes?|min)\b/i.exec(message)?.[1];
  if (minutes) return Math.min(24 * 60, Number(minutes) + 1) * 60_000;
  const hours = /(\d+)\s*hours?\b/i.exec(message)?.[1];
  if (hours) return Math.min(24, Number(hours)) * 3600_000 + 60_000;
  const at = /resets?\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/i.exec(message);
  if (at) {
    let h = Number(at[1]);
    if (at[3]?.toLowerCase() === 'pm' && h < 12) h += 12;
    const d = new Date(now);
    d.setHours(h, Number(at[2] ?? 0), 0, 0);
    if (d.getTime() <= now) d.setDate(d.getDate() + 1);
    return d.getTime() - now + 60_000;
  }
  return 30 * 60_000;
}
