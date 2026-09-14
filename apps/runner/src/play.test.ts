import { generateKeyPairSync } from 'node:crypto';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { parseServiceAccount, PlayError, privacyHtml, publishToPlay } from './play.js';

const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const pem = privateKey.export({ type: 'pkcs8', format: 'pem' }).toString();
const saJson = JSON.stringify({ type: 'service_account', client_email: 'pub@proj.iam.gserviceaccount.com', private_key: pem });

interface Call {
  method: string;
  url: string;
  body?: unknown;
}

function fakeGoogle(opts: { draftOnly?: boolean; missingApp?: boolean } = {}) {
  const calls: Call[] = [];
  const impl = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    const method = init?.method ?? 'GET';
    const body = typeof init?.body === 'string' && init.body.startsWith('{') ? JSON.parse(init.body) : init?.body;
    calls.push({ method, url, body });
    const ok = (j: unknown) => new Response(JSON.stringify(j), { status: 200, headers: { 'content-type': 'application/json' } });
    if (url.includes('oauth2.googleapis.com/token')) return ok({ access_token: 'ya29.test' });
    if (opts.missingApp && url.endsWith('/edits')) return new Response(JSON.stringify({ error: { message: 'Package not found' } }), { status: 404 });
    if (url.endsWith('/edits')) return ok({ id: 'edit123' });
    if (url.endsWith('/details') && (init?.method ?? 'GET') === 'GET') return ok({ defaultLanguage: 'en-US' });
    if (url.includes('/bundles?uploadType=media')) return ok({ versionCode: 7, sha256: 'x' });
    if (url.includes('/tracks/')) {
      const status = (body as { releases: Array<{ status: string }> }).releases[0]!.status;
      if (opts.draftOnly && status !== 'draft') {
        return new Response(JSON.stringify({ error: { message: 'Only releases with status draft may be created on draft app.' } }), { status: 400 });
      }
      return ok(body);
    }
    return ok({});
  }) as typeof fetch;
  return { calls, impl };
}

describe('Google Play publishing', () => {
  let tmp = '';
  let aab = '';
  beforeAll(async () => {
    tmp = await mkdtemp(path.join(os.tmpdir(), 'fc-play-'));
    aab = path.join(tmp, 'app-release.aab');
    await writeFile(aab, 'PK-fake-aab');
  });
  afterAll(() => rm(tmp, { recursive: true, force: true }));

  it('validates service account JSON', () => {
    expect(parseServiceAccount(saJson).client_email).toContain('@');
    expect(() => parseServiceAccount('nope')).toThrow(PlayError);
    expect(() => parseServiceAccount('{"type":"authorized_user"}')).toThrow(/service account/);
  });

  it('runs edit → upload → listing → track → commit with a signed JWT', async () => {
    const g = fakeGoogle();
    const r = await publishToPlay(
      {
        serviceAccount: parseServiceAccount(saJson),
        packageName: 'dev.fluttercursor.app.chat',
        aabPath: aab,
        track: 'internal',
        status: 'completed',
        listing: { language: 'it-IT', title: 'Chat Amici con un titolo troppo lungo', shortDescription: 'Chatta', fullDescription: 'Lunga' },
        releaseNotes: { language: 'it-IT', text: 'Prima versione' },
      },
      g.impl,
    );
    expect(r).toEqual({ editId: 'edit123', versionCode: 7, track: 'internal', status: 'completed', downgradedToDraft: false, uploaded: { languages: ['en-US', 'it-IT'], listing: true, icon: false, featureGraphic: false, screenshots: 0 } });
    const token = g.calls[0]!;
    expect(String(token.body)).toContain('grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer');
    expect(g.calls.map((c) => `${c.method} ${c.url.replace(/^https:\/\/[^/]+/, '')}`)).toEqual([
      'POST /token',
      'POST /androidpublisher/v3/applications/dev.fluttercursor.app.chat/edits',
      'POST /upload/androidpublisher/v3/applications/dev.fluttercursor.app.chat/edits/edit123/bundles?uploadType=media',
      'GET /androidpublisher/v3/applications/dev.fluttercursor.app.chat/edits/edit123/details',
      'PUT /androidpublisher/v3/applications/dev.fluttercursor.app.chat/edits/edit123/listings/en-US',
      'PUT /androidpublisher/v3/applications/dev.fluttercursor.app.chat/edits/edit123/listings/it-IT',
      'PUT /androidpublisher/v3/applications/dev.fluttercursor.app.chat/edits/edit123/tracks/internal',
      'POST /androidpublisher/v3/applications/dev.fluttercursor.app.chat/edits/edit123:commit',
    ]);
    expect((g.calls[4]!.body as { title: string }).title.length).toBeLessThanOrEqual(30);
    expect(g.calls[6]!.body).toMatchObject({ track: 'internal', releases: [{ versionCodes: ['7'], status: 'completed', releaseNotes: [{ text: 'Prima versione' }] }] });
  });

  it('falls back to a draft release for never-published apps', async () => {
    const g = fakeGoogle({ draftOnly: true });
    const r = await publishToPlay(
      { serviceAccount: parseServiceAccount(saJson), packageName: 'a.b', aabPath: aab, track: 'internal', status: 'completed' },
      g.impl,
    );
    expect(r.downgradedToDraft).toBe(true);
    expect(r.status).toBe('draft');
  });

  it('explains a missing app in Play Console', async () => {
    const g = fakeGoogle({ missingApp: true });
    await expect(
      publishToPlay({ serviceAccount: parseServiceAccount(saJson), packageName: 'a.b', aabPath: aab, track: 'internal', status: 'draft' }, g.impl),
    ).rejects.toMatchObject({ code: 'play_app_not_found' });
  });

  it('renders privacy policy markdown safely', () => {
    const html = privacyHtml('Privacy – Chat', '# Privacy\n\nRaccogliamo **email**.\n- Login con [Google](https://policies.google.com)\n- <script>x</script>');
    expect(html).toContain('<h1>Privacy</h1>');
    expect(html).toContain('<strong>email</strong>');
    expect(html).toContain('<a href="https://policies.google.com"');
    expect(html).not.toContain('<script>');
  });
});
