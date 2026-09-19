import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

/**
 * The two things Google needs before an app can go public, and that Ember can
 * settle alone: a package name worth keeping forever, and a privacy policy
 * page anyone on the internet can open.
 */

/** The prefix every new project starts with, before it has a real name. */
export const PLACEHOLDER_PREFIX = 'dev.fluttercursor.app.';

/** A package name from the app's own name: `com.studio.doodledino`. */
export function packageName(appName: string, prefix: string): string {
  const word = appName
    .split(':')[0]!
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
  const safe = /^[a-z]/.test(word) ? word : `app${word}`;
  return `${prefix.replace(/\.$/, '')}.${safe.slice(0, 40) || 'app'}`;
}

/**
 * Gives a project its real package name, once, before it ever reaches Google.
 *
 * A package name can never change after the first upload, so the placeholder
 * must go before that — and only then. An app already on Play, or wired to
 * Firebase with the old name, keeps what it has: renaming it would break it.
 */
export async function claimPackageName(
  projectRoot: string,
  input: { appName: string; prefix: string; alreadyPublished: boolean },
): Promise<string | null> {
  if (input.alreadyPublished || !input.appName.trim()) return null;
  if (existsSync(path.join(projectRoot, 'android', 'app', 'google-services.json'))) return null;
  const gradle = path.join(projectRoot, 'android', 'app', 'build.gradle.kts');
  const text = await readFile(gradle, 'utf8').catch(() => null);
  if (!text) return null;
  const current = /applicationId\s*=\s*"([^"]+)"/.exec(text)?.[1];
  if (!current?.startsWith(PLACEHOLDER_PREFIX)) return null;
  const next = packageName(input.appName, input.prefix);
  await writeFile(gradle, text.replace(/applicationId\s*=\s*"[^"]+"/, `applicationId = "${next}"`));
  return next;
}

/** Fills the blanks an AI-written policy leaves for the owner's name and address. */
export function fillPolicy(markdown: string, owner: { name: string; email: string }): string {
  return markdown
    .replace(/^<!--.*-->\n/, '')
    .replace(/\[(NOME TITOLARE|OWNER NAME|NOME DEL TITOLARE|COMPANY NAME|NOME AZIENDA)\]/gi, owner.name)
    .replace(/\[(EMAIL|E-MAIL|INDIRIZZO EMAIL|CONTACT EMAIL)\]/gi, owner.email);
}

function run(bin: string, args: string[], cwd: string): Promise<{ code: number; out: string }> {
  return new Promise((resolve) => {
    const win = process.platform === 'win32';
    const p = spawn(win ? `${bin}.exe` : bin, args, { cwd, windowsHide: true });
    let out = '';
    p.stdout?.on('data', (d) => (out += d));
    p.stderr?.on('data', (d) => (out += d));
    const t = setTimeout(() => p.kill(), 120_000);
    p.on('error', (e) => (clearTimeout(t), resolve({ code: -1, out: e.message })));
    p.on('close', (code) => (clearTimeout(t), resolve({ code: code ?? -1, out })));
  });
}

/**
 * Publishes the policy as a public page on the user's GitHub, the way Google
 * wants it: an address anyone can open, that stays up. Returns null when the
 * GitHub tool is not signed in, and the user pastes a link of their own.
 */
export async function publishPolicy(markdown: string, appName: string): Promise<string | null> {
  const dir = await mkdtemp(path.join(os.tmpdir(), 'ember-policy-'));
  try {
    const file = `${appName.split(':')[0]!.trim().replace(/[^\w-]+/g, '-').toLowerCase() || 'app'}-privacy.md`;
    await writeFile(path.join(dir, file), markdown);
    const res = await run('gh', ['gist', 'create', '--public', '--desc', `${appName} - Privacy Policy`, file], dir);
    return /https:\/\/gist\.github\.com\/\S+/.exec(res.out)?.[0] ?? null;
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}
