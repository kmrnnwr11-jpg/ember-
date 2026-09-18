import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { inspectProject } from './doctor.js';

async function project(files: Record<string, string>): Promise<string> {
  const root = await mkdtemp(path.join(os.tmpdir(), 'ember-doctor-'));
  for (const [rel, text] of Object.entries(files)) {
    const file = path.join(root, rel);
    await mkdir(path.dirname(file), { recursive: true });
    await writeFile(file, text);
  }
  return root;
}

const ids = (f: Awaited<ReturnType<typeof inspectProject>>) => f.findings.map((x) => x.id);

describe('inspectProject', () => {
  it('sees an app that cannot reach its Firebase project', async () => {
    const root = await project({
      'pubspec.yaml': 'dependencies:\n  firebase_core: ^4.1.1\n',
      'lib/config/app_config.dart': "static const String firebaseApiKey = '';\n",
    });
    expect(ids(await inspectProject(root))).toContain('firebase_keys');
    await rm(root, { recursive: true, force: true });
  });

  it('says nothing about Firebase once the keys are in place', async () => {
    const root = await project({
      'pubspec.yaml': 'dependencies:\n  firebase_core: ^4.1.1\n',
      'lib/config/app_config.dart': "static const String firebaseApiKey = 'AIzaSy-real';\n",
      'lib/firebase_options.dart': "projectId: 'demo-1234',\n",
    });
    const checked = await inspectProject(root);
    expect(ids(checked)).not.toContain('firebase_keys');
    expect(checked.firebaseProject).toBe('demo-1234');
    await rm(root, { recursive: true, force: true });
  });

  it('warns that published test ads earn nothing', async () => {
    const root = await project({
      'pubspec.yaml': 'dependencies:\n  google_mobile_ads: ^9.1.0\n',
      'lib/config/ads_config.dart': "static const String androidBannerId = 'ca-app-pub-3940256099942544/6300978111';\n",
    });
    expect(ids(await inspectProject(root))).toContain('ads_test_ids');
    await rm(root, { recursive: true, force: true });
  });

  it('notices an app that goes online without asking for the permission', async () => {
    const root = await project({
      'pubspec.yaml': 'dependencies:\n  http: ^1.2.0\n',
      'android/app/src/main/AndroidManifest.xml': '<manifest><application/></manifest>',
      'android/app/build.gradle.kts': '        applicationId = "dev.demo.app"\n',
    });
    const checked = await inspectProject(root);
    expect(ids(checked)).toContain('no_internet_permission');
    expect(checked.packageName).toBe('dev.demo.app');
    await rm(root, { recursive: true, force: true });
  });

  it('calls out rules that let every signed-in person read everyone else', async () => {
    const root = await project({
      'pubspec.yaml': 'dependencies:\n  firebase_core: ^4.1.1\n',
      'lib/config/app_config.dart': "static const String firebaseApiKey = 'AIzaSy-real';\n",
      'lib/firebase_options.dart': "projectId: 'demo-1234',\n",
      'firestore.rules': "rules_version = '2';\nservice cloud.firestore {\n  match /databases/{database}/documents {\n    match /{document=**} {\n      allow read, write: if request.auth != null;\n    }\n  }\n}\n",
    });
    const checked = await inspectProject(root);
    expect(ids(checked)).toContain('rules_open');
    expect(checked.findings.find((f) => f.id === 'rules_open')?.fixable).toBe(true);
    await rm(root, { recursive: true, force: true });
  });

  it('gives Ember the words to fix what only code can fix', async () => {
    const root = await project({
      'pubspec.yaml': 'dependencies:\n  google_mobile_ads: ^9.1.0\n',
      'lib/config/ads_config.dart': "static const String rewardedId = 'ca-app-pub-3940256099942544/5224354917';\n",
    });
    const rewarded = (await inspectProject(root)).findings.find((f) => f.id === 'ads_rewarded_unused');
    expect(rewarded?.ask).toMatch(/rewarded ad/i);
    expect(rewarded?.ask).toMatch(/never forced/i);
    await rm(root, { recursive: true, force: true });
  });

  it('warns that the preview window cannot do a Google sign-in', async () => {
    const root = await project({
      'pubspec.yaml': 'dependencies:\n  google_sign_in: ^7.2.0\n',
      'lib/services/auth_service.dart': 'final provider = GoogleAuthProvider();\n',
    });
    expect(ids(await inspectProject(root))).toContain('google_login_preview');
    await rm(root, { recursive: true, force: true });
  });

  it('has nothing to say about a plain, finished app', async () => {
    const root = await project({
      'pubspec.yaml': 'dependencies:\n  flutter:\n    sdk: flutter\n',
      'android/app/src/main/AndroidManifest.xml': '<manifest><uses-permission android:name="android.permission.INTERNET" /></manifest>',
    });
    expect(ids(await inspectProject(root))).toEqual([]);
    await rm(root, { recursive: true, force: true });
  });
});
