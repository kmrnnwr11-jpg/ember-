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

## Speed + signed Android builds

- Claude Code "fast" mode (default): Sonnet at medium effort, scope-matched prompt, `flutter test/run/build` blocked (a hung `flutter_tester` was the main slowdown). "Best quality" toggle uses Opus at high effort.
- Build screen shows Claude Code's live action instead of a stuck step row.
- After an app is ready the user is asked for **APK** or **AAB**. Both are release builds signed with a per-app upload key (PKCS12, generated with keytool, stored under `WORKSPACES_ROOT/.signing/<projectId>`, password AES-GCM-encrypted when `VAULT_MASTER_KEY` is set). Secrets reach Gradle only via `FC_KEYSTORE_*` env vars; `build.gradle.kts` is patched to read them. `versionCode` is bumped on every signed build.
- Verified live: signed AAB (40 MB, 83 s), certificate `CN=<app>, O=FlutterCursor`, version bumped to `+2`.
- Upload-key backup: one-time 10-minute download link + alias/password shown in the app.
- iOS/IPA: not possible on the Windows Runner (needs macOS + Xcode + Apple Developer account); planned via a macOS CI (Codemagic / GitHub Actions) in Phase 6.

## Terminal CLIs + mockups

- Terminal: new-tab menu with cmd / PowerShell (bash on Linux) and one-tap **Claude Code**, **Codex (GPT)**, **Gemini CLI**. The start command is typed only after the shell prompt appears (ConPTY mangles early input; Enter is a separate write). Mobile key bar adds Enter, Ctrl+C and Paste (bracketed paste). `GET /v1/health` reports `shells` and `cli`.
- Verified live through the Runner PTY: `claude --version` 2.1.263, `codex --version` 0.144.1, `gemini --version` 0.59.0 (installed), `flutter --version` in PowerShell, interactive Claude Code TUI renders its trust prompt.
- Mockups (§1B step 3) shown right after the description, before any project is created: 5 clearly different styles generated in parallel as self-contained HTML (fast: ~1 min for all five) and shown full screen, swipe between them. Actions: Choose, Edit this (prompted change), New mockups (next 5 styles from a pool of 15, previous sets kept), Skip. The chosen mockup's palette/typography/HTML is appended to the build instructions. Deviation from the spec's "mockups as Flutter widgets": HTML is ~5× faster than compiling five Flutter previews; the build then implements the chosen design in Flutter.
- Claude Code one-shot `agent.complete` (no tools, neutral cwd) used for mockups when the engine is Claude Code; API engines use `ai_connect`.
- Verified live: "Dark premium" recipe-app mockup in 57 s, 15.7 KB HTML, 3 screens.

## Simpler interface (branch `ux/semplice`, plan in `docs/UX_PIANO.md`)

- One theme and one set of sizes and building blocks in `apps/ide/lib/ui`; light and dark; the horror wordmark, the code rain and the "summon" wording are gone.
- Home: prompt box and one button; engine, model and "who draws" under "Options" (remembered); one list of apps, never shown twice; empty project and "restore from GitHub" in the menu.
- App screen: status and "Open app", six "next steps" rows that each open a page (phone, pictures, checks, Google Play, App Store, more), the conversation, and the change box fixed at the bottom. Technical details are closed by default.
- Play listing: languages behind "Manage" (search, on/off) instead of 83 chips. App Store: four sections on its own page.
- Settings: one page for language, appearance, AI keys and reviewers, connected accounts, advanced, sign out.
- Words: five complete languages, no text in code, plain names for APK/AAB/Runner, long guides as numbered steps.
- Cancelling the "AI not available" check goes back instead of closing the app.
- Verified: analyzer clean, 209 tests (screens at phone/tablet/desktop width, English and Arabic, light and dark), web release build, and a walk through the real web app against a local Runner (home, options, settings, an existing app and its six pages; screenshots in `docs/ux/dopo`). Not walked live: a new build from prompt to ready, the mockup gallery, publishing to the stores, the Windows and phone builds, the light theme.
