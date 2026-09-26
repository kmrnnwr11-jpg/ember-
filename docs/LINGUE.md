# Le dieci lingue — regola fissa per ogni app creata con Ember

Ogni app che Ember costruisce parla **dieci lingue** e sceglie da sola quella
del telefono. Non è una funzione da chiedere volta per volta: vale sempre,
per ogni app, senza eccezioni.

La regola vive nel codice, non solo qui: `AppBuilder.languagesBlock` in
[`apps/ide/lib/features/create/app_builder.dart`](../apps/ide/lib/features/create/app_builder.dart)
viene allegata a **ogni** build e a ogni modifica, insieme al blocco
`NEEDS YOU`. Un test la tiene lì.

## Le dieci lingue

| Codice | Lingua | Perché |
|--------|--------|--------|
| `en` | Inglese | **predefinita e riserva** |
| `it` | Italiano | mercato di casa |
| `es` | Spagnolo | Spagna + America Latina |
| `pt-BR` | Portoghese (Brasile) | Brasile, enorme su Play Store |
| `fr` | Francese | Francia, Belgio, Africa francofona |
| `de` | Tedesco | mercato che spende |
| `hi` | Hindi | India |
| `ar` | Arabo | Medio Oriente e Nord Africa |
| `id` | Indonesiano | Indonesia, fra i primi mercati Android |
| `ru` | Russo | Russia e Asia centrale |

Insieme coprono la gran parte degli utenti Android nel mondo.

Se una app punta a un pubblico particolare (per esempio l'urdu per il
Pakistan), si **sostituisce** una di queste, non se ne aggiunge un'undicesima
senza motivo: ogni lingua in più è una colonna di testo da mantenere per
sempre.

## Come, in pratica

- `flutter_localizations` + `l10n.yaml` + un file `.arb` per lingua in
  `lib/l10n`, generati con `gen-l10n` e letti da `AppLocalizations`.
- **Nessun testo visibile scritto dentro un widget.** Nemmeno un'etichetta di
  un bottone, un errore, uno snackbar. Tutto dai file `.arb`.
- Ogni chiave esiste in tutti e dieci i file. Se una traduzione manca si
  ripiega sull'inglese, non si mostra il nome della chiave.
- Telefono impostato su una lingua fuori elenco → l'app apre in inglese.
- **L'arabo si legge da destra a sinistra**: i layout usano `start`/`end`, mai
  `left`/`right`, altrimenti in arabo si scompongono.
- Nelle impostazioni l'utente può scegliere la lingua a mano, e la scelta
  resta.
- Anche i testi della scheda del negozio (titolo, descrizione breve e lunga)
  vanno nelle stesse dieci lingue.

## Perché all'inizio e non dopo

Tradurre dopo è riscrivere. Quando qualche centinaio di stringhe è già
sparso dentro i widget, tirarle fuori costa più che aver fatto le cose per
bene dal primo giorno — e di solito finisce che non si traduce affatto.
Detta prima della prima riga di codice, non costa niente.
