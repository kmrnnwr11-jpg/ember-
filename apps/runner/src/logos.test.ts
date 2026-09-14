import { mkdtemp, readFile, rm, stat, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { applyLogo, generateLogos, sanitizeSvg, withLauncherIcons } from './logos.js';

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

  it('generates proposals, then applies one as icon, Play icon and feature graphic', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-logo-'));
    await writeFile(path.join(root, 'pubspec.yaml'), 'name: demo\ndependencies:\n  flutter:\n    sdk: flutter\ndev_dependencies:\n  flutter_test:\n    sdk: flutter\n');
    const prompts: string[] = [];
    const logos = await generateLogos({ projectRoot: root, appName: 'Demo', about: 'reads PDFs', hint: 'blue shield', count: 3, complete: async (_s, p) => (prompts.push(p), SVG) });
    expect(logos).toHaveLength(3);
    expect(new Set(prompts).size).toBe(3);
    expect(prompts[0]).toContain('blue shield');
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
});
