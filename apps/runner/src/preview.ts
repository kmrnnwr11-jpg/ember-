import { EventEmitter } from 'node:events';
import { pinProjectSdk } from './sdk_pins.js';
import { stat } from 'node:fs/promises';
import path from 'node:path';
import type { Config } from './config.js';
import type { FsChange, WatchHub } from './fs.js';
import type { Job } from './jobs.js';
import type { Services } from './services.js';
import type { ProjectRow } from './store.js';

/** Paths whose change triggers a web rebuild. */
const REBUILD_RE = /^(lib|web|assets|packages)\/|^pubspec\.(yaml|lock)$|^l10n\.yaml$/;
const DEBOUNCE_MS = 1500;

export interface PreviewInfo {
  projectId: string;
  /** Absolute URL when PREVIEW_BASE_DOMAIN is set, otherwise null. */
  url: string | null;
  /** Path on the Runner host (client prefixes its Runner URL when url is null). */
  path: string;
  built: boolean;
  builtAt: string | null;
  autoRebuild: boolean;
  building: boolean;
}

interface Live {
  ownerId: string;
  release: () => void;
  timer: NodeJS.Timeout | null;
}

export interface PreviewEvents {
  ready: [ownerId: string, info: PreviewInfo];
  failed: [ownerId: string, projectId: string, jobId: string];
  building: [ownerId: string, projectId: string, jobId: string];
}

/**
 * Web preview per project (§2): `flutter build web` with the right base href,
 * served statically; optional rebuild-on-save via the shared watcher.
 */
export class PreviewService extends EventEmitter<PreviewEvents> {
  private readonly live = new Map<string, Live>();

  constructor(
    private readonly cfg: Config,
    private readonly services: Services,
    private readonly hub: WatchHub,
  ) {
    super();
    this.hub.on('change', (c) => this.onChange(c));
    services.jobs.on('status', (job) => void this.onJob(job));
  }

  basePath(p: Pick<ProjectRow, 'workspaceId' | 'id'>): string {
    return this.cfg.PREVIEW_BASE_DOMAIN ? `/${p.workspaceId}/${p.id}/` : `/preview/${p.workspaceId}/${p.id}/`;
  }

  webRoot(project: ProjectRow): string {
    return path.join(this.services.projectRoot(project), 'build', 'web');
  }

  async info(project: ProjectRow): Promise<PreviewInfo> {
    const index = await stat(path.join(this.webRoot(project), 'index.html')).catch(() => null);
    const building = !!this.services.jobs.findActive((j) => j.projectId === project.id && j.kind === 'build_web');
    const base = this.basePath(project);
    return {
      projectId: project.id,
      url: this.cfg.PREVIEW_BASE_DOMAIN ? `https://preview.${this.cfg.PREVIEW_BASE_DOMAIN}${base}` : null,
      path: `/preview/${project.workspaceId}/${project.id}/`,
      built: !!index,
      builtAt: index ? index.mtime.toISOString() : null,
      autoRebuild: this.live.has(project.id),
      building,
    };
  }

  /** Builds now (deduplicated) and optionally keeps rebuilding on changes. */
  async start(ownerId: string, projectId: string, autoRebuild: boolean): Promise<{ job: Job; info: PreviewInfo }> {
    const { fs, project } = await this.services.projectFs(ownerId, projectId);
    await pinProjectSdk(fs.root);
    if (autoRebuild && !this.live.has(projectId)) {
      this.live.set(projectId, { ownerId, release: this.hub.acquire(projectId, fs.root), timer: null });
    } else if (!autoRebuild) {
      this.stop(projectId);
    }
    const job = this.build(ownerId, project);
    return { job, info: await this.info(project) };
  }

  stop(projectId: string) {
    const l = this.live.get(projectId);
    if (!l) return;
    if (l.timer) clearTimeout(l.timer);
    l.release();
    this.live.delete(projectId);
  }

  stopAll() {
    for (const id of [...this.live.keys()]) this.stop(id);
  }

  private build(ownerId: string, project: ProjectRow): Job {
    const existing = this.services.jobs.findActive(
      (j) => j.projectId === project.id && j.kind === 'build_web' && j.status === 'queued',
    );
    if (existing) return existing;
    const job = this.services.jobs.enqueue({
      kind: 'build_web',
      ownerId,
      workspaceId: project.workspaceId,
      projectId: project.id,
      cwd: `projects/${project.name}`,
      cmd: 'flutter',
      // The preview is for looking at the app, not for shipping it: light
      // optimisation and no source maps cut the wait roughly in half, and the
      // published build is a different job that keeps every optimisation.
      args: [
        'build',
        'web',
        '--release',
        '--base-href',
        this.basePath(project),
        '--no-wasm-dry-run',
        '--no-source-maps',
        '--dart2js-optimization',
        'O1',
        '--no-tree-shake-icons',
      ],
    });
    this.emit('building', ownerId, project.id, job.id);
    return job;
  }

  private onChange(c: FsChange) {
    const l = this.live.get(c.projectId);
    if (!l || !REBUILD_RE.test(c.path)) return;
    if (l.timer) clearTimeout(l.timer);
    l.timer = setTimeout(() => {
      l.timer = null;
      void this.services.store.getProject(c.projectId).then((p) => {
        if (p && p.status === 'ready') this.build(l.ownerId, p);
      });
    }, DEBOUNCE_MS);
  }

  private async onJob(job: Job) {
    if (job.kind !== 'build_web' || !job.projectId) return;
    if (job.status === 'succeeded') {
      const project = await this.services.store.getProject(job.projectId);
      if (project) this.emit('ready', job.ownerId, await this.info(project));
    } else if (job.status === 'failed') {
      this.emit('failed', job.ownerId, job.projectId, job.id);
    }
  }
}
