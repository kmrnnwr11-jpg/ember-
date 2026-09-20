import { getAccessToken, PlayError, type ServiceAccount } from './play.js';

/**
 * Creates and activates in-app products on Google Play (Android Publisher v3):
 * one-time products (`inappproducts`, prices auto-converted to every country)
 * and subscriptions with a base plan (`monetization.subscriptions`, prices
 * converted with `pricing:convertRegionPrices`, then the base plan is activated).
 */

const API = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';
const REGIONS_VERSION = '2022/02';

export interface ProductSpec {
  /** Product id used in the app code, e.g. `premium_monthly`. */
  id: string;
  type: 'inapp' | 'subscription';
  title: string;
  description: string;
  /** Price in the major unit, e.g. "4.99". */
  price: string;
  currency: string;
  /** Subscriptions only: ISO-8601 billing period (P1W, P1M, P3M, P6M, P1Y). */
  period?: string;
  /** Subscriptions only: free trial length in days (0 = none). */
  freeTrialDays?: number;
  language?: string;
}

export interface ProductResult {
  id: string;
  ok: boolean;
  status?: 'active' | 'created';
  error?: string;
}

type Fetch = typeof fetch;

/** "4.99" → { units: "4", nanos: 990000000 } (Money). */
export function toMoney(price: string, currency: string) {
  const [whole, frac = ''] = price.trim().replace(',', '.').split('.');
  const nanos = Number((frac + '000000000').slice(0, 9));
  return { currencyCode: currency.toUpperCase(), units: String(Number(whole) || 0), nanos };
}

/** "4.99" → "4990000" (micros, for the legacy inappproducts API). */
export function toMicros(price: string): string {
  const m = toMoney(price, 'X');
  return String(Number(m.units) * 1_000_000 + Math.round(m.nanos / 1000));
}

export function validateProduct(p: ProductSpec): string | null {
  if (!/^[a-z0-9][a-z0-9._]{0,138}$/.test(p.id)) return 'id must start with a lowercase letter or digit and use only a-z, 0-9, "_" and "."';
  if (!/^\d+([.,]\d{1,2})?$/.test(p.price.trim())) return 'price must look like 4.99';
  if (!/^[A-Za-z]{3}$/.test(p.currency)) return 'currency must be a 3-letter code like EUR';
  if (p.type === 'subscription' && !/^P(\d+W|\d+M|\d+Y)$/.test(p.period ?? '')) return 'subscriptions need a period like P1M or P1Y';
  if (!p.title.trim() || p.title.length > 55) return 'title must be 1-55 characters';
  return null;
}

async function call(fetchImpl: Fetch, token: string, method: string, url: string, body?: unknown) {
  const res = await fetchImpl(url, {
    method,
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json: Record<string, unknown> = {};
  try {
    json = text ? (JSON.parse(text) as Record<string, unknown>) : {};
  } catch {
    // non-JSON error page
  }
  return { res, json, message: (json.error as { message?: string } | undefined)?.message ?? `${res.status} ${res.statusText}` };
}

/** Human explanation for the errors Google returns most often. */
export function explainProductError(status: number, message: string): string {
  if (/billing permission|does not have billing|BILLING/i.test(message)) {
    return 'Google Play needs an app version with Google Play Billing uploaded first (upload the AAB to internal testing), then try again.';
  }
  if (/payments profile|merchant/i.test(message)) {
    return 'Set up your payments profile in Play Console → Setup → Payments profile (bank account and tax info), then try again.';
  }
  if (status === 401 || status === 403) {
    return 'Permission denied: in Play Console → Users and permissions, give the service account "Manage store presence" and "Manage orders and subscriptions" for this app.';
  }
  if (status === 404) return 'App not found on Google Play: create it in Play Console with this package name and upload the AAB once.';
  return `Google Play: ${message}`;
}

async function upsertInApp(fetchImpl: Fetch, token: string, pkg: string, p: ProductSpec): Promise<ProductResult> {
  const lang = p.language ?? 'it-IT';
  const body = {
    packageName: pkg,
    sku: p.id,
    status: 'active',
    purchaseType: 'managedUser',
    defaultLanguage: lang,
    defaultPrice: { priceMicros: toMicros(p.price), currency: p.currency.toUpperCase() },
    listings: { [lang]: { title: p.title, description: p.description || p.title } },
  };
  const r = await call(fetchImpl, token, 'PUT', `${API}/${pkg}/inappproducts/${encodeURIComponent(p.id)}?autoConvertMissingPrices=true&allowMissing=true`, body);
  if (!r.res.ok) return { id: p.id, ok: false, error: explainProductError(r.res.status, r.message) };
  return { id: p.id, ok: true, status: 'active' };
}

async function upsertSubscription(fetchImpl: Fetch, token: string, pkg: string, p: ProductSpec): Promise<ProductResult> {
  const lang = p.language ?? 'it-IT';
  // Prices for every region from one price.
  const conv = await call(fetchImpl, token, 'POST', `${API}/${pkg}/pricing:convertRegionPrices`, { price: toMoney(p.price, p.currency) });
  if (!conv.res.ok) return { id: p.id, ok: false, error: explainProductError(conv.res.status, conv.message) };
  const converted = (conv.json.convertedRegionPrices ?? {}) as Record<string, { regionCode: string; price: unknown }>;
  const other = conv.json.convertedOtherRegionsPrice as { usdPrice?: unknown; eurPrice?: unknown } | undefined;
  const basePlanId = p.period === 'P1Y' ? 'yearly' : p.period === 'P1W' ? 'weekly' : p.period === 'P1M' ? 'monthly' : `plan-${p.period!.slice(1).toLowerCase()}`;
  const trial = p.freeTrialDays && p.freeTrialDays > 0;
  const subscription = {
    packageName: pkg,
    productId: p.id,
    // An app's default language on Play is usually en-US, and Google refuses a
    // subscription that has no listing in it. Ship both from the start.
    listings: [lang, ...(lang === 'en-US' ? [] : ['en-US'])].map((languageCode) => ({
      languageCode,
      title: p.title,
      description: (p.description || p.title).slice(0, 80),
    })),
    basePlans: [
      {
        basePlanId,
        state: 'DRAFT',
        autoRenewingBasePlanType: { billingPeriodDuration: p.period, legacyCompatible: true },
        regionalConfigs: Object.values(converted).map((c) => ({ regionCode: c.regionCode, price: c.price, newSubscriberAvailability: true })),
        ...(other ? { otherRegionsConfig: { usdPrice: other.usdPrice, eurPrice: other.eurPrice, newSubscriberAvailability: true } } : {}),
      },
    ],
  };
  const url = `${API}/${pkg}/subscriptions/${encodeURIComponent(p.id)}?updateMask=listings,basePlans&allowMissing=true&regionsVersion.version=${REGIONS_VERSION}`;
  // A country can change its money (Bulgaria: lev → euro), and Google then
  // refuses the price it converted itself. Drop the countries it argues about
  // and sell everywhere else, rather than failing the whole subscription.
  const dropped: string[] = [];
  let up = await call(fetchImpl, token, 'PATCH', url, subscription);
  // Google insists on a listing in the app's own default language, whatever the
  // product was written in: add it with the same words and try again.
  const missingLanguage = /default language of the app:\s*([\w-]+)/i.exec(up.message)?.[1];
  if (!up.res.ok && missingLanguage) {
    subscription.listings = [...subscription.listings, { ...subscription.listings[0]!, languageCode: missingLanguage }];
    up = await call(fetchImpl, token, 'PATCH', url, subscription);
  }
  for (let i = 0; i < 12 && !up.res.ok; i++) {
    // Google names the country in several ways: a changed currency, a country
    // it will not bill in, a region it does not know at this regions version.
    const region = /region\s*code\s*"?([A-Z]{2})/i.exec(up.message)?.[1];
    if (!region) break;
    dropped.push(region);
    const keep = (c: { regionCode: string }) => !dropped.includes(c.regionCode);
    subscription.basePlans[0]!.regionalConfigs = subscription.basePlans[0]!.regionalConfigs.filter(keep);
    up = await call(fetchImpl, token, 'PATCH', url, subscription);
  }
  if (!up.res.ok) return { id: p.id, ok: false, error: explainProductError(up.res.status, up.message) };

  const keptRegions = subscription.basePlans[0]!.regionalConfigs.map((c) => c.regionCode);
  if (trial) {
    const offer = {
      packageName: pkg,
      productId: p.id,
      basePlanId,
      offerId: 'free-trial',
      phases: [{ recurrenceCount: 1, duration: `P${p.freeTrialDays}D`, regionalConfigs: keptRegions.map((regionCode) => ({ regionCode, free: {} })), otherRegionsConfig: { free: {} } }],
      targeting: { acquisitionRule: { scope: { anySubscriptionInApp: {} } } },
      regionalConfigs: keptRegions.map((regionCode) => ({ regionCode, newSubscriberAvailability: true })),
      otherRegionsConfig: { otherRegionsNewSubscriberAvailability: true },
    };
    const o = await call(fetchImpl, token, 'POST', `${API}/${pkg}/subscriptions/${encodeURIComponent(p.id)}/basePlans/${basePlanId}/offers?offerId=free-trial&regionsVersion.version=${REGIONS_VERSION}`, offer);
    if (o.res.ok || o.res.status === 409) {
      await call(fetchImpl, token, 'POST', `${API}/${pkg}/subscriptions/${encodeURIComponent(p.id)}/basePlans/${basePlanId}/offers/free-trial:activate`, {});
    }
  }

  const act = await call(fetchImpl, token, 'POST', `${API}/${pkg}/subscriptions/${encodeURIComponent(p.id)}/basePlans/${basePlanId}:activate`, {});
  if (!act.res.ok && !/already active/i.test(act.message)) {
    return { id: p.id, ok: false, status: 'created', error: explainProductError(act.res.status, act.message) };
  }
  return {
    id: p.id,
    ok: true,
    status: 'active',
    ...(dropped.length > 0 ? { error: `On sale everywhere except ${dropped.join(', ')}: Google would not accept the converted price there. Set those prices by hand in Play Console if you want them.` } : {}),
  };
}

/** Creates or updates every product, one by one, and reports each result. */
export async function syncProducts(input: { serviceAccount: ServiceAccount; packageName: string; products: ProductSpec[] }, fetchImpl: Fetch = fetch): Promise<ProductResult[]> {
  const token = await getAccessToken(input.serviceAccount, fetchImpl);
  const results: ProductResult[] = [];
  for (const p of input.products) {
    const invalid = validateProduct(p);
    if (invalid) {
      results.push({ id: p.id, ok: false, error: invalid });
      continue;
    }
    try {
      results.push(p.type === 'subscription' ? await upsertSubscription(fetchImpl, token, input.packageName, p) : await upsertInApp(fetchImpl, token, input.packageName, p));
    } catch (e) {
      results.push({ id: p.id, ok: false, error: e instanceof PlayError ? e.message : (e as Error).message });
    }
  }
  return results;
}
