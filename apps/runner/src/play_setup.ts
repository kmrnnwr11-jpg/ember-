import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

/**
 * Hands-free Google Play connection on the Runner machine, using the Google
 * account already logged in to gcloud:
 *  1. a Google Cloud project with the Play Developer API enabled,
 *  2. a service account + JSON key (returned once, stored by the client),
 *  3. the service account invited to the Play Console developer account.
 */

const PLAY_SCOPES = [
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/cloud-platform',
  'https://www.googleapis.com/auth/androidpublisher',
].join(',');

/** Drive access is asked for on its own: Ember only ever touches files it created. */
const DRIVE_SCOPES = [PLAY_SCOPES, 'https://www.googleapis.com/auth/drive.file'].join(',');

export const INVITE_PERMISSIONS = [
  'CAN_SEE_ALL_APPS',
  'CAN_VIEW_NON_FINANCIAL_DATA_GLOBAL',
  'CAN_MANAGE_PUBLIC_APKS_GLOBAL',
  'CAN_MANAGE_TRACK_APKS_GLOBAL',
  'CAN_MANAGE_TRACK_USERS_GLOBAL',
  'CAN_MANAGE_PUBLIC_LISTING_GLOBAL',
  'CAN_MANAGE_DRAFT_APPS_GLOBAL',
  'CAN_MANAGE_ORDERS_GLOBAL',
  'CAN_MANAGE_APP_CONTENT_GLOBAL',
];

/** Runs gcloud with fixed arguments (never user text) and returns stdout. */
function gcloud(args: string[], timeoutMs = 120_000): Promise<{ code: number; out: string; err: string }> {
  return new Promise((resolve) => {
    const win = process.platform === 'win32';
    const quoted = win ? args.map((a) => (/\s/.test(a) ? `"${a}"` : a)) : args;
    const p = spawn(win ? 'gcloud.cmd' : 'gcloud', quoted, { windowsHide: true, shell: win });
    let out = '';
    let err = '';
    p.stdout?.on('data', (d) => (out += d));
    p.stderr?.on('data', (d) => (err += d));
    const t = setTimeout(() => p.kill(), timeoutMs);
    p.on('error', (e) => (clearTimeout(t), resolve({ code: -1, out, err: e.message })));
    p.on('close', (code) => (clearTimeout(t), resolve({ code: code ?? -1, out: out.trim(), err: err.trim() })));
  });
}

/**
 * Whether a program is on the PATH. Asking the shell is not enough on Windows: it
 * answers "not recognised" with an ordinary exit code, so a missing gcloud looked installed.
 */
export function onPath(name: string, env: NodeJS.ProcessEnv = process.env, platform: NodeJS.Platform = process.platform): boolean {
  const dirs = (env.PATH ?? env.Path ?? '').split(platform === 'win32' ? ';' : ':').filter(Boolean);
  const exts = platform === 'win32' ? ['', ...(env.PATHEXT ?? '.COM;.EXE;.BAT;.CMD').toLowerCase().split(';')] : [''];
  return dirs.some((d) => exts.some((e) => existsSync(path.join(d, name + e))));
}

/** Opens a window on this computer that signs gcloud in to Google (the owner finishes it in the browser). */
export async function openGcloudLogin(): Promise<'opened' | 'unsupported'> {
  const windows = process.platform === 'win32';
  if (!windows && process.platform !== 'darwin') return 'unsupported';
  const dir = path.join(os.tmpdir(), 'ember-login');
  await mkdir(dir, { recursive: true });
  const done = 'Fatto. Puoi chiudere questa finestra e tornare in Ember.';
  if (windows) {
    const file = path.join(dir, 'gcloud.cmd');
    await writeFile(file, ['@echo off', 'title Ember - accesso a Google', 'echo Accedi con il tuo account Google. Ember non vede la tua password.', 'echo.', 'call gcloud auth login', 'echo.', `echo ${done}`, 'pause >nul'].join('\r\n') + '\r\n');
    spawn('cmd.exe', ['/d', '/c', 'start', 'Ember', 'cmd.exe', '/k', file], { detached: true, stdio: 'ignore' }).unref();
  } else {
    const file = path.join(dir, 'gcloud.command');
    await writeFile(file, ['#!/bin/bash', 'echo "Accedi con il tuo account Google. Ember non vede la tua password."', 'gcloud auth login', `echo "${done}"`, 'read -n 1 -s'].join('\n') + '\n', { mode: 0o755 });
    spawn('open', [file], { detached: true, stdio: 'ignore' }).unref();
  }
  return 'opened';
}

export async function gcloudStatus(): Promise<{ installed: boolean; account: string | null }> {
  if (!onPath('gcloud')) return { installed: false, account: null };
  const r = await gcloud(['auth', 'list', '--filter=status:ACTIVE', '--format=value(account)'], 30_000);
  if (r.code === -1) return { installed: false, account: null };
  return { installed: true, account: r.out.split(/\r?\n/)[0] || null };
}

/** Project id: reuse the one created earlier on this machine, otherwise a new `ember-play-xxxxxx`. */
async function ensureProject(stateDir: string): Promise<string> {
  const statePath = path.join(stateDir, 'setup.json');
  const saved = existsSync(statePath) ? (JSON.parse(await readFile(statePath, 'utf8')) as { projectId?: string }) : {};
  if (saved.projectId) {
    const exists = await gcloud(['projects', 'describe', saved.projectId, '--format=value(projectId)']);
    if (exists.code === 0) return saved.projectId;
  }
  const projectId = `ember-play-${Math.random().toString(36).slice(2, 8)}`;
  const created = await gcloud(['projects', 'create', projectId, '--name=Ember Play'], 180_000);
  if (created.code !== 0) throw new Error(`Could not create the Google Cloud project: ${created.err.slice(-400)}`);
  await mkdir(stateDir, { recursive: true });
  await writeFile(statePath, JSON.stringify({ projectId, createdAt: new Date().toISOString() }));
  return projectId;
}

export async function createServiceAccountKey(stateDir: string): Promise<{ projectId: string; email: string; key: string; account: string }> {
  const status = await gcloudStatus();
  if (!status.installed) throw new Error('Google Cloud CLI (gcloud) is not installed on the Runner PC');
  if (!status.account) throw new Error('Log in to gcloud on the Runner PC first: run "gcloud auth login"');
  const projectId = await ensureProject(stateDir);
  const enable = await gcloud(['services', 'enable', 'androidpublisher.googleapis.com', `--project=${projectId}`], 300_000);
  if (enable.code !== 0) throw new Error(`Could not enable the Google Play Developer API: ${enable.err.slice(-400)}`);
  const email = `ember-publisher@${projectId}.iam.gserviceaccount.com`;
  const describe = await gcloud(['iam', 'service-accounts', 'describe', email, `--project=${projectId}`, '--format=value(email)']);
  if (describe.code !== 0) {
    const create = await gcloud(['iam', 'service-accounts', 'create', 'ember-publisher', '--display-name=Ember publisher', `--project=${projectId}`]);
    if (create.code !== 0) throw new Error(`Could not create the service account: ${create.err.slice(-400)}`);
  }
  const tmp = path.join(os.tmpdir(), `ember-sa-${Date.now()}.json`);
  try {
    // New accounts can take a few seconds to be usable for key creation.
    let key = { code: -1, out: '', err: '' };
    for (let i = 0; i < 4 && key.code !== 0; i++) {
      key = await gcloud(['iam', 'service-accounts', 'keys', 'create', tmp, `--iam-account=${email}`, `--project=${projectId}`]);
      if (key.code !== 0) await new Promise((r) => setTimeout(r, 5000));
    }
    if (key.code !== 0) throw new Error(`Could not create the key: ${key.err.slice(-400)}`);
    return { projectId, email, key: await readFile(tmp, 'utf8'), account: status.account };
  } finally {
    await rm(tmp, { force: true });
  }
}

/** Access token of the user's Google account with Play scope; opens the browser once to grant it. */
async function userPlayToken(): Promise<string> {
  let t = await gcloud(['auth', 'application-default', 'print-access-token']);
  const scoped = t.code === 0 && (await hasPlayScope(t.out));
  if (!scoped) {
    const login = await gcloud(['auth', 'application-default', 'login', `--scopes=${PLAY_SCOPES}`], 5 * 60_000);
    if (login.code !== 0) throw new Error('Google login was not completed in the browser');
    t = await gcloud(['auth', 'application-default', 'print-access-token']);
  }
  if (t.code !== 0 || !t.out) throw new Error('Could not get a Google access token');
  return t.out.split(/\r?\n/).pop()!;
}

/** Access token allowed to write to the user's Drive; asks for the permission once. */
export async function driveToken(): Promise<string> {
  let t = await gcloud(['auth', 'application-default', 'print-access-token']);
  const scoped = t.code === 0 && ((await tokenInfo(t.out)).scope ?? '').includes('drive.file');
  if (!scoped) {
    const login = await gcloud(['auth', 'application-default', 'login', `--scopes=${DRIVE_SCOPES}`], 5 * 60_000);
    if (login.code !== 0) throw new Error('Google login was not completed in the browser, so Ember cannot save to your Drive');
    t = await gcloud(['auth', 'application-default', 'print-access-token']);
  }
  if (t.code !== 0 || !t.out) throw new Error('Could not get a Google access token');
  return t.out.split(/\r?\n/).pop()!;
}

async function tokenInfo(token: string): Promise<{ scope?: string; email?: string }> {
  try {
    const res = await fetch(`https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(token.split(/\r?\n/).pop()!)}`);
    return (await res.json()) as { scope?: string; email?: string };
  } catch {
    return {};
  }
}

async function hasPlayScope(token: string): Promise<boolean> {
  return ((await tokenInfo(token)).scope ?? '').includes('androidpublisher');
}

/** Google Cloud project used for API quota with personal credentials. */
export async function quotaProject(stateDir: string): Promise<string | null> {
  try {
    const saved = JSON.parse(await readFile(path.join(stateDir, 'setup.json'), 'utf8')) as { projectId?: string };
    return saved.projectId ?? null;
  } catch {
    return null;
  }
}

/** Invites the service account into the Play Console developer account (idempotent). */
export async function invitePlayUser(
  developerId: string,
  serviceAccountEmail: string,
  fetchImpl: typeof fetch = fetch,
  stateDir?: string,
): Promise<{ invited: boolean; alreadyMember: boolean }> {
  const token = await userPlayToken();
  // Personal credentials need a billing/quota project for the Play API.
  const project = stateDir ? await quotaProject(stateDir) : null;
  if (project) {
    await gcloud(['auth', 'application-default', 'set-quota-project', project], 60_000);
    // The browser login can be a different Google account than the one that owns the project.
    const email = (await tokenInfo(token)).email;
    if (email) {
      await gcloud(
        ['projects', 'add-iam-policy-binding', project, `--member=user:${email}`, '--role=roles/serviceusage.serviceUsageConsumer', '--condition=None', '--quiet'],
        120_000,
      );
    }
  }
  const res = await fetchImpl(`https://androidpublisher.googleapis.com/androidpublisher/v3/developers/${developerId}/users`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
      ...(project ? { 'x-goog-user-project': project } : {}),
    },
    body: JSON.stringify({ email: serviceAccountEmail, developerAccountPermissions: INVITE_PERMISSIONS }),
  });
  if (res.ok) return { invited: true, alreadyMember: false };
  const text = await res.text();
  if (res.status === 409 || /already/i.test(text)) return { invited: true, alreadyMember: true };
  let message = text;
  try {
    message = (JSON.parse(text) as { error?: { message?: string } }).error?.message ?? text;
  } catch {
    // raw text
  }
  throw new Error(`Play Console did not accept the invite (${res.status}): ${message.slice(0, 400)}`);
}

/** Extracts the developer account id from any Play Console URL. */
export function developerIdFromUrl(url: string): string | null {
  return /developers\/(\d{5,25})/.exec(url)?.[1] ?? null;
}

/** Store graphics produced by Ember for a project, when present. */
export async function storeImages(projectRoot: string): Promise<{ icon?: string; featureGraphic?: string; phoneScreenshots?: string[] }> {
  const store = path.join(projectRoot, 'store');
  const icon = path.join(store, 'play_icon_512.png');
  const feature = path.join(store, 'feature_graphic.png');
  const shotsDir = path.join(store, 'screenshots');
  const shots = (await readdir(shotsDir).catch(() => [] as string[]))
    .filter((f) => /^phone_\d+\.png$/.test(f))
    .sort((a, b) => Number(/\d+/.exec(a)![0]) - Number(/\d+/.exec(b)![0]))
    .map((f) => path.join(shotsDir, f));
  return {
    ...(existsSync(icon) ? { icon } : {}),
    ...(existsSync(feature) ? { featureGraphic: feature } : {}),
    ...(shots.length >= 2 ? { phoneScreenshots: shots } : {}),
  };
}
