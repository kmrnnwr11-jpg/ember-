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

## Android tools on Windows (for the Android bundle and the Factory)

The Android bundle (`.aab`) needs a JDK 17 and the Android SDK. Without Android Studio:

1. JDK 17 (Temurin zip) unpacked to `C:\Users\<you>\tools\jdk-17`.
2. Android command-line tools unpacked so that `sdkmanager.bat` is at
   `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin` (the folder Flutter and the Factory look at first).
3. With `JAVA_HOME` pointing at that JDK: `sdkmanager --licenses`, then
   `sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"`.
4. `flutter config --android-sdk "%LOCALAPPDATA%\Android\Sdk" --jdk-dir "C:\Users\<you>\tools\jdk-17"`.

The Runner finds the JDK for the signing key from Flutter's own settings (`%APPDATA%\.flutter_settings`),
so no `JAVA_HOME` is needed. The first Android build downloads Gradle and the Android dependencies
(a few minutes and about 1 GB); the next ones are much faster.
