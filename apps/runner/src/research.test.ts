import { describe, expect, it } from 'vitest';
import { parseDetails, parseSearchIds } from './research.js';

describe('Play Store research', () => {
  it('lists app ids from a search page in order, without duplicates', () => {
    const html = '<a href="/store/apps/details?id=it.bonusx.app.prod">x</a><a href="/store/apps/details?id=it.pagopa.io.app"></a><a href="/store/apps/details?id=it.bonusx.app.prod"></a>';
    expect(parseSearchIds(html)).toEqual(['it.bonusx.app.prod', 'it.pagopa.io.app']);
  });

  it('extracts title, icon and the full description from a details page', () => {
    const html = `<meta property="og:title" content="BonusX - ISEE, 730 e 600 bonus - App su Google Play"><meta property="og:image" content="https://img/icon.png">
      <a href="/store/apps/dev?id=123"><span>BonusX Srl</span></a>
      <div data-g-id="description" inert>Trova i bonus.<br><br>Richiedi ISEE &amp; 730.</div>`;
    const a = parseDetails('it.bonusx.app.prod', html, 'it')!;
    expect(a.title).toBe('BonusX - ISEE, 730 e 600 bonus');
    expect(a.developer).toBe('BonusX Srl');
    expect(a.icon).toBe('https://img/icon.png');
    expect(a.description).toBe('Trova i bonus.\n\nRichiedi ISEE & 730.');
    expect(a.url).toContain('id=it.bonusx.app.prod');
  });

  it('returns null when the page is not an app listing', () => {
    expect(parseDetails('x.y', '<html></html>', 'it')).toBeNull();
  });
});
