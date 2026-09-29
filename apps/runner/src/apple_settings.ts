import { readFile } from 'node:fs/promises';
import path from 'node:path';
import type { AppDataFacts } from './data_safety.js';
import { parseJson } from './paths.js';

/**
 * Per-app choices for the App Store that the code alone cannot tell, in
 * store/apple_settings.json. Example for a children's app:
 *   { "kids": true, "kidsAgeBand": "FIVE_AND_UNDER", "iosAds": false }
 */
export interface AppleSettings {
  /** Made for kids: Apple Kids category (age band required, no tracking). */
  kids?: boolean;
  kidsAgeBand?: 'FIVE_AND_UNDER' | 'SIX_TO_EIGHT' | 'NINE_TO_ELEVEN';
  /** false when the iPhone build shows no ads (e.g. Kids category). */
  iosAds?: boolean;
  /** File in store/screenshots/ showing the purchase, for the reviewer. */
  reviewScreenshot?: string;
  /** false when the iPhone build hides sign-in (and so any cloud upload). */
  iosAccount?: boolean;
}

export async function readAppleSettings(root: string): Promise<AppleSettings> {
  try {
    return parseJson(await readFile(path.join(root, 'store', 'apple_settings.json'), 'utf8')) as AppleSettings;
  } catch {
    return {};
  }
}

/**
 * The data facts as they are on the iPhone: an app whose iPhone build shows
 * no ads collects nothing through the ad SDK there, and a kids app tracks nothing.
 */
export function appleFacts(facts: AppDataFacts, s: AppleSettings): AppDataFacts {
  const out: AppDataFacts = { ...facts, kids: !!s.kids };
  if (s.iosAds === false && facts.ads) {
    const viaAnalytics = facts.analytics;
    out.ads = false;
    out.deviceId = viaAnalytics;
    out.approxLocation = viaAnalytics;
    out.productInteraction = viaAnalytics;
    // crash/performance reports came from the ad SDK unless a crash reporter is there too
    out.crashLogs = facts.crashLogs && viaAnalytics;
    out.performance = facts.performance && viaAnalytics;
  }
  if (s.iosAccount === false) {
    // No account on iPhone: nothing linked to a person, nothing uploaded.
    out.account = false;
    out.photos = false;
    out.files = false;
    out.microphone = false;
    out.messages = false;
    out.cloudStorage = false;
    out.purchases = false;
  }
  return out;
}
