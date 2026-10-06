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

## API del Runner (`/v1/factory`, tutte autenticate come le altre rotte `/v1`)

Stadi (ordine di visualizzazione): `create, code, verify, preview, logo, listing, shots, android, play, ios, appstore`.
Motori: `claude-code, codex, gemini-cli, qwen-code`. Stato app: `queued | running | needs_you | done | failed | cancelled`.
Stato stadio: `pending | queued | running | done | skipped | blocked | failed` (uno stadio fuori dall'obiettivo del lotto è `skipped` con `message: "outside"`).
Obiettivo (`recipe.goal`): `app | assets | android | ios` (ognuno include i precedenti; `ios` = tutto). Play sempre canale interno in bozza, App Store sempre TestFlight: non c'è nessuna opzione.
I testi che il Runner scrive (`title`, `detail`, `message`, righe di log) sono in inglese e vanno mostrati solo come ripiego: l'interfaccia deve usare le proprie parole in base a `kind`, `stage`, `state`.

### Stato — `GET /v1/factory?rev=N`
Con `rev=N` uguale a quello corrente risponde `{ "unchanged": true, "rev": N }`; altrimenti:
```json
{
  "rev": 482, "paused": false, "interrupted": false, "lowDisk": false, "simulated": false,
  "summary": { "total": 100, "queued": 61, "running": 12, "needsYou": 3, "done": 20, "failed": 4, "cancelled": 0,
               "onPlay": 18, "onAppStore": 0, "progress": 0.31, "etaSeconds": 5400 },
  "settings": { "lanes": { "light": 3, "text": 3, "build": 2, "image": 2, "shots": 1, "store": 2, "agent:claude-code": 3, "agent:qwen-code": 3, "agent:gemini-cli": 3, "agent:codex": 2 },
                "maxInFlight": 12, "dailyStoreCap": { "play": 10, "appstore": 10 }, "minFreeDiskGb": 10 },
  "uploads": { "date": "2026-10-06", "play": 4, "appstore": 0, "cap": { "play": 10, "appstore": 10 }, "resetsAt": "2026-10-07T00:00:00.000+02:00" },
  "lanes": { "build": { "limit": 2, "running": 2, "waiting": 9 }, "agent:claude-code": { "limit": 3, "running": 3, "waiting": 20, "pausedUntil": "ISO (solo se il motore ha raggiunto il limite)" } },
  "batches": [ { "id": "b1", "name": "Lotto giardino", "createdAt": "ISO", "appIds": ["a1"], "recipe": { "engines": { "claude-code": 2, "qwen-code": 1 }, "quality": "fast", "logoBy": "codex", "goal": "android", "languages": ["en-US","it-IT"], "maxAttempts": 2, "extra": "" } } ],
  "apps": [ {
    "id": "a1", "batchId": "b1", "order": 0, "name": "Acqua di Oggi", "summary": "…", "size": "small", "category": "health",
    "engine": "claude-code", "folder": "acqua_di_oggi", "projectId": "p1 (assente finché `create` non è fatto; serve per aprire l'app)", "workspaceId": "w1", "packageName": "com.emberapps.acqua",
    "state": "running", "doing": "Scrive lib/home.dart",
    "stages": { "create": { "state": "done", "attempts": 1, "startedAt": "ISO", "finishedAt": "ISO", "message": "…" }, "play": { "state": "pending", "attempts": 0, "until": "ISO (attesa del tetto giornaliero)" } },
    "needs": [ { "id": "n1", "kind": "play_console_app", "stage": "play", "title": "…", "detail": "…", "data": { "name": "…", "package": "…" }, "createdAt": "ISO" } ],
    "error": "…", "errorStage": "code", "notBefore": "ISO (l'app aspetta questo momento)", "costUsd": 0.42,
    "log": ["ultime 8 righe"], "createdAt": "ISO", "updatedAt": "ISO"
  } ],
  "needsYou": [ { "id": "n1", "appId": "a1", "appName": "Acqua di Oggi", "kind": "play_console_app", "stage": "play", "title": "…", "detail": "…", "data": {}, "createdAt": "ISO" } ]
}
```
`needs[].kind`: `play_console_app` (data: name, package, shortDescription, category), `apple_app_record` (data: name, bundleId, sku), `mac`, `android_sdk`, `play_key`, `apple_key`, `login` (data: engine), `other`.

### Dettaglio — `GET /v1/factory/apps/:id`
Come un elemento di `apps` ma con `brief` e `log` completo (fino a 80 righe).

### Piano dal testo — `POST /v1/factory/plan`
Corpo: `{ "text": "tutto quello incollato nella casella grande", "count": 30, "engines": { "claude-code": 2, "qwen-code": 1 } }` (`count` solo se il testo è un tema; `engines` sono i pesi per assegnare un motore a ogni scheda, i grandi ai più forti; se manca si usano i motori collegati). Lento (decine di secondi): usare un timeout lungo (5 minuti).
Risposta: `{ "apps": [ { "name", "summary", "brief", "size": "small|big", "category", "engine" } ], "dropped": [ { "name", "reason": "duplicate_name|similar_idea|too_many", "keptInstead": "nome" } ], "warnings": ["no_ai"], "source": "supervisor|list" }`. Errore `502 { code: "no_ai" }` se non c'è nessun motore AI per un testo libero. Massimo 100 schede.

### Nuovo lotto — `POST /v1/factory/batches`
Corpo: `{ "name": "Lotto giardino", "apps": [ { "name", "summary", "brief?", "size?", "category?", "engine?" } ], "recipe": { "engines": {…}, "quality": "fast|best", "logoBy": "codex|claude_code|gemini_runner|auto", "goal": "app|assets|android|ios", "languages": ["en-US","it-IT"], "maxAttempts": 2, "extra": "" }, "start": true }` → `201 { "batchId", "rev" }`. Con `"start": false` il lotto nasce e il Factory resta in pausa se lo era. Da 1 a 100 app.

### Comandi
| Rotta | Corpo | Risposta |
|---|---|---|
| `POST /v1/factory/pause` · `/resume` | – | `{ paused, rev }` |
| `POST /v1/factory/apps/:id/retry` | `{ from?: stage }` | `{ ok, rev }` (riparte dallo stadio fallito, o da `from` e da ciò che ne dipende) |
| `POST /v1/factory/apps/:id/cancel` | – | `{ ok, rev }` |
| `POST /v1/factory/apps/:id/resolve` | `{ needId?, skip?: bool }` | `{ ok, rev }` («Fatto, continua» oppure «Salta questo passo») |
| `DELETE /v1/factory/apps/:id?project=true` | – | `{ ok, rev }` (con `project=true` toglie anche il progetto) |
| `POST /v1/factory/apps/bulk` | `{ ids: [], action: "retry\|cancel\|delete" }` | `{ done: n, rev }` |
| `POST /v1/factory/batches/:id/retry-failed` · `/cancel` | – | `{ done: n, rev }` |
| `PATCH /v1/factory/settings` | `{ lanes?: {…}, maxInFlight?, dailyStoreCap?: { play?, appstore? }, minFreeDiskGb? }` | stato come `GET` |

### Collegamenti e capacità — `GET /v1/factory/connections`
```json
{ "links": { "claude": { "ready": true, "detail": "" }, "qwen": { "ready": false, "detail": "not_installed" }, "gemini": {…}, "codex": {…},
             "flutter": {…}, "android": {…}, "chrome": {…}, "playKey": {…}, "appleKey": {…}, "mac": { "ready": false, "detail": "windows" } },
  "capacity": { "cpus": 16, "totalRamMb": 8100, "freeRamMb": 3200, "freeDiskGb": 108, "buildSlots": 1, "agentSlots": 6,
                "suggested": { "lanes": { "build": 1, "agent:claude-code": 3 }, "maxInFlight": 8 } } }
```
`detail` per un collegamento non pronto: `not_installed | not_signed_in | missing | windows | …` (codice, non frase). Per accedere a un motore: `POST /v1/subscriptions/:engine/login` con `claude-code | codex | gemini-cli | qwen-code` (funziona uguale per Qwen).

### Modalità simulata
Con `EMBER_FACTORY_SIMULATE=1` il Runner usa operazioni finte (tempi di pochi secondi, qualche errore e qualche «serve te» a caso, nessun progetto vero, nessun abbonamento usato): `simulated: true` in `GET /v1/factory`. Serve per provare l'interfaccia con 100 app.
