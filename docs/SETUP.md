# Setup

## Requirements

- Flutter stable ≥ 3.38 (Dart ≥ 3.10), `dart pub global activate melos`
- Node ≥ 22
- Docker + Compose (for the `docker` driver / production). Not needed for local dev.

## Local development (no Docker, no Supabase)

```bash
cp .env.example .env              # DEV_AUTH=true, WORKSPACE_DRIVER=local
flutter pub get                   # resolves the whole Dart workspace
cd apps/runner && npm install && npm run dev
# another terminal
cd apps/ide && flutter run -d chrome --dart-define=RUNNER_URL=http://localhost:8787
```

Android emulator: use `--dart-define=RUNNER_URL=http://10.0.2.2:8787`.
Physical phone: the PC's LAN IP, e.g. `http://192.168.1.20:8787`.

Sign in with any email (dev mode), create a project, open `lib/main.dart`, edit, Ctrl+S.

## Tests

```bash
melos run analyze && melos run test     # Dart/Flutter
cd apps/runner && npm run typecheck && npm test
npm run smoke                            # e2e against a running Runner (real flutter create)
```

## With Supabase

1. Create a project, run `infra/supabase/migrations/0001_init.sql` in the SQL editor.
2. Enable Email (and Google/GitHub later) providers.
3. `.env`: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, optional `SUPABASE_JWT_SECRET`
   (legacy projects), `DEV_AUTH=false`.
4. IDE: `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

## Docker

```bash
docker compose -f infra/docker-compose.yml --profile build build   # runner + workspace image (~6 GB)
sudo mkdir -p /srv/ember/workspaces && sudo chown 1000:1000 /srv/ember/workspaces
docker compose -f infra/docker-compose.yml up -d                   # add --profile prod for Caddy HTTPS
```

DNS for prod: `runner.<domain>` and `preview.<domain>` → VPS IP.
