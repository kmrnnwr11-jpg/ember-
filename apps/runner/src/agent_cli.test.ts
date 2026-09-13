import { EventEmitter } from 'node:events';
import { PassThrough } from 'node:stream';
import { describe, expect, it } from 'vitest';
import { ClaudeCodeEngine, parseClaudeLine, type AgentEvent } from './agent_cli.js';
import { loadConfig } from './config.js';

class FakeChild extends EventEmitter {
  stdout = new PassThrough();
  stderr = new PassThrough();
  stdin = new PassThrough();
  pid = 4242;
  input = '';
  constructor() {
    super();
    this.stdin.on('data', (d) => (this.input += d));
  }
  kill() {
    this.emit('close', null);
    return true;
  }
}

describe('parseClaudeLine', () => {
  it('maps assistant text, tool use and result', () => {
    expect(parseClaudeLine('{"type":"assistant","message":{"content":[{"type":"text","text":"Creo la home"},{"type":"tool_use","name":"Write","input":{"file_path":"C:\\\\ws\\\\p\\\\lib\\\\main.dart"}}]}}')).toEqual([
      { kind: 'text', text: 'Creo la home' },
      { kind: 'tool', name: 'Write', summary: 'p/lib/main.dart' },
    ]);
    expect(parseClaudeLine('{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"flutter analyze"}}]}}')[0]).toEqual({
      kind: 'tool',
      name: 'Bash',
      summary: 'flutter analyze',
    });
    expect(parseClaudeLine('{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0.42,"num_turns":12,"result":"Fatto"}')).toEqual([
      { kind: 'result', ok: true, costUsd: 0.42, turns: 12, message: 'Fatto' },
    ]);
    expect(parseClaudeLine('{"type":"system","subtype":"init"}')).toEqual([]);
    expect(parseClaudeLine('not json')).toEqual([]);
  });
});

describe('ClaudeCodeEngine', () => {
  it('passes prompt on stdin with restricted tools, streams events, reports success', async () => {
    const child = new FakeChild();
    let spawned: { bin: string; args: string[]; cwd?: string } | null = null;
    const fakeSpawn = ((bin: string, args: string[], opts: { cwd?: string }) => {
      spawned = { bin, args, cwd: opts.cwd };
      return child;
    }) as never;
    const engine = new ClaudeCodeEngine(loadConfig({ DEV_AUTH: 'true', CLAUDE_BIN: 'claude-test' }), fakeSpawn);
    const events: AgentEvent[] = [];
    const statuses: string[] = [];
    engine.on('event', (_r, e) => events.push(e));
    engine.on('status', (r) => statuses.push(r.status));

    const run = engine.start({ ownerId: 'u', projectId: 'p', cwd: '/ws/p', prompt: 'app ricette "con" $foto' });
    expect(spawned!.bin).toBe('claude-test');
    expect(spawned!.cwd).toBe('/ws/p');
    expect(spawned!.args).toContain('--strict-mcp-config');
    expect(spawned!.args).toContain('Bash(flutter:*)');
    expect(spawned!.args).not.toContain('Bash');
    const a = spawned!.args;
    expect([a[a.indexOf('--model') + 1], a[a.indexOf('--effort') + 1]]).toEqual(['sonnet', 'medium']);
    expect(spawned!.args.join(' ')).not.toContain('ricette');
    await new Promise((r) => setTimeout(r, 5));
    expect(child.input).toBe('app ricette "con" $foto');
    expect(engine.activeFor('p')?.id).toBe(run.id);

    child.stdout.write('{"type":"assistant","message":{"content":[{"type":"text","text":"ok"}]}}\n{"type":"res');
    child.stdout.write('ult","subtype":"success","total_cost_usd":0.1,"num_turns":3,"result":"done"}\n');
    await new Promise((r) => setTimeout(r, 5));
    child.emit('close', 0);

    expect(events.map((e) => e.kind)).toEqual(['text', 'result']);
    expect(statuses).toEqual(['running', 'succeeded']);
    expect(engine.activeFor('p')).toBeUndefined();
  });

  it('fails when the process exits without a result and surfaces stderr', async () => {
    const child = new FakeChild();
    const engine = new ClaudeCodeEngine(loadConfig({ DEV_AUTH: 'true' }), (() => child) as never);
    const events: AgentEvent[] = [];
    let last = '';
    engine.on('event', (_r, e) => events.push(e));
    engine.on('status', (r) => (last = r.status));
    engine.start({ ownerId: 'u', projectId: 'p', cwd: '.', prompt: 'x' });
    child.stderr.write('Not logged in');
    await new Promise((r) => setTimeout(r, 5));
    child.emit('close', 1);
    expect(last).toBe('failed');
    expect(events).toContainEqual({ kind: 'error', message: 'Not logged in' });
  });

  it('is unavailable with the docker driver or when disabled', async () => {
    expect(await new ClaudeCodeEngine(loadConfig({ DEV_AUTH: 'true', WORKSPACE_DRIVER: 'docker' })).isAvailable()).toBe(false);
    expect(await new ClaudeCodeEngine(loadConfig({ DEV_AUTH: 'true', CLAUDE_CODE_ENABLED: 'false' })).isAvailable()).toBe(false);
  });
});
