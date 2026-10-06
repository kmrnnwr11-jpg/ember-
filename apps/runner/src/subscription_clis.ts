import { spawn } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { AgentEvent } from './agent_cli.js';

/** Coding CLIs that run on the user's own subscription (logged in on the Runner machine). */
export type CliEngine = 'claude-code' | 'codex' | 'gemini-cli' | 'qwen-code';

export const CLI_ENGINES: CliEngine[] = ['claude-code', 'codex', 'gemini-cli', 'qwen-code'];

/** Node entry points of npm-installed CLIs, so they can be spawned without a shell. */
function npmScript(pkg: string, file: string): string | null {
  const roots = [process.env.APPDATA && path.join(process.env.APPDATA, 'npm', 'node_modules'), '/usr/local/lib/node_modules', '/usr/lib/node_modules'];
  for (const r of roots) {
    if (!r) continue;
    const p = path.join(r, pkg, file);
    if (existsSync(p)) return p;
  }
  return null;
}

/** Command + leading args to run a subscription CLI. */
export function cliCommand(engine: Exclude<CliEngine, 'claude-code'>): { bin: string; pre: string[] } | null {
  const script =
    engine === 'codex'
      ? npmScript('@openai/codex', 'bin/codex.js')
      : engine === 'qwen-code'
        ? npmScript('@qwen-code/qwen-code', 'cli-entry.js')
        : npmScript('@google/gemini-cli', 'bundle/gemini.js');
  return script ? { bin: process.execPath, pre: [script] } : null;
}

/** Arguments for a headless build; the full instructions + request go to stdin. */
export function cliBuildArgs(engine: Exclude<CliEngine, 'claude-code'>, cwd: string, model?: string): string[] {
  if (engine === 'codex') {
    return ['exec', '--json', '--skip-git-repo-check', '--full-auto', '-C', cwd, ...(model ? ['-m', model] : []), '-'];
  }
  // Qwen Code is a fork of Gemini CLI: the same headless flags.
  return ['-p', 'Follow the instructions and the user request above.', '--approval-mode', 'yolo', '-o', 'stream-json', ...(model ? ['-m', model] : [])];
}

const base = (p: string) => p.replace(/\\/g, '/').split('/').slice(-3).join('/');

/**
 * The files a PowerShell command writes: `... | Set-Content lib\a.dart`,
 * `Out-File -FilePath x`, `Add-Content -Path 'x'`, `[IO.File]::WriteAllText('x', ...)`.
 * Only what is plainly a file write; anything cleverer stays a shell command.
 */
export function shellWrites(cmd: string): string[] {
  const out: string[] = [];
  const clean = (p: string) => p.trim().replace(/^['"]|['"]$/g, '').replace(/\\\\/g, '\\');
  for (const m of cmd.matchAll(/\b(?:Set-Content|Add-Content|Out-File)\b([^|;\r\n]*)/gi)) {
    const args = (m[1] ?? '').trim();
    const named = /-(?:LiteralPath|FilePath|Path)\s+("[^"]+"|'[^']+'|\S+)/i.exec(args);
    const rest = args.replace(/-(?:Encoding|Width)\s+\S+/gi, '').replace(/-(?:NoNewline|Force|Append|NoClobber)\b/gi, '').trim();
    const target = named?.[1] ?? /^("[^"]+"|'[^']+'|\S+)/.exec(rest)?.[1];
    if (target && !target.startsWith('-') && !target.startsWith('$')) out.push(clean(target));
  }
  for (const m of cmd.matchAll(/WriteAllText\(\s*("[^"]+"|'[^']+')/gi)) out.push(clean(m[1] ?? ''));
  return [...new Set(out.filter((p) => p.length > 0))];
}

/** Parses one `codex exec --json` line. `lastText` keeps the final agent message for the result. */
export function parseCodexLine(line: string, state: { lastText: string }): AgentEvent[] {
  let j: Record<string, unknown>;
  try {
    j = JSON.parse(line) as Record<string, unknown>;
  } catch {
    return [];
  }
  const item = (j.item ?? {}) as Record<string, unknown>;
  if (j.type === 'item.completed' && item.type === 'agent_message' && typeof item.text === 'string') {
    state.lastText = item.text;
    return item.text.trim() ? [{ kind: 'text', text: item.text }] : [];
  }
  if (j.type === 'item.started' && item.type === 'file_change') {
    const changes = (item.changes ?? []) as Array<{ path?: string; kind?: string }>;
    return changes.map((c) => ({ kind: 'tool', name: c.kind === 'add' ? 'Write' : 'Edit', summary: base(c.path ?? '') }));
  }
  if (j.type === 'item.started' && item.type === 'command_execution') {
    const cmd = String(item.command ?? '');
    // On Windows Codex writes most files through PowerShell rather than its
    // file tool, so the build read "0 of 24 files" and showed a bare "@'"
    // while the app was being written. A write through the shell counts as a
    // write, named by its file.
    const written = shellWrites(cmd);
    if (written.length > 0) return written.map((p) => ({ kind: 'tool', name: 'Write', summary: base(p) }));
    return [{ kind: 'tool', name: 'Bash', summary: cmd.replace(/^.*?-Command\s+/, '').replace(/^["']|["']$/g, '').slice(0, 160) }];
  }
  if (j.type === 'turn.completed') return [{ kind: 'result', ok: true, costUsd: null, turns: null, message: state.lastText }];
  if (j.type === 'turn.failed' || j.type === 'error') {
    const msg = String((j.error as { message?: string } | undefined)?.message ?? j.message ?? 'Codex failed');
    return [{ kind: 'error', message: msg }];
  }
  return [];
}

/** Parses one `gemini -o stream-json` line (tolerant to minor format changes). */
export function parseGeminiLine(line: string, state: { lastText: string }): AgentEvent[] {
  let j: Record<string, unknown>;
  try {
    j = JSON.parse(line) as Record<string, unknown>;
  } catch {
    return [];
  }
  const type = String(j.type ?? '');
  if (type === 'message' || type === 'content' || type === 'text') {
    const text = String(j.content ?? j.text ?? j.value ?? '');
    if (!text.trim()) return [];
    state.lastText += text;
    return [{ kind: 'text', text }];
  }
  if (type === 'tool_use' || type === 'tool_call') {
    const name = String(j.tool_name ?? j.name ?? 'tool');
    const params = (j.parameters ?? j.args ?? {}) as Record<string, unknown>;
    const file = String(params.file_path ?? params.path ?? params.absolute_path ?? '');
    const mapped = /write/i.test(name) ? 'Write' : /edit|replace/i.test(name) ? 'Edit' : /read|glob|grep|list/i.test(name) ? 'Read' : /shell|command/i.test(name) ? 'Bash' : name;
    return [{ kind: 'tool', name: mapped, summary: file ? base(file) : String(params.command ?? '').slice(0, 160) }];
  }
  if (type === 'result') {
    const ok = j.status === undefined || j.status === 'success';
    const message = typeof j.response === 'string' ? j.response : state.lastText;
    return [{ kind: 'result', ok, costUsd: null, turns: null, message }];
  }
  if (type === 'error') return [{ kind: 'error', message: String(j.message ?? (j.error as { message?: string })?.message ?? 'Gemini CLI failed') }];
  return [];
}

/**
 * Parses one `qwen -o stream-json` line. Recent Qwen Code versions speak Claude
 * Code's event language (assistant / result with content blocks), older ones
 * Gemini CLI's (message / tool_use / result): both are read, the first that
 * recognises the line wins.
 */
export function parseQwenLine(line: string, state: { lastText: string }): AgentEvent[] {
  let j: Record<string, unknown>;
  try {
    j = JSON.parse(line) as Record<string, unknown>;
  } catch {
    return [];
  }
  if (j.type === 'assistant' || j.type === 'result') {
    const events = parseClaudeStyle(j);
    for (const ev of events) if (ev.kind === 'text') state.lastText = ev.text;
    return events;
  }
  return parseGeminiLine(line, state);
}

/** Claude-style content blocks, which Qwen Code also emits. */
function parseClaudeStyle(j: Record<string, unknown>): AgentEvent[] {
  if (j.type === 'assistant') {
    const content = ((j.message as { content?: unknown[] } | undefined)?.content ?? []) as Array<Record<string, unknown>>;
    const out: AgentEvent[] = [];
    for (const block of content) {
      if (block.type === 'text' && typeof block.text === 'string' && block.text.trim()) out.push({ kind: 'text', text: block.text });
      if (block.type === 'tool_use') {
        const raw = String(block.name);
        const input = (block.input ?? {}) as Record<string, unknown>;
        const name = /write/i.test(raw) ? 'Write' : /edit|replace/i.test(raw) ? 'Edit' : /shell|bash|command/i.test(raw) ? 'Bash' : raw;
        const file = String(input.file_path ?? input.path ?? input.absolute_path ?? '');
        out.push({ kind: 'tool', name, summary: file ? base(file) : String(input.command ?? '').slice(0, 160) });
      }
    }
    return out;
  }
  const ok = j.subtype === 'success' && j.is_error !== true;
  return [
    {
      kind: 'result',
      ok,
      costUsd: typeof j.total_cost_usd === 'number' ? j.total_cost_usd : null,
      turns: typeof j.num_turns === 'number' ? j.num_turns : null,
      message: typeof j.result === 'string' ? j.result : String(j.subtype ?? ''),
    },
  ];
}

/**
 * Qwen Code keeps its sign-in in ~/.qwen/settings.json (the provider chosen
 * with /auth) and, for a Qwen account, in ~/.qwen/oauth_creds.json. It counts as
 * signed in when either says a way to reach a model was set up.
 */
export function qwenConfigured(dir = path.join(os.homedir(), '.qwen'), env: NodeJS.ProcessEnv = process.env): boolean {
  if (existsSync(path.join(dir, 'oauth_creds.json'))) return true;
  try {
    const settings = JSON.parse(readFileSync(path.join(dir, 'settings.json'), 'utf8')) as Record<string, unknown>;
    const auth = (settings.security as { auth?: { selectedType?: string } } | undefined)?.auth?.selectedType;
    const providers = settings.modelProviders as Record<string, unknown> | undefined;
    if (typeof auth === 'string' && auth) return true;
    if (providers && Object.keys(providers).length > 0) return true;
  } catch {
    // no settings file yet
  }
  return !!(env.DASHSCOPE_API_KEY || env.QWEN_API_KEY || env.OPENAI_API_KEY);
}

/** Whether each subscription CLI is installed and logged in on this machine (cached 60 s). */
let loginCache: { at: number; value: Record<'codex' | 'gemini-cli' | 'qwen-code', boolean> } | null = null;

export async function cliLogins(): Promise<Record<'codex' | 'gemini-cli' | 'qwen-code', boolean>> {
  if (loginCache && Date.now() - loginCache.at < 60_000) return loginCache.value;
  const codex = await new Promise<boolean>((resolve) => {
    const cmd = cliCommand('codex');
    if (!cmd) return resolve(false);
    const p = spawn(cmd.bin, [...cmd.pre, 'login', 'status'], { windowsHide: true });
    let out = '';
    p.stdout?.on('data', (d) => (out += d));
    p.stderr?.on('data', (d) => (out += d));
    const t = setTimeout(() => (p.kill(), resolve(false)), 15000);
    p.on('error', () => (clearTimeout(t), resolve(false)));
    p.on('close', (code) => (clearTimeout(t), resolve(code === 0 && /logged in/i.test(out))));
  });
  let gemini = false;
  if (cliCommand('gemini-cli')) {
    const dir = path.join(os.homedir(), '.gemini');
    try {
      const settings = JSON.parse(readFileSync(path.join(dir, 'settings.json'), 'utf8')) as Record<string, unknown>;
      const auth = (settings.security as { auth?: { selectedType?: string } } | undefined)?.auth?.selectedType ?? settings.selectedAuthType;
      gemini = typeof auth === 'string' && (auth !== 'oauth-personal' || existsSync(path.join(dir, 'oauth_creds.json')));
    } catch {
      gemini = false;
    }
  }
  loginCache = { at: Date.now(), value: { codex, 'gemini-cli': gemini, 'qwen-code': !!cliCommand('qwen-code') && qwenConfigured() } };
  return loginCache.value;
}

/** Models each subscription CLI can use, for the model picker. First entry is the default. */
export function cliModels(): Record<CliEngine, Array<{ id: string; label: string; description?: string }>> {
  let codex: Array<{ id: string; label: string; description?: string }> = [];
  try {
    const cache = JSON.parse(readFileSync(path.join(os.homedir(), '.codex', 'models_cache.json'), 'utf8')) as { models?: Array<Record<string, unknown>> };
    codex = (cache.models ?? [])
      .filter((m) => m.visibility === 'list' && typeof m.slug === 'string')
      .sort((a, b) => Number(a.priority ?? 99) - Number(b.priority ?? 99))
      .map((m) => ({ id: String(m.slug), label: String(m.display_name ?? m.slug), description: typeof m.description === 'string' ? m.description : undefined }));
  } catch {
    // Codex not used yet on this machine: let the CLI pick its default.
  }
  return {
    'claude-code': [
      { id: 'sonnet', label: 'Claude Sonnet', description: 'Fast, great for most apps' },
      { id: 'opus', label: 'Claude Opus', description: 'Most capable, slower' },
      { id: 'fable', label: 'Claude Fable', description: 'Latest flagship' },
      { id: 'haiku', label: 'Claude Haiku', description: 'Fastest, simple apps' },
    ],
    codex,
    // No fixed list: Qwen Code uses the model of the provider chosen with /auth.
    'qwen-code': [],
    'gemini-cli': [
      { id: 'gemini-3.8-flash', label: 'Gemini 3.8 Flash', description: 'Fast' },
      { id: 'gemini-3.1-pro-preview', label: 'Gemini 3.1 Pro (preview)', description: 'Most capable' },
      { id: 'gemini-3.5-flash-lite', label: 'Gemini 3.5 Flash-Lite', description: 'Fastest' },
      { id: 'gemini-2.5-pro', label: 'Gemini 2.5 Pro' },
    ],
  };
}

/** A model id from the client, or undefined when it is not a safe CLI model name. */
export function safeModel(v: unknown): string | undefined {
  return typeof v === 'string' && /^[A-Za-z0-9][\w.-]{0,59}$/.test(v) && v !== 'fast' && v !== 'best' ? v : undefined;
}

/** Forget what was learned about the logins, so the next health check looks again. */
export function forgetLoginCache(): void {
  loginCache = null;
  claudeLoginCache = null;
}

let claudeLoginCache: { at: number; value: boolean } | null = null;

/** Whether Claude Code is signed in on this machine (`claude auth status`, cached 60 s). */
export async function claudeLoggedIn(claudeBin: string): Promise<boolean> {
  if (claudeLoginCache && Date.now() - claudeLoginCache.at < 60_000) return claudeLoginCache.value;
  const value = await new Promise<boolean>((resolve) => {
    const p = spawn(claudeBin, ['auth', 'status'], { windowsHide: true });
    let out = '';
    p.stdout?.on('data', (d) => (out += d));
    const t = setTimeout(() => (p.kill(), resolve(false)), 15000);
    p.on('error', () => (clearTimeout(t), resolve(false)));
    p.on('close', () => {
      clearTimeout(t);
      try {
        resolve((JSON.parse(out) as { loggedIn?: boolean }).loggedIn === true);
      } catch {
        resolve(false);
      }
    });
  });
  claudeLoginCache = { at: Date.now(), value };
  return value;
}

const q = (s: string) => `"${s.replace(/"/g, '')}"`;

/**
 * The lines of a small script that signs one subscription CLI in. Installing
 * the CLI comes first when it is missing. The person finishes the sign-in in
 * the browser that opens; nothing is typed for them and no password passes here.
 */
export function loginLines(engine: CliEngine, claudeBin: string, windows: boolean): string[] {
  const npm = windows ? q(path.join(path.dirname(process.execPath), 'npm.cmd')) : 'npm';
  const call = windows ? 'call ' : '';
  if (engine === 'claude-code') return [`${q(claudeBin)} auth login`];
  if (engine === 'codex') {
    const cmd = cliCommand('codex');
    return cmd ? [`${q(cmd.bin)} ${cmd.pre.map(q).join(' ')} login`] : [`${call}${npm} install -g @openai/codex`, 'codex login'];
  }
  if (engine === 'qwen-code') {
    return [
      ...(cliCommand('qwen-code') ? [] : [`${call}${npm} install -g @qwen-code/qwen-code`]),
      'echo Scrivi /auth, scegli il tuo accesso Qwen, poi scrivi /quit',
      'qwen',
    ];
  }
  const installed = cliCommand('gemini-cli');
  return [
    ...(installed ? [] : [`${call}${npm} install -g @google/gemini-cli`]),
    'echo Scegli "Login with Google", accedi nel browser, poi scrivi /quit',
    'gemini',
  ];
}

/** Opens a terminal window on this computer that signs a subscription CLI in. */
export async function openLoginWindow(engine: CliEngine, claudeBin: string): Promise<'opened' | 'unsupported'> {
  const windows = process.platform === 'win32';
  if (!windows && process.platform !== 'darwin') return 'unsupported';
  const lines = loginLines(engine, claudeBin, windows);
  const done = 'Fatto. Puoi chiudere questa finestra e tornare in Ember.';
  const dir = path.join(os.tmpdir(), 'ember-login');
  const { mkdirSync, writeFileSync } = await import('node:fs');
  mkdirSync(dir, { recursive: true });
  if (windows) {
    const file = path.join(dir, `${engine}.cmd`);
    const text = ['@echo off', 'title Ember - accesso', 'echo Accedi con il tuo abbonamento. Ember non vede la tua password.', 'echo.', ...lines, 'echo.', `echo ${done}`, 'pause >nul'];
    writeFileSync(file, text.join('\r\n') + '\r\n');
    spawn('cmd.exe', ['/d', '/c', 'start', 'Ember', 'cmd.exe', '/k', file], { detached: true, stdio: 'ignore' }).unref();
  } else {
    const file = path.join(dir, `${engine}.command`);
    writeFileSync(file, ['#!/bin/bash', 'echo "Accedi con il tuo abbonamento. Ember non vede la tua password."', ...lines, `echo "${done}"`, 'read -n 1 -s'].join('\n') + '\n', { mode: 0o755 });
    spawn('open', [file], { detached: true, stdio: 'ignore' }).unref();
  }
  forgetLoginCache();
  return 'opened';
}
