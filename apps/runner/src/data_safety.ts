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

/**
 * The data that LEAVES the phone, read from the app's dependencies and code.
 * Both stores ask the same thing: "collected" means sent off the device (to
 * you or to an SDK), not merely used on it. A photo editor that never uploads
 * a photo does not collect photos; an ad SDK always collects a device id.
 */
export interface AppDataFacts {
  /** Sign-in: name, email, user id. */
  account: boolean;
  /** Photos or videos uploaded. */
  photos: boolean;
  /** Documents uploaded. */
  files: boolean;
  /** Precise location sent to a server. */
  location: boolean;
  /** Approximate location (e.g. from the IP, by ad and analytics SDKs). */
  approxLocation: boolean;
  contacts: boolean;
  /** Voice or sound recordings uploaded (playing music is not it). */
  microphone: boolean;
  /** Chat or messages stored on a server. */
  messages: boolean;
  crashLogs: boolean;
  performance: boolean;
  /** An analytics SDK (Firebase Analytics, Mixpanel…). */
  analytics: boolean;
  /** Taps, screens viewed…, sent by analytics or ad SDKs. */
  productInteraction: boolean;
  /** Advertising or app-instance id. */
  deviceId: boolean;
  ads: boolean;
  /** Purchase history kept by you or a service like RevenueCat (store-only purchases are Apple's/Google's). */
  purchases: boolean;
  /** Sells anything in the app, even through the store alone. */
  payments: boolean;
  /** Other user content stored in the cloud. */
  cloudStorage: boolean;
  /** App for children (Apple Kids category): nothing is used to track. */
  kids?: boolean;
}

const has = (deps: Set<string>, ...names: string[]) => names.some((n) => deps.has(n));

/** Dependency names from pubspec.yaml (dependencies only, not dev tools). */
function dependencies(pubspec: string): Set<string> {
  const block = /^dependencies:\s*\n([\s\S]*?)(?=^\S)/m.exec(`${pubspec}\nend:`)?.[1] ?? '';
  return new Set([...block.matchAll(/^\s{2}([a-z0-9_]+):/gm)].map((m) => m[1]!));
}

async function dartCode(dir: string): Promise<string> {
  let out = '';
  for (const e of await readdir(dir, { withFileTypes: true }).catch(() => [])) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out += await dartCode(p);
    else if (e.name.endsWith('.dart')) out += `${await readFile(p, 'utf8').catch(() => '')}\n`;
  }
  return out;
}

export async function detectDataFacts(projectRoot: string): Promise<AppDataFacts> {
  const deps = dependencies(await readFile(path.join(projectRoot, 'pubspec.yaml'), 'utf8').catch(() => ''));
  const code = await dartCode(path.join(projectRoot, 'lib'));

  const ads = has(deps, 'google_mobile_ads', 'applovin_max', 'startapp_sdk', 'unity_ads_plugin', 'facebook_audience_network', 'ironsource_mediation', 'easy_ads_flutter');
  const analytics = has(deps, 'firebase_analytics', 'mixpanel_flutter', 'amplitude_flutter', 'appsflyer_sdk', 'adjust_sdk', 'facebook_app_events', 'posthog_flutter');
  const crash = has(deps, 'firebase_crashlytics', 'sentry_flutter', 'bugsnag_flutter');
  const backend =
    has(deps, 'cloud_firestore', 'firebase_database', 'supabase_flutter', 'appwrite', 'parse_server_sdk_flutter', 'graphql_flutter') ||
    /\b(http|dio|client)\.(post|put|patch)\s*\(/i.test(code);
  // Something is uploaded: a multipart form, a storage bucket, a file put.
  const uploads =
    has(deps, 'firebase_storage') ||
    /MultipartRequest|MultipartFile|FormData\.fromMap|\.putFile\s*\(|\.putData\s*\(|\.uploadBinary\s*\(|storage\s*\.\s*from\s*\(/.test(code);

  return {
    account: has(deps, 'firebase_auth', 'google_sign_in', 'sign_in_with_apple', 'flutter_facebook_auth') || (deps.has('supabase_flutter') && /\.auth\.sign(In|Up)/.test(code)),
    photos: has(deps, 'image_picker', 'camera', 'photo_manager', 'wechat_assets_picker', 'image_cropper') && uploads,
    files: has(deps, 'file_picker') && uploads,
    location: has(deps, 'geolocator', 'location', 'background_location') && backend,
    approxLocation: ads || analytics,
    contacts: has(deps, 'contacts_service', 'flutter_contacts') && backend,
    microphone: has(deps, 'record', 'flutter_sound', 'audio_waveforms') && uploads,
    messages: (backend || has(deps, 'socket_io_client', 'stream_chat_flutter')) && /collection\(\s*['"](messages|chats?)['"]|from\(\s*['"](messages|chats?)['"]|stream_chat|socket.*emit\(\s*['"]message/i.test(code),
    crashLogs: crash || ads,
    performance: crash || ads || has(deps, 'firebase_performance'),
    analytics,
    productInteraction: analytics || ads,
    deviceId: ads || analytics,
    ads,
    purchases: has(deps, 'purchases_flutter', 'flutter_stripe', 'stripe_sdk', 'adapty_flutter', 'qonversion_flutter'),
    payments: has(deps, 'in_app_purchase', 'purchases_flutter', 'flutter_stripe', 'stripe_sdk', 'adapty_flutter', 'qonversion_flutter'),
    cloudStorage: has(deps, 'firebase_storage') || (deps.has('supabase_flutter') && /storage\s*\.\s*from\s*\(/.test(code)),
  };
}

/** Human summary of the facts, used in the prompt and shown to the user. */
export function factsSummary(f: AppDataFacts): string {
  const yes = declarations(f).map((d) => d.label);
  return yes.length === 0 ? 'the app collects no personal data' : `the app collects: ${yes.join(', ')}`;
}

export type Purpose = 'app' | 'analytics' | 'ads' | 'account';

/**
 * One declared data type, in both stores' words. This single table feeds
 * Google's Data safety form and Apple's App Privacy answers, so the two
 * stores are always told the same thing.
 */
export interface DataDeclaration {
  /** Google Play response id, when Play has the type. */
  play: string | null;
  /** Apple appDataUsageCategories id, when Apple has the type. */
  apple: string | null;
  /** Italian label as App Store Connect shows it. */
  label: string;
  purposes: Purpose[];
  /** Tied to the user's identity (account, user id). */
  linked: boolean;
  /** Used to track the user across other companies' apps (personalised ads). */
  tracking: boolean;
}

export function declarations(f: AppDataFacts): DataDeclaration[] {
  const out: DataDeclaration[] = [];
  const add = (on: boolean, d: DataDeclaration) => on && out.push(d);
  const own = (extra: Purpose[] = []): Purpose[] => ['app', ...extra];
  const bySdk = (): Purpose[] => [...(f.ads ? (['ads'] as Purpose[]) : []), ...(f.analytics || f.ads ? (['analytics'] as Purpose[]) : [])];

  add(f.account, { play: 'PSL_NAME', apple: 'NAME', label: 'Nome', purposes: own(['account']), linked: true, tracking: false });
  add(f.account, { play: 'PSL_EMAIL', apple: 'EMAIL_ADDRESS', label: 'Indirizzo email', purposes: own(['account']), linked: true, tracking: false });
  add(f.account, { play: 'PSL_USER_ACCOUNT', apple: 'USER_ID', label: 'ID utente', purposes: own(['account']), linked: true, tracking: false });
  add(f.photos, { play: 'PSL_PHOTOS', apple: 'PHOTOS_OR_VIDEOS', label: 'Foto o video', purposes: own(), linked: f.account, tracking: false });
  add(f.files, { play: 'PSL_FILES_AND_DOCS', apple: 'OTHER_USER_CONTENT', label: 'Altri contenuti dell’utente', purposes: own(), linked: f.account, tracking: false });
  add(f.microphone, { play: 'PSL_AUDIO', apple: 'AUDIO_DATA', label: 'Dati audio', purposes: own(), linked: f.account, tracking: false });
  add(f.messages, { play: 'PSL_OTHER_MESSAGES', apple: 'OTHER_USER_CONTENT', label: 'Altri contenuti dell’utente (messaggi)', purposes: own(), linked: f.account, tracking: false });
  add(f.cloudStorage && !f.photos && !f.files, { play: 'PSL_USER_GENERATED_CONTENT', apple: 'OTHER_USER_CONTENT', label: 'Altri contenuti dell’utente', purposes: own(), linked: f.account, tracking: false });
  add(f.contacts, { play: 'PSL_CONTACTS', apple: 'CONTACTS', label: 'Contatti', purposes: own(), linked: f.account, tracking: false });
  add(f.location, { play: 'PSL_PRECISE_LOCATION', apple: 'PRECISE_LOCATION', label: 'Posizione precisa', purposes: own(), linked: f.account, tracking: false });
  const track = f.ads && !f.kids; // child-directed ads never track
  add(f.approxLocation, { play: 'PSL_APPROX_LOCATION', apple: 'COARSE_LOCATION', label: 'Posizione approssimativa', purposes: bySdk(), linked: false, tracking: track });
  add(f.purchases, { play: 'PSL_PURCHASE_HISTORY', apple: 'PURCHASE_HISTORY', label: 'Cronologia acquisti', purposes: own(), linked: f.account, tracking: false });
  add(f.deviceId, { play: 'PSL_DEVICE_ID', apple: 'DEVICE_ID', label: 'ID dispositivo', purposes: f.ads ? ['ads'] : ['analytics'], linked: false, tracking: track });
  add(f.productInteraction, { play: 'PSL_USER_INTERACTION', apple: 'PRODUCT_INTERACTION', label: 'Interazione con il prodotto', purposes: bySdk(), linked: false, tracking: false });
  add(f.ads, { play: null, apple: 'ADVERTISING_DATA', label: 'Dati sulla pubblicità', purposes: ['ads'], linked: false, tracking: track });
  add(f.crashLogs, { play: 'PSL_CRASH_LOGS', apple: 'CRASH_DATA', label: 'Dati sui crash', purposes: ['analytics'], linked: false, tracking: false });
  add(f.performance, { play: 'PSL_PERFORMANCE_DIAGNOSTICS', apple: 'PERFORMANCE_DATA', label: 'Dati sulle prestazioni', purposes: ['analytics'], linked: false, tracking: false });
  return out;
}

/** Data types the app collects, by Play's own response ids. */
function selectedTypes(f: AppDataFacts): Set<string> {
  return new Set(declarations(f).map((d) => d.play).filter((x): x is string => !!x));
}

const PLAY_PURPOSE: Record<Purpose, string> = {
  app: 'PSL_APP_FUNCTIONALITY',
  analytics: 'PSL_ANALYTICS',
  ads: 'PSL_ADVERTISING',
  account: 'PSL_ACCOUNT_MANAGEMENT',
};

/** Why each data type is collected, in Play's words. */
function purposes(type: string, f: AppDataFacts): Set<string> {
  const p = new Set<string>();
  for (const d of declarations(f)) if (d.play === type) d.purposes.forEach((x) => p.add(PLAY_PURPOSE[x]));
  return p;
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

/**
 * Fills the exported form from what the app actually does. The ids Google puts
 * in the CSV are stable, so this needs no AI: same answers every time, in a
 * second, for a form of ~800 rows.
 */
export function fillCsv(csv: string, facts: AppDataFacts, deletionUrl = ''): string {
  if (facts.account && !/^https?:\/\//.test(deletionUrl)) {
    throw new PlayError(
      'needs_deletion_url',
      'The app has sign-in, so Google asks for a public page where users can request deletion of their account and data. Add the privacy policy link in "Edit title and descriptions", then press this button again.',
    );
  }
  const types = selectedTypes(facts);
  const collects = types.size > 0;
  const lines = csv.replace(/\r\n/g, '\n').trim().split('\n');
  const out = lines.map((line, index) => {
    if (index === 0) return line;
    const cols = splitCsv(line);
    const [question = '', response = ''] = cols;
    let value = '';
    if (question === 'PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA') value = collects ? 'TRUE' : 'FALSE';
    // An app that collects nothing answers nothing else: Google refuses the
    // encryption, account-creation and deletion answers when no data is
    // collected ("You cannot answer PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT").
    else if (!collects) value = '';
    else if (question === 'PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT') value = 'TRUE';
    else if (question === 'PSL_SUPPORT_DATA_DELETION_BY_USER') value = response === (facts.account ? 'DATA_DELETION_YES' : 'DATA_DELETION_NO') ? 'TRUE' : '';
    // Saying users can ask for deletion obliges us to say where: the privacy policy page explains how.
    else if (question === 'PSL_ACCOUNT_DELETION_URL' || question === 'PSL_DATA_DELETION_URL') value = facts.account ? deletionUrl : '';
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
