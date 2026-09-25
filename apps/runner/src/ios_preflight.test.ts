import { mkdir, mkdtemp, readFile, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import sharp from 'sharp';
import { describe, expect, it } from 'vitest';
import { blocking, fixPreflight, namesMatch, plistString, pngHasAlpha, preflightIos, shortStoreName } from './ios_preflight.js';
import { withoutOtherPlatforms } from './appstore.js';

const okFetch = (async (url: string) =>
  new Response(String(url).endsWith('/app-ads.txt') ? 'google.com, pub-1111, DIRECT, f08c47fec0942fa0' : 'ok', { status: 200 })) as unknown as typeof fetch;
const deadFetch = (async () => new Response('no', { status: 404 })) as unknown as typeof fetch;

const PLIST = (extra = '') => `<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
\t<key>CFBundleDisplayName</key>
\t<string>Story Saver &amp; Reel Maker</string>
${extra}
</dict>
</plist>
`;

/** A project like Reel Maker was before its first iOS review. */
async function reelMakerBefore(opts: { code?: string; plist?: string; deps?: string } = {}) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'ember-pre-'));
  const deps = opts.deps ?? 'image_picker, audioplayers, in_app_purchase, google_mobile_ads';
  await writeFile(path.join(root, 'pubspec.yaml'), `name: x\ndependencies:\n${deps.split(',').map((d) => `  ${d.trim()}: ${d.trim() === 'google_mobile_ads' ? '5.3.1' : 'any'}`).join('\n')}\n\ndev_dependencies:\n  flutter_test: any\n`);
  await mkdir(path.join(root, 'lib'), { recursive: true });
  await writeFile(path.join(root, 'lib', 'main.dart'), opts.code ?? "void main() {} // restorePurchases, Uri.base.queryParameters['ember_screen']");
  await mkdir(path.join(root, 'ios', 'Runner.xcodeproj'), { recursive: true });
  await mkdir(path.join(root, 'ios', 'Flutter'), { recursive: true });
  await mkdir(path.join(root, 'ios', 'Runner'), { recursive: true });
  await writeFile(
    path.join(root, 'ios', 'Runner', 'Info.plist'),
    opts.plist ??
      PLIST('\t<key>GADApplicationIdentifier</key>\n\t<string>ca-app-pub-1111~2222</string>\n\t<key>NSUserTrackingUsageDescription</key>\n\t<string>Ads</string>\n\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>Photos</string>\n\t<key>NSCameraUsageDescription</key>\n\t<string>Camera</string>'),
  );
  await writeFile(path.join(root, 'ios', 'Runner.xcodeproj', 'project.pbxproj'), 'IPHONEOS_DEPLOYMENT_TARGET = 13.0;\nIPHONEOS_DEPLOYMENT_TARGET = 13.0;\n');
  await writeFile(path.join(root, 'ios', 'Podfile'), "# platform :ios, '13.0'\ntarget 'Runner' do\nend\n");
  return root;
}

const listing = { title: 'Reel Maker: Video Editor Story', privacyUrl: 'https://example.com/privacy' };
const ids = (f: Array<{ id: string }>) => f.map((x) => x.id).sort();

describe('iOS preflight', () => {
  it('finds what sent Reel Maker back: no tracking prompt, a different name under the icon', async () => {
    const root = await reelMakerBefore();
    const found = await preflightIos({ root, listing, reviewPhone: '+39 333', fetchImpl: okFetch, marketingUrl: 'https://dev.example' });
    expect(ids(blocking(found))).toEqual(['att_request']);
    expect(ids(found)).toEqual(['att_request', 'display_name', 'ios_target']);
    expect(found.find((f) => f.id === 'att_request')!.ask).toMatch(/requestTrackingAuthorization/);
  });

  it('is quiet once the app asks for tracking and the names match', async () => {
    const root = await reelMakerBefore({ code: "void main() { AppTrackingTransparency.requestTrackingAuthorization(); } // restorePurchases ember_screen" });
    await fixPreflight('display_name', { root, listing });
    await fixPreflight('ios_target', { root, listing });
    expect(await preflightIos({ root, listing, reviewPhone: '+39 333', fetchImpl: okFetch, marketingUrl: 'https://dev.example' })).toEqual([]);
    const plist = await readFile(path.join(root, 'ios', 'Runner', 'Info.plist'), 'utf8');
    expect(plistString(plist, 'CFBundleDisplayName')).toBe('Reel Maker');
    expect(await readFile(path.join(root, 'ios', 'Podfile'), 'utf8')).toMatch(/^platform :ios, '16.0'/m);
  });

  it('blocks what makes the app crash or Apple refuse it, and fixes the texts itself', async () => {
    const root = await reelMakerBefore({ plist: PLIST(), code: 'void main() {}' });
    const found = await preflightIos({ root, listing: { title: 'Story Saver' }, fetchImpl: okFetch });
    expect(ids(blocking(found))).toEqual(
      ['admob_app_id', 'att_request', 'att_text', 'marketing_url', 'privacy_url', 'restore_purchases', 'review_phone', 'usage:NSCameraUsageDescription', 'usage:NSPhotoLibraryUsageDescription'].sort(),
    );
    for (const id of ['att_text', 'usage:NSCameraUsageDescription', 'usage:NSPhotoLibraryUsageDescription']) await fixPreflight(id, { root, listing });
    const plist = await readFile(path.join(root, 'ios', 'Runner', 'Info.plist'), 'utf8');
    expect(plistString(plist, 'NSCameraUsageDescription')).toMatch(/Take photos/);
    expect(plistString(plist, 'NSUserTrackingUsageDescription')).toMatch(/relevant ads/);
  });

  it('asks for Sign in with Apple and account deletion when the app has Google sign-in', async () => {
    const root = await reelMakerBefore({ deps: 'google_sign_in, firebase_auth', plist: PLIST(), code: 'void main() {} // ember_screen' });
    expect(ids(blocking(await preflightIos({ root, listing, reviewPhone: '1', fetchImpl: okFetch, marketingUrl: 'https://dev.example' })))).toEqual(['account_deletion', 'sign_in_with_apple']);
  });

  it('says when the privacy page does not open', async () => {
    const root = await reelMakerBefore({ code: 'requestTrackingAuthorization restore ember_screen' });
    const found = await preflightIos({ root, listing, reviewPhone: '1', fetchImpl: deadFetch, marketingUrl: 'https://dev.example' });
    expect(found.find((f) => f.id === 'privacy_url')?.title).toMatch(/non si apre/);
  });

  it('makes a see-through icon opaque', async () => {
    const root = await reelMakerBefore();
    const dir = path.join(root, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');
    await mkdir(dir, { recursive: true });
    const icon = await sharp({ create: { width: 64, height: 64, channels: 4, background: { r: 200, g: 20, b: 60, alpha: 0.5 } } }).png().toBuffer();
    expect(pngHasAlpha(icon)).toBe(true);
    await writeFile(path.join(dir, 'Icon-App-1024x1024@1x.png'), icon);
    expect(ids(await preflightIos({ root, listing, reviewPhone: '1', fetchImpl: okFetch, marketingUrl: 'https://dev.example' }))).toContain('icon_alpha');
    await fixPreflight('icon_alpha', { root, listing });
    expect(pngHasAlpha(await readFile(path.join(dir, 'Icon-App-1024x1024@1x.png')))).toBe(false);
  });
});

describe('store names and text', () => {
  it('matches the name under the icon with the store name', () => {
    expect(shortStoreName('Reel Maker: Video Editor Story')).toBe('Reel Maker');
    expect(shortStoreName('Sagre - Feste vicino a me')).toBe('Sagre');
    expect(namesMatch('Reel Maker', 'Reel Maker: Video Editor Story')).toBe(true);
    expect(namesMatch('Story Saver & Reel Maker', 'Reel Maker: Video Editor Story')).toBe(false);
  });

  it('drops the sentences that name Android or Google Play from Apple text', () => {
    expect(withoutOtherPlatforms('Great editor. Also on Android and Google Play!\nExport in HD.')).toBe('Great editor.\nExport in HD.');
    expect(withoutOtherPlatforms('Share to Instagram.')).toBe('Share to Instagram.');
  });
});

describe('AdMob needs the developer website', () => {
  it('blocks an app with ads and no Marketing URL, and checks app-ads.txt', async () => {
    const root = await reelMakerBefore({ code: 'requestTrackingAuthorization restore ember_screen' });
    const noSite = await preflightIos({ root, listing, reviewPhone: '1', fetchImpl: okFetch });
    expect(blocking(noSite).map((f) => f.id)).toEqual(['marketing_url']);
    const ads = (async (url: string) => new Response(String(url).endsWith('/app-ads.txt') ? 'google.com, pub-9999, DIRECT, f08c47fec0942fa0' : 'ok')) as unknown as typeof fetch;
    const plist = path.join(root, 'ios', 'Runner', 'Info.plist');
    await writeFile(plist, (await readFile(plist, 'utf8')).replace('ca-app-pub-1111~2222', 'ca-app-pub-1111~2222'));
    const wrong = await preflightIos({ root, listing, reviewPhone: '1', fetchImpl: ads, marketingUrl: 'https://dev.example' });
    expect(wrong.map((f) => f.id)).toContain('app_ads_txt');
    const good = (async (url: string) => new Response(String(url).endsWith('/app-ads.txt') ? 'google.com, pub-1111, DIRECT, f08c47fec0942fa0' : 'ok')) as unknown as typeof fetch;
    expect((await preflightIos({ root, listing, reviewPhone: '1', fetchImpl: good, marketingUrl: 'https://dev.example' })).map((f) => f.id)).not.toContain('app_ads_txt');
  });
});

describe('the ad library that builds for iPhone', () => {
  it('blocks google_mobile_ads left on "any" (9.x fails with Xcode 26)', async () => {
    const root = await reelMakerBefore({ code: 'requestTrackingAuthorization restore ember_screen' });
    const pub = path.join(root, 'pubspec.yaml');
    await writeFile(pub, (await readFile(pub, 'utf8')).replace('google_mobile_ads: 5.3.1', 'google_mobile_ads: any'));
    const found = await preflightIos({ root, listing, reviewPhone: '1', fetchImpl: okFetch, marketingUrl: 'https://dev.example' });
    expect(blocking(found).map((f) => f.id)).toEqual(['gma_version']);
    expect(found.find((f) => f.id === 'gma_version')!.ask).toMatch(/5\.3\.1/);
  });
});

describe('apps for children', () => {
  it('blocks ads on iPhone in a Kids app, and asks no tracking prompt once they are off', async () => {
    const root = await reelMakerBefore({ code: 'void main() {} // restore ember_screen', plist: PLIST('\t<key>GADApplicationIdentifier</key>\n\t<string>ca-app-pub-1~2</string>\n\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>p</string>\n\t<key>NSCameraUsageDescription</key>\n\t<string>c</string>') });
    await mkdir(path.join(root, 'store'), { recursive: true });
    await writeFile(path.join(root, 'store', 'apple_settings.json'), JSON.stringify({ kids: true }));
    const withAds = blocking(await preflightIos({ root, listing, reviewPhone: '1', fetchImpl: okFetch, marketingUrl: 'https://dev.example' })).map((f) => f.id);
    expect(withAds).toContain('kids_ads');
    expect(withAds).not.toContain('att_request');
    await writeFile(path.join(root, 'store', 'apple_settings.json'), JSON.stringify({ kids: true, iosAds: false }));
    const off = blocking(await preflightIos({ root, listing, reviewPhone: '1', fetchImpl: okFetch })).map((f) => f.id);
    expect(off).toEqual([]);
  });
});

describe('subscriptions', () => {
  it('asks for tappable Terms and Privacy links on the paywall', async () => {
    const root = await reelMakerBefore({ code: "requestTrackingAuthorization restore ember_screen; const id = 'premium_monthly';" });
    const found = await preflightIos({ root, listing, reviewPhone: '1', fetchImpl: okFetch, marketingUrl: 'https://dev.example' });
    expect(blocking(found).map((f) => f.id)).toEqual(['subscription_links']);
    const ok = await reelMakerBefore({ code: "requestTrackingAuthorization restore ember_screen premium_monthly launchUrl('stdeula') privacy" });
    expect(blocking(await preflightIos({ root: ok, listing, reviewPhone: '1', fetchImpl: okFetch, marketingUrl: 'https://dev.example' }))).toEqual([]);
  });
});
