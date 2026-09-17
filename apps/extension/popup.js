/** Holds the facts about one app, so the helper knows what to answer. */

const $ = (id) => document.getElementById(id);

async function show() {
  const { app } = await chrome.storage.local.get('app');
  $('current').innerHTML = app
    ? `<div class="app"><b>${app.name}</b><br><span class="small">${app.ads ? 'con pubblicità' : 'senza pubblicità'} · ${app.account ? 'con login' : 'senza login'}</span></div>`
    : '<p class="small">Nessuna app impostata.</p>';
}

/** Accepts the app data, wherever it came from. */
async function save(raw) {
  try {
    const app = JSON.parse(raw.trim());
    if (!app.name) throw new Error("mancano i dati dell'app");
    await chrome.storage.local.set({ app });
    $('data').value = '';
    $('msg').textContent = 'Salvato ✓ — ora apri Play Console e premi il pulsante Ember.';
    show();
  } catch (e) {
    $('msg').textContent = `Non riesco a leggere questi dati: ${e.message}`;
  }
}

// One button instead of paste-then-save: Ember already put the data on the clipboard.
$('fromClipboard').addEventListener('click', async () => {
  try {
    const text = await navigator.clipboard.readText();
    if (!text.trim()) throw new Error('gli appunti sono vuoti');
    await save(text);
  } catch (e) {
    $('msg').textContent = `Non riesco a leggere gli appunti: ${e.message}. Incolla qui sotto con Ctrl+V.`;
  }
});

$('save').addEventListener('click', () => save($('data').value));

show();
