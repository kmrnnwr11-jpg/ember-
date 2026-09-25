import { existsSync } from 'node:fs';
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

/** What an icon on a 2026 home screen looks like, spelled out. */
export const LOGO_2026 = `THIS MUST LOOK LIKE A 2026 APP ICON, NOT A 2015 ONE:
- One simple, bold shape that reads at 48 px. If it needs a second look to be understood, it is too complicated.
- Flat or a single smooth gradient between two neighbouring hues. No bevels, no glossy highlight, no drop shadow, no outer glow, no skeuomorphic depth.
- Two or three colours at most, confident and saturated, on a solid or single-gradient ground.
- Thick, even strokes and generous rounding where the shape has corners; nothing hair-thin, which disappears when small.
- No text, no thin decorative rings, no busy background patterns, no photo-realism.`;

export const LOGO_SYSTEM = `You are a senior brand designer who draws mobile app icons as clean SVG code.

${LOGO_2026}

Rules:
- Output ONLY one SVG, starting with <svg and ending with </svg>. No markdown, no explanations.
- viewBox="0 0 512 512", width="512" height="512". Full-bleed square background (the launcher masks corners): fill the whole canvas.
- THE SUBJECT FILLS THE ICON: it spans at least 440 of the 512 units in its larger dimension — roughly 90% of the canvas, leaving only a thin margin (about 36 units) around it. A small mark floating in empty space is the most common failure and is rejected. Centre it, and let it touch that margin on the sides where its shape allows.
- Draw exactly what was asked for, recognisably: if the user names a thing, that thing is the icon — its real silhouette, seen straight on, in a shape a person names at a glance and at 48 px. No unrelated shapes, no abstract blob standing in for the subject.
- No text except at most one or two letters when the style asks for a monogram. No photos, no <image>, no external links, no scripts, no fonts.
- Use gradients, shapes and paths only. Make it professional, distinctive and on-brand for the app.`;

export function logoPrompt(opts: { appName: string; about: string; hint?: string; style: string; avoid?: string[] }): string {
  return [
    // What the user asked for outranks everything else, so it goes first.
    opts.hint ? `DRAW THIS, exactly this, as the subject of the icon: ${opts.hint.slice(0, 500)}\nIt must be immediately recognisable as that, and fill about 90% of the canvas.` : '',
    `App name: ${opts.appName}`,
    `What the app does: ${opts.about.slice(0, 1500)}`,
    opts.hint
      ? `Visual style for this proposal: ${opts.style}. The style changes how the subject is drawn; it never replaces the subject.`
      : `Visual style for this proposal: ${opts.style}.`,
    opts.avoid?.length ? `It must look clearly different from these previous proposals: ${opts.avoid.join(' | ')}` : '',
    'Draw the icon now, big, filling the canvas.',
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
  /** Filled only when a panel drew them: who drew it and how it was judged. */
  authorLabel?: string;
  score?: number;
  notes?: string[];
}

/** One model at the design table: it draws, then judges the others' drawings. */
export interface LogoPanelMember {
  id: string;
  label: string;
  complete: CompleteFn;
}

const CRITIQUE_SYSTEM = `You are a brand design director reviewing app icons drawn by other designers as SVG, and you answer with JSON only.
You read SVG the way a designer reads a sketch: how many shapes, how big the subject is inside the 512 canvas, how many colours,
whether it would still be readable at 48 px. You never praise; you name the one change that would most improve each icon.
Reject, every time you see them: a small mark floating in empty space, more than three colours, bevels, glossy highlights,
drop shadows, glows, hair-thin strokes, text, and anything too detailed to read at 48 px.`;

const critiquePrompt = (appName: string, about: string, entries: string) => `The app: ${appName} — ${about.slice(0, 600)}

These are the icons on the table, as SVG:

${entries}

Score every icon from 1 to 10 and give ONE concrete instruction that would most improve it — something a designer can act on
("make the cup fill 90% of the canvas and drop the thin ring around it"), never vague advice ("make it more modern").
Answer with a JSON array only, one entry per icon, no prose around it:
[{"n": 1, "score": 7, "fix": "the one instruction"}]`;

/** Reads the scores out of a critic's answer, however it wrapped them. */
export function parseLogoCritique(text: string): Array<{ n: number; score: number; fix: string }> {
  const start = text.indexOf('[');
  const end = text.lastIndexOf(']');
  if (start < 0 || end <= start) return [];
  try {
    const raw = JSON.parse(text.slice(start, end + 1)) as unknown;
    if (!Array.isArray(raw)) return [];
    const out: Array<{ n: number; score: number; fix: string }> = [];
    for (const e of raw) {
      if (!e || typeof e !== 'object') continue;
      const o = e as Record<string, unknown>;
      const n = Number(o.n);
      const score = Number(o.score);
      if (!Number.isFinite(n) || !Number.isFinite(score)) continue;
      out.push({ n, score: Math.min(10, Math.max(1, score)), fix: `${o.fix ?? ''}`.trim().slice(0, 400) });
    }
    return out;
  } catch {
    return [];
  }
}

/** Draws one icon, retrying once: models sometimes return a cut or invalid drawing. */
async function drawSvg(complete: CompleteFn, prompt: string): Promise<string | null> {
  for (let attempt = 0; attempt < 2; attempt++) {
    const svg = sanitizeSvg(await complete(LOGO_SYSTEM, prompt).catch(() => ''));
    if (!svg) continue;
    const ok = await renderPng(svg, 64).then(
      () => true,
      () => false,
    );
    if (ok) return svg;
  }
  return null;
}

async function saveLogo(dir: string, id: string, svg: string, meta: Record<string, unknown>): Promise<void> {
  await writeFile(path.join(dir, `${id}.svg`), svg);
  await writeFile(path.join(dir, `${id}.json`), JSON.stringify({ ...meta, createdAt: new Date().toISOString() }));
}

/**
 * Several models draw the icons, then read each other's SVG, score it and say
 * the one thing that would most improve it; every model then redraws its own
 * icons with the notes the others wrote. A drawing nobody but its own author
 * has looked at is how the dated, floating-mark icons got through.
 */
export async function generateLogosPanel(opts: {
  projectRoot: string;
  appName: string;
  about: string;
  hint?: string;
  count: number;
  members: LogoPanelMember[];
}): Promise<LogoProposal[]> {
  const dir = logosDir(opts.projectRoot);
  await mkdir(dir, { recursive: true });
  const previous = (await readdir(dir).catch(() => [] as string[])).filter((f) => f.endsWith('.json')).length;

  // Round-robin, so the set is never one model's taste repeated six times.
  const jobs = Array.from({ length: opts.count }, (_, i) => ({
    style: LOGO_STYLES[(previous + i) % LOGO_STYLES.length]!,
    member: opts.members[i % opts.members.length]!,
    prompt: logoPrompt({ appName: opts.appName, about: opts.about, hint: opts.hint, style: LOGO_STYLES[(previous + i) % LOGO_STYLES.length]! }),
  }));

  const drawn = (
    await Promise.all(
      jobs.map(async (j) => {
        const svg = await drawSvg(j.member.complete, j.prompt);
        return svg ? { ...j, svg, id: nanoid(8) } : null;
      }),
    )
  ).filter((d): d is NonNullable<typeof d> => d !== null);
  if (drawn.length === 0) return [];

  // The table: every member scores every icon, including its own.
  const entries = drawn.map((d, i) => `ICON ${i + 1} — by ${d.member.label}, style "${d.style}"\n${d.svg.slice(0, 2200)}`).join('\n\n');
  const votes = await Promise.all(
    opts.members.map(async (m) => ({
      by: m.id,
      label: m.label,
      list: parseLogoCritique(await m.complete(CRITIQUE_SYSTEM, critiquePrompt(opts.appName, opts.about, entries)).catch(() => '')),
    })),
  );

  const judged = drawn.map((d, i) => {
    const scores: number[] = [];
    const notes: string[] = [];
    for (const v of votes) {
      const entry = v.list.find((e) => e.n === i + 1);
      if (!entry) continue;
      scores.push(entry.score);
      // A designer's opinion of their own drawing is not a second opinion.
      if (v.by !== d.member.id && entry.fix) notes.push(`${v.label}: ${entry.fix}`);
    }
    return { ...d, score: scores.length ? scores.reduce((a, b) => a + b, 0) / scores.length : undefined, notes };
  });

  // Each author redraws its own icons with what the others said.
  const finished = await Promise.all(
    judged.map(async (d) => {
      let svg = d.svg;
      if (d.notes.length > 0) {
        const better = await drawSvg(
          d.member.complete,
          `${d.prompt}\n\nThis is the icon you drew:\n${d.svg.slice(0, 2200)}\n\n` +
            `The design panel scored it ${d.score?.toFixed(1) ?? '?'}/10. Apply these notes from the other designers, ` +
            `keep what already works, and draw the complete improved icon:\n${d.notes.map((n) => `- ${n}`).join('\n')}`,
        );
        if (better) svg = better;
      }
      try {
        const png = await renderPng(svg, 512);
        await saveLogo(dir, d.id, svg, { style: d.style, hint: opts.hint ?? '', author: d.member.label, score: d.score ?? null, notes: d.notes });
        return { id: d.id, style: d.style, png: png.toString('base64'), authorLabel: d.member.label, score: d.score, notes: d.notes };
      } catch {
        return null;
      }
    }),
  );

  // Best first: what several models independently rated highly is the safest bet.
  const kept: LogoProposal[] = finished.filter((p) => p !== null);
  return kept.sort((a, b) => (b.score ?? 0) - (a.score ?? 0));
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
  await applySplash(projectRoot, svg).catch(() => undefined);
  return { icon: 'assets/icon/app_icon.png', playIcon: 'store/play_icon_512.png', featureGraphic: 'store/feature_graphic.png' };
}

/** The colour in the middle of the icon: the ground a splash screen sits on. */
export async function iconBackgroundColor(iconPng: Buffer): Promise<string> {
  const { data } = await sharp(iconPng).resize(1, 1, { fit: 'cover' }).raw().toBuffer({ resolveWithObject: true });
  const hex = (n: number) => (n ?? 0).toString(16).padStart(2, '0');
  return `#${hex(data[0] ?? 255)}${hex(data[1] ?? 255)}${hex(data[2] ?? 255)}`;
}

/** Android: the launch screen shows the app's own icon, centred, on its colour. */
export function withSplashBitmap(launchBackground: string, color: string): string {
  const item = `    <item>\n        <bitmap\n            android:gravity="center"\n            android:src="@mipmap/launch_image" />\n    </item>`;
  const withColour = launchBackground.replace(/<item android:drawable="[^"]*"\s*\/>/, `<item android:drawable="@color/launchBackground" />`);
  // The template ships the bitmap commented out; replace it, or add it before </layer-list>.
  const uncommented = withColour.replace(/<!--\s*You can insert your own image assets here\s*-->\s*<!--[\s\S]*?-->/, item);
  const out = uncommented.includes('@mipmap/launch_image') ? uncommented : uncommented.replace('</layer-list>', `${item}\n</layer-list>`);
  return out.replace(/<!--\s*Modify this file[^>]*-->\n?/, `<!-- Launch screen: the app's own icon on ${color} -->\n`);
}

/**
 * The picture a phone shows while the app starts. Without this every app made
 * with Ember opens on Flutter's blank white screen, whatever its icon is.
 */
export async function applySplash(projectRoot: string, svg: string): Promise<void> {
  const icon512 = await renderPng(svg, 512);
  const color = await iconBackgroundColor(icon512);

  // Android: one launch image per screen density, plus the colour behind it.
  const res = path.join(projectRoot, 'android', 'app', 'src', 'main', 'res');
  const densities: Array<[string, number]> = [
    ['mipmap-mdpi', 160],
    ['mipmap-hdpi', 240],
    ['mipmap-xhdpi', 320],
    ['mipmap-xxhdpi', 480],
    ['mipmap-xxxhdpi', 640],
  ];
  for (const [dir, size] of densities) {
    await mkdir(path.join(res, dir), { recursive: true });
    await writeFile(path.join(res, dir, 'launch_image.png'), await renderPng(svg, size));
  }
  for (const dir of ['drawable', 'drawable-v21']) {
    const file = path.join(res, dir, 'launch_background.xml');
    const current = await readFile(file, 'utf8').catch(() => null);
    if (current !== null) await writeFile(file, withSplashBitmap(current, color));
  }
  await mkdir(path.join(res, 'values'), { recursive: true });
  const colorsFile = path.join(res, 'values', 'colors.xml');
  const colors = await readFile(colorsFile, 'utf8').catch(() => null);
  const entry = `    <color name="launchBackground">${color}</color>`;
  await writeFile(
    colorsFile,
    colors === null
      ? `<?xml version="1.0" encoding="utf-8"?>\n<resources>\n${entry}\n</resources>\n`
      : /name="launchBackground"/.test(colors)
        ? colors.replace(/<color name="launchBackground">[^<]*<\/color>/, entry.trim())
        : colors.replace('</resources>', `${entry}\n</resources>`),
  );

  // iPhone: the launch image set Flutter's storyboard already points at.
  const launchSet = path.join(projectRoot, 'ios', 'Runner', 'Assets.xcassets', 'LaunchImage.imageset');
  if (existsSync(launchSet)) {
    for (const [name, size] of [
      ['LaunchImage.png', 160],
      ['LaunchImage@2x.png', 320],
      ['LaunchImage@3x.png', 480],
    ] as Array<[string, number]>) {
      await writeFile(path.join(launchSet, name), await renderPng(svg, size));
    }
  }
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

/** Everything Ember produced for the store, so a reopened app shows it again. */
export async function storeState(projectRoot: string): Promise<{
  logos: Array<{ id: string; thumb: string }>;
  appliedLogo: string | null;
  screenshots: string[];
  listing: Record<string, unknown> | null;
}> {
  const dir = logosDir(projectRoot);
  const files = await readdir(dir).catch(() => [] as string[]);
  const metas = await Promise.all(
    files
      .filter((f) => f.endsWith('.json'))
      .map(async (f) => {
        const id = f.slice(0, -5);
        const meta = JSON.parse(await readFile(path.join(dir, f), 'utf8').catch(() => '{}')) as { createdAt?: string };
        return { id, at: meta.createdAt ?? '' };
      }),
  );
  metas.sort((a, b) => b.at.localeCompare(a.at));
  const logos: Array<{ id: string; thumb: string }> = [];
  for (const m of metas.slice(0, 30)) {
    const svg = await readFile(path.join(dir, `${m.id}.svg`), 'utf8').catch(() => null);
    if (!svg) continue;
    const png = await renderPng(svg, 256).catch(() => null);
    if (png) logos.push({ id: m.id, thumb: png.toString('base64') });
  }
  const store = path.join(projectRoot, 'store');
  const applied = JSON.parse(await readFile(path.join(store, 'logo.json'), 'utf8').catch(() => '{}')) as { logoId?: string };
  const shotsDir = path.join(store, 'screenshots');
  const shotFiles = (await readdir(shotsDir).catch(() => [] as string[]))
    .filter((f) => /^phone_\d+\.png$/.test(f))
    .sort((a, b) => Number(/\d+/.exec(a)![0]) - Number(/\d+/.exec(b)![0]));
  const screenshots: string[] = [];
  for (const f of shotFiles) {
    const buf = await readFile(path.join(shotsDir, f)).catch(() => null);
    if (buf) screenshots.push((await sharp(buf).resize(270, 480).png().toBuffer()).toString('base64'));
  }
  const listing = JSON.parse(await readFile(path.join(store, 'listing.json'), 'utf8').catch(() => 'null')) as Record<string, unknown> | null;
  return { logos, appliedLogo: applied.logoId ?? null, screenshots, listing };
}
