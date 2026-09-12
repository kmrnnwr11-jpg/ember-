# Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Monorepo, Runner (REST+WS, auth, drivers, jobs, fs), IDE login/projects/tree/editor | ✅ done |
| 2 | PTY terminal + mobile keys, build web, preview URL, WebView, open in browser | next |
| 3 | ai_connect BYOK (Anthropic, OpenAI, Gemini, compatible), model picker, chat, apply | |
| 4 | Command palette, Cmd+K, Tab autocomplete, @context, Rules | |
| 5 | Agent/Composer, multi-file diff, command confirm, fix loop, @codebase | |
| 5B | "Crea App" flow: summary, prompt generator, 5 live mockups, build modes, resume | |
| 6 | Git panel + GitHub OAuth, APK build/install, templates with ai_connect | |
| 7 | CLI subscription engines (claude/codex/gemini) | |
| 8 | Themes, shortcuts, settings, quotas, onboarding, deploy script, CI | |

## Known gaps after Phase 1

- Docker driver and compose stack are written but **not verified here** (no Docker on the dev machine).
- Job queue is in-process; BullMQ/Redis wiring comes with build jobs.
- Idle-container reaper (`WORKSPACE_IDLE_MINUTES`) not implemented yet (Phase 2).
- Editor: minimap and multi-cursor are not provided by re_editor 0.8; evaluate in Phase 4.
- Only the `empty` template exists (templates package in Phase 6).
