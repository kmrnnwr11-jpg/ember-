import { describe, expect, it } from 'vitest';
import { parseScreenshots } from './research.js';

/** The shapes Play puts on a listing page: icon, badges, and the screenshots. */
const page = `
  <img src="https://play-lh.googleusercontent.com/ICONICONICON=w240-h480-rw" alt="Icon">
  <img src="https://play-lh.googleusercontent.com/AAAAAAAAAAA=w526-h296" srcset="https://play-lh.googleusercontent.com/AAAAAAAAAAA=w1052-h592 2x">
  <img src="https://play-lh.googleusercontent.com/BBBBBBBBBBB=w526-h296">
  <img src="https://play-lh.googleusercontent.com/SQUARESQUARE=w512-h512">
  <img src="https://play-lh.googleusercontent.com/TINYTINYTINY=w64-h64">
`;

describe('Play Store listing', () => {
  it('takes the screenshots and leaves icons and badges alone', () => {
    const shots = parseScreenshots(page);
    expect(shots).toEqual([
      'https://play-lh.googleusercontent.com/AAAAAAAAAAA=w1080',
      'https://play-lh.googleusercontent.com/BBBBBBBBBBB=w1080',
    ]);
  });

  it('keeps one copy of a picture that appears at several sizes', () => {
    const twice = `${page}<img src="https://play-lh.googleusercontent.com/AAAAAAAAAAA=w2104-h1184">`;
    expect(parseScreenshots(twice).filter((u) => u.includes('AAAAAAAAAAA'))).toHaveLength(1);
  });

  it('stops at the number asked for', () => {
    expect(parseScreenshots(page, 1)).toHaveLength(1);
    expect(parseScreenshots('<html></html>')).toEqual([]);
  });
});
