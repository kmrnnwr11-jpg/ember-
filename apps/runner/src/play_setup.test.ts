import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { developerIdFromUrl, storeImages } from './play_setup.js';

describe('play setup', () => {
  it('reads the developer id from any Play Console link', () => {
    expect(developerIdFromUrl('https://play.google.com/console/u/0/developers/8123456789012345678/app-list')).toBe('8123456789012345678');
    expect(developerIdFromUrl('https://play.google.com/store/apps/details?id=x')).toBeNull();
  });

  it('collects icon, feature graphic and ordered screenshots', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-store-'));
    await mkdir(path.join(root, 'store', 'screenshots'), { recursive: true });
    expect(await storeImages(root)).toEqual({});
    await writeFile(path.join(root, 'store', 'play_icon_512.png'), 'x');
    for (const n of [10, 2, 1]) await writeFile(path.join(root, 'store', 'screenshots', `phone_${n}.png`), 'x');
    const imgs = await storeImages(root);
    expect(imgs.icon).toContain('play_icon_512.png');
    expect(imgs.featureGraphic).toBeUndefined();
    expect(imgs.phoneScreenshots!.map((p) => path.basename(p))).toEqual(['phone_1.png', 'phone_2.png', 'phone_10.png']);
    await rm(root, { recursive: true, force: true });
  });
});

describe('onPath', () => {
  it('finds a program by looking in the PATH folders, with the Windows extensions', async () => {
    const { mkdtemp, writeFile, rm } = await import('node:fs/promises');
    const os = await import('node:os');
    const path = await import('node:path');
    const { onPath } = await import('./play_setup.js');
    const dir = await mkdtemp(path.join(os.tmpdir(), 'fc-path-'));
    try {
      await writeFile(path.join(dir, 'gcloud.cmd'), '@echo off');
      expect(onPath('gcloud', { PATH: `C:\nowhere;${dir}`, PATHEXT: '.EXE;.CMD' }, 'win32')).toBe(true);
      expect(onPath('gcloud', { PATH: 'C:\nowhere', PATHEXT: '.EXE;.CMD' }, 'win32')).toBe(false);
      // The shell would call this "installed" (it answers "not recognised" with an ordinary exit code).
      expect(onPath('definitely-not-here', { PATH: dir, PATHEXT: '.EXE;.CMD' }, 'win32')).toBe(false);
      await writeFile(path.join(dir, 'gcloud'), '#!/bin/sh');
      expect(onPath('gcloud', { PATH: `/nowhere:${dir}` }, 'linux')).toBe(true);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });
});
