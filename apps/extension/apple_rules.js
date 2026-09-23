/**
 * What Ember writes on App Store Connect, as plain data. Pure functions: no
 * DOM, no chrome APIs, testable on their own (see apple_rules.test.mjs).
 *
 * App Store Connect's public API (the .p8 key) cannot create an app or answer
 * App Privacy. The website does both through its own endpoints (/iris/v1),
 * with the signed-in session: the extension calls them from the user's own
 * tab, the same requests the page sends when the user clicks.
 */

export const IRIS = 'https://appstoreconnect.apple.com/iris/v1';

/** The three answers Apple stores per data type and purpose. */
export const LINKED = 'DATA_LINKED_TO_YOU';
export const NOT_LINKED = 'DATA_NOT_LINKED_TO_YOU';
export const TRACKING = 'DATA_USED_TO_TRACK_YOU';
export const NOT_COLLECTED = 'DATA_NOT_COLLECTED';

/**
 * The rows the way App Store Connect keeps them: one per (data type, purpose)
 * with linked / not linked, plus ONE "used to track you" row per data type,
 * without a purpose (checked against an app answered by hand on the website).
 * An app that collects nothing is a single "not collected" row.
 */
export function privacyRows(privacy) {
  if (!privacy?.length) return [{ category: null, purpose: null, protection: NOT_COLLECTED }];
  const rows = [];
  for (const d of privacy) {
    for (const purpose of d.purposes) rows.push({ category: d.category, purpose, protection: d.linked ? LINKED : NOT_LINKED });
    if (d.tracking) rows.push({ category: d.category, purpose: null, protection: TRACKING });
  }
  return rows;
}

/** One row in words, for the panel. */
export function rowText(r) {
  return [r.category ?? 'nessun dato', r.purpose, r.protection?.replace(/^DATA_/, '').toLowerCase()].filter(Boolean).join(' · ');
}

const key = (r) => `${r.category ?? '-'}|${r.purpose ?? '-'}|${r.protection}`;

/** The body that creates one App Privacy row. */
export function usageBody(appId, row) {
  const relationships = { app: { data: { type: 'apps', id: appId } } };
  if (row.category) relationships.category = { data: { type: 'appDataUsageCategories', id: row.category } };
  if (row.purpose) relationships.purpose = { data: { type: 'appDataUsagePurposes', id: row.purpose } };
  relationships.dataProtection = { data: { type: 'appDataUsageDataProtections', id: row.protection } };
  return { data: { type: 'appDataUsages', relationships } };
}

/** Rows as App Store Connect returns them (GET apps/{id}/dataUsages). */
export function rowsFromApple(json) {
  return (json?.data ?? []).map((u) => ({
    id: u.id,
    category: u.relationships?.category?.data?.id ?? null,
    purpose: u.relationships?.purpose?.data?.id ?? null,
    protection: u.relationships?.dataProtection?.data?.id ?? null,
  }));
}

/** What differs between what Apple has and what the app really does. */
export function privacyDiff(current, wanted) {
  const have = new Set(current.map(key));
  const want = new Set(wanted.map(key));
  return {
    missing: wanted.filter((r) => !have.has(key(r))),
    extra: current.filter((r) => !want.has(key(r))),
    same: current.length > 0 && [...want].every((k) => have.has(k)) && [...have].every((k) => want.has(k)),
  };
}

/**
 * The body that creates the app (what "My Apps → + → New App" sends): name,
 * primary language, Bundle ID, SKU and a first 1.0 version.
 */
export function createAppBody(plan) {
  return {
    data: {
      type: 'apps',
      attributes: { sku: plan.sku, primaryLocale: plan.primaryLocale || 'en-US', bundleId: plan.bundleId },
      relationships: {
        appStoreVersions: { data: [{ type: 'appStoreVersions', id: '${store-version}' }] },
        appInfos: { data: [{ type: 'appInfos', id: '${new-appInfo-id}' }] },
      },
    },
    included: [
      {
        type: 'appStoreVersions',
        id: '${store-version}',
        attributes: { platform: 'IOS', versionString: '1.0' },
        // Apple refuses the app without the first version's page in the main language (409).
        relationships: { appStoreVersionLocalizations: { data: [{ type: 'appStoreVersionLocalizations', id: '${new-appStoreVersionLocalization-id}' }] } },
      },
      { type: 'appStoreVersionLocalizations', id: '${new-appStoreVersionLocalization-id}', attributes: { locale: plan.primaryLocale || 'en-US' } },
      {
        type: 'appInfos',
        id: '${new-appInfo-id}',
        relationships: { appInfoLocalizations: { data: [{ type: 'appInfoLocalizations', id: '${new-appInfoLocalization-id}' }] } },
      },
      { type: 'appInfoLocalizations', id: '${new-appInfoLocalization-id}', attributes: { locale: plan.primaryLocale || 'en-US', name: plan.name } },
    ],
  };
}

/** The app id in an App Store Connect address, e.g. /apps/6815011065/distribution. */
export function appIdFromUrl(url) {
  return /\/apps\/(\d+)/.exec(url)?.[1] ?? null;
}

/** Apple's error, in one readable line. */
export function appleError(status, json) {
  const e = json?.errors?.[0];
  const why = Object.values(e?.meta?.associatedErrors ?? {})
    .flat()
    .map((a) => a.detail)
    .filter(Boolean);
  const text = [e?.title, e?.detail, ...why].filter(Boolean).join(' — ');
  if (status === 401 || status === 403) return `Apple non ti riconosce su questa pagina (${status}): ricarica App Store Connect ed entra con l’account giusto. ${text}`.trim();
  if (status === 409 && /name/i.test(text)) return `Il nome è già usato da un’altra app su App Store: cambialo in Ember e riprova. (${text})`;
  return `${status} ${text}`.trim();
}

const PURPOSE_IT = {
  THIRD_PARTY_ADVERTISING: 'Pubblicità di terze parti',
  DEVELOPERS_ADVERTISING: 'Pubblicità dello sviluppatore',
  ANALYTICS: 'Analisi',
  PRODUCT_PERSONALIZATION: 'Personalizzazione',
  APP_FUNCTIONALITY: 'Funzionalità dell’app',
  OTHER_PURPOSES: 'Altri scopi',
};

/** The plan in the words App Store Connect shows, for the panel. */
export function privacySummary(privacy) {
  if (!privacy?.length) return ['Nessun dato raccolto'];
  return privacy.map(
    (d) => `${d.label}: ${d.purposes.map((p) => PURPOSE_IT[p] ?? p).join(' + ')} · collegato: ${d.linked ? 'Sì' : 'No'} · tracciamento: ${d.tracking ? 'Sì' : 'No'}`,
  );
}

/**
 * What goes into the review with the version, in the website's own order:
 * the version, each subscription group, its subscriptions, one-time purchases.
 * Apple refuses a new group alone ("must be submitted with an auto-renewable
 * subscription") and a first subscription without the version.
 */
export function reviewBodies({ submissionId, versionId, groupIds = [], subscriptionIds = [], purchaseIds = [] }) {
  const rel = (type, id) => ({ data: { type, id } });
  return [
    ...(versionId
      ? [['reviewSubmissionItems', { data: { type: 'reviewSubmissionItems', relationships: { reviewSubmission: rel('reviewSubmissions', submissionId), appStoreVersion: rel('appStoreVersions', versionId) } } }]]
      : []),
    ...groupIds.map((id) => ['subscriptionGroupSubmissions', { data: { type: 'subscriptionGroupSubmissions', relationships: { subscriptionGroup: rel('subscriptionGroups', id) } } }]),
    ...subscriptionIds.map((id) => ['subscriptionSubmissions', { data: { type: 'subscriptionSubmissions', relationships: { subscription: rel('subscriptions', id) } } }]),
    ...purchaseIds.map((id) => ['inAppPurchaseSubmissions', { data: { type: 'inAppPurchaseSubmissions', relationships: { inAppPurchaseV2: rel('inAppPurchases', id) } } }]),
  ];
}
