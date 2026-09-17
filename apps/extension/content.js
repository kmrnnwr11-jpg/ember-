/**
 * Ember inside Play Console.
 *
 * It never acts on its own: the user opens an App content page, presses the
 * Ember button, reads what Ember proposes, and confirms. Ember then selects the
 * options — and stops. Saving stays the user's own click, so nothing is ever
 * declared to Google without a person having read it.
 *
 * The page is a single-page app with generated ids, so questions and answers
 * are found by the words on screen, never by id or CSS path.
 */

(() => {
  if (window.__emberPlayHelper) return;
  window.__emberPlayHelper = true;

  let rules = null;

  /**
   * Reloading the extension leaves open tabs holding a dead connection to it:
   * chrome.* is then gone or throws. Say what to do instead of a raw error.
   */
  const STALE = 'Ho aggiornato Ember: ricarica questa pagina (F5) e ripremi il pulsante.';

  async function storedApp() {
    if (!chrome?.runtime?.id || !chrome?.storage?.local) throw new Error(STALE);
    try {
      return (await chrome.storage.local.get('app')).app;
    } catch {
      throw new Error(STALE);
    }
  }

  const text = (el) => (el?.innerText ?? el?.textContent ?? '').replace(/\s+/g, ' ').trim();

  /** Radio buttons and checkboxes on screen, with the label a person reads. */
  function readOptions() {
    const inputs = [...document.querySelectorAll('input[type="radio"], input[type="checkbox"], [role="radio"], [role="checkbox"]')];
    return inputs
      .filter((el) => el.offsetParent !== null || el.getClientRects().length > 0)
      .map((el) => {
        const labelled = el.getAttribute('aria-label') || document.getElementById(el.getAttribute('aria-labelledby') ?? '')?.textContent;
        const label = labelled || text(el.closest('label')) || text(el.parentElement) || text(el.closest('[role="radiogroup"] > *'));
        return { el, label: (label ?? '').slice(0, 200) };
      })
      .filter((o) => o.label);
  }

  /** Groups the options under the question they belong to. */
  function readFields() {
    const groups = [...document.querySelectorAll('[role="radiogroup"], fieldset, form section')].filter((g) => g.querySelector('input, [role="radio"]'));
    const all = readOptions();
    if (groups.length === 0) return [{ question: text(document.querySelector('h1, h2')) || document.title, options: all.map((o) => o.label), els: all.map((o) => o.el) }];
    return groups
      .map((group) => {
        const mine = all.filter((o) => group.contains(o.el));
        const heading = text(group.querySelector('legend, h2, h3, [role="heading"]')) || text(group.previousElementSibling) || text(document.querySelector('h1, h2'));
        return { question: heading, options: mine.map((o) => o.label), els: mine.map((o) => o.el) };
      })
      .filter((f) => f.options.length > 0);
  }

  /** Text boxes on screen, with the label a person reads next to them. */
  function readTextInputs() {
    return [...document.querySelectorAll('input[type="text"], input[type="email"], input:not([type])')]
      .filter((el) => (el.offsetParent !== null || el.getClientRects().length > 0) && !el.disabled && !el.readOnly)
      .map((el, index) => ({
        el,
        index,
        type: el.type,
        label:
          el.getAttribute('aria-label') ||
          document.getElementById(el.getAttribute('aria-labelledby') ?? '')?.textContent ||
          text(el.closest('label')) ||
          text(el.closest('div')?.previousElementSibling) ||
          el.placeholder ||
          '',
      }));
  }

  /** Types into a box the way a person would, so the page notices the change. */
  function type(el, value) {
    const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set;
    el.focus();
    setter ? setter.call(el, value) : (el.value = value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
    el.blur();
    return el.value === value;
  }

  function panel() {
    let box = document.getElementById('ember-panel');
    if (box) return box;
    box = document.createElement('div');
    box.id = 'ember-panel';
    document.body.appendChild(box);
    return box;
  }

  function close() {
    document.getElementById('ember-panel')?.remove();
  }

  function render(html) {
    panel().innerHTML = `<div class="ember-head"><span class="ember-dot"></span><b>Ember</b><button class="ember-x" title="Chiudi">×</button></div>${html}`;
    panel().querySelector('.ember-x').addEventListener('click', close);
  }

  /** Clicks an option the way a person would, and reports whether it took. */
  function choose(el) {
    const target = el.closest('label') ?? el;
    target.click();
    if (!el.checked && el.getAttribute('aria-checked') !== 'true') el.click();
    return el.checked || el.getAttribute('aria-checked') === 'true';
  }

  async function propose() {
    const app = await storedApp();
    rules ??= await import(chrome.runtime.getURL('rules.js'));
    if (!app) {
      render('<p>Prima incolla i dati dell\'app: apri Ember, scheda <b>Contenuti dell\'app</b>, premi <b>Copia per l\'estensione</b>, poi clicca l\'icona di Ember qui nel browser e incolla.</p>');
      return;
    }
    const fields = readFields();
    const proposals = rules.plan({ url: location.href, title: document.title, fields, app });

    // "Target audience" is a list of ages, not a yes/no question.
    const ageField = fields.find((f) => /età|age|anni|years/i.test(f.options.join(' ')) && f.options.length >= 4);
    const ages = ageField ? rules.targetAudience(ageField.options) : [];

    // The contact address, and the category of the content rating questionnaire.
    const inputs = readTextInputs();
    const texts = rules.textAnswers(inputs, app).filter((t) => !inputs[t.index].el.value);
    const categoryField = /categor/i.test(document.body.innerText) ? fields.find((f) => /gioco|game/i.test(f.options.join(' '))) : null;
    const category = categoryField ? rules.categoryChoice(categoryField.options) : -1;

    if (proposals.length === 0 && ages.length === 0 && texts.length === 0 && category < 0) {
      render(`<p>Su questa pagina non c'è niente che io possa compilare con certezza: rispondi tu.</p><p class="ember-small">App: ${app.name}</p>`);
      return;
    }

    const list = [
      ...texts.map((t) => `<li><b>${t.value}</b><br><span class="ember-small">${inputs[t.index].label || 'Campo di testo'}</span></li>`),
      ...(category >= 0 ? [`<li><b>${categoryField.options[category]}</b><br><span class="ember-small">Categoria</span></li>`] : []),
      ...proposals.map((p) => `<li><b>${p.label}</b><br><span class="ember-small">${p.question}</span></li>`),
      ...ages.map((i) => `<li><b>${ageField.options[i]}</b><br><span class="ember-small">Fascia d'età</span></li>`),
    ].join('');
    render(
      `<p>Per <b>${app.name}</b> risponderei così:</p><ul class="ember-list">${list}</ul>` +
        `<p class="ember-small">Ember seleziona le risposte e si ferma: <b>Salva lo premi tu</b> dopo aver riletto.</p>` +
        `<div class="ember-actions"><button class="ember-go">Seleziona</button></div>`,
    );

    panel().querySelector('.ember-go').addEventListener('click', () => {
      let done = 0;
      let failed = 0;
      for (const t of texts) {
        if (type(inputs[t.index].el, t.value)) done++;
        else failed++;
      }
      if (category >= 0 && categoryField.els[category]) {
        if (choose(categoryField.els[category])) done++;
        else failed++;
      }
      for (const p of proposals) {
        const field = fields.find((f) => f.question === p.question);
        const el = field?.els?.[p.option];
        if (el && choose(el)) done++;
        else failed++;
      }
      for (const i of ages) {
        const el = ageField.els[i];
        if (el && !(el.checked || el.getAttribute('aria-checked') === 'true') && choose(el)) done++;
      }
      render(
        `<p><b>${done}</b> risposte selezionate${failed ? `, ${failed} non riuscite` : ''}.</p>` +
          `<p>Adesso rileggile e premi <b>Salva</b> nella pagina.</p>`,
      );
    });
  }

  const button = document.createElement('button');
  button.id = 'ember-button';
  button.textContent = 'Ember';
  button.title = "Compila le risposte di questa pagina con Ember";
  button.addEventListener('click', () => propose().catch((e) => render(`<p>Errore: ${e.message}</p>`)));
  document.documentElement.appendChild(button);
})();
