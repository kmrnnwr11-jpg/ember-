import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';

/** Public Play Store data about an app the user wants to take as a model. */
export interface PlayApp {
  id: string;
  title: string;
  developer: string;
  icon: string;
  url: string;
  description: string;
}

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130 Safari/537.36';
const ID_RE = /^[A-Za-z][\w]*(\.[\w]+)+$/;

const decode = (s: string) =>
  s
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/\n{3,}/g, '\n\n')
    .trim();

const meta = (html: string, prop: string) => new RegExp(`<meta (?:property|name)="${prop}" content="([^"]*)"`).exec(html)?.[1];

/** Extracts the listing from a Play Store details page. */
export function parseDetails(id: string, html: string, lang: string): PlayApp | null {
  const rawTitle = meta(html, 'og:title');
  if (!rawTitle) return null;
  const title = decode(rawTitle).replace(/\s+-\s+(App su Google Play|Apps on Google Play|Aplicaciones en Google Play|Applications sur Google Play)$/i, '');
  const descMatch = /data-g-id="description"[^>]*>([\s\S]*?)<\/div>/.exec(html);
  const description = decode(descMatch?.[1] ?? meta(html, 'description') ?? '').slice(0, 6000);
  const developer = decode(/href="\/store\/apps\/dev(?:eloper)?\?id=[^"]*"[^>]*>(?:<span>)?([^<]{1,80})/.exec(html)?.[1] ?? '');
  return {
    id,
    title,
    developer,
    icon: meta(html, 'og:image') ?? '',
    url: `https://play.google.com/store/apps/details?id=${id}&hl=${lang}`,
    description,
  };
}

/** App ids in the order the Play Store search page lists them. */
export function parseSearchIds(html: string): string[] {
  const ids: string[] = [];
  for (const m of html.matchAll(/\/store\/apps\/details\?id=([A-Za-z][\w.]+)/g)) {
    if (!ids.includes(m[1]!)) ids.push(m[1]!);
  }
  return ids;
}

export async function registerResearchRoutes(
  app: FastifyInstance,
  opts: { authenticate: (req: FastifyRequest, reply: FastifyReply) => Promise<void>; fetchImpl?: typeof fetch },
) {
  const fetchImpl = opts.fetchImpl ?? fetch;
  const get = async (url: string) => {
    const res = await fetchImpl(url, { headers: { 'user-agent': UA, 'accept-language': 'it,en;q=0.8' }, signal: AbortSignal.timeout(15000) });
    if (!res.ok) throw Object.assign(new Error(`Play Store answered ${res.status}`), { status: res.status });
    return res.text();
  };
  const details = async (id: string, lang: string) => parseDetails(id, await get(`https://play.google.com/store/apps/details?id=${encodeURIComponent(id)}&hl=${lang}&gl=IT`), lang);
  const langOf = (q: unknown) => (typeof q === 'string' && /^[a-z]{2}$/.test(q) ? q : 'it');

  await app.register(async (r) => {
    r.addHook('preHandler', opts.authenticate);

    // Top matches for an app name, with title and icon so the user can pick the right one.
    r.get('/v1/research/play/search', async (req, reply) => {
      const { q, lang } = req.query as { q?: string; lang?: string };
      const query = (q ?? '').trim().slice(0, 80);
      if (query.length < 2) return reply.status(400).send({ code: 'bad_request', message: 'q is required' });
      try {
        const l = langOf(lang);
        const ids = parseSearchIds(await get(`https://play.google.com/store/search?q=${encodeURIComponent(query)}&c=apps&hl=${l}&gl=IT`)).slice(0, 5);
        const apps = (await Promise.all(ids.map((id) => details(id, l).catch(() => null)))).filter((a): a is PlayApp => a !== null);
        return { apps: apps.map(({ description, ...a }) => ({ ...a, summary: description.slice(0, 160) })) };
      } catch {
        return reply.status(502).send({ code: 'upstream_unreachable', message: 'Play Store unreachable' });
      }
    });

    // Full listing of one app (description = its feature list).
    r.get('/v1/research/play/app', async (req, reply) => {
      const { id, lang } = req.query as { id?: string; lang?: string };
      if (!id || !ID_RE.test(id)) return reply.status(400).send({ code: 'bad_request', message: 'invalid app id' });
      try {
        const a = await details(id, langOf(lang));
        return a ?? reply.status(404).send({ code: 'not_found', message: 'app not found on Play Store' });
      } catch (e) {
        const status = (e as { status?: number }).status;
        return reply.status(status === 404 ? 404 : 502).send({ code: status === 404 ? 'not_found' : 'upstream_unreachable', message: 'Play Store lookup failed' });
      }
    });
  });
}
