import { EventEmitter } from 'node:events';
import { nanoid } from 'nanoid';
import type { WorkspaceDriver } from './workspaces/driver.js';

export type JobKind = 'create' | 'pub_get' | 'analyze' | 'test' | 'build_web' | 'build_apk' | 'build_aab' | 'launcher_icons';
export type JobState = 'queued' | 'running' | 'succeeded' | 'failed' | 'cancelled';

export interface JobSpec {
  kind: JobKind;
  ownerId: string;
  workspaceId: string;
  projectId: string | null;
  cwd: string;
  cmd: string;
  args: string[];
  /** Extra environment (e.g. signing secrets). Never logged or returned to clients. */
  env?: Record<string, string>;
}

export interface Job extends JobSpec {
  id: string;
  status: JobState;
  exitCode: number | null;
  createdAt: string;
  finishedAt: string | null;
  log: string[];
}

export interface JobEvents {
  log: [job: Job, stream: 'stdout' | 'stderr', chunk: string];
  status: [job: Job];
}

const MAX_LOG_CHUNKS = 4000;
const MAX_CONCURRENT_PER_WORKSPACE = 1;

/**
 * In-process job queue: one running job per workspace, FIFO, timeout and
 * cancellation. Logs are kept in a ring buffer so late subscribers can replay.
 */
export class JobManager extends EventEmitter<JobEvents> {
  private readonly jobs = new Map<string, Job>();
  private readonly controllers = new Map<string, AbortController>();
  private readonly running = new Map<string, number>();
  private readonly queue: string[] = [];
  private readonly completion = new Map<string, Promise<Job>>();
  private readonly resolvers = new Map<string, (j: Job) => void>();

  constructor(
    private readonly driver: WorkspaceDriver,
    private readonly timeoutSeconds: number,
  ) {
    super();
  }

  enqueue(spec: JobSpec): Job {
    const job: Job = {
      ...spec,
      id: nanoid(12),
      status: 'queued',
      exitCode: null,
      createdAt: new Date().toISOString(),
      finishedAt: null,
      log: [],
    };
    this.jobs.set(job.id, job);
    this.completion.set(job.id, new Promise((r) => this.resolvers.set(job.id, r)));
    this.queue.push(job.id);
    this.emit('status', job);
    this.pump();
    return job;
  }

  get(id: string): Job | undefined {
    return this.jobs.get(id);
  }

  /** A queued or running job matching [pred], if any. */
  findActive(pred: (job: Job) => boolean): Job | undefined {
    for (const job of this.jobs.values()) {
      if ((job.status === 'queued' || job.status === 'running') && pred(job)) return job;
    }
    return undefined;
  }

  wait(id: string): Promise<Job> {
    const p = this.completion.get(id);
    if (!p) return Promise.reject(new Error(`unknown job ${id}`));
    return p;
  }

  cancel(id: string): boolean {
    const job = this.jobs.get(id);
    if (!job) return false;
    if (job.status === 'queued') {
      this.queue.splice(this.queue.indexOf(id), 1);
      this.finish(job, 'cancelled', null);
      return true;
    }
    if (job.status === 'running') {
      this.controllers.get(id)?.abort();
      return true;
    }
    return false;
  }

  private pump() {
    for (let i = 0; i < this.queue.length; ) {
      const id = this.queue[i]!;
      const job = this.jobs.get(id)!;
      const n = this.running.get(job.workspaceId) ?? 0;
      if (n >= MAX_CONCURRENT_PER_WORKSPACE) {
        i++;
        continue;
      }
      this.queue.splice(i, 1);
      this.running.set(job.workspaceId, n + 1);
      void this.run(job);
    }
  }

  private append(job: Job, stream: 'stdout' | 'stderr', chunk: string) {
    job.log.push(chunk);
    if (job.log.length > MAX_LOG_CHUNKS) job.log.splice(0, job.log.length - MAX_LOG_CHUNKS);
    this.emit('log', job, stream, chunk);
  }

  private async run(job: Job) {
    const ctrl = new AbortController();
    this.controllers.set(job.id, ctrl);
    let timedOut = false;
    const timer = setTimeout(() => {
      timedOut = true;
      ctrl.abort();
    }, this.timeoutSeconds * 1000);
    job.status = 'running';
    this.emit('status', job);
    this.append(job, 'stdout', `$ ${job.cmd} ${job.args.join(' ')}\n`);
    try {
      const code = await this.driver.exec(job.workspaceId, job.cmd, job.args, {
        cwd: job.cwd,
        env: job.env,
        signal: ctrl.signal,
        onStdout: (c) => this.append(job, 'stdout', c),
        onStderr: (c) => this.append(job, 'stderr', c),
      });
      if (timedOut) this.append(job, 'stderr', `\n[runner] timeout after ${this.timeoutSeconds}s\n`);
      const state: JobState = ctrl.signal.aborted ? (timedOut ? 'failed' : 'cancelled') : code === 0 ? 'succeeded' : 'failed';
      this.finish(job, state, code);
    } catch (e) {
      this.append(job, 'stderr', `\n[runner] failed to start: ${(e as Error).message}\n`);
      this.finish(job, 'failed', null);
    } finally {
      clearTimeout(timer);
      this.controllers.delete(job.id);
      this.running.set(job.workspaceId, (this.running.get(job.workspaceId) ?? 1) - 1);
      this.pump();
    }
  }

  private finish(job: Job, status: JobState, exitCode: number | null) {
    job.status = status;
    job.exitCode = exitCode;
    job.finishedAt = new Date().toISOString();
    this.emit('status', job);
    this.resolvers.get(job.id)?.(job);
    this.resolvers.delete(job.id);
  }
}

export function jobPublic(job: Job) {
  return { jobId: job.id, kind: job.kind, status: job.status, exitCode: job.exitCode, projectId: job.projectId };
}
