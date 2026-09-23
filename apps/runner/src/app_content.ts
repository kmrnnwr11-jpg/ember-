import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { detectDataFacts, type AppDataFacts } from './data_safety.js';

/**
 * Play Console "App content": eleven declarations Google asks for before an app
 * can go public. Only Data safety has an API (see data_safety.ts); for the rest
 * Ember works out the right answer from what the app actually does, so the user
 * only has to click it in Play Console.
 */

export interface ContentItem {
  /** Matches the row in Play Console → App content. */
  id: string;
  /** The row's name, as Play Console shows it. */
  title: string;
  /** The answer Ember proposes, ready to copy. */
  answer: string;
  /** Why that is the answer, or what to paste where. */
  detail: string;
  /** True when Ember can send it to Google by itself. */
  automatic: boolean;
}

interface Listing {
  privacyUrl?: string;
  contactEmail?: string;
  title?: string;
}

async function readJson<T>(file: string): Promise<T | null> {
  return JSON.parse(await readFile(file, 'utf8').catch(() => 'null')) as T | null;
}

/** Answers for every App content row, from the project's own dependencies and setup. */
export async function appContentAnswers(projectRoot: string): Promise<{ facts: AppDataFacts; email: string; items: ContentItem[] }> {
  const facts = await detectDataFacts(projectRoot);
  const store = path.join(projectRoot, 'store');
  const listing = (await readJson<Listing>(path.join(store, 'listing.json'))) ?? {};
  const products = (await readJson<{ products?: unknown[] }>(path.join(store, 'products.json')))?.products ?? [];
  const ads = (await readJson<{ enabled?: boolean }>(path.join(store, 'ads.json')))?.enabled ?? facts.ads;
  const sells = products.length > 0 || facts.payments;
  const email = listing.contactEmail?.includes('@') ? listing.contactEmail : '';

  const titles: Record<string, string> = {
    privacy_policy: 'Privacy policy',
    app_access: 'App access',
    ads: 'Ads',
    content_rating: 'Content rating',
    target_audience: 'Target audience and content',
    data_safety: 'Data safety',
    government_apps: 'Government apps',
    financial_features: 'Financial features',
    news_apps: 'News apps',
    health_apps: 'Health apps',
    store_listing: 'Store listing',
  };

  const rows: Array<Omit<ContentItem, 'title'>> = [
    {
      id: 'privacy_policy',
      answer: listing.privacyUrl || '',
      detail: listing.privacyUrl
        ? 'Paste this address in the Privacy policy field and save.'
        : 'No privacy policy link yet: write one in "Edit title and descriptions", then come back.',
      automatic: false,
    },
    {
      id: 'app_access',
      answer: facts.account ? 'Some functionality is restricted' : 'All functionality is available without special access',
      detail: facts.account
        ? 'The app has sign-in: add test credentials (an account you created) so Google can review it.'
        : 'The app needs no login, so nothing else to fill in here.',
      automatic: false,
    },
    {
      id: 'ads',
      answer: ads ? 'Yes, the app contains ads' : 'No, the app does not contain ads',
      detail: ads ? 'The app shows ads, so this must be declared.' : 'No ad library is used by the app.',
      automatic: false,
    },
    {
      id: 'content_rating',
      answer: email ? `Email: ${email} — Category: Utility / Productivity / Other` : 'Category: Utility / Productivity / Other',
      detail: 'Answer "No" to violence, sex, drugs, gambling and profanity. Say the app does not share the user location and has no user-to-user chat unless it really does.',
      automatic: false,
    },
    {
      id: 'target_audience',
      answer: '13-15, 16-17, 18 and over',
      detail: 'Do not tick the under-13 ages: they turn on the Families programme with much stricter rules.',
      automatic: false,
    },
    {
      id: 'data_safety',
      answer: 'Ember fills this one in',
      detail: 'Export the CSV from Play Console, then press "Fill Data safety": Ember answers it and sends it to Google.',
      automatic: true,
    },
    { id: 'government_apps', answer: 'No', detail: 'The app is not published on behalf of a government body.', automatic: false },
    {
      id: 'financial_features',
      answer: sells ? 'No financial features (in-app purchases only)' : 'My app does not provide any financial features',
      detail: 'This row is about loans, crypto and payments; selling in-app products is not a financial feature.',
      automatic: false,
    },
    { id: 'news_apps', answer: 'No, this is not a news app', detail: 'Only for apps whose main purpose is news.', automatic: false },
    { id: 'health_apps', answer: 'No health features', detail: 'Only for apps with medical, wellbeing or health-research features.', automatic: false },
    {
      id: 'store_listing',
      answer: listing.title ? `Title, descriptions, logo and screenshots: ready (${listing.title})` : 'Not ready yet',
      detail: 'Ember uploads these with every new version.',
      automatic: true,
    },
  ];
  return { facts, email, items: rows.map((r) => ({ ...r, title: titles[r.id] ?? r.id })) };
}
