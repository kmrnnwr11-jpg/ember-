import type { FastifyBaseLogger } from 'fastify';
import { CLI_ENGINES, safeModel, type CliEngine } from './subscription_clis.js';
import type { WebSocket } from 'ws';
import type { AuthUser } from './auth.js';
import type { FsChange, WatchHub } from './fs.js';
import type { AgentEvent, AgentRun, ClaudeCodeEngine } from './agent_cli.js';
import { jobPublic, type Job } from './jobs.js';
import type { PreviewInfo, PreviewService } from './preview.js';
import { PtySessions } from './pty.js';
import type { PtyHandle, ShellKind } from './workspaces/driver.js';
import type { Services } from './services.js';
import { errorPayload } from './errors.js';

interface Frame {
  id?: string;
  type: string;
  payload: Record<string, unknown>;
}

const HEARTBEAT_MS = 20_000;
const RATE_WINDOW_MS = 10_000;
// Terminal keystrokes are one frame each, so allow bursts of fast typing/pasting.
const RATE_MAX = 3000;

const str = (v: unknown, field: string): string => {
  if (typeof v !== 'string') throw Object.assign(new Error(`payload.${field} must be a string`), { code: 'bad_request' });
  return v;
};

const dim = (v: unknown, fallback: number): number =>
  typeof v === 'number' && Number.isFinite(v) ? Math.max(2, Math.min(500, Math.floor(v))) : fallback;

/**
 * Types [command] once the shell shows its prompt (cmd `>`, PowerShell `PS …>`,
 * bash `$`/`#`). Writing too early gets mangled by ConPTY, and Enter must be a
 * separate write or PowerShell treats the line as incomplete. Falls back after 5 s.
 */
export function typeWhenPromptReady(handle: PtyHandle, command: string, fallbackMs = 5000) {
  let buf = '';
  let sent = false;
  const send = () => {
    if (sent) return;
    sent = true;
    clearTimeout(timer);
    handle.write(command);
    setTimeout(() => handle.write('\r'), 150);
  };
  const timer = setTimeout(send, fallbackMs);
  handle.onData((d) => {
    if (sent) return;
    buf = (buf + d).slice(-400);
    const plain = buf.replace(/\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07/g, '');
    if (/[>$#]\s*$/.test(plain)) send();
  });
}

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
  private readonly onPreviewReady = (ownerId: string, info: PreviewInfo) => {
    if (ownerId === this.user.id) this.send({ type: 'preview.ready', payload: { ...info } });
  };
  private readonly onPreviewBuilding = (ownerId: string, projectId: string, jobId: string) => {
    if (ownerId === this.user.id) this.send({ type: 'preview.building', payload: { projectId, jobId } });
  };
  private readonly onPreviewFailed = (ownerId: string, projectId: string, jobId: string) => {
    if (ownerId === this.user.id) this.send({ type: 'preview.failed', payload: { projectId, jobId } });
  };
  private readonly onAgentEvent = (run: AgentRun, event: AgentEvent) => {
    if (run.ownerId === this.user.id) {
      this.send({ type: 'agent.event', payload: { runId: run.id, projectId: run.projectId, event: { ...event } } });
    }
  };
  private readonly onAgentStatus = (run: AgentRun) => {
    if (run.ownerId === this.user.id) this.send({ type: 'agent.status', payload: { ...run, events: undefined } });
  };
  private readonly ptys = new PtySessions(
    (ptyId, data) => this.send({ type: 'pty.output', payload: { ptyId, data } }),
    (ptyId, exitCode) => this.send({ type: 'pty.exit', payload: { ptyId, exitCode } }),
  );

  constructor(
    private readonly socket: WebSocket,
    private readonly user: AuthUser,
    private readonly services: Services,
    private readonly hub: WatchHub,
    private readonly preview: PreviewService,
    private readonly claudeCode: ClaudeCodeEngine,
    private readonly log: FastifyBaseLogger,
  ) {
    claudeCode.on('event', this.onAgentEvent);
    claudeCode.on('status', this.onAgentStatus);
    hub.on('change', this.onFsChange);
    services.jobs.on('status', this.onJobStatus);
    services.jobs.on('log', this.onJobLog);
    preview.on('ready', this.onPreviewReady);
    preview.on('building', this.onPreviewBuilding);
    preview.on('failed', this.onPreviewFailed);
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
    this.preview.off('ready', this.onPreviewReady);
    this.preview.off('building', this.onPreviewBuilding);
    this.preview.off('failed', this.onPreviewFailed);
    this.claudeCode.off('event', this.onAgentEvent);
    this.claudeCode.off('status', this.onAgentStatus);
    this.ptys.closeAll();
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
      case 'pty.open': {
        const { project } = await this.services.projectFs(uid, str(p.projectId, 'projectId'));
        const shell = ['cmd', 'powershell', 'bash'].includes(p.shell as string) ? (p.shell as ShellKind) : 'default';
        const command = typeof p.command === 'string' ? p.command.trim() : '';
        if (command && !/^[\w .:/=-]{1,200}$/.test(command)) {
          throw Object.assign(new Error('invalid start command'), { code: 'bad_request' });
        }
        const handle = await this.services.driver.openPty(project.workspaceId, {
          cwd: `projects/${project.name}`,
          cols: dim(p.cols, 80),
          rows: dim(p.rows, 24),
          shell,
        });
        const ptyId = this.ptys.add(project.id, handle);
        // Optional start command (e.g. `claude`, `codex`, `gemini`), typed as if by the user.
        if (command) typeWhenPromptReady(handle, command);
        return { ptyId };
      }
      case 'pty.input': {
        const e = this.ptys.get(str(p.ptyId, 'ptyId'));
        if (!e) throw Object.assign(new Error('terminal not found'), { code: 'not_found' });
        e.handle.write(str(p.data, 'data'));
        return;
      }
      case 'pty.resize': {
        const e = this.ptys.get(str(p.ptyId, 'ptyId'));
        if (!e) throw Object.assign(new Error('terminal not found'), { code: 'not_found' });
        e.handle.resize(dim(p.cols, 80), dim(p.rows, 24));
        return;
      }
      case 'pty.close':
        return { closed: this.ptys.close(str(p.ptyId, 'ptyId')) };
      case 'preview.start': {
        const { job, info } = await this.preview.start(uid, str(p.projectId, 'projectId'), p.autoRebuild !== false);
        return { job: jobPublic(job), preview: { ...info } };
      }
      case 'preview.reload': {
        const { job, info } = await this.preview.start(uid, str(p.projectId, 'projectId'), p.autoRebuild !== false);
        return { job: jobPublic(job), preview: { ...info } };
      }
      case 'preview.stop': {
        const { project } = await this.services.ownedProject(uid, str(p.projectId, 'projectId'));
        this.preview.stop(project.id);
        return;
      }
      case 'preview.status': {
        const { project } = await this.services.ownedProject(uid, str(p.projectId, 'projectId'));
        return { ...(await this.preview.info(project)) };
      }
      case 'agent.start': {
        const engine = p.engine as CliEngine;
        if (!CLI_ENGINES.includes(engine)) throw Object.assign(new Error('unsupported engine'), { code: 'bad_request' });
        if (!(await this.claudeCode.isEngineAvailable(engine))) {
          throw Object.assign(new Error(`${engine} is not connected on this Runner: log in to it on the Runner machine`), { code: 'unsupported' });
        }
        const { fs, project } = await this.services.projectFs(uid, str(p.projectId, 'projectId'));
        const prompt = str(p.prompt, 'prompt');
        // Sent via stdin: long requests (reference app listing + design brief + Android info) are fine.
        if (!prompt.trim() || prompt.length > 200_000) throw Object.assign(new Error('prompt must be 1-200000 characters'), { code: 'bad_request' });
        if (this.claudeCode.activeFor(project.id)) throw Object.assign(new Error('an agent is already running on this project'), { code: 'bad_request' });
        const run = this.claudeCode.start({
          ownerId: uid,
          projectId: project.id,
          cwd: fs.root,
          prompt,
          resume: p.resume === true,
          quality: p.quality === 'best' ? 'best' : 'fast',
          engine,
          model: safeModel(p.model),
        });
        return { ...run };
      }
      case 'agent.complete': {
        if (!(await this.claudeCode.isAvailable())) {
          throw Object.assign(new Error('Claude Code is not available on this Runner'), { code: 'unsupported' });
        }
        const prompt = str(p.prompt, 'prompt');
        const system = str(p.system, 'system');
        if (prompt.length > 200_000 || system.length > 50_000) throw Object.assign(new Error('prompt too long'), { code: 'bad_request' });
        return await this.claudeCode.complete({ prompt, system, quality: p.quality === 'best' ? 'best' : 'fast' });
      }
      // Catch-up after a disconnect: status, planned files and recent events of a run.
      case 'agent.get': {
        const run = typeof p.runId === 'string' ? this.claudeCode.get(p.runId) : this.claudeCode.latestFor(str(p.projectId, 'projectId'));
        if (!run || run.ownerId !== uid) return { run: null };
        return { run: { ...run, events: p.withEvents === true ? run.events ?? [] : undefined } };
      }
      case 'job.get': {
        const job = this.services.jobs.get(str(p.jobId, 'jobId'));
        if (!job || job.ownerId !== uid) throw Object.assign(new Error('job not found'), { code: 'not_found' });
        return jobPublic(job);
      }
      case 'agent.cancel': {
        const run = this.claudeCode.get(str(p.runId, 'runId'));
        if (!run || run.ownerId !== uid) throw Object.assign(new Error('run not found'), { code: 'not_found' });
        return { cancelled: this.claudeCode.cancel(run.id) };
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
