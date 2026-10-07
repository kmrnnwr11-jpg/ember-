import { generateKeyPairSync } from 'node:crypto';
import { mkdtemp, readFile, rm, stat } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { ConnectError, ConnectionService, type ConnState } from './connect.js';
import { readAppleCredsPublic } from './apple_creds.js';
import { readSettings } from './settings_store.js';

let dir: string;
const OWNER = 'dev_test_owner';

/** A real key pair each, made here: the code signs and parses them for real, only the stores are pretend. */
const rsa = generateKeyPairSync('rsa', { modulusLength: 2048, privateKeyEncoding: { type: 'pkcs8', format: 'pem' }, publicKeyEncoding: { type: 'spki', format: 'pem' } });
const ec = generateKeyPairSync('ec', { namedCurve: 'P-256', privateKeyEncoding: { type: 'pkcs8', format: 'pem' }, publicKeyEncoding: { type: 'spki', format: 'pem' } });
const serviceAccount = (email = 'ember-publisher@proj.iam.gserviceaccount.com') => JSON.stringify({ type: 'service_account', client_email: email, private_key: rsa.privateKey, token_uri: 'https://oauth2.googleapis.com/token' });
const ISSUER = '69a6de70-1111-47e3-e053-5b8c7c11a4d1';

/** What each store says next, set per test. */
const stores = { google: 'ok' as 'ok' | 'revoked' | 'offline', apple: 'ok' as 'ok' | 'refused' | 'no_role', team: 'ABCDE12345' };
const fakeFetch = (async (input: string | URL | Request, init?: RequestInit) => {
  const url = String(input);
  const json = (status: number, body: unknown) => new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });
  if (url.includes('oauth2.googleapis.com')) {
    if (stores.google === 'offline') throw new TypeError('fetch failed');
    if (stores.google === 'revoked') return json(400, { error: 'invalid_grant', error_description: 'Invalid JWT Signature.' });
    return json(200, { access_token: 'ya29.fake', expires_in: 3600 });
  }
  if (url.includes('api.appstoreconnect.apple.com')) {
    expect((init?.headers as Record<string, string>).authorization).toMatch(/^Bearer ey/);
    if (stores.apple === 'refused') return json(401, { errors: [{ title: 'NOT_AUTHORIZED', detail: 'Authentication credentials are missing or invalid.' }] });
    if (stores.apple === 'no_role') return json(403, { errors: [{ title: 'FORBIDDEN_ERROR', detail: 'This request is forbidden for security reasons.' }] });
    if (url.includes('/bundleIds')) return json(200, { data: [{ id: 'b1', attributes: { seedId: stores.team } }] });
    return json(200, { data: [] });
  }
  throw new Error(`unexpected request to ${url}`);
}) as typeof fetch;

const make = (now = Date.now) => new ConnectionService({ fetchImpl: fakeFetch, now });

beforeAll(async () => {
  dir = await mkdtemp(path.join(os.tmpdir(), 'connect-'));
  process.env.EMBER_SETTINGS_DIR = path.join(dir, 'settings');
  process.env.EMBER_APPLE_DIR = path.join(dir, 'apple');
});
afterAll(async () => {
  await rm(dir, { recursive: true, force: true });
});
beforeEach(async () => {
  stores.google = 'ok';
  stores.apple = 'ok';
  await make().disconnect(OWNER, 'google_play');
  await make().disconnect(OWNER, 'apple');
});

describe('Google Play', () => {
  it('is missing until a key is connected', async () => {
    const s = await make().status(OWNER);
    expect(s.googlePlay).toMatchObject({ state: 'missing', detail: 'missing', account: '' });
    expect(s.apple.state).toBe('missing');
  });

  it('keeps a key only after Google accepts it, and shows the account, never the key', async () => {
    const c = make();
    const st = await c.connectGooglePlay(OWNER, { serviceAccount: serviceAccount(), developerId: '1234567890123456789' });
    expect(st).toMatchObject({ provider: 'google_play', state: 'connected', detail: 'ok', account: 'ember-publisher@proj.iam.gserviceaccount.com' });
    expect(JSON.stringify(st)).not.toContain('PRIVATE KEY');
    const saved = await readSettings(OWNER);
    expect(JSON.parse(saved['play_service_account']!).client_email).toBe('ember-publisher@proj.iam.gserviceaccount.com');
    expect(await c.developerId(OWNER)).toBe('1234567890123456789');
    // A new Runner reads it back from the disk.
    expect((await make().status(OWNER)).googlePlay.state).toBe('connected');
  });

  it('refuses what is not a key, and a key Google refuses, and saves nothing', async () => {
    const c = make();
    await expect(c.connectGooglePlay(OWNER, { serviceAccount: 'x'.repeat(80) })).rejects.toMatchObject({ code: 'bad_key' });
    await expect(c.connectGooglePlay(OWNER, { serviceAccount: JSON.stringify({ type: 'authorized_user', client_email: 'a@b.c', private_key: 'k'.repeat(60) }) })).rejects.toBeInstanceOf(ConnectError);
    stores.google = 'revoked';
    await expect(c.connectGooglePlay(OWNER, { serviceAccount: serviceAccount() })).rejects.toMatchObject({ code: 'key_refused' });
    await expect(c.connectGooglePlay(OWNER, { serviceAccount: serviceAccount(), developerId: 'abc' })).rejects.toMatchObject({ code: 'key_refused' });
    expect((await readSettings(OWNER))['play_service_account']).toBeUndefined();
    expect((await c.status(OWNER, { fresh: true })).googlePlay.state).toBe('missing');
  });

  it('checks the developer id only when the key is good', async () => {
    await expect(make().connectGooglePlay(OWNER, { serviceAccount: serviceAccount(), developerId: 'not-a-number' })).rejects.toMatchObject({ code: 'bad_developer_id' });
  });

  it('says so when the internet is down, instead of calling the key bad', async () => {
    stores.google = 'offline';
    await expect(make().connectGooglePlay(OWNER, { serviceAccount: serviceAccount() })).rejects.toMatchObject({ code: 'offline' });
    stores.google = 'ok';
    const c = make();
    await c.connectGooglePlay(OWNER, { serviceAccount: serviceAccount() });
    stores.google = 'offline';
    expect((await c.verify(OWNER, 'google_play')).state).toBe('unreachable');
  });

  it('notices a key that was revoked later, and tells the listeners', async () => {
    const c = make();
    await c.connectGooglePlay(OWNER, { serviceAccount: serviceAccount() });
    const seen: Array<[ConnState, ConnState | undefined]> = [];
    c.onChange((_o, st, before) => void seen.push([st.state, before]));
    stores.google = 'revoked';
    expect(await c.verify(OWNER, 'google_play')).toMatchObject({ state: 'invalid', detail: 'key_refused', account: 'ember-publisher@proj.iam.gserviceaccount.com' });
    stores.google = 'ok';
    expect((await c.verify(OWNER, 'google_play')).state).toBe('connected');
    expect(seen).toEqual([['invalid', 'connected'], ['connected', 'invalid']]);
  });

  it('does not ask Google again within the time to live', async () => {
    let now = 1_000_000;
    let asked = 0;
    const counting = new ConnectionService({ fetchImpl: ((i: string | URL | Request, init?: RequestInit) => (asked++, fakeFetch(i, init))) as typeof fetch, now: () => now, ttlMs: 60_000 });
    await counting.connectGooglePlay(OWNER, { serviceAccount: serviceAccount() });
    const afterConnect = asked;
    await counting.status(OWNER);
    await counting.status(OWNER);
    expect(asked).toBe(afterConnect);
    now += 61_000;
    await counting.status(OWNER);
    expect(asked).toBe(afterConnect + 1);
  });
});

describe('Apple', () => {
  const input = () => ({ keyId: 'Z47GM3ZDZ6', issuerId: ISSUER, privateKey: ec.privateKey });

  it('keeps a key only after Apple accepts it, finds the team, and shows the Key ID, never the key', async () => {
    const st = await make().connectApple(OWNER, input());
    expect(st).toMatchObject({ provider: 'apple', state: 'connected', account: 'Z47GM3ZDZ6', teamId: 'ABCDE12345' });
    expect(JSON.stringify(st)).not.toContain('PRIVATE KEY');
    expect(await readAppleCredsPublic()).toMatchObject({ hasKey: true, keyId: 'Z47GM3ZDZ6', issuerId: ISSUER, teamId: 'ABCDE12345' });
    expect((await make().status(OWNER)).apple.state).toBe('connected');
  });

  it('refuses a bad file, a key Apple refuses and a key without a role, and saves nothing', async () => {
    await expect(make().connectApple(OWNER, { ...input(), privateKey: 'AuthKey_Z47GM3ZDZ6.p8' })).rejects.toMatchObject({ code: 'bad_key' });
    await expect(make().connectApple(OWNER, { ...input(), keyId: 'no' })).rejects.toMatchObject({ code: 'bad_key' });
    await expect(make().connectApple(OWNER, { ...input(), issuerId: 'nope' })).rejects.toMatchObject({ code: 'bad_key' });
    stores.apple = 'refused';
    await expect(make().connectApple(OWNER, input())).rejects.toMatchObject({ code: 'key_refused' });
    stores.apple = 'no_role';
    await expect(make().connectApple(OWNER, input())).rejects.toMatchObject({ code: 'no_permission' });
    expect((await readAppleCredsPublic()).hasKey).toBe(false);
  });

  it('notices later that Apple took the key away', async () => {
    const c = make();
    await c.connectApple(OWNER, input());
    stores.apple = 'refused';
    expect(await c.verify(OWNER, 'apple')).toMatchObject({ state: 'invalid', detail: 'key_refused', account: 'Z47GM3ZDZ6' });
    stores.apple = 'no_role';
    expect(await c.verify(OWNER, 'apple')).toMatchObject({ state: 'invalid', detail: 'no_permission' });
  });

  it('lets the owner change only the IDs of the key already saved', async () => {
    const c = make();
    await c.connectApple(OWNER, input());
    const again = await c.connectApple(OWNER, { keyId: 'Z47GM3ZDZ6', issuerId: '11111111-2222-3333-4444-555555555555' });
    expect(again.state).toBe('connected');
    expect((await readAppleCredsPublic()).issuerId).toBe('11111111-2222-3333-4444-555555555555');
  });
});

describe('disconnecting and watching', () => {
  it('forgets each account on this computer', async () => {
    const c = make();
    await c.connectGooglePlay(OWNER, { serviceAccount: serviceAccount() });
    await c.connectApple(OWNER, { keyId: 'Z47GM3ZDZ6', issuerId: ISSUER, privateKey: ec.privateKey });
    expect((await c.disconnect(OWNER, 'google_play')).state).toBe('missing');
    expect((await c.disconnect(OWNER, 'apple')).state).toBe('missing');
    expect((await readSettings(OWNER))['play_service_account']).toBeUndefined();
    await expect(stat(path.join(dir, 'apple', 'AuthKey_Z47GM3ZDZ6.p8'))).rejects.toThrow();
    expect(await readFile(path.join(dir, 'apple', 'credentials.json'), 'utf8').catch(() => 'gone')).toBe('gone');
  });

  it('the monitor looks again on its own and reports a change', async () => {
    const c = make();
    await c.connectGooglePlay(OWNER, { serviceAccount: serviceAccount() });
    const changes: ConnState[] = [];
    c.onChange((_o, st) => void changes.push(st.state));
    c.monitor(OWNER, 20);
    stores.google = 'revoked';
    for (let i = 0; i < 100 && !changes.includes('invalid'); i++) await new Promise((r) => setTimeout(r, 10));
    c.stop();
    expect(changes).toContain('invalid');
  });
});
