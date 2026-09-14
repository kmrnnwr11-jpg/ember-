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
