import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { type AppDataFacts, detectDataFacts, factsSummary, fillCsv, findExportedCsv, validateFilledCsv } from './data_safety.js';

const CSV = 'Question ID,Response,Response value,Answer requirement,Human-friendly question label\nPSL_DATA_TYPES_PERSONAL,PSL_NAME,,MULTIPLE_CHOICE,Personal info - Name\nPSL_DATA_TYPES_PERSONAL,PSL_EMAIL,,MULTIPLE_CHOICE,Personal info - Email';

describe('data safety', () => {
  it('detects what the app uses from its dependencies', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-ds-'));
    await writeFile(path.join(root, 'pubspec.yaml'), 'dependencies:\n  firebase_auth: ^6.0.0\n  image_picker: ^1.0.0\n  http: ^1.0.0\n');
    const f = await detectDataFacts(root);
    expect(f.account).toBe(true);
    expect(f.photos).toBe(true);
    expect(f.location).toBe(false);
    expect(factsSummary(f)).toContain('account');
    await rm(root, { recursive: true, force: true });
  });

  it('accepts a filled CSV with the same questions and rejects tampering', () => {
    const filled = CSV.replace('PSL_NAME,,', 'PSL_NAME,TRUE,');
    expect(validateFilledCsv(CSV, filled)).toContain('PSL_NAME,TRUE');
    expect(validateFilledCsv(CSV, '```csv\n' + filled + '\n```')).toContain('PSL_NAME,TRUE');
    expect(() => validateFilledCsv(CSV, CSV.split('\n').slice(0, 2).join('\n'))).toThrow(/rows/);
    expect(() => validateFilledCsv(CSV, filled.replace('PSL_DATA_TYPES_PERSONAL,PSL_EMAIL', 'PSL_OTHER,PSL_EMAIL'))).toThrow(/changed question/);
  });

  it('finds the newest exported CSV in a folder', async () => {
    const dir = await mkdtemp(path.join(os.tmpdir(), 'fc-dl-'));
    expect(await findExportedCsv(dir)).toBeNull();
    await writeFile(path.join(dir, 'data_safety_export.csv'), CSV);
    expect(await findExportedCsv(dir)).toContain('data_safety_export.csv');
    await rm(dir, { recursive: true, force: true });
  });
});

const FIXTURE = path.join(path.dirname(fileURLToPath(import.meta.url)), 'fixtures', 'data_safety_export.csv');

const facts = (over: Partial<AppDataFacts> = {}): AppDataFacts => ({
  account: false,
  photos: false,
  files: false,
  location: false,
  contacts: false,
  microphone: false,
  messages: false,
  crashLogs: false,
  analytics: false,
  ads: false,
  purchases: false,
  cloudStorage: false,
  ...over,
});

/** value of the "Response value" column for a question/response pair. */
function valueOf(csv: string, question: string, response = ''): string {
  const row = csv.split('\n').find((l) => l.startsWith(`${question},${response},`));
  return row ? row.split(',')[2] ?? '' : '<missing>';
}

describe('fillCsv', () => {
  it('fills the real exported form for a camera app with sign-in', async () => {
    const csv = await readFile(FIXTURE, 'utf8');
    const filled = fillCsv(csv, facts({ account: true, photos: true, files: true, crashLogs: true, analytics: true }), 'https://example.com/privacy');
    // Saying deletion is offered obliges us to say where.
    expect(valueOf(filled, 'PSL_ACCOUNT_DELETION_URL')).toBe('https://example.com/privacy');
    expect(valueOf(filled, 'PSL_DATA_DELETION_URL')).toBe('https://example.com/privacy');
    expect(() => validateFilledCsv(csv, filled)).not.toThrow();
    expect(filled.split('\n')).toHaveLength(csv.trim().split(/\r?\n/).length);

    expect(valueOf(filled, 'PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA')).toBe('TRUE');
    expect(valueOf(filled, 'PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT')).toBe('TRUE');
    expect(valueOf(filled, 'PSL_SUPPORT_DATA_DELETION_BY_USER', 'DATA_DELETION_YES')).toBe('TRUE');
    expect(valueOf(filled, 'PSL_SUPPORT_DATA_DELETION_BY_USER', 'DATA_DELETION_NO')).toBe('');
    expect(valueOf(filled, 'PSL_SUPPORTED_ACCOUNT_CREATION_METHODS', 'PSL_ACM_OAUTH')).toBe('TRUE');

    // Declared: photos, files, account data, crash logs. Not declared: location, contacts.
    expect(valueOf(filled, 'PSL_DATA_TYPES_PHOTOS_AND_VIDEOS', 'PSL_PHOTOS')).toBe('TRUE');
    expect(valueOf(filled, 'PSL_DATA_TYPES_PERSONAL', 'PSL_EMAIL')).toBe('TRUE');
    expect(valueOf(filled, 'PSL_DATA_TYPES_APP_PERFORMANCE', 'PSL_CRASH_LOGS')).toBe('TRUE');
    expect(valueOf(filled, 'PSL_DATA_TYPES_LOCATION', 'PSL_APPROX_LOCATION')).toBe('');
    expect(valueOf(filled, 'PSL_DATA_TYPES_CONTACTS', 'PSL_CONTACTS')).toBe('');

    // Every declared type says how it is used; undeclared ones stay empty.
    expect(valueOf(filled, 'PSL_DATA_USAGE_RESPONSES:PSL_PHOTOS:PSL_DATA_USAGE_COLLECTION_AND_SHARING', 'PSL_DATA_USAGE_ONLY_COLLECTED')).toBe('TRUE');
    expect(valueOf(filled, 'PSL_DATA_USAGE_RESPONSES:PSL_PHOTOS:PSL_DATA_USAGE_EPHEMERAL')).toBe('FALSE');
    expect(valueOf(filled, 'PSL_DATA_USAGE_RESPONSES:PSL_PHOTOS:DATA_USAGE_COLLECTION_PURPOSE', 'PSL_APP_FUNCTIONALITY')).toBe('TRUE');
    expect(valueOf(filled, 'PSL_DATA_USAGE_RESPONSES:PSL_PHOTOS:DATA_USAGE_COLLECTION_PURPOSE', 'PSL_ADVERTISING')).toBe('');
    expect(valueOf(filled, 'PSL_DATA_USAGE_RESPONSES:PSL_CONTACTS:PSL_DATA_USAGE_EPHEMERAL')).toBe('');
  });

  it('declares no collection at all for an app that touches nothing', async () => {
    const csv = await readFile(FIXTURE, 'utf8');
    const filled = fillCsv(csv, facts());
    expect(valueOf(filled, 'PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA')).toBe('FALSE');
    expect(valueOf(filled, 'PSL_SUPPORTED_ACCOUNT_CREATION_METHODS', 'PSL_ACM_NONE')).toBe('TRUE');
    expect(valueOf(filled, 'PSL_DATA_TYPES_PHOTOS_AND_VIDEOS', 'PSL_PHOTOS')).toBe('');
  });

  it('adds the advertising purpose to the device id only when the app shows ads', async () => {
    const csv = await readFile(FIXTURE, 'utf8');
    const withAds = fillCsv(csv, facts({ ads: true }));
    expect(valueOf(withAds, 'PSL_ACCOUNT_DELETION_URL')).toBe('');
    expect(valueOf(withAds, 'PSL_DATA_TYPES_IDENTIFIERS', 'PSL_DEVICE_ID')).toBe('TRUE');
    expect(valueOf(withAds, 'PSL_DATA_USAGE_RESPONSES:PSL_DEVICE_ID:DATA_USAGE_COLLECTION_PURPOSE', 'PSL_ADVERTISING')).toBe('TRUE');
    const noAds = fillCsv(csv, facts({ analytics: true }));
    expect(valueOf(noAds, 'PSL_DATA_USAGE_RESPONSES:PSL_DEVICE_ID:DATA_USAGE_COLLECTION_PURPOSE', 'PSL_ADVERTISING')).toBe('');
  });

  it('asks for the privacy link instead of sending a form Google would refuse', async () => {
    const csv = await readFile(FIXTURE, 'utf8');
    expect(() => fillCsv(csv, facts({ account: true }))).toThrow(/privacy policy link/);
  });

  it('keeps quoted labels intact', async () => {
    const csv = await readFile(FIXTURE, 'utf8');
    const filled = fillCsv(csv, facts({ account: true }), 'https://example.com/privacy');
    expect(filled).toContain('"Quale dei seguenti metodi di creazione dell\'account supporta la tua app? Seleziona tutte le opzioni pertinenti/Nome utente, password e altre autenticazioni"');
  });
});
