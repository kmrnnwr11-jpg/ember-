import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { ClaudeCodeEngine } from '../agent_cli.js';
import { resolveClaudeBin } from '../agent_cli.js';
import { readAppleKey } from '../apple_creds.js';
import type { Config } from '../config.js';
import { findBrowser } from '../screenshots.js';
import { readSettings } from '../settings_store.js';
import { claudeLoggedIn, cliCommand, cliLogins } from '../subscription_clis.js';
import type { ConnectionService, ConnStatus } from '../connect.js';
import type { Link, Links } from './service.js';

const ok: Link = { ready: true, detail: '' };
const no = (detail: string): Link => ({ ready: false, detail });

/** Result of `flutter --version`, remembered for five minutes: it takes a second or two. */
let flutterCache: { at: number; link: Link } | null = null;

export function flutterLink(cfg: Config, run: typeof spawn = spawn): Promise<Link> {
  if (flutterCache && Date.now() - flutterCache.at < 300_000) return Promise.resolve(flutterCache.link);
  return new Promise<Link>((resolve) => {
    const done = (link: Link) => {
      flutterCache = { at: Date.now(), link };
      resolve(link);
    };
    try {
      const child = run(cfg.FLUTTER_BIN, ['--version'], { windowsHide: true, shell: process.platform === 'win32' && /\.(bat|cmd)$/i.test(cfg.FLUTTER_BIN) });
      const timer = setTimeout(() => (child.kill(), done(no('timeout'))), 30_000);
      child.on('error', () => (clearTimeout(timer), done(no('not_installed'))));
      child.on('close', (code) => (clearTimeout(timer), done(code === 0 ? ok : no('not_installed'))));
    } catch {
      done(no('not_installed'));
    }
  });
}

/** Where the Android SDK is, if it is anywhere. */
export function androidLink(env: NodeJS.ProcessEnv = process.env, platform = process.platform): Link {
  const candidates = [
    env.ANDROID_HOME,
    env.ANDROID_SDK_ROOT,
    platform === 'win32' && env.LOCALAPPDATA ? path.join(env.LOCALAPPDATA, 'Android', 'Sdk') : undefined,
    platform === 'darwin' ? path.join(os.homedir(), 'Library', 'Android', 'sdk') : undefined,
    path.join(os.homedir(), 'Android', 'Sdk'),
  ];
  return candidates.some((c) => c && existsSync(c)) ? ok : no('not_installed');
}

/** The Google Play key saved once in the owner's settings, when it is a usable service account. */
export function playKeyLink(saved: string | undefined): Link {
  if (!saved) return no('missing');
  try {
    const j = JSON.parse(saved) as { client_email?: string; private_key?: string };
    return j.client_email && j.private_key ? { ready: true, detail: j.client_email } : no('invalid');
  } catch {
    return no('invalid');
  }
}

/** A store account as the connection service sees it, as a readiness line. */
export function storeLink(status: ConnStatus | undefined): Link {
  if (!status || status.state === 'missing') return no('missing');
  if (status.state === 'connected') return { ready: true, detail: status.account };
  return no(status.state === 'unreachable' ? 'offline' : 'invalid');
}

export async function readLinks(opts: { cfg: Config; claudeCode: ClaudeCodeEngine; ownerId: string; local: boolean; connect?: ConnectionService }): Promise<Links> {
  const { cfg, claudeCode, ownerId, local } = opts;
  // The store accounts are asked about, not just looked for: a key that was revoked is not ready.
  const stores = opts.connect ? await opts.connect.status(ownerId).catch(() => null) : null;
  const logins = local ? await cliLogins().catch(() => ({ codex: false, 'gemini-cli': false, 'qwen-code': false })) : { codex: false, 'gemini-cli': false, 'qwen-code': false };
  const engine = (name: 'codex' | 'gemini-cli' | 'qwen-code'): Link => (!local || !cliCommand(name) ? no('not_installed') : logins[name] ? ok : no('not_signed_in'));
  const claude: Link = !local ? no('not_local') : !(await claudeCode.isAvailable()) ? no('not_installed') : (await claudeLoggedIn(resolveClaudeBin(cfg)).catch(() => false)) ? ok : no('not_signed_in');
  const settings = await readSettings(ownerId).catch(() => ({}) as Record<string, string>);
  return {
    claude,
    qwen: engine('qwen-code'),
    gemini: engine('gemini-cli'),
    codex: engine('codex'),
    flutter: await flutterLink(cfg),
    android: androidLink(),
    chrome: findBrowser() ? ok : no('not_installed'),
    playKey: stores ? storeLink(stores.googlePlay) : playKeyLink(settings['play_service_account']),
    appleKey: stores ? storeLink(stores.apple) : (await readAppleKey().catch(() => null)) ? ok : no('missing'),
    mac: process.platform === 'darwin' ? ok : no(process.platform === 'win32' ? 'windows' : 'linux'),
  };
}
