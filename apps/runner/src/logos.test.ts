import { mkdtemp, readFile, rm, stat, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { applyLogo, generateLogos, LOGO_SYSTEM, quotedWords, sanitizeSvg, storeIcons, withLauncherIcons } from './logos.js';
import sharp from 'sharp';

const SVG = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><rect width="512" height="512" fill="#123"/><circle cx="256" cy="256" r="120" fill="#fc3"/></svg>';

describe('logos', () => {
  it('strips scripts, events and external references', () => {
    const dirty = '```svg\n<svg viewBox="0 0 512 512" onload="x()"><script>alert(1)</script><image href="http://evil/x.png"/><use href="#a"/><rect width="1" height="1"/></svg>\n```';
    const clean = sanitizeSvg(dirty)!;
    expect(clean).not.toMatch(/script|onload|evil|<image/);
    expect(clean).toContain('href="#a"');
    expect(clean).toContain('xmlns=');
    expect(sanitizeSvg('no svg here')).toBeNull();
  });

  it('puts the app own icon on the launch screen, instead of Flutter blank one', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-splash-'));
    const { mkdir } = await import('node:fs/promises');
    const res = path.join(root, 'android', 'app', 'src', 'main', 'res');
    await mkdir(path.join(res, 'drawable'), { recursive: true });
    await mkdir(path.join(root, 'ios', 'Runner', 'Assets.xcassets', 'LaunchImage.imageset'), { recursive: true });
    await writeFile(
      path.join(res, 'drawable', 'launch_background.xml'),
      '<?xml version="1.0" encoding="utf-8"?>\n<!-- Modify this file to customize your launch splash screen -->\n<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n    <item android:drawable="@android:color/white" />\n\n    <!-- You can insert your own image assets here -->\n    <!-- <item>\n        <bitmap\n            android:gravity="center"\n            android:src="@mipmap/launch_image" />\n    </item> -->\n</layer-list>\n',
    );
    await writeFile(path.join(root, 'pubspec.yaml'), 'name: demo\n');

    const logos = await generateLogos({ projectRoot: root, appName: 'Demo', about: 'x', count: 1, complete: async () => SVG });
    await applyLogo(root, logos[0]!.id);

    const xml = await readFile(path.join(res, 'drawable', 'launch_background.xml'), 'utf8');
    expect(xml).toContain('@mipmap/launch_image');
    expect(xml).not.toContain('<!-- <item>');
    expect(xml).toContain('@color/launchBackground');
    expect(await readFile(path.join(res, 'values', 'colors.xml'), 'utf8')).toMatch(/launchBackground">#[0-9a-f]{6}</);
    // One image per screen density, and the iPhone set Flutter already uses.
    for (const d of ['mipmap-mdpi', 'mipmap-xxxhdpi']) expect((await stat(path.join(res, d, 'launch_image.png'))).size).toBeGreaterThan(100);
    expect((await stat(path.join(root, 'ios', 'Runner', 'Assets.xcassets', 'LaunchImage.imageset', 'LaunchImage@3x.png'))).size).toBeGreaterThan(100);
    await rm(root, { recursive: true, force: true });
  });

  it('tells the designer to fill the icon and draw the thing that was asked for', () => {
    expect(LOGO_SYSTEM).toContain('at least 440 of the 512 units');
    expect(LOGO_SYSTEM).toContain('Draw exactly what was asked for');
    expect(LOGO_SYSTEM).not.toContain('360x360');
  });

  it('generates proposals, then applies one as icon, Play icon and feature graphic', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-logo-'));
    await writeFile(path.join(root, 'pubspec.yaml'), 'name: demo\ndependencies:\n  flutter:\n    sdk: flutter\ndev_dependencies:\n  flutter_test:\n    sdk: flutter\n');
    const prompts: string[] = [];
    const logos = await generateLogos({ projectRoot: root, appName: 'Demo', about: 'reads PDFs', hint: 'blue shield', count: 3, complete: async (_s, p) => (prompts.push(p), SVG) });
    expect(logos).toHaveLength(3);
    expect(new Set(prompts).size).toBe(3);
    // What the user asked for leads the prompt and outranks the style, and the
    // drawing must fill the icon instead of floating in empty space.
    expect(prompts[0]!.startsWith('DRAW THIS, exactly this, as the subject of the icon: blue shield')).toBe(true);
    expect(prompts[0]).toContain('never replaces the subject');
    expect(prompts[0]).toContain('90% of the canvas');
    const applied = await applyLogo(root, logos[0]!.id);
    for (const f of [applied.icon, applied.playIcon, applied.featureGraphic]) expect((await stat(path.join(root, f))).size).toBeGreaterThan(1000);
    const pubspec = await readFile(path.join(root, 'pubspec.yaml'), 'utf8');
    expect(pubspec).toContain('  flutter_launcher_icons: ^0.14.4');
    expect(pubspec).toContain('image_path: "assets/icon/app_icon.png"');
    expect(withLauncherIcons(pubspec)).toBe(pubspec);
    await rm(root, { recursive: true, force: true });
  });
});

describe('store state', () => {
  it('returns saved logos, applied logo, screenshots and listing', async () => {
    const { storeState } = await import('./logos.js');
    const sharp = (await import('sharp')).default;
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-state-'));
    await writeFile(path.join(root, 'pubspec.yaml'), 'name: demo\n');
    expect(await storeState(root)).toEqual({ logos: [], appliedLogo: null, screenshots: [], listing: null });
    const logos = await generateLogos({ projectRoot: root, appName: 'Demo', about: 'x', count: 2, complete: async () => SVG });
    await applyLogo(root, logos[1]!.id);
    const { mkdir } = await import('node:fs/promises');
    await mkdir(path.join(root, 'store', 'screenshots'), { recursive: true });
    const png = await sharp({ create: { width: 1080, height: 1920, channels: 3, background: '#fff' } }).png().toBuffer();
    await writeFile(path.join(root, 'store', 'screenshots', 'phone_1.png'), png);
    await writeFile(path.join(root, 'store', 'listing.json'), JSON.stringify({ title: 'Demo' }));
    const state = await storeState(root);
    expect(state.logos).toHaveLength(2);
    expect(state.appliedLogo).toBe(logos[1]!.id);
    expect(state.screenshots).toHaveLength(1);
    expect(state.listing).toMatchObject({ title: 'Demo' });
    await rm(root, { recursive: true, force: true });
  });

  it('builds both stores icons from the app own icon, whatever drew it', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-storeicons-'));
    const { mkdir } = await import('node:fs/promises');
    await mkdir(path.join(root, 'assets', 'icon'), { recursive: true });
    // An icon nobody generated through Ember: transparent corners, like a cut-out.
    await writeFile(
      path.join(root, 'assets', 'icon', 'app_icon.png'),
      await sharp({ create: { width: 1024, height: 1024, channels: 4, background: { r: 255, g: 239, b: 218, alpha: 0.5 } } }).png().toBuffer(),
    );
    const made = await storeIcons(root);
    expect(made?.appStoreIcon).toBe('store/appstore_icon_1024.png');
    const play = sharp(await readFile(path.join(root, 'store', 'play_icon_512.png')));
    expect((await play.metadata()).width).toBe(512);
    const apple = await sharp(await readFile(path.join(root, 'store', 'appstore_icon_1024.png'))).metadata();
    expect(apple.width).toBe(1024);
    // Apple refuses an icon with an alpha channel (ITMS-90717).
    expect(apple.hasAlpha).toBe(false);
    await rm(root, { recursive: true, force: true });
  });

  it('keeps the wording a brief asked for', () => {
    expect(quotedWords('scrivi "I am Capy" sopra')).toEqual(['I am Capy']);
    expect(quotedWords('nothing quoted here')).toEqual([]);
  });
});

describe('logo variants and delete', () => {
  it('a variant prompt carries the liked icon and one change', async () => {
    const { logoPrompt, VARIANT_TWEAKS } = await import('./logos.js');
    const p = logoPrompt({ appName: 'X', about: 'a', style: VARIANT_TWEAKS[0]!, base: '<svg id="liked"></svg>' });
    expect(p).toContain('VARIANT');
    expect(p).toContain('<svg id="liked"></svg>');
    expect(p).toContain(VARIANT_TWEAKS[0]!);
  });

  it('deletes the files of one proposal only', async () => {
    const { deleteLogo, logosDir } = await import('./logos.js');
    const { mkdtemp, mkdir: mk, writeFile: wf, readdir: rd } = await import('node:fs/promises');
    const os = await import('node:os');
    const root = await mkdtemp(path.join(os.tmpdir(), 'logo-del-'));
    const dir = logosDir(root);
    await mk(dir, { recursive: true });
    for (const f of ['abcd1234.svg', 'abcd1234.json', 'keep5678.svg', 'keep5678.json']) await wf(path.join(dir, f), 'x');
    expect(await deleteLogo(root, 'abcd1234')).toEqual({ deleted: 2 });
    expect((await rd(dir)).sort()).toEqual(['keep5678.json', 'keep5678.svg']);
    await expect(deleteLogo(root, '../x')).rejects.toThrow();
  });
});
