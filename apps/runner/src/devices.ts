import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

/**
 * The phones plugged into this computer, and how to put an app on one.
 *
 * Testing on a real phone is the only way to see what the user will see:
 * Google sign-in, notifications and ads all behave differently there than in
 * the preview.
 */

export interface Device {
  id: string;
  name: string;
  /** `device` when ready, `unauthorized` when the phone has not allowed this PC yet. */
  state: string;
}

/** Where Android's tools live, following the usual installs. */
export function adbPath(env: NodeJS.ProcessEnv = process.env): string {
  const exe = process.platform === 'win32' ? 'adb.exe' : 'adb';
  const roots = [
    env.ANDROID_SDK_ROOT,
    env.ANDROID_HOME,
    path.join(os.homedir(), 'AppData', 'Local', 'Android', 'Sdk'),
    path.join(os.homedir(), 'Library', 'Android', 'sdk'),
    path.join(os.homedir(), 'Android', 'Sdk'),
  ].filter(Boolean) as string[];
  for (const root of roots) {
    const candidate = path.join(root, 'platform-tools', exe);
    if (existsSync(candidate)) return candidate;
  }
  return exe;
}

/**
 * The address of this computer on the home network, so a phone can reach it.
 *
 * `localhost` means nothing to another device, and virtual-machine adapters
 * (VirtualBox's 192.168.56.x, Docker, WSL) answer only to the PC itself: they
 * would produce a QR code that leads nowhere.
 */
export function lanAddress(interfaces: Record<string, Array<{ family: string; internal: boolean; address: string }> | undefined> = os.networkInterfaces() as never): string | null {
  const candidates: string[] = [];
  for (const [name, addresses] of Object.entries(interfaces)) {
    if (/virtualbox|vmware|docker|wsl|loopback/i.test(name)) continue;
    for (const a of addresses ?? []) {
      if (a.family !== 'IPv4' || a.internal) continue;
      if (a.address.startsWith('192.168.56.')) continue;
      candidates.push(a.address);
    }
  }
  // A home router hands out 192.168.x.x, so prefer those over anything exotic.
  return candidates.sort((a, b) => Number(b.startsWith('192.168.')) - Number(a.startsWith('192.168.')))[0] ?? null;
}

function run(bin: string, args: string[], timeoutMs = 120_000): Promise<{ code: number; out: string }> {
  return new Promise((resolve) => {
    const p = spawn(bin, args, { windowsHide: true });
    let out = '';
    p.stdout?.on('data', (d) => (out += d));
    p.stderr?.on('data', (d) => (out += d));
    const t = setTimeout(() => p.kill(), timeoutMs);
    p.on('error', (e) => (clearTimeout(t), resolve({ code: -1, out: e.message })));
    p.on('close', (code) => (clearTimeout(t), resolve({ code: code ?? -1, out })));
  });
}

/** Reads `adb devices -l`: one phone per line, with the model when the phone says it. */
export function parseDevices(output: string): Device[] {
  return output
    .split(/\r?\n/)
    .slice(1)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('*'))
    .map((line) => {
      const [id, state = '', ...rest] = line.split(/\s+/);
      const details = rest.join(' ');
      const model = /model:(\S+)/.exec(details)?.[1]?.replace(/_/g, ' ');
      return { id: id!, state, name: model ?? id! };
    })
    .filter((d) => d.id.length > 2);
}

export async function listDevices(adb = adbPath()): Promise<Device[]> {
  const res = await run(adb, ['devices', '-l'], 30_000);
  return res.code === 0 ? parseDevices(res.out) : [];
}

/** Installs the built APK on a phone and opens it. */
export async function installAndRun(
  input: { apkPath: string; packageName: string; deviceId?: string },
  adb = adbPath(),
  exec: typeof run = run,
): Promise<string> {
  const target = input.deviceId ? ['-s', input.deviceId] : [];
  const install = await exec(adb, [...target, 'install', '-r', input.apkPath], 10 * 60_000);
  if (!/Success/i.test(install.out)) {
    if (/INSTALL_FAILED_UPDATE_INCOMPATIBLE|signatures do not match/i.test(install.out)) {
      throw new Error('The phone already has a version of this app signed with a different key: uninstall it from the phone and press again.');
    }
    if (/device unauthorized/i.test(install.out)) {
      throw new Error('The phone has not allowed this computer yet: unlock it and accept "Allow USB debugging".');
    }
    throw new Error(`The phone refused the app: ${install.out.trim().slice(-300)}`);
  }
  const started = await exec(adb, [...target, 'shell', 'monkey', '-p', input.packageName, '-c', 'android.intent.category.LAUNCHER', '1'], 60_000);
  return /No activities found/i.test(started.out) ? 'Installed on the phone. Open it from the home screen.' : 'Installed and opened on the phone.';
}
