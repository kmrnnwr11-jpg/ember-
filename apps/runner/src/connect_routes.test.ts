import { mkdtemp, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from './app.js';
import { Authenticator } from './auth.js';
import { loadConfig } from './config.js';

/** The /v1/connect routes in the whole Runner. Only what needs no store is exercised here: the stores themselves are in connect.test.ts. */
let app: FastifyInstance;
let dir: string;
let auth: Record<string, string>;

const call = async (method: 'GET' | 'PUT' | 'POST' | 'DELETE', url: string, payload?: unknown) => {
  const res = await app.inject({ method, url, headers: payload === undefined ? auth : { ...auth, 'content-type': 'application/json' }, ...(payload === undefined ? {} : { payload: JSON.stringify(payload) }) });
  return { status: res.statusCode, body: (res.body ? res.json() : {}) as Record<string, any> };
};

beforeAll(async () => {
  dir = await mkdtemp(path.join(os.tmpdir(), 'connect-routes-'));
  process.env.EMBER_SETTINGS_DIR = path.join(dir, 'settings');
  process.env.EMBER_APPLE_DIR = path.join(dir, 'apple');
  const cfg = loadConfig({ DEV_AUTH: 'true', LOG_LEVEL: 'silent', DATA_DIR: path.join(dir, 'data'), WORKSPACES_ROOT: path.join(dir, 'ws'), EMBER_FACTORY_SIMULATE: 'true' });
  ({ app } = await buildApp(cfg));
  const { token } = await new Authenticator(cfg).issueDevToken('connect@test.dev');
  auth = { authorization: `Bearer ${token}` };
});
afterAll(async () => {
  await app.close();
  await rm(dir, { recursive: true, force: true });
});

describe('/v1/connect', () => {
  it('needs a signed-in user', async () => {
    expect((await app.inject({ method: 'GET', url: '/v1/connect' })).statusCode).toBe(401);
  });

  it('starts with nothing connected and says where to make the keys', async () => {
    const { status, body } = await call('GET', '/v1/connect');
    expect(status).toBe(200);
    expect(body.googlePlay).toMatchObject({ provider: 'google_play', state: 'missing' });
    expect(body.apple).toMatchObject({ provider: 'apple', state: 'missing' });
    expect(typeof body.gcloud.installed).toBe('boolean');
    expect(body.links.appStoreKeys).toContain('appstoreconnect.apple.com');
    expect(body.links.playApiAccess).toContain('play.google.com');
    expect(JSON.stringify(body)).not.toMatch(/PRIVATE KEY/);
  });

  it('refuses things that are not keys before asking any store', async () => {
    const g = await call('PUT', '/v1/connect/google-play', { serviceAccount: 'x'.repeat(80) });
    expect(g.status).toBe(422);
    expect(g.body).toMatchObject({ code: 'bad_key' });
    expect((await call('PUT', '/v1/connect/google-play', { serviceAccount: 'short' })).status).toBe(400);
    const a = await call('PUT', '/v1/connect/apple', { keyId: 'Z47GM3ZDZ6', issuerId: 'not-an-uuid', privateKey: '-----BEGIN PRIVATE KEY-----\nx\n-----END PRIVATE KEY-----' });
    expect(a.status).toBe(422);
    expect(a.body).toMatchObject({ code: 'bad_key' });
    expect((await call('PUT', '/v1/connect/apple', { keyId: 'Z47GM3ZDZ6' })).status).toBe(400);
  });

  it('checks and disconnects by name, and knows only two accounts', async () => {
    expect((await call('POST', '/v1/connect/google-play/verify')).body).toMatchObject({ provider: 'google_play', state: 'missing' });
    expect((await call('POST', '/v1/connect/apple/verify')).body).toMatchObject({ provider: 'apple', state: 'missing' });
    expect((await call('DELETE', '/v1/connect/apple')).body).toMatchObject({ state: 'missing' });
    expect((await call('DELETE', '/v1/connect/google-play')).body).toMatchObject({ state: 'missing' });
    expect((await call('POST', '/v1/connect/amazon/verify')).status).toBe(400);
  });

  it('shows the store accounts as the Factory readiness lines', async () => {
    const { body } = await call('GET', '/v1/factory/connections');
    expect(body.links.playKey).toMatchObject({ ready: false, detail: 'missing' });
    expect(body.links.appleKey).toMatchObject({ ready: false, detail: 'missing' });
  });
});
