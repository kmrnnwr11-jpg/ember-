import { generateKeyPair, exportPKCS8 } from 'jose';
import { describe, expect, it } from 'vitest';
import { AppStoreError, appleLocale, appStoreToken, parseAppStoreKey, privacyCategories, publishToAppStore, uploadIpa } from './appstore.js';
import type { AppDataFacts } from './data_safety.js';

const NO_FACTS: AppDataFacts = {
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
};

async function realKey() {
  const { privateKey } = await generateKeyPair('ES256', { extractable: true });
  return { keyId: '2X9R4HXF34', issuerId: '69a6de80-1234-47e3-e053-5b8c7c11a4d1', privateKey: await exportPKCS8(privateKey) };
}

/** App Store Connect, reduced to the calls a publish makes. */
function fakeApple(opts: { appExists?: boolean; editableVersion?: boolean; build?: boolean } = {}) {
  const calls: Array<{ method: string; url: string; body: Record<string, unknown> }> = [];
  const impl = (async (url: string | URL, init: RequestInit = {}) => {
    const u = String(url);
    const method = init.method ?? 'GET';
    calls.push({ method, url: u, body: typeof init.body === 'string' ? (JSON.parse(init.body) as Record<string, unknown>) : {} });
    const ok = (data: unknown) => new Response(JSON.stringify({ data }), { status: 200 });

    if (u.includes('/apps?filter[bundleId]')) return opts.appExists === false ? ok([]) : ok([{ id: 'APP1', attributes: { name: 'Doodle Dino' } }]);
    if (u.includes('/appStoreVersions?')) return ok(opts.editableVersion ? [{ id: 'VER1', attributes: { appStoreState: 'PREPARE_FOR_SUBMISSION', versionString: '1.4.0' } }] : []);
    if (u.endsWith('/appStoreVersions') && method === 'POST') return ok({ id: 'VER_NEW' });
    if (u.includes('appStoreVersionLocalizations?')) return ok([{ id: 'LOC_IT', attributes: { locale: 'it' } }]);
    if (u.includes('/appInfos?')) return ok([{ id: 'INFO1', attributes: { appStoreState: 'PREPARE_FOR_SUBMISSION' } }]);
    if (u.includes('appInfoLocalizations?')) return ok([]);
    if (u.includes('/appDataUsages?')) return ok([{ id: 'OLD_USAGE' }]);
    if (u.includes('/builds?')) return ok(opts.build === false ? [] : [{ id: 'BUILD1', attributes: { processingState: 'VALID', version: '7' } }]);
    return ok({ id: 'X' });
  }) as unknown as typeof fetch;
  return { impl, calls };
}

describe('the Apple key', () => {
  it('refuses what is not a key, in words the user can act on', () => {
    expect(() => parseAppStoreKey({ keyId: 'no', issuerId: 'x', privateKey: 'y' })).toThrow(/Key ID/);
    expect(() => parseAppStoreKey({ keyId: '2X9R4HXF34', issuerId: 'x', privateKey: 'y' })).toThrow(/Issuer ID/);
    expect(() => parseAppStoreKey({ keyId: '2X9R4HXF34', issuerId: '69a6de80-1234-47e3-e053-5b8c7c11a4d1', privateKey: 'y' })).toThrow(/AuthKey/);
  });

  it('signs a token Apple can check', async () => {
    const key = parseAppStoreKey(await realKey());
    const [header, payload] = (await appStoreToken(key)).split('.');
    expect(JSON.parse(Buffer.from(header!, 'base64url').toString())).toMatchObject({ alg: 'ES256', kid: key.keyId });
    expect(JSON.parse(Buffer.from(payload!, 'base64url').toString())).toMatchObject({ aud: 'appstoreconnect-v1', iss: key.issuerId });
  });
});

describe('privacy answers', () => {
  it('says nothing is collected when the app collects nothing', () => {
    expect(privacyCategories(NO_FACTS)).toEqual([]);
  });

  it('follows what the app really uses, ads and login included', () => {
    const rows = privacyCategories({ ...NO_FACTS, account: true, ads: true, crashLogs: true });
    expect(rows.map((r) => r.category)).toContain('EMAIL_ADDRESS');
    expect(rows.find((r) => r.category === 'EMAIL_ADDRESS')!.linked).toBe(true);
    expect(rows.find((r) => r.category === 'DEVICE_ID')).toMatchObject({ purpose: 'THIRD_PARTY_ADVERTISING', linked: false });
  });
});

describe('language codes', () => {
  it('writes Play languages the way Apple spells them', () => {
    expect(appleLocale('it-IT')).toBe('it');
    expect(appleLocale('ar')).toBe('ar-SA');
    expect(appleLocale('en-US')).toBe('en-US');
  });
});

describe('publishing to the App Store', () => {
  it('writes every language, sets privacy and attaches the build', async () => {
    const apple = fakeApple({ editableVersion: true });
    const res = await publishToAppStore(
      {
        key: parseAppStoreKey(await realKey()),
        bundleId: 'com.dreamcodestudio.doodledino',
        versionString: '1.4.0',
        projectRoot: 'nowhere',
        listing: { language: 'it-IT', title: 'Doodle Dino', description: 'Disegna e colora' },
        translations: [{ language: 'en-US', title: 'Doodle Dino', description: 'Draw and colour' }],
        privacyPolicyUrl: 'https://gist.github.com/x',
        facts: { ...NO_FACTS, ads: true },
      },
      apple.impl,
    );

    expect(res).toMatchObject({ appId: 'APP1', versionId: 'VER1', versionCreated: false, buildAttached: true, submitted: false });
    expect(res.languages).toEqual(['it', 'en-US']);
    // The Italian page already existed and is updated; the English one is created.
    expect(apple.calls.some((c) => c.method === 'PATCH' && c.url.includes('/appStoreVersionLocalizations/LOC_IT'))).toBe(true);
    expect(apple.calls.some((c) => c.method === 'POST' && c.url.endsWith('/appStoreVersionLocalizations'))).toBe(true);
    // The privacy address belongs to the app details, not to the version.
    expect(apple.calls.some((c) => c.method === 'POST' && c.url.endsWith('/appInfoLocalizations') && JSON.stringify(c.body).includes('gist.github.com'))).toBe(true);
    // Old privacy answers are cleared before the new ones are written.
    expect(apple.calls.some((c) => c.method === 'DELETE' && c.url.includes('/appDataUsages/OLD_USAGE'))).toBe(true);
    expect(res.privacy).toMatchObject({ collects: true });
  });

  it('creates a version when none is open, and declares an app that collects nothing', async () => {
    const apple = fakeApple({ editableVersion: false, build: false });
    const res = await publishToAppStore(
      { key: parseAppStoreKey(await realKey()), bundleId: 'com.x.y', versionString: '2.0.0', projectRoot: 'nowhere', facts: NO_FACTS, submit: true },
      apple.impl,
    );
    expect(res).toMatchObject({ versionId: 'VER_NEW', versionCreated: true, buildAttached: false, submitted: false });
    expect(res.privacy).toMatchObject({ collects: false, categories: [] });
    expect(apple.calls.some((c) => c.method === 'POST' && c.url.endsWith('/appDataUsages') && JSON.stringify(c.body).includes('DATA_NOT_COLLECTED'))).toBe(true);
    // Nothing is sent for review without a build, and the user is told why.
    expect(res.notes.join(' ')).toMatch(/build attached first/i);
  });

  it('tells the user to create the app when Apple has never heard of it', async () => {
    const apple = fakeApple({ appExists: false });
    await expect(
      publishToAppStore({ key: parseAppStoreKey(await realKey()), bundleId: 'com.x.y', versionString: '1.0.0', projectRoot: 'nowhere' }, apple.impl),
    ).rejects.toThrow(/App Store Connect has no app/);
  });

  it('refuses the upload away from a Mac, and says what to do', async () => {
    const key = parseAppStoreKey(await realKey());
    await expect(uploadIpa('/tmp/app.ipa', key, async () => ({ code: 0, out: '' }), 'win32')).rejects.toBeInstanceOf(AppStoreError);
    const sent = await uploadIpa('/tmp/app.ipa', key, async (bin, args) => ({ code: 0, out: `${bin} ${args.join(' ')}` }), 'darwin');
    expect(sent.output).toContain('altool --upload-app');
    expect(sent.output).toContain(key.keyId);
  });
});
