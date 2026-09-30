import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

/**
 * "Save on GitHub": the app's source, pushed to a repository the user owns.
 * The token is used for this one push and never written into the project.
 */

const API = 'https://api.github.com';

/** Files that must never leave this machine, plus the usual build noise. */
const GITIGNORE = [
  '# Ember',
  'build/',
  '.dart_tool/',
  '.flutter-plugins-dependencies',
  'android/local.properties',
  'android/key.properties',
  '*.jks',
  '*.keystore',
  'google-services.json',
  '.env',
  '',
].join('\n');

export class GitHubError extends Error {
  constructor(
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

function git(args: string[], cwd: string, timeoutMs = 180_000): Promise<{ code: number; out: string; err: string }> {
  return new Promise((resolve) => {
    const p = spawn('git', args, { cwd, windowsHide: true });
    let out = '';
    let err = '';
    p.stdout?.on('data', (d) => (out += d));
    p.stderr?.on('data', (d) => (err += d));
    const t = setTimeout(() => p.kill(), timeoutMs);
    p.on('error', (e) => (clearTimeout(t), resolve({ code: -1, out, err: e.message })));
    p.on('close', (code) => (clearTimeout(t), resolve({ code: code ?? -1, out: out.trim(), err: err.trim() })));
  });
}

async function api(token: string, method: string, url: string, body: unknown, fetchImpl: typeof fetch): Promise<Record<string, unknown>> {
  const res = await fetchImpl(`${API}${url}`, {
    method,
    headers: {
      authorization: `Bearer ${token}`,
      accept: 'application/vnd.github+json',
      'user-agent': 'ember-app-maker',
      ...(body !== undefined ? { 'content-type': 'application/json' } : {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  const json = (text ? JSON.parse(text) : {}) as Record<string, unknown>;
  if (res.ok) return json;
  if (res.status === 401) throw new GitHubError('bad_token', 'GitHub did not accept the token. Create a new one with "repo" permission and paste it again.');
  if (res.status === 404) throw new GitHubError('not_found', `GitHub: not found (${url})`);
  throw new GitHubError('github_error', `GitHub refused: ${String(json.message ?? text).slice(0, 300)}`);
}

/** The upload was cut by the network, not refused by GitHub: worth another try. */
export function isDroppedConnection(output: string): boolean {
  return /RPC failed|curl \d+|remote end hung up|unexpected disconnect|Connection (was )?(aborted|reset)|early EOF|timed out/i.test(output);
}

/** A repository name GitHub accepts, from the app's own name. */
export function repoName(appName: string): string {
  const slug = appName
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 90);
  return slug || 'ember-app';
}

/** Marks a repository as an Ember app, so any computer can find it again. */
export const EMBER_TOPIC = 'ember-app';
const MARKER = path.join('.ember', 'app.json');

export interface SaveInput {
  projectRoot: string;
  token: string;
  appName: string;
  /** Existing repository to push to; otherwise one is created from the app name. */
  repo?: string;
  private?: boolean;
  message?: string;
  /** Test seam: runs the git commands. */
  runGit?: (args: string[], cwd: string) => Promise<{ code: number; out: string; err: string }>;
}

/** Creates the repository if needed and pushes everything. Returns the repo page. */
export async function saveToGitHub(input: SaveInput, fetchImpl: typeof fetch = fetch): Promise<{ url: string; repo: string; owner: string; created: boolean; pushed: boolean }> {
  const run = input.runGit ?? ((args: string[], cwd: string) => git(args, cwd));
  const me = (await api(input.token, 'GET', '/user', undefined, fetchImpl)) as { login?: string };
  const owner = String(me.login ?? '');
  if (!owner) throw new GitHubError('bad_token', 'GitHub did not say who the token belongs to');
  const repo = input.repo?.trim() || repoName(input.appName);

  let created = false;
  try {
    await api(input.token, 'GET', `/repos/${owner}/${repo}`, undefined, fetchImpl);
  } catch (e) {
    if (!(e instanceof GitHubError) || e.code !== 'not_found') throw e;
    await api(input.token, 'POST', '/user/repos', { name: repo, private: input.private ?? true, auto_init: false }, fetchImpl);
    created = true;
  }

  const root = input.projectRoot;
  // What this repository is, so Ember on another computer recognises the app.
  await mkdir(path.join(root, '.ember'), { recursive: true });
  await writeFile(path.join(root, MARKER), `${JSON.stringify({ app: input.appName, folder: path.basename(root), savedAt: new Date().toISOString() }, null, 2)}\n`);
  await api(input.token, 'PUT', `/repos/${owner}/${repo}/topics`, { names: [EMBER_TOPIC] }, fetchImpl).catch(() => ({}));

  const ignore = path.join(root, '.gitignore');
  if (!existsSync(ignore)) await writeFile(ignore, GITIGNORE);
  else {
    const current = await readFile(ignore, 'utf8');
    if (!/\*\.jks/.test(current)) await writeFile(ignore, `${current.replace(/\s*$/, '')}\n${GITIGNORE}`);
  }

  if (!existsSync(path.join(root, '.git'))) {
    const init = await run(['init', '-b', 'main'], root);
    if (init.code !== 0) throw new GitHubError('git_failed', `Could not start the repository: ${init.err.slice(-300)}`);
  }
  // Identity only for this repository, so the user's own git setup is untouched.
  await run(['config', 'user.name', owner], root);
  await run(['config', 'user.email', `${owner}@users.noreply.github.com`], root);
  await run(['add', '-A'], root);
  const commit = await run(['commit', '-m', input.message?.trim() || 'Update from Ember'], root);
  const nothingToCommit = commit.code !== 0 && /nothing to commit/i.test(`${commit.out}${commit.err}`);
  if (commit.code !== 0 && !nothingToCommit) throw new GitHubError('git_failed', `Could not save the changes: ${(commit.err || commit.out).slice(-300)}`);

  // The token travels in this one command and is never stored as a remote.
  const url = `https://x-access-token:${input.token}@github.com/${owner}/${repo}.git`;
  // Videos and images go up in one large request, and on Windows git's HTTP/2
  // connection is often cut halfway ("curl 55 Send failure: Connection was
  // aborted"). HTTP/1.1 with a large buffer carries it; a dropped connection
  // is tried again before giving up.
  await run(['config', 'http.version', 'HTTP/1.1'], root);
  await run(['config', 'http.postBuffer', '524288000'], root);
  let push = await run(['push', url, 'HEAD:main', '--force'], root);
  for (let attempt = 1; push.code !== 0 && attempt < 3 && isDroppedConnection(`${push.err}${push.out}`); attempt++) {
    await new Promise((r) => setTimeout(r, 2000 * attempt));
    push = await run(['push', url, 'HEAD:main', '--force'], root);
  }
  if (push.code !== 0) {
    const reason = (push.err || push.out).replace(input.token, '***').slice(-300);
    throw new GitHubError('push_failed', `GitHub refused the upload: ${reason}`);
  }
  return { url: `https://github.com/${owner}/${repo}`, repo, owner, created, pushed: !nothingToCommit || push.code === 0 };
}

export interface RemoteApp {
  repo: string;
  owner: string;
  app: string;
  url: string;
  updatedAt: string;
  private: boolean;
}

/**
 * The apps this account saved from Ember, newest first: every repository
 * carrying the Ember topic, wherever it was saved from.
 */
export async function listEmberApps(token: string, fetchImpl: typeof fetch = fetch): Promise<RemoteApp[]> {
  const me = (await api(token, 'GET', '/user', undefined, fetchImpl)) as { login?: string };
  const owner = String(me.login ?? '');
  const rows = (await api(token, 'GET', `/user/repos?per_page=100&sort=updated&affiliation=owner`, undefined, fetchImpl)) as unknown as Array<{
    name: string;
    owner?: { login?: string };
    topics?: string[];
    description?: string;
    html_url?: string;
    updated_at?: string;
    private?: boolean;
  }>;
  return (Array.isArray(rows) ? rows : [])
    .filter((r) => (r.topics ?? []).includes(EMBER_TOPIC))
    .map((r) => ({
      repo: r.name,
      owner: r.owner?.login ?? owner,
      app: r.name.replace(/-/g, ' '),
      url: r.html_url ?? `https://github.com/${owner}/${r.name}`,
      updatedAt: r.updated_at ?? '',
      private: r.private ?? true,
    }));
}

export interface RestoreInput {
  token: string;
  repo: string;
  owner?: string;
  /** Folder to create the app in; it must not exist yet. */
  dest: string;
  runGit?: (args: string[], cwd: string) => Promise<{ code: number; out: string; err: string }>;
}

/** Brings one saved app back onto this computer. Returns its name on the store. */
export async function restoreFromGitHub(input: RestoreInput, fetchImpl: typeof fetch = fetch): Promise<{ app: string; dest: string }> {
  const run = input.runGit ?? ((args: string[], cwd: string) => git(args, cwd));
  let owner = input.owner?.trim() ?? '';
  if (!owner) {
    const me = (await api(input.token, 'GET', '/user', undefined, fetchImpl)) as { login?: string };
    owner = String(me.login ?? '');
  }
  if (existsSync(input.dest)) throw new GitHubError('exists', `An app already exists in ${path.basename(input.dest)}`);
  await mkdir(path.dirname(input.dest), { recursive: true });

  const url = `https://x-access-token:${input.token}@github.com/${owner}/${input.repo}.git`;
  const clone = await run(['clone', '--depth', '1', url, input.dest], path.dirname(input.dest));
  if (clone.code !== 0) {
    const reason = (clone.err || clone.out).replace(input.token, '***').slice(-300);
    throw new GitHubError('clone_failed', `GitHub could not send the app back: ${reason}`);
  }
  // The clone keeps the token in the remote: replace it with the plain address.
  await run(['remote', 'set-url', 'origin', `https://github.com/${owner}/${input.repo}.git`], input.dest);

  const marker = await readFile(path.join(input.dest, MARKER), 'utf8').catch(() => '');
  const app = `${(JSON.parse(marker || 'null') as { app?: string } | null)?.app ?? ''}`.trim() || input.repo.replace(/-/g, ' ');
  return { app, dest: input.dest };
}
