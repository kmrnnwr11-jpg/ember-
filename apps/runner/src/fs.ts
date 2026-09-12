import { mkdir, readdir, readFile, rename, rm, stat, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { EventEmitter } from 'node:events';
import chokidar, { type FSWatcher } from 'chokidar';
import { PathError, safeResolve, toRel } from './paths.js';

export class FsError extends Error {
  constructor(
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export interface FsEntry {
  path: string;
  name: string;
  isDir: boolean;
  size: number;
}

/** Directories hidden from the tree and ignored by the watcher. */
export const IGNORED_DIRS = new Set(['.dart_tool', 'build', '.git', 'node_modules', '.idea', 'Pods', '.gradle']);

/** Confined file operations on a single project root. */
export class ProjectFs {
  constructor(
    readonly root: string,
    private readonly maxBytes: number,
  ) {}

  async list(dir: string): Promise<FsEntry[]> {
    const abs = safeResolve(this.root, dir);
    let dirents;
    try {
      dirents = await readdir(abs, { withFileTypes: true });
    } catch (e) {
      throw mapErr(e, dir);
    }
    const out: FsEntry[] = [];
    for (const d of dirents) {
      if (d.isDirectory() && IGNORED_DIRS.has(d.name)) continue;
      if (d.isSymbolicLink()) continue; // never follow links out of the project
      const childAbs = path.join(abs, d.name);
      let size = 0;
      if (d.isFile()) {
        try {
          size = (await stat(childAbs)).size;
        } catch {
          continue;
        }
      }
      out.push({ path: toRel(this.root, childAbs), name: d.name, isDir: d.isDirectory(), size });
    }
    out.sort((a, b) => (a.isDir === b.isDir ? a.name.localeCompare(b.name) : a.isDir ? -1 : 1));
    return out;
  }

  async read(file: string): Promise<{ path: string; content: string; mtimeMs: number }> {
    const abs = safeResolve(this.root, file);
    try {
      const st = await stat(abs);
      if (st.isDirectory()) throw new FsError('is_directory', `${file} is a directory`);
      if (st.size > this.maxBytes) throw new FsError('too_large', `${file} exceeds ${this.maxBytes} bytes; use REST download`);
      const buf = await readFile(abs);
      if (buf.subarray(0, 8000).includes(0)) throw new FsError('binary', `${file} is a binary file`);
      return { path: toRel(this.root, abs), content: buf.toString('utf8'), mtimeMs: st.mtimeMs };
    } catch (e) {
      throw mapErr(e, file);
    }
  }

  /**
   * Writes a UTF-8 file, creating parent directories. When [expectedMtimeMs]
   * is given and the file changed on disk since, fails with `conflict`.
   */
  async write(file: string, content: string, expectedMtimeMs?: number): Promise<{ path: string; mtimeMs: number }> {
    const abs = safeResolve(this.root, file);
    if (abs === path.resolve(this.root)) throw new PathError('cannot write project root');
    if (Buffer.byteLength(content) > this.maxBytes) throw new FsError('too_large', 'content too large');
    try {
      if (expectedMtimeMs !== undefined) {
        const current = await stat(abs).catch(() => null);
        if (current && Math.abs(current.mtimeMs - expectedMtimeMs) > 1) {
          throw new FsError('conflict', `${file} changed on disk`);
        }
      }
      await mkdir(path.dirname(abs), { recursive: true });
      await writeFile(abs, content, 'utf8');
      return { path: toRel(this.root, abs), mtimeMs: (await stat(abs)).mtimeMs };
    } catch (e) {
      throw mapErr(e, file);
    }
  }

  async mkdir(dir: string): Promise<void> {
    await mkdir(safeResolve(this.root, dir), { recursive: true });
  }

  async rename(from: string, to: string): Promise<void> {
    const a = safeResolve(this.root, from);
    const b = safeResolve(this.root, to);
    const root = path.resolve(this.root);
    if (a === root || b === root) throw new PathError('cannot rename project root');
    if (await stat(b).catch(() => null)) throw new FsError('exists', `${to} already exists`);
    try {
      await mkdir(path.dirname(b), { recursive: true });
      await rename(a, b);
    } catch (e) {
      throw mapErr(e, from);
    }
  }

  async delete(target: string): Promise<void> {
    const abs = safeResolve(this.root, target);
    if (abs === path.resolve(this.root)) throw new PathError('cannot delete project root');
    if (!(await stat(abs).catch(() => null))) throw new FsError('not_found', `${target} not found`);
    await rm(abs, { recursive: true, force: true });
  }
}

function mapErr(e: unknown, p: string): Error {
  if (e instanceof FsError || e instanceof PathError) return e;
  const code = (e as NodeJS.ErrnoException).code;
  if (code === 'ENOENT') return new FsError('not_found', `${p} not found`);
  if (code === 'ENOTDIR') return new FsError('not_directory', `${p} is not a directory`);
  if (code === 'EACCES' || code === 'EPERM') return new FsError('forbidden', `${p}: permission denied`);
  return e as Error;
}

export interface FsChange {
  projectId: string;
  event: 'add' | 'change' | 'unlink' | 'addDir' | 'unlinkDir';
  path: string;
}

/** Ref-counted chokidar watchers, one per project, shared across sockets. */
export class WatchHub extends EventEmitter<{ change: [FsChange] }> {
  private readonly watchers = new Map<string, { w: FSWatcher; refs: number }>();

  acquire(projectId: string, root: string): () => void {
    let entry = this.watchers.get(projectId);
    if (!entry) {
      const w = chokidar.watch(root, {
        ignoreInitial: true,
        followSymlinks: false,
        ignored: (p: string) => p.split(/[\\/]/).some((seg) => IGNORED_DIRS.has(seg)),
        awaitWriteFinish: { stabilityThreshold: 150, pollInterval: 50 },
      });
      w.on('all', (event, abs) => {
        if (!['add', 'change', 'unlink', 'addDir', 'unlinkDir'].includes(event)) return;
        const rel = toRel(root, abs);
        if (rel === '' || rel.startsWith('..')) return;
        this.emit('change', { projectId, event: event as FsChange['event'], path: rel });
      });
      entry = { w, refs: 0 };
      this.watchers.set(projectId, entry);
    }
    entry.refs++;
    let released = false;
    return () => {
      if (released) return;
      released = true;
      const e = this.watchers.get(projectId);
      if (!e) return;
      if (--e.refs <= 0) {
        void e.w.close();
        this.watchers.delete(projectId);
      }
    };
  }

  async closeAll() {
    await Promise.all([...this.watchers.values()].map((e) => e.w.close()));
    this.watchers.clear();
  }
}
