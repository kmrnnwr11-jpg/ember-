import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { PassThrough } from 'node:stream';
import Docker from 'dockerode';
import type { Config } from '../config.js';
import { normalizeRel } from '../paths.js';
import type { ExecOptions, PtyHandle, PtyOptions, WorkspaceDriver } from './driver.js';

const CONTAINER_ROOT = '/workspace';

/** One isolated container per workspace: non-root, CPU/RAM/PID limits, no privilege escalation. */
export class DockerDriver implements WorkspaceDriver {
  readonly kind = 'docker' as const;
  private readonly docker: Docker;

  constructor(private readonly cfg: Config, docker?: Docker) {
    this.docker = docker ?? new Docker();
  }

  hostRoot(workspaceId: string): string {
    return path.resolve(this.cfg.WORKSPACES_ROOT, workspaceId);
  }

  private name(workspaceId: string) {
    return `fc-ws-${workspaceId}`;
  }

  async ensure(workspaceId: string) {
    await mkdir(this.hostRoot(workspaceId), { recursive: true });
    const name = this.name(workspaceId);
    let container = this.docker.getContainer(name);
    try {
      const info = await container.inspect();
      if (!info.State.Running) await container.start();
      return { containerId: info.Id };
    } catch (e) {
      if ((e as { statusCode?: number }).statusCode !== 404) throw e;
    }
    container = await this.docker.createContainer({
      name,
      Image: this.cfg.WORKSPACE_IMAGE,
      Cmd: ['sleep', 'infinity'],
      User: '1000:1000',
      WorkingDir: CONTAINER_ROOT,
      Labels: { 'fluttercursor.workspace': workspaceId },
      HostConfig: {
        Binds: [`${this.hostRoot(workspaceId)}:${CONTAINER_ROOT}`],
        NanoCpus: Math.round(this.cfg.WORKSPACE_CPU * 1e9),
        Memory: this.cfg.WORKSPACE_RAM_MB * 1024 * 1024,
        PidsLimit: 2048,
        SecurityOpt: ['no-new-privileges'],
        CapDrop: ['ALL'],
        NetworkMode: 'fc-workspaces',
        RestartPolicy: { Name: 'unless-stopped' },
      },
    });
    await container.start();
    return { containerId: container.id };
  }

  async stop(workspaceId: string) {
    try {
      await this.docker.getContainer(this.name(workspaceId)).stop({ t: 5 });
    } catch (e) {
      const code = (e as { statusCode?: number }).statusCode;
      if (code !== 404 && code !== 304) throw e;
    }
  }

  async openPty(workspaceId: string, opts: PtyOptions): Promise<PtyHandle> {
    await this.ensure(workspaceId);
    const container = this.docker.getContainer(this.name(workspaceId));
    const rel = normalizeRel(opts.cwd);
    const exec = await container.exec({
      Cmd: ['bash', '-l'],
      WorkingDir: rel ? `${CONTAINER_ROOT}/${rel}` : CONTAINER_ROOT,
      Env: ['TERM=xterm-256color', 'COLORTERM=truecolor'],
      AttachStdin: true,
      AttachStdout: true,
      AttachStderr: true,
      Tty: true,
      User: '1000:1000',
    });
    const stream = await exec.start({ hijack: true, stdin: true, Tty: true });
    await exec.resize({ h: opts.rows, w: opts.cols }).catch(() => undefined);
    const exitCbs: Array<(code: number) => void> = [];
    let exited = false;
    const fireExit = () => {
      if (exited) return;
      exited = true;
      void exec.inspect().then(
        (i) => exitCbs.forEach((cb) => cb(i.ExitCode ?? 0)),
        () => exitCbs.forEach((cb) => cb(0)),
      );
    };
    stream.on('end', fireExit);
    stream.on('close', fireExit);
    stream.on('error', fireExit);
    return {
      onData: (cb) => void stream.on('data', (b: Buffer) => cb(b.toString('utf8'))),
      onExit: (cb) => void exitCbs.push(cb),
      write: (d) => void stream.write(d),
      resize: (c, r) => void exec.resize({ h: r, w: c }).catch(() => undefined),
      kill: () => {
        // Ctrl-D then close; bash exits and the exec ends.
        stream.write('\x04');
        stream.end();
      },
    };
  }

  async exec(workspaceId: string, cmd: string, args: string[], opts: ExecOptions): Promise<number> {
    await this.ensure(workspaceId);
    const container = this.docker.getContainer(this.name(workspaceId));
    const rel = normalizeRel(opts.cwd);
    const exec = await container.exec({
      Cmd: [cmd, ...args],
      WorkingDir: rel ? `${CONTAINER_ROOT}/${rel}` : CONTAINER_ROOT,
      Env: Object.entries(opts.env ?? {}).map(([k, v]) => `${k}=${v}`),
      AttachStdout: true,
      AttachStderr: true,
      User: '1000:1000',
    });
    const stream = await exec.start({ hijack: true, stdin: false });
    const out = new PassThrough();
    const err = new PassThrough();
    out.setEncoding('utf8').on('data', opts.onStdout);
    err.setEncoding('utf8').on('data', opts.onStderr);
    this.docker.modem.demuxStream(stream, out, err);

    const onAbort = () => {
      // Kill the process tree started by this exec inside the container.
      void exec.inspect().then(async (info) => {
        if (!info.Pid) return;
        const killer = await container.exec({ Cmd: ['pkill', '-TERM', '-P', String(info.Pid)], User: '1000:1000' });
        await killer.start({ Detach: true });
        stream.destroy();
      });
    };
    opts.signal.addEventListener('abort', onAbort, { once: true });

    await new Promise<void>((resolve) => {
      stream.on('end', resolve);
      stream.on('close', resolve);
      stream.on('error', () => resolve());
    });
    opts.signal.removeEventListener('abort', onAbort);
    const info = await exec.inspect();
    return info.ExitCode ?? (opts.signal.aborted ? 130 : 1);
  }
}
