import { mkdir, mkdtemp, utimes, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { AutoTracker, needsFreshIpa, readAutoStatus } from './appstore_auto.js';

async function project(build: number, onApple: number) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'ember-auto-'));
  await mkdir(path.join(root, 'lib'), { recursive: true });
  await mkdir(path.join(root, 'store'), { recursive: true });
  await writeFile(path.join(root, 'pubspec.yaml'), `name: x\nversion: 1.0.0+${build}\n`);
  await writeFile(path.join(root, 'lib', 'main.dart'), 'void main() {}\n');
  if (onApple) await writeFile(path.join(root, 'store', 'appstore.json'), JSON.stringify({ lastBuildNumber: onApple }));
  return root;
}

async function ipa(root: string, when: Date) {
  const dir = path.join(root, 'build', 'ios', 'ipa');
  await mkdir(dir, { recursive: true });
  const f = path.join(dir, 'App.ipa');
  await writeFile(f, 'ipa');
  await utimes(f, when, when);
}

describe('does Publish need a new iPhone build?', () => {
  it('yes when there is no file yet', async () => {
    expect((await needsFreshIpa(await project(3, 0))).build).toBe(true);
  });

  it('no build and no upload when Apple already has this very file', async () => {
    const root = await project(12, 12);
    await ipa(root, new Date(Date.now() + 60_000));
    expect(await needsFreshIpa(root)).toMatchObject({ build: false, upload: false, reason: expect.stringMatching(/già questa build \(12\)/) });
  });

  it('yes when Apple has this build number but the code changed since', async () => {
    const root = await project(12, 12);
    await ipa(root, new Date(Date.now() - 3_600_000));
    expect(await needsFreshIpa(root)).toMatchObject({ build: true, upload: true, reason: expect.stringMatching(/già la build 12/) });
  });

  it('yes when the code changed after the file was made', async () => {
    const root = await project(13, 12);
    await ipa(root, new Date(Date.now() - 3_600_000));
    expect(await needsFreshIpa(root)).toMatchObject({ build: true, reason: expect.stringMatching(/codice è cambiato/) });
  });

  it('no when the file is newer than the code and Apple does not have it', async () => {
    const root = await project(13, 12);
    await ipa(root, new Date(Date.now() + 60_000));
    expect((await needsFreshIpa(root)).build).toBe(false);
  });
});

describe('the publish status', () => {
  it('keeps finished steps and survives a restart through the file', async () => {
    const root = await project(1, 0);
    const t = await AutoTracker.open(root);
    await t.start('building', 'Creo il file iPhone');
    await t.phase('publishing', 'Carico su Apple');
    await t.progress('Carico su Apple (screenshot)');
    await t.phase('waiting', 'Apple sta elaborando la build 2', { wait: { appId: 'A', versionId: 'V', buildNumber: 2, submit: true } });
    const saved = await readAutoStatus(root);
    expect(saved).toMatchObject({ phase: 'waiting', steps: ['Creo il file iPhone', 'Carico su Apple (screenshot)'], wait: { buildNumber: 2 } });
    expect((await AutoTracker.open(root)).status?.phase).toBe('waiting');
  });
});
