# Ember Fabbrica: tante app insieme, dall'idea agli store

Branch `feature/fabbrica` (parte da `ux/semplice`). Piano scritto il 2026-10-06, eseguito per fasi; ogni fase = un commit, a fine fase analisi e test passano.

## Obiettivo

Un'unica schermata con una **casella grande** dove si incolla o si trascina tutto (idee, elenchi, piani, prompt, file) oppure si chiede all'AI di inventare idee su un tema. Un **agente supervisore** legge tutto, lo divide in **fino a 100 app distinte**, scarta le troppo simili, sceglie per ognuna il motore AI e se è piccola o grande, e mostra il riepilogo. Dopo il tuo OK Ember porta **tutte le app avanti nello stesso tempo**, ognuna con il suo agente, fino alle bozze su Google Play e ai test su App Store, senza che nessuno resti ad aspettare davanti a una app alla volta. L'utente vede a colpo d'occhio cosa sta succedendo, cosa è pronto, cosa è fermo e **cosa serve da lui**.

## Decisioni prese (2026-10-06)

1. **Sempre in bozza e in test, mai in produzione.** Google Play: canale **test interno**, versione in **bozza**. App Store: **TestFlight**. La Fabbrica non pubblica in produzione e non invia in revisione: quello si farà a mano, app per app, quando decidi tu.
2. **Gli store si riempiono nei giorni, non in un giorno.** Le app si costruiscono tutte (fino a 100 al giorno se il PC regge), ma il caricamento su Play e su App Store ha un **tetto giornaliero** (predefinito 10 app al giorno per store, regolabile). Superato il tetto le app aspettano pronte e riprendono da sole il giorno dopo.
3. **Tutto automatico quello che si può**: logo, screenshot, schede store nelle lingue, build, caricamento. Quello che solo tu puoi fare finisce nella lista **"Serve te"**.

Motori disponibili (abbonamenti già dell'utente): **Claude Code** (codice), **Qwen Code** (codice), **Gemini CLI** (codice), **ChatGPT/Codex** (loghi e immagini, e codice se serve).

## Cosa c'è già (verificato sul codice) e cosa manca

| Pezzo | Oggi | Manca per 100 app |
|---|---|---|
| Creare l'app | Flusso "Crea app" **guidato dal client**: se si chiude la schermata si perde il filo (`app_builder.dart`, 1343 righe) | Un orchestratore **nel Runner** che non dipende da nessuna schermata |
| Code in parallelo | `JobManager`: un solo job per workspace; il motore agente va avviato a mano, app per app | Scheduler globale con **corsie** (agenti per motore, build, immagini, store) e limiti |
| Motori | claude-code, codex, gemini-cli (CLI con abbonamento); Qwen solo via OpenRouter (API a pagamento) | **Qwen Code** come motore CLI con abbonamento/OAuth |
| Loghi | `logos.ts` (SVG disegnati da Claude/GPT/Gemini), per app | Chiamata automatica, scelta del migliore, applicazione |
| Scheda store | Scritta e tradotta **dal client** (`listing_ai.dart`) | Stessa cosa nel Runner, stesso formato `store/listing.json` |
| Pubblicare | Rotte per app: `play/publish`, `appstore/autopublish` | Orchestrazione per lotto con ritmo e blocchi chiari |
| Schermata | Home = una sola app alla volta | **Fabbrica**: cruscotto, nuovo lotto, dettaglio app, collegamenti e capacità |

## Limiti reali (non aggirabili: la Fabbrica li gestisce, non li nasconde)

1. **Questo PC ha 16 core e 8 GB di RAM.** Una build Android (Gradle) usa 2-3 GB: in pratica 2 alla volta. "100 insieme" vuol dire 100 app **in lavorazione ordinata**: gli agenti AI (rete) vanno 4-6 alla volta, le build 1-2; il resto aspetta in coda e il cruscotto dice quanto manca. I limiti si regolano e partono dalla RAM libera misurata.
2. **Google Play non permette di creare un'app via API.** La prima volta si crea in Play Console (nome, lingua, gratis/a pagamento). La Fabbrica prepara tutto (nome, pacchetto, testi) e mette l'app nella lista **"Serve te"**; appena esiste, il caricamento riparte da solo. Un account Play *personale* nuovo deve anche fare un test chiuso con 12 tester per 14 giorni prima della produzione: per questo il caricamento è sul canale **interno** e in **bozza** (decisione 1).
3. **App Store: il file iPhone si costruisce solo su un Mac** e il record dell'app si crea in App Store Connect. Su Windows lo stadio iPhone resta "serve un Mac" (con il codice già salvato su GitHub per riprendere dal Mac); su un Mac gira da solo.
4. **Apple e Google rifiutano le app fatte in serie e quasi uguali** (Apple 4.3 "Spam", Google "Minimum functionality / Spam"). La Fabbrica controlla che idee, nomi e pacchetti siano distinti, **non invia mai in revisione né in produzione** e carica sugli store con un **tetto giornaliero** (decisioni 1 e 2).
5. **Gli abbonamenti hanno limiti d'uso.** Se un motore risponde "limite raggiunto" la sua corsia si ferma per un tempo e le app passano ad un altro motore (se il lotto ne usa più d'uno).

## Architettura

```
Flutter (apps/ide)                              Runner (apps/runner)
┌────────────────────────┐   REST /v1/factory   ┌─────────────────────────────────────────┐
│ Fabbrica (nuova UI)    │◄────polling 2 s─────►│ factory/                                │
│  · cruscotto           │                      │  store.ts      stato su disco (atomico) │
│  · nuovo lotto         │                      │  scheduler.ts  corsie, priorità, pausa  │
│  · dettaglio app       │                      │  pipeline.ts   11 stadi, retry, ripresa │
│  · collegamenti        │                      │  ops.ts        azioni reali (servizi)   │
└────────────────────────┘                      │  ideas.ts      elenco/AI → idee uniche  │
                                                │  listing.ts    scheda store + lingue    │
                                                │  capacity.ts   CPU/RAM/disco → limiti   │
                                                └──────────────┬──────────────────────────┘
                                                               │ riusa (stessi servizi e rotte)
                                    Services · JobManager · ClaudeCodeEngine · logos · screenshots · play · appstore
```

**Stadi di ogni app** (ognuno ha la sua corsia):

| # | Stadio | Corsia | Cosa fa |
|---|---|---|---|
| 1 | `create` | leggera | `flutter create` con nome e pacchetto unici |
| 2 | `code` | agente:<motore> | il motore scrive l'app (stesse istruzioni del "Crea app") |
| 3 | `verify` | leggera + agente | `pub get` + `analyze`, fino a 2 giri di correzione |
| 4 | `preview` | build | build web (anche per gli screenshot) |
| 5 | `logo` | immagini | loghi (ChatGPT di default), scelta e applicazione |
| 6 | `shots` | schermate | screenshot dello store da Chrome headless |
| 7 | `listing` | agente testo | titolo, descrizioni, privacy, lingue |
| 8 | `android` | build | AAB firmato |
| 9 | `play` | store | caricamento su Play, canale interno, in bozza (se l'app esiste in Console, altrimenti "Serve te") |
| 10 | `ios` | build | file iPhone (solo Mac, altrimenti "serve un Mac") |
| 11 | `appstore` | store | scheda e build su App Store Connect (TestFlight); mai invio in revisione |

**Dipendenze**: dopo `listing` la strada si divide, `android → play` e `ios → appstore` vanno **indipendenti** (un'app ferma su "serve te" per Play non blocca la parte iPhone). Il lotto sceglie fin dove arrivare (solo app · + logo, screenshot e schede · + Android e Play · + iPhone e App Store): gli stadi fuori scelta partono già come "saltati".

Regole dello scheduler: gli stadi più avanti passano per primi (si **chiudono** le app invece di aprirne cento a metà); al massimo N app "in volo" (default 12) per tenere disco e RAM sotto controllo; un'app ferma per "serve te" o in attesa del tetto giornaliero degli store **non occupa** un posto "in volo"; **tetto giornaliero degli store** (decisione 2): il posto si prenota quando il caricamento parte e si restituisce se non è andato a buon fine, a mezzanotte (ora del PC) si azzera; spazio libero sotto 10 GB = pausa e pulizia delle cartelle `build` delle app finite; un errore ferma **solo quell'app**; dopo un riavvio del Runner il lotto riparte in **pausa** (non brucia abbonamenti da solo).

**Stato per app**: 11 stadi × {in attesa, in coda, in corso, fatto, saltato, bloccato, fallito}, tentativi, ultimo messaggio, ultime righe di log, costo. Salvato in `DATA_DIR/factory/<utente>.json` ad ogni cambio (scrittura atomica, come lo store dei progetti).

## Interfaccia (stile "Ember calmo", solo componenti di `lib/ui`)

Navigazione nuova: barra laterale da 840 px in su, barra in basso sotto; voci **Fabbrica · Nuovo lotto · Le mie app · Collegamenti · Impostazioni**. La home semplice ("descrivi un'app") resta, come "Le mie app".

1. **Fabbrica (cruscotto)**: striscia di numeri (totale, in corso, in coda, serve te, pronte, su Play, su App Store), barra di avanzamento complessiva con tempo stimato, Pausa/Riprendi, capacità in uso; sotto l'elenco di tutte le app come **tessere** (griglia) o **righe** (tabella densa) con il percorso a 11 puntini, filtri (stato, lotto, motore), ricerca, selezione multipla con azioni di gruppo (riprova, pausa, annulla, elimina, pubblica).
2. **Serve te**: la coda delle cose che solo l'utente può fare (creare l'app in Play Console, un accesso scaduto, una chiave), con i dati da copiare e "Fatto, continua".
3. **Nuovo lotto** (3 passi): *Casella grande* (incolla o trascina testi, elenchi, piani, prompt, file · oppure "inventa N idee su questo tema"; il **supervisore** li trasforma in schede di app) → *Ricetta* (motori e quanti per motore, chi disegna i loghi, fino a dove arrivare, tetto giornaliero degli store; Play sempre interno in bozza, App Store sempre TestFlight) → *Verifica e avvia* (le app proposte dal supervisore con nome, cosa fa, piccola/grande, motore; scarti e avvisi di somiglianza; stima di tempo e di uso; tu togli, cambi o confermi).
4. **Dettaglio app** (pannello laterale o pagina): percorso a 11 stadi con stato, log, azioni (riprova da qui, apri app, apri anteprima), nome e pacchetto.
5. **Collegamenti e capacità**: cosa è pronto (Claude, Qwen, Gemini, ChatGPT, Flutter, Android, chiave Play, chiave Apple, Mac) con il pulsante per accedere, e i limiti di parallelismo regolabili.

Cinque lingue complete (en, it, es, fr, ar), nessun testo nel codice, nessun colore fuori da `lib/ui`, nessuna schermata sopra 500 righe: i test esistenti lo impongono.

## Fasi

0. **Base**: branch, questo piano.
1. **Runner: cuore** — tipi, scheduler a corsie, stato su disco, pipeline con operazioni iniettabili, test (senza AI né rete).
2. **Runner: operazioni vere** — Qwen Code come motore, supervisore e idee (`supervisor.ts`, `ideas.ts`: testo libero → schede di app uniche), scheda store, creare, scrivere, verificare, anteprima, logo, screenshot, AAB, Play (interno, bozza), iPhone, App Store (TestFlight); capacità del PC.
3. **Runner: rotte** — `/v1/factory/*` (piano del supervisore, lotti, stato, azioni, collegamenti), simulazione per provare la UI senza consumare abbonamenti.
4. **Flutter: dati** — modelli, client, provider con polling.
5. **Flutter: schermate** — guscio di navigazione, cruscotto, Serve te, nuovo lotto, dettaglio, collegamenti; parole nelle cinque lingue.
6. **Prova** — analisi, test, build web, percorso reale contro il Runner (con simulazione di 100 app), schermate in `docs/ux/fabbrica`.
7. **Documenti** — ARCHITECTURE, ROADMAP, API aggiornati.

## Verifica

Runner (solo file di test mirati, mai tutta la suite: scrive in `~/.ember`): `npx vitest run src/factory/...` con Node 22 (`C:\Users\kmrnn\tools\node-v22.23.3-win-x64`) e `tsc --noEmit`.
App: `C:\Users\kmrnn\tools\flutter\bin\flutter.bat analyze` e `test` da `apps/ide`.
Prova a mano: Runner con `EMBER_FACTORY_SIMULATE=1`, 100 app finte, cruscotto a 390, 900 e 1280 px, italiano e arabo.
