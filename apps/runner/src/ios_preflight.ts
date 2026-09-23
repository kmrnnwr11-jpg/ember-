import { readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';
import type { Finding } from './doctor.js';
import { readAppleSettings } from './apple_settings.js';

/**
 * What Apple would reject, checked before the app is sent: each rejection
 * costs one to three days. Every finding names the guideline, says what goes
 * wrong, and is either fixed by Ember (fixable), fixed by the engine that wrote
 * the app (ask), or needs the user.
 */

export interface PreflightFinding extends Finding {
  /** block: Apple rejects the app or it crashes in review. warn: worth fixing. */
  severity: 'block' | 'warn';
}

type Listing = { title?: string; privacyUrl?: string };

const read = (root: string, ...rel: string[]) => readFile(path.join(root, ...rel), 'utf8').catch(() => '');

/** A plist <key>'s string value, or null when the key is absent. */
export function plistString(plist: string, key: string): string | null {
  const m = new RegExp(`<key>${key}</key>\\s*<string>([^<]*)</string>`).exec(plist);
  return m ? m[1]!.replace(/&amp;/g, '&').trim() : null;
}

function setPlistString(plist: string, key: string, value: string): string {
  const v = value.replace(/&/g, '&amp;').replace(/</g, '&lt;');
  const re = new RegExp(`(<key>${key}</key>\\s*<string>)[^<]*(</string>)`);
  if (re.test(plist)) return plist.replace(re, `$1${v}$2`);
  return plist.replace(/<dict>/, `<dict>\n\t<key>${key}</key>\n\t<string>${v}</string>`);
}

const deps = (pubspec: string) => {
  const block = /^dependencies:\s*\n([\s\S]*?)(?=^\S)/m.exec(`${pubspec}\nend:`)?.[1] ?? '';
  return new Set([...block.matchAll(/^\s{2}([a-z0-9_]+):/gm)].map((m) => m[1]!));
};

async function dartCode(dir: string): Promise<string> {
  let out = '';
  for (const e of await readdir(dir, { withFileTypes: true }).catch(() => [])) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out += await dartCode(p);
    else if (e.name.endsWith('.dart')) out += `${await readFile(p, 'utf8').catch(() => '')}\n`;
  }
  return out;
}

/** The name under the icon that matches the store name: the part before ":" or " - ". */
export function shortStoreName(title: string): string {
  const head = title.split(/\s*[:|–—]\s*|\s+-\s+/)[0]!.trim();
  return head.length > 0 && head.length <= 30 ? head : title.slice(0, 30).trim();
}

const norm = (s: string) => s.toLowerCase().replace(/[^\p{L}\p{N}]+/gu, ' ').trim();

/** Apple wants the name under the icon to be recognisably the store name (2.3.8). */
export function namesMatch(displayName: string, storeTitle: string): boolean {
  const title = new Set(norm(storeTitle).split(' '));
  const words = norm(displayName).split(' ').filter(Boolean);
  if (words.length === 0 || title.size === 0) return true;
  // Every word under the icon must be in the store name: "Reel Maker" fits
  // "Reel Maker: Video Editor Story", "Story Saver & Reel Maker" does not.
  return words.every((w) => title.has(w));
}

/** Permission texts iOS requires before a plugin may touch the hardware: without them the app crashes. */
const USAGE: Array<{ deps: string[]; key: string; text: string }> = [
  { deps: ['image_picker', 'photo_manager', 'wechat_assets_picker', 'image_gallery_saver', 'gal', 'saver_gallery'], key: 'NSPhotoLibraryUsageDescription', text: 'Choose photos and videos from your library to use in the app.' },
  { deps: ['image_picker', 'camera'], key: 'NSCameraUsageDescription', text: 'Take photos and videos to use in the app.' },
  { deps: ['record', 'flutter_sound', 'speech_to_text', 'camera', 'audio_waveforms'], key: 'NSMicrophoneUsageDescription', text: 'Record audio to use in the app.' },
  { deps: ['geolocator', 'location'], key: 'NSLocationWhenInUseUsageDescription', text: 'Show results near you.' },
  { deps: ['contacts_service', 'flutter_contacts'], key: 'NSContactsUsageDescription', text: 'Pick contacts to share with.' },
  { deps: ['speech_to_text'], key: 'NSSpeechRecognitionUsageDescription', text: 'Turn your voice into text.' },
  { deps: ['image_gallery_saver', 'gal', 'saver_gallery'], key: 'NSPhotoLibraryAddUsageDescription', text: 'Save your creations to your photo library.' },
];

const TEST_ADMOB = 'ca-app-pub-3940256099942544';
const ADS_SDKS = ['google_mobile_ads', 'applovin_max', 'unity_ads_plugin', 'easy_ads_flutter'];

/** PNG with an alpha channel (colour type 4 or 6): Apple refuses such an app icon (ITMS-90717). */
export function pngHasAlpha(buf: Buffer): boolean {
  return buf.length > 26 && buf.toString('ascii', 1, 4) === 'PNG' && (buf[25] === 6 || buf[25] === 4);
}

const iconFile = (root: string) => path.join(root, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset', 'Icon-App-1024x1024@1x.png');

export interface PreflightContext {
  root: string;
  listing: Listing;
  /** Review phone saved for the account. */
  reviewPhone?: string;
  /** Checks the privacy page answers (injected in tests). */
  fetchImpl?: typeof fetch;
  /** Developer website saved for the account (Marketing URL). */
  marketingUrl?: string;
}

export async function preflightIos(ctx: PreflightContext): Promise<PreflightFinding[]> {
  const { root, listing } = ctx;
  const out: PreflightFinding[] = [];
  const add = (f: PreflightFinding) => out.push(f);
  const pubspec = await read(root, 'pubspec.yaml');
  const d = deps(pubspec);
  const code = await dartCode(path.join(root, 'lib'));
  const plist = await read(root, 'ios', 'Runner', 'Info.plist');
  const pbx = await read(root, 'ios', 'Runner.xcodeproj', 'project.pbxproj');
  const has = (...n: string[]) => n.some((x) => d.has(x));
  if (!plist) return out; // no iOS folder: nothing to check

  // ---- Crashes in review (2.1) ----
  for (const u of USAGE) {
    if (has(...u.deps) && !plistString(plist, u.key)) {
      add({
        id: `usage:${u.key}`,
        severity: 'block',
        title: `Manca il testo del permesso ${u.key}`,
        detail: 'Senza questa frase l’iPhone chiude l’app appena chiede il permesso: Apple la rifiuta (2.1). Ember la aggiunge in inglese.',
        fixable: true,
      });
    }
  }
  const settings = await readAppleSettings(root);
  const kids = !!settings.kids;
  // The iPhone build may show no ads at all (Kids category): then AdMob rules do not apply there.
  const ads = has(...ADS_SDKS) && settings.iosAds !== false;
  if (kids && ads) {
    add({
      id: 'kids_ads',
      severity: 'block',
      title: 'Annunci in un’app per bambini su iPhone',
      detail: 'Apple non ammette pubblicità di terze parti nelle app per bambini (1.3, 5.1.4): su iPhone gli annunci vanno spenti e "iosAds": false in store/apple_settings.json.',
      fixable: false,
      ask: 'This is a Kids category app on iPhone: never initialize or show ads on iOS (keep them on Android, child-directed). Make the ads service report unsupported when defaultTargetPlatform == TargetPlatform.iOS.',
    });
  }
  if (ads && d.has('google_mobile_ads') && !plistString(plist, 'GADApplicationIdentifier')) {
    add({
      id: 'admob_app_id',
      severity: 'block',
      title: 'Manca l’ID app AdMob per iPhone',
      detail: 'Senza GADApplicationIdentifier in Info.plist l’app si chiude all’avvio (2.1). Crea l’app iOS su AdMob e incolla l’ID nella scheda Annunci.',
      fixable: false,
    });
  }

  // ---- Tracking permission (5.1.2) ----
  const asksTracking = /requestTrackingAuthorization/.test(code);
  const trackingText = plistString(plist, 'NSUserTrackingUsageDescription');
  if (ads && !kids && !asksTracking) {
    add({
      id: 'att_request',
      severity: 'block',
      title: 'L’app non chiede il permesso di tracciamento',
      detail: 'Gli annunci usano l’ID pubblicità: Apple vuole il popup "Consenti di tracciare…" prima degli annunci (5.1.2).',
      fixable: false,
      ask: 'On iOS, show the App Tracking Transparency prompt before ads load: add the app_tracking_transparency package and call AppTrackingTransparency.requestTrackingAuthorization() when trackingAuthorizationStatus is notDetermined, after the Google UMP consent form and before MobileAds.instance.initialize(). If the user refuses, ads stay non-personalised and the app works the same. Keep an English NSUserTrackingUsageDescription in ios/Runner/Info.plist.',
    });
  }
  if (((ads && !kids) || asksTracking) && !trackingText) {
    add({ id: 'att_text', severity: 'block', title: 'Manca la frase del permesso di tracciamento', detail: 'Il popup di tracciamento senza NSUserTrackingUsageDescription fa chiudere l’app (2.1). Ember la aggiunge.', fixable: true });
  } else if (trackingText && !asksTracking && !ads) {
    add({
      id: 'att_unused',
      severity: 'block',
      title: 'Frase di tracciamento presente ma il permesso non viene mai chiesto',
      detail: 'Apple rifiuta un’app che dichiara il tracciamento senza chiederlo (5.1.2). Ember toglie la frase inutile.',
      fixable: true,
    });
  }

  if (kids && asksTracking) {
    add({ id: 'kids_att', severity: 'block', title: 'Un’app per bambini non può chiedere il tracciamento', detail: 'Nelle app Kids il tracciamento non è ammesso: togli il popup App Tracking Transparency.', fixable: false, ask: 'Remove the App Tracking Transparency request and NSUserTrackingUsageDescription: this is a Kids category app.' });
  }

  // ---- Payments and accounts ----
  if (has('in_app_purchase', 'purchases_flutter', 'adapty_flutter', 'qonversion_flutter') && !/restore/i.test(code)) {
    add({
      id: 'restore_purchases',
      severity: 'block',
      title: 'Manca "Ripristina acquisti"',
      detail: 'Chi ha già pagato deve poter recuperare l’acquisto da un pulsante: Apple lo esige (3.1.1).',
      fixable: false,
      ask: 'Add a visible "Restore purchases" button on the paywall/premium screen (and in settings) that calls the store restore (InAppPurchase.instance.restorePurchases() or Purchases.restorePurchases()) and unlocks what the user already bought, with a short message when nothing is found.',
    });
  }
  if (has('google_sign_in', 'flutter_facebook_auth') && !d.has('sign_in_with_apple')) {
    add({
      id: 'sign_in_with_apple',
      severity: 'block',
      title: 'Manca "Accedi con Apple"',
      detail: 'Un’app che offre l’accesso con Google o Facebook deve offrire anche quello con Apple (4.8).',
      fixable: false,
      ask: 'Add "Sign in with Apple" next to the other sign-in buttons, on iOS, with the sign_in_with_apple package (and Firebase/Supabase Apple provider if the app uses them), same size and prominence as Google sign-in.',
    });
  }
  const account = has('firebase_auth', 'google_sign_in', 'sign_in_with_apple', 'flutter_facebook_auth') || (d.has('supabase_flutter') && /\.auth\.sign(In|Up)/.test(code));
  if (account && !/delete\w*account|deleteUser|user\??\.delete\(|account.?deletion/i.test(code)) {
    add({
      id: 'account_deletion',
      severity: 'block',
      title: 'Manca "Elimina account"',
      detail: 'Se l’app crea account, deve permettere di cancellarlo dall’app stessa (5.1.1(v)).',
      fixable: false,
      ask: 'Add a "Delete account" option in the settings/profile screen: ask for confirmation, delete the user\'s data and the auth account (re-authenticate if required), sign out and return to the start screen.',
    });
  }

  // ---- Store page ----
  const display = plistString(plist, 'CFBundleDisplayName') ?? '';
  if (listing.title && display && !namesMatch(display, listing.title)) {
    add({
      id: 'display_name',
      severity: 'warn',
      title: `Il nome sotto l’icona ("${display}") è diverso da quello sullo store`,
      detail: `Apple chiede che siano riconoscibilmente la stessa app (2.3.8). Ember usa "${shortStoreName(listing.title)}".`,
      fixable: true,
    });
  }
  if (!listing.privacyUrl) {
    add({ id: 'privacy_url', severity: 'block', title: 'Manca il link della privacy policy', detail: 'Apple non accetta un’app senza privacy policy pubblica (5.1.1).', fixable: false });
  } else {
    const ok = await (ctx.fetchImpl ?? fetch)(listing.privacyUrl, { method: 'GET', redirect: 'follow', signal: AbortSignal.timeout(10_000) })
      .then((r) => r.ok)
      .catch(() => false);
    if (!ok) {
      add({ id: 'privacy_url', severity: 'block', title: 'Il link della privacy policy non si apre', detail: `${listing.privacyUrl} non risponde: il recensore deve poterlo aprire (5.1.1).`, fixable: false });
    } else if (/gist\.github\.com|pastebin\.com|docs\.google\.com\/document/.test(listing.privacyUrl)) {
      add({
        id: 'privacy_host',
        severity: 'warn',
        title: 'La privacy policy è su una pagina di appunti',
        detail: 'Un gist o un documento condiviso funziona, ma a volte il recensore lo contesta: meglio una pagina web vera (GitHub Pages).',
        fixable: false,
      });
    }
  }
  // AdMob only fully serves an iPhone app whose store listing names a developer
  // website with an app-ads.txt that lists the account's publisher id.
  if (ads) {
    const pub = /ca-app-pub-(\d+)~/.exec(plistString(plist, 'GADApplicationIdentifier') ?? '')?.[1];
    if (!ctx.marketingUrl) {
      add({
        id: 'marketing_url',
        severity: 'block',
        title: 'Manca il sito sviluppatore (Marketing URL)',
        detail: 'AdMob cerca app-ads.txt sul sito indicato nella scheda: senza, gli annunci iPhone vengono limitati. Scrivilo una volta in "Dati per la revisione → Sito sviluppatore".',
        fixable: false,
      });
    } else if (pub && pub !== '3940256099942544') {
      const txt = await (ctx.fetchImpl ?? fetch)(new URL('/app-ads.txt', ctx.marketingUrl).toString(), { signal: AbortSignal.timeout(10_000) })
        .then(async (r) => (r.ok ? r.text() : ''))
        .catch(() => '');
      if (!txt.includes(`pub-${pub}`)) {
        add({
          id: 'app_ads_txt',
          severity: 'warn',
          title: 'app-ads.txt non contiene il tuo codice editore',
          detail: `Su ${new URL('/app-ads.txt', ctx.marketingUrl)} deve esserci la riga "google.com, pub-${pub}, DIRECT, f08c47fec0942fa0", altrimenti AdMob limita gli annunci.`,
          fixable: false,
        });
      }
    }
  }
  if (!ctx.reviewPhone) {
    add({ id: 'review_phone', severity: 'block', title: 'Manca il telefono per la revisione', detail: 'Apple lo chiede per poterti contattare. Scrivilo in "Dati per la revisione".', fixable: false });
  }
  if (!/ember_screen/.test(code)) {
    add({
      id: 'screenshot_mode',
      severity: 'warn',
      title: 'L’app non ha la modalità screenshot',
      detail: 'Senza, Ember non può fotografare le schermate e Apple non accetta l’invio senza screenshot.',
      fixable: false,
      ask: "Add a screenshot mode: on web, when the URL has the query parameter ember_screen=N (N = 0..5), open directly the app's N-th most representative screen with realistic demo content, without dialogs or debug banners. Read it with Uri.base.queryParameters['ember_screen'] and keep the screen list in lib/config/screenshot_screens.dart. Normal launches are unchanged.",
    });
  }

  // ---- Build ----
  const target = Math.min(...[...pbx.matchAll(/IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);/g)].map((m) => Number(m[1])));
  if (Number.isFinite(target) && target < 15) {
    add({
      id: 'ios_target',
      severity: 'warn',
      title: `L’app parte da iOS ${target}`,
      detail: 'Dalla primavera 2027 Apple accetterà solo app da iOS 15 in su. Ember alza il minimo a iOS 15.',
      fixable: true,
    });
  }
  // The iPhone ids only: an ads config keeps Google's test ids for debug builds too.
  const iosIds = `${plistString(plist, 'GADApplicationIdentifier') ?? ''}\n${[...(await read(root, 'lib', 'config', 'ads_config.dart')).matchAll(/ios\w*Id\s*=\s*\n?\s*'([^']+)'/gi)].map((m) => m[1]).join('\n')}`;
  if (ads && iosIds.includes(TEST_ADMOB)) {
    add({
      id: 'admob_test_ids',
      severity: 'warn',
      title: 'Annunci di prova (ID di test di Google)',
      detail: 'Apple accetta l’app, ma gli annunci non ti fanno guadagnare nulla. Inserisci gli ID veri di AdMob per iPhone nella scheda Annunci.',
      fixable: false,
    });
  }
  // google_mobile_ads 9.x fails the iPhone archive with Xcode 26 ("non-modular header"): 5.3.1 builds.
  const gma = /^\s{2}google_mobile_ads:\s*(\S+)/m.exec(pubspec)?.[1] ?? '';
  const lockGma = /google_mobile_ads:[\s\S]*?version:\s*"(\d+)\./.exec(await read(root, 'pubspec.lock'))?.[1];
  if (d.has('google_mobile_ads') && (gma === 'any' || Number(lockGma ?? 0) >= 6)) {
    add({
      id: 'gma_version',
      severity: 'block',
      title: 'La libreria degli annunci (google_mobile_ads) è troppo nuova per iPhone',
      detail: 'Dalla 6 in su non compila con Xcode 26. Ember la fissa alla 5.3.1, che funziona.',
      fixable: false,
      ask: 'Pin google_mobile_ads to exactly 5.3.1 in pubspec.yaml, run flutter pub get, and adapt any API the app uses that 5.3.1 lacks (e.g. use AdSize.getAnchoredAdaptiveBannerAdSize instead of getLargeAnchoredAdaptiveBannerAdSizeWithOrientation).',
    });
  }
  const icon = await readFile(iconFile(root)).catch(() => null);
  if (icon && pngHasAlpha(icon)) {
    add({ id: 'icon_alpha', severity: 'block', title: 'L’icona ha la trasparenza', detail: 'Apple rifiuta il caricamento di un’icona con canale alfa (ITMS-90717). Ember la rende opaca.', fixable: true });
  }
  return out;
}

/** Applies a fixable finding. Returns what was done, in the user's words. */
export async function fixPreflight(id: string, ctx: { root: string; listing: Listing }): Promise<string> {
  const plistPath = path.join(ctx.root, 'ios', 'Runner', 'Info.plist');
  const plist = await readFile(plistPath, 'utf8');
  if (id.startsWith('usage:')) {
    const key = id.slice('usage:'.length);
    const u = USAGE.find((x) => x.key === key);
    if (!u) throw new Error(`permesso sconosciuto: ${key}`);
    await writeFile(plistPath, setPlistString(plist, key, u.text));
    return `Aggiunto ${key}`;
  }
  switch (id) {
    case 'att_text':
      await writeFile(plistPath, setPlistString(plist, 'NSUserTrackingUsageDescription', 'This lets us show you more relevant ads. You can say no and keep every feature of the app.'));
      return 'Aggiunta la frase del permesso di tracciamento';
    case 'att_unused':
      await writeFile(plistPath, plist.replace(/\s*<key>NSUserTrackingUsageDescription<\/key>\s*<string>[^<]*<\/string>/, ''));
      return 'Tolta la frase di tracciamento inutilizzata';
    case 'display_name': {
      const name = shortStoreName(ctx.listing.title ?? '');
      if (!name) throw new Error('manca il nome dello store');
      await writeFile(plistPath, setPlistString(setPlistString(plist, 'CFBundleDisplayName', name), 'CFBundleName', name.slice(0, 15)));
      return `Nome sotto l’icona: "${name}"`;
    }
    case 'ios_target': {
      const pbxPath = path.join(ctx.root, 'ios', 'Runner.xcodeproj', 'project.pbxproj');
      const pbx = await readFile(pbxPath, 'utf8');
      await writeFile(pbxPath, pbx.replace(/IPHONEOS_DEPLOYMENT_TARGET = [\d.]+;/g, (m) => (Number(/[\d.]+/.exec(m)![0]) < 15 ? 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;' : m)));
      const podPath = path.join(ctx.root, 'ios', 'Podfile');
      const pod = await readFile(podPath, 'utf8').catch(() => null);
      if (pod !== null) await writeFile(podPath, /^#?\s*platform :ios.*$/m.test(pod) ? pod.replace(/^#?\s*platform :ios.*$/m, "platform :ios, '15.0'") : `platform :ios, '15.0'\n${pod}`);
      const appInfo = path.join(ctx.root, 'ios', 'Flutter', 'AppFrameworkInfo.plist');
      const fw = await readFile(appInfo, 'utf8').catch(() => null);
      if (fw !== null) await writeFile(appInfo, setPlistString(fw, 'MinimumOSVersion', '15.0'));
      return 'iOS minimo portato a 15.0';
    }
    case 'icon_alpha': {
      const file = iconFile(ctx.root);
      const img = sharp(await readFile(file));
      const { data } = await img.clone().raw().toBuffer({ resolveWithObject: true });
      // Fill the see-through parts with the icon's own corner colour, not a white box.
      const bg = { r: data[0] ?? 255, g: data[1] ?? 255, b: data[2] ?? 255 };
      await writeFile(file, await img.flatten({ background: bg }).removeAlpha().png().toBuffer());
      return 'Icona resa opaca';
    }
    default:
      throw new Error(`Ember non sa correggere da solo: ${id}`);
  }
}

/** The ones Apple would reject: a publish stops on these unless told otherwise. */
export const blocking = (f: PreflightFinding[]) => f.filter((x) => x.severity === 'block');
