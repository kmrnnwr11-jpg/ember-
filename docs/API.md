# Runner API

Base URL: `RUNNER_URL` (dev `http://localhost:8787`). All bodies are JSON.
Errors: `{ "code": string, "message": string }` with HTTP status
`400 bad_request|bad_path|bad_template|bad_job`, `401 unauthorized`, `403 forbidden`,
`404 not_found`, `409 exists|conflict|not_ready`, `413 too_large`, `429 rate_limited`, `500 internal`.

Auth: `Authorization: Bearer <JWT>` — a Supabase access token (JWKS or legacy
HS256) or, when `DEV_AUTH=true`, a token from `/v1/auth/dev-login`.

## REST

| Method | Path | Auth | Body | Response |
|---|---|---|---|---|
| GET | `/v1/health` | – | – | `{ok, driver, store, devAuth, version}` |
| POST | `/v1/auth/dev-login` | – | `{email}` | `{token, user:{id,email}}` (404 if dev auth disabled) |
| GET | `/v1/me` | ✓ | – | `{id, email}` |
| GET | `/v1/templates` | ✓ | – | `{templates: ["empty"]}` |
| GET | `/v1/workspaces` | ✓ | – | `{workspaces: Workspace[]}` |
| POST | `/v1/workspaces` | ✓ | `{name?}` | `201 Workspace` (container/dir ensured) |
| GET | `/v1/workspaces/:workspaceId/projects` | ✓ | – | `{projects: Project[]}` |
| POST | `/v1/workspaces/:workspaceId/projects` | ✓ | `{name, template?}` | `202 {project, job: JobStatus}` — runs `flutter create` |
| GET | `/v1/projects/:projectId` | ✓ | – | `Project` |
| DELETE | `/v1/projects/:projectId` | ✓ | – | `204` (removes files) |
| GET | `/v1/jobs/:jobId` | ✓ | – | `JobStatus + {log, createdAt, finishedAt}` |
| POST | `/v1/jobs/:jobId/cancel` | ✓ | – | `{cancelled}` |

Types:

```ts
Workspace = { id, name, status: 'stopped'|'starting'|'running'|'error', createdAt }
Project   = { id, workspaceId, name, template, status: 'creating'|'ready'|'error', lastModel, createdAt }
JobStatus = { jobId, kind: 'create'|'pub_get'|'analyze'|'test'|'build_web'|'build_apk',
              status: 'queued'|'running'|'succeeded'|'failed'|'cancelled', exitCode, projectId }
FsEntry   = { path, name, isDir, size }   // path is project-relative POSIX
```

Project names must match `^[a-z][a-z0-9_]{0,63}$` (Dart package name).

## WebSocket

`GET /v1/ws?token=<JWT>` (or `Authorization` header). Invalid token → close code `4401`.

Frames: `{ id?, type, payload }`. A request with `id` gets exactly one response
with the same `id`: `{type:"ok", payload}` or `{type:"error", payload:{code,message}}`.
Server events have no `id`. The server sends WS pings every 20 s; clients may
also send `{type:"ping"}` → event `pong`. Limit: 400 frames / 10 s per socket.
File content over WS ≤ `MAX_WS_FILE_BYTES` (5 MB). All paths are confined to
the project root (`..`, absolute and drive paths rejected with `bad_path`).

### Requests (Phase 1)

| type | payload | ok payload |
|---|---|---|
| `fs.list` | `{projectId, path?}` | `{entries: FsEntry[]}` — dirs first; hides `.dart_tool build .git node_modules .idea Pods .gradle` |
| `fs.read` | `{projectId, path}` | `{path, content, mtimeMs}` — errors `binary`, `too_large`, `is_directory` |
| `fs.write` | `{projectId, path, content, expectedMtimeMs?}` | `{path, mtimeMs}` — `conflict` if file changed since `expectedMtimeMs` |
| `fs.mkdir` | `{projectId, path}` | `{}` |
| `fs.rename` | `{projectId, from, to}` | `{}` — `exists` if target exists |
| `fs.delete` | `{projectId, path}` | `{}` (recursive) |
| `fs.watch` | `{projectId, enabled?=true}` | `{watching}` |
| `job.start` | `{projectId, kind: 'pub_get'|'analyze'|'test'}` | `JobStatus` |
| `job.cancel` | `{jobId}` | `{cancelled}` |

Reserved for later phases (currently `unsupported`): `pty.open`, `pty.input`,
`pty.resize`, `pty.close` (Phase 2), `analyze.run`, `preview.reload`.

### Events

| type | payload |
|---|---|
| `fs.changed` | `{projectId, event: 'add'|'change'|'unlink'|'addDir'|'unlinkDir', path}` (only for watched projects) |
| `job.status` | `JobStatus` (all jobs of the connected user) |
| `job.log` | `{jobId, stream: 'stdout'|'stderr', chunk}` |
| `pong` | `{}` |

## Jobs

One running job per workspace, FIFO queue, timeout `JOB_TIMEOUT_SECONDS`
(default 900 s), log ring buffer (4000 chunks) replayable via `GET /v1/jobs/:id`.
Clients never send raw commands; each `kind` maps to a fixed command line.
