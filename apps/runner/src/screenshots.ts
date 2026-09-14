import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';

/**
 * Play Store screenshots: the web preview is opened in headless Chrome at phone
 * size (360×640 @3x = 1080×1920) once per screen, using the app's screenshot mode
 * (`?ember_screen=N` opens screen N with demo data).
 */

export const SCREEN_PARAM = 'ember_screen';

/** Instruction for the AI, used in build prompts and to upgrade existing apps. */
export const SCREENSHOT_MODE_RULE =
  `SCREENSHOT MODE (always include): on web, when the URL has the query parameter ${SCREEN_PARAM}=N (N = 0..5), open directly the app's N-th most representative screen ` +
  '(home, main feature, detail, list, profile/settings, premium…), filled with realistic demo content, skipping splash, login, onboarding and "configuration needed" screens, ' +
  `without dialogs or debug banners. Read it with Uri.base.queryParameters['${SCREEN_PARAM}'] and keep the screen list in lib/config/screenshot_screens.dart. Normal launches are unchanged.`;

export const SCREENSHOT_UPGRADE_REQUEST = `Add a screenshot mode to this app for the Play Store screenshots. ${SCREENSHOT_MODE_RULE} Do not change anything else.`;

export function findBrowser(explicit?: string): string | null {
  const candidates = [
    explicit,
    process.env.CHROME_BIN,
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  ];
  return candidates.find((c): c is string => !!c && existsSync(c)) ?? null;
}

/** True when the app code already contains the screenshot mode. */
export async function hasScreenshotMode(projectRoot: string): Promise<boolean> {
  const walk = async (dir: string): Promise<boolean> => {
    const entries = await readdir(dir, { withFileTypes: true }).catch(() => []);
    for (const e of entries) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (await walk(p)) return true;
      } else if (e.name.endsWith('.dart') && (await readFile(p, 'utf8')).includes(SCREEN_PARAM)) {
        return true;
      }
    }
    return false;
  };
  return walk(path.join(projectRoot, 'lib'));
}

export interface Shot {
  index: number;
  file: string;
  thumb: string;
}

/** Captures up to [count] distinct screens; identical frames (screen not implemented) are skipped. */
export async function captureScreenshots(opts: { previewUrl: string; projectRoot: string; browser: string; count?: number }): Promise<Shot[]> {
  const { default: puppeteer } = await import('puppeteer-core');
  const count = opts.count ?? 6;
  const dir = path.join(opts.projectRoot, 'store', 'screenshots');
  await mkdir(dir, { recursive: true });
  const browser = await puppeteer.launch({
    executablePath: opts.browser,
    headless: true,
    args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--no-first-run', '--no-default-browser-check', '--hide-scrollbars'],
  });
  const shots: Shot[] = [];
  const seen = new Set<string>();
  try {
    for (let i = 0; i < count; i++) {
      const page = await browser.newPage();
      try {
        await page.setViewport({ width: 360, height: 640, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
        const sep = opts.previewUrl.includes('?') ? '&' : '?';
        await page.goto(`${opts.previewUrl}${sep}${SCREEN_PARAM}=${i}`, { waitUntil: 'networkidle0', timeout: 90_000 });
        await page.waitForFunction(() => document.querySelector('flutter-view, flt-glass-pane') !== null, { timeout: 60_000 });
        // Let fonts, images and entrance animations settle.
        await new Promise((r) => setTimeout(r, 3500));
        const png = Buffer.from(await page.screenshot({ type: 'png' }));
        const hash = createHash('sha1').update(png).digest('hex');
        if (seen.has(hash)) continue;
        seen.add(hash);
        const n = shots.length + 1;
        const file = `store/screenshots/phone_${n}.png`;
        await writeFile(path.join(opts.projectRoot, file), png);
        const thumb = (await sharp(png).resize(270, 480).png().toBuffer()).toString('base64');
        shots.push({ index: i, file, thumb });
      } finally {
        await page.close().catch(() => undefined);
      }
    }
  } finally {
    await browser.close().catch(() => undefined);
  }
  return shots;
}
