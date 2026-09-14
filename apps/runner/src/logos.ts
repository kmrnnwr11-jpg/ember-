import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { nanoid } from 'nanoid';
import sharp from 'sharp';

/**
 * App logos: the AI draws vector logos (SVG), the Runner renders them to PNG,
 * and the chosen one becomes the launcher icon, the 512 px Play icon and the
 * 1024×500 feature graphic. Vector output keeps logos crisp at every size and
 * works on free text models (image models have no free quota).
 */

export const LOGO_STYLES = [
  'flat minimal geometric symbol, two or three solid colors',
  'bold glyph on a vibrant diagonal gradient background',
  'soft 3D look with subtle shadows and highlights',
  'elegant line-art monogram made from the first letter of the app name',
  'playful rounded friendly shape with bright colors',
  'premium dark background with a gold or neon accent',
  'glass-like translucent layered shapes',
  'retro badge style with a thick outline',
  'abstract modern mark built from overlapping shapes',
  'duotone illustration of the app’s main object',
];

export const LOGO_SYSTEM = `You are a senior brand designer who draws mobile app icons as clean SVG code.
Rules:
- Output ONLY one SVG, starting with <svg and ending with </svg>. No markdown, no explanations.
- viewBox="0 0 512 512", width="512" height="512". Full-bleed square background (the launcher masks corners): fill the whole canvas.
- Centered symbol with generous padding (keep it inside the central 360x360 area), readable at 48 px.
- No text except at most one or two letters when the style asks for a monogram. No photos, no <image>, no external links, no scripts, no fonts.
- Use gradients, shapes and paths only. Make it professional, distinctive and on-brand for the app.`;

export function logoPrompt(opts: { appName: string; about: string; hint?: string; style: string; avoid?: string[] }): string {
  return [
    `App name: ${opts.appName}`,
    `What the app does: ${opts.about.slice(0, 1500)}`,
    opts.hint ? `The user wants the logo to be: ${opts.hint.slice(0, 500)}` : '',
    `Visual style for this proposal: ${opts.style}.`,
    opts.avoid?.length ? `It must look clearly different from these previous proposals: ${opts.avoid.join(' | ')}` : '',
    'Draw the icon now.',
  ]
    .filter(Boolean)
    .join('\n');
}

/** Keeps only a safe, self-contained SVG (no scripts, events or external references). */
export function sanitizeSvg(raw: string): string | null {
  const m = /<svg[\s\S]*?<\/svg>/i.exec(raw);
  if (!m) return null;
  let svg = m[0]
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<foreignObject[\s\S]*?<\/foreignObject>/gi, '')
    .replace(/<image[\s\S]*?(\/>|<\/image>)/gi, '')
    .replace(/\son[a-z]+\s*=\s*("[^"]*"|'[^']*')/gi, '')
    .replace(/\s(?:xlink:)?href\s*=\s*("(?!#)[^"]*"|'(?!#)[^']*')/gi, '');
  if (!/viewBox=/i.test(svg)) svg = svg.replace(/<svg/i, '<svg viewBox="0 0 512 512"');
  if (!/xmlns=/i.test(svg)) svg = svg.replace(/<svg/i, '<svg xmlns="http://www.w3.org/2000/svg"');
  return svg;
}

export async function renderPng(svg: string, size: number): Promise<Buffer> {
  return sharp(Buffer.from(svg), { density: 300 }).resize(size, size, { fit: 'cover' }).png().toBuffer();
}

/** Play Store feature graphic: the icon on a wide background taken from its own corner color. */
export async function featureGraphic(iconPng: Buffer): Promise<Buffer> {
  const { data } = await sharp(iconPng).resize(1, 1, { position: 'left top', fit: 'cover' }).raw().toBuffer({ resolveWithObject: true });
  const [r, g, b] = [data[0] ?? 20, data[1] ?? 20, data[2] ?? 20];
  const icon = await sharp(iconPng).resize(380, 380).toBuffer();
  return sharp({ create: { width: 1024, height: 500, channels: 4, background: { r, g, b, alpha: 1 } } })
    .composite([{ input: icon, left: 322, top: 60 }])
    .png()
    .toBuffer();
}

export type CompleteFn = (system: string, prompt: string) => Promise<string>;

export interface LogoProposal {
  id: string;
  style: string;
  png: string;
}

export function logosDir(projectRoot: string) {
  return path.join(projectRoot, 'store', 'logos');
}

/** Generates [count] proposals in parallel; failed drawings are simply skipped. */
export async function generateLogos(opts: { projectRoot: string; appName: string; about: string; hint?: string; count: number; complete: CompleteFn }): Promise<LogoProposal[]> {
  const dir = logosDir(opts.projectRoot);
  await mkdir(dir, { recursive: true });
  const previous = (await readdir(dir).catch(() => [] as string[])).filter((f) => f.endsWith('.json')).length;
  const styles = Array.from({ length: opts.count }, (_, i) => LOGO_STYLES[(previous + i) % LOGO_STYLES.length]!);
  const made = await Promise.all(
    styles.map(async (style) => {
      try {
        // One retry per proposal: models sometimes return a cut or invalid drawing.
        let svg: string | null = null;
        for (let attempt = 0; attempt < 2 && !svg; attempt++) {
          svg = sanitizeSvg(await opts.complete(LOGO_SYSTEM, logoPrompt({ appName: opts.appName, about: opts.about, hint: opts.hint, style })).catch(() => ''));
          if (svg) await renderPng(svg, 64).catch(() => (svg = null));
        }
        if (!svg) return null;
        const png = await renderPng(svg, 512);
        const id = nanoid(8);
        await writeFile(path.join(dir, `${id}.svg`), svg);
        await writeFile(path.join(dir, `${id}.json`), JSON.stringify({ style, hint: opts.hint ?? '', createdAt: new Date().toISOString() }));
        return { id, style, png: png.toString('base64') };
      } catch {
        return null;
      }
    }),
  );
  return made.filter((m): m is LogoProposal => m !== null);
}

/** Writes the chosen logo into the project: launcher icon source, Play icon and feature graphic, and icon generator config. */
export async function applyLogo(projectRoot: string, logoId: string): Promise<{ icon: string; playIcon: string; featureGraphic: string }> {
  if (!/^[\w-]{4,20}$/.test(logoId)) throw Object.assign(new Error('invalid logo id'), { code: 'bad_request' });
  const svg = await readFile(path.join(logosDir(projectRoot), `${logoId}.svg`), 'utf8').catch(() => null);
  if (!svg) throw Object.assign(new Error('logo not found'), { code: 'not_found' });
  const icon1024 = await renderPng(svg, 1024);
  await mkdir(path.join(projectRoot, 'assets', 'icon'), { recursive: true });
  await writeFile(path.join(projectRoot, 'assets', 'icon', 'app_icon.png'), icon1024);
  const store = path.join(projectRoot, 'store');
  await writeFile(path.join(store, 'play_icon_512.png'), await renderPng(svg, 512));
  await writeFile(path.join(store, 'feature_graphic.png'), await featureGraphic(icon1024));
  await writeFile(path.join(store, 'logo.json'), JSON.stringify({ logoId, appliedAt: new Date().toISOString() }));
  const pubspecPath = path.join(projectRoot, 'pubspec.yaml');
  const pubspec = await readFile(pubspecPath, 'utf8').catch(() => null);
  if (pubspec !== null) await writeFile(pubspecPath, withLauncherIcons(pubspec));
  return { icon: 'assets/icon/app_icon.png', playIcon: 'store/play_icon_512.png', featureGraphic: 'store/feature_graphic.png' };
}

/** Adds flutter_launcher_icons (dev dependency + config for Android, iOS, web, Windows) once. */
export function withLauncherIcons(pubspec: string): string {
  let out = pubspec;
  if (!/^\s+flutter_launcher_icons:/m.test(out)) {
    out = /^dev_dependencies:[ \t]*$/m.test(out)
      ? out.replace(/^dev_dependencies:[ \t]*\n/m, (h) => `${h}  flutter_launcher_icons: ^0.14.4\n`)
      : `${out.replace(/\s*$/, '')}\n\ndev_dependencies:\n  flutter_launcher_icons: ^0.14.4\n`;
  }
  if (!/^flutter_launcher_icons:/m.test(out)) {
    out = `${out.replace(/\s*$/, '')}\n\nflutter_launcher_icons:\n  image_path: "assets/icon/app_icon.png"\n  android: true\n  ios: true\n  remove_alpha_ios: true\n  web:\n    generate: true\n    image_path: "assets/icon/app_icon.png"\n  windows:\n    generate: true\n    image_path: "assets/icon/app_icon.png"\n`;
  }
  return out;
}
