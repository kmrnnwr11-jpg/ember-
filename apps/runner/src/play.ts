import { readFile } from 'node:fs/promises';
import { importPKCS8, SignJWT } from 'jose';

/**
 * Google Play Developer API (Android Publisher v3) client: upload an AAB,
 * update the store listing and create a release on a track, in one edit.
 * Auth uses the user's own service account JSON (never stored by the Runner).
 */

export const PLAY_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const API = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';
const UPLOAD = 'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications';
/** One piece of a big bundle (Google wants multiples of 256 KB). */
const CHUNK = 8 * 1024 * 1024;

export interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

export class PlayError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly status?: number,
  ) {
    super(message);
  }
}

export function parseServiceAccount(raw: string): ServiceAccount {
  let j: Record<string, unknown>;
  try {
    j = JSON.parse(raw) as Record<string, unknown>;
  } catch {
    throw new PlayError('bad_request', 'The service account key is not valid JSON');
  }
  if (j.type !== 'service_account' || typeof j.client_email !== 'string' || typeof j.private_key !== 'string') {
    throw new PlayError('bad_request', 'This is not a Google service account key (expected type "service_account" with client_email and private_key)');
  }
  return { client_email: j.client_email, private_key: j.private_key, token_uri: typeof j.token_uri === 'string' ? j.token_uri : undefined };
}

export type PlayTrack = 'internal' | 'alpha' | 'beta' | 'production';
export type ReleaseStatus = 'draft' | 'completed';

export interface PlayListing {
  language: string;
  title?: string;
  shortDescription?: string;
  fullDescription?: string;
}

export interface PublishInput {
  serviceAccount: ServiceAccount;
  packageName: string;
  aabPath: string;
  track: PlayTrack;
  status: ReleaseStatus;
  listing?: PlayListing;
  /**
   * The same listing in other languages. Each one becomes its own store page
   * on Google Play, so a user in Madrid or Cairo reads the app in their tongue.
   */
  translations?: PlayListing[];
  releaseNotes?: { language: string; text: string };
  contactEmail?: string;
  /** Store graphics (PNG paths): replaced on every upload when present. */
  images?: { icon?: string; featureGraphic?: string; phoneScreenshots?: string[] };
  /** Only the store page (texts, languages, graphics): no new bundle, no release. */
  listingOnly?: boolean;
}

export interface PublishResult {
  editId: string;
  versionCode: number;
  track: PlayTrack;
  status: ReleaseStatus;
  /** True when Google required a draft release because the app was never published. */
  downgradedToDraft: boolean;
  /** True when Google would not auto-send the changes for review (new app): committed, but the
   * user must press "Send for review" once in the Play Console. */
  reviewNotSent: boolean;
  /** Listing languages written and graphics uploaded, so the client can say exactly what changed. */
  uploaded: { languages: string[]; listing: boolean; icon: boolean; featureGraphic: boolean; screenshots: number; skipped?: string[] };
}

type Fetch = typeof fetch;

async function googleError(res: Response): Promise<PlayError> {
  let message = `${res.status} ${res.statusText}`;
  try {
    const j = (await res.json()) as { error?: { message?: string } ; error_description?: string };
    message = j.error?.message ?? j.error_description ?? message;
  } catch {
    // keep status text
  }
  if (res.status === 404) {
    return new PlayError('play_app_not_found', `Google Play: app not found. Create the app in Play Console with this exact package name first. (${message})`, 404);
  }
  // Play reports a reused version code as 403; say what it really is.
  const used = /version\s*code\s*(\d+)\s*has already been used/i.exec(message);
  if (used) {
    return new PlayError(
      'version_code_used',
      `Google Play already has version ${used[1]} of this app. Build a new AAB: Ember raises the version number and uploads it.`,
      res.status,
    );
  }
  if (res.status === 401 || res.status === 403) {
    return new PlayError(
      'play_permission',
      `Google Play: permission denied. Invite the service account in Play Console → Users and permissions with release permissions for this app, then wait a few minutes. (${message})`,
      res.status,
    );
  }
  return new PlayError('play_api_error', `Google Play: ${message}`, res.status);
}

export async function getAccessToken(sa: ServiceAccount, fetchImpl: Fetch = fetch): Promise<string> {
  const tokenUri = sa.token_uri ?? 'https://oauth2.googleapis.com/token';
  let key;
  try {
    key = await importPKCS8(sa.private_key, 'RS256');
  } catch {
    throw new PlayError('bad_request', 'The service account private_key cannot be read');
  }
  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({ scope: PLAY_SCOPE })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience(tokenUri)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);
  const res = await fetchImpl(tokenUri, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }).toString(),
  });
  if (!res.ok) throw await googleError(res);
  const j = (await res.json()) as { access_token?: string };
  if (!j.access_token) throw new PlayError('play_api_error', 'Google did not return an access token');
  return j.access_token;
}

export async function publishToPlay(input: PublishInput, fetchImpl: Fetch = fetch): Promise<PublishResult> {
  const token = await getAccessToken(input.serviceAccount, fetchImpl);
  const auth = { authorization: `Bearer ${token}` };
  const pkg = encodeURIComponent(input.packageName);
  const json = async (method: string, url: string, body?: unknown) => {
    const res = await fetchImpl(url, {
      method,
      headers: { ...auth, ...(body !== undefined ? { 'content-type': 'application/json' } : {}) },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    if (!res.ok) throw await googleError(res);
    const text = await res.text();
    return (text ? JSON.parse(text) : {}) as Record<string, unknown>;
  };

  const edit = await json('POST', `${API}/${pkg}/edits`, {});
  const editId = String(edit.id);
  const base = `${API}/${pkg}/edits/${encodeURIComponent(editId)}`;

  // Only the store page: the app already published stays as it is.
  const bundle: { versionCode?: number } = input.listingOnly ? { versionCode: 0 } : await uploadBundle();
  async function uploadBundle(): Promise<{ versionCode?: number }> {
  const aab = await readFile(input.aabPath);
  // A big bundle in one request outlives the 5 minutes Node waits for an answer:
  // it goes in pieces, and a dropped piece resumes where Google stopped receiving.
  if (aab.length > CHUNK) return uploadBundleInPieces(aab);
  // A bundle is tens of megabytes: on a slow uplink the connection can die mid-way, so try again.
  let upload: Response | null = null;
  let networkError: Error | null = null;
  for (let attempt = 0; attempt < 3 && !upload; attempt++) {
    try {
      upload = await fetchImpl(`${UPLOAD}/${pkg}/edits/${encodeURIComponent(editId)}/bundles?uploadType=media`, {
        method: 'POST',
        headers: { ...auth, 'content-type': 'application/octet-stream' },
        body: aab,
        signal: AbortSignal.timeout(30 * 60_000),
      });
    } catch (e) {
      networkError = e as Error;
      await new Promise((r) => setTimeout(r, 3000));
    }
  }
  if (!upload) {
    throw new PlayError(
      'upload_interrupted',
      `The connection dropped while sending the ${Math.round(aab.length / 1_000_000)} MB bundle to Google (${networkError?.message ?? 'network error'}). Nothing was published: try again on a steadier connection.`,
    );
  }
  if (!upload.ok) throw await googleError(upload);
  const uploadedBundle = (await upload.json()) as { versionCode?: number };
  if (typeof uploadedBundle.versionCode !== 'number') throw new PlayError('play_api_error', 'Google Play did not return a versionCode for the bundle');
  return uploadedBundle;
  }

  async function uploadBundleInPieces(aab: Buffer): Promise<{ versionCode?: number }> {
    const total = aab.length;
    const interrupted = (why: string) =>
      new PlayError(
        'upload_interrupted',
        `The connection dropped while sending the ${Math.round(total / 1_000_000)} MB bundle to Google (${why}). Nothing was published: try again on a steadier connection.`,
      );
    const start = await fetchImpl(`${UPLOAD}/${pkg}/edits/${encodeURIComponent(editId)}/bundles?uploadType=resumable`, {
      method: 'POST',
      headers: { ...auth, 'x-upload-content-type': 'application/octet-stream', 'x-upload-content-length': String(total) },
    });
    if (!start.ok) throw await googleError(start);
    const session = start.headers.get('location');
    if (!session) throw new PlayError('play_api_error', 'Google Play did not open an upload session for the bundle');

    // How far Google got, from the Range header of a 308 answer.
    const received = (res: Response) => {
      const m = /bytes=0-(\d+)/.exec(res.headers.get('range') ?? '');
      return m ? Number(m[1]) + 1 : 0;
    };
    let offset = 0;
    let failures = 0;
    while (true) {
      const end = Math.min(offset + CHUNK, total);
      let res: Response;
      try {
        res = await fetchImpl(session, {
          method: 'PUT',
          headers: { 'content-range': `bytes ${offset}-${end - 1}/${total}` },
          body: aab.subarray(offset, end) as unknown as BodyInit,
          signal: AbortSignal.timeout(4 * 60_000),
        });
      } catch (e) {
        if (++failures > 8) throw interrupted((e as Error).message || 'network error');
        await new Promise((r) => setTimeout(r, 3000));
        try {
          const ask = await fetchImpl(session, { method: 'PUT', headers: { 'content-range': `bytes */${total}` } });
          if (ask.status === 308) offset = received(ask);
          else if (ask.ok) res = ask;
          else continue;
        } catch {
          continue;
        }
        if (!res!) continue;
      }
      if (res.status === 308) {
        offset = received(res) || end;
        failures = 0;
        continue;
      }
      if (!res.ok) throw await googleError(res);
      const uploadedBundle = (await res.json()) as { versionCode?: number };
      if (typeof uploadedBundle.versionCode !== 'number') throw new PlayError('play_api_error', 'Google Play did not return a versionCode for the bundle');
      return uploadedBundle;
    }
  }

  // The main store listing is the app's DEFAULT language: write there too, otherwise Play Console shows it empty.
  const details = await json('GET', `${base}/details`).catch(() => ({}) as Record<string, unknown>);
  const defaultLanguage = typeof details.defaultLanguage === 'string' ? details.defaultLanguage : undefined;
  const languages = [...new Set([defaultLanguage, input.listing?.language].filter((x): x is string => !!x))];
  const uploaded = { languages: [] as string[], listing: false, icon: false, featureGraphic: false, screenshots: 0 };

  // One page per language. The main listing fills the default language too (or
  // Play Console shows it empty), but a real translation for that language wins:
  // an English store page must not carry the Italian text.
  const pages = new Map<string, PlayListing>();
  const hasText = (l?: PlayListing) => !!l && !!(l.title || l.shortDescription || l.fullDescription);
  if (hasText(input.listing)) for (const lang of languages) pages.set(lang, input.listing!);
  for (const t of input.translations ?? []) if (t.language && hasText(t)) pages.set(t.language, t);

  const skippedLanguages: string[] = [];
  for (const [lang, l] of pages) {
    try {
      await json('PUT', `${base}/listings/${encodeURIComponent(lang)}`, {
        language: lang,
        ...(l.title ? { title: l.title.slice(0, 30) } : {}),
        ...(l.shortDescription ? { shortDescription: l.shortDescription.slice(0, 80) } : {}),
        ...(l.fullDescription ? { fullDescription: l.fullDescription.slice(0, 4000) } : {}),
      });
    } catch (e) {
      // A language Google refuses for this app is skipped; the main page never is.
      if (lang === languages[0]) throw e;
      skippedLanguages.push(lang);
      continue;
    }
    uploaded.languages.push(lang);
    uploaded.listing = true;
  }
  if (skippedLanguages.length > 0) (uploaded as { skipped?: string[] }).skipped = skippedLanguages;
  if (input.contactEmail) {
    await json('PATCH', `${base}/details`, { contactEmail: input.contactEmail });
  }

  // Icon, feature graphic and phone screenshots for the listing language.
  const images = input.images;
  if (images && languages.length > 0 && uploaded.listing) {
    const put = async (lang: string, type: string, files: string[]) => {
      if (files.length === 0) return 0;
      await json('DELETE', `${base}/listings/${encodeURIComponent(lang)}/${type}`);
      for (const f of files) {
        const res = await fetchImpl(`${UPLOAD}/${pkg}/edits/${encodeURIComponent(editId)}/listings/${encodeURIComponent(lang)}/${type}?uploadType=media`, {
          method: 'POST',
          headers: { ...auth, 'content-type': 'image/png' },
          body: await readFile(f),
        });
        if (!res.ok) throw await googleError(res);
      }
      return files.length;
    };
    for (const lang of languages) {
      uploaded.icon = (await put(lang, 'icon', images.icon ? [images.icon] : [])) > 0 || uploaded.icon;
      uploaded.featureGraphic = (await put(lang, 'featureGraphic', images.featureGraphic ? [images.featureGraphic] : [])) > 0 || uploaded.featureGraphic;
      uploaded.screenshots = Math.max(uploaded.screenshots, await put(lang, 'phoneScreenshots', (images.phoneScreenshots ?? []).slice(0, 8)));
    }
  }

  const release = (status: ReleaseStatus) => ({
    track: input.track,
    releases: [
      {
        versionCodes: [String(bundle.versionCode)],
        status,
        ...(input.releaseNotes?.text ? { releaseNotes: [{ language: input.releaseNotes.language, text: input.releaseNotes.text.slice(0, 500) }] } : {}),
      },
    ],
  });

  let status = input.status;
  let downgradedToDraft = false;
  let reviewNotSent = false;
  const commit = async (notSentForReview = false) => {
    if (!input.listingOnly) await json('PUT', `${base}/tracks/${input.track}`, release(status));
    // New apps (never reviewed) cannot be auto-submitted; Google requires this flag, then the
    // user sends for review once from the Play Console UI.
    await json('POST', `${base}:commit${notSentForReview ? '?changesNotSentForReview=true' : ''}`);
  };
  try {
    await commit();
  } catch (e) {
    // Apps that were never published only accept draft releases.
    if (status !== 'draft' && e instanceof PlayError && /draft/i.test(e.message)) {
      status = 'draft';
      downgradedToDraft = true;
      try {
        await commit();
      } catch (e2) {
        if (e2 instanceof PlayError && /changesNotSentForReview/i.test(e2.message)) {
          reviewNotSent = true;
          await commit(true);
        } else {
          throw e2;
        }
      }
    } else if (e instanceof PlayError && /changesNotSentForReview/i.test(e.message)) {
      // First-time app: commit without auto-review, user submits from the Console.
      reviewNotSent = true;
      await commit(true);
    } else {
      throw e;
    }
  }
  return { editId, versionCode: bundle.versionCode ?? 0, track: input.track, status, downgradedToDraft, reviewNotSent, uploaded };
}

/** Minimal, safe Markdown → HTML for hosted privacy policies (headings, lists, bold, links, paragraphs). */
export function privacyHtml(title: string, markdown: string): string {
  const esc = (s: string) => s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
  const inline = (s: string) =>
    esc(s)
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g, '<a href="$2" rel="nofollow noopener">$1</a>');
  const out: string[] = [];
  let list = false;
  for (const raw of markdown.split(/\r?\n/)) {
    const line = raw.trimEnd();
    const li = /^\s*[-*]\s+(.*)$/.exec(line);
    if (li) {
      if (!list) out.push('<ul>');
      list = true;
      out.push(`<li>${inline(li[1]!)}</li>`);
      continue;
    }
    if (list) {
      out.push('</ul>');
      list = false;
    }
    const h = /^(#{1,3})\s+(.*)$/.exec(line);
    if (h) out.push(`<h${h[1]!.length}>${inline(h[2]!)}</h${h[1]!.length}>`);
    else if (line.trim()) out.push(`<p>${inline(line)}</p>`);
  }
  if (list) out.push('</ul>');
  return `<!doctype html><html lang="it"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${esc(title)}</title><style>body{font-family:system-ui,sans-serif;max-width:760px;margin:0 auto;padding:24px;line-height:1.6;color:#222}h1,h2,h3{line-height:1.25}a{color:#1a73e8}</style></head><body>${out.join('\n')}</body></html>`;
}
