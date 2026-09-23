import { generateKeyPair, exportPKCS8 } from 'jose';
import { describe, expect, it } from 'vitest';
import { AppStoreError, appleLocale, appStoreToken, finishWhenBuildReady, parseAppStoreKey, privacyCategories, publishToAppStore, uploadIpa } from './appstore.js';
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
  approxLocation: false,
  performance: false,
  productInteraction: false,
  deviceId: false,
  payments: false,
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
    const rows = privacyCategories({ ...NO_FACTS, account: true, ads: true, deviceId: true, approxLocation: true, crashLogs: true });
    expect(rows.map((r) => r.category)).toContain('EMAIL_ADDRESS');
    expect(rows.find((r) => r.category === 'EMAIL_ADDRESS')).toMatchObject({ linked: true, tracking: false });
    expect(rows.find((r) => r.category === 'DEVICE_ID')).toMatchObject({ purpose: 'THIRD_PARTY_ADVERTISING', linked: false, tracking: true });
    expect(rows.filter((r) => r.category === 'COARSE_LOCATION').map((r) => r.purpose).sort()).toEqual(['ANALYTICS', 'THIRD_PARTY_ADVERTISING']);
    expect(rows.find((r) => r.category === 'ADVERTISING_DATA')).toMatchObject({ tracking: true });
  });

  it('writes the website answers in App Store Connect words', async () => {
    const { applePrivacyGuide } = await import('./appstore.js');
    expect(applePrivacyGuide(NO_FACTS)).toEqual(['"No, non raccogliamo dati da quest’app"']);
    const guide = applePrivacyGuide({ ...NO_FACTS, ads: true, deviceId: true });
    expect(guide).toContain('ID dispositivo: Pubblicità di terze parti · collegato all’identità: No · monitoraggio: Sì');
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
    ).rejects.toThrow(/non ha ancora un'app.*Crea l'app/);
  });

  it('refuses the upload away from a Mac, and says what to do', async () => {
    const key = parseAppStoreKey(await realKey());
    await expect(uploadIpa('/tmp/app.ipa', key, async () => ({ code: 0, out: '' }), 'win32')).rejects.toBeInstanceOf(AppStoreError);
    const sent = await uploadIpa('/tmp/app.ipa', key, async (bin, args) => ({ code: 0, out: `${bin} ${args.join(' ')}` }), 'darwin');
    expect(sent.output).toContain('altool --upload-app');
    expect(sent.output).toContain(key.keyId);
  });

  it('hands altool the saved key through API_PRIVATE_KEYS_DIR, then removes it', async () => {
    const { existsSync, readFileSync } = await import('node:fs');
    const key = parseAppStoreKey(await realKey());
    let dir = '';
    await uploadIpa(
      '/tmp/app.ipa',
      key,
      async (_bin, _args, env) => {
        dir = env?.API_PRIVATE_KEYS_DIR ?? '';
        expect(readFileSync(`${dir}/AuthKey_${key.keyId}.p8`, 'utf8')).toContain('BEGIN PRIVATE KEY');
        return { code: 0, out: '' };
      },
      'darwin',
    );
    expect(dir).not.toBe('');
    expect(existsSync(dir)).toBe(false);
  });
});

describe('Apple store text', () => {
  it('cuts the subtitle at a word and never on a filler word', async () => {
    const { cutAtWord } = await import('./appstore.js');
    expect(cutAtWord('Create stunning Reels & Stories with templates', 30)).toBe('Create stunning Reels');
    expect(cutAtWord('Crea Reel e Storie con modelli, musica', 30)).toBe('Crea Reel e Storie');
    expect(cutAtWord('Short one', 30)).toBe('Short one');
  });

  it('makes keywords without the name, filler words or other brands', async () => {
    const { keywordsFrom } = await import('./appstore.js');
    const kw = keywordsFrom({ title: 'Reel Maker: Video Editor', subtitle: 'Create Reels for Instagram and TikTok with music', description: 'Filters and effects' });
    expect(kw).toBe('create,music,filters,effects');
    expect(kw.length).toBeLessThanOrEqual(100);
  });
});

describe('Apple text rules', () => {
  it('drops the emoji Apple refuses and keeps the rest', async () => {
    const { appleText } = await import('./appstore.js');
    expect(appleText('✨ FEATURES\n• Templates 👍🏽\n💎 PREMIUM\n🇮🇹 Italia ❤️ ok')).toBe('FEATURES\n• Templates\nPREMIUM\nItalia ok');
    expect(appleText('🎉 First release!')).toBe('First release!');
  });
});

describe('one-press publish: waiting for the build', () => {
  const appleWith = (rounds: Array<Array<{ version: string; state: string }>>) => {
    let i = 0;
    const calls: string[] = [];
    const impl = (async (url: string | URL, init: RequestInit = {}) => {
      const u = String(url);
      const method = init.method ?? 'GET';
      calls.push(`${method} ${u.replace('https://api.appstoreconnect.apple.com/v1', '')}`);
      const ok = (data: unknown) => new Response(JSON.stringify({ data }), { status: 200 });
      if (u.includes('/builds?')) {
        const r = rounds[Math.min(i++, rounds.length - 1)]!;
        return ok(r.map((b, n) => ({ id: `B${b.version}-${n}`, attributes: { version: b.version, processingState: b.state } })));
      }
      if (u.includes('/reviewSubmissions?')) return ok([]);
      if (u.includes('appStoreVersionLocalizations?')) return ok([]);
      if (u.includes('/items?')) return ok([]);
      return ok({ id: 'SUB1' });
    }) as unknown as typeof fetch;
    return { impl, calls };
  };

  it('waits for the new build, never takes the older ready one, then attaches and submits', async () => {
    const key = parseAppStoreKey(await realKey());
    const apple = appleWith([
      [{ version: '11', state: 'VALID' }], // the new build is not listed yet
      [{ version: '12', state: 'PROCESSING' }, { version: '11', state: 'VALID' }],
      [{ version: '12', state: 'VALID' }, { version: '11', state: 'VALID' }],
    ]);
    const seen: string[] = [];
    const done = await finishWhenBuildReady({ key, appId: 'APP1', versionId: 'VER1', buildNumber: 12, submit: true, pollMs: 1, onProgress: (m) => seen.push(m) }, apple.impl);
    expect(done).toEqual({ attached: true, submitted: true });
    const attach = apple.calls.find((c) => c.includes('relationships/build'));
    expect(attach).toContain('PATCH /appStoreVersions/VER1/relationships/build');
    expect(apple.calls.filter((c) => c.startsWith('GET /builds?')).length).toBe(3);
    // A build made before the Info.plist answer gets it on Apple.
    expect(apple.calls.some((c) => c.startsWith('PATCH /builds/'))).toBe(true);
    expect(apple.calls.some((c) => c.startsWith('PATCH /reviewSubmissions/SUB1'))).toBe(true);
    expect(seen.join(' | ')).toMatch(/compaia su Apple.*elaborando la build 12.*pronta/);
  });

  it('stops with Apple’s verdict when the build is refused', async () => {
    const key = parseAppStoreKey(await realKey());
    const apple = appleWith([[{ version: '12', state: 'INVALID' }]]);
    await expect(finishWhenBuildReady({ key, appId: 'APP1', versionId: 'VER1', buildNumber: 12, submit: true, pollMs: 1 }, apple.impl)).rejects.toThrow(/scartato la build 12/);
  });
});

describe('App Store purchases from the app', () => {
  it('turns the declared products into Apple ones, with ids unique to the app', async () => {
    const { appleProductsFrom } = await import('./appstore_products.js');
    const out = appleProductsFrom(
      [
        { id: 'premium_monthly', type: 'subscription', title: 'Premium', description: 'All features', price: '4.99', period: 'P1M' },
        { id: 'premium_yearly', type: 'subscription', title: 'Premium Year', price: 24.99, period: 'P1Y', freeTrialDays: 7 },
        { id: 'coins_100', type: 'inapp', title: '100 coins', price: '0.99' },
        { id: 'lifetime', type: 'inapp', price: '29.99', iosId: 'readmaster_lifetime' },
        { id: 'free', type: 'inapp', price: '0' },
      ],
      'read_master',
    );
    expect(out.map((p) => [p.productId, p.kind, p.period ?? null, p.freeTrial ?? null])).toEqual([
      ['read_master_premium_monthly', 'subscription', 'ONE_MONTH', null],
      ['read_master_premium_yearly', 'subscription', 'ONE_YEAR', 'ONE_WEEK'],
      ['read_master_coins_100', 'consumable', null, null],
      ['readmaster_lifetime', 'non_consumable', null, null],
    ]);
  });

  it('fits the purchase screen into the exact iPhone size Apple accepts', async () => {
    const sharp = (await import('sharp')).default;
    const { reviewScreenshotFor } = await import('./appstore_products.js');
    const png = await sharp({ create: { width: 1080, height: 1920, channels: 4, background: { r: 250, g: 250, b: 255, alpha: 1 } } }).png().toBuffer();
    const meta = await sharp(await reviewScreenshotFor(png)).metadata();
    expect([meta.width, meta.height, meta.hasAlpha]).toEqual([1242, 2688, false]);
  });
});

describe('what Ember always writes for Apple', () => {
  it('promotional text from the short pitch, review notes from the app', async () => {
    const { promotionalFrom, reviewNotesFor } = await import('./appstore.js');
    expect(promotionalFrom({ subtitle: 'Open PDF, Word, Excel, images and P7M signed files — all in one reader!' })).toBe('Open PDF, Word, Excel, images and P7M signed files — all in one reader!');
    const notes = reviewNotesFor({
      facts: { ...NO_FACTS, ads: true },
      products: [{ productId: 'x_premium_yearly', kind: 'subscription', name: 'Premium Yearly', description: 'd', price: 24.99, period: 'ONE_YEAR', freeTrial: 'ONE_WEEK' }],
    });
    expect(notes).toMatch(/No account or login/);
    expect(notes).toMatch(/Premium Yearly \(x_premium_yearly, free trial\)/);
    expect(notes).toMatch(/Restore/);
    expect(notes).toMatch(/App Tracking Transparency/);
  });
});

describe('subscriptions need the Terms of Use on the store page', () => {
  it('adds the EULA and privacy links to the description once', async () => {
    const { withLegalLinks } = await import('./appstore.js');
    const once = withLegalLinks('Great app.', 'https://example.com/privacy');
    expect(once).toMatch(/Terms of Use \(EULA\): https:\/\/www\.apple\.com\/legal\/internet-services\/itunes\/dev\/stdeula\//);
    expect(once).toMatch(/Privacy Policy: https:\/\/example\.com\/privacy$/);
    expect(withLegalLinks(once, 'https://example.com/privacy')).toBe(once);
  });
});
