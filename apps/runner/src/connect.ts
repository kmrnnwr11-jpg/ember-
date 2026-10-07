import { readAppleCreds, readAppleCredsPublic, readAppleKey, deleteAppleCreds, rememberTeamId, saveAppleCreds } from './apple_creds.js';
import { AppStore, AppStoreError, parseAppStoreKey, type AppStoreKey } from './appstore.js';
import { teamFromAppStore } from './ios_signing.js';
import { getAccessToken, parseServiceAccount, PlayError } from './play.js';
import { readSettings, writeSettings } from './settings_store.js';

/**
 * The two store accounts, connected once and kept connected.
 *
 * Google Play: a service account key (the JSON file). Apple: an App Store Connect
 * API key (Key ID, Issuer ID and the .p8 file). Both are checked against the
 * store itself before they are saved, saved on this computer only, looked at again
 * now and then, and never shown again: the screens get the account name and a state.
 */

export type Provider = 'google_play' | 'apple';

/** `connected`: the store accepted the key just now. `invalid`: it refused it. `unreachable`: nobody could be asked. */
export type ConnState = 'connected' | 'missing' | 'invalid' | 'unreachable';

export interface ConnStatus {
  provider: Provider;
  state: ConnState;
  /** A code, not a sentence: `ok`, `missing`, `bad_key`, `key_refused`, `no_permission`, `offline`. */
  detail: string;
  /** Who the key belongs to: the service account's email, or the Apple Key ID. */
  account: string;
  /** What the store said, when it refused. Not for the owner's eyes except as a hint. */
  message?: string;
  /** Apple Developer Team ID, when known. */
  teamId?: string;
  connectedAt?: string;
  checkedAt?: string;
}

/** The owner typed something that cannot be a key, or the store refused it. */
export class ConnectError extends Error {
  constructor(
    readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'ConnectError';
  }
}

const KEYS = { key: 'play_service_account', developer: 'play_developer_id', at: 'play_connected_at' } as const;

export interface ConnectOptions {
  fetchImpl?: typeof fetch;
  now?: () => number;
  /** How long a check stays good for the screens (default 10 minutes). */
  ttlMs?: number;
}

const missing = (provider: Provider): ConnStatus => ({ provider, state: 'missing', detail: 'missing', account: '' });

/** A failure of the network itself (as opposed to the store saying no). */
const isNetwork = (e: unknown) => e instanceof TypeError || /fetch failed|ENOTFOUND|ECONNRESET|ETIMEDOUT|EAI_AGAIN|network/i.test((e as Error)?.message ?? '');

export class ConnectionService {
  private readonly cache = new Map<string, { at: number; status: ConnStatus }>();
  private readonly listeners = new Set<(owner: string, status: ConnStatus, before: ConnState | undefined) => void>();
  private readonly timers = new Map<string, NodeJS.Timeout>();
  private readonly fetchImpl: typeof fetch;
  private readonly now: () => number;
  private readonly ttl: number;

  constructor(opts: ConnectOptions = {}) {
    this.fetchImpl = opts.fetchImpl ?? fetch;
    this.now = opts.now ?? Date.now;
    this.ttl = opts.ttlMs ?? 10 * 60_000;
  }

  /** Called whenever a check changes what the state is (connected → invalid, invalid → connected…). */
  onChange(cb: (owner: string, status: ConnStatus, before: ConnState | undefined) => void): () => void {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  /** Both accounts. Checks again when the last check is older than the time to live, or when asked to. */
  async status(owner: string, opts: { fresh?: boolean } = {}): Promise<{ googlePlay: ConnStatus; apple: ConnStatus }> {
    const [googlePlay, apple] = await Promise.all([this.get(owner, 'google_play', opts.fresh), this.get(owner, 'apple', opts.fresh)]);
    return { googlePlay, apple };
  }

  /** Looks at the account now. */
  verify(owner: string, provider: Provider): Promise<ConnStatus> {
    return this.get(owner, provider, true);
  }

  /** The cached status, if there is one: no network. */
  cached(owner: string, provider: Provider): ConnStatus | undefined {
    return this.cache.get(`${owner}:${provider}`)?.status;
  }

  // ------------------------------------------------------------------ Google Play

  /** Checks a service account key against Google and, only if Google accepts it, keeps it. */
  async connectGooglePlay(owner: string, input: { serviceAccount: string; developerId?: string }): Promise<ConnStatus> {
    let email: string;
    try {
      const sa = parseServiceAccount(input.serviceAccount);
      await getAccessToken(sa, this.fetchImpl);
      email = sa.client_email;
    } catch (e) {
      if (e instanceof PlayError) throw new ConnectError(e.code === 'bad_request' ? 'bad_key' : 'key_refused', e.message);
      if (isNetwork(e)) throw new ConnectError('offline', 'Google could not be reached: check the internet connection and try again.');
      throw e;
    }
    const developerId = (input.developerId ?? '').trim();
    if (developerId && !/^\d{5,25}$/.test(developerId)) {
      throw new ConnectError('bad_developer_id', 'The developer account id is the long number in the Play Console address (…/developers/1234567890123456789/…).');
    }
    await writeSettings(owner, {
      [KEYS.key]: input.serviceAccount.trim(),
      [KEYS.developer]: developerId || null,
      [KEYS.at]: new Date(this.now()).toISOString(),
    });
    return this.record(owner, { provider: 'google_play', state: 'connected', detail: 'ok', account: email, connectedAt: new Date(this.now()).toISOString(), checkedAt: new Date(this.now()).toISOString() });
  }

  private async checkGoogle(owner: string): Promise<ConnStatus> {
    const settings = await readSettings(owner).catch(() => ({}) as Record<string, string>);
    const raw = settings[KEYS.key];
    if (!raw) return missing('google_play');
    const connectedAt = settings[KEYS.at];
    const checkedAt = new Date(this.now()).toISOString();
    let email = '';
    try {
      const sa = parseServiceAccount(raw);
      email = sa.client_email;
      await getAccessToken(sa, this.fetchImpl);
      return { provider: 'google_play', state: 'connected', detail: 'ok', account: email, connectedAt, checkedAt };
    } catch (e) {
      if (e instanceof PlayError) return { provider: 'google_play', state: 'invalid', detail: e.code === 'bad_request' ? 'bad_key' : 'key_refused', account: email, message: e.message.slice(0, 300), connectedAt, checkedAt };
      return { provider: 'google_play', state: 'unreachable', detail: 'offline', account: email, message: (e as Error).message.slice(0, 200), connectedAt, checkedAt };
    }
  }

  // ------------------------------------------------------------------ Apple

  /**
   * Checks an App Store Connect key against Apple and, only if Apple accepts it, keeps it.
   * Without a new .p8 the saved one is used (to change only the IDs of the same key).
   */
  async connectApple(owner: string, input: { keyId: string; issuerId: string; privateKey?: string; teamId?: string }): Promise<ConnStatus> {
    let key: AppStoreKey;
    try {
      const saved = input.privateKey?.trim() ? null : await readAppleKey();
      key = parseAppStoreKey({ keyId: input.keyId, issuerId: input.issuerId, privateKey: input.privateKey?.trim() || saved?.privateKey });
    } catch (e) {
      if (e instanceof AppStoreError) throw new ConnectError('bad_key', e.message);
      throw e;
    }
    await this.askApple(key);
    await saveAppleCreds({ keyId: input.keyId, issuerId: input.issuerId, privateKey: input.privateKey?.trim() || undefined, teamId: input.teamId });
    const teamId = (await this.findTeam(key)) ?? '';
    const at = new Date(this.now()).toISOString();
    return this.record(owner, { provider: 'apple', state: 'connected', detail: 'ok', account: key.keyId, ...(teamId ? { teamId } : {}), connectedAt: at, checkedAt: at });
  }

  /** One cheap question to Apple that proves the key works and has a role. Throws [ConnectError]. */
  private async askApple(key: AppStoreKey): Promise<void> {
    try {
      const store = await AppStore.open(key, this.fetchImpl);
      await store.call('GET', '/apps?limit=1', undefined, 'Checking the connection');
    } catch (e) {
      if (e instanceof AppStoreError) {
        if (e.code === 'bad_key' || e.code === 'bad_request') throw new ConnectError('key_refused', e.message);
        if (e.code === 'no_permission') throw new ConnectError('no_permission', e.message);
        throw new ConnectError('offline', e.message);
      }
      if (isNetwork(e)) throw new ConnectError('offline', 'Apple could not be reached: check the internet connection and try again.');
      throw e;
    }
  }

  private async findTeam(key: AppStoreKey): Promise<string | null> {
    const saved = (await readAppleCreds())?.teamId;
    if (saved) return saved;
    const found = await teamFromAppStore(key, '', this.fetchImpl).catch(() => null);
    if (found) await rememberTeamId(found).catch(() => {});
    return found;
  }

  private async checkApple(): Promise<ConnStatus> {
    const key = await readAppleKey().catch(() => null);
    if (!key) return missing('apple');
    const pub = await readAppleCredsPublic().catch(() => null);
    const base = { provider: 'apple' as const, account: key.keyId, ...(pub?.teamId ? { teamId: pub.teamId } : {}), connectedAt: pub?.updatedAt, checkedAt: new Date(this.now()).toISOString() };
    try {
      await this.askApple(key);
      return { ...base, state: 'connected', detail: 'ok' };
    } catch (e) {
      const c = e as ConnectError;
      return { ...base, state: c.code === 'offline' ? 'unreachable' : 'invalid', detail: c.code, message: c.message.slice(0, 300) };
    }
  }

  // ------------------------------------------------------------------ both

  /** Forgets the account on this computer. The key stays valid at the store: it is revoked there. */
  async disconnect(owner: string, provider: Provider): Promise<ConnStatus> {
    if (provider === 'google_play') await writeSettings(owner, { [KEYS.key]: null, [KEYS.developer]: null, [KEYS.at]: null });
    else await deleteAppleCreds();
    return this.record(owner, missing(provider));
  }

  /** The developer account id saved with the Google key, for links into Play Console. */
  async developerId(owner: string): Promise<string> {
    return (await readSettings(owner).catch(() => ({}) as Record<string, string>))[KEYS.developer] ?? '';
  }

  private async get(owner: string, provider: Provider, fresh = false): Promise<ConnStatus> {
    const hit = this.cache.get(`${owner}:${provider}`);
    if (!fresh && hit && this.now() - hit.at < this.ttl) return hit.status;
    const status = provider === 'google_play' ? await this.checkGoogle(owner) : await this.checkApple();
    return this.record(owner, status);
  }

  private record(owner: string, status: ConnStatus): ConnStatus {
    const slot = `${owner}:${status.provider}`;
    const before = this.cache.get(slot)?.status.state;
    this.cache.set(slot, { at: this.now(), status });
    if (before !== status.state) for (const cb of this.listeners) cb(owner, status, before);
    return status;
  }

  /**
   * Keeps looking at both accounts while the Runner runs, so a key that was
   * revoked, or an Apple role that was taken away, shows up before an upload fails.
   */
  monitor(owner: string, everyMs = 30 * 60_000): void {
    if (this.timers.has(owner)) return;
    const timer = setInterval(() => void this.status(owner, { fresh: true }).catch(() => {}), everyMs);
    timer.unref?.();
    this.timers.set(owner, timer);
    void this.status(owner).catch(() => {});
  }

  stop(): void {
    for (const t of this.timers.values()) clearInterval(t);
    this.timers.clear();
  }
}
