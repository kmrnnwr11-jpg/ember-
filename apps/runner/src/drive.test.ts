import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it, vi } from 'vitest';
import { backupKey } from './drive.js';

vi.mock('./play_setup.js', () => ({ driveToken: async () => 'test-token' }));

/** Google Drive, reduced to what the backup needs: search, create folder, upload. */
function fakeDrive() {
  const calls: Array<{ url: string; method: string; body: string }> = [];
  const impl = (async (url: string | URL, init: RequestInit = {}) => {
    const u = String(url);
    const body = typeof init.body === 'string' ? init.body : Buffer.isBuffer(init.body) ? init.body.toString('utf8') : '';
    calls.push({ url: u, method: init.method ?? 'GET', body });
    if (u.includes('/files?q=') && u.includes('folder')) return new Response(JSON.stringify({ files: [] }), { status: 200 });
    if (u.includes('/files?q=')) return new Response(JSON.stringify({ files: [] }), { status: 200 });
    return new Response(JSON.stringify({ id: `id-${calls.length}` }), { status: 200 });
  }) as unknown as typeof fetch;
  return { impl, calls };
}

describe('backupKey', () => {
  it('creates the folder once and saves the keystore next to its password', async () => {
    const dir = await mkdtemp(path.join(os.tmpdir(), 'ember-drive-'));
    const keystorePath = path.join(dir, 'upload-keystore.jks');
    await writeFile(keystorePath, 'binary-keystore');
    const drive = fakeDrive();

    const out = await backupKey(
      { appName: 'Beauty Camera & Photo Editor', packageName: 'dev.demo.app', keystorePath, alias: 'upload', password: 's3cret' },
      drive.impl,
    );

    expect(out.folderUrl).toContain('drive.google.com/drive/folders/');
    expect(out.files).toHaveLength(2);
    const uploads = drive.calls.filter((c) => c.url.includes('/upload/drive'));
    expect(uploads).toHaveLength(2);
    expect(uploads[0]!.body).toContain('Beauty Camera  Photo Editor - upload-keystore.jks');
    expect(uploads[0]!.body).toContain('binary-keystore');
    // The password is useless without the keystore, and the keystore useless without it: keep both.
    expect(uploads[1]!.body).toContain('s3cret');
    expect(uploads[1]!.body).toContain('dev.demo.app');
    await rm(dir, { recursive: true, force: true });
  });

  it('says what Google refused instead of failing silently', async () => {
    const dir = await mkdtemp(path.join(os.tmpdir(), 'ember-drive-'));
    const keystorePath = path.join(dir, 'k.jks');
    await writeFile(keystorePath, 'x');
    const impl = (async () => new Response(JSON.stringify({ error: { message: 'Insufficient permission' } }), { status: 403 })) as unknown as typeof fetch;
    await expect(backupKey({ appName: 'A', packageName: null, keystorePath, alias: 'upload', password: 'p' }, impl)).rejects.toThrow(/Insufficient permission/);
    await rm(dir, { recursive: true, force: true });
  });
});
