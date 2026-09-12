export interface ExecOptions {
  /** Project-relative working directory inside the workspace ('' = workspace root). */
  cwd: string;
  env?: Record<string, string>;
  onStdout: (chunk: string) => void;
  onStderr: (chunk: string) => void;
  signal: AbortSignal;
}

/** An interactive terminal session. */
export interface PtyHandle {
  onData(cb: (data: string) => void): void;
  onExit(cb: (exitCode: number) => void): void;
  write(data: string): void;
  resize(cols: number, rows: number): void;
  kill(): void;
}

export interface PtyOptions {
  cwd: string;
  cols: number;
  rows: number;
}

/**
 * Runs commands and hosts files for a workspace.
 * - `local`: files under WORKSPACES_ROOT/<id>, processes on the host (dev only).
 * - `docker`: same host directory bind-mounted at /workspace in an isolated container.
 */
export interface WorkspaceDriver {
  readonly kind: 'local' | 'docker';
  /** Host path of the workspace files. */
  hostRoot(workspaceId: string): string;
  ensure(workspaceId: string): Promise<{ containerId: string | null }>;
  stop(workspaceId: string): Promise<void>;
  /** Runs a command; resolves with the exit code. Rejects only on spawn failure. */
  exec(workspaceId: string, cmd: string, args: string[], opts: ExecOptions): Promise<number>;
  /** Opens an interactive login shell. */
  openPty(workspaceId: string, opts: PtyOptions): Promise<PtyHandle>;
}
