import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { claimBundleId, claimPackageName, fillPolicy, packageName } from './publish_prep.js';

async function project(applicationId: string, withFirebase = false): Promise<string> {
  const root = await mkdtemp(path.join(os.tmpdir(), 'ember-prep-'));
  await mkdir(path.join(root, 'android', 'app'), { recursive: true });
  await writeFile(path.join(root, 'android', 'app', 'build.gradle.kts'), `android {\n    defaultConfig {\n        applicationId = "${applicationId}"\n    }\n}\n`);
  if (withFirebase) await writeFile(path.join(root, 'android', 'app', 'google-services.json'), '{}');
  return root;
}

const idOf = async (root: string) => /applicationId = "([^"]+)"/.exec(await readFile(path.join(root, 'android', 'app', 'build.gradle.kts'), 'utf8'))?.[1];

describe('package name', () => {
  it('comes from the app name, the way a store expects it', () => {
    expect(packageName('Doodle Dino: Kids Coloring', 'com.dreamcodestudio')).toBe('com.dreamcodestudio.doodledino');
    expect(packageName('Città Perù', 'com.studio.')).toBe('com.studio.cittaperu');
    // A package part cannot start with a digit.
    expect(packageName('2048 Blocks', 'com.studio')).toBe('com.studio.app2048blocks');
  });

  it('replaces the placeholder before the first upload', async () => {
    const root = await project('dev.fluttercursor.app.app_uguale_questa_119');
    expect(await claimPackageName(root, { appName: 'Doodle Dino: Kids Coloring', prefix: 'com.dreamcodestudio', alreadyPublished: false })).toBe('com.dreamcodestudio.doodledino');
    expect(await idOf(root)).toBe('com.dreamcodestudio.doodledino');
    await rm(root, { recursive: true, force: true });
  });

  it('never touches an app that is already on Play, or wired to Firebase', async () => {
    const published = await project('dev.fluttercursor.app.old');
    expect(await claimPackageName(published, { appName: 'Demo', prefix: 'com.x', alreadyPublished: true })).toBeNull();
    expect(await idOf(published)).toBe('dev.fluttercursor.app.old');

    const firebase = await project('dev.fluttercursor.app.fire', true);
    expect(await claimPackageName(firebase, { appName: 'Demo', prefix: 'com.x', alreadyPublished: false })).toBeNull();

    // A name the user already chose is theirs to keep.
    const chosen = await project('com.mine.app');
    expect(await claimPackageName(chosen, { appName: 'Demo', prefix: 'com.x', alreadyPublished: false })).toBeNull();
    for (const r of [published, firebase, chosen]) await rm(r, { recursive: true, force: true });
  });
});

describe('iPhone bundle id', () => {
  async function iosProject(current: string): Promise<string> {
    const root = await mkdtemp(path.join(os.tmpdir(), 'ember-ios-'));
    await mkdir(path.join(root, 'ios', 'Runner.xcodeproj'), { recursive: true });
    await writeFile(
      path.join(root, 'ios', 'Runner.xcodeproj', 'project.pbxproj'),
      `\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = ${current};\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = ${current};\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = ${current}.RunnerTests;\n`,
    );
    return root;
  }

  it('gives the iPhone app the same name as the Android one, tests included', async () => {
    const root = await iosProject('com.example.demo');
    expect(await claimBundleId(root, 'com.dreamcodestudio.doodledino')).toBe('com.dreamcodestudio.doodledino');
    const pbx = await readFile(path.join(root, 'ios', 'Runner.xcodeproj', 'project.pbxproj'), 'utf8');
    expect(pbx.match(/PRODUCT_BUNDLE_IDENTIFIER = com\.dreamcodestudio\.doodledino;/g)).toHaveLength(2);
    expect(pbx).toContain('com.dreamcodestudio.doodledino.RunnerTests;');
    await rm(root, { recursive: true, force: true });
  });

  it('never renames an app Apple already has', async () => {
    const root = await iosProject('com.mine.app');
    expect(await claimBundleId(root, 'com.other.app', true)).toBeNull();
    expect(await readFile(path.join(root, 'ios', 'Runner.xcodeproj', 'project.pbxproj'), 'utf8')).toContain('com.mine.app;');
    await rm(root, { recursive: true, force: true });
  });
});

describe('privacy policy', () => {
  it('fills the blanks an AI leaves, which a reviewer would refuse', () => {
    const filled = fillPolicy('<!-- App -->\n## Titolare\n[NOME TITOLARE]\nEmail: [EMAIL]\n', { name: 'DreamcodeStudio', email: 'me@x.it' });
    expect(filled).toContain('DreamcodeStudio');
    expect(filled).toContain('me@x.it');
    expect(filled).not.toMatch(/\[|<!--/);
  });
});
