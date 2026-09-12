import { nanoid } from 'nanoid';
import type { PtyHandle } from './workspaces/driver.js';

const MAX_PER_SESSION = 8;
const FLUSH_MS = 12;
const MAX_BUFFER = 64 * 1024;

export class PtyLimitError extends Error {
  readonly code = 'too_many_terminals';
}

interface Entry {
  handle: PtyHandle;
  projectId: string;
  buffer: string;
  timer: NodeJS.Timeout | null;
}

/**
 * Terminals owned by one WebSocket session. Output is coalesced into ~12ms
 * frames so a chatty process does not flood the socket with tiny messages.
 */
export class PtySessions {
  private readonly ptys = new Map<string, Entry>();

  constructor(
    private readonly onOutput: (ptyId: string, data: string) => void,
    private readonly onExit: (ptyId: string, exitCode: number) => void,
  ) {}

  add(projectId: string, handle: PtyHandle): string {
    if (this.ptys.size >= MAX_PER_SESSION) {
      handle.kill();
      throw new PtyLimitError(`max ${MAX_PER_SESSION} terminals per connection`);
    }
    const id = nanoid(10);
    const entry: Entry = { handle, projectId, buffer: '', timer: null };
    this.ptys.set(id, entry);
    handle.onData((d) => {
      entry.buffer += d;
      if (entry.buffer.length >= MAX_BUFFER) return this.flush(id);
      entry.timer ??= setTimeout(() => this.flush(id), FLUSH_MS);
    });
    handle.onExit((code) => {
      this.flush(id);
      this.ptys.delete(id);
      this.onExit(id, code);
    });
    return id;
  }

  private flush(id: string) {
    const e = this.ptys.get(id);
    if (!e) return;
    if (e.timer) clearTimeout(e.timer);
    e.timer = null;
    if (!e.buffer) return;
    const data = e.buffer;
    e.buffer = '';
    this.onOutput(id, data);
  }

  get(id: string): Entry | undefined {
    return this.ptys.get(id);
  }

  close(id: string): boolean {
    const e = this.ptys.get(id);
    if (!e) return false;
    e.handle.kill();
    return true;
  }

  closeAll() {
    for (const [id, e] of this.ptys) {
      if (e.timer) clearTimeout(e.timer);
      e.handle.kill();
      this.ptys.delete(id);
    }
  }
}
