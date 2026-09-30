import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { EMBER_TOPIC, GitHubError, listEmberApps, repoName, restoreFromGitHub, saveToGitHub } from './github.js';

/** GitHub, reduced to the three calls the save needs. */
function fakeGitHub(opts: { repoExists: boolean }) {
  const calls: Array<{ url: string; method: string; body: string }> = [];
  const impl = (async (url: string | URL, init: RequestInit = {}) => {
    const u = String(url);
    calls.push({ url: u, method: init.method ?? 'GET', body: typeof init.body === 'string' ? init.body : '' });
    if (u.endsWith('/user')) return new Response(JSON.stringify({ login: 'adnan' }), { status: 200 });
    if (u.includes('/repos/') && !opts.repoExists) return new Response(JSON.stringify({ message: 'Not Found' }), { status: 404 });
    return new Response(JSON.stringify({ id: 1 }), { status: 200 });
  }) as unknown as typeof fetch;
  return { impl, calls };
}

function fakeGit() {
  const ran: string[][] = [];
  const run = async (args: string[]) => (ran.push(args), { code: 0, out: '', err: '' });
  return { ran, run };
}

describe('saveToGitHub', () => {
  it('turns an app name into a repository name GitHub accepts', () => {
    expect(repoName('Beauty Camera & Photo Editor')).toBe('beauty-camera-photo-editor');
    expect(repoName('Città Perù!')).toBe('citta-peru');
    expect(repoName('***')).toBe('ember-app');
  });

  it('creates the repository when it does not exist and pushes the app', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'ember-gh-'));
    const gh = fakeGitHub({ repoExists: false });
    const git = fakeGit();
    const out = await saveToGitHub({ projectRoot: root, token: 'ghp_secret', appName: 'Beauty Camera', runGit: git.run }, gh.impl);

    expect(out).toMatchObject({ url: 'https://github.com/adnan/beauty-camera', owner: 'adnan', created: true });
    expect(gh.calls.filter((c) => c.method === 'POST')[0]!.body).toContain('"private":true');
    expect(git.ran[0]).toEqual(['init', '-b', 'main']);
    expect(git.ran.at(-1)![0]).toBe('push');
    // The token is what authenticates the push, and must never end up in a stored remote.
    expect(git.ran.at(-1)![1]).toContain('ghp_secret');
    expect(git.ran.some((a) => a[0] === 'remote')).toBe(false);
    await rm(root, { recursive: true, force: true });
  });

  it('never uploads the signing key or build output', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'ember-gh-'));
    const git = fakeGit();
    await saveToGitHub({ projectRoot: root, token: 't'.repeat(25), appName: 'Demo', runGit: git.run }, fakeGitHub({ repoExists: true }).impl);
    const ignore = await readFile(path.join(root, '.gitignore'), 'utf8');
    for (const secret of ['*.jks', 'android/key.properties', 'google-services.json', 'build/']) expect(ignore).toContain(secret);

    // An existing .gitignore is kept, with the secrets added to it.
    await writeFile(path.join(root, '.gitignore'), '# mine\nnotes.txt\n');
    await saveToGitHub({ projectRoot: root, token: 't'.repeat(25), appName: 'Demo', runGit: git.run }, fakeGitHub({ repoExists: true }).impl);
    const merged = await readFile(path.join(root, '.gitignore'), 'utf8');
    expect(merged).toContain('notes.txt');
    expect(merged).toContain('*.jks');
    await rm(root, { recursive: true, force: true });
  });

  it('hides the token when git refuses the push', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'ember-gh-'));
    const run = async (args: string[]) => (args[0] === 'push' ? { code: 1, out: '', err: 'remote: rejected https://x-access-token:ghp_secret@github.com' } : { code: 0, out: '', err: '' });
    await expect(
      saveToGitHub({ projectRoot: root, token: 'ghp_secret', appName: 'Demo', runGit: run }, fakeGitHub({ repoExists: true }).impl),
    ).rejects.toThrow(/\*\*\*/);
    await rm(root, { recursive: true, force: true });
  });

  it('marks the repository as an Ember app, so another computer finds it', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'ember-gh-'));
    const gh = fakeGitHub({ repoExists: true });
    await saveToGitHub({ projectRoot: root, token: 't'.repeat(25), appName: 'Beauty Camera', runGit: fakeGit().run }, gh.impl);
    expect(JSON.parse(await readFile(path.join(root, '.ember', 'app.json'), 'utf8')).app).toBe('Beauty Camera');
    expect(gh.calls.some((c) => c.method === 'PUT' && c.url.endsWith('/topics') && c.body.includes(EMBER_TOPIC))).toBe(true);
    await rm(root, { recursive: true, force: true });
  });

  it('says plainly when the token is not valid', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'ember-gh-'));
    const impl = (async () => new Response(JSON.stringify({ message: 'Bad credentials' }), { status: 401 })) as unknown as typeof fetch;
    await expect(saveToGitHub({ projectRoot: root, token: 'x'.repeat(25), appName: 'Demo', runGit: fakeGit().run }, impl)).rejects.toBeInstanceOf(GitHubError);
    await rm(root, { recursive: true, force: true });
  });
});

describe('apps saved on GitHub', () => {
  const repos = (async (url: string | URL) => {
    if (String(url).endsWith('/user')) return new Response(JSON.stringify({ login: 'adnan' }), { status: 200 });
    return new Response(
      JSON.stringify([
        { name: 'beauty-camera', topics: [EMBER_TOPIC], html_url: 'https://github.com/adnan/beauty-camera', updated_at: '2026-09-01T10:00:00Z', private: true },
        { name: 'notes-of-mine', topics: ['personal'], updated_at: '2026-08-01T10:00:00Z' },
      ]),
      { status: 200 },
    );
  }) as unknown as typeof fetch;

  it('lists only the repositories Ember saved', async () => {
    const apps = await listEmberApps('t'.repeat(25), repos);
    expect(apps.map((a) => a.repo)).toEqual(['beauty-camera']);
    expect(apps[0]).toMatchObject({ owner: 'adnan', app: 'beauty camera' });
  });

  it('brings one back and takes the token out of the saved address', async () => {
    const dir = await mkdtemp(path.join(os.tmpdir(), 'ember-gh-'));
    const dest = path.join(dir, 'beauty_camera');
    const git = fakeGit();
    const out = await restoreFromGitHub({ token: 'ghp_secret', repo: 'beauty-camera', dest, runGit: git.run }, repos);

    expect(git.ran[0]!.slice(0, 3)).toEqual(['clone', '--depth', '1']);
    expect(git.ran[0]![3]).toContain('ghp_secret');
    expect(git.ran.at(-1)).toEqual(['remote', 'set-url', 'origin', 'https://github.com/adnan/beauty-camera.git']);
    // Without the marker file the repository name is the best name we have.
    expect(out.app).toBe('beauty camera');
    await rm(dir, { recursive: true, force: true });
  });

  it('never writes over an app already on this computer', async () => {
    const dir = await mkdtemp(path.join(os.tmpdir(), 'ember-gh-'));
    await writeFile(path.join(dir, 'taken'), 'x');
    await expect(restoreFromGitHub({ token: 't'.repeat(25), repo: 'r', dest: path.join(dir, 'taken'), runGit: fakeGit().run }, repos)).rejects.toThrow(/already exists/i);
    await rm(dir, { recursive: true, force: true });
  });
});

describe('a dropped upload', () => {
  it('is told apart from a real refusal', async () => {
    const { isDroppedConnection } = await import('./github.js');
    expect(isDroppedConnection('error: RPC failed; curl 55 Send failure: Connection was aborted')).toBe(true);
    expect(isDroppedConnection('remote: Permission to x denied')).toBe(false);
  });
});
