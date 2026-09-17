import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { GitHubError, repoName, saveToGitHub } from './github.js';

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

  it('says plainly when the token is not valid', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'ember-gh-'));
    const impl = (async () => new Response(JSON.stringify({ message: 'Bad credentials' }), { status: 401 })) as unknown as typeof fetch;
    await expect(saveToGitHub({ projectRoot: root, token: 'x'.repeat(25), appName: 'Demo', runGit: fakeGit().run }, impl)).rejects.toBeInstanceOf(GitHubError);
    await rm(root, { recursive: true, force: true });
  });
});
