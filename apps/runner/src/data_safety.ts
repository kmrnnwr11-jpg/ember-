import { readdir, readFile, stat } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { getAccessToken, PlayError, type ServiceAccount } from './play.js';

/**
 * Play Console "Data safety": the user exports the CSV template from Play Console,
 * the AI fills the answers from what the app actually uses, and the Runner uploads
 * it with the Android Publisher API (applications.dataSafety).
 */

const API = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';

/** What the app does with data, read from its dependencies and code. */
export interface AppDataFacts {
  account: boolean;
  photos: boolean;
  files: boolean;
  location: boolean;
  contacts: boolean;
  microphone: boolean;
  messages: boolean;
  crashLogs: boolean;
  analytics: boolean;
  ads: boolean;
  purchases: boolean;
  cloudStorage: boolean;
}

const SIGNALS: Array<[keyof AppDataFacts, RegExp]> = [
  ['account', /firebase_auth|google_sign_in|sign_in_with_apple|supabase_flutter/],
  ['photos', /image_picker|camera:|photo_manager|image_cropper/],
  ['files', /file_picker|path_provider|share_plus/],
  ['location', /geolocator|location:|google_maps_flutter/],
  ['contacts', /contacts_service|flutter_contacts/],
  ['microphone', /record:|audioplayers|speech_to_text|agora|jitsi/],
  ['messages', /cloud_firestore|supabase_flutter|socket_io|web_socket/],
  ['crashLogs', /firebase_crashlytics|sentry/],
  ['analytics', /firebase_analytics|firebase_core/],
  ['ads', /google_mobile_ads|applovin|startapp/],
  ['purchases', /in_app_purchase|stripe/],
  ['cloudStorage', /firebase_storage|supabase_flutter|aws_s3/],
];

export async function detectDataFacts(projectRoot: string): Promise<AppDataFacts> {
  const pubspec = await readFile(path.join(projectRoot, 'pubspec.yaml'), 'utf8').catch(() => '');
  const facts: Record<string, boolean> = Object.fromEntries(SIGNALS.map(([k]) => [k, false]));
  for (const [key, re] of SIGNALS) {
    if (re.test(pubspec)) facts[key] = true;
  }
  return facts as unknown as AppDataFacts;
}

/** Human summary of the facts, used in the prompt and shown to the user. */
export function factsSummary(f: AppDataFacts): string {
  const yes = (Object.entries(f) as Array<[string, boolean]>).filter(([, v]) => v).map(([k]) => k);
  return yes.length === 0 ? 'the app collects no personal data' : `the app uses: ${yes.join(', ')}`;
}

/** Splits one CSV line into fields, honouring quotes. */
function splitCsv(line: string): string[] {
  const out: string[] = [];
  let field = '';
  let quoted = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i]!;
    if (quoted) {
      if (c === '"' && line[i + 1] === '"') (field += '"', i++);
      else if (c === '"') quoted = false;
      else field += c;
    } else if (c === '"') quoted = true;
    else if (c === ',') (out.push(field), (field = ''));
    else field += c;
  }
  out.push(field);
  return out;
}

const quote = (f: string) => (/[",\n]/.test(f) ? `"${f.replace(/"/g, '""')}"` : f);

/** Data types the app can collect, by Play's own response ids. */
function selectedTypes(f: AppDataFacts): Set<string> {
  const types = new Set<string>();
  const add = (on: boolean, ...ids: string[]) => on && ids.forEach((i) => types.add(i));
  add(f.account, 'PSL_NAME', 'PSL_EMAIL', 'PSL_USER_ACCOUNT');
  add(f.photos, 'PSL_PHOTOS');
  add(f.files, 'PSL_FILES_AND_DOCS');
  add(f.location, 'PSL_APPROX_LOCATION');
  add(f.contacts, 'PSL_CONTACTS');
  add(f.microphone, 'PSL_AUDIO');
  add(f.messages, 'PSL_OTHER_MESSAGES');
  add(f.crashLogs, 'PSL_CRASH_LOGS', 'PSL_PERFORMANCE_DIAGNOSTICS');
  add(f.analytics, 'PSL_USER_INTERACTION', 'PSL_DEVICE_ID');
  add(f.ads, 'PSL_DEVICE_ID');
  add(f.purchases, 'PSL_PURCHASE_HISTORY');
  add(f.cloudStorage, 'PSL_USER_GENERATED_CONTENT');
  return types;
}

/** Why each data type is collected. Every type serves the app itself; some serve more. */
function purposes(type: string, f: AppDataFacts): Set<string> {
  const p = new Set(['PSL_APP_FUNCTIONALITY']);
  if (['PSL_CRASH_LOGS', 'PSL_PERFORMANCE_DIAGNOSTICS', 'PSL_USER_INTERACTION'].includes(type)) p.add('PSL_ANALYTICS');
  if (['PSL_NAME', 'PSL_EMAIL', 'PSL_USER_ACCOUNT'].includes(type)) p.add('PSL_ACCOUNT_MANAGEMENT');
  if (type === 'PSL_DEVICE_ID' && f.ads) p.add('PSL_ADVERTISING');
  return p;
}

/**
 * Fills the exported form from what the app actually does. The ids Google puts
 * in the CSV are stable, so this needs no AI: same answers every time, in a
 * second, for a form of ~800 rows.
 */
export function fillCsv(csv: string, facts: AppDataFacts): string {
  const types = selectedTypes(facts);
  const collects = types.size > 0;
  const lines = csv.replace(/\r\n/g, '\n').trim().split('\n');
  const out = lines.map((line, index) => {
    if (index === 0) return line;
    const cols = splitCsv(line);
    const [question = '', response = ''] = cols;
    let value = '';
    if (question === 'PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA') value = collects ? 'TRUE' : 'FALSE';
    else if (question === 'PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT') value = 'TRUE';
    else if (question === 'PSL_SUPPORT_DATA_DELETION_BY_USER') value = response === (facts.account ? 'DATA_DELETION_YES' : 'DATA_DELETION_NO') ? 'TRUE' : '';
    else if (question === 'PSL_SUPPORTED_ACCOUNT_CREATION_METHODS') value = response === (facts.account ? 'PSL_ACM_OAUTH' : 'PSL_ACM_NONE') ? 'TRUE' : '';
    else if (question.startsWith('PSL_DATA_TYPES_')) value = types.has(response) ? 'TRUE' : '';
    else if (question.startsWith('PSL_DATA_USAGE_RESPONSES:')) {
      const [, type = '', field = ''] = question.split(':');
      if (!types.has(type)) value = '';
      else if (field === 'PSL_DATA_USAGE_COLLECTION_AND_SHARING') value = response === 'PSL_DATA_USAGE_ONLY_COLLECTED' ? 'TRUE' : '';
      else if (field === 'PSL_DATA_USAGE_EPHEMERAL') value = 'FALSE';
      else if (field === 'DATA_USAGE_USER_CONTROL') value = response === 'PSL_DATA_USAGE_USER_CONTROL_REQUIRED' ? 'TRUE' : '';
      else if (field === 'DATA_USAGE_COLLECTION_PURPOSE') value = purposes(type, facts).has(response) ? 'TRUE' : '';
    }
    cols[2] = value;
    return cols.map(quote).join(',');
  });
  return out.join('\n');
}

/** Safety net: same question ids, same order, only the response value may change. */
export function validateFilledCsv(original: string, filled: string): string {
  const rows = (t: string) => t.trim().split(/\r?\n/).map((l) => l.split(','));
  const a = rows(original);
  const b = rows(filled.replace(/^```[a-z]*\n?|```$/gm, '').trim());
  if (b.length !== a.length) throw new PlayError('bad_request', `The filled form has ${b.length} rows instead of ${a.length}`);
  for (let i = 0; i < a.length; i++) {
    if (a[i]![0] !== b[i]![0]) throw new PlayError('bad_request', `Row ${i + 1} changed question: ${b[i]![0]}`);
  }
  return b.map((r) => r.join(',')).join('\n');
}

/** The newest Data safety CSV exported from Play Console, from the user's Downloads folder. */
export async function findExportedCsv(dir = path.join(os.homedir(), 'Downloads')): Promise<string | null> {
  const files = await readdir(dir).catch(() => [] as string[]);
  const candidates = files.filter((f) => /\.csv$/i.test(f) && /(data.?safety|safety.?labels|privacy)/i.test(f));
  let newest: { file: string; at: number } | null = null;
  for (const f of candidates) {
    const s = await stat(path.join(dir, f)).catch(() => null);
    if (s && (!newest || s.mtimeMs > newest.at)) newest = { file: path.join(dir, f), at: s.mtimeMs };
  }
  return newest?.file ?? null;
}

/** Uploads the filled CSV to Google Play. */
export async function uploadDataSafety(
  input: { serviceAccount: ServiceAccount; packageName: string; csv: string },
  fetchImpl: typeof fetch = fetch,
): Promise<{ ok: true }> {
  const token = await getAccessToken(input.serviceAccount, fetchImpl);
  const res = await fetchImpl(`${API}/${encodeURIComponent(input.packageName)}/dataSafety`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ safetyLabels: input.csv }),
  });
  if (res.ok) return { ok: true };
  const text = await res.text();
  let message = text;
  try {
    message = (JSON.parse(text) as { error?: { message?: string } }).error?.message ?? text;
  } catch {
    // raw text
  }
  throw new PlayError('data_safety_rejected', `Google Play refused the Data safety form: ${message.slice(0, 500)}`, res.status);
}
