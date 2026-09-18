import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import puppeteer from 'puppeteer-core';
import { findBrowser } from './screenshots.js';

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
  /**
   * What to ask the engine that wrote the app, when the fix is a change to the
   * code rather than a setting. The user presses one button; this is the
   * request that gets sent.
   */
  ask?: string;
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
        detail: 'The app can show ads that pay the user back with something: coins, a filter, an extra life. That format earns the most.',
        fixable: false,
        ask:
          'Use the rewarded ad that is already configured: put it where the user gains something by watching it (coins, an extra try, a locked feature), '
          + 'always as a choice with a clear button, never forced and never on first launch. Give the reward only when the ad reports it was watched.',
      });
    }
  }

  // Rules that let any signed-in person read everything are fine while building
  // and a data leak once the app is public: every user can read every other user.
  const rules = await read(root, 'firestore.rules');
  if (/allow read, write: if request\.auth != null;[\s\S]*document=\*\*/.test(rules) || /\{document=\*\*\}[\s\S]*allow read, write: if request\.auth != null;/.test(rules)) {
    findings.push({
      id: 'rules_open',
      title: 'Anyone signed in can read everyone else’s data',
      detail: 'The database rules are wide open to any signed-in user. Fine while building, a leak once the app is public.',
      fixable: true,
    });
  }

  // Google refuses its own sign-in inside an embedded browser window, so the
  // preview shows a black screen after login while the app is perfectly fine.
  if ((await grepLib(root, 'GoogleAuthProvider')).length > 0 || /google_sign_in:/.test(pubspec)) {
    findings.push({
      id: 'google_login_preview',
      title: 'Google sign-in does not work inside the preview window',
      detail: 'Google blocks its sign-in in embedded windows. Press "Open in browser" to try it, or install the app on a phone: there it works.',
      fixable: false,
    });
  }

  if (usesFirebase && !existsSync(path.join(root, 'android', 'app', 'google-services.json'))) {
    findings.push({
      id: 'no_google_services',
      title: 'The Android app has no google-services.json',
      detail: 'Notifications and Google sign-in can fail once installed on a phone, while the preview works.',
      fixable: false,
      ask: 'Add the google-services.json for this Android app from the Firebase project, and wire the Gradle plugin that reads it.',
    });
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

const IDENTITY = 'https://identitytoolkit.googleapis.com/admin/v2/projects';

/** The addresses Firebase accepts a sign-in from. Ember's preview runs on 127.0.0.1. */
const NEEDED_DOMAINS = ['localhost', '127.0.0.1'];

async function googleToken(): Promise<string | null> {
  const t = await run('gcloud', ['auth', 'print-access-token'], undefined, 60_000);
  const token = t.out.trim().split(/\r?\n/).pop() ?? '';
  return t.code === 0 && token.length > 50 ? token : null;
}

async function authConfig(project: string, fetchImpl: typeof fetch): Promise<{ token: string; config: Record<string, unknown> } | null> {
  const token = await googleToken();
  if (!token) return null;
  const res = await fetchImpl(`${IDENTITY}/${project}/config`, {
    headers: { authorization: `Bearer ${token}`, 'x-goog-user-project': project },
  }).catch(() => null);
  if (!res?.ok) return null;
  return { token, config: (await res.json()) as Record<string, unknown> };
}

/** What Google itself says about the project: a database that does not exist is a black screen. */
export async function inspectCloud(firebaseProject: string | null, fetchImpl: typeof fetch = fetch): Promise<Finding[]> {
  if (!firebaseProject) return [];
  const findings: Finding[] = [];

  const auth = await authConfig(firebaseProject, fetchImpl);
  const domains = (auth?.config.authorizedDomains as string[] | undefined) ?? null;
  if (domains && NEEDED_DOMAINS.some((d) => !domains.includes(d))) {
    findings.push({
      id: 'auth_domains',
      title: 'Google sign-in is refused where the app is being tested',
      detail: 'Firebase only accepts a sign-in from addresses it knows, and the preview address is not one of them: the user signs in and the screen stays black.',
      fixable: true,
    });
  }
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

/**
 * Opens the built app in a real browser and reports what it complains about.
 *
 * Reading the files only finds what is missing; a running app is the only place
 * where a wrong setting shows itself. The app keeps running: nothing is clicked.
 */
export async function inspectRunning(previewUrl: string | null, launch = puppeteer.launch): Promise<Finding[]> {
  if (!previewUrl) return [];
  const executablePath = await findBrowser();
  if (!executablePath) return [];
  const problems: string[] = [];
  let browser;
  try {
    browser = await launch({ executablePath, headless: true, args: ['--no-sandbox'] });
    const page = await browser.newPage();
    page.on('pageerror', (e) => {
      problems.push((e as Error).message);
    });
    page.on('console', (m) => {
      if (m.type() === 'error') problems.push(m.text());
    });
    await page.goto(previewUrl, { waitUntil: 'networkidle2', timeout: 90_000 });
    await page.evaluate(() => new Promise((r) => setTimeout(r, 8000)));
  } catch (e) {
    problems.push((e as Error).message);
  } finally {
    await browser?.close().catch(() => {});
  }
  const real = problems.filter((p) => p && !/favicon|service worker|DevTools/i.test(p)).slice(0, 3);
  if (real.length === 0) return [];
  const text = real.join(' · ').slice(0, 300);
  return [
    {
      id: 'runtime_errors',
      title: 'The app reports errors while running',
      detail: text,
      fixable: false,
      ask: `The app prints these errors while running, and the user sees a broken screen. Find the cause and fix it:\n${text}`,
    },
  ];
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
  if (id === 'auth_domains') {
    if (!firebaseProject) throw new Error('This app has no Firebase project yet');
    const auth = await authConfig(firebaseProject, fetch);
    if (!auth) throw new Error('Could not read the Firebase sign-in settings');
    const current = (auth.config.authorizedDomains as string[] | undefined) ?? [];
    const authorizedDomains = [...new Set([...current, ...NEEDED_DOMAINS])];
    const res = await fetch(`${IDENTITY}/${firebaseProject}/config?updateMask=authorizedDomains`, {
      method: 'PATCH',
      headers: { authorization: `Bearer ${auth.token}`, 'x-goog-user-project': firebaseProject, 'content-type': 'application/json' },
      body: JSON.stringify({ authorizedDomains }),
    });
    if (!res.ok) throw new Error(`Google refused the change: ${(await res.text()).slice(0, 200)}`);
    return 'Sign-in now accepted from the address the preview runs on.';
  }
  if (id === 'rules_open') {
    if (!firebaseProject) throw new Error('This app has no Firebase project yet');
    await writeFile(path.join(projectRoot, 'firestore.rules'), OWNER_ONLY_RULES);
    const rules = await run('firebase', ['deploy', '--only', 'firestore:rules', '--project', firebaseProject], projectRoot, 300_000);
    if (rules.code !== 0) throw new Error(`Google refused the rules: ${rules.out.slice(-300)}`);
    return 'Each person can now read and write only their own data.';
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
