/**
 * Ember inside App Store Connect: the two things Apple's public API cannot do.
 *
 *  - Create the app (My Apps → + → New App) with the name, Bundle ID and SKU
 *    Ember already knows.
 *  - Answer App Privacy with the same answers Google's Data safety got.
 *
 * It sends the requests the website itself sends, from the user's own signed-in
 * tab: no password, no separate browser. Nothing is written until the user
 * presses a button, and every write is read back and compared.
 */

(() => {
  if (window.__emberAppleHelper) return;
  window.__emberAppleHelper = true;

  const STALE = 'Ho aggiornato Ember: ricarica questa pagina (⌘R) e riprova.';
  let rules = null;
  let plan = null;
  let appId = null;

  const load = async () => (rules ??= await import(chrome.runtime.getURL('apple_rules.js')));

  /** Same request the page would send, with the user's session. */
  async function iris(method, path, body) {
    const { IRIS, appleError } = await load();
    const res = await fetch(`${IRIS}/${path}`, {
      method,
      credentials: 'include',
      headers: { accept: 'application/json', 'content-type': 'application/json', 'x-requested-with': 'XMLHttpRequest' },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await res.text();
    const json = text ? JSON.parse(text) : {};
    if (!res.ok) throw new Error(appleError(res.status, json));
    return json;
  }

  const askEmber = (bundleId) =>
    new Promise((resolve) => {
      if (!chrome?.runtime?.id) return resolve({ error: STALE });
      chrome.runtime.sendMessage({ type: 'ember:apple-plan', bundleId }, (r) => resolve(r ?? { error: STALE }));
    });

  /** The Bundle ID of the app open in this tab, when the page is an app's. */
  async function bundleOfOpenApp() {
    const { appIdFromUrl } = await load();
    const id = appIdFromUrl(location.href);
    if (!id) return null;
    const json = await iris('GET', `apps/${id}?fields[apps]=bundleId`).catch(() => null);
    return json?.data?.attributes?.bundleId ?? null;
  }

  // ---------------------------------------------------------------- panel
  const el = (tag, attrs = {}, ...kids) => {
    const n = document.createElement(tag);
    Object.assign(n, attrs);
    kids.flat().forEach((k) => n.append(k instanceof Node ? k : document.createTextNode(`${k}`)));
    return n;
  };
  const panel = el('div', { id: 'ember-panel', hidden: true });
  const button = el('button', { id: 'ember-button', textContent: 'EMBER', title: 'Ember: crea l’app e compila la Privacy' });
  const log = el('div', { className: 'ember-log' });

  function say(line, kind = '') {
    log.append(el('p', { className: kind }, line));
    log.scrollTop = log.scrollHeight;
  }

  function actionButton(label, run) {
    const b = el('button', { className: 'ember-action', textContent: label });
    b.addEventListener('click', async () => {
      panel.querySelectorAll('button.ember-action').forEach((x) => (x.disabled = true));
      try {
        await run();
      } catch (e) {
        say(`✗ ${e.message}`, 'ember-error');
      } finally {
        panel.querySelectorAll('button.ember-action').forEach((x) => (x.disabled = false));
      }
    });
    return b;
  }

  /** The app on App Store Connect with Ember's Bundle ID, or null. */
  async function findApp() {
    const json = await iris('GET', `apps?filter[bundleId]=${encodeURIComponent(plan.bundleId)}&limit=1`);
    return json.data?.[0]?.id ?? null;
  }

  async function createApp() {
    const { createAppBody } = await load();
    if (await findApp()) return say('L’app esiste già su App Store Connect ✓', 'ember-ok');
    if (!plan.bundleRegistered) say('Attenzione: Ember non ha potuto registrare il Bundle ID. Se Apple rifiuta, registralo su developer.apple.com → Identifiers.', 'ember-warn');
    say(`Creo "${plan.name}" (${plan.bundleId})…`);
    const json = await iris('POST', 'apps', createAppBody(plan));
    appId = json.data?.id ?? (await findApp());
    say(`App creata ✓ — ora torna in Ember e premi Publish.`, 'ember-ok');
    if (appId) setTimeout(() => location.assign(`https://appstoreconnect.apple.com/apps/${appId}/distribution`), 1500);
  }

  async function currentPrivacy(id) {
    const { rowsFromApple } = await load();
    return rowsFromApple(await iris('GET', `apps/${id}/dataUsages?include=category,purpose,dataProtection&limit=500`));
  }

  async function checkPrivacy() {
    const { privacyDiff, privacyRows } = await load();
    const id = appId ?? (await findApp());
    if (!id) return say('L’app non c’è ancora su App Store Connect: premi prima "Crea l’app".', 'ember-warn');
    const diff = privacyDiff(await currentPrivacy(id), privacyRows(plan.privacy));
    if (diff.same) return say('La Privacy su Apple è già giusta ✓', 'ember-ok');
    say(`Da sistemare: ${diff.missing.length} risposte mancanti, ${diff.extra.length} in più.`, 'ember-warn');
    const { rowText } = await load();
    diff.missing.forEach((r) => say(`+ manca: ${rowText(r)}`, 'ember-small'));
    diff.extra.forEach((r) => say(`− in più: ${rowText(r)}`, 'ember-small'));
    return diff;
  }

  async function fillPrivacy() {
    const { privacyDiff, privacyRows, usageBody } = await load();
    const id = appId ?? (await findApp());
    if (!id) return say('L’app non c’è ancora su App Store Connect: premi prima "Crea l’app".', 'ember-warn');
    const wanted = privacyRows(plan.privacy);
    const diff = privacyDiff(await currentPrivacy(id), wanted);
    if (diff.same) return say('La Privacy su Apple è già giusta ✓', 'ember-ok');
    // Wrong answers first, then the missing ones: never both "collected" and "not collected".
    for (const r of diff.extra) {
      await iris('DELETE', `appDataUsages/${r.id}`);
    }
    if (diff.extra.length) say(`Tolte ${diff.extra.length} risposte sbagliate`);
    for (const r of diff.missing) {
      await iris('POST', 'appDataUsages', usageBody(id, r));
    }
    say(`Scritte ${diff.missing.length} risposte`);
    // Read back what Apple kept before calling it done.
    const after = privacyDiff(await currentPrivacy(id), wanted);
    if (!after.same) throw new Error(`Apple non ha tenuto tutte le risposte (${after.missing.length} mancano): ricarica la pagina e riprova.`);
    const state = await iris('GET', `apps/${id}/dataUsagePublishState`);
    if (state.data?.id && !state.data.attributes?.published) {
      await iris('PATCH', `appDataUsagesPublishState/${state.data.id}`, { data: { type: 'appDataUsagesPublishState', id: state.data.id, attributes: { published: true } } });
    }
    say('Privacy dell’app compilata e pubblicata ✓', 'ember-ok');
    if (/\/privacy/.test(location.pathname)) setTimeout(() => location.reload(), 1500);
  }

  async function open() {
    panel.replaceChildren(el('p', {}, 'Chiedo a Ember quale app…'));
    panel.hidden = false;
    // The app open in this tab decides which app Ember talks about.
    const { plan: p, error } = await askEmber(await bundleOfOpenApp());
    if (error) return panel.replaceChildren(el('p', { className: 'ember-error' }, error));
    plan = p;
    const { appIdFromUrl, privacySummary } = await load();
    appId = appIdFromUrl(location.href);
    const summary = el('ul', { className: 'ember-list' }, privacySummary(plan.privacy).map((l) => el('li', {}, l)));
    log.replaceChildren();
    panel.replaceChildren(
      el('p', {}, el('b', {}, plan.name)),
      el('p', { className: 'ember-small' }, `${plan.bundleId} · SKU ${plan.sku} · ${plan.primaryLocale}`),
      el('p', { className: 'ember-small' }, 'Privacy che Ember dichiara (solo i dati che escono dal telefono):'),
      summary,
      el(
        'div',
        { className: 'ember-actions' },
        actionButton('Crea l’app', createApp),
        actionButton('Controlla Privacy', checkPrivacy),
        actionButton('Compila Privacy', fillPrivacy),
      ),
      log,
    );
    const exists = await findApp().catch((e) => (say(`✗ ${e.message}`, 'ember-error'), undefined));
    if (exists === null) say('Questa app non esiste ancora su App Store Connect: premi "Crea l’app".');
    else if (exists) {
      appId = exists;
      say('L’app è su App Store Connect ✓');
    }
  }

  button.addEventListener('click', () => (panel.hidden ? open() : (panel.hidden = true)));
  document.documentElement.append(button, panel);
})();
