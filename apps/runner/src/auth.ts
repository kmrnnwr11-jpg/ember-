import { createRemoteJWKSet, jwtVerify, SignJWT, type JWTPayload } from 'jose';
import type { Config } from './config.js';

export interface AuthUser {
  id: string;
  email?: string;
}

export class AuthError extends Error {}

/**
 * Verifies bearer tokens. Accepts, in order:
 *  - Supabase access tokens signed with the project's asymmetric keys (JWKS)
 *  - Supabase legacy HS256 tokens (SUPABASE_JWT_SECRET)
 *  - dev tokens issued by /v1/auth/dev-login when DEV_AUTH=true
 */
export class Authenticator {
  private readonly jwks;
  private readonly legacySecret;
  private readonly devSecret;

  constructor(private readonly cfg: Config) {
    this.jwks = cfg.SUPABASE_URL
      ? createRemoteJWKSet(new URL(`${cfg.SUPABASE_URL.replace(/\/$/, '')}/auth/v1/.well-known/jwks.json`))
      : null;
    this.legacySecret = cfg.SUPABASE_JWT_SECRET ? new TextEncoder().encode(cfg.SUPABASE_JWT_SECRET) : null;
    this.devSecret = new TextEncoder().encode(cfg.DEV_JWT_SECRET);
  }

  async verify(token: string | undefined): Promise<AuthUser> {
    if (!token) throw new AuthError('missing token');
    const attempts: Array<() => Promise<JWTPayload>> = [];
    if (this.cfg.DEV_AUTH) {
      attempts.push(async () => (await jwtVerify(token, this.devSecret, { issuer: 'fluttercursor-dev' })).payload);
    }
    if (this.legacySecret) {
      const s = this.legacySecret;
      attempts.push(async () => (await jwtVerify(token, s, { algorithms: ['HS256'] })).payload);
    }
    if (this.jwks) {
      const k = this.jwks;
      attempts.push(async () => (await jwtVerify(token, k)).payload);
    }
    for (const attempt of attempts) {
      try {
        const payload = await attempt();
        if (!payload.sub) continue;
        return { id: payload.sub, email: typeof payload.email === 'string' ? payload.email : undefined };
      } catch {
        // try next verifier
      }
    }
    throw new AuthError('invalid token');
  }

  async issueDevToken(email: string): Promise<{ token: string; user: AuthUser }> {
    if (!this.cfg.DEV_AUTH) throw new AuthError('dev auth disabled');
    const id = `dev_${Buffer.from(email.toLowerCase()).toString('hex').slice(0, 24)}`;
    const token = await new SignJWT({ email })
      .setProtectedHeader({ alg: 'HS256' })
      .setSubject(id)
      .setIssuer('fluttercursor-dev')
      .setIssuedAt()
      .setExpirationTime('7d')
      .sign(this.devSecret);
    return { token, user: { id, email } };
  }
}

export function bearer(header: string | undefined): string | undefined {
  if (!header) return undefined;
  const m = /^Bearer\s+(.+)$/i.exec(header);
  return m?.[1];
}
