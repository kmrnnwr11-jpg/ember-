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
