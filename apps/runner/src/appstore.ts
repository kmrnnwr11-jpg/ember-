import { spawn } from 'node:child_process';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { importPKCS8, SignJWT } from 'jose';
import type { AppDataFacts } from './data_safety.js';

/**
 * App Store Connect: the Apple half of publishing. Same idea as play.ts —
 * the user's own key, nothing stored by the Runner — covering what Apple lets
 * a program do: upload the build, write the store page in every language, set
 * the privacy answers, and send the version for review.
 *
 * The one step that needs a Mac is making and uploading the file itself
 * (Apple's own tools), so that part refuses politely anywhere else.
 */

const API = 'https://api.appstoreconnect.apple.com/v1';

export class AppStoreError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly status?: number,
  ) {
    super(message);
  }
}

/** The three things Apple gives when you create an API key. */
export interface AppStoreKey {
  /** Key ID, e.g. "2X9R4HXF34". */
  keyId: string;
  /** Issuer ID: a UUID, the same for every key of the account. */
  issuerId: string;
  /** Contents of the AuthKey_XXXX.p8 file. */
  privateKey: string;
}

export function parseAppStoreKey(input: { keyId?: unknown; issuerId?: unknown; privateKey?: unknown }): AppStoreKey {
  const keyId = `${input.keyId ?? ''}`.trim();
  const issuerId = `${input.issuerId ?? ''}`.trim();
  const privateKey = `${input.privateKey ?? ''}`.trim();
  if (!/^[A-Z0-9]{8,12}$/i.test(keyId)) throw new AppStoreError('bad_request', 'The Key ID is the short code Apple shows next to the key, e.g. 2X9R4HXF34');
  if (!/^[0-9a-f-]{36}$/i.test(issuerId)) throw new AppStoreError('bad_request', 'The Issuer ID is the long code at the top of the Keys page in App Store Connect');
  if (!privateKey.includes('BEGIN PRIVATE KEY')) throw new AppStoreError('bad_request', 'Paste the whole AuthKey_….p8 file, including the BEGIN PRIVATE KEY line');
  return { keyId, issuerId, privateKey };
}

/** A token Apple accepts, signed with the user's key. Valid 20 minutes. */
export async function appStoreToken(key: AppStoreKey, now = Date.now()): Promise<string> {
  const pk = await importPKCS8(key.privateKey, 'ES256').catch(() => {
    throw new AppStoreError('bad_request', 'Apple did not accept this .p8 key. Download it again from App Store Connect.');
  });
  return new SignJWT({ aud: 'appstoreconnect-v1' })
    .setProtectedHeader({ alg: 'ES256', kid: key.keyId, typ: 'JWT' })
    .setIssuer(key.issuerId)
    .setIssuedAt(Math.floor(now / 1000))
    .setExpirationTime(Math.floor(now / 1000) + 20 * 60)
    .sign(pk);
}

type Fetch = typeof fetch;

interface Resource {
  id: string;
  attributes?: Record<string, unknown>;
  relationships?: Record<string, unknown>;
}

async function appleError(res: Response, what: string): Promise<AppStoreError> {
  let detail = `${res.status} ${res.statusText}`;
  try {
    const j = (await res.json()) as { errors?: Array<{ title?: string; detail?: string }> };
    const first = j.errors?.[0];
    if (first) detail = `${first.title ?? ''}${first.detail ? `: ${first.detail}` : ''}`.trim() || detail;
  } catch {
    // keep the status text
  }
  if (res.status === 401) return new AppStoreError('bad_key', `Apple did not accept the key. Check Key ID, Issuer ID and the .p8 file. (${detail})`, 401);
  if (res.status === 403) return new AppStoreError('no_permission', `This key may not do that. Give it the "App Manager" role in App Store Connect. (${detail})`, 403);
  return new AppStoreError('appstore_error', `${what}: ${detail}`, res.status);
}

/** One signed-in conversation with App Store Connect. */
export class AppStore {
  constructor(
    private readonly token: string,
    private readonly fetchImpl: Fetch = fetch,
  ) {}

  static async open(key: AppStoreKey, fetchImpl: Fetch = fetch): Promise<AppStore> {
    return new AppStore(await appStoreToken(key), fetchImpl);
  }

  async call<T = { data: Resource | Resource[] }>(method: string, url: string, body?: unknown, what = 'App Store Connect'): Promise<T> {
    const res = await this.fetchImpl(url.startsWith('http') ? url : `${API}${url}`, {
      method,
      headers: {
        authorization: `Bearer ${this.token}`,
        ...(body !== undefined ? { 'content-type': 'application/json' } : {}),
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    if (!res.ok) throw await appleError(res, what);
    const text = await res.text();
    return (text ? JSON.parse(text) : {}) as T;
  }

  /** The app with this Bundle ID, as Apple knows it. */
  async findApp(bundleId: string): Promise<{ id: string; name: string }> {
    const { data } = await this.call<{ data: Resource[] }>('GET', `/apps?filter[bundleId]=${encodeURIComponent(bundleId)}&limit=1`, undefined, 'Looking for the app');
    const app = data?.[0];
    if (!app) {
      throw new AppStoreError(
        'app_not_found',
        `App Store Connect has no app with Bundle ID ${bundleId}. Create it once in App Store Connect (My Apps → +), then Ember does the rest.`,
        404,
      );
    }
    return { id: app.id, name: `${app.attributes?.name ?? ''}` };
  }

  /**
   * The version being prepared: the one still editable, or a new one.
   * Apple refuses to change a version that is already in review or on sale.
   */
  async ensureVersion(appId: string, versionString: string): Promise<{ id: string; versionString: string; created: boolean }> {
    const { data } = await this.call<{ data: Resource[] }>(
      'GET',
      `/apps/${appId}/appStoreVersions?filter[platform]=IOS&limit=10`,
      undefined,
      'Reading the versions',
    );
    const editable = new Set(['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED', 'INVALID_BINARY']);
    const open = (data ?? []).find((v) => editable.has(`${v.attributes?.appStoreState ?? ''}`));
    if (open) return { id: open.id, versionString: `${open.attributes?.versionString ?? versionString}`, created: false };

    const created = await this.call<{ data: Resource }>(
      'POST',
      '/appStoreVersions',
      { data: { type: 'appStoreVersions', attributes: { platform: 'IOS', versionString }, relationships: { app: { data: { type: 'apps', id: appId } } } } },
      'Creating the version',
    );
    return { id: created.data.id, versionString, created: true };
  }

  /** The store page in one language: description, keywords, what's new. */
  async writeVersionPage(versionId: string, page: AppStoreListing): Promise<void> {
    const locale = appleLocale(page.language);
    const attributes = {
      locale,
      description: page.description?.slice(0, 4000) || undefined,
      keywords: page.keywords?.slice(0, 100) || undefined,
      whatsNew: page.releaseNotes?.slice(0, 4000) || undefined,
      supportUrl: page.supportUrl || undefined,
      marketingUrl: page.marketingUrl || undefined,
      promotionalText: page.promotionalText?.slice(0, 170) || undefined,
    };
    const { data } = await this.call<{ data: Resource[] }>('GET', `/appStoreVersions/${versionId}/appStoreVersionLocalizations?limit=50`, undefined, 'Reading the store page');
    const existing = (data ?? []).find((l) => `${l.attributes?.locale ?? ''}` === locale);
    if (existing) {
      const { locale: _drop, ...rest } = attributes;
      await this.call('PATCH', `/appStoreVersionLocalizations/${existing.id}`, { data: { type: 'appStoreVersionLocalizations', id: existing.id, attributes: rest } }, 'Writing the store page');
      return;
    }
    await this.call(
      'POST',
      '/appStoreVersionLocalizations',
      { data: { type: 'appStoreVersionLocalizations', attributes, relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } } } } },
      'Writing the store page',
    );
  }

  /** Name, subtitle and privacy address: these belong to the app, not to one version. */
  async writeAppPage(appId: string, page: AppStoreListing & { privacyPolicyUrl?: string }): Promise<void> {
    const locale = appleLocale(page.language);
    const { data: infos } = await this.call<{ data: Resource[] }>('GET', `/apps/${appId}/appInfos?limit=10`, undefined, 'Reading the app details');
    const editable = new Set(['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED']);
    const info = (infos ?? []).find((i) => editable.has(`${i.attributes?.appStoreState ?? ''}`)) ?? infos?.[0];
    if (!info) return;

    const attributes = {
      locale,
      name: page.title?.slice(0, 30) || undefined,
      subtitle: page.subtitle?.slice(0, 30) || undefined,
      privacyPolicyUrl: page.privacyPolicyUrl || undefined,
    };
    const { data } = await this.call<{ data: Resource[] }>('GET', `/appInfos/${info.id}/appInfoLocalizations?limit=50`, undefined, 'Reading the app details');
    const existing = (data ?? []).find((l) => `${l.attributes?.locale ?? ''}` === locale);
    if (existing) {
      const { locale: _drop, ...rest } = attributes;
      await this.call('PATCH', `/appInfoLocalizations/${existing.id}`, { data: { type: 'appInfoLocalizations', id: existing.id, attributes: rest } }, 'Writing the app details');
      return;
    }
    await this.call(
      'POST',
      '/appInfoLocalizations',
      { data: { type: 'appInfoLocalizations', attributes, relationships: { appInfo: { data: { type: 'appInfos', id: info.id } } } } },
      'Writing the app details',
    );
  }

  /**
   * Apple's privacy answers ("App Privacy"), the counterpart of Google's Data
   * safety: written from what the app actually uses, never guessed.
   */
  async writePrivacy(appId: string, facts: AppDataFacts): Promise<{ collects: boolean; categories: string[] }> {
    const wanted = privacyCategories(facts);
    const existing = await this.call<{ data: Resource[] }>('GET', `/apps/${appId}/appDataUsages?limit=200`, undefined, 'Reading the privacy answers');
    for (const row of existing.data ?? []) {
      await this.call('DELETE', `/appDataUsages/${row.id}`, undefined, 'Clearing the old privacy answers').catch(() => ({}));
    }

    if (wanted.length === 0) {
      await this.call(
        'POST',
        '/appDataUsages',
        {
          data: {
            type: 'appDataUsages',
            relationships: {
              app: { data: { type: 'apps', id: appId } },
              dataProtection: { data: { type: 'appDataUsageDataProtections', id: 'DATA_NOT_COLLECTED' } },
            },
          },
        },
        'Saying the app collects nothing',
      );
      return { collects: false, categories: [] };
    }

    for (const c of wanted) {
      await this.call(
        'POST',
        '/appDataUsages',
        {
          data: {
            type: 'appDataUsages',
            relationships: {
              app: { data: { type: 'apps', id: appId } },
              category: { data: { type: 'appDataUsageCategories', id: c.category } },
              dataProtection: { data: { type: 'appDataUsageDataProtections', id: c.linked ? 'DATA_LINKED_TO_YOU' : 'DATA_NOT_LINKED_TO_YOU' } },
              purpose: { data: { type: 'appDataUsagePurposes', id: c.purpose } },
            },
          },
        },
        `Privacy: ${c.category}`,
      );
    }
    await this.call('PATCH', `/apps/${appId}/relationships/appDataUsagesPublishState`, { data: { type: 'appDataUsagesPublishState', attributes: { published: true } } }, 'Publishing the privacy answers').catch(() => ({}));
    return { collects: true, categories: wanted.map((c) => c.category) };
  }

  /** The newest build Apple has finished processing for this version string. */
  async latestBuild(appId: string, versionString?: string): Promise<{ id: string; version: string } | null> {
    const q = versionString ? `&filter[preReleaseVersion.version]=${encodeURIComponent(versionString)}` : '';
    const { data } = await this.call<{ data: Resource[] }>('GET', `/builds?filter[app]=${appId}&limit=10&sort=-uploadedDate${q}`, undefined, 'Looking for the uploaded build');
    const ready = (data ?? []).find((b) => `${b.attributes?.processingState ?? ''}` === 'VALID') ?? data?.[0];
    return ready ? { id: ready.id, version: `${ready.attributes?.version ?? ''}` } : null;
  }

  /** Ties the uploaded build to the version being prepared. */
  async attachBuild(versionId: string, buildId: string): Promise<void> {
    await this.call('PATCH', `/appStoreVersions/${versionId}/relationships/build`, { data: { type: 'builds', id: buildId } }, 'Attaching the build');
  }

  /** Sends the version to Apple's reviewers. */
  async submitForReview(versionId: string): Promise<void> {
    await this.call(
      'POST',
      '/appStoreVersionSubmissions',
      { data: { type: 'appStoreVersionSubmissions', relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } } } } },
      'Sending for review',
    );
  }
}

export interface AppStoreListing {
  /** Same language codes as the Play listing, e.g. `en-US`, `it-IT`. */
  language: string;
  title?: string;
  subtitle?: string;
  description?: string;
  keywords?: string;
  releaseNotes?: string;
  promotionalText?: string;
  supportUrl?: string;
  marketingUrl?: string;
}

/** Play language codes as Apple writes them. */
export function appleLocale(language: string): string {
  const map: Record<string, string> = {
    'en-US': 'en-US',
    'en-GB': 'en-GB',
    'it-IT': 'it',
    'fr-FR': 'fr-FR',
    'es-ES': 'es-ES',
    'de-DE': 'de-DE',
    'pt-PT': 'pt-PT',
    'pt-BR': 'pt-BR',
    'ru-RU': 'ru',
    'tr-TR': 'tr',
    'hi-IN': 'hi',
    ar: 'ar-SA',
    'ar-SA': 'ar-SA',
  };
  return map[language] ?? map[language.replace('_', '-')] ?? language;
}

/**
 * What the app collects, in Apple's own words. Deliberately the same source as
 * Google's Data safety, so the two stores can never be told different things.
 */
export function privacyCategories(facts: AppDataFacts): Array<{ category: string; purpose: string; linked: boolean }> {
  const out: Array<{ category: string; purpose: string; linked: boolean }> = [];
  const add = (category: string, purpose: string, linked: boolean) => out.push({ category, purpose, linked });
  if (facts.account) {
    add('EMAIL_ADDRESS', 'APP_FUNCTIONALITY', true);
    add('NAME', 'APP_FUNCTIONALITY', true);
    add('USER_ID', 'APP_FUNCTIONALITY', true);
  }
  if (facts.photos) add('PHOTOS_OR_VIDEOS', 'APP_FUNCTIONALITY', true);
  if (facts.contacts) add('CONTACTS', 'APP_FUNCTIONALITY', true);
  if (facts.location) add('COARSE_LOCATION', 'APP_FUNCTIONALITY', true);
  if (facts.microphone) add('AUDIO_DATA', 'APP_FUNCTIONALITY', true);
  if (facts.messages) add('OTHER_USER_CONTENT', 'APP_FUNCTIONALITY', true);
  if (facts.purchases) add('PURCHASE_HISTORY', 'APP_FUNCTIONALITY', true);
  if (facts.crashLogs) add('CRASH_DATA', 'ANALYTICS', false);
  if (facts.analytics) add('PRODUCT_INTERACTION', 'ANALYTICS', false);
  if (facts.ads) {
    add('DEVICE_ID', 'THIRD_PARTY_ADVERTISING', false);
    add('ADVERTISING_DATA', 'THIRD_PARTY_ADVERTISING', false);
  }
  return out;
}

/** The .ipa a finished iPhone build leaves behind. */
export async function findIpa(projectRoot: string): Promise<string | null> {
  const dir = path.join(projectRoot, 'build', 'ios', 'ipa');
  const files = await readdir(dir).catch(() => [] as string[]);
  const ipa = files.filter((f) => f.toLowerCase().endsWith('.ipa')).sort();
  return ipa.length > 0 ? path.join(dir, ipa[ipa.length - 1]!) : null;
}

function runTool(bin: string, args: string[], timeoutMs = 30 * 60_000): Promise<{ code: number; out: string }> {
  return new Promise((resolve) => {
    const p = spawn(bin, args, { windowsHide: true });
    let out = '';
    p.stdout?.on('data', (d) => (out += d));
    p.stderr?.on('data', (d) => (out += d));
    const t = setTimeout(() => p.kill(), timeoutMs);
    p.on('error', (e) => (clearTimeout(t), resolve({ code: -1, out: e.message })));
    p.on('close', (code) => (clearTimeout(t), resolve({ code: code ?? -1, out })));
  });
}

/**
 * Sends the .ipa to Apple with their own tool, the only way in. It lives on the
 * Mac, so anywhere else this says so instead of failing.
 */
export async function uploadIpa(
  ipaPath: string,
  key: AppStoreKey,
  run: (bin: string, args: string[]) => Promise<{ code: number; out: string }> = runTool,
  platform = process.platform,
): Promise<{ uploaded: boolean; output: string }> {
  if (platform !== 'darwin') {
    throw new AppStoreError('needs_mac', 'Only a Mac can send the app to Apple. Open Ember on your Mac, take the app back from GitHub and upload from there.');
  }
  const res = await run('xcrun', ['altool', '--upload-app', '-f', ipaPath, '-t', 'ios', '--apiKey', key.keyId, '--apiIssuer', key.issuerId]);
  if (res.code !== 0) throw new AppStoreError('upload_failed', `Apple refused the upload: ${res.out.slice(-500)}`);
  return { uploaded: true, output: res.out.slice(-2000) };
}

export interface AppStorePublishInput {
  key: AppStoreKey;
  bundleId: string;
  /** Version shown on the store, e.g. "1.0.0". */
  versionString: string;
  projectRoot: string;
  listing?: AppStoreListing;
  translations?: AppStoreListing[];
  privacyPolicyUrl?: string;
  facts?: AppDataFacts;
  /** Send the .ipa (needs a Mac). When false, only the store page is written. */
  uploadBuild?: boolean;
  /** Hand the version to Apple's reviewers at the end. */
  submit?: boolean;
}

export interface AppStorePublishResult {
  appId: string;
  appName: string;
  versionId: string;
  versionString: string;
  versionCreated: boolean;
  languages: string[];
  privacy: { collects: boolean; categories: string[] } | null;
  buildUploaded: boolean;
  buildAttached: boolean;
  submitted: boolean;
  notes: string[];
}

/**
 * Everything Ember can do on Apple without a human: upload the build, write the
 * store page in every language, set the privacy answers, attach the build and
 * send it for review.
 */
export async function publishToAppStore(input: AppStorePublishInput, fetchImpl: Fetch = fetch): Promise<AppStorePublishResult> {
  const store = await AppStore.open(input.key, fetchImpl);
  const app = await store.findApp(input.bundleId);
  const notes: string[] = [];

  let buildUploaded = false;
  if (input.uploadBuild) {
    const ipa = await findIpa(input.projectRoot);
    if (!ipa) throw new AppStoreError('no_ipa', 'No iPhone file yet: build the iPhone app first.');
    await uploadIpa(ipa, input.key);
    buildUploaded = true;
    notes.push('Apple needs a few minutes to process the build before it can be attached.');
  }

  const version = await store.ensureVersion(app.id, input.versionString);
  const pages = [input.listing, ...(input.translations ?? [])].filter((p): p is AppStoreListing => !!p && !!p.language);
  for (const page of pages) {
    await store.writeVersionPage(version.id, page);
    await store.writeAppPage(app.id, { ...page, privacyPolicyUrl: input.privacyPolicyUrl });
  }

  const privacy = input.facts ? await store.writePrivacy(app.id, input.facts) : null;

  let buildAttached = false;
  const build = await store.latestBuild(app.id).catch(() => null);
  if (build) {
    await store.attachBuild(version.id, build.id).then(
      () => (buildAttached = true),
      () => notes.push('The build is still being processed by Apple: attach it when it turns green, or run this again.'),
    );
  } else if (!input.uploadBuild) {
    notes.push('No build on Apple yet for this app.');
  }

  let submitted = false;
  if (input.submit && buildAttached) {
    await store.submitForReview(version.id).then(
      () => (submitted = true),
      (e: unknown) => notes.push(`Not sent for review: ${(e as Error).message}`),
    );
  } else if (input.submit) {
    notes.push('Not sent for review: Apple wants the build attached first.');
  }

  return {
    appId: app.id,
    appName: app.name,
    versionId: version.id,
    versionString: version.versionString,
    versionCreated: version.created,
    languages: pages.map((p) => appleLocale(p.language)),
    privacy,
    buildUploaded,
    buildAttached,
    submitted,
    notes,
  };
}

/** The version string ("1.0.0") from the project's pubspec. */
export async function projectVersion(projectRoot: string): Promise<string> {
  const pubspec = await readFile(path.join(projectRoot, 'pubspec.yaml'), 'utf8').catch(() => '');
  return /^version:\s*([0-9]+\.[0-9]+\.[0-9]+)/m.exec(pubspec)?.[1] ?? '1.0.0';
}
