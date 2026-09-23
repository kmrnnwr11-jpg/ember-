/**
 * The bridge to Ember on this computer. A content script runs with the page's
 * origin and cannot read http://127.0.0.1; the extension's own worker can
 * (host_permissions), so the Apple helper asks here.
 */
chrome.runtime.onMessage.addListener((msg, _sender, reply) => {
  if (msg?.type !== 'ember:apple-plan') return false;
  fetch('http://127.0.0.1:8787/helper/apple', { cache: 'no-store' })
    .then(async (res) => {
      const body = await res.json().catch(() => ({}));
      reply(res.ok ? { plan: body } : { error: body.message || `Ember ha risposto ${res.status}` });
    })
    .catch(() => reply({ error: 'Ember non risponde: apri Ember sul Mac (il Runner deve essere acceso).' }));
  return true; // answered asynchronously
});
