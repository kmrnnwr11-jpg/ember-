import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { type AppDataFacts, detectDataFacts, factsSummary, fillCsv, findExportedCsv, validateFilledCsv } from './data_safety.js';

const CSV = 'Question ID,Response,Response value,Answer requirement,Human-friendly question label\nPSL_DATA_TYPES_PERSONAL,PSL_NAME,,MULTIPLE_CHOICE,Personal info - Name\nPSL_DATA_TYPES_PERSONAL,PSL_EMAIL,,MULTIPLE_CHOICE,Personal info - Email';

describe('data safety', () => {
  const app = async (deps: string, code = 'void main() {}') => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-ds-'));
    await writeFile(path.join(root, 'pubspec.yaml'), `name: x\ndependencies:\n${deps.split(',').map((d) => `  ${d.trim()}: any`).join('\n')}\n\ndev_dependencies:\n  flutter_test:\n    sdk: flutter\n`);
    await mkdir(path.join(root, 'lib'), { recursive: true });
    await writeFile(path.join(root, 'lib', 'main.dart'), code);
    const f = await detectDataFacts(root);
    await rm(root, { recursive: true, force: true });
    return f;
  };
  const on = (f: AppDataFacts) => (Object.keys(f) as Array<keyof AppDataFacts>).filter((k) => f[k]).sort();

  it('a video editor with ads: only what AdMob sends, not the photos and music that stay on the phone', async () => {
    const f = await app('image_picker, audioplayers, video_player, path_provider, share_plus, in_app_purchase, google_mobile_ads');
    expect(on(f)).toEqual(['ads', 'approxLocation', 'crashLogs', 'deviceId', 'payments', 'performance', 'productInteraction']);
    expect(factsSummary(f)).not.toMatch(/Foto|audio|acquisti/i);
  });

  it('photos count only when the app uploads them', async () => {
    expect((await app('image_picker, http')).photos).toBe(false);
    expect((await app('image_picker, http', 'final r = http.MultipartRequest("POST", u);')).photos).toBe(true);
    expect((await app('image_picker, firebase_storage')).photos).toBe(true);
  });

  it('sign-in is collected and linked; firebase_core alone is nothing', async () => {
    const f = await app('firebase_core, firebase_auth');
    expect(f.account).toBe(true);
    expect(f.analytics).toBe(false);
    expect(on(await app('firebase_core'))).toEqual([]);
    expect(factsSummary(await app('firebase_core'))).toBe('the app collects no personal data');
  });

  it('store-only purchases are Apple’s and Google’s; RevenueCat keeps a history', async () => {
    expect(await app('in_app_purchase')).toMatchObject({ purchases: false, payments: true });
    expect(await app('purchases_flutter')).toMatchObject({ purchases: true, payments: true });
  });

  it('location is precise only when the app sends it', async () => {
    expect((await app('geolocator')).location).toBe(false);
    expect((await app('geolocator, cloud_firestore')).location).toBe(true);
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
  approxLocation: false,
  performance: false,
  productInteraction: false,
  deviceId: false,
  payments: false,
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
    expect(valueOf(filled, 'PSL_SUPPORTED_ACCOUNT_CREATION_METHODS', 'PSL_ACM_NONE')).toBe('');
    expect(valueOf(filled, 'PSL_DATA_TYPES_PHOTOS_AND_VIDEOS', 'PSL_PHOTOS')).toBe('');
  });

  it('adds the advertising purpose to the device id only when the app shows ads', async () => {
    const csv = await readFile(FIXTURE, 'utf8');
    const withAds = fillCsv(csv, facts({ ads: true, deviceId: true, approxLocation: true, productInteraction: true }));
    expect(valueOf(withAds, 'PSL_ACCOUNT_DELETION_URL')).toBe('');
    expect(valueOf(withAds, 'PSL_DATA_TYPES_IDENTIFIERS', 'PSL_DEVICE_ID')).toBe('TRUE');
    expect(valueOf(withAds, 'PSL_DATA_USAGE_RESPONSES:PSL_DEVICE_ID:DATA_USAGE_COLLECTION_PURPOSE', 'PSL_ADVERTISING')).toBe('TRUE');
    // Ad data is for ads and analytics, not for the app's own functions.
    expect(valueOf(withAds, 'PSL_DATA_USAGE_RESPONSES:PSL_DEVICE_ID:DATA_USAGE_COLLECTION_PURPOSE', 'PSL_APP_FUNCTIONALITY')).toBe('');
    expect(valueOf(withAds, 'PSL_DATA_TYPES_LOCATION', 'PSL_APPROX_LOCATION')).toBe('TRUE');
    expect(valueOf(withAds, 'PSL_DATA_TYPES_LOCATION', 'PSL_PRECISE_LOCATION')).toBe('');
    const noAds = fillCsv(csv, facts({ analytics: true, deviceId: true }));
    expect(valueOf(noAds, 'PSL_DATA_USAGE_RESPONSES:PSL_DEVICE_ID:DATA_USAGE_COLLECTION_PURPOSE', 'PSL_ADVERTISING')).toBe('');
    expect(valueOf(noAds, 'PSL_DATA_USAGE_RESPONSES:PSL_DEVICE_ID:DATA_USAGE_COLLECTION_PURPOSE', 'PSL_ANALYTICS')).toBe('TRUE');
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

describe('an app that collects no data', () => {
  it('answers only "no data collected", nothing Google would refuse', async () => {
    const csv = await readFile(FIXTURE, 'utf8');
    const filled = fillCsv(csv, facts());
    expect(valueOf(filled, 'PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA')).toBe('FALSE');
    for (const q of ['PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT', 'PSL_SUPPORTED_ACCOUNT_CREATION_METHODS', 'PSL_SUPPORT_DATA_DELETION_BY_USER']) {
      expect(filled.split('\n').filter((l) => l.startsWith(q + ',') && /,TRUE/.test(l))).toEqual([]);
    }
  });
});
