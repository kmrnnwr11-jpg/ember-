import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { syncAdmobAppId } from './services.js';

const REAL = 'ca-app-pub-9396424020196768~7284056584';
const TEST = 'ca-app-pub-3940256099942544~3347511713';

async function project(adsConfig: string, manifestValue: string): Promise<string> {
  const root = await mkdtemp(path.join(os.tmpdir(), 'fc-admob-'));
  await mkdir(path.join(root, 'lib', 'config'), { recursive: true });
  await mkdir(path.join(root, 'android', 'app', 'src', 'main'), { recursive: true });
  await writeFile(path.join(root, 'lib', 'config', 'ads_config.dart'), adsConfig);
  await writeFile(
    path.join(root, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'),
    `<manifest><application><meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="${manifestValue}"/></application></manifest>`,
  );
  return root;
}

const manifestId = async (root: string) =>
  /android:value="([^"]*)"/.exec(await readFile(path.join(root, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'), 'utf8'))?.[1];

describe('AdMob app id kept in step with the manifest', () => {
  it('takes the real id, not the test one that shares its name', async () => {
    // The test constant comes first on purpose: that is the order an app gets
    // when the ids are split into test and live.
    const root = await project(
      `static const String testAndroidAppId = '${TEST}';\nstatic const String liveAndroidAppId = '${REAL}';\n`,
      'ca-app-pub-0000000000000000~0000000000',
    );
    await syncAdmobAppId(root);
    expect(await manifestId(root)).toBe(REAL);
    await rm(root, { recursive: true, force: true });
  });

  it('leaves a per-build-type placeholder alone', async () => {
    // Filling this in would put the real id in debug builds, where tapping an
    // ad is tapping your own — the fastest way to lose an AdMob account.
    const root = await project(`static const String liveAndroidAppId = '${REAL}';\n`, '${admobAppId}');
    await syncAdmobAppId(root);
    expect(await manifestId(root)).toBe('${admobAppId}');
    await rm(root, { recursive: true, force: true });
  });

  it('writes nothing when the app still carries only test ids', async () => {
    const root = await project(`static const String androidAppId = '${TEST}';\n`, 'ca-app-pub-0000000000000000~0000000000');
    await syncAdmobAppId(root);
    expect(await manifestId(root)).toBe('ca-app-pub-0000000000000000~0000000000');
    await rm(root, { recursive: true, force: true });
  });
});
