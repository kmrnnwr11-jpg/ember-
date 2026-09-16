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

export const DATA_SAFETY_SYSTEM = `You fill Google Play Console "Data safety" CSV forms.
You get the exported CSV (columns: Question ID, Response, Response value, Answer requirement, Human-friendly question label) and facts about the app.
Rules:
- Output ONLY the complete CSV, same rows in the same order, same columns, nothing else. No markdown fences, no comments.
- Only change the "Response value" column: TRUE or FALSE (or empty where the requirement is OPTIONAL and the answer is no).
- Answer truthfully from the facts: declare every data type the app can collect, mark data as encrypted in transit, say users can request deletion, and that data is collected (not only processed ephemerally) when it is stored in the cloud.
- Every REQUIRED question must have a value, every SINGLE_CHOICE exactly one TRUE, every MULTIPLE_CHOICE at least one TRUE.`;

export function dataSafetyPrompt(csv: string, facts: AppDataFacts, appName: string): string {
  return [
    `App: ${appName}`,
    `Facts: ${factsSummary(facts)}.`,
    'Notes: account data (email, name) when the app has sign-in; photos when it uses camera or gallery; messages when users write to each other;',
    'device or other ids and crash logs when Firebase is used; purchase history when it sells products; ads id when it shows ads.',
    'Fill this CSV now:',
    '',
    csv,
  ].join('\n');
}

/** Keeps the AI honest: same question ids, same order, only the response value may change. */
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
