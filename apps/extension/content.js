/**
 * Ember inside Play Console.
 *
 * Two ways to use it: answer the page in front of you, or press "Do everything"
 * and let Ember walk the whole App content list — opening each section, filling
 * it, saving it, and moving on.
 *
 * It runs inside the user's own session, the way an extension is meant to: no
 * separate browser, no sign-in, nothing pretending to be someone it is not. The
 * run survives page reloads because its progress is kept in storage, and it
 * stops the moment the user presses Stop.
 */

(() => {
  if (window.__emberPlayHelper) return;
  window.__emberPlayHelper = true;

  let rules = null;

  /** Reloading the extension leaves open tabs holding a dead connection to it. */
  const STALE = 'Ho aggiornato Ember: ricarica questa pagina (F5) e ripremi il pulsante.';

  /** The App content sections Ember can answer, in the order it walks them. */
  const ROWS = [
    { id: 'ads', name: 'Annunci', words: ['annunci', 'ads'] },
    { id: 'rating', name: 'Classificazione contenuti', words: ['classificazione', 'content rating'] },
    { id: 'audience', name: 'Pubblico di destinazione', words: ['pubblico di destinazione', 'target audience'] },
    { id: 'government', name: 'App governative', words: ['app governative', 'government'] },
    { id: 'financial', name: 'Funzionalità finanziarie', words: ['funzionalità finanziarie', 'financial'] },
    { id: 'news', name: 'App di notizie', words: ['app di notizie', 'news'] },
    { id: 'health', name: 'Salute', words: ['salute', 'health'] },
  ];

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const text = (el) => (el?.innerText ?? el?.textContent ?? '').replace(/\s+/g, ' ').trim();
  const lower = (el) => text(el).toLowerCase();

  /** The app Ember is publishing, asked straight to Ember on this computer. */
  async function appFromEmber() {
    try {
      const res = await fetch('http://127.0.0.1:8787/helper/app', { cache: 'no-store' });
      if (!res.ok) return null;
      const app = await res.json();
      return app?.name ? app : null;
    } catch {
      return null;
    }
  }

  async function store(patch) {
    if (!chrome?.runtime?.id || !chrome?.storage?.local) throw new Error(STALE);
    if (patch === undefined) return chrome.storage.local.get(['app', 'run']);
    await chrome.storage.local.set(patch);
    return patch;
  }

  /** Waits until `check` returns something truthy, or gives up. */
  async function waitFor(check, timeout = 15000, step = 400) {
    for (let waited = 0; waited < timeout; waited += step) {
      const value = check();
      if (value) return value;
      await sleep(step);
    }
    return null;
  }

  // ---------------------------------------------------------------- reading

  /**
   * Material hides the real radio behind a styled element, so the input itself
   * has no size: what counts is whether the thing the user sees is on screen.
   */
  function onScreen(el) {
    for (let node = el; node && node !== document.body; node = node.parentElement) {
      const rect = node.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) return getComputedStyle(node).visibility !== 'hidden';
    }
    return false;
  }

  function readOptions() {
    return [...document.querySelectorAll('input[type="radio"], input[type="checkbox"], [role="radio"], [role="checkbox"], mat-radio-button, mat-checkbox')]
      .filter(onScreen)
      .map((el) => {
        const labelled = el.getAttribute('aria-label') || document.getElementById(el.getAttribute('aria-labelledby') ?? '')?.textContent;
        // The words sit next to the control, sometimes a couple of boxes away.
        const near = el.closest('label, mat-radio-button, mat-checkbox, [role="radio"], [role="checkbox"], li, tr') ?? el.parentElement;
        const label = (labelled || text(near) || text(el.parentElement) || '').slice(0, 200);
        return { el, label, checked: el.checked === true || el.getAttribute('aria-checked') === 'true' || el.classList.contains('mat-mdc-radio-checked') };
      })
      .filter((o) => o.label);
  }

  function readFields() {
    const all = readOptions();
    const groups = [...document.querySelectorAll('[role="radiogroup"], mat-radio-group, fieldset, form section')].filter((g) =>
      g.querySelector('input, [role="radio"], mat-radio-button'),
    );
    if (groups.length === 0) {
      return [{ question: text(document.querySelector('h1, h2')) || document.title, options: all.map((o) => o.label), els: all.map((o) => o.el), checked: all.map((o) => o.checked) }];
    }
    return groups
      .map((group) => {
        const mine = all.filter((o) => group.contains(o.el));
        const heading = text(group.querySelector('legend, h2, h3, [role="heading"]')) || text(group.previousElementSibling) || text(document.querySelector('h1, h2'));
        return { question: heading, options: mine.map((o) => o.label), els: mine.map((o) => o.el), checked: mine.map((o) => o.checked) };
      })
      .filter((f) => f.options.length > 0);
  }

  function readTextInputs() {
    return [...document.querySelectorAll('input[type="text"], input[type="email"], input:not([type])')]
      .filter((el) => onScreen(el) && !el.disabled && !el.readOnly)
      .map((el, index) => ({
        el,
        index,
        type: el.type,
        value: el.value,
        label:
          el.getAttribute('aria-label') ||
          document.getElementById(el.getAttribute('aria-labelledby') ?? '')?.textContent ||
          text(el.closest('label')) ||
          text(el.closest('div')?.previousElementSibling) ||
          el.placeholder ||
          '',
      }));
  }

  // ---------------------------------------------------------------- acting

  function choose(el) {
    (el.closest('label') ?? el).click();
    if (!el.checked && el.getAttribute('aria-checked') !== 'true') el.click();
    return el.checked === true || el.getAttribute('aria-checked') === 'true';
  }

  function type(el, value) {
    const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set;
    el.focus();
    setter ? setter.call(el, value) : (el.value = value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
    el.blur();
    return el.value === value;
  }

  /** Presses a button by the word written on it. */
  function pressButton(words) {
    const buttons = [...document.querySelectorAll('button, [role="button"]')].filter(
      (b) => !b.disabled && b.getAttribute('aria-disabled') !== 'true' && onScreen(b),
    );
    const hit = buttons.find((b) => words.some((w) => lower(b) === w || lower(b).startsWith(`${w} `)));
    if (!hit) return false;
    hit.click();
    return true;
  }

  /** Answers everything Ember is sure about on the page in front of us. */
  async function answerHere(app) {
    const fields = readFields();
    const inputs = readTextInputs();
    let done = 0;

    for (const t of rules.textAnswers(inputs, app)) {
      const input = inputs[t.index];
      if (input && !input.value && type(input.el, t.value)) done++;
    }

    if (/categor/i.test(document.body.innerText)) {
      const field = fields.find((f) => /gioco|game/i.test(f.options.join(' ')));
      const choice = field ? rules.categoryChoice(field.options) : -1;
      if (field && choice >= 0 && !field.checked[choice] && choose(field.els[choice])) done++;
    }

    for (const p of rules.plan({ url: location.href, title: document.title, fields, app })) {
      const field = fields.find((f) => f.question === p.question);
      if (field && !field.checked[p.option] && field.els[p.option] && choose(field.els[p.option])) done++;
    }

    const ages = fields.find((f) => /anni|age|years|et/i.test(f.options.join(' ')) && f.options.length >= 4);
    if (ages) {
      for (const i of rules.targetAudience(ages.options)) {
        if (!ages.checked[i] && choose(ages.els[i])) done++;
      }
    }
    return done;
  }

  /** Opens one App content section from the list page. */
  /** Everything on the page a person could click, ignoring Ember's own panel. */
  /**
   * The short pieces of text on the page, as a person reads them.
   *
   * Only elements that hold text and nothing else: one cheap pass, no style
   * computation. An earlier version measured every element on the page and
   * froze Play Console, which then showed its own error.
   */
  function labels() {
    const out = [];
    for (const el of document.querySelectorAll('span, a, button, div, li, td')) {
      if (el.childElementCount > 1 || el.closest('#ember-panel')) continue;
      const t = text(el);
      if (t && t.length < 60) out.push({ el, t: t.toLowerCase() });
      if (out.length > 800) break;
    }
    return out;
  }

  /** The thing to click to open a section: the shortest text that names it. */
  function rowLink(row) {
    const matches = labels()
      .filter(({ t }) => row.words.some((w) => t.includes(w)))
      .sort((a, b) => a.t.length - b.t.length);
    const hit = matches[0]?.el;
    return hit && onScreen(hit) ? hit : null;
  }

  async function openRow(row) {
    const before = location.href;
    const link = await waitFor(() => rowLink(row), 8000, 800);
    if (!link) return false;
    // The words sit inside the row; what answers to a click is the row itself.
    (link.closest('a[href], button, [role="link"], [role="button"], li, tr') ?? link).click();
    // The section is open once the address changed and something answerable is on screen.
    await waitFor(() => location.href !== before, 8000);
    await waitFor(() => readOptions().length > 0 || readTextInputs().length > 0, 12000);
    await sleep(1200);
    return true;
  }

  // ---------------------------------------------------------------- the run

  /** Ember running on this computer is the source of truth; storage is the fallback. */
  async function currentApp() {
    const fresh = await appFromEmber();
    if (fresh) {
      await store({ app: fresh });
      return fresh;
    }
    return (await store()).app ?? null;
  }

  async function loadRules() {
    if (!chrome?.runtime?.id) throw new Error(STALE);
    rules ??= await import(chrome.runtime.getURL('rules.js'));
  }

  const hubUrl = () => `${location.href.split('/app-content')[0].split('/app-dashboard')[0]}/app-content`;

  /** Walks every section: open, answer, save, next. Survives page reloads. */
  async function runAll() {
    await loadRules();
    const app = await currentApp();
    const { run } = await store();
    if (!app) return render(needAppHtml());
    if (!run?.active) return;

    for (let i = run.index; i < ROWS.length; i++) {
      const row = ROWS[i];
      const current = (await store()).run;
      if (!current?.active) return render(`<p>Fermato. ${summary(current)}</p>`);

      render(`<p>Sto compilando <b>${row.name}</b> (${i + 1} di ${ROWS.length})…</p>${listHtml(current.results)}<div class="ember-actions"><button class="ember-stop">Ferma</button></div>`);
      wireStop();

      // The sections are listed on the dashboard and on the App content page: if the
      // link is not here, try the other page once before giving up on this section.
      if (!rowLink(row) && !current.searched) {
        await store({ run: { ...current, searched: true } });
        location.assign(location.href.includes('/app-content') ? `${hubUrl().replace('/app-content', '')}/app-dashboard` : hubUrl());
        return; // the script starts again on the new page and carries on
      }

      let answered = 0;
      let saved = false;
      const short = (t) => t.replace(/\s+/g, ' ').trim().slice(0, 40);
      let seen = 'sezione non trovata';
      const opened = await openRow(row);
      if (opened) {
        // The labels Ember read: without them a section that fills nothing cannot be understood.
        const options = readOptions().map((o) => short(o.label));
        seen = `${readFields().length} domande · ${options.slice(0, 5).join(' | ')}`;
        // The content rating questionnaire is several screens long.
        for (let screen = 0; screen < 14; screen++) {
          answered += await answerHere(app);
          await sleep(800);
          // "Classificazione contenuti" starts behind a button before any question appears.
          if (!pressButton(['avanti', 'next', 'continua', 'continue', 'avvia questionario', 'inizia', 'start'])) break;
          await sleep(2500);
        }
        saved = pressButton(['salva', 'save', 'invia', 'submit']);
        await sleep(3000);
      }

      const results = [...(current.results ?? []), { id: row.id, name: row.name, answered, saved, seen }];
      await store({ run: { ...current, index: i + 1, searched: false, results } });
      history.pushState({}, '', hubUrl());
      location.assign(hubUrl());
      return; // continues after the page settles
    }

    const finished = (await store()).run;
    await store({ run: { ...finished, active: false } });
    render(`<p><b>Finito.</b> ${summary(finished)}</p>${listHtml(finished.results)}<p class="ember-small">Controlla le sezioni in Play Console: quello che hai dichiarato è a tuo nome.</p>`);
  }

  const summary = (run) => `${(run?.results ?? []).filter((r) => r.saved).length} sezioni salvate su ${ROWS.length}.`;

  const listHtml = (results = []) =>
    `<ul class="ember-list">${results
      .map((r) => `<li>${r.saved ? '✓' : '✗'} <b>${r.name}</b> <span class="ember-small">${r.answered} risposte${r.seen ? ` · ${r.seen}` : ''}</span></li>`)
      .join('')}</ul>`;

  const needAppHtml = () =>
    "<p>Non trovo l'app. Apri Ember sul computer, vai sull'app, scheda <b>App content</b>, e premi <b>Copy for the browser helper</b>. Poi ripremi qui.</p>" +
    '<p class="ember-small">Ember deve essere aperto: è lui a dire all\'estensione com\'è fatta l\'app.</p>';

  // ---------------------------------------------------------------- panel

  function panel() {
    let box = document.getElementById('ember-panel');
    if (box) return box;
    box = document.createElement('div');
    box.id = 'ember-panel';
    document.body.appendChild(box);
    return box;
  }

  function render(html) {
    panel().innerHTML = `<div class="ember-head"><span class="ember-dot"></span><b>Ember</b><button class="ember-x" title="Chiudi">×</button></div>${html}`;
    panel().querySelector('.ember-x').addEventListener('click', () => document.getElementById('ember-panel')?.remove());
  }

  function wireStop() {
    panel()
      .querySelector('.ember-stop')
      ?.addEventListener('click', async () => {
        const { run } = await store();
        await store({ run: { ...run, active: false } });
        render(`<p>Fermato. ${summary(run)}</p>${listHtml(run?.results)}`);
      });
  }

  /** The panel shown when the user presses the Ember button. */
  async function offer() {
    await loadRules();
    const app = await currentApp();
    if (!app) return render(needAppHtml());
    render(
      `<p>App: <b>${app.name}</b></p>` +
        `<div class="ember-actions"><button class="ember-go">Compila questa pagina</button></div>` +
        `<div class="ember-actions"><button class="ember-all">Fai tutto da solo</button></div>` +
        `<p class="ember-small">«Fai tutto» apre le ${ROWS.length} sezioni una per una, risponde e salva. Puoi fermarlo quando vuoi.</p>`,
    );
    panel()
      .querySelector('.ember-go')
      .addEventListener('click', async () => {
        const done = await answerHere(app);
        render(`<p><b>${done}</b> risposte selezionate. Rileggile e premi <b>Salva</b> nella pagina.</p>`);
      });
    panel()
      .querySelector('.ember-all')
      .addEventListener('click', async () => {
        await store({ run: { active: true, index: 0, results: [] } });
        runAll().catch((e) => render(`<p>Errore: ${e.message}</p>`));
      });
  }

  const button = document.createElement('button');
  button.id = 'ember-button';
  button.textContent = 'Ember';
  button.title = 'Compila le risposte con Ember';
  button.addEventListener('click', () => offer().catch((e) => render(`<p>Errore: ${e.message}</p>`)));
  document.documentElement.appendChild(button);

  // A run in progress carries on by itself after each page change.
  store()
    .then(({ run }) => run?.active && runAll())
    .catch(() => {});
})();
