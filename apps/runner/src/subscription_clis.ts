import { spawn } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { AgentEvent } from './agent_cli.js';

/** Coding CLIs that run on the user's own subscription (logged in on the Runner machine). */
export type CliEngine = 'claude-code' | 'codex' | 'gemini-cli';

export const CLI_ENGINES: CliEngine[] = ['claude-code', 'codex', 'gemini-cli'];

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
  const script = engine === 'codex' ? npmScript('@openai/codex', 'bin/codex.js') : npmScript('@google/gemini-cli', 'bundle/gemini.js');
  return script ? { bin: process.execPath, pre: [script] } : null;
}

/** Arguments for a headless build; the full instructions + request go to stdin. */
export function cliBuildArgs(engine: Exclude<CliEngine, 'claude-code'>, cwd: string, model?: string): string[] {
  if (engine === 'codex') {
    return ['exec', '--json', '--skip-git-repo-check', '--full-auto', '-C', cwd, ...(model ? ['-m', model] : []), '-'];
  }
  return ['-p', 'Follow the instructions and the user request above.', '--approval-mode', 'yolo', '-o', 'stream-json', ...(model ? ['-m', model] : [])];
}

const base = (p: string) => p.replace(/\\/g, '/').split('/').slice(-3).join('/');

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

/** Whether each subscription CLI is installed and logged in on this machine (cached 60 s). */
let loginCache: { at: number; value: Record<'codex' | 'gemini-cli', boolean> } | null = null;

export async function cliLogins(): Promise<Record<'codex' | 'gemini-cli', boolean>> {
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
  loginCache = { at: Date.now(), value: { codex, 'gemini-cli': gemini } };
  return loginCache.value;
}
