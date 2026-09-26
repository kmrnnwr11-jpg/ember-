import { spawn, type ChildProcess } from 'node:child_process';
import { existsSync, mkdirSync } from 'node:fs';
import { EventEmitter } from 'node:events';
import path from 'node:path';
import { nanoid } from 'nanoid';
import type { Config } from './config.js';
import { cliBuildArgs, cliCommand, cliLogins, parseCodexLine, parseGeminiLine, type CliEngine } from './subscription_clis.js';

/** Normalized agent progress event sent to the IDE as `agent.event`. */
export type AgentEvent =
  | { kind: 'text'; text: string }
  | { kind: 'tool'; name: string; summary: string }
  | { kind: 'result'; ok: boolean; costUsd: number | null; turns: number | null; message: string }
  | { kind: 'error'; message: string };

export interface AgentRun {
  id: string;
  ownerId: string;
  projectId: string;
  engine: CliEngine;
  status: 'running' | 'succeeded' | 'failed' | 'cancelled';
  startedAt: string;
  /** Files the agent announced it will create or change (from its `PLAN_FILES: n` line). */
  plannedFiles?: number;
  /** Latest events, so a client that reconnects (screen off, app in background) can catch up. */
  events?: AgentEvent[];
}

const PLAN_RE = /PLAN_FILES:\s*(\d{1,3})/;

/** System prompt appended to Claude Code for "Crea App" builds. */
export const CLAUDE_CODE_BUILD_PROMPT = `You are building a Flutter app inside the current directory (a \`flutter create\` project), working with a non-technical user through a phone chat. Later messages in this session are follow-up requests on the same app: keep everything that already works and extend it.

FIRST LINE: before touching any file, reply with one line \`PLAN_FILES: <n>\` where n is how many files you expect to create or change.

WHAT TO BUILD
- Build a complete, real product for the kind of app requested, not a single screen or a demo. For a product-type request include the core feature set users expect (e.g. a chat/dating app like Badoo: sign-up and login with email and Google, profile with photo, user list/discovery, conversation list, 1-to-1 private chats and private rooms, real-time messages, logout). For a simple utility (e.g. a calculator) keep it simple.
- Large extras the user did not ask for (e.g. video calls, payments) are NOT built automatically: propose them in "Prossimi passi".
- UI text in the user's language. Material 3, polished, consistent. If an APPROVED DESIGN is given, follow it closely.
- Must compile for Android and web.

REAL SERVICES, NEVER FAKE
- Use real, standard integrations: Firebase Auth (email/password + Google Sign-In), Cloud Firestore (data, real-time), Firebase Storage (images); video calls with Agora (agora_rtc_engine) or Jitsi; push with Firebase Messaging; payments with Stripe; maps with Google Maps.
- Never invent API keys or config. Put every key/config value in lib/config/app_config.dart with empty defaults. Initialize services only when configured; when something is missing show a clear in-app "Configurazione necessaria" screen/banner saying exactly what is missing, so the app still runs.
- Do not use flutterfire CLI; initialize Firebase with FirebaseOptions built from AppConfig.
- When the user pastes keys or config values in a message, write them into AppConfig and wire them up.

SPEED
- Do not explore the template beyond what you need. Write files directly.
- Run \`flutter pub get\` after changing dependencies. At the end run \`flutter analyze\` and fix all errors (re-run until clean). Do not run \`flutter test\`, \`flutter run\` or builds. Keep test/widget_test.dart as a minimal test that compiles.
- Stay inside this directory.

PAYMENTS (only when the user asks for paid features, subscriptions, premium, packs or coins): implement Google Play Billing with the \`in_app_purchase\` package: a polished paywall screen with the products and prices loaded from the store, buy, restore purchases, pending/error states, entitlement saved locally that unlocks the paid features, and complete purchases (consumables for coins/packs). On web show that purchases are available in the Android app. Keep product ids in lib/config/monetization.dart. On iOS (App Store) a product id must be unique across the whole developer account, so compute each id per platform: on iOS use '<pubspec name>_<id>' (e.g. read_master_premium_monthly), on Android the plain id, with a getter based on defaultTargetPlatform == TargetPlatform.iOS; list the plain ids in EMBER_PRODUCTS. At the very end of the final reply add ONE line starting with EMBER_PRODUCTS: followed by a compact JSON array of every product the app uses, e.g. EMBER_PRODUCTS: [{"id":"premium_monthly","type":"subscription","title":"Premium","description":"All features","price":"4.99","currency":"EUR","period":"P1M","freeTrialDays":7},{"id":"coins_100","type":"inapp","title":"100 coins","description":"Coin pack","price":"0.99","currency":"EUR"}] (ids lowercase a-z 0-9 _ ; period P1W/P1M/P3M/P6M/P1Y; prices the user asked for, otherwise sensible ones). Omit the line when the app has no purchases.

SCREENSHOT MODE (always include): on web, when the URL has the query parameter ember_screen=N (N = 0..5), open directly the app's N-th most representative screen (home, main feature, detail, list, profile/settings, premium…), filled with realistic demo content, skipping splash, login, onboarding and "configuration needed" screens, without dialogs or debug banners. Read it with Uri.base.queryParameters['ember_screen'] and keep the screen list in lib/config/screenshot_screens.dart. Normal launches are unchanged.

ADS (only when the user asks for ads/AdMob): use the google_mobile_ads package pinned to exactly 5.3.1 in pubspec (9.x does not build for iPhone with Xcode 26) with the Google UMP consent form (required in the EU) shown before loading ads, then on iOS the App Tracking Transparency prompt (app_tracking_transparency package, requestTrackingAuthorization when the status is notDetermined, before MobileAds.instance.initialize) with an English NSUserTrackingUsageDescription in ios/Runner/Info.plist (Apple rejects an app that declares tracking without asking), the ad formats the user asked for (banner, interstitial with frequency capping, rewarded) placed where they do not break the UX, and no ads for users who bought premium. Keep the IDs in lib/config/ads_config.dart: AdMob app id and one ad unit id per format, defaulting to Google's official TEST ids so the app works before real ids exist; put the app id in android/app/src/main/AndroidManifest.xml (com.google.android.gms.ads.APPLICATION_ID) and ios/Runner/Info.plist (GADApplicationIdentifier). On web show nothing. When the user pastes real AdMob ids, write them in ads_config.dart and the manifests. At the very end of the final reply add ONE line starting with EMBER_ADS: followed by compact JSON listing the formats used, e.g. EMBER_ADS: {"banner":true,"interstitial":true,"rewarded":false}. Omit the line when the app has no ads.

FINAL REPLY (always, in the user's language, Markdown, concise):
## Fatto
- bullet list of what now works
## Da configurare
Numbered, step-by-step instructions for every external service still missing: which site to open (full URL), which account/project to create, what to click, which values to copy, and exactly what to paste back in this chat (e.g. "Incollami apiKey, appId, projectId…"). Use the ANDROID APP INFO provided (package name and SHA-1 fingerprints) where needed (Firebase Android app, Google Sign-In). Write "Niente da configurare" if nothing is needed.
## Prossimi passi suggeriti
- 2-4 concrete feature ideas
End with one professional question inviting the next request, e.g. "Dimmi quali altre funzioni vuoi aggiungere o cosa vuoi migliorare."`;

/** `fast` = Sonnet at medium effort (default); `best` = Opus at high effort. */
export type BuildQuality = 'fast' | 'best';

/** Locates the Claude Code executable (native binary on Windows npm installs). */
export function resolveClaudeBin(cfg: Config): string {
  if (cfg.CLAUDE_BIN) return cfg.CLAUDE_BIN;
  if (process.platform === 'win32' && process.env.APPDATA) {
    const exe = path.join(process.env.APPDATA, 'npm', 'node_modules', '@anthropic-ai', 'claude-code', 'bin', 'claude.exe');
    if (existsSync(exe)) return exe;
  }
  return 'claude';
}

function summarizeToolInput(name: string, input: Record<string, unknown>): string {
  const p = (input.file_path ?? input.path ?? input.pattern ?? '') as string;
  if (name === 'Bash') return String(input.command ?? '').slice(0, 200);
  return typeof p === 'string' ? p.replace(/\\/g, '/').split('/').slice(-3).join('/') : '';
}

let cliCache: { at: number; value: Record<string, boolean> } | null = null;

/** Which AI CLIs are on PATH (cached 5 min): claude (Claude Code), codex (ChatGPT), gemini. */
export async function detectClis(): Promise<Record<string, boolean>> {
  if (cliCache && Date.now() - cliCache.at < 300_000) return cliCache.value;
  const which = process.platform === 'win32' ? 'where.exe' : 'which';
  const check = (name: string) =>
    new Promise<boolean>((resolve) => {
      const p = spawn(which, [name], { windowsHide: true });
      p.on('error', () => resolve(false));
      p.on('close', (code) => resolve(code === 0));
    });
  const [claude, codex, gemini] = await Promise.all([check('claude'), check('codex'), check('gemini')]);
  cliCache = { at: Date.now(), value: { claude, codex, gemini } };
  return cliCache.value;
}

/** Parses one stream-json line from `claude -p --output-format stream-json`. */
export function parseClaudeLine(line: string): AgentEvent[] {
  let j: Record<string, unknown>;
  try {
    j = JSON.parse(line) as Record<string, unknown>;
  } catch {
    return [];
  }
  switch (j.type) {
    case 'assistant': {
      const content = ((j.message as { content?: unknown[] } | undefined)?.content ?? []) as Array<Record<string, unknown>>;
      const out: AgentEvent[] = [];
      for (const block of content) {
        if (block.type === 'text' && typeof block.text === 'string' && block.text.trim()) out.push({ kind: 'text', text: block.text });
        if (block.type === 'tool_use') {
          const name = String(block.name);
          out.push({ kind: 'tool', name, summary: summarizeToolInput(name, (block.input ?? {}) as Record<string, unknown>) });
        }
      }
      return out;
    }
    case 'result':
      return [
        {
          kind: 'result',
          ok: j.subtype === 'success' && j.is_error !== true,
          costUsd: typeof j.total_cost_usd === 'number' ? j.total_cost_usd : null,
          turns: typeof j.num_turns === 'number' ? j.num_turns : null,
          message: typeof j.result === 'string' ? j.result : String(j.subtype ?? ''),
        },
      ];
    default:
      return [];
  }
}

/**
 * Runs Claude Code headless in a project directory using the machine's own
 * Claude login (§3 "CLI con abbonamento", brought forward from Phase 7).
 * Local driver only: the CLI runs on the host with the host user's session.
 */
export class ClaudeCodeEngine extends EventEmitter<{ event: [run: AgentRun, event: AgentEvent]; status: [run: AgentRun] }> {
  private readonly procs = new Map<string, ChildProcess>();
  private readonly runs = new Map<string, AgentRun>();
  private available: boolean | null = null;

  constructor(
    private readonly cfg: Config,
    private readonly spawnImpl: typeof spawn = spawn,
  ) {
    super();
  }

  /** True when the CLI is installed and runnable (cached). */
  async isAvailable(): Promise<boolean> {
    if (this.cfg.WORKSPACE_DRIVER !== 'local' || this.cfg.CLAUDE_CODE_ENABLED === false) return false;
    if (this.available !== null) return this.available;
    this.available = await new Promise<boolean>((resolve) => {
      try {
        const p = this.spawnImpl(resolveClaudeBin(this.cfg), ['--version'], { windowsHide: true });
        const timer = setTimeout(() => (p.kill(), resolve(false)), 15000);
        p.on('error', () => (clearTimeout(timer), resolve(false)));
        p.on('close', (code) => (clearTimeout(timer), resolve(code === 0)));
      } catch {
        resolve(false);
      }
    });
    return this.available;
  }

  activeFor(projectId: string): AgentRun | undefined {
    return [...this.runs.values()].find((r) => r.projectId === projectId && r.status === 'running');
  }

  /**
   * Every build still running for this user, one entry per project.
   *
   * The app list needs to say which projects are being written right now, and
   * asking project by project would be one round trip each: with thirty
   * projects on screen that is thirty questions to answer one.
   */
  runningFor(ownerId: string): Array<{ projectId: string; runId: string; startedAt: string; files: number; plannedFiles?: number }> {
    return [...this.runs.values()]
      .filter((r) => r.ownerId === ownerId && r.status === 'running' && r.projectId)
      .map((r) => ({
        projectId: r.projectId!,
        runId: r.id,
        startedAt: r.startedAt,
        files: (r.events ?? []).filter((e) => e.kind === 'tool' && (e.name === 'Write' || e.name === 'Edit' || e.name === 'MultiEdit')).length,
        plannedFiles: r.plannedFiles,
      }));
  }

  /** The running or most recent run of a project. */
  latestFor(projectId: string): AgentRun | undefined {
    return [...this.runs.values()].filter((r) => r.projectId === projectId).at(-1);
  }

  get(runId: string): AgentRun | undefined {
    return this.runs.get(runId);
  }

  /** Whether a CLI engine can run builds: Claude Code installed, Codex/Gemini CLI logged in. */
  async isEngineAvailable(engine: CliEngine): Promise<boolean> {
    if (engine === 'claude-code') return this.isAvailable();
    if (this.cfg.WORKSPACE_DRIVER !== 'local') return false;
    return (await cliLogins())[engine];
  }

  start(opts: { ownerId: string; projectId: string; cwd: string; prompt: string; resume?: boolean; quality?: BuildQuality; engine?: CliEngine; model?: string }): AgentRun {
    const best = opts.quality === 'best' || /opus|fable/.test(opts.model ?? '');
    const engine = opts.engine ?? 'claude-code';
    const run: AgentRun = {
      id: nanoid(12),
      ownerId: opts.ownerId,
      projectId: opts.projectId,
      engine,
      status: 'running',
      startedAt: new Date().toISOString(),
    };
    this.runs.set(run.id, run);
    const args = [
      '-p',
      '--output-format', 'stream-json',
      '--verbose',
      '--model', opts.model ?? (best ? this.cfg.CLAUDE_CODE_MODEL_BEST : this.cfg.CLAUDE_CODE_MODEL_FAST),
      '--effort', best ? 'high' : 'medium',
      '--permission-mode', 'acceptEdits',
      '--allowedTools', 'Read', 'Write', 'Edit', 'MultiEdit', 'Glob', 'Grep', 'TodoWrite', 'Bash(flutter:*)', 'Bash(dart:*)',
      // Tests and run/build commands are slow and can hang; the Runner builds the preview itself.
      '--disallowedTools', 'WebFetch', 'WebSearch', 'Task', 'Bash(flutter test:*)', 'Bash(flutter run:*)', 'Bash(flutter build:*)',
      '--strict-mcp-config',
      '--max-turns', String(this.cfg.CLAUDE_CODE_MAX_TURNS),
      '--append-system-prompt', CLAUDE_CODE_BUILD_PROMPT,
      ...(opts.resume ? ['--continue'] : []),
    ];
    // Codex (ChatGPT plan) and Gemini CLI (Google account) get the same instructions through stdin.
    const other = engine === 'claude-code' ? null : cliCommand(engine);
    if (engine !== 'claude-code' && !other) throw Object.assign(new Error(`${engine} is not installed on this Runner`), { code: 'unsupported' });
    const child = other
      ? this.spawnImpl(other.bin, [...other.pre, ...cliBuildArgs(engine as 'codex' | 'gemini-cli', opts.cwd, opts.model)], { cwd: opts.cwd, windowsHide: true, env: { ...process.env, CI: '1' } })
      : this.spawnImpl(resolveClaudeBin(this.cfg), args, {
          cwd: opts.cwd,
          windowsHide: true,
          env: { ...process.env, CI: '1' },
        });
    this.procs.set(run.id, child);
    this.emit('status', run);

    // Prompt via stdin: avoids shell quoting of arbitrary user text.
    child.stdin?.end(other ? `${CLAUDE_CODE_BUILD_PROMPT}\n\nUSER REQUEST (work in the current directory; keep what already works):\n${opts.prompt}` : opts.prompt);
    const state = { lastText: '' };
    const parse = (line: string) => (engine === 'codex' ? parseCodexLine(line, state) : engine === 'gemini-cli' ? parseGeminiLine(line, state) : parseClaudeLine(line));

    let buffer = '';
    let sawResult = false;
    child.stdout?.setEncoding('utf8').on('data', (chunk: string) => {
      buffer += chunk;
      let nl: number;
      while ((nl = buffer.indexOf('\n')) >= 0) {
        const line = buffer.slice(0, nl).trim();
        buffer = buffer.slice(nl + 1);
        if (!line) continue;
        for (const ev of parse(line)) {
          if (ev.kind === 'result') sawResult = true;
          if (ev.kind === 'text' && run.plannedFiles === undefined) {
            const m = PLAN_RE.exec(ev.text);
            if (m) run.plannedFiles = Number(m[1]);
          }
          run.events = [...(run.events ?? []), ev].slice(-300);
          this.emit('event', run, ev);
        }
      }
    });
    let stderr = '';
    child.stderr?.setEncoding('utf8').on('data', (c: string) => (stderr = (stderr + c).slice(-4000)));
    child.on('error', (e) => this.emit('event', run, { kind: 'error', message: `${engine} could not start: ${e.message}` }));
    child.on('close', (code) => {
      this.procs.delete(run.id);
      if (run.status === 'running') {
        run.status = code === 0 && sawResult ? 'succeeded' : 'failed';
        if (run.status === 'failed' && stderr.trim()) this.emit('event', run, { kind: 'error', message: stderr.trim().slice(-1000) });
      }
      this.emit('status', run);
    });
    return run;
  }

  /**
   * One-shot text generation with the machine's Claude login (no tools, no
   * project access), e.g. design mockups. Runs in a neutral directory so no
   * CLAUDE.md or project context is loaded.
   */
  complete(opts: { prompt: string; system: string; quality?: BuildQuality; timeoutMs?: number }): Promise<{ text: string; costUsd: number | null }> {
    const best = opts.quality === 'best';
    const cwd = path.resolve(this.cfg.WORKSPACES_ROOT, '.tmp');
    mkdirSync(cwd, { recursive: true });
    const args = [
      '-p',
      '--output-format', 'json',
      '--model', best ? this.cfg.CLAUDE_CODE_MODEL_BEST : this.cfg.CLAUDE_CODE_MODEL_FAST,
      '--effort', best ? 'medium' : 'low',
      '--tools', '',
      '--strict-mcp-config',
      '--max-turns', '1',
      '--system-prompt', opts.system,
    ];
    return new Promise((resolve, reject) => {
      const child = this.spawnImpl(resolveClaudeBin(this.cfg), args, { cwd, windowsHide: true, env: { ...process.env, CI: '1' } });
      let out = '';
      let err = '';
      const timer = setTimeout(() => {
        child.kill();
        reject(new Error('Claude Code timed out'));
      }, opts.timeoutMs ?? 300_000);
      child.stdout?.setEncoding('utf8').on('data', (c: string) => (out += c));
      child.stderr?.setEncoding('utf8').on('data', (c: string) => (err = (err + c).slice(-2000)));
      child.on('error', (e) => (clearTimeout(timer), reject(e)));
      child.on('close', (code) => {
        clearTimeout(timer);
        try {
          const j = JSON.parse(out.trim().split('\n').pop() ?? '{}') as { result?: string; is_error?: boolean; total_cost_usd?: number };
          if (code !== 0 || j.is_error || typeof j.result !== 'string') throw new Error(j.result || err.trim() || `exit ${code}`);
          resolve({ text: j.result, costUsd: typeof j.total_cost_usd === 'number' ? j.total_cost_usd : null });
        } catch (e) {
          reject(new Error(`Claude Code: ${(e as Error).message}`.slice(0, 1000)));
        }
      });
      child.stdin?.end(opts.prompt);
    });
  }

  cancel(runId: string): boolean {
    const run = this.runs.get(runId);
    if (!run) return false;
    // The process may already be gone (the machine slept, the CLI died): the
    // run must still stop counting as running, or the project stays blocked.
    run.status = 'cancelled';
    const child = this.procs.get(runId);
    if (!child) return false;
    if (process.platform === 'win32' && child.pid) {
      this.spawnImpl('taskkill', ['/pid', String(child.pid), '/T', '/F'], { windowsHide: true });
    } else {
      child.kill('SIGTERM');
    }
    return true;
  }

  cancelAll() {
    for (const id of this.procs.keys()) this.cancel(id);
  }
}
