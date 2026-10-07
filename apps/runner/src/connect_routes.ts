import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { ConnectError, type ConnectionService, type Provider } from './connect.js';

/** Where the owner goes in each store to make the key (the screens turn these into buttons). */
export const STORE_LINKS = {
  playConsole: 'https://play.google.com/console/developers',
  playApiAccess: 'https://play.google.com/console/developers/api-access',
  googleCloudKeys: 'https://console.cloud.google.com/iam-admin/serviceaccounts',
  appStoreKeys: 'https://appstoreconnect.apple.com/access/integrations/api',
} as const;

const PROVIDERS: Record<string, Provider> = { 'google-play': 'google_play', apple: 'apple' };

export interface ConnectRouteDeps {
  connect: ConnectionService;
  /** Whether the Google Cloud CLI is here (it makes the Google Play connection hands-free). */
  gcloud: () => Promise<{ installed: boolean; account: string | null }>;
}

/** The `/v1/connect` routes. Call inside the authenticated scope. */
export function registerConnectRoutes(r: FastifyInstance, deps: ConnectRouteDeps): void {
  const { connect } = deps;
  let gcloudSeen: { at: number; value: { installed: boolean; account: string | null } } | null = null;
  const gcloud = async () => {
    if (!gcloudSeen || Date.now() - gcloudSeen.at > 5 * 60_000) gcloudSeen = { at: Date.now(), value: await deps.gcloud().catch(() => ({ installed: false, account: null })) };
    return gcloudSeen.value;
  };

  const provider = (params: unknown): Provider => {
    const p = PROVIDERS[(params as { provider?: string }).provider ?? ''];
    if (!p) throw new ConnectError('bad_request', 'unknown account: use google-play or apple');
    return p;
  };

  /** A refusal of the key is the owner's to fix: 422 with a code the screen can word. */
  const failing = async <T>(reply: { status(code: number): { send(body: unknown): unknown } }, run: () => Promise<T>) => {
    try {
      return await run();
    } catch (e) {
      if (e instanceof ConnectError) return reply.status(e.code === 'bad_request' ? 400 : 422).send({ code: e.code, message: e.message });
      throw e;
    }
  };

  r.get('/v1/connect', async (req) => {
    const fresh = (req.query as { fresh?: string }).fresh === '1';
    const { googlePlay, apple } = await connect.status(req.user.id, { fresh });
    return { googlePlay, apple, gcloud: await gcloud(), developerId: await connect.developerId(req.user.id), links: STORE_LINKS };
  });

  r.put('/v1/connect/google-play', async (req, reply) => {
    const body = z.object({ serviceAccount: z.string().min(50).max(20000), developerId: z.string().max(30).optional() }).parse(req.body);
    return failing(reply, () => connect.connectGooglePlay(req.user.id, body));
  });

  r.put('/v1/connect/apple', async (req, reply) => {
    const body = z
      .object({ keyId: z.string().max(40), issuerId: z.string().max(60), privateKey: z.string().max(8000).optional(), teamId: z.string().max(20).optional() })
      .parse(req.body);
    return failing(reply, () => connect.connectApple(req.user.id, body));
  });

  r.post('/v1/connect/:provider/verify', async (req) => connect.verify(req.user.id, provider(req.params)));

  r.delete('/v1/connect/:provider', async (req) => connect.disconnect(req.user.id, provider(req.params)));
}
