import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

/**
 * A website taken as the model for an app: what it offers and what it looks
 * like. The Play Store gives Ember a listing to copy; a website gives its own
 * pages, so the same "make me this, complete" flow works from a link.
 */

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130 Safari/537.36';

export interface WebSite {
  url: string;
  title: string;
  description: string;
  /** What the site says it does: headings, menu entries, buttons, tool names. */
  features: string[];
  /** Pages of the same site worth copying too (tools, sections). */
  pages: Array<{ url: string; label: string }>;
  /** Prices found on the page, so the app can earn the same way. */
  prices: string[];
  /** Brand colours read from the page, as a starting point to depart from. */
  colors: string[];
}

const strip = (s: string) =>
  s
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#0?39;|&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/\s+/g, ' ')
    .trim();

const meta = (html: string, prop: string) => new RegExp(`<meta[^>]+(?:property|name)=["']${prop}["'][^>]+content=["']([^"']*)`, 'i').exec(html)?.[1];

/** Everything the page offers, in the words the site itself uses. */
export function parseSite(url: string, html: string): WebSite {
  const title = strip(meta(html, 'og:site_name') ?? meta(html, 'og:title') ?? /<title[^>]*>([\s\S]*?)<\/title>/i.exec(html)?.[1] ?? '');
  const description = strip(meta(html, 'og:description') ?? meta(html, 'description') ?? '');

  const features: string[] = [];
  const add = (raw: string) => {
    const text = strip(raw);
    if (text.length < 2 || text.length > 70) return;
    if (/^(cookie|privacy|accetta|accept|login|accedi|sign in|sign up|registrati|menu|home)$/i.test(text)) return;
    if (!features.some((f) => f.toLowerCase() === text.toLowerCase())) features.push(text);
  };
  for (const re of [/<h[1-3][^>]*>([\s\S]{2,120}?)<\/h[1-3]>/gi, /<button[^>]*>([\s\S]{2,80}?)<\/button>/gi, /<a[^>]*class=["'][^"']*(?:card|tool|tile|service|item)[^"']*["'][^>]*>([\s\S]{2,120}?)<\/a>/gi]) {
    for (const m of html.matchAll(re)) add(m[1]!);
  }

  // Other pages of the same site: each one is usually one tool to rebuild.
  const base = new URL(url);
  const pages: Array<{ url: string; label: string }> = [];
  for (const m of html.matchAll(/<a[^>]+href=["']([^"'#?]+)["'][^>]*>([\s\S]{2,80}?)<\/a>/gi)) {
    const label = strip(m[2]!);
    if (label.length < 2 || label.length > 40) continue;
    let href: URL;
    try {
      href = new URL(m[1]!, base);
    } catch {
      continue;
    }
    if (href.host !== base.host || href.pathname === base.pathname || href.pathname === '/') continue;
    if (/privacy|cookie|terms|termini|login|signup|account|blog|contact/i.test(href.pathname)) continue;
    if (pages.some((p) => p.url === href.href)) continue;
    pages.push({ url: href.href, label });
    if (pages.length >= 25) break;
  }

  const prices: string[] = [];
  for (const m of strip(html).matchAll(/((?:[$€£]\s?\d+(?:[.,]\d{1,2})?)(?:\s*\/\s*(?:mese|month|anno|year|mo|yr))?)/gi)) {
    if (!prices.includes(m[1]!) && prices.length < 8) prices.push(m[1]!);
  }

  const colors: string[] = [];
  for (const m of html.matchAll(/#([0-9a-f]{6})\b/gi)) {
    const hex = `#${m[1]!.toLowerCase()}`;
    // Black, white and near-greys say nothing about a brand.
    const [r, g, b] = [parseInt(hex.slice(1, 3), 16), parseInt(hex.slice(3, 5), 16), parseInt(hex.slice(5, 7), 16)];
    if (Math.max(r, g, b) - Math.min(r, g, b) < 24) continue;
    if (!colors.includes(hex) && colors.length < 6) colors.push(hex);
  }

  return { url, title, description, features: features.slice(0, 40), pages, prices, colors };
}

/** Reads a website as a model for an app. */
export async function readSite(url: string, fetchImpl: typeof fetch = fetch): Promise<WebSite> {
  const res = await fetchImpl(url, { headers: { 'user-agent': UA, 'accept-language': 'it,en;q=0.8' }, signal: AbortSignal.timeout(20000) });
  if (!res.ok) throw Object.assign(new Error(`The site answered ${res.status}`), { status: res.status });
  return parseSite(url, await res.text());
}

/**
 * Photographs the site the way a phone sees it, into the project's `reference/`
 * folder: the engine copies screens it has seen, not screens it imagined.
 */
export async function saveSiteShots(opts: { projectRoot: string; urls: string[]; browser: string; limit?: number }): Promise<{ saved: number; dir: string }> {
  const { default: puppeteer } = await import('puppeteer-core');
  const dir = path.join(opts.projectRoot, 'reference');
  await mkdir(dir, { recursive: true });
  const browser = await puppeteer.launch({
    executablePath: opts.browser,
    headless: true,
    args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--no-first-run', '--no-default-browser-check', '--hide-scrollbars'],
  });
  let saved = 0;
  try {
    for (const url of opts.urls.slice(0, opts.limit ?? 6)) {
      const page = await browser.newPage();
      try {
        await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
        await page.goto(url, { waitUntil: 'networkidle2', timeout: 45_000 });
        await new Promise((r) => setTimeout(r, 1500));
        const png = Buffer.from(await page.screenshot({ type: 'png', fullPage: true }));
        await writeFile(path.join(dir, `site_${saved + 1}.png`), png);
        saved++;
      } catch {
        // A page that will not load is simply not part of the model.
      } finally {
        await page.close().catch(() => undefined);
      }
    }
  } finally {
    await browser.close().catch(() => undefined);
  }
  return { saved, dir };
}
