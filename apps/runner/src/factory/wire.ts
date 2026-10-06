import type { FastifyInstance } from 'fastify';
import type { ClaudeCodeEngine } from '../agent_cli.js';
import { resolveClaudeBin } from '../agent_cli.js';
import { readAppleKey } from '../apple_creds.js';
import type { Config } from '../config.js';
import type { PreviewService } from '../preview.js';
import { findBrowser, hasScreenshotMode } from '../screenshots.js';
import type { Services } from '../services.js';
import { readSettings, writeSettings } from '../settings_store.js';
import { cliLogins } from '../subscription_clis.js';
import { freeDiskGb } from './capacity.js';
import { androidLink, readLinks } from './links.js';
import { realOps, type OpsHost } from './ops.js';
import { FactoryService, NoAi } from './service.js';
import { simulatedComplete, simulatedOps } from './simulate.js';

/** The header that lets the Runner call its own routes as a user, with a secret only this process knows. */
export const INTERNAL_HEADERS = { secret: 'x-ember-internal', user: 'x-ember-user' } as const;

export interface FactoryHost {
  cfg: Config;
  app: FastifyInstance;
  services: Services;
  claudeCode: ClaudeCodeEngine;
  preview: PreviewService;
  /** Secret for [INTERNAL_HEADERS]. */
  internalSecret: string;
  /** One answer from Gemini on the Runner's own key, when there is one. */
  geminiComplete: (system: string, prompt: string) => Promise<string>;
  local: boolean;
}

/** Calls this Runner's own routes in-process, as [ownerId], with the secret only this process knows. */
export function internalCall(app: FastifyInstance, secret: string): OpsHost['call'] {
  return async (ownerId, method, url, body) => {
    const res = await app.inject({
      method,
      url,
      // A content type without a body is refused: send one only with a body.
      headers: { [INTERNAL_HEADERS.secret]: secret, [INTERNAL_HEADERS.user]: ownerId, ...(body === undefined ? {} : { 'content-type': 'application/json' }) },
      ...(body === undefined ? {} : { payload: JSON.stringify(body) }),
    });
    let json: Record<string, unknown> = {};
    try {
      json = JSON.parse(res.body || '{}') as Record<string, unknown>;
    } catch {
      json = { message: res.body.slice(0, 300) };
    }
    return { status: res.statusCode, json };
  };
}

/** Builds the Factory service for this Runner: real operations, or pretend ones with EMBER_FACTORY_SIMULATE=1. */
export function createFactoryService(host: FactoryHost): FactoryService {
  const { cfg, claudeCode } = host;
  const simulated = cfg.EMBER_FACTORY_SIMULATE;
  const fake = simulatedComplete();

  /** The best engine that is connected answers: Claude, then ChatGPT, then Gemini on the Runner's key. */
  const complete = async (_ownerId: string, system: string, prompt: string): Promise<string> => {
    if (simulated) return fake(system, prompt);
    if (host.local && (await claudeCode.isAvailable())) return (await claudeCode.complete({ system, prompt, quality: 'fast', timeoutMs: 600_000 })).text;
    if (host.local && (await cliLogins().catch(() => ({ codex: false }))).codex) return (await claudeCode.completeCodex({ system, prompt, timeoutMs: 600_000 })).text;
    if (cfg.GEMINI_API_KEY) return host.geminiComplete(system, prompt);
    throw new NoAi();
  };

  const call = internalCall(host.app, host.internalSecret);

  const opsHost: OpsHost = {
    cfg,
    services: host.services,
    claudeCode,
    preview: host.preview,
    call,
    complete,
    readSettings,
    writeSettings,
    hasAppleKey: async () => !!(await readAppleKey().catch(() => null)),
    findBrowser: () => findBrowser(),
    androidReady: () => androidLink().ready,
    hasScreenshotMode,
    freeDiskGb: () => freeDiskGb(cfg.WORKSPACES_ROOT),
    platform: process.platform,
  };

  return new FactoryService({
    cfg,
    simulated,
    opsFor: (ownerId, email) => (simulated ? simulatedOps({ mac: process.platform === 'darwin', speed: cfg.EMBER_FACTORY_SIM_SPEED }) : realOps(opsHost, ownerId, email)),
    complete,
    links: (ownerId) => readLinks({ cfg, claudeCode, ownerId, local: host.local }),
  });
}

export { resolveClaudeBin };
