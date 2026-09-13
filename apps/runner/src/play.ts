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
  releaseNotes?: { language: string; text: string };
  contactEmail?: string;
}

export interface PublishResult {
  editId: string;
  versionCode: number;
  track: PlayTrack;
  status: ReleaseStatus;
  /** True when Google required a draft release because the app was never published. */
  downgradedToDraft: boolean;
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

  const aab = await readFile(input.aabPath);
  const upload = await fetchImpl(`${UPLOAD}/${pkg}/edits/${encodeURIComponent(editId)}/bundles?uploadType=media`, {
    method: 'POST',
    headers: { ...auth, 'content-type': 'application/octet-stream' },
    body: aab,
    signal: AbortSignal.timeout(10 * 60_000),
  });
  if (!upload.ok) throw await googleError(upload);
  const bundle = (await upload.json()) as { versionCode?: number };
  if (typeof bundle.versionCode !== 'number') throw new PlayError('play_api_error', 'Google Play did not return a versionCode for the bundle');

  if (input.listing && (input.listing.title || input.listing.shortDescription || input.listing.fullDescription)) {
    const l = input.listing;
    await json('PUT', `${base}/listings/${encodeURIComponent(l.language)}`, {
      language: l.language,
      ...(l.title ? { title: l.title.slice(0, 30) } : {}),
      ...(l.shortDescription ? { shortDescription: l.shortDescription.slice(0, 80) } : {}),
      ...(l.fullDescription ? { fullDescription: l.fullDescription.slice(0, 4000) } : {}),
    });
  }
  if (input.contactEmail) {
    await json('PATCH', `${base}/details`, { contactEmail: input.contactEmail });
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
  const commit = async () => {
    await json('PUT', `${base}/tracks/${input.track}`, release(status));
    await json('POST', `${base}:commit`);
  };
  try {
    await commit();
  } catch (e) {
    // Apps that were never published only accept draft releases.
    if (status !== 'draft' && e instanceof PlayError && /draft/i.test(e.message)) {
      status = 'draft';
      downgradedToDraft = true;
      await commit();
    } else {
      throw e;
    }
  }
  return { editId, versionCode: bundle.versionCode, track: input.track, status, downgradedToDraft };
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
