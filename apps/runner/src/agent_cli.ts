import { spawn, type ChildProcess } from 'node:child_process';
import { existsSync } from 'node:fs';
import { EventEmitter } from 'node:events';
import path from 'node:path';
import { nanoid } from 'nanoid';
import type { Config } from './config.js';

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
  engine: 'claude-code';
  status: 'running' | 'succeeded' | 'failed' | 'cancelled';
  startedAt: string;
}

/** System prompt appended to Claude Code for "Crea App" builds. */
export const CLAUDE_CODE_BUILD_PROMPT = `You are building a Flutter app inside the current directory, which is a fresh \`flutter create\` project. The user is waiting on a phone: be FAST.
Scope:
- Build exactly what the user asked, working and polished, with a clean Material 3 look. Match the size of the app to the request: a simple request (e.g. a calculator) gets a simple app in 1-3 files. Do not add features, screens or persistence the user did not ask for.
- Use the same language as the user's request for all UI text.
- The app must run on the web and on Android: prefer Flutter SDK widgets and pure-Dart packages; add dependencies only if really needed.
Speed rules:
- Do not explore: the project is the standard template (lib/main.dart, pubspec.yaml, test/widget_test.dart). Write files directly with Write.
- Only if you added dependencies, run \`flutter pub get\` once.
- Replace test/widget_test.dart with a minimal test that compiles against your app.
- At the end run \`flutter analyze\` once; if it reports errors, fix them and re-run until clean. Do not run \`flutter test\`, \`flutter run\` or builds.
- Stay inside this directory. Finish with 2-3 short lines describing the app, in the user's language.`;

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

  get(runId: string): AgentRun | undefined {
    return this.runs.get(runId);
  }

  start(opts: { ownerId: string; projectId: string; cwd: string; prompt: string; resume?: boolean; quality?: BuildQuality }): AgentRun {
    const best = opts.quality === 'best';
    const run: AgentRun = {
      id: nanoid(12),
      ownerId: opts.ownerId,
      projectId: opts.projectId,
      engine: 'claude-code',
      status: 'running',
      startedAt: new Date().toISOString(),
    };
    this.runs.set(run.id, run);
    const args = [
      '-p',
      '--output-format', 'stream-json',
      '--verbose',
      '--model', best ? this.cfg.CLAUDE_CODE_MODEL_BEST : this.cfg.CLAUDE_CODE_MODEL_FAST,
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
    const child = this.spawnImpl(resolveClaudeBin(this.cfg), args, {
      cwd: opts.cwd,
      windowsHide: true,
      env: { ...process.env, CI: '1' },
    });
    this.procs.set(run.id, child);
    this.emit('status', run);

    // Prompt via stdin: avoids shell quoting of arbitrary user text.
    child.stdin?.end(opts.prompt);

    let buffer = '';
    let sawResult = false;
    child.stdout?.setEncoding('utf8').on('data', (chunk: string) => {
      buffer += chunk;
      let nl: number;
      while ((nl = buffer.indexOf('\n')) >= 0) {
        const line = buffer.slice(0, nl).trim();
        buffer = buffer.slice(nl + 1);
        if (!line) continue;
        for (const ev of parseClaudeLine(line)) {
          if (ev.kind === 'result') sawResult = true;
          this.emit('event', run, ev);
        }
      }
    });
    let stderr = '';
    child.stderr?.setEncoding('utf8').on('data', (c: string) => (stderr = (stderr + c).slice(-4000)));
    child.on('error', (e) => this.emit('event', run, { kind: 'error', message: `Claude Code could not start: ${e.message}` }));
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

  cancel(runId: string): boolean {
    const run = this.runs.get(runId);
    const child = this.procs.get(runId);
    if (!run || !child) return false;
    run.status = 'cancelled';
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
