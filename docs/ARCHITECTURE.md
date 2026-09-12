# Architecture

```
┌──────────────── apps/ide (Flutter: iOS/Android/Web/Desktop) ────────────────┐
│  go_router · Riverpod · re_editor · l10n it/en                               │
│  core/session.dart      Supabase auth or dev login, secure storage           │
│  core/runner_api.dart   REST (dio)                                           │
│  core/runner_socket.dart WS: req/resp ids, heartbeat, reconnect, re-watch     │
│  features/projects      workspace + project list, create with live job log   │
│  features/editor        ProjectController (tree, tabs, save, conflicts)       │
└───────────────┬───────────────────────────── REST + WSS (JWT) ───────────────┘
                │
┌───────────────▼──────────── apps/runner (Node 22 + TS, Fastify 5) ───────────┐
│  auth.ts       Supabase JWKS / HS256 / dev tokens                            │
│  services.ts   ownership checks, workspaces, projects, job command whitelist  │
│  fs.ts         ProjectFs (confined ops, mtime conflicts) + WatchHub (chokidar)│
│  jobs.ts       per-workspace FIFO queue, timeout, cancel, log ring buffer     │
│  ws.ts         Session: protocol dispatch, rate limit, subscriptions          │
│  store.ts      JsonStore (dev) | SupabaseStore (prod, service role)           │
│  workspaces/   LocalDriver (dev, host processes) | DockerDriver (prod)        │
└───────────────┬──────────────────────────────────────────────────────────────┘
                │ docker exec (uid 1000, CapDrop ALL, no-new-privileges, CPU/RAM/PID limits)
┌───────────────▼──────── fc-ws-<workspaceId> (infra/workspace/Dockerfile) ────┐
│  /workspace/projects/<name>  ← bind mount of WORKSPACES_ROOT/<workspaceId>   │
│  Flutter · Android SDK 35 · JDK 17 · Chromium · Node · claude/codex/gemini   │
└──────────────────────────────────────────────────────────────────────────────┘
```

Shared Dart code lives in `packages/ide_core` (wire protocol `WsFrame`/`MsgType`,
models, `ProjectPath` with the same confinement rules as the Runner).
`packages/ai_connect` holds the provider contracts (adapters in Phase 3).

## Key decisions

- **Two workspace drivers.** Production isolation needs Docker; the `local`
  driver runs the identical code path against host processes so development
  and CI work without Docker. Never expose a `local` Runner publicly.
- **Files live on the host** (`WORKSPACES_ROOT/<ws>`), bind-mounted into the
  container. The Runner does file I/O directly (fast, watchable) and uses the
  container only to execute commands.
- **Optimistic concurrency** on save via `expectedMtimeMs` → `conflict` →
  the IDE offers Reload / Overwrite.
- **No raw commands** from clients before Phase 2's PTY: jobs are whitelisted.
- **In-process job queue** in Phase 1; `REDIS_URL` is provisioned in compose
  for BullMQ when build jobs arrive (Phase 2/6) and multiple Runner replicas.
- **Store abstraction** keeps local dev dependency-free (JSON file, atomic
  writes) while production uses Supabase Postgres (`infra/supabase/migrations`).
