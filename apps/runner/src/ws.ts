import type { FastifyBaseLogger } from 'fastify';
import type { WebSocket } from 'ws';
import type { AuthUser } from './auth.js';
import type { FsChange, WatchHub } from './fs.js';
import { jobPublic, type Job } from './jobs.js';
import type { Services } from './services.js';
import { errorPayload } from './errors.js';

interface Frame {
  id?: string;
  type: string;
  payload: Record<string, unknown>;
}

const HEARTBEAT_MS = 20_000;
const RATE_WINDOW_MS = 10_000;
const RATE_MAX = 400;

const str = (v: unknown, field: string): string => {
  if (typeof v !== 'string') throw Object.assign(new Error(`payload.${field} must be a string`), { code: 'bad_request' });
  return v;
};

/** One authenticated IDE connection. Protocol: docs/API.md §WebSocket. */
export class Session {
  private readonly watches = new Map<string, () => void>();
  private alive = true;
  private windowStart = Date.now();
  private windowCount = 0;
  private readonly heartbeat: NodeJS.Timeout;
  private readonly onFsChange = (c: FsChange) => {
    if (this.watches.has(c.projectId)) this.send({ type: 'fs.changed', payload: { ...c } });
  };
  private readonly onJobStatus = (job: Job) => {
    if (job.ownerId === this.user.id) this.send({ type: 'job.status', payload: jobPublic(job) });
  };
  private readonly onJobLog = (job: Job, stream: 'stdout' | 'stderr', chunk: string) => {
    if (job.ownerId === this.user.id) this.send({ type: 'job.log', payload: { jobId: job.id, stream, chunk } });
  };

  constructor(
    private readonly socket: WebSocket,
    private readonly user: AuthUser,
    private readonly services: Services,
    private readonly hub: WatchHub,
    private readonly log: FastifyBaseLogger,
  ) {
    hub.on('change', this.onFsChange);
    services.jobs.on('status', this.onJobStatus);
    services.jobs.on('log', this.onJobLog);
    socket.on('message', (data) => void this.onMessage(data.toString()));
    socket.on('pong', () => (this.alive = true));
    socket.on('close', () => this.dispose());
    socket.on('error', () => this.dispose());
    this.heartbeat = setInterval(() => {
      if (!this.alive) return socket.terminate();
      this.alive = false;
      socket.ping();
    }, HEARTBEAT_MS);
  }

  private send(frame: Frame) {
    if (this.socket.readyState === this.socket.OPEN) this.socket.send(JSON.stringify(frame));
  }

  private dispose() {
    clearInterval(this.heartbeat);
    this.hub.off('change', this.onFsChange);
    this.services.jobs.off('status', this.onJobStatus);
    this.services.jobs.off('log', this.onJobLog);
    for (const release of this.watches.values()) release();
    this.watches.clear();
  }

  private rateLimited(): boolean {
    const now = Date.now();
    if (now - this.windowStart > RATE_WINDOW_MS) {
      this.windowStart = now;
      this.windowCount = 0;
    }
    return ++this.windowCount > RATE_MAX;
  }

  private async onMessage(raw: string) {
    let frame: Frame;
    try {
      const parsed = JSON.parse(raw) as Partial<Frame>;
      if (typeof parsed.type !== 'string') throw new Error('missing type');
      frame = { id: typeof parsed.id === 'string' ? parsed.id : undefined, type: parsed.type, payload: (parsed.payload as Record<string, unknown>) ?? {} };
    } catch {
      return this.send({ type: 'error', payload: { code: 'bad_frame', message: 'invalid JSON frame' } });
    }
    if (this.rateLimited()) {
      return this.send({ id: frame.id, type: 'error', payload: { code: 'rate_limited', message: 'too many messages' } });
    }
    try {
      const result = await this.dispatch(frame);
      if (frame.id !== undefined) this.send({ id: frame.id, type: 'ok', payload: result ?? {} });
    } catch (e) {
      const payload = errorPayload(e);
      if (payload.code === 'internal') this.log.error({ err: e, type: frame.type }, 'ws handler failed');
      this.send({ id: frame.id, type: 'error', payload });
    }
  }

  private async dispatch({ type, payload: p }: Frame): Promise<Record<string, unknown> | void> {
    const uid = this.user.id;
    switch (type) {
      case 'ping':
        this.send({ type: 'pong', payload: {} });
        return;
      case 'fs.list': {
        const { fs } = await this.services.projectFs(uid, str(p.projectId, 'projectId'));
        return { entries: await fs.list(typeof p.path === 'string' ? p.path : '') };
      }
      case 'fs.read': {
        const { fs } = await this.services.projectFs(uid, str(p.projectId, 'projectId'));
        return await fs.read(str(p.path, 'path'));
      }
      case 'fs.write': {
        const { fs } = await this.services.projectFs(uid, str(p.projectId, 'projectId'));
        const expected = typeof p.expectedMtimeMs === 'number' ? p.expectedMtimeMs : undefined;
        return await fs.write(str(p.path, 'path'), str(p.content, 'content'), expected);
      }
      case 'fs.mkdir': {
        const { fs } = await this.services.projectFs(uid, str(p.projectId, 'projectId'));
        await fs.mkdir(str(p.path, 'path'));
        return;
      }
      case 'fs.rename': {
        const { fs } = await this.services.projectFs(uid, str(p.projectId, 'projectId'));
        await fs.rename(str(p.from, 'from'), str(p.to, 'to'));
        return;
      }
      case 'fs.delete': {
        const { fs } = await this.services.projectFs(uid, str(p.projectId, 'projectId'));
        await fs.delete(str(p.path, 'path'));
        return;
      }
      case 'fs.watch': {
        const projectId = str(p.projectId, 'projectId');
        const { fs } = await this.services.projectFs(uid, projectId);
        if (p.enabled === false) {
          this.watches.get(projectId)?.();
          this.watches.delete(projectId);
        } else if (!this.watches.has(projectId)) {
          this.watches.set(projectId, this.hub.acquire(projectId, fs.root));
        }
        return { watching: this.watches.has(projectId) };
      }
      case 'job.start': {
        const job = await this.services.startJob(uid, str(p.projectId, 'projectId'), p.kind);
        return jobPublic(job);
      }
      case 'job.cancel': {
        const job = this.services.ownedJob(uid, str(p.jobId, 'jobId'));
        return { cancelled: this.services.jobs.cancel(job.id) };
      }
      default:
        throw Object.assign(new Error(`unsupported message type: ${type}`), { code: 'unsupported' });
    }
  }
}
