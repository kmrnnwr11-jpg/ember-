import { createServer, type IncomingHttpHeaders, type Server } from 'node:http';
import { mkdtemp, rm } from 'node:fs/promises';
import type { AddressInfo } from 'node:net';
import os from 'node:os';
import path from 'node:path';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { validateCompatibleBaseUrl } from './ai.js';
import { buildApp } from './app.js';
import { loadConfig } from './config.js';

describe('AI proxy', () => {
  let upstream: Server;
  let seen: { url: string; headers: IncomingHttpHeaders; body: string } | null = null;
  let base: string;
  let token: string;
  let tmp: string;
  let close: () => Promise<void>;

  beforeAll(async () => {
    upstream = createServer((req, res) => {
      let body = '';
      req.on('data', (c) => (body += c));
      req.on('end', () => {
        seen = { url: req.url!, headers: req.headers, body };
        if (req.url!.includes('fail')) {
          res.writeHead(401, { 'content-type': 'application/json' });
          return res.end('{"type":"error","error":{"message":"invalid x-api-key"}}');
        }
        res.writeHead(200, { 'content-type': 'text/event-stream', 'request-id': 'req_123', 'set-cookie': 'x=1' });
        res.write('event: message_start\ndata: {"type":"message_start"}\n\n');
        setTimeout(() => res.end('event: message_stop\ndata: {"type":"message_stop"}\n\n'), 20);
      });
    });
    await new Promise<void>((r) => upstream.listen(0, '127.0.0.1', r));
    const up = `http://127.0.0.1:${(upstream.address() as AddressInfo).port}`;

    tmp = await mkdtemp(path.join(os.tmpdir(), 'fc-ai-'));
    const cfg = loadConfig({ DEV_AUTH: 'true', DATA_DIR: tmp, WORKSPACES_ROOT: path.join(tmp, 'ws'), LOG_LEVEL: 'silent', AI_RATE_LIMIT_PER_MINUTE: '6' });
    const { app } = await buildApp(cfg, { aiUpstreams: { anthropic: up, gemini: up } });
    await app.listen({ port: 0, host: '127.0.0.1' });
    base = `http://127.0.0.1:${(app.server.address() as AddressInfo).port}`;
    close = () => app.close();
    const res = await fetch(`${base}/v1/auth/dev-login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: '{"email":"ai@example.com"}' });
    token = ((await res.json()) as { token: string }).token;
  });

  afterAll(async () => {
    await close();
    upstream.close();
    await rm(tmp, { recursive: true, force: true });
  });

  const post = (p: string, headers: Record<string, string>, body: unknown = { model: 'claude-opus-5' }) =>
    fetch(`${base}${p}`, { method: 'POST', headers: { 'content-type': 'application/json', ...headers }, body: JSON.stringify(body) });

  it('requires runner auth', async () => {
    expect((await post('/v1/ai/proxy/anthropic/v1/messages', { 'x-provider-key': 'k' })).status).toBe(401);
  });

  it('streams upstream SSE, injects provider auth, never forwards runner token or x-provider-key', async () => {
    const res = await post('/v1/ai/proxy/anthropic/v1/messages', {
      authorization: `Bearer ${token}`,
      'x-provider-key': 'sk-ant-secret',
      'anthropic-version': '2023-06-01',
      'anthropic-beta': 'server-side-fallback-2026-07-01',
    });
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toContain('text/event-stream');
    expect(res.headers.get('request-id')).toBe('req_123');
    expect(res.headers.get('set-cookie')).toBeNull();
    const text = await res.text();
    expect(text).toContain('message_start');
    expect(text).toContain('message_stop');
    expect(seen!.url).toBe('/v1/messages');
    expect(seen!.headers['x-api-key']).toBe('sk-ant-secret');
    expect(seen!.headers['anthropic-beta']).toBe('server-side-fallback-2026-07-01');
    expect(seen!.headers['x-provider-key']).toBeUndefined();
    expect(seen!.headers.authorization).toBeUndefined();
    expect(JSON.parse(seen!.body)).toEqual({ model: 'claude-opus-5' });
  });

  it('keeps query string (gemini alt=sse) and uses x-goog-api-key', async () => {
    const res = await post('/v1/ai/proxy/gemini/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse', {
      authorization: `Bearer ${token}`,
      'x-provider-key': 'AIza-secret',
    });
    await res.text();
    expect(seen!.url).toBe('/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse');
    expect(seen!.headers['x-goog-api-key']).toBe('AIza-secret');
  });

  it('rejects disallowed paths, unknown providers, missing keys, private compatible URLs', async () => {
    const auth = { authorization: `Bearer ${token}` };
    expect((await post('/v1/ai/proxy/anthropic/v1/files', { ...auth, 'x-provider-key': 'k' })).status).toBe(403);
    expect((await post('/v1/ai/proxy/mistral/v1/chat/completions', { ...auth, 'x-provider-key': 'k' })).status).toBe(404);
    expect((await post('/v1/ai/proxy/openai/v1/chat/completions', auth)).status).toBe(400);
    const priv = await post('/v1/ai/proxy/openaiCompatible/v1/chat/completions', {
      ...auth,
      'x-provider-key': '',
      'x-provider-base-url': 'https://169.254.169.254/v1',
    });
    expect(priv.status).toBe(403);
  });

  it('rate limits per user', async () => {
    const auth = { authorization: `Bearer ${token}`, 'x-provider-key': 'k' };
    const statuses: number[] = [];
    for (let i = 0; i < 4; i++) {
      const r = await post('/v1/ai/proxy/anthropic/v1/messages', auth);
      await r.text();
      statuses.push(r.status);
    }
    expect(statuses).toContain(429);
  });

  it('serves the model catalog', async () => {
    const res = await fetch(`${base}/v1/ai/models`, { headers: { authorization: `Bearer ${token}` } });
    const body = (await res.json()) as { models: Array<{ id: string }>; defaults: { chat: string } };
    expect(body.defaults.chat).toBe('anthropic:claude-opus-5');
    expect(body.models.map((m) => m.id)).toContain('gemini-2.5-flash');
  });
});

describe('validateCompatibleBaseUrl', () => {
  const prod = loadConfig({ DEV_AUTH: 'true' });
  const dev = loadConfig({ DEV_AUTH: 'true', AI_ALLOW_PRIVATE_BASE_URLS: 'true' });
  it('accepts public https and strips /v1', () => {
    expect(validateCompatibleBaseUrl('https://openrouter.ai/api/v1/', prod)).toBe('https://openrouter.ai/api');
  });
  it('blocks http, loopback, private ranges and embedded credentials', () => {
    for (const bad of ['http://api.groq.com', 'https://127.0.0.1', 'https://10.1.2.3', 'https://[::1]', 'https://localhost:11434', 'https://u:p@example.com', 'nope']) {
      expect(() => validateCompatibleBaseUrl(bad, prod)).toThrow();
    }
  });
  it('allows local Ollama when explicitly enabled', () => {
    expect(validateCompatibleBaseUrl('http://localhost:11434/v1', dev)).toBe('http://localhost:11434');
  });
});

describe('free assistant', () => {
  it('uses the server Gemini key, restricts the model and enforces a daily limit', async () => {
    const seen: Array<{ url: string; key: string | null; body: string }> = [];
    const fakeFetch = (async (url: string | URL | Request, init?: RequestInit) => {
      seen.push({ url: String(url), key: new Headers(init?.headers).get('x-goog-api-key'), body: String(init?.body) });
      return new Response('data: {"candidates":[{"content":{"parts":[{"text":"Ciao"}]}}]}\n\n', { status: 200, headers: { 'content-type': 'text/event-stream' } });
    }) as typeof fetch;
    const tmp = await mkdtemp(path.join(os.tmpdir(), 'fc-asst-'));
    const cfg = loadConfig({ DEV_AUTH: 'true', DATA_DIR: tmp, WORKSPACES_ROOT: path.join(tmp, 'ws'), LOG_LEVEL: 'silent', GEMINI_API_KEY: 'server-key', ASSISTANT_DAILY_LIMIT: '2' });
    const { buildApp } = await import('./app.js');
    const { app } = await buildApp(cfg);
    const { registerAiRoutes } = await import('./ai.js');
    void registerAiRoutes;
    await app.close();
    // Build a minimal app with injected fetch for the assistant route.
    const Fastify = (await import('fastify')).default;
    const small = Fastify();
    small.decorateRequest('user', null as never);
    await (await import('./ai.js')).registerAiRoutes(small, {
      cfg,
      authenticate: async (req) => void ((req as { user: unknown }).user = { id: 'u1' }),
      fetchImpl: fakeFetch,
    });
    const call = () => small.inject({ method: 'POST', url: '/v1/ai/assistant/v1beta/models/gemini-2.5-flash:streamGenerateContent', payload: { contents: [], generationConfig: { maxOutputTokens: 99999 } } });
    const r1 = await call();
    expect(r1.statusCode).toBe(200);
    expect(r1.body).toContain('Ciao');
    expect(seen[0]!.key).toBe('server-key');
    expect(seen[0]!.url).toContain('gemini-2.5-flash:streamGenerateContent?alt=sse');
    expect(JSON.parse(seen[0]!.body).generationConfig.maxOutputTokens).toBe(4096);
    expect((await call()).statusCode).toBe(200);
    expect((await call()).statusCode).toBe(429);
    const wrongModel = await small.inject({ method: 'POST', url: '/v1/ai/assistant/v1beta/models/gemini-2.5-pro:streamGenerateContent', payload: {} });
    expect(wrongModel.statusCode).toBe(403);
    const status = await small.inject({ method: 'GET', url: '/v1/ai/assistant/status' });
    expect(status.json()).toMatchObject({ enabled: true, dailyLimit: 2, used: 2 });
    await small.close();
    await rm(tmp, { recursive: true, force: true });
  });
});
