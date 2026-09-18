import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

/**
 * What is missing for an app to actually work, checked the way a person would:
 * read the project, then ask Google what it really has. Every finding says what
 * is wrong, what it costs the user, and whether Ember can fix it alone.
 */

export interface Finding {
  id: string;
  /** What the user sees as a title. */
  title: string;
  /** Why it matters, in plain words. */
  detail: string;
  /** true when Ember can put it right without asking anything else. */
  fixable: boolean;
}

export interface Checked {
  /** The Firebase project the app points at, when it has one. */
  firebaseProject: string | null;
  packageName: string | null;
  findings: Finding[];
}

const read = (root: string, ...rel: string[]) => readFile(path.join(root, ...rel), 'utf8').catch(() => '');

/** Google's public test ids: fine while building, money lost once published. */
const TEST_AD_PUBLISHER = 'ca-app-pub-3940256099942544';

/** Everything that can be known from the project's own files. */
export async function inspectProject(root: string): Promise<Checked> {
  const findings: Finding[] = [];
  const pubspec = await read(root, 'pubspec.yaml');
  const config = await read(root, 'lib', 'config', 'app_config.dart');
  const options = await read(root, 'lib', 'firebase_options.dart');
  const manifest = await read(root, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
  const packageName = /applicationId\s*=\s*"([^"]+)"/.exec(await read(root, 'android', 'app', 'build.gradle.kts'))?.[1] ?? null;

  const usesFirebase = /^\s+firebase_core:/m.test(pubspec);
  const firebaseProject = /projectId:\s*'([^']+)'/.exec(options)?.[1] ?? /firebaseProjectId = '([^']+)'/.exec(config)?.[1] ?? null;

  if (usesFirebase) {
    const emptyKey = /static const String firebase\w*ApiKey = ''/.test(config);
    if (!firebaseProject || emptyKey) {
      findings.push({
        id: 'firebase_keys',
        title: 'Firebase keys missing',
        detail: 'Sign-in, saved data and notifications cannot work: the app has no project to talk to.',
        fixable: true,
      });
    }
  }

  const ads = await read(root, 'lib', 'config', 'ads_config.dart');
  if (ads) {
    if (ads.includes(TEST_AD_PUBLISHER)) {
      findings.push({
        id: 'ads_test_ids',
        title: 'Ads still on Google test ids',
        detail: 'Published like this the app shows fake ads and earns nothing. Paste your own AdMob ids in the AdMob card.',
        fixable: false,
      });
    }
    const usesRewarded = (await grepLib(root, 'RewardedAd')).length > 0;
    if (!usesRewarded && /rewarded/i.test(ads)) {
      findings.push({
        id: 'ads_rewarded_unused',
        title: 'Rewarded ads set up but never shown',
        detail: 'The app can show ads that pay the user with something (coins, a filter). That format earns the most: ask Ember to use it.',
        fixable: false,
      });
    }
  }

  if (manifest && !/android\.permission\.INTERNET/.test(manifest) && /http|firebase|dio/i.test(pubspec)) {
    findings.push({
      id: 'no_internet_permission',
      title: 'The app has no permission to reach the internet',
      detail: 'Anything online fails on a real phone, while it works in the preview.',
      fixable: true,
    });
  }

  return { firebaseProject, packageName, findings };
}

/** Runs a command and gives back what it printed, without ever throwing. */
function run(bin: string, args: string[], cwd?: string, timeoutMs = 180_000): Promise<{ code: number; out: string }> {
  return new Promise((resolve) => {
    const win = process.platform === 'win32';
    const p = spawn(win ? `${bin}.cmd` : bin, args, { cwd, windowsHide: true, shell: win });
    let out = '';
    p.stdout?.on('data', (d) => (out += d));
    p.stderr?.on('data', (d) => (out += d));
    const t = setTimeout(() => p.kill(), timeoutMs);
    p.on('error', (e) => (clearTimeout(t), resolve({ code: -1, out: e.message })));
    p.on('close', (code) => (clearTimeout(t), resolve({ code: code ?? -1, out })));
  });
}

/** What Google itself says about the project: a database that does not exist is a black screen. */
export async function inspectCloud(firebaseProject: string | null): Promise<Finding[]> {
  if (!firebaseProject) return [];
  const findings: Finding[] = [];
  const db = await run('gcloud', ['firestore', 'databases', 'list', `--project=${firebaseProject}`, '--format=value(name)'], undefined, 90_000);
  if (db.code !== 0 || !db.out.trim()) {
    findings.push({
      id: 'no_firestore',
      title: 'The database does not exist yet',
      detail: 'The app signs the user in, then asks for their data and waits forever: that is the black screen after login.',
      fixable: true,
    });
  }
  return findings;
}

/** Creates what is missing. Returns what was done, in the user's words. */
export async function fix(id: string, input: { projectRoot: string; firebaseProject: string | null }): Promise<string> {
  const { firebaseProject, projectRoot } = input;
  if (id === 'no_firestore') {
    if (!firebaseProject) throw new Error('This app has no Firebase project yet');
    await run('gcloud', ['services', 'enable', 'firestore.googleapis.com', `--project=${firebaseProject}`], undefined, 300_000);
    const created = await run('gcloud', ['firestore', 'databases', 'create', '--location=eur3', `--project=${firebaseProject}`], undefined, 300_000);
    if (created.code !== 0 && !/already exists/i.test(created.out)) throw new Error(`Could not create the database: ${created.out.slice(-300)}`);
    await writeFile(path.join(projectRoot, 'firestore.rules'), OWNER_ONLY_RULES);
    if (!existsSync(path.join(projectRoot, 'firebase.json'))) {
      await writeFile(path.join(projectRoot, 'firebase.json'), `${JSON.stringify({ firestore: { rules: 'firestore.rules' } }, null, 2)}\n`);
    }
    const rules = await run('firebase', ['deploy', '--only', 'firestore:rules', '--project', firebaseProject], projectRoot, 300_000);
    if (rules.code !== 0) throw new Error(`Database created, but the rules were refused: ${rules.out.slice(-300)}`);
    return 'Database created, with rules that let each person read and write only their own data.';
  }
  if (id === 'no_internet_permission') {
    const file = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
    const manifest = await readFile(file, 'utf8');
    await writeFile(file, manifest.replace(/<manifest([^>]*)>/, '<manifest$1>\n    <uses-permission android:name="android.permission.INTERNET" />'));
    return 'Internet permission added to the Android app.';
  }
  throw new Error(`Ember cannot fix "${id}" on its own`);
}

/** Each signed-in person owns their own document, and nothing else is readable. */
const OWNER_ONLY_RULES = `rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /{sub=**} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
`;

/** Files under lib/ that contain a word. */
async function grepLib(root: string, needle: string): Promise<string[]> {
  const out: string[] = [];
  const walk = async (dir: string) => {
    for (const entry of await readdir(dir, { withFileTypes: true }).catch(() => [])) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) await walk(full);
      else if (entry.name.endsWith('.dart') && (await readFile(full, 'utf8').catch(() => '')).includes(needle)) out.push(full);
    }
  };
  if (existsSync(path.join(root, 'lib'))) await walk(path.join(root, 'lib'));
  return out;
}
