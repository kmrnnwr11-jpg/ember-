import { describe, expect, it } from 'vitest';
import { parseSite, readSite } from './web_reference.js';

const HTML = `
<html><head>
<title>ZenDocs - Modifica PDF online</title>
<meta name="description" content="Modifica, unisci e comprimi PDF direttamente dal browser.">
<style>.btn{background:#2f6df6;color:#ffffff} .accent{color:#f43f5e} .grey{color:#4a4a4a}</style>
</head><body>
<h1>Modifica PDF</h1>
<h2>Unisci PDF</h2>
<h2>Comprimi PDF</h2>
<h3>Accetta</h3>
<button>Carica file</button>
<a href="/it/merge-pdf">Unisci PDF</a>
<a href="/it/sign-pdf">Firma PDF</a>
<a href="/it/privacy">Privacy</a>
<a href="https://other.com/it/x">Altro sito</a>
<p>Premium 9,99 € / mese oppure €89 / anno</p>
</body></html>`;

describe('a website taken as the model for an app', () => {
  const site = parseSite('https://zendocs.com/it/edit-pdf?id=abc', HTML);

  it('reads what the site offers, in its own words', () => {
    expect(site.title).toBe('ZenDocs - Modifica PDF online');
    expect(site.description).toContain('Modifica, unisci e comprimi PDF');
    expect(site.features).toContain('Modifica PDF');
    expect(site.features).toContain('Comprimi PDF');
    expect(site.features).toContain('Carica file');
    // Cookie banners and log-in buttons are not features.
    expect(site.features).not.toContain('Accetta');
  });

  it('collects the other pages of the same site, which are the other tools', () => {
    expect(site.pages.map((p) => p.url)).toEqual(['https://zendocs.com/it/merge-pdf', 'https://zendocs.com/it/sign-pdf']);
    // Another site, and the legal pages, are none of our business.
    expect(site.pages.some((p) => p.url.includes('other.com') || p.url.includes('privacy'))).toBe(false);
  });

  it('notices how it earns and the colours it wears', () => {
    expect(site.prices.join(' ')).toContain('€89');
    expect(site.colors).toContain('#2f6df6');
    // White and greys say nothing about a brand.
    expect(site.colors).not.toContain('#ffffff');
    expect(site.colors).not.toContain('#4a4a4a');
  });

  it('says plainly when the site will not answer', async () => {
    const dead = (async () => new Response('nope', { status: 503 })) as unknown as typeof fetch;
    await expect(readSite('https://x.test', dead)).rejects.toThrow(/503/);
  });
});
