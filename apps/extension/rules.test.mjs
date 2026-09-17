import assert from 'node:assert/strict';
import test from 'node:test';
import { isWantedOption, normalize, plan, targetAudience } from './rules.js';

const app = { name: 'Beauty Camera', ads: false, account: true };

test('short answers match a whole label, not a word inside it', () => {
  assert.equal(isWantedOption('No', ['no']), true);
  assert.equal(isWantedOption('Sì', ['si']), true);
  // The trap: "Nome" and "Non lo so" both start with the letters of "no".
  assert.equal(isWantedOption('Nome utente', ['no']), false);
  assert.equal(isWantedOption('Non lo so', ['no']), false);
  assert.equal(normalize(' Città  PERÙ '), "citta peru");
});

test('answers the ads question from what the app really uses', () => {
  const page = { url: 'https://play.google.com/console/u/0/developers/1/app/2/app-content/ads', title: 'Annunci', app };
  const fields = [{ question: 'La tua app contiene annunci?', options: ['Sì, la mia app contiene annunci', 'No, la mia app non contiene annunci'] }];
  assert.deepEqual(plan({ ...page, fields })[0].option, 1);

  const withAds = plan({ ...page, fields, app: { ...app, ads: true } })[0];
  assert.equal(withAds.option, 0);
});

test('says no to every content the app does not have', () => {
  const proposals = plan({
    url: 'https://play.google.com/console/u/0/developers/1/app/2/app-content/rating',
    title: 'Classificazione contenuti',
    app,
    fields: [
      { question: "L'app contiene violenza realistica?", options: ['Sì', 'No'] },
      { question: 'Contenuti sessuali o nudità?', options: ['Sì', 'No'] },
      { question: 'Riferimenti a droghe, alcol o tabacco?', options: ['Sì', 'No'] },
      { question: 'Qual è il nome del tuo studio?', options: ['Sì', 'No'] },
    ],
  });
  assert.equal(proposals.length, 3, 'the question Ember cannot answer is left alone');
  for (const p of proposals) assert.equal(p.label, 'No');
});

test('leaves a page it does not understand untouched', () => {
  const proposals = plan({
    url: 'https://play.google.com/console/u/0/developers/1/app/2/app-content/app-access',
    title: 'Dettagli di accesso',
    app,
    fields: [{ question: 'Come accede un revisore alla tua app?', options: ['Con credenziali', 'Senza credenziali'] }],
  });
  assert.deepEqual(proposals, []);
});

test('ticks 13 and over, never the children age groups', () => {
  const ages = ['5 anni e meno', '6-8', '9-12', '13-15', '16-17', '18 e oltre'];
  assert.deepEqual(targetAudience(ages), [3, 4, 5]);
});
