# Architecture

```
┌──────────────── apps/ide (Flutter: iOS/Android/Web/Desktop) ────────────────┐
│  go_router · Riverpod · re_editor · l10n en/it/es/fr/ar                            │
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

## The IDE's screens

```
/login                      sign in (the Runner address is under "Advanced")
/projects                   home: describe an app; the list of apps beside or under the prompt box
/mockups                    full-screen designs to choose from
/projects/:id/create        the app's home: build progress, "Open app", next steps, conversation
/projects/:id/test          phone preview, file to install (APK)
/projects/:id/images        logo, store screenshots
/projects/:id/checks        automatic check, reviewers
/projects/:id/google-play   Play status, file for Google Play (AAB), signing key
/projects/:id/play[/details] guided Play publishing, store listing
/projects/:id/app-store     iPhone build, App Store Connect
/projects/:id/more          GitHub backup, ads, purchases, signing key, the code
/projects/:id               the code editor (files, editor, terminal, preview, AI)
/settings                   language, appearance, AI keys, connected accounts, advanced, sign out
```

## Look and building blocks (`apps/ide/lib/ui`)

Screens do not style themselves. Sizes, colours and the common pieces live in one place:

- `tokens.dart` — `Gap` (4/8/12/16/24/32), `Radii`, `Motion` (150/250/400 ms, one curve), `Breakpoints` (840: one side panel, 1100: two), `Widths`.
- `theme.dart` — `emberTheme(brightness)`: neutral surfaces, Ember red as the only accent, light and dark. `EmberColors` adds `success`, `warning` and the always-dark `codeSurface` used by logs, terminals and previews. Use `context.scheme`, `context.text`, `context.ember`.
- `section_card.dart` — `SectionCard`, `BusyRow`, `InlineMessage`, `StatusRow`, `FindingTile`, `Pill`, `StepsList`.
- `feedback.dart` — `LoadingState`, `EmptyState`, `ErrorState`, `showConfirm`, `showEmberSnack`, `PageBody`.
- `inputs.dart` — `SecretField` (keys and tokens). `chat.dart` — `ChatBubble`, `ChatComposer`, `LogSurface`, `OverlayButton`. `tab_strip.dart` — `TabStrip`.

Rules, checked by `test/tokens_test.dart` and `test/l10n_complete_test.dart`: no colour literal and no hand-drawn field border outside `lib/ui`; no screen file over 500 lines; every string in all five `.arb` files. One primary action per screen; everything else is one tap away. Start/end, never left/right (Arabic).

## The Factory (`apps/runner/src/factory`)

Takes up to 100 apps at once from an idea to Google Play (internal testing, draft) and TestFlight, in
the background, whatever screen is open. Plan and decisions: [FABBRICA_PIANO.md](FABBRICA_PIANO.md).

```
supervisor.ts  free text / theme / list  →  up to 100 app cards (name, summary, brief, small|big)
engines.ts     cards + engine weights    →  one engine per app, big apps to the strongest
engine.ts      Factory: state machine per app, 11 stages in a dependency graph, retries, pause,
               restart-safe, daily cap on store uploads, "needs you" list, in-flight limit
scheduler.ts   Lanes: pools with a limit and an ordered waiting line (agent:<engine>, build, light…)
ops.ts         the real stage operations: they drive the same services the IDE uses
               (Services.createProject/startJob, ClaudeCodeEngine, PreviewService, and the
               Runner's own routes for logos, screenshots, listing, Play and App Store)
simulate.ts    pretend operations (EMBER_FACTORY_SIMULATE=1) to try the interface without engines
listing.ts     store page + translations, saved in the format the IDE's publish screen reads
links.ts       what is connected (engines, Flutter, Android SDK, keys, Mac); capacity.ts what it can carry
routes.ts      /v1/factory REST; service.ts one Factory per user, state in DATA_DIR/factory/<user>.json
```

- **Stages** `create → code → verify → (preview, logo, listing in parallel) → shots → android → play`, and
  `ios → appstore` independent of the Android side. A stage starts when everything it needs is done.
- **Lanes** keep the machine inside what it can carry: AI agents per engine, builds (RAM-based), screenshots, stores.
  Stages deeper in the pipeline are served first, so apps get finished rather than a hundred started.
- **Never production**: Play = internal track + draft release, App Store = TestFlight; nothing is sent for review.
  Uploads per store per local day are capped (default 10 each); the rest wait ready and go the next day.
- **Needs you**: what no program can do (create the app in Play Console / App Store Connect, a Mac, keys, an SDK,
  an expired engine login) parks that stage and the app (it holds no slot) in a list with the values to copy.
- The Runner calls its own routes in-process with a per-process secret (`x-ember-internal`), as the owner.
