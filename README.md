# FlutterCursor

A Cursor-style IDE for building Flutter apps from phone, tablet, web and desktop.
The IDE (`apps/ide`) talks to a Runner (`apps/runner`) that hosts one isolated
container per workspace with the Flutter and Android SDKs.

```
apps/ide/            Flutter client
apps/runner/         Node + TypeScript backend (Fastify, WebSocket, Docker)
packages/ide_core/   shared protocol, models, path rules
packages/ai_connect/ AI provider layer
infra/               workspace image, compose, Caddy, Supabase migrations
docs/                ARCHITECTURE, API, SETUP, ROADMAP, SHORTCUTS
```

Quick start: see [docs/SETUP.md](docs/SETUP.md). Status: [docs/ROADMAP.md](docs/ROADMAP.md).
