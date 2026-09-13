# Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Monorepo, Runner (REST+WS, auth, drivers, jobs, fs), IDE login/projects/tree/editor | ✅ done |
| 2 | PTY terminal + mobile keys, build web, preview URL, WebView, open in browser | ✅ done |
| 3 | ai_connect BYOK (Anthropic, OpenAI, Gemini, compatible), model picker, chat, apply | ✅ done |
| 4 | Command palette, Cmd+K, Tab autocomplete, @context, Rules | next |
| 5 | Agent/Composer, multi-file diff, command confirm, fix loop, @codebase | |
| 5B | "Crea App" flow: summary, prompt generator, 5 live mockups, build modes, resume | |
| 6 | Git panel + GitHub OAuth, APK build/install, templates with ai_connect | |
| 7 | CLI subscription engines (claude/codex/gemini) | |
| 8 | Themes, shortcuts, settings, quotas, onboarding, deploy script, CI | |

## Known gaps after Phase 1

- Docker driver and compose stack are written but **not verified here** (no Docker on the dev machine).
- Job queue is in-process; BullMQ/Redis wiring comes with build jobs.
- Idle-container reaper (`WORKSPACE_IDLE_MINUTES`) not implemented yet (Phase 8, quotas).

## Known gaps after Phase 2

- "Hot reload" on web is rebuild-on-save + automatic WebView reload (~20 s per
  release build), not stateful hot reload (§6C). A `flutter run -d web-server`
  dev mode needs a long-lived process per project; evaluate with Docker in Phase 8.
- Terminals do not survive a WebSocket reconnect (tap "Restart").
- JS console capture works on Android/iOS/macOS/Windows WebViews; on the web
  build of the IDE the preview is an iframe and console messages are not available.
- Docker PTY (`docker exec` with TTY) is implemented but unverified (no Docker here).

## Known gaps after Phase 3

- Adapters are verified against recorded SSE fixtures and the proxy against a
  fake upstream; **not yet against the live APIs** (no API key on the dev machine).
- OpenAI/Gemini model ids and prices in the catalog are best-known values;
  update `apps/runner/ai-catalog.json` (or `AI_CATALOG_URL`) without an app release.
- Chat history and per-project model are stored on the device
  (`shared_preferences`), not yet in Supabase `chat_threads`/`chat_messages`.
- Keys are client-side only (secure storage); the server-side encrypted vault
  (`api_keys` table, `VAULT_MASTER_KEY`) is not used yet.
- Anthropic has no embeddings API; `@codebase` (Phase 5) will need an OpenAI or Gemini key.
- The compatible-URL SSRF check does not resolve DNS; production Runners need egress filtering.
- Editor: minimap and multi-cursor are not provided by re_editor 0.8; evaluate in Phase 4.
- Only the `empty` template exists (templates package in Phase 6).

## "Crea App" (§1B) — first version, brought forward on request

- Home: "Descrivi la tua app" + engine choice (Gemini, Claude Code, Claude, ChatGPT, Grok) → project created → build screen.
- API engines: generate files (fenced blocks with paths, write allowlist, package name enforced) → `flutter pub get` → `flutter analyze` → up to 3 AI fix rounds → web build → preview. Follow-up "change" prompts.
- Claude Code engine: Runner runs the local `claude` CLI headless in the project (prompt via stdin, restricted tools, no MCP), streams progress as `agent.event`; then web build.
- Verified live with Claude Code: "Acqua di oggi" app, 9 files, analyze clean, 2 tests passing, preview served (≈4.5 min).
- Not yet: 5 mockup styles, "give me the prompt" mode, step-by-step mode, resume after app restart, push notification, summary/clarifying questions.
- Local workspaces now default to `C:\FlutterCursor\workspaces` in dev so Claude Code does not inherit unrelated CLAUDE.md files from the user's home directory.
