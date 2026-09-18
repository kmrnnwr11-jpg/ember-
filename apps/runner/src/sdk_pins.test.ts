import { describe, expect, it } from 'vitest';
import { applySdkPins, relaxFirebaseVersions, tuneGradleText } from './sdk_pins.js';

describe('SDK pins', () => {
  it('pins firebase_core_web for Firebase apps, once', () => {
    const src = 'name: demo\ndependencies:\n  flutter:\n    sdk: flutter\n  firebase_core: ^4.1.1\n';
    const once = applySdkPins(src);
    expect(once).toContain('dependency_overrides:\n  # firebase_core_web');
    expect(once).toContain('  firebase_core_web: 3.10.0');
    expect(applySdkPins(once)).toBe(once);
  });

  it('adds under an existing dependency_overrides section and leaves other apps alone', () => {
    const src = 'dependencies:\n  firebase_core: ^4.0.0\ndependency_overrides:\n  intl: 0.19.0\n';
    expect(applySdkPins(src)).toMatch(/dependency_overrides:\n  # .*\n  firebase_core_web: 3.10.0\n  intl: 0.19.0/);
    const plain = 'dependencies:\n  http: ^1.0.0\n';
    expect(applySdkPins(plain)).toBe(plain);
  });

  it('lets the other Firebase packages follow the pinned one', () => {
    // The AI writes these versions from memory; an old firebase_storage next to a
    // pinned firebase_core_web makes pub give up before anything is built.
    const src = 'dependencies:\n  firebase_core: ^4.1.1\n  firebase_storage: ^12.4.10\n  cloud_firestore: ^5.6.0\n  http: ^1.2.0\n';
    const out = applySdkPins(src);
    expect(out).toContain('  firebase_storage: any');
    expect(out).toContain('  cloud_firestore: any');
    expect(out).toContain('  firebase_core: any');
    expect(out).toContain('  http: ^1.2.0');
    // The override itself keeps its exact version.
    expect(out).toContain('  firebase_core_web: 3.10.0');
    expect(relaxFirebaseVersions('dependencies:\n  http: ^1.0.0\n')).toBe('dependencies:\n  http: ^1.0.0\n');
  });

  it('turns on the Gradle settings that make the next build fast', () => {
    const tuned = tuneGradleText('org.gradle.jvmargs=-Xmx8G\nandroid.useAndroidX=true\n');
    expect(tuned).toContain('org.gradle.caching=true');
    expect(tuned).toContain('org.gradle.parallel=true');
    expect(tuned).toContain('org.gradle.jvmargs=-Xmx8G');
    // Applying it twice must not stack the same keys again.
    expect(tuneGradleText(tuned)).toBe(tuned);
    // A value the project already chose is left alone.
    expect(tuneGradleText('org.gradle.parallel=false\n')).toContain('org.gradle.parallel=false');
  });

  it('respects a pin the project already has', () => {
    const src = 'dependencies:\n  firebase_core: ^4.0.0\ndependency_overrides:\n  firebase_core_web: 3.9.0\n';
    expect(applySdkPins(src)).toBe(src);
  });
});
