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
