import { readFile } from 'node:fs/promises';
import { isIP } from 'node:net';
import path from 'node:path';
import { Readable } from 'node:stream';
import { fileURLToPath } from 'node:url';
import type { FastifyInstance, FastifyRequest } from 'fastify';
import type { Config } from './config.js';

export type ProviderId = 'anthropic' | 'openai' | 'gemini' | 'xai' | 'openaiCompatible';

export const DEFAULT_UPSTREAMS: Record<Exclude<ProviderId, 'openaiCompatible'>, string> = {
  anthropic: 'https://api.anthropic.com',
  openai: 'https://api.openai.com',
  gemini: 'https://generativelanguage.googleapis.com',
  xai: 'https://api.x.ai',
};

/** Only these upstream paths may be proxied (no arbitrary provider API access). */
const ALLOWED_PATHS: Record<ProviderId, RegExp> = {
  anthropic: /^v1\/messages(\/count_tokens)?$/,
  openai: /^v1\/(chat\/completions|embeddings)$/,
  xai: /^v1\/chat\/completions$/,
  openaiCompatible: /^v1\/(chat\/completions|embeddings)$/,
  gemini: /^v1beta\/models\/[\w.-]+:(streamGenerateContent|generateContent|batchEmbedContents|countTokens)$/,
};

const PASS_REQUEST_HEADERS = ['anthropic-version', 'anthropic-beta', 'content-type', 'accept'];
const PASS_RESPONSE_HEADERS = ['content-type', 'request-id', 'x-request-id', 'retry-after', 'anthropic-ratelimit-requests-remaining'];

class ProxyError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

function isPrivateHost(host: string): boolean {
  const h = host.replace(/^\[|\]$/g, '').toLowerCase();
  if (h === 'localhost' || h.endsWith('.localhost') || h.endsWith('.internal') || h.endsWith('.local')) return true;
  const kind = isIP(h);
  if (kind === 4) {
    const [a, b] = h.split('.').map(Number) as [number, number];
    return a === 10 || a === 127 || a === 0 || (a === 169 && b === 254) || (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168) || (a === 100 && b >= 64 && b <= 127);
  }
  if (kind === 6) return h === '::1' || h.startsWith('fc') || h.startsWith('fd') || h.startsWith('fe80') || h.startsWith('::ffff:');
  return false;
}

/**
 * Validates a user-supplied OpenAI-compatible base URL. Blocks private and
 * loopback targets (SSRF) unless AI_ALLOW_PRIVATE_BASE_URLS is enabled.
 * DNS names resolving to private IPs are not detected; run the Runner with
 * egress filtering in production (§4).
 */
export function validateCompatibleBaseUrl(raw: string | undefined, cfg: Config): string {
  if (!raw) throw new ProxyError(400, 'bad_request', 'x-provider-base-url header is required for openaiCompatible');
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new ProxyError(400, 'bad_request', 'invalid x-provider-base-url');
  }
  if (url.protocol !== 'https:' && !(url.protocol === 'http:' && cfg.AI_ALLOW_PRIVATE_BASE_URLS)) {
    throw new ProxyError(400, 'bad_request', 'x-provider-base-url must use https');
  }
  if (url.username || url.password) throw new ProxyError(400, 'bad_request', 'credentials in base URL are not allowed');
  if (!cfg.AI_ALLOW_PRIVATE_BASE_URLS && isPrivateHost(url.hostname)) {
    throw new ProxyError(403, 'forbidden', 'private or loopback base URLs are not allowed');
  }
  // Accept both ".../v1" and bare hosts; the proxied path always starts with v1/.
  return url.toString().replace(/\/+$/, '').replace(/\/v1$/, '');
}

/** Fixed-window per-user limiter. */
export class RateLimiter {
  private readonly hits = new Map<string, { start: number; count: number }>();
  constructor(
    private readonly max: number,
    private readonly windowMs = 60_000,
  ) {}
  allow(key: string): boolean {
    const now = Date.now();
    const e = this.hits.get(key);
    if (!e || now - e.start >= this.windowMs) {
      this.hits.set(key, { start: now, count: 1 });
      return true;
    }
    return ++e.count <= this.max;
  }
}

export interface AiRouteOptions {
  cfg: Config;
  authenticate: (req: FastifyRequest) => Promise<void>;
  upstreams?: Partial<typeof DEFAULT_UPSTREAMS>;
  fetchImpl?: typeof fetch;
}

let cachedCatalog: { at: number; body: unknown } | null = null;

async function loadCatalog(cfg: Config, fetchImpl: typeof fetch): Promise<unknown> {
  if (cachedCatalog && Date.now() - cachedCatalog.at < 3600_000) return cachedCatalog.body;
  let body: unknown;
  if (cfg.AI_CATALOG_URL) {
    try {
      const res = await fetchImpl(cfg.AI_CATALOG_URL, { signal: AbortSignal.timeout(5000) });
      if (res.ok) body = await res.json();
    } catch {
      // fall back to bundled catalog
    }
  }
  if (!body) {
    const here = path.dirname(fileURLToPath(import.meta.url));
    body = JSON.parse(await readFile(path.resolve(here, '..', 'ai-catalog.json'), 'utf8'));
  }
  cachedCatalog = { at: Date.now(), body };
  return body;
}

/** AI routes (§5B): model catalog + transparent per-request BYOK proxy. */
export async function registerAiRoutes(app: FastifyInstance, opts: AiRouteOptions) {
  const { cfg, authenticate } = opts;
  const fetchImpl = opts.fetchImpl ?? fetch;
  const upstreams = { ...DEFAULT_UPSTREAMS, ...opts.upstreams };
  const limiter = new RateLimiter(cfg.AI_RATE_LIMIT_PER_MINUTE);

  // Free assistant: daily message counter per user (resets at UTC midnight).
  const assistantUsage = new Map<string, number>();
  const assistantKey = (userId: string) => `${userId}|${new Date().toISOString().slice(0, 10)}`;

  await app.register(async (r) => {
    r.addHook('preHandler', authenticate);

    r.get('/v1/ai/models', async () => loadCatalog(cfg, fetchImpl));

    r.get('/v1/ai/assistant/status', async (req) => ({
      enabled: cfg.GEMINI_API_KEY !== '',
      model: cfg.ASSISTANT_MODEL,
      dailyLimit: cfg.ASSISTANT_DAILY_LIMIT,
      used: assistantUsage.get(assistantKey(req.user.id)) ?? 0,
    }));

    // Gemini streaming with the server's key, for the free in-app assistant only.
    r.post('/v1/ai/assistant/*', async (req, reply) => {
      const { '*': rest } = req.params as { '*': string };
      if (!cfg.GEMINI_API_KEY) {
        return reply.status(503).send({ code: 'assistant_unconfigured', message: 'The free assistant is not configured on this Runner (GEMINI_API_KEY missing)' });
      }
      const allowed = `v1beta/models/${cfg.ASSISTANT_MODEL}:streamGenerateContent`;
      if (rest !== allowed) return reply.status(403).send({ code: 'forbidden', message: `assistant only allows ${allowed}` });
      const k = assistantKey(req.user.id);
      const used = assistantUsage.get(k) ?? 0;
      if (used >= cfg.ASSISTANT_DAILY_LIMIT) {
        return reply.status(429).send({ code: 'rate_limited', message: `Limite giornaliero dell'assistente gratuito raggiunto (${cfg.ASSISTANT_DAILY_LIMIT} messaggi). Riprova domani.` });
      }
      assistantUsage.set(k, used + 1);
      const body = (req.body ?? {}) as { generationConfig?: Record<string, unknown> };
      // Cap output to keep the free tier sustainable.
      body.generationConfig = { ...(body.generationConfig ?? {}), maxOutputTokens: Math.min(Number(body.generationConfig?.maxOutputTokens ?? 4096), 4096) };
      const abort = new AbortController();
      req.raw.on('close', () => {
        if (!reply.raw.writableEnded) abort.abort();
      });
      try {
        const upstream = await fetchImpl(`${upstreams.gemini}/${allowed}?alt=sse`, {
          method: 'POST',
          headers: { 'content-type': 'application/json', 'x-goog-api-key': cfg.GEMINI_API_KEY },
          body: JSON.stringify(body),
          signal: abort.signal,
        });
        reply.status(upstream.status);
        const ct = upstream.headers.get('content-type');
        if (ct) reply.header('content-type', ct);
        reply.header('cache-control', 'no-cache');
        if (!upstream.body) return reply.send();
        return reply.send(Readable.fromWeb(upstream.body as import('node:stream/web').ReadableStream));
      } catch (e) {
        if ((e as Error).name === 'AbortError') return reply;
        return reply.status(502).send({ code: 'upstream_unreachable', message: 'Gemini unreachable' });
      }
    });

    r.post('/v1/ai/proxy/:provider/*', async (req, reply) => {
      const { provider, '*': rest } = req.params as { provider: string; '*': string };
      try {
        if (!(provider in ALLOWED_PATHS)) throw new ProxyError(404, 'not_found', `unknown provider ${provider}`);
        const pid = provider as ProviderId;
        if (!ALLOWED_PATHS[pid].test(rest)) throw new ProxyError(403, 'forbidden', `path not allowed: ${rest}`);
        if (!limiter.allow(req.user.id)) throw new ProxyError(429, 'rate_limited', 'too many AI requests, slow down');
        const key = req.headers['x-provider-key'];
        if (typeof key !== 'string' || (key === '' && pid !== 'openaiCompatible')) {
          throw new ProxyError(400, 'bad_request', 'x-provider-key header is required');
        }

        const base =
          pid === 'openaiCompatible'
            ? validateCompatibleBaseUrl(req.headers['x-provider-base-url'] as string | undefined, cfg)
            : upstreams[pid];
        const query = req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : '';
        const target = `${base}/${rest}${query}`;

        const headers: Record<string, string> = {};
        for (const h of PASS_REQUEST_HEADERS) {
          const v = req.headers[h];
          if (typeof v === 'string') headers[h] = v;
        }
        headers['content-type'] ??= 'application/json';
        if (pid === 'anthropic') headers['x-api-key'] = key;
        else if (pid === 'gemini') headers['x-goog-api-key'] = key;
        else if (key) headers['authorization'] = `Bearer ${key}`;

        const abort = new AbortController();
        req.raw.on('close', () => {
          if (!reply.raw.writableEnded) abort.abort();
        });
        const upstream = await fetchImpl(target, {
          method: 'POST',
          headers,
          body: JSON.stringify(req.body ?? {}),
          signal: abort.signal,
        });

        reply.status(upstream.status);
        for (const h of PASS_RESPONSE_HEADERS) {
          const v = upstream.headers.get(h);
          if (v) reply.header(h, v);
        }
        reply.header('cache-control', 'no-cache');
        reply.header('x-accel-buffering', 'no');
        if (!upstream.body) return reply.send();
        return reply.send(Readable.fromWeb(upstream.body as import('node:stream/web').ReadableStream));
      } catch (e) {
        if (e instanceof ProxyError) return reply.status(e.status).send({ code: e.code, message: e.message });
        if ((e as Error).name === 'AbortError') return reply;
        req.log.warn({ err: (e as Error).message, provider }, 'ai proxy upstream failure');
        return reply.status(502).send({ code: 'upstream_unreachable', message: 'AI provider unreachable' });
      }
    });
  });
}
