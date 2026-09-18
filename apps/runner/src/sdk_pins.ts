import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

/**
 * Packages whose newest release needs a newer Dart than the Runner's Flutter SDK
 * although their pubspec says otherwise. Pinned through dependency_overrides.
 */
export const SDK_PINS: Array<{ when: RegExp; pkg: string; version: string; reason: string }> = [
  {
    when: /^\s+firebase_core:/m,
    pkg: 'firebase_core_web',
    version: '3.10.0',
    reason: 'firebase_core_web 3.11 uses Object.isA (newer Dart): web build fails on Flutter 3.38',
  },
];

/**
 * Frees the other Firebase packages to follow the pinned one.
 *
 * The packages share an internal interface, so pinning one and leaving the
 * others on an older major makes pub give up with a version-solving error. The
 * AI writes those versions from memory, and they are rarely a matching set:
 * letting pub choose is both more reliable and closer to what it meant.
 */
export function relaxFirebaseVersions(pubspec: string): string {
  // Everything up to dependency_overrides: the overrides are deliberate and stay as they are.
  const cut = pubspec.search(/^dependency_overrides:/m);
  const head = cut < 0 ? pubspec : pubspec.slice(0, cut);
  const tail = cut < 0 ? '' : pubspec.slice(cut);
  return head.replace(/^([ \t]+)(firebase_[a-z_]+|cloud_firestore):[ \t]*\^?[\d][\w.+-]*[ \t]*$/gm, '$1$2: any') + tail;
}

/** Adds the needed overrides to a pubspec text; returns it unchanged when nothing applies. */
export function applySdkPins(pubspec: string): string {
  let out = pubspec;
  for (const pin of SDK_PINS) {
    if (!pin.when.test(out) || new RegExp(`^[ \\t]+${pin.pkg}:`, 'm').test(out.split(/^dependency_overrides:/m)[1] ?? '')) continue;
    out = relaxFirebaseVersions(out);
    const line = `  # ${pin.reason}\n  ${pin.pkg}: ${pin.version}\n`;
    out = /^dependency_overrides:[ \t]*$/m.test(out)
      ? out.replace(/^dependency_overrides:[ \t]*\n/m, (h) => h + line)
      : `${out.replace(/\s*$/, '')}\n\ndependency_overrides:\n${line}`;
  }
  return out;
}

/**
 * Gradle settings that make the second build fast.
 *
 * Out of the box Gradle rebuilds everything, in one thread, throwing away what
 * it learned. Turning on its cache and parallel work costs nothing and is the
 * difference between waiting ten minutes and waiting one.
 */
const GRADLE_SPEED: Array<[string, string]> = [
  ['org.gradle.caching', 'true'],
  ['org.gradle.parallel', 'true'],
  ['org.gradle.configureondemand', 'true'],
  ['org.gradle.daemon', 'true'],
  ['kotlin.incremental', 'true'],
];

export function tuneGradleText(properties: string): string {
  let out = properties.replace(/\s*$/, '');
  for (const [key, value] of GRADLE_SPEED) {
    if (new RegExp(`^${key.replace(/\./g, '\\.')}\\s*=`, 'm').test(out)) continue;
    out += `\n${key}=${value}`;
  }
  return `${out}\n`;
}

/** Applies the speed settings to a project on disk, once. */
export async function tuneGradle(projectRoot: string): Promise<void> {
  const file = path.join(projectRoot, 'android', 'gradle.properties');
  const text = await readFile(file, 'utf8').catch(() => null);
  if (text === null) return;
  const tuned = tuneGradleText(text);
  if (tuned !== text) await writeFile(file, tuned);
}

/** Applies [applySdkPins] to a project's pubspec.yaml on disk. */
export async function pinProjectSdk(projectRoot: string): Promise<void> {
  const file = path.join(projectRoot, 'pubspec.yaml');
  const text = await readFile(file, 'utf8').catch(() => null);
  if (text === null) return;
  const pinned = applySdkPins(text);
  if (pinned !== text) await writeFile(file, pinned);
}
