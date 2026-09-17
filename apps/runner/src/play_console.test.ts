import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { chromeProfileDir, lastUsedProfile, profileForAccount } from './play_console.js';

describe('play console window', () => {
  it('opens the Chrome profile the person actually uses', () => {
    // Opening "Default" when they work in "Profile 3" lands on a logged-out window,
    // and Google will not let a driven window sign in again.
    expect(lastUsedProfile(JSON.stringify({ profile: { last_used: 'Profile 3', last_active_profiles: ['Profile 3'] } }))).toBe('Profile 3');
    expect(lastUsedProfile(JSON.stringify({ profile: { last_active_profiles: ['Profile 1'] } }))).toBe('Profile 1');
    expect(lastUsedProfile(JSON.stringify({}))).toBe('Default');
    expect(lastUsedProfile('not json')).toBe('Default');
  });

  it('picks the profile signed in with the account that owns the app', async () => {
    const dir = await mkdtemp(path.join(os.tmpdir(), 'ember-chrome-'));
    const profile = async (name: string, emails: string[]) => {
      await mkdir(path.join(dir, name), { recursive: true });
      await writeFile(path.join(dir, name, 'Preferences'), JSON.stringify({ account_info: emails.map((email) => ({ email })) }));
    };
    await profile('Default', ['personal@gmail.com', 'other@gmail.com']);
    await profile('Profile 1', ['work@gmail.com']);
    await profile('Profile 4', ['store@gmail.com']);

    expect(await profileForAccount(dir, 'store@gmail.com')).toBe('Profile 4');
    expect(await profileForAccount(dir, 'STORE@gmail.com')).toBe('Profile 4');
    expect(await profileForAccount(dir, 'personal@gmail.com')).toBe('Default');
    // Unknown account: the caller falls back to the last used profile rather than guessing.
    expect(await profileForAccount(dir, 'nobody@gmail.com')).toBeNull();
    expect(await profileForAccount(dir, '')).toBeNull();
    await rm(dir, { recursive: true, force: true });
  });

  it('finds where this computer keeps Chrome profiles', () => {
    expect(chromeProfileDir({ LOCALAPPDATA: 'C:\\Users\\a\\AppData\\Local' }, 'win32')).toContain('Chrome');
    expect(chromeProfileDir({ HOME: '/home/a' }, 'linux')).toContain('google-chrome');
    expect(chromeProfileDir({ HOME: '/Users/a' }, 'darwin')).toContain('Application Support');
    expect(chromeProfileDir({}, 'win32')).toBeNull();
  });
});
