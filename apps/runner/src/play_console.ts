import path from 'node:path';
import puppeteer, { type Browser, type Page } from 'puppeteer-core';
import { categoryChoice, plan, targetAudience, textAnswers } from '../../extension/rules.js';
import { findBrowser } from './screenshots.js';

/**
 * Filling Play Console's "App content" questions, which have no API.
 *
 * Ember drives a real Chrome window, visibly, only when the user asks. It reads
 * the questions on screen, decides with the same rules as the browser helper,
 * clicks the answers and saves. Everything a person could watch happening.
 */

/** The rows of App content Ember can answer, by the words on the link. */
const ROWS = [
  { id: 'ads', words: ['annunci', 'ads'] },
  { id: 'content_rating', words: ['classificazione', 'content rating'] },
  { id: 'target_audience', words: ['pubblico di destinazione', 'target audience'] },
  { id: 'government_apps', words: ['governative', 'government'] },
  { id: 'financial_features', words: ['finanziarie', 'financial'] },
  { id: 'news_apps', words: ['notizie', 'news'] },
  { id: 'health_apps', words: ['salute', 'health'] },
];

export interface FillResult {
  row: string;
  answered: number;
  saved: boolean;
  note?: string;
}

/** What the page shows right now, with every element tagged so it can be clicked back. */
const READ_PAGE = `(() => {
  const clean = (el) => ((el?.innerText ?? el?.textContent ?? '').replace(/\\s+/g, ' ').trim());
  const visible = (el) => el.offsetParent !== null || el.getClientRects().length > 0;
  let n = 0;
  const tag = (el) => (el.setAttribute('data-ember', String(++n)), n);

  const choices = [...document.querySelectorAll('input[type="radio"], input[type="checkbox"], [role="radio"], [role="checkbox"]')]
    .filter(visible)
    .map((el) => {
      const labelled = el.getAttribute('aria-label') || document.getElementById(el.getAttribute('aria-labelledby') ?? '')?.textContent;
      const label = (labelled || clean(el.closest('label')) || clean(el.parentElement) || '').slice(0, 200);
      return { ember: tag(el), label, checked: el.checked === true || el.getAttribute('aria-checked') === 'true', el };
    })
    .filter((c) => c.label);

  const groups = [...document.querySelectorAll('[role="radiogroup"], fieldset, form section')].filter((g) => g.querySelector('input, [role="radio"]'));
  const fields = groups.length
    ? groups
        .map((g) => {
          const mine = choices.filter((c) => g.contains(c.el));
          const heading = clean(g.querySelector('legend, h2, h3, [role="heading"]')) || clean(g.previousElementSibling) || clean(document.querySelector('h1, h2'));
          return { question: heading, options: mine.map((c) => c.label), tags: mine.map((c) => c.ember), checked: mine.map((c) => c.checked) };
        })
        .filter((f) => f.options.length)
    : [{ question: clean(document.querySelector('h1, h2')) || document.title, options: choices.map((c) => c.label), tags: choices.map((c) => c.ember), checked: choices.map((c) => c.checked) }];

  const inputs = [...document.querySelectorAll('input[type="text"], input[type="email"], input:not([type])')]
    .filter((el) => visible(el) && !el.disabled && !el.readOnly)
    .map((el, index) => ({
      index,
      ember: tag(el),
      type: el.type,
      value: el.value,
      label: (el.getAttribute('aria-label') || document.getElementById(el.getAttribute('aria-labelledby') ?? '')?.textContent || clean(el.closest('label')) || clean(el.closest('div')?.previousElementSibling) || el.placeholder || '').slice(0, 120),
    }));

  return { url: location.href, title: document.title, fields, inputs, body: document.body.innerText.slice(0, 4000) };
})()`;

interface PageRead {
  url: string;
  title: string;
  fields: Array<{ question: string; options: string[]; tags: number[]; checked: boolean[] }>;
  inputs: Array<{ index: number; ember: number; type: string; value: string; label: string }>;
  body: string;
}

/** Clicks one tagged element the way a person would. */
async function click(page: Page, ember: number): Promise<boolean> {
  return page.evaluate((id: number) => {
    const el = document.querySelector(`[data-ember="${id}"]`) as HTMLElement | null;
    if (!el) return false;
    (el.closest('label') ?? el).click();
    const input = el as HTMLInputElement;
    if (!input.checked && el.getAttribute('aria-checked') !== 'true') el.click();
    return input.checked === true || el.getAttribute('aria-checked') === 'true';
  }, ember);
}

async function typeInto(page: Page, ember: number, value: string): Promise<boolean> {
  return page.evaluate(
    (id: number, text: string) => {
      const el = document.querySelector(`[data-ember="${id}"]`) as HTMLInputElement | null;
      if (!el) return false;
      const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set;
      el.focus();
      setter ? setter.call(el, text) : (el.value = text);
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      el.blur();
      return el.value === text;
    },
    ember,
    value,
  );
}

/** Presses a button by the word written on it (Save, Next…). Returns false when there is none. */
async function press(page: Page, words: string[]): Promise<boolean> {
  const pressed = await page.evaluate((wanted: string[]) => {
    const text = (el: Element) => (el.textContent ?? '').replace(/\s+/g, ' ').trim().toLowerCase();
    const buttons = [...document.querySelectorAll('button, [role="button"]')].filter((b) => {
      const el = b as HTMLElement;
      const enabled = !(b as HTMLButtonElement).disabled && b.getAttribute('aria-disabled') !== 'true';
      return enabled && (el.offsetParent !== null || el.getClientRects().length > 0);
    });
    const hit = buttons.find((b) => wanted.some((w) => text(b) === w || text(b).startsWith(`${w} `)));
    if (!hit) return false;
    (hit as HTMLElement).click();
    return true;
  }, words);
  if (pressed) await new Promise((r) => setTimeout(r, 2500));
  return pressed;
}

const settle = (page: Page, ms = 2000) => page.evaluate((t: number) => new Promise((r) => setTimeout(r, t)), ms);

/** Answers every question on the page in front of us. Returns how many were set. */
async function answerVisible(page: Page, app: Record<string, unknown>): Promise<number> {
  const read = (await page.evaluate(READ_PAGE)) as PageRead;
  let done = 0;

  for (const t of textAnswers(read.inputs, app)) {
    const input = read.inputs[t.index];
    if (input && !input.value && (await typeInto(page, input.ember, t.value))) done++;
  }

  if (/categor/i.test(read.body)) {
    const field = read.fields.find((f) => /gioco|game/i.test(f.options.join(' ')));
    const choice = field ? categoryChoice(field.options) : -1;
    if (field && choice >= 0 && !field.checked[choice] && (await click(page, field.tags[choice]!))) done++;
  }

  for (const p of plan({ url: read.url, title: read.title, fields: read.fields, app })) {
    const field = read.fields.find((f) => f.question === p.question);
    const tag = field?.tags[p.option];
    if (tag && !field!.checked[p.option] && (await click(page, tag))) done++;
  }

  const ageField = read.fields.find((f) => /età|age|anni|years/i.test(f.options.join(' ')) && f.options.length >= 4);
  if (ageField) {
    for (const i of targetAudience(ageField.options)) {
      if (!ageField.checked[i] && (await click(page, ageField.tags[i]!))) done++;
    }
  }
  return done;
}

/** Opens one App content row from the hub page. */
async function openRow(page: Page, words: string[]): Promise<boolean> {
  const opened = await page.evaluate((wanted: string[]) => {
    const text = (el: Element) => (el.textContent ?? '').replace(/\s+/g, ' ').trim().toLowerCase();
    const links = [...document.querySelectorAll('a, [role="link"], button')];
    const hit = links.find((l) => wanted.some((w) => text(l).startsWith(w)));
    if (!hit) return false;
    (hit as HTMLElement).click();
    return true;
  }, words);
  if (opened) await new Promise((r) => setTimeout(r, 3500));
  return opened;
}

export interface ConsoleFillInput {
  /** Play Console addresses: the developer account and the app inside it. */
  developerId: string;
  appId: string;
  userIndex?: number;
  app: Record<string, unknown>;
  /** Where Chrome keeps the Google login between runs. */
  profileDir: string;
  /** false answers the questions and stops, leaving Save to the user. */
  save?: boolean;
  browserPath?: string | null;
}

/**
 * Walks the App content rows, answers what it can and saves.
 * The window stays visible: the user watches, and can take over at any point.
 */
export async function fillAppContent(input: ConsoleFillInput, launch = puppeteer.launch): Promise<{ results: FillResult[] }> {
  const executablePath = input.browserPath ?? (await findBrowser());
  if (!executablePath) throw new Error('Chrome is not installed on this PC, so Ember cannot open Play Console for you');

  const base = `https://play.google.com/console/u/${input.userIndex ?? 0}/developers/${input.developerId}/app/${input.appId}`;
  const browser: Browser = await launch({
    executablePath,
    headless: false,
    defaultViewport: null,
    userDataDir: path.resolve(input.profileDir),
    args: ['--start-maximized', '--no-first-run', '--no-default-browser-check'],
  });
  const results: FillResult[] = [];
  try {
    const page = (await browser.pages())[0] ?? (await browser.newPage());
    await page.goto(`${base}/app-content`, { waitUntil: 'domcontentloaded', timeout: 120_000 });
    await settle(page, 3000);

    // A login page means the user has not signed in to Google in this window yet.
    if (/accounts\.google\.com/.test(page.url())) {
      await page.waitForFunction('location.host === "play.google.com"', { timeout: 10 * 60_000 }).catch(() => {
        throw new Error('Sign in to Google in the window Ember opened, then press the button again');
      });
      await page.goto(`${base}/app-content`, { waitUntil: 'domcontentloaded', timeout: 120_000 });
      await settle(page, 3000);
    }

    for (const row of ROWS) {
      await page.goto(`${base}/app-content`, { waitUntil: 'domcontentloaded', timeout: 120_000 }).catch(() => {});
      await settle(page, 2500);
      if (!(await openRow(page, row.words))) {
        results.push({ row: row.id, answered: 0, saved: false, note: 'not found on this page' });
        continue;
      }
      let answered = 0;
      // The content rating questionnaire is several screens long: keep going while it moves on.
      for (let screen = 0; screen < 12; screen++) {
        answered += await answerVisible(page, input.app);
        const moved = await press(page, ['avanti', 'next', 'continua', 'continue']);
        if (!moved) break;
      }
      const saved = input.save === false ? false : await press(page, ['salva', 'save', 'invia', 'submit']);
      results.push({ row: row.id, answered, saved });
    }
    return { results };
  } finally {
    await browser.close().catch(() => {});
  }
}
