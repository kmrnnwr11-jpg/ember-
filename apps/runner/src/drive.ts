import { readFile } from 'node:fs/promises';
import { driveToken } from './play_setup.js';

/**
 * Backup of an app's upload key to the user's own Google Drive.
 *
 * The upload key is the one thing that cannot be recreated: lose it and that
 * app can never be updated again on Google Play. It lives on this PC only, so
 * Ember copies it — with its password — into a folder on the user's Drive.
 */

const FOLDER = 'Ember - app signing keys';
const API = 'https://www.googleapis.com/drive/v3';
const UPLOAD = 'https://www.googleapis.com/upload/drive/v3/files';

async function driveFetch(token: string, url: string, init: RequestInit, fetchImpl: typeof fetch): Promise<Record<string, unknown>> {
  const res = await fetchImpl(url, { ...init, headers: { ...init.headers, authorization: `Bearer ${token}` } });
  const text = await res.text();
  if (!res.ok) {
    let message = text;
    try {
      message = (JSON.parse(text) as { error?: { message?: string } }).error?.message ?? text;
    } catch {
      // raw text
    }
    throw new Error(`Google Drive refused the backup: ${message.slice(0, 300)}`);
  }
  return (text ? JSON.parse(text) : {}) as Record<string, unknown>;
}

/** The backup folder, created the first time. */
async function ensureFolder(token: string, fetchImpl: typeof fetch): Promise<string> {
  const q = encodeURIComponent(`name='${FOLDER}' and mimeType='application/vnd.google-apps.folder' and trashed=false`);
  const found = (await driveFetch(token, `${API}/files?q=${q}&fields=files(id)`, { method: 'GET' }, fetchImpl)) as { files?: Array<{ id: string }> };
  if (found.files?.[0]?.id) return found.files[0].id;
  const created = await driveFetch(
    token,
    `${API}/files?fields=id`,
    { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ name: FOLDER, mimeType: 'application/vnd.google-apps.folder' }) },
    fetchImpl,
  );
  return String(created.id);
}

/** Writes one file into the backup folder, replacing the previous copy with the same name. */
async function put(token: string, folderId: string, name: string, body: Buffer, contentType: string, fetchImpl: typeof fetch): Promise<string> {
  const q = encodeURIComponent(`name='${name.replace(/'/g, "\\'")}' and '${folderId}' in parents and trashed=false`);
  const existing = (await driveFetch(token, `${API}/files?q=${q}&fields=files(id)`, { method: 'GET' }, fetchImpl)) as { files?: Array<{ id: string }> };
  const id = existing.files?.[0]?.id;
  const metadata = id ? { name } : { name, parents: [folderId] };
  const boundary = `ember${Date.now()}`;
  const payload = Buffer.concat([
    Buffer.from(`--${boundary}\r\ncontent-type: application/json; charset=UTF-8\r\n\r\n${JSON.stringify(metadata)}\r\n--${boundary}\r\ncontent-type: ${contentType}\r\n\r\n`),
    body,
    Buffer.from(`\r\n--${boundary}--`),
  ]);
  const url = id ? `${UPLOAD}/${id}?uploadType=multipart&fields=id` : `${UPLOAD}?uploadType=multipart&fields=id`;
  const res = await driveFetch(
    token,
    url,
    { method: id ? 'PATCH' : 'POST', headers: { 'content-type': `multipart/related; boundary=${boundary}` }, body: payload },
    fetchImpl,
  );
  return String(res.id);
}

export interface KeyBackup {
  appName: string;
  packageName: string | null;
  keystorePath: string;
  alias: string;
  password: string;
}

/** Copies the keystore and its password to Drive; returns the folder to open. */
export async function backupKey(key: KeyBackup, fetchImpl: typeof fetch = fetch): Promise<{ folderUrl: string; files: string[] }> {
  const token = await driveToken();
  const folderId = await ensureFolder(token, fetchImpl);
  const safe = key.appName.replace(/[^\w .-]/g, '').trim() || 'app';
  const notes = [
    `App: ${key.appName}`,
    `Package: ${key.packageName ?? 'unknown'}`,
    `Key alias: ${key.alias}`,
    `Key password: ${key.password}`,
    `Store password: ${key.password}`,
    `Backed up: ${new Date().toISOString()}`,
    '',
    'Keep this file. Without the keystore and this password no one, not even Google,',
    'can publish an update of this app ever again.',
  ].join('\n');
  const files = [
    await put(token, folderId, `${safe} - upload-keystore.jks`, await readFile(key.keystorePath), 'application/octet-stream', fetchImpl),
    await put(token, folderId, `${safe} - password.txt`, Buffer.from(notes, 'utf8'), 'text/plain', fetchImpl),
  ];
  return { folderUrl: `https://drive.google.com/drive/folders/${folderId}`, files };
}
