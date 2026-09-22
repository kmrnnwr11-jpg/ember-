import { chmod, mkdir, readFile, rename, unlink, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { importPKCS8 } from 'jose';
import { AppStoreError, type AppStoreKey } from './appstore.js';

/**
 * The App Store Connect key, kept ONCE for the whole Apple account (every app of
 * the same account shares it), so the Key ID / Issuer ID / .p8 fields come back
 * filled after a page reload, a closed browser, a Runner restart or a reboot.
 *
 * It lives OUTSIDE the repo, in ~/.ember/apple, as a 0600 file — the same place
 * and permissions ~/.ssh keys use — so it never reaches git and is never sent to
 * the browser. The IDE only ever sees the Key ID, the Issuer ID and the file
 * name; the .p8 contents stay on the server for signing.
 */

export interface AppleCredsPublic {
  hasKey: boolean;
  keyId: string;
  issuerId: string;
  /** Display name only, e.g. "AuthKey_Z47GM3ZDZ6.p8". Never the contents. */
  p8File: string;
  updatedAt?: string;
}

interface Stored {
  keyId: string;
  issuerId: string;
  p8File: string;
  updatedAt: string;
}

const KEY_ID = /^[A-Z0-9]{8,12}$/i;
const ISSUER = /^[0-9a-f-]{36}$/i;

/** ~/.ember/apple, or EMBER_APPLE_DIR when set (tests, custom homes). */
function home(): string {
  return process.env.EMBER_APPLE_DIR?.trim() || path.join(os.homedir(), '.ember', 'apple');
}
const metaFile = () => path.join(home(), 'credentials.json');
const p8Name = (keyId: string) => `AuthKey_${keyId}.p8`;

async function readMeta(): Promise<Stored | null> {
  try {
    return JSON.parse(await readFile(metaFile(), 'utf8')) as Stored;
  } catch (e) {
    if ((e as NodeJS.ErrnoException).code === 'ENOENT') return null;
    throw e;
  }
}

async function writeSecret(file: string, data: string): Promise<void> {
  await mkdir(path.dirname(file), { recursive: true, mode: 0o700 });
  const tmp = `${file}.tmp`;
  await writeFile(tmp, data, { mode: 0o600 });
  await chmod(tmp, 0o600).catch(() => {});
  await rename(tmp, file);
  await chmod(file, 0o600).catch(() => {});
}

/** What the IDE may see: everything except the private key itself. */
export async function readAppleCredsPublic(): Promise<AppleCredsPublic> {
  const m = await readMeta();
  if (!m) return { hasKey: false, keyId: '', issuerId: '', p8File: '' };
  // "Saved" only if the key file is really still there.
  const present = await readFile(path.join(home(), m.p8File), 'utf8').then(
    () => true,
    () => false,
  );
  return { hasKey: present, keyId: m.keyId, issuerId: m.issuerId, p8File: m.p8File, updatedAt: m.updatedAt };
}

/** The full key for signing — server-side only, never leaves the Runner. */
export async function readAppleKey(): Promise<AppStoreKey | null> {
  const m = await readMeta();
  if (!m) return null;
  const privateKey = await readFile(path.join(home(), m.p8File), 'utf8').catch(() => '');
  if (!privateKey.includes('BEGIN PRIVATE KEY')) return null;
  return { keyId: m.keyId, issuerId: m.issuerId, privateKey };
}

export interface SaveInput {
  keyId?: unknown;
  issuerId?: unknown;
  /** The .p8 contents. Omit to change only the Key ID / Issuer ID. */
  privateKey?: unknown;
}

/**
 * Save or update the account key. Messages are Italian on purpose: they surface
 * straight into the card. The new value always replaces the old one.
 */
export async function saveAppleCreds(input: SaveInput): Promise<AppleCredsPublic> {
  const keyId = `${input.keyId ?? ''}`.trim();
  const issuerId = `${input.issuerId ?? ''}`.trim();
  const rawKey = input.privateKey === undefined || input.privateKey === null ? null : `${input.privateKey}`.trim();

  if (!KEY_ID.test(keyId)) throw new AppStoreError('bad_request', 'Il Key ID è il codice breve accanto alla chiave in App Store Connect, es. Z47GM3ZDZ6.');
  if (!ISSUER.test(issuerId)) throw new AppStoreError('bad_request', "L'Issuer ID è il codice lungo (un UUID) in cima alla pagina Chiavi di App Store Connect.");

  const prev = await readMeta();
  let p8File = prev?.p8File ?? '';

  if (rawKey && rawKey.length > 0) {
    // A key was pasted or loaded: it must be the file CONTENTS, not its name.
    if (!rawKey.includes('BEGIN PRIVATE KEY')) {
      throw new AppStoreError(
        'bad_request',
        'Questo non è il contenuto della chiave: incolla tutto il file AuthKey_….p8, dalla riga -----BEGIN PRIVATE KEY----- fino a -----END PRIVATE KEY-----. Il solo nome del file non basta.',
      );
    }
    await importPKCS8(rawKey, 'ES256').catch(() => {
      throw new AppStoreError('bad_request', 'Apple non ha accettato questo file .p8: riscaricalo da App Store Connect.');
    });
    const newName = p8Name(keyId);
    await writeSecret(path.join(home(), newName), rawKey.endsWith('\n') ? rawKey : `${rawKey}\n`);
    if (p8File && p8File !== newName) await unlink(path.join(home(), p8File)).catch(() => {}); // Key ID changed: drop the old file.
    p8File = newName;
  } else {
    // No new key: we can only change the IDs, and only if a key is already stored.
    if (!p8File) throw new AppStoreError('bad_request', 'Manca la chiave .p8: la prima volta carica o incolla il file AuthKey_….p8.');
    if (prev && prev.keyId !== keyId) throw new AppStoreError('bad_request', 'Hai cambiato il Key ID: carica anche il nuovo file .p8 corrispondente.');
  }

  const meta: Stored = { keyId, issuerId, p8File, updatedAt: new Date().toISOString() };
  await writeSecret(metaFile(), JSON.stringify(meta, null, 2));
  return { hasKey: true, keyId, issuerId, p8File, updatedAt: meta.updatedAt };
}

export async function deleteAppleCreds(): Promise<void> {
  const m = await readMeta();
  if (m?.p8File) await unlink(path.join(home(), m.p8File)).catch(() => {});
  await unlink(metaFile()).catch(() => {});
}
