import { spawn } from 'node:child_process';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import type { Config } from '../config.js';
import { safeResolve } from '../paths.js';
import type { ExecOptions, WorkspaceDriver } from './driver.js';

/** Host-process driver. No isolation: use only for local development. */
export class LocalDriver implements WorkspaceDriver {
  readonly kind = 'local' as const;

  constructor(private readonly cfg: Config) {}

  hostRoot(workspaceId: string): string {
    return path.resolve(this.cfg.WORKSPACES_ROOT, workspaceId);
  }

  async ensure(workspaceId: string) {
    await mkdir(this.hostRoot(workspaceId), { recursive: true });
    return { containerId: null };
  }

  async stop(): Promise<void> {
    // Nothing to stop: processes are tied to their jobs.
  }

  exec(workspaceId: string, cmd: string, args: string[], opts: ExecOptions): Promise<number> {
    const bin = cmd === 'flutter' ? this.cfg.FLUTTER_BIN : cmd;
    const cwd = safeResolve(this.hostRoot(workspaceId), opts.cwd);
    return new Promise((resolve, reject) => {
      const child = spawn(bin, args, {
        cwd,
        env: { ...process.env, ...opts.env },
        // .bat/.cmd files need a shell on Windows; args are validated by callers.
        shell: process.platform === 'win32' && /\.(bat|cmd)$/i.test(bin),
        windowsHide: true,
      });
      const kill = () => {
        if (process.platform === 'win32' && child.pid) {
          spawn('taskkill', ['/pid', String(child.pid), '/T', '/F'], { windowsHide: true });
        } else {
          child.kill('SIGTERM');
        }
      };
      if (opts.signal.aborted) kill();
      opts.signal.addEventListener('abort', kill, { once: true });
      child.stdout.setEncoding('utf8').on('data', opts.onStdout);
      child.stderr.setEncoding('utf8').on('data', opts.onStderr);
      child.on('error', reject);
      child.on('close', (code) => {
        opts.signal.removeEventListener('abort', kill);
        resolve(code ?? (opts.signal.aborted ? 130 : 1));
      });
    });
  }
}
