import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { Config } from './config.js';

export interface WorkspaceRow {
  id: string;
  ownerId: string;
  name: string;
  status: 'stopped' | 'starting' | 'running' | 'error';
  containerId: string | null;
  createdAt: string;
  lastActiveAt: string;
}

export interface ProjectRow {
  id: string;
  workspaceId: string;
  name: string;
  template: string;
  status: 'creating' | 'ready' | 'error';
  lastModel: string | null;
  createdAt: string;
}

/** Persistence for workspaces and projects (§5C). */
export interface Store {
  listWorkspaces(ownerId: string): Promise<WorkspaceRow[]>;
  getWorkspace(id: string): Promise<WorkspaceRow | null>;
  insertWorkspace(row: WorkspaceRow): Promise<void>;
  updateWorkspace(id: string, patch: Partial<WorkspaceRow>): Promise<void>;
  listProjects(workspaceId: string): Promise<ProjectRow[]>;
  getProject(id: string): Promise<ProjectRow | null>;
  insertProject(row: ProjectRow): Promise<void>;
  updateProject(id: string, patch: Partial<ProjectRow>): Promise<void>;
  deleteProject(id: string): Promise<void>;
}

interface JsonData {
  workspaces: WorkspaceRow[];
  projects: ProjectRow[];
}

/** File-backed store for local development (no Supabase). Writes are atomic and serialized. */
export class JsonStore implements Store {
  private data: JsonData | null = null;
  private chain: Promise<void> = Promise.resolve();
  private readonly file: string;

  constructor(dataDir: string) {
    this.file = path.resolve(dataDir, 'store.json');
  }

  private async load(): Promise<JsonData> {
    if (this.data) return this.data;
    try {
      this.data = JSON.parse(await readFile(this.file, 'utf8')) as JsonData;
    } catch (e) {
      if ((e as NodeJS.ErrnoException).code !== 'ENOENT') throw e;
      this.data = { workspaces: [], projects: [] };
    }
    return this.data;
  }

  private mutate(fn: (d: JsonData) => void): Promise<void> {
    const next = this.chain.then(async () => {
      const d = await this.load();
      fn(d);
      await mkdir(path.dirname(this.file), { recursive: true });
      const tmp = `${this.file}.tmp`;
      await writeFile(tmp, JSON.stringify(d, null, 2));
      await rename(tmp, this.file);
    });
    this.chain = next.catch(() => undefined);
    return next;
  }

  async listWorkspaces(ownerId: string) {
    return (await this.load()).workspaces.filter((w) => w.ownerId === ownerId);
  }
  async getWorkspace(id: string) {
    return (await this.load()).workspaces.find((w) => w.id === id) ?? null;
  }
  insertWorkspace(row: WorkspaceRow) {
    return this.mutate((d) => void d.workspaces.push(row));
  }
  updateWorkspace(id: string, patch: Partial<WorkspaceRow>) {
    return this.mutate((d) => {
      const w = d.workspaces.find((x) => x.id === id);
      if (w) Object.assign(w, patch);
    });
  }
  async listProjects(workspaceId: string) {
    return (await this.load()).projects.filter((p) => p.workspaceId === workspaceId);
  }
  async getProject(id: string) {
    return (await this.load()).projects.find((p) => p.id === id) ?? null;
  }
  insertProject(row: ProjectRow) {
    return this.mutate((d) => void d.projects.push(row));
  }
  updateProject(id: string, patch: Partial<ProjectRow>) {
    return this.mutate((d) => {
      const p = d.projects.find((x) => x.id === id);
      if (p) Object.assign(p, patch);
    });
  }
  deleteProject(id: string) {
    return this.mutate((d) => {
      d.projects = d.projects.filter((p) => p.id !== id);
    });
  }
}

const wsToDb = (r: Partial<WorkspaceRow>) =>
  strip({
    id: r.id,
    owner_id: r.ownerId,
    name: r.name,
    status: r.status,
    container_id: r.containerId,
    created_at: r.createdAt,
    last_active_at: r.lastActiveAt,
  });
const wsFromDb = (r: Record<string, unknown>): WorkspaceRow => ({
  id: r.id as string,
  ownerId: r.owner_id as string,
  name: r.name as string,
  status: r.status as WorkspaceRow['status'],
  containerId: (r.container_id as string | null) ?? null,
  createdAt: r.created_at as string,
  lastActiveAt: r.last_active_at as string,
});
const prToDb = (r: Partial<ProjectRow>) =>
  strip({
    id: r.id,
    workspace_id: r.workspaceId,
    name: r.name,
    template: r.template,
    status: r.status,
    last_model: r.lastModel,
    created_at: r.createdAt,
  });
const prFromDb = (r: Record<string, unknown>): ProjectRow => ({
  id: r.id as string,
  workspaceId: r.workspace_id as string,
  name: r.name as string,
  template: r.template as string,
  status: r.status as ProjectRow['status'],
  lastModel: (r.last_model as string | null) ?? null,
  createdAt: r.created_at as string,
});

function strip<T extends Record<string, unknown>>(o: T): Partial<T> {
  return Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined)) as Partial<T>;
}

/** Supabase Postgres store (schema in infra/supabase/migrations). Uses the service role; ownership is enforced by the Runner. */
export class SupabaseStore implements Store {
  private readonly db: SupabaseClient;

  constructor(cfg: Config) {
    this.db = createClient(cfg.SUPABASE_URL, cfg.SUPABASE_SERVICE_ROLE_KEY, { auth: { persistSession: false } });
  }

  private static check<T>(res: { data: T; error: { message: string } | null }): T {
    if (res.error) throw new Error(`supabase: ${res.error.message}`);
    return res.data;
  }

  async listWorkspaces(ownerId: string) {
    const rows = SupabaseStore.check(await this.db.from('workspaces').select('*').eq('owner_id', ownerId).order('created_at'));
    return (rows ?? []).map(wsFromDb);
  }
  async getWorkspace(id: string) {
    const row = SupabaseStore.check(await this.db.from('workspaces').select('*').eq('id', id).maybeSingle());
    return row ? wsFromDb(row) : null;
  }
  async insertWorkspace(row: WorkspaceRow) {
    SupabaseStore.check(await this.db.from('workspaces').insert(wsToDb(row)));
  }
  async updateWorkspace(id: string, patch: Partial<WorkspaceRow>) {
    SupabaseStore.check(await this.db.from('workspaces').update(wsToDb(patch)).eq('id', id));
  }
  async listProjects(workspaceId: string) {
    const rows = SupabaseStore.check(await this.db.from('projects').select('*').eq('workspace_id', workspaceId).order('created_at'));
    return (rows ?? []).map(prFromDb);
  }
  async getProject(id: string) {
    const row = SupabaseStore.check(await this.db.from('projects').select('*').eq('id', id).maybeSingle());
    return row ? prFromDb(row) : null;
  }
  async insertProject(row: ProjectRow) {
    SupabaseStore.check(await this.db.from('projects').insert(prToDb(row)));
  }
  async updateProject(id: string, patch: Partial<ProjectRow>) {
    SupabaseStore.check(await this.db.from('projects').update(prToDb(patch)).eq('id', id));
  }
  async deleteProject(id: string) {
    SupabaseStore.check(await this.db.from('projects').delete().eq('id', id));
  }
}
