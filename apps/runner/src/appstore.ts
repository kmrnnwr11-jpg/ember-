import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { chmod, mkdtemp, readdir, readFile, rm, stat, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { importPKCS8, SignJWT } from 'jose';
import { declarations, type AppDataFacts, type DataDeclaration, type Purpose } from './data_safety.js';
import { ensureAppleProducts, submitProductsWithVersion, type AppleProduct } from './appstore_products.js';
import { SCREEN_PARAM } from './screenshots.js';

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
    const first = (j.errors as Array<{ title?: string; detail?: string; meta?: { associatedErrors?: Record<string, Array<{ detail?: string }>> } }> | undefined)?.[0];
    if (first) detail = `${first.title ?? ''}${first.detail ? `: ${first.detail}` : ''}`.trim() || detail;
    // "Cannot be reviewed" hides the real reasons in associatedErrors: show them.
    const why = Object.values(first?.meta?.associatedErrors ?? {}).flat().map((a) => a.detail).filter(Boolean);
    if (why.length) detail = `${detail} — ${why.join(' · ')}`;
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

  /**
   * Registers the Bundle ID on the developer account when it is missing, so the
   * app can be created on App Store Connect (the public API cannot create apps).
   */
  async ensureBundleId(identifier: string, name: string): Promise<{ id: string; created: boolean }> {
    const { data } = await this.call<{ data: Resource[] }>('GET', `/bundleIds?filter[identifier]=${encodeURIComponent(identifier)}&limit=5`, undefined, 'Looking for the Bundle ID');
    // The filter matches prefixes too: take the exact one.
    const found = (data ?? []).find((b) => `${b.attributes?.identifier ?? ''}` === identifier);
    if (found) return { id: found.id, created: false };
    const created = await this.call<{ data: Resource }>(
      'POST',
      '/bundleIds',
      { data: { type: 'bundleIds', attributes: { identifier, name: name.replace(/[^\p{L}\p{N} ]+/gu, ' ').trim().slice(0, 60) || identifier, platform: 'IOS' } } },
      'Registering the Bundle ID',
    );
    return { id: created.data.id, created: true };
  }

  /** The app with this Bundle ID, as Apple knows it. */
  async findApp(bundleId: string): Promise<{ id: string; name: string }> {
    const { data } = await this.call<{ data: Resource[] }>('GET', `/apps?filter[bundleId]=${encodeURIComponent(bundleId)}&limit=1`, undefined, 'Looking for the app');
    const app = data?.[0];
    if (!app) {
      throw new AppStoreError(
        'app_not_found',
        `App Store Connect non ha ancora un'app con Bundle ID ${bundleId}. Apri App Store Connect nel browser con l'estensione Ember e premi "Crea l'app": poi Ember fa il resto.`,
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
    if (open) {
      // Apple attaches a build only to the version with its own number: the
      // "1.0" App Store Connect makes with a new app must become e.g. "1.0.0".
      const current = `${open.attributes?.versionString ?? ''}`;
      if (versionString && current !== versionString) {
        await this.call(
          'PATCH',
          `/appStoreVersions/${open.id}`,
          { data: { type: 'appStoreVersions', id: open.id, attributes: { versionString } } },
          'Renaming the version',
        );
      }
      return { id: open.id, versionString: versionString || current, created: false };
    }

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
      description: withoutOtherPlatforms(appleText(page.description)).slice(0, 4000) || undefined,
      keywords: appleText(page.keywords || keywordsFrom(page)).slice(0, 100) || undefined,
      whatsNew: withoutOtherPlatforms(appleText(page.releaseNotes)).slice(0, 4000) || undefined,
      supportUrl: page.supportUrl || undefined,
      marketingUrl: page.marketingUrl || undefined,
      promotionalText: appleText(page.promotionalText).slice(0, 170) || undefined,
    };
    const { data } = await this.call<{ data: Resource[] }>('GET', `/appStoreVersions/${versionId}/appStoreVersionLocalizations?limit=50`, undefined, 'Reading the store page');
    const existing = (data ?? []).find((l) => `${l.attributes?.locale ?? ''}` === locale);
    const write = (attrs: typeof attributes) =>
      existing
        ? (() => {
            const { locale: _drop, ...rest } = attrs;
            return this.call('PATCH', `/appStoreVersionLocalizations/${existing.id}`, { data: { type: 'appStoreVersionLocalizations', id: existing.id, attributes: rest } }, 'Writing the store page');
          })()
        : this.call(
            'POST',
            '/appStoreVersionLocalizations',
            { data: { type: 'appStoreVersionLocalizations', attributes: attrs, relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } } } } },
            'Writing the store page',
          );
    try {
      await write(attributes);
    } catch (e) {
      // The first version of an app has no "What's new": Apple refuses the field.
      if (!(e instanceof AppStoreError) || !attributes.whatsNew || !/whatsNew/i.test(e.message)) throw e;
      await write({ ...attributes, whatsNew: undefined });
    }
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
      name: cutAtWord(appleText(page.title), 30) || undefined,
      subtitle: cutAtWord(appleText(page.subtitle), 30) || undefined,
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
  async latestBuild(appId: string, versionString?: string): Promise<{ id: string; version: string; state: string } | null> {
    const q = versionString ? `&filter[preReleaseVersion.version]=${encodeURIComponent(versionString)}` : '';
    const { data } = await this.call<{ data: Resource[] }>('GET', `/builds?filter[app]=${appId}&limit=10&sort=-uploadedDate${q}`, undefined, 'Looking for the uploaded build');
    // The newest build by its number, whatever its state: an older build that
    // is already processed must never be sent in place of the one just built.
    const newest = [...(data ?? [])].sort((a, b) => Number(b.attributes?.version ?? 0) - Number(a.attributes?.version ?? 0))[0];
    return newest ? { id: newest.id, version: `${newest.attributes?.version ?? ''}`, state: `${newest.attributes?.processingState ?? ''}` } : null;
  }

  /** Ties the uploaded build to the version being prepared. */
  async attachBuild(versionId: string, buildId: string): Promise<void> {
    await this.call('PATCH', `/appStoreVersions/${versionId}/relationships/build`, { data: { type: 'builds', id: buildId } }, 'Attaching the build');
    // A build made before Info.plist said "no special encryption" asks the question again.
    const { data } = await this.call<{ data: Resource }>('GET', `/builds/${buildId}`, undefined, 'Reading the build');
    if (data?.attributes?.usesNonExemptEncryption == null) {
      await this.call('PATCH', `/builds/${buildId}`, { data: { type: 'builds', id: buildId, attributes: { usesNonExemptEncryption: false } } }, 'Answering the encryption question');
    }
  }

  /** Waits (up to [maxMs]) until Apple has processed every screenshot of the version. */
  async waitForScreenshots(versionId: string, maxMs = 10 * 60_000): Promise<number> {
    const until = Date.now() + maxMs;
    for (;;) {
      const { data: locs } = await this.call<{ data: Resource[] }>('GET', `/appStoreVersions/${versionId}/appStoreVersionLocalizations?limit=50`, undefined, 'Reading the store pages');
      let pending = 0;
      for (const l of locs ?? []) {
        const sets = await this.call<{ included?: Resource[] }>('GET', `/appStoreVersionLocalizations/${l.id}/appScreenshotSets?include=appScreenshots&limit=50`, undefined, 'Reading the screenshots');
        for (const sh of (sets.included ?? []).filter((x) => (x as { type?: string }).type === 'appScreenshots')) {
          const st = (sh.attributes?.assetDeliveryState as { state?: string } | undefined)?.state;
          if (st !== 'COMPLETE' && st !== 'FAILED') pending++;
        }
      }
      if (pending === 0 || Date.now() > until) return pending;
      await new Promise((r) => setTimeout(r, 15_000));
    }
  }

  /**
   * Sends the version to Apple's reviewers through a review submission (the old
   * appStoreVersionSubmissions endpoint no longer accepts CREATE). An open
   * submission left by an earlier try is reused instead of piling up new ones.
   */
  async submitForReview(versionId: string, appId: string, withVersion?: () => Promise<unknown>): Promise<void> {
    const { data: open } = await this.call<{ data: Resource[] }>(
      'GET',
      `/reviewSubmissions?filter[app]=${appId}&filter[platform]=IOS&filter[state]=READY_FOR_REVIEW&limit=5`,
      undefined,
      'Reading the review submissions',
    );
    let subId = open?.[0]?.id;
    if (!subId) {
      const sub = await this.call<{ data: Resource }>(
        'POST',
        '/reviewSubmissions',
        { data: { type: 'reviewSubmissions', attributes: { platform: 'IOS' }, relationships: { app: { data: { type: 'apps', id: appId } } } } },
        'Opening the review submission',
      );
      subId = sub.data.id;
    }
    const { data: items } = await this.call<{ data: Resource[] }>('GET', `/reviewSubmissions/${subId}/items?limit=10`, undefined, 'Reading the review submission');
    if (!items?.length) {
      await this.call(
        'POST',
        '/reviewSubmissionItems',
        { data: { type: 'reviewSubmissionItems', relationships: { reviewSubmission: { data: { type: 'reviewSubmissions', id: subId } }, appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } } } } },
        'Adding the version to the review',
      );
    }
    // What must travel with the version (an app's first purchases) goes in now, while it is open.
    // If Apple refuses it, the version leaves the draft again: a version stuck in a draft hides
    // the page's purchase section and blocks the next try.
    try {
      await withVersion?.();
    } catch (e) {
      const { data: items } = await this.call<{ data: Resource[] }>('GET', `/reviewSubmissions/${subId}/items?limit=20`, undefined, 'Reading the review submission').catch(() => ({ data: [] as Resource[] }));
      for (const it of items ?? []) await this.call('DELETE', `/reviewSubmissionItems/${it.id}`, undefined, 'Taking the version out of the draft').catch(() => {});
      throw e;
    }
    await this.call('PATCH', `/reviewSubmissions/${subId}`, { data: { type: 'reviewSubmissions', id: subId, attributes: { submitted: true } } }, 'Sending for review');
  }

  /**
   * The age-rating questionnaire, the same one App Store Connect shows as a long
   * list of yes/no rows. Written from the app's facts; a plain app lands on 4+.
   */
  async setAgeRating(appId: string, decl: AgeRatingDeclaration): Promise<void> {
    // The questionnaire now belongs to the app's details (appInfo), not to a version.
    const { data: infos } = await this.call<{ data: Resource[] }>('GET', `/apps/${appId}/appInfos?limit=10`, undefined, 'Reading the app details');
    const editable = new Set(['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED']);
    const info = (infos ?? []).find((i) => editable.has(`${i.attributes?.appStoreState ?? ''}`)) ?? infos?.[0];
    if (!info) return;
    const { data } = await this.call<{ data: Resource }>('GET', `/appInfos/${info.id}/ageRatingDeclaration`, undefined, 'Reading the age rating');
    if (!data?.id) return;
    await this.call('PATCH', `/ageRatingDeclarations/${data.id}`, { data: { type: 'ageRatingDeclarations', id: data.id, attributes: decl } }, 'Writing the age rating');
  }

  /** The app's category (and an optional second one), on the App Store shelf. */
  async setCategories(appId: string, primary: string, secondary?: string): Promise<void> {
    const { data: infos } = await this.call<{ data: Resource[] }>('GET', `/apps/${appId}/appInfos?limit=10`, undefined, 'Reading the app details');
    const editable = new Set(['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED']);
    const info = (infos ?? []).find((i) => editable.has(`${i.attributes?.appStoreState ?? ''}`)) ?? infos?.[0];
    if (!info) return;
    const relationships: Record<string, unknown> = { primaryCategory: { data: { type: 'appCategories', id: primary } } };
    if (secondary) relationships.secondaryCategory = { data: { type: 'appCategories', id: secondary } };
    await this.call('PATCH', `/appInfos/${info.id}`, { data: { type: 'appInfos', id: info.id, relationships } }, 'Writing the category');
  }

  /**
   * The two answers Apple asks before any review: the copyright line of the
   * version, and whether the app ships content owned by others (music, images…).
   */
  async setRightsAndCopyright(appId: string, versionId: string, copyright: string, thirdPartyContent: boolean): Promise<void> {
    await this.call('PATCH', `/appStoreVersions/${versionId}`, { data: { type: 'appStoreVersions', id: versionId, attributes: { copyright } } }, 'Writing the copyright');
    await this.call(
      'PATCH',
      `/apps/${appId}`,
      { data: { type: 'apps', id: appId, attributes: { contentRightsDeclaration: thirdPartyContent ? 'USES_THIRD_PARTY_CONTENT' : 'DOES_NOT_USE_THIRD_PARTY_CONTENT' } } },
      'Writing the content rights',
    );
  }

  /** The account holder's name and Apple ID, the default review contact. */
  async accountHolder(): Promise<{ firstName: string; lastName: string; email: string } | null> {
    const { data } = await this.call<{ data: Resource[] }>('GET', '/users?limit=50', undefined, 'Reading the team');
    const u = (data ?? []).find((x) => ((x.attributes?.roles as string[] | undefined) ?? []).includes('ACCOUNT_HOLDER')) ?? data?.[0];
    return u ? { firstName: `${u.attributes?.firstName ?? ''}`, lastName: `${u.attributes?.lastName ?? ''}`, email: `${u.attributes?.username ?? ''}` } : null;
  }

  /**
   * The "App Review Information": who Apple can contact, and a demo login when
   * the app needs one. Removes the reviewer-contact form before submitting.
   */
  async setReviewDetails(versionId: string, d: AppReviewDetails): Promise<void> {
    const attributes = {
      contactFirstName: d.firstName || undefined,
      contactLastName: d.lastName || undefined,
      contactEmail: d.email || undefined,
      contactPhone: d.phone || undefined,
      demoAccountName: d.demoUser || undefined,
      demoAccountPassword: d.demoPassword || undefined,
      demoAccountRequired: !!(d.demoUser && d.demoPassword),
      notes: d.notes || undefined,
    };
    const existing = await this.call<{ data: Resource | null }>('GET', `/appStoreVersions/${versionId}/appStoreReviewDetail`, undefined, 'Reading the review details').catch(() => ({ data: null }));
    if (existing.data?.id) {
      await this.call('PATCH', `/appStoreReviewDetails/${existing.data.id}`, { data: { type: 'appStoreReviewDetails', id: existing.data.id, attributes } }, 'Writing the review details');
      return;
    }
    await this.call(
      'POST',
      '/appStoreReviewDetails',
      { data: { type: 'appStoreReviewDetails', attributes, relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } } } } },
      'Writing the review details',
    );
  }

  /** The store-page ids by Apple locale (created by writeVersionPage). */
  async versionLocalizations(versionId: string): Promise<Map<string, string>> {
    const { data } = await this.call<{ data: Resource[] }>('GET', `/appStoreVersions/${versionId}/appStoreVersionLocalizations?limit=50`, undefined, 'Reading the store pages');
    const map = new Map<string, string>();
    for (const l of data ?? []) map.set(`${l.attributes?.locale ?? ''}`, l.id);
    return map;
  }

  /**
   * Replace the screenshots of one device size for one language. Idempotent:
   * old images are cleared first, so re-publishing does not pile them up.
   */
  async putScreenshots(localizationId: string, displayType: string, images: Array<{ fileName: string; bytes: Buffer }>): Promise<number> {
    const { data: sets } = await this.call<{ data: Resource[] }>('GET', `/appStoreVersionLocalizations/${localizationId}/appScreenshotSets?limit=50`, undefined, 'Reading the screenshots');
    let setId = (sets ?? []).find((s) => `${s.attributes?.screenshotDisplayType ?? ''}` === displayType)?.id;
    if (!setId) {
      const made = await this.call<{ data: Resource }>(
        'POST',
        '/appScreenshotSets',
        { data: { type: 'appScreenshotSets', attributes: { screenshotDisplayType: displayType }, relationships: { appStoreVersionLocalization: { data: { type: 'appStoreVersionLocalizations', id: localizationId } } } } },
        'Making the screenshot set',
      );
      setId = made.data.id;
    } else {
      const { data: old } = await this.call<{ data: Resource[] }>('GET', `/appScreenshotSets/${setId}/appScreenshots?limit=50`, undefined, 'Reading the screenshots');
      for (const s of old ?? []) await this.call('DELETE', `/appScreenshots/${s.id}`, undefined, 'Clearing a screenshot').catch(() => ({}));
    }
    let done = 0;
    for (const img of images) {
      await this.uploadOneScreenshot(setId, img.fileName, img.bytes);
      done++;
    }
    return done;
  }

  /**
   * Apple's three-step upload for any image resource (review screenshots of
   * in-app purchases and subscriptions, …): reserve, send the parts, commit.
   */
  async uploadAsset(resource: string, relationships: Record<string, unknown>, fileName: string, bytes: Buffer, what = 'Uploading an image'): Promise<string> {
    const reserve = await this.call<{ data: { id: string; attributes?: { uploadOperations?: UploadOperation[] } } }>(
      'POST',
      `/${resource}`,
      { data: { type: resource, attributes: { fileName, fileSize: bytes.length }, relationships } },
      what,
    );
    const id = reserve.data.id;
    for (const op of reserve.data.attributes?.uploadOperations ?? []) {
      const headers: Record<string, string> = {};
      for (const h of op.requestHeaders ?? []) headers[h.name] = h.value;
      const start = op.offset ?? 0;
      const chunk = bytes.subarray(start, start + (op.length ?? bytes.length));
      const res = await this.fetchImpl(op.url, { method: op.method ?? 'PUT', headers, body: new Uint8Array(chunk) });
      if (!res.ok) throw new AppStoreError('upload_failed', `Apple ha rifiutato un pezzo del file: ${res.status}`);
    }
    const checksum = createHash('md5').update(bytes).digest('hex');
    await this.call('PATCH', `/${resource}/${id}`, { data: { type: resource, id, attributes: { uploaded: true, sourceFileChecksum: checksum } } }, what);
    return id;
  }

  private async uploadOneScreenshot(setId: string, fileName: string, bytes: Buffer): Promise<void> {
    const reserve = await this.call<{ data: { id: string; attributes?: { uploadOperations?: UploadOperation[] } } }>(
      'POST',
      '/appScreenshots',
      { data: { type: 'appScreenshots', attributes: { fileName, fileSize: bytes.length }, relationships: { appScreenshotSet: { data: { type: 'appScreenshotSets', id: setId } } } } },
      'Reserving a screenshot',
    );
    const id = reserve.data.id;
    for (const op of reserve.data.attributes?.uploadOperations ?? []) {
      const headers: Record<string, string> = {};
      for (const h of op.requestHeaders ?? []) headers[h.name] = h.value;
      const start = op.offset ?? 0;
      const chunk = bytes.subarray(start, start + (op.length ?? bytes.length));
      const res = await this.fetchImpl(op.url, { method: op.method ?? 'PUT', headers, body: new Uint8Array(chunk) });
      if (!res.ok) throw new AppStoreError('upload_failed', `Apple ha rifiutato un pezzo dello screenshot: ${res.status}`);
    }
    const checksum = createHash('md5').update(bytes).digest('hex');
    await this.call('PATCH', `/appScreenshots/${id}`, { data: { type: 'appScreenshots', id, attributes: { uploaded: true, sourceFileChecksum: checksum } } }, 'Finishing a screenshot');
  }

  /**
   * Make the app free in every territory. Apple's price model is finicky, so the
   * caller treats a failure as a note, not a stop.
   */
  async setFreePrice(appId: string): Promise<void> {
    const { data: points } = await this.call<{ data: Resource[] }>('GET', `/apps/${appId}/appPricePoints?filter[territory]=USA&limit=200`, undefined, 'Reading the prices');
    // Apple writes the free tier as "0.0" (it used to be "0.00").
    const free = (points ?? []).find((p) => Number(`${p.attributes?.customerPrice ?? 'x'}`) === 0);
    if (!free) throw new AppStoreError('no_free_point', 'Apple non offre il livello gratuito per questa app.');
    await this.call(
      'POST',
      '/appPriceSchedules',
      {
        data: {
          type: 'appPriceSchedules',
          relationships: {
            app: { data: { type: 'apps', id: appId } },
            baseTerritory: { data: { type: 'territories', id: 'USA' } },
            manualPrices: { data: [{ type: 'appPrices', id: '${price-free}' }] },
          },
        },
        included: [
          {
            type: 'appPrices',
            id: '${price-free}',
            attributes: { startDate: null },
            relationships: { appPricePoint: { data: { type: 'appPricePoints', id: free.id } } },
          },
        ],
      },
      'Setting the price to free',
    );
  }
}

interface UploadOperation {
  method?: string;
  url: string;
  length?: number;
  offset?: number;
  requestHeaders?: Array<{ name: string; value: string }>;
}

/** iPhone 6.7", iPhone 6.5" and iPad 12.9" — the sizes App Store asks for. */
export const APPLE_SHOT_SPECS: Array<{ type: string; width: number; height: number; scale: number; ipad?: boolean }> = [
  { type: 'APP_IPHONE_67', width: 430, height: 932, scale: 3 }, // 1290×2796
  { type: 'APP_IPHONE_65', width: 414, height: 896, scale: 3 }, // 1242×2688
  { type: 'APP_IPAD_PRO_3GEN_129', width: 1024, height: 1366, scale: 2, ipad: true }, // 2048×2732
];

/**
 * Open the web preview at each device size and screen and grab a PNG, exactly as
 * the Play screenshots do — but at Apple's pixel sizes and grouped by device.
 */
export async function captureAppleScreenshots(opts: {
  previewUrl: string;
  browser: string;
  count?: number;
  specs?: typeof APPLE_SHOT_SPECS;
}): Promise<Map<string, Buffer[]>> {
  const { default: puppeteer } = await import('puppeteer-core');
  const count = opts.count ?? 4;
  const specs = opts.specs ?? APPLE_SHOT_SPECS;
  const out = new Map<string, Buffer[]>();
  const browser = await puppeteer.launch({
    executablePath: opts.browser,
    headless: true,
    args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--no-first-run', '--no-default-browser-check', '--hide-scrollbars'],
  });
  try {
    for (const spec of specs) {
      const buffers: Buffer[] = [];
      const seen = new Set<string>();
      for (let i = 0; i < count; i++) {
        const page = await browser.newPage();
        try {
          await page.setViewport({ width: spec.width, height: spec.height, deviceScaleFactor: spec.scale, isMobile: !spec.ipad, hasTouch: true });
          const sep = opts.previewUrl.includes('?') ? '&' : '?';
          await page.goto(`${opts.previewUrl}${sep}${SCREEN_PARAM}=${i}`, { waitUntil: 'networkidle0', timeout: 90_000 });
          await page.waitForFunction(() => document.querySelector('flutter-view, flt-glass-pane') !== null, { timeout: 60_000 });
          await new Promise((r) => setTimeout(r, 3500));
          const png = Buffer.from(await page.screenshot({ type: 'png' }));
          const hash = createHash('sha1').update(png).digest('hex');
          if (seen.has(hash)) continue; // screen not implemented → same frame, skip
          seen.add(hash);
          buffers.push(png);
        } finally {
          await page.close().catch(() => undefined);
        }
      }
      if (buffers.length > 0) out.set(spec.type, buffers);
    }
  } finally {
    await browser.close().catch(() => undefined);
  }
  return out;
}

/**
 * The one-line encryption answer, set in the app itself so App Store Connect
 * never asks again: `ITSAppUsesNonExemptEncryption = false` in ios Info.plist.
 * iOS-only file — Android is untouched.
 */
export async function setIosExportCompliance(projectRoot: string): Promise<boolean> {
  const file = path.join(projectRoot, 'ios', 'Runner', 'Info.plist');
  let xml = await readFile(file, 'utf8').catch(() => '');
  if (!xml) return false;
  if (xml.includes('ITSAppUsesNonExemptEncryption')) return true;
  const idx = xml.lastIndexOf('</dict>');
  if (idx < 0) return false;
  xml = `${xml.slice(0, idx)}\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>\n${xml.slice(idx)}`;
  await writeFile(file, xml);
  return true;
}

/**
 * The age-rating answers. Every level is NONE and every switch is off for a
 * normal utility app — Apple reads that as 4+. Only bump what actually applies.
 */
export interface AgeRatingDeclaration {
  alcoholTobaccoOrDrugUseOrReferences?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  contests?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  gamblingSimulated?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  horrorOrFearThemes?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  matureOrSuggestiveThemes?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  medicalOrTreatmentInformation?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  profanityOrCrudeHumor?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  sexualContentGraphicAndNudity?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  sexualContentOrNudity?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  violenceCartoonOrFantasy?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  violenceRealistic?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  violenceRealisticProlongedGraphicOrSadistic?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  gambling?: boolean;
  unrestrictedWebAccess?: boolean;
  kidsAgeBand?: null | 'FIVE_AND_UNDER' | 'SIX_TO_EIGHT' | 'NINE_TO_ELEVEN';
  // Questions Apple added to the questionnaire in 2025.
  advertising?: boolean;
  gunsOrOtherWeapons?: 'NONE' | 'INFREQUENT_OR_MILD' | 'FREQUENT_OR_INTENSE';
  healthOrWellnessTopics?: boolean;
  lootBox?: boolean;
  messagingAndChat?: boolean;
  parentalControls?: boolean;
  ageAssurance?: boolean;
  userGeneratedContent?: boolean;
}

/** A safe, "nothing to declare" questionnaire → 4+ (ads are declared, as Apple asks). */
export function ageRating4Plus(facts?: Pick<AppDataFacts, 'ads'>, kidsAgeBand?: AgeRatingDeclaration['kidsAgeBand']): AgeRatingDeclaration {
  return {
    kidsAgeBand: kidsAgeBand ?? null,
    advertising: !!facts?.ads,
    gunsOrOtherWeapons: 'NONE',
    healthOrWellnessTopics: false,
    lootBox: false,
    messagingAndChat: false,
    parentalControls: false,
    ageAssurance: false,
    userGeneratedContent: false,
    alcoholTobaccoOrDrugUseOrReferences: 'NONE',
    contests: 'NONE',
    gamblingSimulated: 'NONE',
    horrorOrFearThemes: 'NONE',
    matureOrSuggestiveThemes: 'NONE',
    medicalOrTreatmentInformation: 'NONE',
    profanityOrCrudeHumor: 'NONE',
    sexualContentGraphicAndNudity: 'NONE',
    sexualContentOrNudity: 'NONE',
    violenceCartoonOrFantasy: 'NONE',
    violenceRealistic: 'NONE',
    violenceRealisticProlongedGraphicOrSadistic: 'NONE',
    gambling: false,
    unrestrictedWebAccess: false,
  };
}

export interface AppReviewDetails {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  demoUser?: string;
  demoPassword?: string;
  notes?: string;
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
 * Apple refuses emoji in the store texts ("Description can't contain the
 * following character(s): ✨, 💎"), which Google accepts. Drop them, and the
 * space or line they leave behind; plain symbols like • and © stay.
 */
export function appleText(text: string | undefined): string {
  if (!text) return '';
  return text
    .replace(/[\p{Extended_Pictographic}\p{Regional_Indicator}\u{1F3FB}-\u{1F3FF}\u200D\uFE0F\u20E3]/gu, '')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/^[ \t]+/gm, '')
    .replace(/[ \t]{2,}/g, ' ')
    .trim();
}

/** The promotional text (170 characters): the listing's short pitch, whole sentences. */
export function promotionalFrom(page: { subtitle?: string; description?: string }): string {
  const short = appleText(page.subtitle);
  if (short.length >= 40) return cutAtWord(short, 170);
  const first = appleText(page.description).split(/\n+/).find((l) => l.trim().length > 30) ?? '';
  return cutAtWord(first, 170);
}

/**
 * What the reviewer should know, in English: how to get in, what is paid and
 * how to restore it, why the tracking prompt appears. Written from the app itself.
 */
export function reviewNotesFor(input: { facts?: AppDataFacts; products?: AppleProduct[] }): string {
  const f = input.facts;
  const lines: string[] = [];
  lines.push(f?.account ? 'Sign-in is required for some features: use the demo account below.' : 'No account or login is needed: every screen is reachable from the first launch.');
  const subs = (input.products ?? []).filter((p) => p.kind === 'subscription');
  const once = (input.products ?? []).filter((p) => p.kind !== 'subscription');
  if (subs.length || once.length) {
    const list = [...subs, ...once].map((p) => `${p.name} (${p.productId}${p.freeTrial ? ', free trial' : ''})`).join('; ');
    lines.push(`Premium is sold through In-App Purchase: ${list}. Open the Premium screen to buy; "Restore" on the same screen restores previous purchases.`);
  }
  if (f?.ads && !f?.kids) lines.push('The app shows Google AdMob ads (none for Premium users). The App Tracking Transparency prompt appears before ads load; refusing it keeps every feature.');
  if (f?.kids) {
    // Apple asks every Kids category app these four questions (guideline 1.3): answer them up front.
    lines.push(
      'Kids Category (guideline 1.3): no third-party analytics; no third-party advertising on iOS (if an ads SDK is in the binary it is only for the shared Android code and is never initialized on iOS); no personal or device data is collected or shared with third parties, everything stays on the device; purchases and adult actions are behind a parental gate.',
    );
  } else {
    lines.push('All documents are processed on the device; nothing is uploaded to our servers.');
  }
  return lines.join('\n');
}

/**
 * Apple rejects store text that names other platforms (2.3.10), and the text
 * comes from the Google Play listing: drop the sentences that mention them.
 */
export function withoutOtherPlatforms(text: string): string {
  const other = /\b(android|google play|play store|play console|apk)\b/i;
  return text
    .split('\n')
    .map((line) => (other.test(line) ? line.split(/(?<=[.!?])\s+/).filter((s) => !other.test(s)).join(' ') : line))
    .filter((line, i, all) => line.trim() || (i > 0 && all[i - 1]!.trim()))
    .join('\n')
    .trim();
}

/** Little words that make weak keywords and bad subtitle endings. */
const STOP = new Set(
  (
    'with,your,into,from,that,this,them,they,have,need,more,just,also,only,what,will,than,then,when,every,make,made,' +
    'con,per,come,nella,nelle,della,delle,alla,dalla,tutto,tutti,ogni,anche,sono,senza,' +
    'para,como,todo,todos,sobre,sans,avec,pour,dans,tout,tous,votre,vous,mit,und,ohne,ihre,eure,' +
    'e,a,o,y,et,di,de,da,the,and,for,of,to,in,on,our,le,la,les,el,los,il,lo,gli,der,die,das,com,sem,और,में,के,की,का,लिए,إلى'
  ).split(','),
);

/** Other companies' names: Apple rejects them in keywords (guideline 2.3.7). */
const BRANDS = /^(instagram|insta|tiktok|whatsapp|facebook|youtube|snapchat|capcut|inshot|google|apple|iphone|ipad|android|twitter|telegram|reels?)$/i;

const words = (text: string) => text.toLowerCase().split(/[^\p{L}\p{M}\p{N}]+/u).filter(Boolean);

/** Text cut to [max] characters without breaking a word or ending on "and", "con", … */
export function cutAtWord(text: string, max: number): string {
  const t = text.trim();
  if ([...t].length <= max) return t;
  const parts = t.split(/\s+/);
  let out = '';
  for (const w of parts) {
    const next = out ? `${out} ${w}` : w;
    if ([...next].length > max) break;
    out = next;
  }
  if (!out) return [...t].slice(0, max).join('');
  const kept = out.split(' ');
  while (kept.length > 1 && (STOP.has(kept[kept.length - 1]!.toLowerCase()) || /^[&+,;:\-–—]+$/.test(kept[kept.length - 1]!))) kept.pop();
  return kept.join(' ').replace(/[\s,;:&+\-–—]+$/, '');
}

/**
 * Keywords are required by Apple. When the listing has none, the words of its
 * own subtitle and description are used: at most 100 characters, comma
 * separated, without the words Apple already indexes from the name, filler
 * words, or other companies' names.
 */
export function keywordsFrom(page: { title?: string; subtitle?: string; description?: string }): string {
  const inName = new Set(words(page.title ?? ''));
  const pool = words(`${page.subtitle ?? ''} ${page.description ?? ''}`).filter(
    (w) => [...w].length >= 3 && !inName.has(w) && !STOP.has(w) && !BRANDS.test(w) && !/^\d+$/.test(w),
  );
  const out: string[] = [];
  let len = 0;
  for (const w of pool) {
    if (out.includes(w)) continue;
    const add = (out.length ? 1 : 0) + [...w].length;
    if (len + add > 100) continue;
    out.push(w);
    len += add;
  }
  return out.join(',');
}

/**
 * What the app collects, in Apple's own words. Deliberately the same source as
 * Google's Data safety, so the two stores can never be told different things.
 */
export function privacyCategories(facts: AppDataFacts): Array<{ category: string; purpose: string; linked: boolean; tracking: boolean }> {
  const APPLE_PURPOSE: Record<Purpose, string> = { app: 'APP_FUNCTIONALITY', analytics: 'ANALYTICS', ads: 'THIRD_PARTY_ADVERTISING', account: 'APP_FUNCTIONALITY' };
  const out: Array<{ category: string; purpose: string; linked: boolean; tracking: boolean }> = [];
  const seen = new Set<string>();
  for (const d of declarations(facts)) {
    if (!d.apple) continue;
    for (const p of d.purposes) {
      const purpose = APPLE_PURPOSE[p];
      const id = `${d.apple}:${purpose}`;
      if (seen.has(id)) continue;
      seen.add(id);
      out.push({ category: d.apple, purpose, linked: d.linked, tracking: d.tracking });
    }
  }
  return out;
}

/**
 * The App Privacy answers for the browser extension, in App Store Connect's
 * ids: one entry per data type with its purposes, linked and tracking. An
 * empty list means "we do not collect data".
 */
export function applePrivacyPlan(facts: AppDataFacts): Array<{ category: string; label: string; purposes: string[]; linked: boolean; tracking: boolean }> {
  const byCategory = new Map<string, { category: string; label: string; purposes: string[]; linked: boolean; tracking: boolean }>();
  for (const row of privacyCategories(facts)) {
    const e = byCategory.get(row.category) ?? { category: row.category, label: declarations(facts).find((d) => d.apple === row.category)?.label ?? row.category, purposes: [], linked: false, tracking: false };
    if (!e.purposes.includes(row.purpose)) e.purposes.push(row.purpose);
    e.linked ||= row.linked;
    e.tracking ||= row.tracking;
    byCategory.set(row.category, e);
  }
  return [...byCategory.values()];
}

/**
 * The App Privacy answers in App Store Connect's own Italian words, one line
 * per data type: what to tick, the purposes, linked to the user, tracking.
 * Shown when the answers have to be given on the website.
 */
export function applePrivacyGuide(facts: AppDataFacts): string[] {
  const words: Record<Purpose, string> = { app: 'Funzionalità dell’app', analytics: 'Analisi', ads: 'Pubblicità di terze parti', account: 'Funzionalità dell’app' };
  const byLabel = new Map<string, DataDeclaration>();
  for (const d of declarations(facts)) if (d.apple && !byLabel.has(d.label)) byLabel.set(d.label, d);
  if (byLabel.size === 0) return ['"No, non raccogliamo dati da quest’app"'];
  return [...byLabel.values()].map(
    (d) => `${d.label}: ${[...new Set(d.purposes.map((p) => words[p]))].join(' + ')} · collegato all’identità: ${d.linked ? 'Sì' : 'No'} · monitoraggio: ${d.tracking ? 'Sì' : 'No'}`,
  );
}

/** The .ipa a finished iPhone build leaves behind. */
export async function findIpa(projectRoot: string): Promise<string | null> {
  const dir = path.join(projectRoot, 'build', 'ios', 'ipa');
  const files = await readdir(dir).catch(() => [] as string[]);
  // The newest file, not the last by name: the name changes with the app's name.
  const ipa = files.filter((f) => f.toLowerCase().endsWith('.ipa')).map((f) => path.join(dir, f));
  const dated = await Promise.all(ipa.map(async (f) => ({ f, t: (await stat(f).catch(() => null))?.mtimeMs ?? 0 })));
  dated.sort((a, b) => b.t - a.t);
  return dated[0]?.f ?? null;
}

function runTool(bin: string, args: string[], env?: Record<string, string>, timeoutMs = 30 * 60_000): Promise<{ code: number; out: string }> {
  return new Promise((resolve) => {
    const p = spawn(bin, args, { windowsHide: true, env: env ? { ...process.env, ...env } : process.env });
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
  run: (bin: string, args: string[], env?: Record<string, string>) => Promise<{ code: number; out: string }> = runTool,
  platform = process.platform,
): Promise<{ uploaded: boolean; output: string }> {
  if (platform !== 'darwin') {
    throw new AppStoreError('needs_mac', 'Only a Mac can send the app to Apple. Open Ember on your Mac, take the app back from GitHub and upload from there.');
  }
  // altool reads the key only from a file named AuthKey_<id>.p8 in a folder it
  // searches (~/.appstoreconnect/private_keys, …) or in $API_PRIVATE_KEYS_DIR.
  // Ember keeps its key elsewhere, so hand altool a private copy for this upload.
  const dir = await mkdtemp(path.join(os.tmpdir(), 'ember-asc-'));
  try {
    await chmod(dir, 0o700).catch(() => {});
    await writeFile(path.join(dir, `AuthKey_${key.keyId}.p8`), key.privateKey.endsWith('\n') ? key.privateKey : `${key.privateKey}\n`, { mode: 0o600 });
    const res = await run('xcrun', ['altool', '--upload-app', '-f', ipaPath, '-t', 'ios', '--apiKey', key.keyId, '--apiIssuer', key.issuerId], {
      API_PRIVATE_KEYS_DIR: dir,
    });
    // Publishing again after a later step failed: Apple already has this build.
    if (res.code !== 0 && /redundant binary upload|already been uploaded|bundle version must be higher|ENTITY_ERROR\.ATTRIBUTE\.INVALID\.DUPLICATE/i.test(res.out)) {
      return { uploaded: true, output: res.out.slice(-2000) };
    }
    if (res.code !== 0) throw new AppStoreError('upload_failed', `Apple refused the upload: ${res.out.slice(-500)}`);
    return { uploaded: true, output: res.out.slice(-2000) };
  } finally {
    await rm(dir, { recursive: true, force: true }).catch(() => {});
  }
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
  /** Kids category age band (Made for Kids), when the app is for children. */
  kidsAgeBand?: AgeRatingDeclaration['kidsAgeBand'];
  /** Age-rating answers. Defaults to 4+ when omitted. */
  ageRating?: AgeRatingDeclaration;
  /** App Store category id, e.g. "UTILITIES", "PRODUCTIVITY". */
  category?: string;
  secondaryCategory?: string;
  /** Who Apple can contact for review, and an optional demo login. */
  review?: AppReviewDetails;
  /** Make the app free in every territory. */
  free?: boolean;
  /** Generate iPhone/iPad screenshots from the web preview and upload them. */
  screenshots?: { previewUrl: string; browser: string; count?: number };
  /** In-app purchases and subscriptions to create (or complete) on Apple. */
  products?: AppleProduct[];
  /** Developer website on every store page (Marketing URL): AdMob reads app-ads.txt there. */
  marketingUrl?: string;
  /** The purchase screen, for the reviewer of those products. */
  productScreenshot?: Buffer;
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
  /** Build number Apple is still processing, when the review has to wait for it. */
  waitingForBuild: number | null;
  submitted: boolean;
  /** The extra iOS chores Ember now fills so you do not have to. */
  ageRated: boolean;
  categorized: boolean;
  reviewInfoSet: boolean;
  exportCompliance: boolean;
  pricedFree: boolean;
  /** Screenshots uploaded per device size, e.g. { APP_IPHONE_67: 8 }. */
  screenshots: Record<string, number>;
  /** Apple product ids created or completed this run. */
  products: string[];
  notes: string[];
}

/**
 * Everything Ember can do on Apple without a human: upload the build, write the
 * store page in every language, set the privacy answers, attach the build and
 * send it for review.
 */
export async function publishToAppStore(input: AppStorePublishInput, fetchImpl: Fetch = fetch): Promise<AppStorePublishResult> {
  const store = await AppStore.open(input.key, fetchImpl);
  const app = await store.findApp(input.bundleId).catch(async (e: unknown) => {
    // Half the way there by itself: the Bundle ID the app will need is registered now.
    if (e instanceof AppStoreError && e.code === 'app_not_found') {
      await store.ensureBundleId(input.bundleId, input.listing?.title ?? input.bundleId).catch(() => null);
    }
    throw e;
  });
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
    // Apple will not send a version for review without a support page: the
    // privacy page carries the contact address, so it stands in for one.
    await store.writeVersionPage(version.id, {
      ...page,
      supportUrl: page.supportUrl || input.privacyPolicyUrl || undefined,
      // AdMob checks app-ads.txt on the developer website of the store listing.
      marketingUrl: page.marketingUrl || input.marketingUrl || undefined,
      // The line at the top of the page, changeable without a review: the short pitch.
      promotionalText: page.promotionalText || promotionalFrom(page),
    });
    await store.writeAppPage(app.id, { ...page, privacyPolicyUrl: input.privacyPolicyUrl });
  }

  // Apple's public API has no App Privacy endpoint (appDataUsages is refused),
  // so the privacy answers may have to be given once on the website: say what
  // to answer instead of stopping the whole publish.
  let privacy: { collects: boolean; categories: string[] } | null = null;
  if (input.facts) {
    try {
      privacy = await store.writePrivacy(app.id, input.facts);
    } catch (e) {
      if (!(e instanceof AppStoreError)) throw e;
      notes.push(`Privacy dell’app: compilala una volta su App Store Connect → Privacy dell’app → Inizia. Risposte: ${applePrivacyGuide(input.facts).join(' | ')}`);
    }
  }

  // ---- In-app purchases and subscriptions, same prices as on Google Play ----
  let products: string[] = [];
  if (input.products?.length) {
    products = await ensureAppleProducts(store, { appId: app.id, products: input.products, reviewScreenshot: input.productScreenshot }).catch((e: unknown) => {
      notes.push(`Abbonamenti/acquisti non creati su Apple: ${(e as Error).message}`);
      return [];
    });
  }

  // ---- The chores that used to be filled by hand in App Store Connect ----

  // Encryption question, answered once in the app itself (iOS Info.plist).
  const exportCompliance = await setIosExportCompliance(input.projectRoot).catch(() => false);

  // Age-rating questionnaire (defaults to 4+).
  let ageRated = false;
  await store.setAgeRating(app.id, input.ageRating ?? ageRating4Plus(input.facts, input.kidsAgeBand)).then(
    () => (ageRated = true),
    (e: unknown) => notes.push(`Fascia d'età non impostata: ${(e as Error).message}`),
  );

  // Copyright and content rights: without them Apple refuses the review.
  const holder = await store.accountHolder().catch(() => null);
  const owner = [holder?.firstName, holder?.lastName].filter(Boolean).join(' ') || app.name;
  await store
    .setRightsAndCopyright(app.id, version.id, `${new Date().getFullYear()} ${owner}`, await shipsThirdPartyMedia(input.projectRoot))
    .catch((e: unknown) => notes.push(`Copyright / diritti sui contenuti non impostati: ${(e as Error).message}`));

  // Store category.
  let categorized = false;
  if (input.category) {
    await store.setCategories(app.id, input.category, input.secondaryCategory).then(
      () => (categorized = true),
      (e: unknown) => notes.push(`Categoria non impostata: ${(e as Error).message}`),
    );
  }

  // Reviewer contact / demo login.
  let reviewInfoSet = false;
  if (input.review) {
    // Apple wants a first and last name: the account holder's, unless given.
    const review = { ...input.review };
    if (!review.firstName || !review.lastName) {
      const holder = await store.accountHolder().catch(() => null);
      review.firstName ||= holder?.firstName;
      review.lastName ||= holder?.lastName;
      review.email ||= holder?.email;
    }
    review.notes ||= reviewNotesFor({ facts: input.facts, products: input.products });
    if (!review.phone) notes.push('Info per la revisione: manca il numero di telefono del contatto (Dati per la revisione → Telefono, con prefisso, es. +39 333 1234567).');
    await store.setReviewDetails(version.id, review).then(
      () => (reviewInfoSet = true),
      (e: unknown) => notes.push(`Info per la revisione non salvate: ${(e as Error).message}`),
    );
  }

  // Price = free, everywhere (best-effort).
  let pricedFree = false;
  if (input.free) {
    await store.setFreePrice(app.id).then(
      () => (pricedFree = true),
      (e: unknown) => notes.push(`Prezzo gratuito non impostato: ${(e as Error).message}`),
    );
  }

  // iPhone/iPad screenshots, generated from the web preview and uploaded to
  // every language of the store page.
  const screenshots: Record<string, number> = {};
  if (input.screenshots) {
    try {
      const byType = await captureAppleScreenshots({ previewUrl: input.screenshots.previewUrl, browser: input.screenshots.browser, count: input.screenshots.count });
      const locs = [...(await store.versionLocalizations(version.id)).values()];
      for (const [type, buffers] of byType) {
        const images = buffers.map((bytes, i) => ({ fileName: `${type}_${i + 1}.png`, bytes }));
        let uploaded = 0;
        for (const locId of locs) uploaded += await store.putScreenshots(locId, type, images).catch(() => 0);
        screenshots[type] = uploaded;
      }
      if (Object.keys(screenshots).length === 0) notes.push('Nessuno screenshot catturato: l’app ha la "modalità screenshot" e l’anteprima web è pronta?');
    } catch (e) {
      notes.push(`Screenshot non caricati: ${(e as Error).message}`);
    }
  }

  let buildAttached = false;
  let waitingForBuild: number | null = null;
  const expected = await projectBuildNumber(input.projectRoot);
  const build = await store.latestBuild(app.id).catch(() => null);
  if (build && Number(build.version) < expected) {
    // Apple lists a new build only minutes after the upload. Never fall back on an older one.
    if (input.uploadBuild) waitingForBuild = expected;
    notes.push(
      input.uploadBuild
        ? `La build ${expected} è appena arrivata ad Apple e la stanno elaborando (10-20 minuti): premi di nuovo Publish dopo, per collegarla e inviarla in revisione.`
        : `Su Apple c'è solo la build ${build.version}, l'app è alla ${expected}: attiva "Send the iPhone file too" e premi di nuovo Publish.`,
    );
  } else if (build && build.state !== 'VALID') {
    waitingForBuild = Number(build.version) || expected;
    notes.push(`La build ${build.version} è ancora in elaborazione da Apple (${build.state}): premi di nuovo Publish tra qualche minuto.`);
  } else if (build) {
    await store.attachBuild(version.id, build.id).then(
      () => (buildAttached = true),
      (e: unknown) => notes.push(`Build non collegata: ${(e as Error).message}`),
    );
  } else if (input.uploadBuild) {
    waitingForBuild = expected;
    notes.push(`La build ${expected} è appena arrivata ad Apple e la stanno elaborando (10-20 minuti): premi di nuovo Publish dopo, per collegarla e inviarla in revisione.`);
  } else {
    notes.push('No build on Apple yet for this app.');
  }

  let submitted = false;
  if (input.submit && buildAttached) {
    await store.waitForScreenshots(version.id).catch(() => 0);
    // An app's first purchases are reviewed with the version: added while it is in the submission.
    const withProducts = () =>
      submitProductsWithVersion(store, app.id).then(
        (sent) => sent.length && notes.push(`Inviati in revisione con la versione: ${sent.join(', ')}`),
        (e: unknown) => {
          // Never send the app without its purchases: the reviewer would find an empty paywall.
          notes.push(`Abbonamenti non accettati da Apple via API: su App Store Connect premi EMBER → "Invia in revisione". (${(e as Error).message})`);
          throw e;
        },
      );
    await store.submitForReview(version.id, app.id, withProducts).then(
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
    waitingForBuild,
    products,
    submitted,
    ageRated,
    categorized,
    reviewInfoSet,
    exportCompliance,
    pricedFree,
    screenshots,
    notes,
  };
}

/** The version string ("1.0.0") from the project's pubspec. */
export interface FinishInput {
  key: AppStoreKey;
  appId: string;
  versionId: string;
  /** The build to wait for: an older, already processed one is never used. */
  buildNumber: number;
  submit: boolean;
  /** Told what is happening, e.g. to show it in the IDE. */
  onProgress?: (message: string) => void;
  signal?: AbortSignal;
  pollMs?: number;
  timeoutMs?: number;
}

/**
 * Waits until Apple has processed [buildNumber] (usually 5-20 minutes after
 * the upload), then attaches it to the version and sends it for review.
 * This is the step that used to need a second press of Publish.
 */
export async function finishWhenBuildReady(input: FinishInput, fetchImpl: Fetch = fetch): Promise<{ attached: boolean; submitted: boolean }> {
  const pollMs = input.pollMs ?? 30_000;
  const deadline = Date.now() + (input.timeoutMs ?? 90 * 60_000);
  const started = Date.now();
  const sleep = (ms: number) =>
    new Promise<void>((resolve, reject) => {
      const t = setTimeout(resolve, ms);
      input.signal?.addEventListener('abort', () => (clearTimeout(t), reject(new Error('annullato'))), { once: true });
    });
  for (;;) {
    if (input.signal?.aborted) throw new Error('annullato');
    // A fresh token each round: the wait can outlast one (they live 20 minutes).
    const store = await AppStore.open(input.key, fetchImpl);
    const build = await store.latestBuild(input.appId).catch(() => null);
    const minutes = Math.round((Date.now() - started) / 60_000);
    if (build && Number(build.version) >= input.buildNumber) {
      if (build.state === 'VALID') {
        input.onProgress?.(`Build ${build.version} pronta: la collego alla versione`);
        await store.attachBuild(input.versionId, build.id);
        if (!input.submit) return { attached: true, submitted: false };
        input.onProgress?.('Aspetto che Apple finisca gli screenshot');
        await store.waitForScreenshots(input.versionId).catch(() => 0);
        input.onProgress?.('Invio in revisione');
        await store.submitForReview(input.versionId, input.appId, () =>
          submitProductsWithVersion(store, input.appId).then(
            (sent) => sent.length && input.onProgress?.(`Acquisti inviati con la versione: ${sent.join(', ')}`),
            (e: unknown) => {
              throw new AppStoreError('products_refused', `Abbonamenti non accettati da Apple via API: su App Store Connect premi EMBER → "Invia in revisione". (${(e as Error).message})`);
            },
          ),
        );
        return { attached: true, submitted: true };
      }
      if (build.state === 'INVALID' || build.state === 'FAILED') {
        throw new AppStoreError('build_invalid', `Apple ha scartato la build ${build.version} (${build.state}): controlla l’email di Apple per il motivo.`);
      }
      input.onProgress?.(`Apple sta elaborando la build ${build.version} (${minutes} min)`);
    } else {
      input.onProgress?.(`Aspetto che la build ${input.buildNumber} compaia su Apple (${minutes} min)`);
    }
    if (Date.now() > deadline) {
      throw new AppStoreError('build_timeout', `Dopo ${minutes} minuti Apple non ha ancora pronta la build ${input.buildNumber}: riprova più tardi con Publish.`);
    }
    await sleep(pollMs);
  }
}

/**
 * True when the app bundles media it did not make itself (music, sounds,
 * videos, stock images): Apple asks to declare it before the review.
 */
export async function shipsThirdPartyMedia(projectRoot: string): Promise<boolean> {
  const pubspec = await readFile(path.join(projectRoot, 'pubspec.yaml'), 'utf8').catch(() => '');
  if (/audioplayers|just_audio|royalty/i.test(pubspec)) return true;
  const walk = async (dir: string): Promise<boolean> => {
    for (const e of await readdir(dir, { withFileTypes: true }).catch(() => [])) {
      const p = path.join(dir, e.name);
      if (e.isDirectory() ? await walk(p) : /\.(mp3|m4a|aac|wav|ogg|mp4|mov)$/i.test(e.name)) return true;
    }
    return false;
  };
  return walk(path.join(projectRoot, 'assets'));
}

/** The build number after "+" in pubspec (1.0.0+11 → 11), 0 when missing. */
export async function projectBuildNumber(projectRoot: string): Promise<number> {
  const pubspec = await readFile(path.join(projectRoot, 'pubspec.yaml'), 'utf8').catch(() => '');
  return Number(/^version:\s*[0-9.]+\+([0-9]+)/m.exec(pubspec)?.[1] ?? 0);
}

export async function projectVersion(projectRoot: string): Promise<string> {
  const pubspec = await readFile(path.join(projectRoot, 'pubspec.yaml'), 'utf8').catch(() => '');
  return /^version:\s*([0-9]+\.[0-9]+\.[0-9]+)/m.exec(pubspec)?.[1] ?? '1.0.0';
}
