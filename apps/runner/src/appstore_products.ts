import sharp from 'sharp';
import { AppStore } from './appstore.js';

/**
 * In-app purchases on the App Store, created with the same product ids and
 * prices the app already sells on Google Play — the app's code asks both
 * stores for the same ids, so they must match exactly.
 *
 * Everything is idempotent: a product that already exists is completed, not
 * duplicated, so a failed run is simply run again.
 */

export type Period = 'ONE_WEEK' | 'ONE_MONTH' | 'TWO_MONTHS' | 'THREE_MONTHS' | 'SIX_MONTHS' | 'ONE_YEAR';
export type TrialLength = 'THREE_DAYS' | 'ONE_WEEK' | 'TWO_WEEKS' | 'ONE_MONTH';

export interface AppleProduct {
  productId: string;
  kind: 'subscription' | 'non_consumable' | 'consumable';
  /** Internal name (App Store Connect) and the name buyers see, e.g. "Premium Monthly". */
  name: string;
  /** What buyers read under the name, max 55 characters. */
  description: string;
  /** Price in the base territory's currency, e.g. 4.99 (euro for Italy). */
  price: number;
  period?: Period;
  freeTrial?: TrialLength;
}

export interface ProductsInput {
  appId: string;
  products: AppleProduct[];
  groupName?: string;
  locale?: string;
  /** Where prices are set; Apple equalises every other country from it. */
  baseTerritory?: string;
  /** Screenshot of the purchase screen for the reviewer (PNG). */
  reviewScreenshot?: Buffer;
  onProgress?: (message: string) => void;
}

type Res = { id: string; attributes?: Record<string, unknown>; relationships?: Record<string, unknown> };
type Page = { data: Res[]; links?: { next?: string } };

/** Every page of a list endpoint. */
async function all(store: AppStore, url: string, what: string, max = 20): Promise<Res[]> {
  const out: Res[] = [];
  let next: string | undefined = url;
  for (let i = 0; next && i < max; i++) {
    const page: Page = await store.call<Page>('GET', next, undefined, what);
    out.push(...(page.data ?? []));
    next = page.links?.next;
  }
  return out;
}

const samePrice = (a: unknown, price: number) => Math.abs(Number(a) - price) < 0.001;

/**
 * Apple accepts a purchase's review screenshot only at an exact iPhone size
 * (IMAGE_INCORRECT_DIMENSIONS otherwise): the screen is fitted into 1242×2688,
 * the space around it filled with the screen's own background colour.
 */
export async function reviewScreenshotFor(png: Buffer): Promise<Buffer> {
  const img = sharp(png).removeAlpha();
  const { data } = await img.clone().raw().toBuffer({ resolveWithObject: true });
  const background = { r: data[0] ?? 255, g: data[1] ?? 255, b: data[2] ?? 255 };
  return img.resize(1242, 2688, { fit: 'contain', background }).png().toBuffer();
}

/**
 * The review screenshot of a subscription or purchase: kept when Apple
 * accepted it, replaced when Apple refused it (FAILED), uploaded when missing.
 */
async function ensureReviewShot(store: AppStore, current: Res | null, resource: string, relationships: Record<string, unknown>, shot: Buffer): Promise<void> {
  const state = (current?.attributes?.assetDeliveryState as { state?: string } | undefined)?.state;
  if (current && state !== 'FAILED') return;
  if (current) await store.call('DELETE', `/${resource}/${current.id}`, undefined, 'Removing the refused screenshot');
  await store.uploadAsset(resource, relationships, 'purchase.png', shot, 'Review screenshot');
}

/** The subscription's own name/description, per language. */
async function ensureSubscriptionPage(store: AppStore, subId: string, p: AppleProduct, locale: string) {
  const { data } = await store.call<{ data: Res[] }>('GET', `/subscriptions/${subId}/subscriptionLocalizations?limit=50`, undefined, 'Reading the subscription page');
  if (data?.some((l) => l.attributes?.locale === locale)) return;
  await store.call(
    'POST',
    '/subscriptionLocalizations',
    { data: { type: 'subscriptionLocalizations', attributes: { locale, name: p.name.slice(0, 30), description: p.description.slice(0, 55) }, relationships: { subscription: { data: { type: 'subscriptions', id: subId } } } } },
    'Writing the subscription page',
  );
}

async function territories(store: AppStore): Promise<string[]> {
  return (await all(store, '/territories?limit=200', 'Reading the countries')).map((t) => t.id);
}

export async function ensureAppleProducts(store: AppStore, input: ProductsInput): Promise<string[]> {
  const locale = input.locale ?? 'en-US';
  const base = input.baseTerritory ?? 'ITA';
  const say = input.onProgress ?? (() => {});
  const done: string[] = [];
  const allTerritories = await territories(store);
  const reviewShot = input.reviewScreenshot ? await reviewScreenshotFor(input.reviewScreenshot) : null;

  // ---------------- auto-renewable subscriptions: one group, highest plan first
  const subs = input.products.filter((p) => p.kind === 'subscription');
  if (subs.length) {
    const groups = await all(store, `/apps/${input.appId}/subscriptionGroups?limit=50`, 'Reading the subscription groups');
    const groupName = input.groupName ?? 'Premium';
    let group = groups.find((g) => g.attributes?.referenceName === groupName) ?? groups[0];
    if (!group) {
      group = (
        await store.call<{ data: Res }>(
          'POST',
          '/subscriptionGroups',
          { data: { type: 'subscriptionGroups', attributes: { referenceName: groupName }, relationships: { app: { data: { type: 'apps', id: input.appId } } } } },
          'Creating the subscription group',
        )
      ).data;
      say(`Gruppo "${groupName}" creato`);
    }
    const groupPages = await store.call<{ data: Res[] }>('GET', `/subscriptionGroups/${group.id}/subscriptionGroupLocalizations?limit=50`, undefined, 'Reading the group page');
    if (!groupPages.data?.some((l) => l.attributes?.locale === locale)) {
      await store.call(
        'POST',
        '/subscriptionGroupLocalizations',
        { data: { type: 'subscriptionGroupLocalizations', attributes: { locale, name: groupName }, relationships: { subscriptionGroup: { data: { type: 'subscriptionGroups', id: group.id } } } } },
        'Writing the group page',
      );
    }

    const existing = await all(store, `/subscriptionGroups/${group.id}/subscriptions?limit=50`, 'Reading the subscriptions');
    // Longer plans rank higher: Apple treats moving up as an upgrade.
    const rank = ['ONE_YEAR', 'SIX_MONTHS', 'THREE_MONTHS', 'TWO_MONTHS', 'ONE_MONTH', 'ONE_WEEK'];
    const ordered = [...subs].sort((a, b) => rank.indexOf(a.period ?? 'ONE_MONTH') - rank.indexOf(b.period ?? 'ONE_MONTH'));
    for (const [i, p] of ordered.entries()) {
      let sub = existing.find((s) => s.attributes?.productId === p.productId);
      if (!sub) {
        sub = (
          await store.call<{ data: Res }>(
            'POST',
            '/subscriptions',
            {
              data: {
                type: 'subscriptions',
                attributes: { name: p.name, productId: p.productId, subscriptionPeriod: p.period ?? 'ONE_MONTH', familySharable: false, groupLevel: i + 1 },
                relationships: { group: { data: { type: 'subscriptionGroups', id: group.id } } },
              },
            },
            `Creating ${p.productId}`,
          )
        ).data;
        say(`${p.productId} creato`);
      }
      await ensureSubscriptionPage(store, sub.id, p, locale);

      // Countries where it is sold: all of them.
      const avail = await store.call<{ data: Res | null }>('GET', `/subscriptions/${sub.id}/subscriptionAvailability`, undefined, 'Reading where it is sold').catch(() => ({ data: null }));
      if (!avail.data) {
        await store.call(
          'POST',
          '/subscriptionAvailabilities',
          {
            data: {
              type: 'subscriptionAvailabilities',
              attributes: { availableInNewTerritories: true },
              relationships: { subscription: { data: { type: 'subscriptions', id: sub.id } }, availableTerritories: { data: allTerritories.map((id) => ({ type: 'territories', id })) } },
            },
          },
          'Selling it in every country',
        );
      }

      // Price: the base country's point, then Apple's equivalent in every other country.
      const prices = await all(store, `/subscriptions/${sub.id}/prices?include=territory&limit=200`, 'Reading the prices');
      if (prices.length < allTerritories.length) {
        const points = await all(store, `/subscriptions/${sub.id}/pricePoints?filter[territory]=${base}&limit=200`, 'Reading the price points');
        const point = points.find((pp) => samePrice(pp.attributes?.customerPrice, p.price));
        if (!point) throw new Error(`Apple non ha il prezzo ${p.price} in ${base} per ${p.productId}`);
        const equal = await all(store, `/subscriptionPricePoints/${point.id}/equalizations?limit=200`, 'Reading the prices in other countries');
        const have = new Set(prices.map((x) => (x.relationships?.territory as { data?: { id?: string } } | undefined)?.data?.id));
        for (const pp of [point, ...equal]) {
          const t = /"t":"([A-Z]{3})"/.exec(Buffer.from(pp.id, 'base64url').toString())?.[1];
          if (t && have.has(t)) continue;
          await store.call(
            'POST',
            '/subscriptionPrices',
            {
              data: {
                type: 'subscriptionPrices',
                attributes: { startDate: null, preserveCurrentPrice: false },
                relationships: { subscription: { data: { type: 'subscriptions', id: sub.id } }, subscriptionPricePoint: { data: { type: 'subscriptionPricePoints', id: pp.id } } },
              },
            },
            `Price of ${p.productId}`,
          );
        }
        say(`${p.productId}: prezzo ${p.price} in ${1 + equal.length} paesi`);
      }

      // Free trial for new subscribers, in every country.
      if (p.freeTrial) {
        const offers = await all(store, `/subscriptions/${sub.id}/introductoryOffers?include=territory&limit=200`, 'Reading the free trials');
        const have = new Set(offers.map((o) => (o.relationships?.territory as { data?: { id?: string } } | undefined)?.data?.id));
        const missing = allTerritories.filter((t) => !have.has(t));
        for (const t of missing) {
          await store.call(
            'POST',
            '/subscriptionIntroductoryOffers',
            {
              data: {
                type: 'subscriptionIntroductoryOffers',
                attributes: { duration: p.freeTrial, offerMode: 'FREE_TRIAL', numberOfPeriods: 1, startDate: null, endDate: null },
                relationships: { subscription: { data: { type: 'subscriptions', id: sub.id } }, territory: { data: { type: 'territories', id: t } } },
              },
            },
            `Free trial of ${p.productId}`,
          );
        }
        if (missing.length) say(`${p.productId}: prova gratuita in ${missing.length} paesi`);
      }

      if (reviewShot) {
        const shot = await store.call<{ data: Res | null }>('GET', `/subscriptions/${sub.id}/appStoreReviewScreenshot`, undefined, 'Reading the review screenshot').catch(() => ({ data: null }));
        await ensureReviewShot(store, shot.data, 'subscriptionAppStoreReviewScreenshots', { subscription: { data: { type: 'subscriptions', id: sub.id } } }, reviewShot);
      }
      done.push(p.productId);
    }
  }

  // ---------------- one-time purchases
  for (const p of input.products.filter((x) => x.kind !== 'subscription')) {
    const iaps = await all(store, `/apps/${input.appId}/inAppPurchasesV2?limit=200`, 'Reading the in-app purchases');
    let iap = iaps.find((x) => x.attributes?.productId === p.productId);
    if (!iap) {
      iap = (
        await store.call<{ data: Res }>(
          'POST',
          'https://api.appstoreconnect.apple.com/v2/inAppPurchases',
          { data: { type: 'inAppPurchases', attributes: { name: p.name, productId: p.productId, inAppPurchaseType: p.kind === 'consumable' ? 'CONSUMABLE' : 'NON_CONSUMABLE', familySharable: false }, relationships: { app: { data: { type: 'apps', id: input.appId } } } } },
          `Creating ${p.productId}`,
        )
      ).data;
      say(`${p.productId} creato`);
    }
    const pages = await store.call<{ data: Res[] }>('GET', `https://api.appstoreconnect.apple.com/v2/inAppPurchases/${iap.id}/inAppPurchaseLocalizations?limit=50`, undefined, 'Reading the purchase page');
    if (!pages.data?.some((l) => l.attributes?.locale === locale)) {
      await store.call(
        'POST',
        '/inAppPurchaseLocalizations',
        { data: { type: 'inAppPurchaseLocalizations', attributes: { locale, name: p.name.slice(0, 30), description: p.description.slice(0, 55) }, relationships: { inAppPurchaseV2: { data: { type: 'inAppPurchases', id: iap.id } } } } },
        'Writing the purchase page',
      );
    }
    const avail = await store.call<{ data: Res | null }>('GET', `https://api.appstoreconnect.apple.com/v2/inAppPurchases/${iap.id}/inAppPurchaseAvailability`, undefined, 'Reading where it is sold').catch(() => ({ data: null }));
    if (!avail.data) {
      await store.call(
        'POST',
        '/inAppPurchaseAvailabilities',
        {
          data: {
            type: 'inAppPurchaseAvailabilities',
            attributes: { availableInNewTerritories: true },
            relationships: { inAppPurchase: { data: { type: 'inAppPurchases', id: iap.id } }, availableTerritories: { data: allTerritories.map((id) => ({ type: 'territories', id })) } },
          },
        },
        'Selling it in every country',
      );
    }
    // Apple creates an empty schedule by itself: priced means it has a manual price.
    const schedule = await store
      .call<{ data: Res | null; included?: Res[] }>('GET', `https://api.appstoreconnect.apple.com/v2/inAppPurchases/${iap.id}/iapPriceSchedule?include=manualPrices`, undefined, 'Reading the price')
      .catch(() => ({ data: null, included: [] as Res[] }));
    if (!schedule.data || !(schedule.included ?? []).some((x) => (x as { type?: string }).type === 'inAppPurchasePrices')) {
      const points = await all(store, `https://api.appstoreconnect.apple.com/v2/inAppPurchases/${iap.id}/pricePoints?filter[territory]=${base}&limit=200`, 'Reading the price points');
      const point = points.find((pp) => samePrice(pp.attributes?.customerPrice, p.price));
      if (!point) throw new Error(`Apple non ha il prezzo ${p.price} in ${base} per ${p.productId}`);
      // One base price: Apple sets the equivalent in every other country by itself.
      await store.call(
        'POST',
        '/inAppPurchasePriceSchedules',
        {
          data: {
            type: 'inAppPurchasePriceSchedules',
            relationships: {
              inAppPurchase: { data: { type: 'inAppPurchases', id: iap.id } },
              baseTerritory: { data: { type: 'territories', id: base } },
              manualPrices: { data: [{ type: 'inAppPurchasePrices', id: '${price}' }] },
            },
          },
          included: [{ type: 'inAppPurchasePrices', id: '${price}', attributes: { startDate: null }, relationships: { inAppPurchasePricePoint: { data: { type: 'inAppPurchasePricePoints', id: point.id } } } }],
        },
        `Price of ${p.productId}`,
      );
      say(`${p.productId}: prezzo ${p.price}`);
    }
    if (reviewShot) {
      const shot = await store.call<{ data: Res | null }>('GET', `https://api.appstoreconnect.apple.com/v2/inAppPurchases/${iap.id}/appStoreReviewScreenshot`, undefined, 'Reading the review screenshot').catch(() => ({ data: null }));
      await ensureReviewShot(store, shot.data, 'inAppPurchaseAppStoreReviewScreenshots', { inAppPurchaseV2: { data: { type: 'inAppPurchases', id: iap.id } } }, reviewShot);
    }
    done.push(p.productId);
  }
  return done;
}

// ---------------------------------------------------------------- from the app

/** A product as the engine declares it (EMBER_PRODUCTS) and Ember keeps it. */
export interface DeclaredProduct {
  id: string;
  /** Apple's id when it differs from Google's (Apple ids are unique across the whole account). */
  iosId?: string;
  type?: string;
  title?: string;
  description?: string;
  price?: string | number;
  period?: string;
  freeTrialDays?: number;
}

const PERIODS: Record<string, Period> = { P1W: 'ONE_WEEK', P1M: 'ONE_MONTH', P2M: 'TWO_MONTHS', P3M: 'THREE_MONTHS', P6M: 'SIX_MONTHS', P1Y: 'ONE_YEAR' };

function trialOf(days?: number): TrialLength | undefined {
  if (!days) return undefined;
  if (days <= 3) return 'THREE_DAYS';
  if (days <= 7) return 'ONE_WEEK';
  if (days <= 14) return 'TWO_WEEKS';
  return 'ONE_MONTH';
}

/**
 * Apple's products from the app's own list. On Apple a product id belongs to
 * the whole developer account, so an id another app already uses is refused:
 * unless the app says otherwise (iosId), the iPhone id is "<project>_<id>".
 */
export function appleProductsFrom(declared: DeclaredProduct[], project: string): AppleProduct[] {
  return declared
    .filter((d) => d.id && Number(d.price) > 0)
    .map((d) => {
      const kind: AppleProduct['kind'] = d.type === 'subscription' ? 'subscription' : /coin|credit|gem|token|pack/i.test(d.id) ? 'consumable' : 'non_consumable';
      const name = (d.title || d.id.replace(/_/g, ' ')).slice(0, 30);
      return {
        productId: d.iosId || `${project}_${d.id}`,
        kind,
        name,
        description: (d.description || name).slice(0, 55),
        price: Number(d.price),
        ...(kind === 'subscription' ? { period: PERIODS[d.period ?? 'P1M'] ?? 'ONE_MONTH', freeTrial: trialOf(d.freeTrialDays) } : {}),
      };
    });
}

/**
 * The first purchases of an app are reviewed together with a version: they
 * are handed in now, right before the version is sent. Returns what went in.
 */
export async function submitProductsWithVersion(store: AppStore, appId: string): Promise<string[]> {
  const sent: string[] = [];
  // Same order as the website's draft: the group, its subscriptions, then one-time purchases.
  // (A new group alone is refused: "must be submitted with an auto-renewable subscription".)
  const groups = await all(store, `/apps/${appId}/subscriptionGroups?limit=50`, 'Reading the subscription groups').catch(() => [] as Res[]);
  for (const g of groups) {
    const subs = (await all(store, `/subscriptionGroups/${g.id}/subscriptions?limit=50`, 'Reading the subscriptions')).filter((x) => x.attributes?.state === 'READY_TO_SUBMIT');
    if (!subs.length) continue;
    await store
      .call('POST', '/subscriptionGroupSubmissions', { data: { type: 'subscriptionGroupSubmissions', relationships: { subscriptionGroup: { data: { type: 'subscriptionGroups', id: g.id } } } } }, `Sending the group ${g.attributes?.referenceName ?? ''}`)
      .catch((e: unknown) => {
        // Already in the submission, or not needed for a group Apple knows: the subscriptions decide.
        if (!/already|duplicate|not.*allowed/i.test((e as Error).message)) throw e;
      });
    for (const sub of subs) {
      await store.call('POST', '/subscriptionSubmissions', { data: { type: 'subscriptionSubmissions', relationships: { subscription: { data: { type: 'subscriptions', id: sub.id } } } } }, `Sending ${sub.attributes?.productId}`);
      sent.push(`${sub.attributes?.productId}`);
    }
  }
  const iaps = await all(store, `/apps/${appId}/inAppPurchasesV2?limit=200`, 'Reading the in-app purchases').catch(() => [] as Res[]);
  for (const iap of iaps.filter((x) => x.attributes?.state === 'READY_TO_SUBMIT')) {
    await store.call('POST', '/inAppPurchaseSubmissions', { data: { type: 'inAppPurchaseSubmissions', relationships: { inAppPurchaseV2: { data: { type: 'inAppPurchases', id: iap.id } } } } }, `Sending ${iap.attributes?.productId}`);
    sent.push(`${iap.attributes?.productId}`);
  }
  return sent;
}
