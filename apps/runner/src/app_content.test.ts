import { mkdtemp, mkdir, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { appContentAnswers } from './app_content.js';

async function project(pubspec: string, listing?: Record<string, unknown>): Promise<string> {
  const root = await mkdtemp(path.join(os.tmpdir(), 'ember-content-'));
  await writeFile(path.join(root, 'pubspec.yaml'), pubspec);
  if (listing) {
    await mkdir(path.join(root, 'store'), { recursive: true });
    await writeFile(path.join(root, 'store', 'listing.json'), JSON.stringify(listing));
  }
  return root;
}

const answer = (items: Awaited<ReturnType<typeof appContentAnswers>>['items'], id: string) => items.find((i) => i.id === id)!.answer;

describe('appContentAnswers', () => {
  it('declares ads and restricted access for an app that has them', async () => {
    const root = await project('dependencies:\n  google_mobile_ads: ^5.0.0\n  firebase_auth: ^5.0.0\n');
    const { items } = await appContentAnswers(root);
    expect(answer(items, 'ads')).toMatch(/Yes/);
    expect(answer(items, 'app_access')).toMatch(/restricted/);
  });

  it('declares no ads and open access for a plain app', async () => {
    const root = await project('dependencies:\n  http: ^1.0.0\n');
    const { items } = await appContentAnswers(root);
    expect(answer(items, 'ads')).toMatch(/does not contain ads/);
    expect(answer(items, 'app_access')).toMatch(/without special access/);
    expect(answer(items, 'target_audience')).not.toMatch(/under/i);
  });

  it('offers the saved privacy link and contact email', async () => {
    const root = await project('dependencies:\n', { privacyUrl: 'https://example.com/privacy', contactEmail: 'me@example.com', title: 'Demo' });
    const { items } = await appContentAnswers(root);
    expect(answer(items, 'privacy_policy')).toBe('https://example.com/privacy');
    expect(answer(items, 'content_rating')).toContain('me@example.com');
    expect(answer(items, 'store_listing')).toContain('Demo');
  });

  it('marks only the rows Ember can send by itself', async () => {
    const { items } = await appContentAnswers(await project('dependencies:\n'));
    expect(items.filter((i) => i.automatic).map((i) => i.id)).toEqual(['data_safety', 'store_listing']);
  });
});
