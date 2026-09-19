import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { afterAll, describe, expect, it } from 'vitest';
import { loadConfig } from './config.js';
import {
  bumpBuildNumber,
  ensureUploadKey,
  lastAppStoreBuildNumber,
  lastPublishedBuildNumber,
  lastPublishedVersionCode,
  rememberAppStoreBuildNumber,
  openSecret,
  patchGradleKts,
  rememberPublishedVersionCode,
  resolveKeytool,
  sealSecret,
  SIGNING_MARKER,
} from './signing.js';

const TEMPLATE = `android {
    defaultConfig {
        versionCode = flutter.versionCode
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
`;

describe('signing helpers', () => {
  it('patches the Flutter Kotlin Gradle template idempotently, without secrets', () => {
    const once = patchGradleKts(TEMPLATE);
    expect(once).toContain(SIGNING_MARKER);
    expect(once).toContain('create("release")');
    expect(once).toContain('System.getenv("FC_KEYSTORE_PASSWORD")');
    expect(once).toContain('if (System.getenv("FC_KEYSTORE_PATH") != null) signingConfigs.getByName("release") else signingConfigs.getByName("debug")');
    expect(once.indexOf('signingConfigs {')).toBeLessThan(once.indexOf('buildTypes {'));
    expect(patchGradleKts(once)).toBe(once);
  });

  it('bumps the build number for every signed upload', () => {
    expect(bumpBuildNumber('name: a\nversion: 1.2.3+7\n')).toEqual({ text: 'name: a\nversion: 1.2.3+8\n', version: '1.2.3+8' });
    expect(bumpBuildNumber('name: a\nversion: 1.0.0\n').version).toBe('1.0.0+1');
    expect(bumpBuildNumber('name: a\n').text).toContain('version: 1.0.0+1');
    // Google Play already has 9: the next build must be above it, not above the file.
    expect(bumpBuildNumber('name: a\nversion: 1.2.3+2\n', 9).version).toBe('1.2.3+10');
  });

  it('reads the published version code even from a hand-written file', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'ember-signing-'));
    const store = path.join(root, 'store');
    await mkdir(store, { recursive: true });
    await writeFile(path.join(store, 'play.json'), '﻿{ "lastVersionCode": 5 }');
    expect(await lastPublishedVersionCode(root)).toBe(5);
    await writeFile(path.join(store, 'play.json'), 'not json at all');
    expect(await lastPublishedVersionCode(root)).toBe(0);
    await rm(root, { recursive: true, force: true });
  });

  it('keeps one build number above both stores', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'ember-signing-'));
    await rememberPublishedVersionCode(root, 9);
    await rememberAppStoreBuildNumber(root, 12);
    expect(await lastPublishedBuildNumber(root)).toBe(12);
    // The next build of either store starts above what Apple already has.
    expect(bumpBuildNumber('name: demo\nversion: 1.0.0+3\n', await lastPublishedBuildNumber(root)).version).toBe('1.0.0+13');
    await rm(root, { recursive: true, force: true });
  });

  it('keeps the highest version code it has seen', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'ember-signing-'));
    await rememberPublishedVersionCode(root, 7);
    await rememberPublishedVersionCode(root, 3);
    expect(await lastPublishedVersionCode(root)).toBe(7);
    await rm(root, { recursive: true, force: true });
  });

  it('encrypts secrets when VAULT_MASTER_KEY is set', () => {
    const cfg = loadConfig({ DEV_AUTH: 'true', VAULT_MASTER_KEY: 'a'.repeat(64) });
    const sealed = sealSecret(cfg, 'hunter2');
    expect(sealed.encrypted).toBe(true);
    expect(sealed.value).not.toContain('hunter2');
    expect(openSecret(cfg, sealed.value, true)).toBe('hunter2');
    expect(sealSecret(loadConfig({ DEV_AUTH: 'true' }), 'x')).toEqual({ value: 'x', encrypted: false });
  });
});

describe('ensureUploadKey (real keytool)', () => {
  let tmp = '';
  afterAll(() => (tmp ? rm(tmp, { recursive: true, force: true }) : undefined));

  it('creates a PKCS12 upload key once and reuses it', async () => {
    const cfg0 = loadConfig({ DEV_AUTH: 'true' });
    const keytool = resolveKeytool(cfg0);
    if (keytool === 'keytool' || keytool === 'keytool.exe') {
      // No JDK found on this machine: skip the real-keytool check.
      return;
    }
    tmp = await mkdtemp(path.join(os.tmpdir(), 'fc-sign-'));
    const cfg = loadConfig({ DEV_AUTH: 'true', WORKSPACES_ROOT: tmp, VAULT_MASTER_KEY: 'b'.repeat(64) });
    const a = await ensureUploadKey(cfg, 'proj1', 'Calcolatrice');
    expect(existsSync(a.keystorePath)).toBe(true);
    expect(a.alias).toBe('upload');
    expect(a.storePassword.length).toBeGreaterThan(20);
    const meta = JSON.parse(await readFile(path.join(path.dirname(a.keystorePath), 'key.json'), 'utf8'));
    expect(meta.encrypted).toBe(true);
    expect(JSON.stringify(meta)).not.toContain(a.storePassword);
    const b = await ensureUploadKey(cfg, 'proj1', 'Calcolatrice');
    expect(b.storePassword).toBe(a.storePassword);
  }, 60000);
});
