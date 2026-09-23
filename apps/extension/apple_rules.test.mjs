import assert from 'node:assert/strict';
import test from 'node:test';
import { appIdFromUrl, appleError, createAppBody, NOT_COLLECTED, privacyDiff, privacyRows, privacySummary, reviewBodies, rowsFromApple, usageBody } from './apple_rules.js';

/** Reel Maker's answers, as the Runner hands them over. */
const reelMaker = [
  { category: 'COARSE_LOCATION', label: 'Posizione approssimativa', purposes: ['THIRD_PARTY_ADVERTISING', 'ANALYTICS'], linked: false, tracking: true },
  { category: 'DEVICE_ID', label: 'ID dispositivo', purposes: ['THIRD_PARTY_ADVERTISING'], linked: false, tracking: true },
  { category: 'CRASH_DATA', label: 'Dati sui crash', purposes: ['ANALYTICS'], linked: false, tracking: false },
];

test('one row per data type and purpose; tracking once per data type, without purpose', () => {
  const rows = privacyRows(reelMaker);
  // Location: 2 purposes + tracking; device id: 1 + tracking; crash: 1.
  assert.equal(rows.length, 3 + 2 + 1);
  assert.deepEqual(rows.filter((r) => r.protection === 'DATA_USED_TO_TRACK_YOU').map((r) => [r.category, r.purpose]), [
    ['COARSE_LOCATION', null],
    ['DEVICE_ID', null],
  ]);
  assert.deepEqual(privacyRows([]), [{ category: null, purpose: null, protection: NOT_COLLECTED }]);
});

test('the create body names the app, its category, purpose and answer', () => {
  const body = usageBody('681', privacyRows(reelMaker)[0]);
  assert.equal(body.data.type, 'appDataUsages');
  assert.deepEqual(body.data.relationships.app.data, { type: 'apps', id: '681' });
  assert.equal(body.data.relationships.category.data.id, 'COARSE_LOCATION');
  assert.equal(body.data.relationships.dataProtection.data.id, 'DATA_NOT_LINKED_TO_YOU');
  const none = usageBody('681', privacyRows([])[0]);
  assert.equal(none.data.relationships.category, undefined);
  assert.equal(none.data.relationships.dataProtection.data.id, NOT_COLLECTED);
});

test('reads what Apple has and tells what is missing or extra', () => {
  const apple = {
    data: privacyRows(reelMaker)
      .slice(1)
      .map((r, i) => ({
        id: `U${i}`,
        relationships: {
          category: { data: { id: r.category } },
          purpose: { data: { id: r.purpose } },
          dataProtection: { data: { id: r.protection } },
        },
      }))
      .concat([{ id: 'OLD', relationships: { category: { data: { id: 'PHOTOS_OR_VIDEOS' } }, purpose: { data: { id: 'APP_FUNCTIONALITY' } }, dataProtection: { data: { id: 'DATA_LINKED_TO_YOU' } } } }]),
  };
  const diff = privacyDiff(rowsFromApple(apple), privacyRows(reelMaker));
  assert.equal(diff.same, false);
  assert.equal(diff.missing.length, 1);
  assert.deepEqual(diff.extra.map((r) => r.id), ['OLD']);
  const all = { data: apple.data.slice(0, -1).concat([{ id: 'U-first', relationships: { category: { data: { id: 'COARSE_LOCATION' } }, purpose: { data: { id: 'THIRD_PARTY_ADVERTISING' } }, dataProtection: { data: { id: 'DATA_NOT_LINKED_TO_YOU' } } } }]) };
  assert.equal(privacyDiff(rowsFromApple(all), privacyRows(reelMaker)).same, true);
});

test('creates the app with its name, language, Bundle ID and SKU', () => {
  const body = createAppBody({ name: 'Reel Maker: Video Editor Story', bundleId: 'com.x.reel', sku: 'reel', primaryLocale: 'en-US' });
  assert.deepEqual(body.data.attributes, { sku: 'reel', primaryLocale: 'en-US', bundleId: 'com.x.reel' });
  const loc = body.included.find((i) => i.type === 'appInfoLocalizations');
  assert.deepEqual(loc.attributes, { locale: 'en-US', name: 'Reel Maker: Video Editor Story' });
  assert.equal(body.included.find((i) => i.type === 'appStoreVersions').attributes.platform, 'IOS');
  // Apple answers 409 without the first version's page in the main language.
  const version = body.included.find((i) => i.type === 'appStoreVersions');
  const page = body.included.find((i) => i.type === 'appStoreVersionLocalizations');
  assert.equal(version.relationships.appStoreVersionLocalizations.data[0].id, page.id);
  assert.equal(page.attributes.locale, 'en-US');
});

test('small helpers', () => {
  assert.equal(appIdFromUrl('https://appstoreconnect.apple.com/apps/6815011065/distribution/privacy'), '6815011065');
  assert.equal(appIdFromUrl('https://appstoreconnect.apple.com/apps'), null);
  assert.match(appleError(403, {}), /ricarica App Store Connect/);
  assert.match(appleError(409, { errors: [{ detail: 'The app name you entered is already being used.' }] }), /nome è già usato/);
  assert.match(privacySummary(reelMaker)[1], /^ID dispositivo: Pubblicità di terze parti · collegato: No · tracciamento: Sì$/);
});

test('the review holds the version, then the group, its subscriptions and one-time purchases', () => {
  const steps = reviewBodies({ submissionId: 'S', versionId: 'V', groupIds: ['G'], subscriptionIds: ['A', 'B'], purchaseIds: ['L'] });
  assert.deepEqual(steps.map(([r]) => r), ['reviewSubmissionItems', 'subscriptionGroupSubmissions', 'subscriptionSubmissions', 'subscriptionSubmissions', 'inAppPurchaseSubmissions']);
  assert.equal(steps[0][1].data.relationships.appStoreVersion.data.id, 'V');
  assert.equal(steps[4][1].data.relationships.inAppPurchaseV2.data.type, 'inAppPurchases');
  assert.equal(reviewBodies({ submissionId: 'S', versionId: null }).length, 0);
});
