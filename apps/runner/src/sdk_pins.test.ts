import { describe, expect, it } from 'vitest';
import { applySdkPins } from './sdk_pins.js';

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

  it('respects a pin the project already has', () => {
    const src = 'dependencies:\n  firebase_core: ^4.0.0\ndependency_overrides:\n  firebase_core_web: 3.9.0\n';
    expect(applySdkPins(src)).toBe(src);
  });
});
