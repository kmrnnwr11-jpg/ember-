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

### Requests (Phase 2)

| type | payload | ok payload |
|---|---|---|
| `pty.open` | `{projectId, cols?=80, rows?=24}` | `{ptyId}` — login shell in the project dir (max 8 per connection, killed on disconnect) |
| `pty.input` | `{ptyId, data}` | `{}` |
| `pty.resize` | `{ptyId, cols, rows}` | `{}` (clamped 2–500) |
| `pty.close` | `{ptyId}` | `{closed}` |
| `preview.start` | `{projectId, autoRebuild?=true}` | `{job: JobStatus, preview: PreviewInfo}` — `flutter build web --release --base-href …` |
| `preview.reload` | same as `preview.start` | same (forces a rebuild) |
| `preview.stop` | `{projectId}` | `{}` — stops rebuild-on-save |
| `preview.status` | `{projectId}` | `PreviewInfo` |

```ts
PreviewInfo = { projectId, url: string|null, path, built, builtAt, autoRebuild, building }
// public URL = url ?? RUNNER_URL + path
```

With `autoRebuild`, saves under `lib/ web/ assets/ packages/`, `pubspec.*` or
`l10n.yaml` trigger a rebuild after 1.5 s of quiet (queued builds are deduplicated).

Reserved (currently `unsupported`): `analyze.run`, `agent.*`.

### Events

| type | payload |
|---|---|
| `fs.changed` | `{projectId, event: 'add'|'change'|'unlink'|'addDir'|'unlinkDir', path}` (only for watched projects) |
| `job.status` | `JobStatus` (all jobs of the connected user) |
| `job.log` | `{jobId, stream: 'stdout'|'stderr', chunk}` |
| `pong` | `{}` |
| `pty.output` | `{ptyId, data}` (coalesced ~12 ms) |
| `pty.exit` | `{ptyId, exitCode}` |
| `preview.building` | `{projectId, jobId}` |
| `preview.ready` | `PreviewInfo` |
| `preview.failed` | `{projectId, jobId}` |

## Preview hosting

`GET /preview/:workspaceId/:projectId/*` serves `build/web` of the project
(no auth: the two random ids act as a capability link; `X-Robots-Tag: noindex`).
Unknown extension-less paths fall back to `index.html` (client routing);
`index.html`, `flutter_bootstrap.js`, service worker and manifests are sent
`no-cache`. While a build is running and nothing is built yet, a placeholder
page auto-refreshes every 3 s. With `PREVIEW_BASE_DOMAIN` set, requests to
`preview.<domain>/<ws>/<project>/…` are rewritten to the same route and builds
use base href `/<ws>/<project>/`.

## AI (Phase 3)

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/v1/ai/models` | ✓ | Model catalog `{version, defaults, models: AiModel[]}` from `AI_CATALOG_URL` (cached 1 h) or bundled `ai-catalog.json` |
| POST | `/v1/ai/proxy/:provider/<upstream path>` | ✓ | Transparent BYOK proxy, streams the upstream response (SSE) back unchanged |

```ts
AiModel = { provider: 'anthropic'|'openai'|'gemini'|'openaiCompatible', id, label,
            inputPerMTok, outputPerMTok, contextTokens, tools, tags: string[] }
```

Proxy request headers:

| Header | Required | Meaning |
|---|---|---|
| `Authorization: Bearer <JWT>` | ✓ | Runner auth (never forwarded upstream) |
| `x-provider-key` | ✓ (may be empty for `openaiCompatible`) | User's API key, injected as `x-api-key` (Anthropic), `x-goog-api-key` (Gemini) or `Authorization: Bearer` (OpenAI/compatible). Never stored, redacted from logs |
| `x-provider-base-url` | for `openaiCompatible` | Upstream base URL; must be https and non-private unless `AI_ALLOW_PRIVATE_BASE_URLS=true` |
| `anthropic-version`, `anthropic-beta`, `content-type`, `accept` | – | Forwarded as-is |

Allowed upstream paths (anything else → `403 forbidden`):

| provider | upstream | paths |
|---|---|---|
| `anthropic` | api.anthropic.com | `v1/messages`, `v1/messages/count_tokens` |
| `openai` | api.openai.com | `v1/chat/completions`, `v1/embeddings` |
| `openaiCompatible` | `x-provider-base-url` | `v1/chat/completions`, `v1/embeddings` |
| `gemini` | generativelanguage.googleapis.com | `v1beta/models/<id>:{streamGenerateContent,generateContent,batchEmbedContents,countTokens}` (query string kept, e.g. `?alt=sse`) |

Errors: `400 bad_request`, `403 forbidden`, `404 not_found` (unknown provider),
`429 rate_limited` (`AI_RATE_LIMIT_PER_MINUTE`, default 120/user), `502 upstream_unreachable`.
Upstream HTTP errors (e.g. 401 invalid key) are passed through with their body.
Closing the client connection aborts the upstream request.

### Why a transparent proxy (deviation from the original §5B)

§5B described a Runner endpoint that normalizes all providers into one SSE
format. Instead, normalization lives once in the Dart package `ai_connect`,
and the Runner only forwards. Reasons: generated apps embed `ai_connect`
without any Runner, so the Dart adapters must exist anyway; one implementation
avoids two diverging translations; the proxy stays small and auditable. A
normalized server-side endpoint can be added for a server-run Agent (Phase 5/7)
if needed.

## Jobs

One running job per workspace, FIFO queue, timeout `JOB_TIMEOUT_SECONDS`
(default 900 s), log ring buffer (4000 chunks) replayable via `GET /v1/jobs/:id`.
Clients never send raw commands; each `kind` maps to a fixed command line.

## Factory (`/v1/factory`)

Many apps at once, from idea to the stores. The routes, the JSON of the state, the plan made by the
supervisor, the commands and the connections are written in
[FABBRICA_PIANO.md](FABBRICA_PIANO.md#api-del-runner-v1factory-tutte-autenticate-come-le-altre-rotte-v1).
The Runner also accepts `qwen-code` in `POST /v1/subscriptions/:engine/login` and reports
`engines.qwenCode` in `GET /v1/health`. `JobManager.setWorkspaceLimit(workspaceId, n)` lets one
workspace run several jobs together (the Factory uses it; every other workspace keeps one).
