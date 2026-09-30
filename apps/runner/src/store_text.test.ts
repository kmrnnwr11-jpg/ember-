import { describe, expect, it } from 'vitest';
import { fitStoreText } from './app.js';

describe('store texts', () => {
  it('shortens an over-long title at a word, never refuses it', () => {
    const out = fitStoreText('Capy Amigo: Mein virtuelles Haustier', 30);
    expect(Array.from(out).length).toBeLessThanOrEqual(30);
    expect(out).toBe('Capy Amigo: Mein virtuelles');
  });
  it('keeps texts that already fit, and counts characters not bytes', () => {
    expect(fitStoreText('  Capy Amigo  ', 30)).toBe('Capy Amigo');
    const hindi = 'कैपी अमीगो: मेरा वर्चुअल पालतू दोस्त और साथी';
    expect(Array.from(fitStoreText(hindi, 30)).length).toBeLessThanOrEqual(30);
  });
});
