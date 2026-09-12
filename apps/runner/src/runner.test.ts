import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import type { AddressInfo } from 'node:net';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import WebSocket from 'ws';
import { buildApp } from './app.js';
import { loadConfig } from './config.js';
import { ProjectFs } from './fs.js';
import { JobManager } from './jobs.js';
import { normalizeRel, safeResolve, validateProjectName } from './paths.js';
import type { ExecOptions, PtyHandle, WorkspaceDriver } from './workspaces/driver.js';

/** Simulates the workspace container: `flutter create <name>` writes a minimal project. */
class FakeDriver implements WorkspaceDriver {
  readonly kind = 'local' as const;
  constructor(private readonly root: string) {}
  hostRoot(id: string) {
    return path.join(this.root, id);
  }
  async ensure(id: string) {
    await mkdir(this.hostRoot(id), { recursive: true });
    return { containerId: null };
  }
  async stop() {}
  /** Echo "terminal": writes back input prefixed, exits on "exit\r". */
  async openPty(): Promise<PtyHandle> {
    let dataCb: (d: string) => void = () => {};
    let exitCb: (c: number) => void = () => {};
    return {
      onData: (cb) => void (dataCb = cb),
      onExit: (cb) => void (exitCb = cb),
      write: (d) => (d === 'exit\r' ? setTimeout(() => exitCb(0), 5) : setTimeout(() => dataCb(`echo:${d}`), 5)),
      resize: (c, r) => setTimeout(() => dataCb(`size:${c}x${r}`), 5),
      kill: () => setTimeout(() => exitCb(137), 5),
    };
  }
  async exec(id: string, cmd: string, args: string[], opts: ExecOptions) {
    if (cmd === 'flutter' && args[0] === 'build' && args[1] === 'web') {
      const dir = path.join(this.hostRoot(id), opts.cwd, 'build', 'web');
      await mkdir(dir, { recursive: true });
      const base = args[args.indexOf('--base-href') + 1];
      await writeFile(path.join(dir, 'index.html'), `<base href="${base}">hello preview`);
      await writeFile(path.join(dir, 'main.dart.js'), 'console.log(1)');
      return 0;
    }
    if (args[0] === 'sleep') {
      await new Promise<void>((r) => {
        const t = setTimeout(r, 10_000);
        opts.signal.addEventListener('abort', () => (clearTimeout(t), r()));
      });
      return opts.signal.aborted ? 130 : 0;
    }
    if (cmd === 'flutter' && args[0] === 'create') {
      const dir = path.join(this.hostRoot(id), opts.cwd, args.at(-1)!);
      await mkdir(path.join(dir, 'lib'), { recursive: true });
      await writeFile(path.join(dir, 'lib', 'main.dart'), 'void main() {}\n');
      await writeFile(path.join(dir, 'pubspec.yaml'), `name: ${args.at(-1)}\n`);
      await mkdir(path.join(dir, '.dart_tool'), { recursive: true });
      opts.onStdout('All done!\n');
      return 0;
    }
    opts.onStderr('unknown command\n');
    return 1;
  }
}

describe('paths', () => {
  it('normalizes and confines', () => {
    expect(normalizeRel('/lib//./a/../main.dart')).toBe('lib/main.dart');
    expect(() => normalizeRel('../x')).toThrow();
    expect(() => normalizeRel('C:/Windows')).toThrow();
    expect(() => normalizeRel(42)).toThrow();
    const root = path.resolve('/tmp/proj');
    expect(safeResolve(root, 'lib/a.dart')).toBe(path.join(root, 'lib', 'a.dart'));
    expect(() => safeResolve(root, 'lib/../../other')).toThrow();
  });

  it('validates project names', () => {
    expect(validateProjectName('my_app')).toBe('my_app');
    for (const bad of ['MyApp', '1app', 'my-app', 'flutter', '', 'a'.repeat(65)]) {
      expect(() => validateProjectName(bad)).toThrow();
    }
  });
});

describe('ProjectFs', () => {
  let root: string;
  beforeAll(async () => {
    root = await mkdtemp(path.join(os.tmpdir(), 'fc-fs-'));
  });
  afterAll(() => rm(root, { recursive: true, force: true }));

  it('write/read/list/rename/delete with conflict detection', async () => {
    const fs = new ProjectFs(root, 1024);
    const w = await fs.write('lib/a.dart', 'x');
    expect((await fs.read('lib/a.dart')).content).toBe('x');
    await expect(fs.write('lib/a.dart', 'y', w.mtimeMs - 10_000)).rejects.toMatchObject({ code: 'conflict' });
    await fs.write('lib/a.dart', 'y', w.mtimeMs);
    await mkdir(path.join(root, 'build'));
    const top = await fs.list('');
    expect(top.map((e) => e.name)).toEqual(['lib']);
    await fs.rename('lib/a.dart', 'lib/b.dart');
    await expect(fs.read('lib/a.dart')).rejects.toMatchObject({ code: 'not_found' });
    await expect(fs.write('big.txt', 'z'.repeat(2000))).rejects.toMatchObject({ code: 'too_large' });
    await writeFile(path.join(root, 'bin.dat'), Buffer.from([1, 0, 2]));
    await expect(fs.read('bin.dat')).rejects.toMatchObject({ code: 'binary' });
    await expect(fs.delete('')).rejects.toThrow();
    await fs.delete('lib');
    await expect(fs.list('lib')).rejects.toMatchObject({ code: 'not_found' });
  });
});

describe('JobManager', () => {
  it('runs serially per workspace and cancels', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'fc-jobs-'));
    const jm = new JobManager(new FakeDriver(root), 60);
    const base = { ownerId: 'u', workspaceId: 'w', projectId: null, cwd: '' } as const;
    const long = jm.enqueue({ ...base, kind: 'test', cmd: 'flutter', args: ['sleep'] });
    const next = jm.enqueue({ ...base, kind: 'analyze', cmd: 'nope', args: [] });
    await new Promise((r) => setTimeout(r, 20));
    expect(long.status).toBe('running');
    expect(next.status).toBe('queued');
    jm.cancel(long.id);
    expect((await jm.wait(long.id)).status).toBe('cancelled');
    const done = await jm.wait(next.id);
    expect(done.status).toBe('failed');
    expect(done.log.join('')).toContain('unknown command');
    await rm(root, { recursive: true, force: true });
  });
});

describe('Runner API (phase 1 acceptance)', () => {
  let tmp: string;
  let base: string;
  let close: () => Promise<void>;

  beforeAll(async () => {
    tmp = await mkdtemp(path.join(os.tmpdir(), 'fc-app-'));
    const cfg = loadConfig({ DEV_AUTH: 'true', DATA_DIR: tmp, WORKSPACES_ROOT: path.join(tmp, 'ws'), LOG_LEVEL: 'silent' });
    const { app } = await buildApp(cfg, { driver: new FakeDriver(path.join(tmp, 'ws')) });
    await app.listen({ port: 0, host: '127.0.0.1' });
    base = `127.0.0.1:${(app.server.address() as AddressInfo).port}`;
    close = () => app.close();
  });
  afterAll(async () => {
    await close();
    await rm(tmp, { recursive: true, force: true });
  });

  const http = async (method: string, url: string, token?: string, body?: unknown) => {
    const res = await fetch(`http://${base}${url}`, {
      method,
      headers: { ...(token ? { authorization: `Bearer ${token}` } : {}), ...(body ? { 'content-type': 'application/json' } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    return { status: res.status, json: res.status === 204 ? null : ((await res.json()) as any) };
  };

  it('login → workspace → create project → edit file over WS → persists', async () => {
    expect((await http('GET', '/v1/workspaces')).status).toBe(401);
    const { json: login } = await http('POST', '/v1/auth/dev-login', undefined, { email: 'adnan@example.com' });
    const token = login.token as string;

    const { status, json: ws } = await http('POST', '/v1/workspaces', token, { name: 'default' });
    expect(status).toBe(201);
    expect(ws.status).toBe('running');

    const { json: created } = await http('POST', `/v1/workspaces/${ws.id}/projects`, token, { name: 'counter' });
    expect(created.project.status).toBe('creating');
    expect((await http('POST', `/v1/workspaces/${ws.id}/projects`, token, { name: 'Bad-Name' })).status).toBe(400);

    let project;
    for (let i = 0; i < 50; i++) {
      project = (await http('GET', `/v1/projects/${created.project.id}`, token)).json;
      if (project.status !== 'creating') break;
      await new Promise((r) => setTimeout(r, 20));
    }
    expect(project.status).toBe('ready');

    // another user cannot see it
    const other = (await http('POST', '/v1/auth/dev-login', undefined, { email: 'x@example.com' })).json.token;
    expect((await http('GET', `/v1/projects/${project.id}`, other)).status).toBe(404);

    const sock = new WebSocket(`ws://${base}/v1/ws?token=${token}`);
    await new Promise((r, j) => (sock.once('open', r), sock.once('error', j)));
    const pending = new Map<string, (f: any) => void>();
    const events: any[] = [];
    sock.on('message', (d) => {
      const f = JSON.parse(d.toString());
      if (f.id && pending.has(f.id)) pending.get(f.id)!(f);
      else events.push(f);
    });
    let n = 0;
    const req = (type: string, payload: object) =>
      new Promise<any>((resolve) => {
        const id = `r${++n}`;
        pending.set(id, resolve);
        sock.send(JSON.stringify({ id, type, payload }));
      });

    const list = await req('fs.list', { projectId: project.id, path: '' });
    expect(list.type).toBe('ok');
    expect(list.payload.entries.map((e: any) => e.name)).toEqual(['lib', 'pubspec.yaml']);

    const read = await req('fs.read', { projectId: project.id, path: 'lib/main.dart' });
    expect(read.payload.content).toBe('void main() {}\n');

    const write = await req('fs.write', { projectId: project.id, path: 'lib/main.dart', content: 'void main() { print(1); }\n', expectedMtimeMs: read.payload.mtimeMs });
    expect(write.type).toBe('ok');

    const escape = await req('fs.read', { projectId: project.id, path: '../../store.json' });
    expect(escape).toMatchObject({ type: 'error', payload: { code: 'bad_path' } });

    const unsupported = await req('agent.run', {});
    expect(unsupported.payload.code).toBe('unsupported');

    // ---- Phase 2: terminal ----
    const waitEvent = (pred: (f: any) => boolean) =>
      new Promise<any>((resolve, reject) => {
        const t0 = Date.now();
        const tick = () => {
          const i = events.findIndex(pred);
          if (i >= 0) return resolve(events.splice(i, 1)[0]);
          if (Date.now() - t0 > 3000) return reject(new Error('event timeout'));
          setTimeout(tick, 10);
        };
        tick();
      });
    const opened = await req('pty.open', { projectId: project.id, cols: 100, rows: 30 });
    const ptyId = opened.payload.ptyId as string;
    expect(ptyId).toBeTruthy();
    await req('pty.input', { ptyId, data: 'ls\r' });
    expect((await waitEvent((f) => f.type === 'pty.output' && f.payload.ptyId === ptyId)).payload.data).toBe('echo:ls\r');
    await req('pty.resize', { ptyId, cols: 9999, rows: 1 });
    expect((await waitEvent((f) => f.type === 'pty.output')).payload.data).toBe('size:500x2');
    await req('pty.input', { ptyId, data: 'exit\r' });
    expect((await waitEvent((f) => f.type === 'pty.exit')).payload).toEqual({ ptyId, exitCode: 0 });
    expect((await req('pty.input', { ptyId, data: 'x' })).payload.code).toBe('not_found');

    // ---- Phase 2: web preview ----
    const notBuilt = await fetch(`http://${base}/preview/${ws.id}/${project.id}/`);
    expect(notBuilt.status).toBe(404);
    const started = await req('preview.start', { projectId: project.id, autoRebuild: true });
    expect(started.payload.preview.path).toBe(`/preview/${ws.id}/${project.id}/`);
    const ready = await waitEvent((f) => f.type === 'preview.ready');
    expect(ready.payload).toMatchObject({ projectId: project.id, built: true, autoRebuild: true });
    const page = await fetch(`http://${base}/preview/${ws.id}/${project.id}/`);
    expect(page.status).toBe(200);
    expect(page.headers.get('cache-control')).toContain('no-cache');
    expect(await page.text()).toContain(`<base href="/preview/${ws.id}/${project.id}/">`);
    const spa = await fetch(`http://${base}/preview/${ws.id}/${project.id}/some/route`);
    expect(await spa.text()).toContain('hello preview');
    expect((await fetch(`http://${base}/preview/${ws.id}/${project.id}/missing.js`)).status).toBe(404);
    expect((await fetch(`http://${base}/preview/${ws.id}/nope/`)).status).toBe(404);
    expect((await fetch(`http://${base}/preview/${ws.id}/${project.id}/..%2F..%2Fstore.json`)).status).toBeGreaterThanOrEqual(400);
    const previewStatus = await req('preview.status', { projectId: project.id });
    expect(previewStatus.payload.built).toBe(true);
    await req('preview.stop', { projectId: project.id });
    sock.close();

    // "persists after refresh": a brand-new connection sees the saved content
    const sock2 = new WebSocket(`ws://${base}/v1/ws?token=${token}`);
    await new Promise((r) => sock2.once('open', r));
    const reread = await new Promise<any>((resolve) => {
      sock2.on('message', (d) => resolve(JSON.parse(d.toString())));
      sock2.send(JSON.stringify({ id: 'x', type: 'fs.read', payload: { projectId: project.id, path: 'lib/main.dart' } }));
    });
    expect(reread.payload.content).toBe('void main() { print(1); }\n');
    sock2.close();

    const bad = new WebSocket(`ws://${base}/v1/ws?token=nope`);
    const code = await new Promise((r) => bad.on('close', (c) => r(c)));
    expect(code).toBe(4401);
  });
});
