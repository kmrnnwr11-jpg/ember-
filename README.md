# Ember

Ember builds an app from a description and publishes it to Google Play and the App Store,
from phone, tablet, web and desktop. The app (`apps/ide`) talks to a Runner (`apps/runner`)
that holds the Flutter and Android SDKs and does the building.

On Windows, double-click `avvia-ember.cmd` to start everything.

```
apps/ide/            Flutter client
apps/runner/         Node + TypeScript backend (Fastify, WebSocket, Docker)
packages/ide_core/   shared protocol, models, path rules
packages/ai_connect/ AI provider layer
infra/               workspace image, compose, Caddy, Supabase migrations
docs/                ARCHITECTURE, API, SETUP, ROADMAP, SHORTCUTS
```

Quick start: see [docs/SETUP.md](docs/SETUP.md). Status: [docs/ROADMAP.md](docs/ROADMAP.md).
