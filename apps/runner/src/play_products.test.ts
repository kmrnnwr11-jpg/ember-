import { describe, expect, it } from 'vitest';
import { explainProductError, syncProducts, toMicros, toMoney, validateProduct } from './play_products.js';
import { generateKeyPairSync } from 'node:crypto';

const key = generateKeyPairSync('rsa', { modulusLength: 2048 }).privateKey.export({ type: 'pkcs8', format: 'pem' }).toString();
const sa = { client_email: 'ember@test.iam.gserviceaccount.com', private_key: key };

describe('Play products', () => {
  it('converts prices', () => {
    expect(toMoney('4.99', 'eur')).toEqual({ currencyCode: 'EUR', units: '4', nanos: 990000000 });
    expect(toMicros('39,9')).toBe('39900000');
  });

  it('validates specs', () => {
    expect(validateProduct({ id: 'premium_monthly', type: 'subscription', title: 'Premium', description: '', price: '4.99', currency: 'EUR', period: 'P1M' })).toBeNull();
    expect(validateProduct({ id: 'Premium!', type: 'inapp', title: 'x', description: '', price: '1', currency: 'EUR' })).toContain('id');
    expect(validateProduct({ id: 'p', type: 'subscription', title: 'x', description: '', price: '1', currency: 'EUR' })).toContain('period');
  });

  it('creates a one-time product and an active subscription', async () => {
    const calls: Array<{ method: string; url: string }> = [];
    const fake = (async (url: string | URL | Request, init?: RequestInit) => {
      const u = String(url);
      calls.push({ method: init?.method ?? 'GET', url: u });
      if (u.includes('oauth2')) return new Response('{"access_token":"t"}', { status: 200 });
      if (u.endsWith('pricing:convertRegionPrices')) {
        return new Response(JSON.stringify({ convertedRegionPrices: { IT: { regionCode: 'IT', price: { currencyCode: 'EUR', units: '4', nanos: 990000000 } } }, convertedOtherRegionsPrice: { usdPrice: {}, eurPrice: {} } }), { status: 200 });
      }
      return new Response('{}', { status: 200 });
    }) as typeof fetch;
    const results = await syncProducts(
      {
        serviceAccount: sa,
        packageName: 'com.demo.app',
        products: [
          { id: 'coins_100', type: 'inapp', title: '100 coins', description: 'Coins', price: '0.99', currency: 'EUR' },
          { id: 'premium', type: 'subscription', title: 'Premium', description: 'All features', price: '4.99', currency: 'EUR', period: 'P1M' },
        ],
      },
      fake,
    );
    expect(results).toEqual([
      { id: 'coins_100', ok: true, status: 'active' },
      { id: 'premium', ok: true, status: 'active' },
    ]);
    expect(calls.some((c) => c.method === 'PUT' && c.url.includes('/inappproducts/coins_100?autoConvertMissingPrices=true'))).toBe(true);
    expect(calls.some((c) => c.method === 'PATCH' && c.url.includes('/subscriptions/premium?'))).toBe(true);
    expect(calls.some((c) => c.url.endsWith('/basePlans/monthly:activate'))).toBe(true);
  });

  it('sells everywhere else when a country changed its money', async () => {
    // Bulgaria moved from lev to euro: Google converts the price to EUR and
    // then refuses it. The subscription must still go live in every other country.
    const bodies: string[] = [];
    const fake = (async (url: string | URL | Request, init?: RequestInit) => {
      const u = String(url);
      if (u.includes('oauth2')) return new Response('{"access_token":"t"}', { status: 200 });
      if (u.endsWith('pricing:convertRegionPrices')) {
        return new Response(
          JSON.stringify({
            convertedRegionPrices: {
              IT: { regionCode: 'IT', price: { currencyCode: 'EUR', units: '4', nanos: 990000000 } },
              BG: { regionCode: 'BG', price: { currencyCode: 'EUR', units: '4', nanos: 990000000 } },
              MN: { regionCode: 'MN', price: { currencyCode: 'MNT', units: '15000', nanos: 0 } },
            },
          }),
          { status: 200 },
        );
      }
      if ((init?.method ?? 'GET') === 'PATCH' && u.includes('/subscriptions/')) {
        const body = typeof init?.body === 'string' ? init.body : '';
        bodies.push(body);
        if (body.includes('"BG"')) {
          return new Response(JSON.stringify({ error: { message: 'Invalid currency for region code BG at the specified regions version 2022/02. Expected BGN but got EUR.' } }), { status: 400 });
        }
        // The same problem, worded another way, must be understood too.
        if (body.includes('"MN"')) {
          return new Response(JSON.stringify({ error: { message: 'Region code MN is not billable at the specified regions version 2022/02.' } }), { status: 400 });
        }
      }
      return new Response('{}', { status: 200 });
    }) as typeof fetch;

    const [res] = await syncProducts(
      { serviceAccount: sa, packageName: 'com.demo.app', products: [{ id: 'premium', type: 'subscription', title: 'Premium', description: 'All', price: '4.99', currency: 'EUR', period: 'P1M' }] },
      fake,
    );
    expect(res).toMatchObject({ id: 'premium', ok: true, status: 'active' });
    expect(res!.error).toContain('BG');
    expect(res!.error).toContain('MN');
    expect(bodies.at(-1)).toContain('"IT"');
    expect(bodies.at(-1)).not.toContain('"BG"');
    expect(bodies.at(-1)).not.toContain('"MN"');
  });

  it('explains the usual Google errors', () => {
    expect(explainProductError(403, 'The caller does not have permission')).toContain('Manage orders and subscriptions');
    expect(explainProductError(400, 'This app does not have BILLING permission')).toContain('upload the AAB');
  });
});
