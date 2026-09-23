import { describe, expect, it } from 'vitest';
import { appleFacts } from './apple_settings.js';
import { declarations, type AppDataFacts } from './data_safety.js';

const withAdMob: AppDataFacts = {
  account: false, photos: false, files: false, location: false, approxLocation: true, contacts: false, microphone: false,
  messages: false, crashLogs: true, performance: true, analytics: false, productInteraction: true, deviceId: true, ads: true,
  purchases: false, payments: true, cloudStorage: false,
};

describe('apps for children on the App Store', () => {
  it('an iPhone build without ads declares nothing collected', () => {
    expect(declarations(appleFacts(withAdMob, { kids: true, iosAds: false }))).toEqual([]);
  });

  it('child-directed ads never count as tracking', () => {
    const rows = declarations(appleFacts(withAdMob, { kids: true }));
    expect(rows.length).toBeGreaterThan(0);
    expect(rows.every((r) => !r.tracking)).toBe(true);
  });

  it('a normal app keeps its ad data and tracking', () => {
    expect(declarations(appleFacts(withAdMob, {})).some((r) => r.tracking)).toBe(true);
  });
});
