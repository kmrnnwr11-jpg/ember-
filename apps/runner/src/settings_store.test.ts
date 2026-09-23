import { mkdtemp, readFile, stat } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { beforeEach, describe, expect, it } from 'vitest';
import { readSettings, writeSettings } from './settings_store.js';

describe('settings kept on the Runner', () => {
  beforeEach(async () => {
    process.env.EMBER_SETTINGS_DIR = await mkdtemp(path.join(os.tmpdir(), 'ember-settings-'));
  });

  it('keeps what was typed, per user, in a file only the user can read', async () => {
    await writeSettings('dev_abc', { github_token: 'ghp_x', 'ai_chat_P1': '[]' });
    expect(await readSettings('dev_abc')).toEqual({ github_token: 'ghp_x', ai_chat_P1: '[]' });
    expect(await readSettings('someone_else')).toEqual({});
    const file = path.join(process.env.EMBER_SETTINGS_DIR!, 'dev_abc.json');
    expect((await stat(file)).mode & 0o777).toBe(0o600);
    expect(JSON.parse(await readFile(file, 'utf8')).github_token).toBe('ghp_x');
  });

  it('removes a key only when asked, and never loses one of two quick saves', async () => {
    await Promise.all([writeSettings('u', { a: '1' }), writeSettings('u', { b: '2' }), writeSettings('u', { c: '3' })]);
    expect(await readSettings('u')).toEqual({ a: '1', b: '2', c: '3' });
    await writeSettings('u', { b: null });
    expect(await readSettings('u')).toEqual({ a: '1', c: '3' });
  });

  it('refuses a key that could escape the file', async () => {
    await expect(writeSettings('u', { '../x': '1' })).rejects.toThrow(/bad setting key/);
  });
});
