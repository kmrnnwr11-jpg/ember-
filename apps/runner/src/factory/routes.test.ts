import { mkdtemp, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../app.js';
import { Authenticator } from '../auth.js';
import { loadConfig, type Config } from '../config.js';

/** The Factory routes against the whole Runner, with pretend stages (no engine, no build, no network). */
let app: FastifyInstance;
let cfg: Config;
let dir: string;
let auth: Record<string, string>;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function get(url: string) {
  const res = await app.inject({ method: 'GET', url, headers: auth });
  return { status: res.statusCode, body: res.json() as Record<string, any> };
}
async function send(method: 'POST' | 'PATCH' | 'DELETE', url: string, payload?: unknown) {
  const res = await app.inject({ method, url, headers: payload === undefined ? auth : { ...auth, 'content-type': 'application/json' }, ...(payload === undefined ? {} : { payload: JSON.stringify(payload) }) });
  return { status: res.statusCode, body: (res.body ? res.json() : {}) as Record<string, any> };
}

beforeAll(async () => {
  dir = await mkdtemp(path.join(os.tmpdir(), 'factory-routes-'));
  // Settings and Apple key are only read here, from folders that do not exist: the owner's real ones stay untouched.
  process.env.EMBER_SETTINGS_DIR = path.join(dir, 'settings');
  process.env.EMBER_APPLE_DIR = path.join(dir, 'apple');
  cfg = loadConfig({
    DEV_AUTH: 'true',
    LOG_LEVEL: 'silent',
    DATA_DIR: path.join(dir, 'data'),
    WORKSPACES_ROOT: path.join(dir, 'ws'),
    EMBER_FACTORY_SIMULATE: 'true',
    EMBER_FACTORY_SIM_SPEED: '0.01',
  });
  ({ app } = await buildApp(cfg));
  const { token } = await new Authenticator(cfg).issueDevToken('factory@test.dev');
  auth = { authorization: `Bearer ${token}` };
});

afterAll(async () => {
  await app.close();
  await rm(dir, { recursive: true, force: true });
});

describe('/v1/factory', () => {
  it('needs a signed-in user, and the in-process secret cannot be guessed', async () => {
    expect((await app.inject({ method: 'GET', url: '/v1/factory' })).statusCode).toBe(401);
    const forged = await app.inject({ method: 'GET', url: '/v1/factory', headers: { 'x-ember-user': 'someone', 'x-ember-internal': 'guess' } });
    expect(forged.statusCode).toBe(401);
  });

  it('starts empty, says it is simulated, and answers "unchanged" to an up-to-date client', async () => {
    const { status, body } = await get('/v1/factory');
    expect(status).toBe(200);
    expect(body).toMatchObject({ paused: false, simulated: true, apps: [], batches: [], needsYou: [], summary: { total: 0 } });
    expect(body.settings.dailyStoreCap).toEqual({ play: 10, appstore: 10 });
    expect(body.uploads).toMatchObject({ play: 0, appstore: 0, cap: { play: 10, appstore: 10 } });
    const again = await get(`/v1/factory?rev=${body.rev}`);
    expect(again.body).toEqual({ unchanged: true, rev: body.rev });
  });

  it('lists what is connected and what this computer can carry', async () => {
    const { status, body } = await get('/v1/factory/connections');
    expect(status).toBe(200);
    for (const name of ['claude', 'qwen', 'gemini', 'codex', 'flutter', 'android', 'chrome', 'playKey', 'appleKey', 'mac']) {
      expect(body.links[name], name).toMatchObject({ ready: expect.any(Boolean), detail: expect.any(String) });
    }
    expect(body.capacity.cpus).toBeGreaterThan(0);
    expect(body.capacity.suggested.lanes.build).toBeGreaterThanOrEqual(1);
    expect(body.simulated).toBe(true);
  });

  it('turns a theme into app cards with an engine each', async () => {
    const { status, body } = await send('POST', '/v1/factory/plan', { text: 'apps for people who love gardening', count: 8, engines: { 'claude-code': 1, 'qwen-code': 1 } });
    expect(status).toBe(200);
    expect(body.apps).toHaveLength(8);
    expect(body.source).toBe('supervisor');
    expect(new Set(body.apps.map((a: { name: string }) => a.name)).size).toBe(8);
    expect(body.apps.every((a: { engine: string; summary: string; brief: string }) => ['claude-code', 'qwen-code'].includes(a.engine) && a.summary && a.brief)).toBe(true);
    // The big apps are Claude's.
    expect(body.apps.filter((a: { size: string }) => a.size === 'big').every((a: { engine: string }) => a.engine === 'claude-code')).toBe(true);
    expect(body.warnings).toEqual([]);
  });

  it('refuses an empty plan or a batch with no apps', async () => {
    expect((await send('POST', '/v1/factory/plan', { text: '' })).status).toBe(400);
    expect((await send('POST', '/v1/factory/batches', { name: 'x', apps: [] })).status).toBe(400);
    expect((await send('POST', '/v1/factory/batches', { name: 'x', apps: Array.from({ length: 101 }, (_, i) => ({ name: `a${i}`, summary: 'does a thing' })) })).status).toBe(400);
  });

  it('runs a batch of apps to the end, and shows each app with its stages', async () => {
    const apps = Array.from({ length: 6 }, (_, i) => ({ name: `Garden ${i}`, summary: `Garden helper number ${i} for the balcony`, size: i === 0 ? 'big' : 'small' }));
    const created = await send('POST', '/v1/factory/batches', { name: 'Garden', apps, recipe: { goal: 'assets', engines: { 'claude-code': 1 } } });
    expect(created.status).toBe(201);
    expect(created.body.batchId).toBeTruthy();
    let state: Record<string, any> = {};
    for (let i = 0; i < 400; i++) {
      state = (await get('/v1/factory')).body;
      if (state.summary.done + state.summary.failed === 6) break;
      await sleep(100);
    }
    expect(state.summary.total).toBe(6);
    expect(state.summary.done + state.summary.failed).toBe(6);
    expect(state.batches[0]).toMatchObject({ name: 'Garden', recipe: { goal: 'assets' } });
    const first = state.apps[0];
    expect(first).toMatchObject({ name: 'Garden 0', size: 'big', engine: 'claude-code', folder: 'garden_0' });
    expect(Object.keys(first.stages)).toEqual(['create', 'code', 'verify', 'preview', 'logo', 'listing', 'shots', 'android', 'play', 'ios', 'appstore']);
    expect(first.stages.android).toMatchObject({ state: 'skipped', message: 'outside' });
    expect(first.log.length).toBeLessThanOrEqual(8);
    // The detail view has the whole brief and log.
    const detail = await get(`/v1/factory/apps/${first.id}`);
    expect(detail.body.brief).toContain('Garden helper');
    expect((await get('/v1/factory/apps/nope')).status).toBe(404);
  });

  it('pauses, resumes and changes settings, with limits kept sane', async () => {
    expect((await send('POST', '/v1/factory/pause')).body).toMatchObject({ paused: true });
    expect((await get('/v1/factory')).body.paused).toBe(true);
    expect((await send('POST', '/v1/factory/resume')).body).toMatchObject({ paused: false });
    const patched = await send('PATCH', '/v1/factory/settings', { dailyStoreCap: { play: 3 }, maxInFlight: 500 });
    expect(patched.status).toBe(400);
    const ok = await send('PATCH', '/v1/factory/settings', { dailyStoreCap: { play: 3 }, lanes: { build: 2 }, maxInFlight: 7 });
    expect(ok.status).toBe(200);
    expect(ok.body.settings).toMatchObject({ dailyStoreCap: { play: 3, appstore: 10 }, maxInFlight: 7, lanes: { build: 2 } });
  });

  it('retries, cancels and removes apps, one by one and in bulk', async () => {
    const created = await send('POST', '/v1/factory/batches', { name: 'Slow', apps: [{ name: 'Slow One', summary: 'a slow app that waits' }, { name: 'Slow Two', summary: 'another slow app that waits' }], recipe: { goal: 'ios' } });
    expect(created.status).toBe(201);
    await send('POST', '/v1/factory/pause');
    const state = (await get('/v1/factory')).body;
    const ids = state.apps.filter((a: { name: string }) => a.name.startsWith('Slow')).map((a: { id: string }) => a.id);
    expect(ids).toHaveLength(2);
    expect((await send('POST', `/v1/factory/apps/${ids[0]}/cancel`)).body.ok).toBe(true);
    expect((await get(`/v1/factory/apps/${ids[0]}`)).body.state).toBe('cancelled');
    expect((await send('POST', `/v1/factory/apps/${ids[0]}/retry`, {})).body.ok).toBe(true);
    expect((await get(`/v1/factory/apps/${ids[0]}`)).body.state).toBe('queued');
    expect((await send('POST', '/v1/factory/apps/bulk', { ids, action: 'cancel' })).body.done).toBe(2);
    expect((await send('POST', '/v1/factory/apps/bulk', { ids, action: 'delete' })).body.done).toBe(2);
    expect((await get(`/v1/factory/apps/${ids[0]}`)).status).toBe(404);
    expect((await send('POST', '/v1/factory/apps/nope/retry', {})).status).toBe(404);
    await send('POST', '/v1/factory/resume');
  });
});

describe('the Runner calling its own routes', () => {
  it('sends a body only when there is one (Fastify refuses a JSON content type without a body)', async () => {
    const { default: Fastify } = await import('fastify');
    const { internalCall, INTERNAL_HEADERS } = await import('./wire.js');
    const inner = Fastify();
    const seen: Array<{ url: string; user?: string; body: unknown }> = [];
    for (const url of ['/nobody', '/withbody']) {
      inner.post(url, async (req) => {
        if (req.headers[INTERNAL_HEADERS.secret] !== 's3cret') return { code: 'denied' };
        seen.push({ url, user: req.headers[INTERNAL_HEADERS.user] as string, body: req.body });
        return { ok: true };
      });
    }
    const call = internalCall(inner, 's3cret');
    expect(await call('owner1', 'POST', '/nobody')).toEqual({ status: 200, json: { ok: true } });
    expect(await call('owner1', 'POST', '/withbody', { a: 1 })).toEqual({ status: 200, json: { ok: true } });
    expect(seen).toEqual([
      { url: '/nobody', user: 'owner1', body: undefined },
      { url: '/withbody', user: 'owner1', body: { a: 1 } },
    ]);
    await inner.close();
  });
});
