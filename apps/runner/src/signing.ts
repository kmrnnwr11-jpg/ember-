import { spawn } from 'node:child_process';
import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';
import { existsSync, readdirSync } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import type { Config } from './config.js';

export const SIGNING_MARKER = '// fluttercursor-signing';

export interface SigningInfo {
  alias: string;
  storePassword: string;
  keystorePath: string;
  createdAt: string;
}

interface StoredKey {
  alias: string;
  /** base64 of iv|tag|ciphertext when encrypted, else plain text. */
  storePassword: string;
  encrypted: boolean;
  createdAt: string;
}

function vaultKey(cfg: Config): Buffer | null {
  if (!cfg.VAULT_MASTER_KEY) return null;
  const raw = /^[0-9a-f]{64}$/i.test(cfg.VAULT_MASTER_KEY) ? Buffer.from(cfg.VAULT_MASTER_KEY, 'hex') : Buffer.from(cfg.VAULT_MASTER_KEY, 'base64');
  if (raw.length !== 32) throw new Error('VAULT_MASTER_KEY must be 32 bytes (hex or base64)');
  return raw;
}

export function sealSecret(cfg: Config, plain: string): { value: string; encrypted: boolean } {
  const key = vaultKey(cfg);
  if (!key) return { value: plain, encrypted: false };
  const iv = randomBytes(12);
  const c = createCipheriv('aes-256-gcm', key, iv);
  const ct = Buffer.concat([c.update(plain, 'utf8'), c.final()]);
  return { value: Buffer.concat([iv, c.getAuthTag(), ct]).toString('base64'), encrypted: true };
}

export function openSecret(cfg: Config, value: string, encrypted: boolean): string {
  if (!encrypted) return value;
  const key = vaultKey(cfg);
  if (!key) throw new Error('keystore password is encrypted but VAULT_MASTER_KEY is not set');
  const buf = Buffer.from(value, 'base64');
  const d = createDecipheriv('aes-256-gcm', key, buf.subarray(0, 12));
  d.setAuthTag(buf.subarray(12, 28));
  return Buffer.concat([d.update(buf.subarray(28)), d.final()]).toString('utf8');
}

/** Finds keytool: KEYTOOL_BIN, JAVA_HOME, common Windows JDK installs, then PATH. */
export function resolveKeytool(cfg: Config): string {
  if (cfg.KEYTOOL_BIN) return cfg.KEYTOOL_BIN;
  const exe = process.platform === 'win32' ? 'keytool.exe' : 'keytool';
  if (process.env.JAVA_HOME) {
    const p = path.join(process.env.JAVA_HOME, 'bin', exe);
    if (existsSync(p)) return p;
  }
  if (process.platform === 'win32') {
    for (const vendorDir of ['C:\\Program Files\\Eclipse Adoptium', 'C:\\Program Files\\Java', 'C:\\Program Files\\Android\\Android Studio\\jbr']) {
      if (!existsSync(vendorDir)) continue;
      if (existsSync(path.join(vendorDir, 'bin', exe))) return path.join(vendorDir, 'bin', exe);
      const jdks = readdirSync(vendorDir).filter((d) => /jdk-?17/i.test(d)).concat(readdirSync(vendorDir).filter((d) => /jdk/i.test(d)));
      for (const d of jdks) {
        const p = path.join(vendorDir, d, 'bin', exe);
        if (existsSync(p)) return p;
      }
    }
  }
  return exe;
}

function run(bin: string, args: string[]): Promise<{ code: number; output: string }> {
  return new Promise((resolve, reject) => {
    const p = spawn(bin, args, { windowsHide: true });
    let output = '';
    p.stdout.on('data', (d) => (output += d));
    p.stderr.on('data', (d) => (output += d));
    p.on('error', reject);
    p.on('close', (code) => resolve({ code: code ?? 1, output }));
  });
}

/** Directory holding a project's upload key; outside any project tree. */
export function signingDir(cfg: Config, projectId: string): string {
  return path.resolve(cfg.WORKSPACES_ROOT, '.signing', projectId);
}

/** Creates (once) and returns the project's upload keystore. */
export async function ensureUploadKey(cfg: Config, projectId: string, appName: string, keytool = resolveKeytool(cfg)): Promise<SigningInfo> {
  const dir = signingDir(cfg, projectId);
  const keystorePath = path.join(dir, 'upload-keystore.jks');
  const metaPath = path.join(dir, 'key.json');
  if (existsSync(keystorePath) && existsSync(metaPath)) {
    const meta = JSON.parse(await readFile(metaPath, 'utf8')) as StoredKey;
    return { alias: meta.alias, storePassword: openSecret(cfg, meta.storePassword, meta.encrypted), keystorePath, createdAt: meta.createdAt };
  }
  await mkdir(dir, { recursive: true });
  const password = randomBytes(18).toString('base64url');
  const cn = appName.replace(/[^\w .-]/g, '').slice(0, 60) || 'App';
  const res = await run(keytool, [
    '-genkeypair', '-noprompt',
    '-keystore', keystorePath,
    '-storetype', 'PKCS12',
    '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000',
    '-alias', 'upload',
    '-storepass', password, '-keypass', password,
    '-dname', `CN=${cn}, O=FlutterCursor`,
  ]);
  if (res.code !== 0) throw new Error(`keytool failed: ${res.output.slice(-500)}`);
  const sealed = sealSecret(cfg, password);
  const meta: StoredKey = { alias: 'upload', storePassword: sealed.value, encrypted: sealed.encrypted, createdAt: new Date().toISOString() };
  await writeFile(metaPath, JSON.stringify(meta, null, 2), { mode: 0o600 });
  return { alias: 'upload', storePassword: password, keystorePath, createdAt: meta.createdAt };
}

/**
 * Makes android/app/build.gradle.kts sign release builds with the key given
 * through FC_KEYSTORE_* environment variables (so no secret is written into
 * the project). Without those variables it keeps using debug keys. Idempotent.
 */
export function patchGradleKts(src: string): string {
  if (src.includes(SIGNING_MARKER)) return src;
  const debugLine = /signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)/;
  const buildTypes = /\n(\s*)buildTypes\s*\{/;
  const m = buildTypes.exec(src);
  if (!m) throw new Error('android/app/build.gradle.kts has no buildTypes block');
  const indent = m[1] ?? '    ';
  const block =
    `\n${indent}${SIGNING_MARKER}\n` +
    `${indent}signingConfigs {\n` +
    `${indent}    create("release") {\n` +
    `${indent}        val ks = System.getenv("FC_KEYSTORE_PATH")\n` +
    `${indent}        if (ks != null) {\n` +
    `${indent}            storeFile = file(ks)\n` +
    `${indent}            storePassword = System.getenv("FC_KEYSTORE_PASSWORD")\n` +
    `${indent}            keyAlias = System.getenv("FC_KEY_ALIAS")\n` +
    `${indent}            keyPassword = System.getenv("FC_KEY_PASSWORD")\n` +
    `${indent}        }\n` +
    `${indent}    }\n` +
    `${indent}}\n`;
  let out = src.replace(buildTypes, `${block}\n${indent}buildTypes {`);
  const releaseSelector = 'signingConfig = if (System.getenv("FC_KEYSTORE_PATH") != null) signingConfigs.getByName("release") else signingConfigs.getByName("debug")';
  out = debugLine.test(out)
    ? out.replace(debugLine, releaseSelector)
    : out.replace(/(release\s*\{)/, `$1\n${indent}${indent}${releaseSelector}`);
  return out;
}

/**
 * Increments the build number in `version: x.y.z+N` (adds +1 if missing).
 * `floor` is the highest version code Google Play has already accepted: the
 * next build must be above it, whatever the project file says.
 */
export function bumpBuildNumber(pubspec: string, floor = 0): { text: string; version: string } {
  const re = /^version:[ \t]*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?[ \t]*$/m;
  const m = re.exec(pubspec);
  const next = Math.max(Number(m?.[2] ?? 0), floor) + 1;
  if (!m) return { text: pubspec.replace(/^name:.*$/m, (l) => `${l}\nversion: 1.0.0+${next}`), version: `1.0.0+${next}` };
  const version = `${m[1]}+${next}`;
  return { text: pubspec.replace(re, `version: ${version}`), version };
}

/** Highest version code Google Play accepted for this project, if known. */
export async function lastPublishedVersionCode(projectRoot: string): Promise<number> {
  const raw = await readFile(path.join(projectRoot, 'store', 'play.json'), 'utf8').catch(() => null);
  if (!raw) return 0;
  const n = Number((JSON.parse(raw) as { lastVersionCode?: number }).lastVersionCode);
  return Number.isFinite(n) ? n : 0;
}

/** Remembers what Google Play accepted, so the next build starts above it. */
export async function rememberPublishedVersionCode(projectRoot: string, versionCode: number): Promise<void> {
  const dir = path.join(projectRoot, 'store');
  await mkdir(dir, { recursive: true });
  const previous = await lastPublishedVersionCode(projectRoot);
  await writeFile(path.join(dir, 'play.json'), JSON.stringify({ lastVersionCode: Math.max(previous, versionCode) }, null, 2));
}

/** SHA-1 of a keystore entry via keytool, or null. */
export async function keystoreSha1(keystore: string, alias: string, password: string, keytool: string): Promise<string | null> {
  if (!existsSync(keystore)) return null;
  const res = await run(keytool, ['-list', '-v', '-keystore', keystore, '-alias', alias, '-storepass', password]);
  const m = /SHA1:\s*([0-9A-F:]{59})/i.exec(res.output);
  return res.code === 0 && m ? m[1]!.toUpperCase() : null;
}

/** Package name + SHA-1s needed for Firebase Android apps and Google Sign-In. */
export async function androidAppInfo(cfg: Config, projectId: string, projectRoot: string, appName: string) {
  const keytool = resolveKeytool(cfg);
  let applicationId: string | null = null;
  const gradle = path.join(projectRoot, 'android', 'app', 'build.gradle.kts');
  if (existsSync(gradle)) applicationId = /applicationId\s*=\s*"([^"]+)"/.exec(await readFile(gradle, 'utf8'))?.[1] ?? null;
  const key = await ensureUploadKey(cfg, projectId, appName, keytool);
  const release = await keystoreSha1(key.keystorePath, key.alias, key.storePassword, keytool);
  const home = process.env.USERPROFILE ?? process.env.HOME ?? '';
  const debug = await keystoreSha1(path.join(home, '.android', 'debug.keystore'), 'androiddebugkey', 'android', keytool);
  return { applicationId, sha1Release: release, sha1Debug: debug };
}

/** Prepares a project for a signed release build; returns env vars for Gradle. */
export async function prepareSignedBuild(cfg: Config, projectId: string, projectRoot: string, appName: string): Promise<{ env: Record<string, string>; version: string }> {
  const gradle = path.join(projectRoot, 'android', 'app', 'build.gradle.kts');
  if (!existsSync(gradle)) throw new Error('android/app/build.gradle.kts not found (project has no Kotlin Gradle Android module)');
  const key = await ensureUploadKey(cfg, projectId, appName);
  const src = await readFile(gradle, 'utf8');
  const patched = patchGradleKts(src);
  if (patched !== src) await writeFile(gradle, patched);
  const pubspecPath = path.join(projectRoot, 'pubspec.yaml');
  const bumped = bumpBuildNumber(await readFile(pubspecPath, 'utf8'), await lastPublishedVersionCode(projectRoot));
  await writeFile(pubspecPath, bumped.text);
  return {
    version: bumped.version,
    env: {
      FC_KEYSTORE_PATH: key.keystorePath,
      FC_KEYSTORE_PASSWORD: key.storePassword,
      FC_KEY_ALIAS: key.alias,
      FC_KEY_PASSWORD: key.storePassword,
    },
  };
}
