/**
 * What to answer on each Play Console "App content" page, and how to recognise
 * the right button on screen. Pure functions: no DOM, no chrome APIs, so this
 * file is testable on its own (see rules.test.mjs).
 *
 * Play Console is a single-page app whose element ids change with every
 * release, so nothing here matches on ids: answers are found by the words the
 * user reads, in the language the console is showing.
 */

/** Words that mean "yes" and "no", in the languages Play Console is used in here. */
const YES = ['sì', 'si', 'yes', 'oui', 'sí', 'نعم'];
const NO = ['no', 'non', 'لا'];

/** One question Ember can answer, with the phrases that identify it. */
const QUESTIONS = [
  {
    id: 'ads',
    page: /app-content\/ads|annunci/i,
    asks: ['contiene annunci', 'contains ads', 'contient des annonces', 'contiene anuncios'],
    answer: (app) => (app.ads ? YES : NO),
    why: (app) => (app.ads ? 'The app shows ads' : 'No ad library is used by the app'),
  },
  {
    id: 'government',
    page: /government|governative/i,
    asks: ['app governativa', 'government app', 'application gouvernementale', 'app gubernamental'],
    answer: () => NO,
    why: () => 'The app is not published on behalf of a government body',
  },
  {
    id: 'financial',
    page: /financial|finanziarie/i,
    asks: ['funzionalità finanziarie', 'financial features', 'fonctionnalités financières', 'funciones financieras'],
    answer: () => ['non offre', 'does not provide', 'ne propose pas', 'no ofrece', ...NO],
    why: () => 'Loans, crypto and payments only; in-app products are not a financial feature',
  },
  {
    id: 'news',
    page: /news|notizie/i,
    asks: ['app di notizie', 'news app', 'application d’actualités', 'app de noticias'],
    answer: () => NO,
    why: () => 'The app is not a news app',
  },
  {
    id: 'health',
    page: /health|salute/i,
    asks: ['salute', 'health'],
    answer: () => NO,
    why: () => 'The app has no medical, wellbeing or health-research features',
  },
];

/** The content rating questionnaire: everything a photo editor does not do. */
const RATING_NO = [
  'violenza',
  'violence',
  'sesso',
  'sexual',
  'sessuale',
  'nudità',
  'nudity',
  'parolacce',
  'profanity',
  'linguaggio volgare',
  'droghe',
  'drugs',
  'alcol',
  'alcohol',
  'tabacco',
  'tobacco',
  'gioco d’azzardo',
  'gambling',
  'scommesse',
  'orrore',
  'horror',
  'spaventos',
  'crimin',
  'crime',
  'discriminazione',
  'hate',
];

/** Text as it is compared: lowercase, no accents, single spaces. */
export function normalize(text) {
  return String(text ?? '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[’']/g, "'")
    .replace(/\s+/g, ' ')
    .trim();
}

const has = (haystack, needle) => normalize(haystack).includes(normalize(needle));

/** True when this option's label is one of the wanted answers. */
export function isWantedOption(label, wanted) {
  const text = normalize(label);
  if (!text) return false;
  return wanted.some((w) => {
    const want = normalize(w);
    // "No" must not match "Nome" or "Non lo so": short answers match the whole label.
    return want.length <= 3 ? text === want || text.startsWith(`${want} `) || text.startsWith(`${want},`) : text.includes(want);
  });
}

/**
 * What to do on the page the user is looking at.
 * `fields` are the questions read from the page: { question, options: [label] }.
 * Returns one proposal per field Ember is sure about.
 */
export function plan({ url, title, fields, app }) {
  const where = `${url} ${title ?? ''}`;
  const proposals = [];

  const rating = /rating|classificazione|questionnaire|questionario/i.test(where);
  for (const field of fields) {
    const question = field.question ?? '';
    let wanted = null;
    let why = '';

    if (rating && RATING_NO.some((w) => has(question, w))) {
      wanted = NO;
      why = 'A photo editor has none of this content';
    } else {
      const match = QUESTIONS.find((q) => q.page.test(where) || q.asks.some((a) => has(question, a)));
      if (match && (match.page.test(where) || match.asks.some((a) => has(question, a)))) {
        wanted = match.answer(app);
        why = match.why(app);
      }
    }
    if (!wanted) continue;

    const option = (field.options ?? []).findIndex((o) => isWantedOption(o, wanted));
    if (option < 0) continue;
    proposals.push({ question, option, label: field.options[option], why });
  }
  return proposals;
}

/** Ages to tick on "Target audience": 13 and over, never the children's groups. */
export function targetAudience(labels) {
  const wanted = [];
  labels.forEach((label, index) => {
    const numbers = normalize(label).match(/\d+/g)?.map(Number) ?? [];
    const youngest = numbers.length ? Math.min(...numbers) : null;
    // "18 e oltre" has one number; "13-15" has two; anything below 13 stays off.
    if (youngest !== null && youngest >= 13) wanted.push(index);
  });
  return wanted;
}
