# Ember: interfaccia semplice ed elegante, da 0 a 100

## Contesto

Ember (`C:\Users\kmrnn\ember\apps\ide`) fa creare e pubblicare un'app a chi non è tecnico, ma l'interfaccia oggi mostra tutto insieme. Misurato sul codice:

| Schermata | Oggi | Problema |
|---|---|---|
| Home (`projects_screen.dart`) | ~30-35 controlli prima della lista | 9 chip motore, 3+ chip "chi disegna", 3 modi diversi di creare, progetti mostrati due volte, assistente aperto di default |
| App (`create_app_screen.dart`, 1128 righe) | ~35-40 pulsanti in 10-12 card impilate | anteprima, file Android, Play, App Store, GitHub, logo, pubblicità e log tecnico in un'unica colonna; il campo "migliora" è in fondo |
| Scheda Play (`play_publish_screen.dart`) | 83 chip lingua + 6 campi + 6 pulsanti | |
| Sistema grafico | nessuno | tema inline in `main.dart`, 3 widget condivisi, la stessa card copiata 13 volte, 4 bolle chat diverse, 7 verdi diversi per "ok", 13 raggi, 5 breakpoint |
| Testi | ~78 frasi italiane scritte nel codice, 47 chiavi mancanti in es/fr/ar | più gergo (APK, AAB, Runner, keystore) e guide da 500-800 caratteri |

Risultato voluto: **una sola azione principale per schermata**, il resto a un tocco di distanza, un solo sistema grafico, parole semplici in 5 lingue.

## Decisione di stile (l'unica che cambia il carattere del prodotto)

Scelta consigliata, applicata dal piano: **"Ember calmo"**. Restano il nome, il simbolo e il rosso Ember come unico colore d'accento su superfici scure neutre. Escono di scena il font horror Nosifer, la pioggia "matrix" e l'effetto glitch di `forge_view.dart`, e le parole "evoca / summon". Se vuoi tenere l'identità horror, dillo all'approvazione: le fasi 2-9 restano uguali, cambia solo la fase 1.

## Obiettivi misurabili

| Misura | Oggi | Obiettivo |
|---|---|---|
| Controlli sulla home prima della lista | ~30 | ≤ 6 |
| Controlli sulla schermata app (pronta) | ~35-40 | ≤ 8 |
| Controlli sulla scheda Play | ~90 | ≤ 8 |
| Frasi scritte nel codice | ~78 | 0 |
| Lingue complete | 2 su 5 | 5 su 5 |
| `Color(0x…)` / `Colors.` fuori da `lib/ui` | 158 | 0 (tranne superfici sempre scure) |
| File schermata oltre 500 righe | 5 | 0 |

## Regole valide per ogni fase

- Una fase = un commit sul branch `ux/semplice`; dopo ogni fase l'app parte e `flutter analyze` + `flutter test` passano.
- Nessuna funzione viene tolta: viene spostata a un tocco di distanza.
- Le `Key('…')` esistenti restano (71 nel codice).
- Nessuna modifica a `apps/runner`.

---

## Fase 0 — Base di partenza

1. Branch `ux/semplice`; commit del lavoro già in corso (cronologia + bozze, correzione click mockup sul web), che è completo e indipendente.
2. Sostituire la bozza `docs/UX_PIANO.md` con questo piano, così si apre da Antigravity.
3. Flutter non è nel PATH: usare `C:\Users\kmrnn\tools\flutter\bin\flutter.bat` (3.38.9).
4. Schermate "prima" in `docs/ux/prima/` (home, app pronta, scheda Play; larghezze 390 e 1280).

## Fase 1 — Fondamenta: `apps/ide/lib/ui/`

Nuova cartella, nessun cambio visibile di struttura.

- **`ui/tokens.dart`**: spazi 4/8/12/16/24/32; raggi 8/12/16/pillola; durate 150/250/400 ms con una curva; larghezze contenuto 420/720; **due breakpoint soli: 840 e 1100** (sotto 840 una colonna, 840-1100 un pannello laterale, oltre 1100 due). Sostituiscono 600/840/900/1000/1100.
- **`ui/theme.dart`**: `ThemeData` spostato da `main.dart:25-87`. Superfici scure neutre, rosso solo come accento. `ThemeExtension EmberColors` con `success`, `warning`, `codeSurface`, `onCodeSurface`. Temi completi per campi (bordo una volta sola: via i 41 `OutlineInputBorder()` a mano), pulsanti outlined/text/icon, dialoghi, snackbar, liste, divisori, indicatori, bottom sheet, tooltip. `emberRed` si sposta qui da `widgets/ember_logo.dart:5-6`.
- **Scritta "EMBER"**: ChakraPetch 700 con spaziatura larga al posto di Nosifer (`ember_logo.dart:122`); il sottotitolo "APP MAKER" passa da l10n.
- **Icone**: solo variante outlined; via le emoji usate come icone (`create_app_screen.dart:755,1115`, `chat_panel.dart:226`, `mockup_gallery_screen.dart:350-352`).

## Fase 2 — Componenti condivisi (`lib/ui/`)

Ogni componente sostituisce i duplicati elencati; cambia l'aspetto in modo uniforme, non il comportamento.

| Componente | Sostituisce |
|---|---|
| `SectionCard` (icona, titolo, aiuto, corpo) | 13 copie in `create/*_card.dart`, `review_card.dart`, `settings_screen.dart` |
| `BusyRow`, `InlineMessage` | 9 + 11 copie |
| `StatusRow`, `FindingTile` | 6 + 3 copie |
| `SecretField` (incolla, mostra, salva, elimina, "prendi la chiave") | 5 copie: impostazioni, revisori, GitHub, App Store |
| `ChatBubble`, `ChatComposer` | 4 + 4 copie |
| `LogSurface` | 5 copie con 3 sfondi diversi |
| `EmptyState`, `ErrorState` (con Riprova), `LoadingState` | spinner e testi sparsi; via i `Text('$e')` grezzi |
| `showConfirm`, `showEmberSnack` | 7 `AlertDialog` e 13 snackbar con durate diverse |
| `Pill`, `OverlayButton`, `StepsList` (guide numerate) | 3 + 3 copie; i testi-guida lunghi |
| `PageBody` (larghezza massima, margini) | i 5 `ConstrainedBox` diversi; impostazioni e scheda Play oggi a tutta larghezza |

## Fase 3 — Home: "Descrivi la tua app"

File: `projects/projects_screen.dart`, nuovo `create/prompt_composer.dart` (estratto da `create_app_screen.dart:211-430`), `create/engines.dart` (da `:175-208`).

- **Barra in alto**: logo, assistente, impostazioni. Lingua, Esci e Ripristina da GitHub si spostano (vedi Fase 6); il pallino di connessione appare solo quando qualcosa non va.
- **Centro**: campo descrizione + un pulsante **Crea app**. Sotto, una sola riga: "Creata con: *Claude Code* · Opzioni". "Opzioni" apre un foglio con motore, chi disegna, modello e i link di accesso (`AccessLinks`). L'ultima scelta viene ricordata.
- **Un solo modo di creare**: via il pulsante flottante "Nuovo progetto"; "Progetto vuoto" e "Ripristina da GitHub" diventano voci del menu "⋯" (la `Key('newProject')` resta sulla voce).
- **Una sola lista**: oltre 1100 px la colonna Cronologia (`HistoryPanel`) è la lista; sotto, lo stesso contenuto compare sotto il campo. Mai due volte.
- **Assistente** chiuso di default (`projects_screen.dart:98`).
- `JobLogDialog` (640×320 fissi, log grezzo) diventa un avanzamento semplice con "Dettagli" richiudibile.

## Fase 4 — Schermata dell'app: da 12 card a un centro con 6 voci

File: `create/create_app_screen.dart` diviso in `create/app_session.dart` (store, args, provider), `create/app_hub_screen.dart`, `create/hub/*.dart`; nuove rotte in `router.dart`.

**Il centro** (`/projects/:id/create`), dall'alto in basso:
1. `NeedsYouCard` solo se serve qualcosa.
2. **Stato**: in costruzione → simbolo Ember, passo attuale, elenco passi, Stop (`ForgeView` semplificato, rispetta "riduci movimento"). Pronta → "La tua app è pronta" con **Apri app** come unica azione principale. Fallita → `_FailedCard` com'è.
3. **Prossimi passi**: sei righe con stato a destra, ognuna apre la sua pagina.
4. Conversazione.
5. **Campo "Cosa vuoi cambiare?" fisso in basso** (oggi è sotto tutte le card).
6. "Dettagli tecnici" (log e costo) chiuso di default (`_showLog`, `:446`).

| Riga | Rotta | Contenuto riusato |
|---|---|---|
| Prova sul telefono | `…/prova` | `PhoneCard`, QR, file da installare (APK) |
| Icona e immagini | `…/immagini` | `LogoCard`, `ScreenshotsCard` |
| Controlli | `…/controlli` | `CheckupCard`, `ReviewCard` |
| Google Play | `…/play` (esiste) | guida se non pubblicata; `PlayUpdateCard` se pubblicata; file AAB |
| App Store | `…/appstore` | `IosCard`, `AppStoreCard` |
| Altro | `…/altro` | `GitHubCard`, `AdsCard`, `ProductsCard`, copia della chiave di firma, "Apri il codice" |

- `PlatformTabs` Android/iPhone sparisce: la piattaforma è la riga scelta.
- Play ha **un solo ingresso** (oggi quattro).
- Correzione: sotto 900 px il pulsante assistente non apre il pannello (`create_app_screen.dart:542-546` non chiama `openEndDrawer()`).
- Controllo "AI non disponibile" (`review/panel_health.dart`): "Chiudi Ember" oggi chiude l'applicazione; diventa "Annulla" e torna indietro. Aggiornare `test/panel_health_test.dart`.

## Fase 5 — Pubblicazione

- **`store/play_publish_screen.dart`** (1047 righe) diviso: `store/listing_languages.dart` (tabella 82 lingue), `store/publish_job.dart`, `store/listing_form.dart`. Le 83 chip diventano una riga "Lingue: 26 attive · Gestisci" che apre un elenco con ricerca. Azione principale **Carica**; "Aggiorna solo la scheda" e "Traduci di nuovo" nel menu "⋯".
- **`create/appstore_card.dart`** (885 righe) diventa una pagina in quattro sezioni: Collegamento (`SecretField`), Cosa compilo io, Controlli, Pubblica. I 6 campi revisione restano in "Avanzate".
- **`store/publish_chat_screen.dart`**: solo componenti condivisi (`ChatBubble`, `ChatComposer`).

## Fase 6 — Impostazioni, accesso, mockup, editor

- **Impostazioni** (`ai/settings_screen.dart` → `settings/settings_screen.dart`), un posto solo: Lingua · Aspetto · Intelligenze artificiali (chiavi e revisori, con `SecretField`) · Account collegati (GitHub, Google Play, Apple) · Avanzate (indirizzo del Runner) · Esci. Le chiavi dei revisori si modificano solo qui (via il doppione in `review_card.dart:172`).
- **Accesso** (`auth/login_screen.dart`): l'indirizzo del Runner va sotto "Avanzate".
- **Mockup** (`mockups/mockup_gallery_screen.dart`): è già il modello giusto. Solo rifinitura: tooltip "Precedente/Successivo", frecce che si girano in arabo, pallini con area di tocco da 48, niente emoji.
- **Editor, terminale, anteprima**: stessi token; scheda terminale selezionata in rosso al posto del blu (`terminal_panel.dart:93`); un solo componente per le schede; tooltip mancanti.

## Fase 7 — Parole

- Le ~78 frasi italiane nel codice passano negli `.arb` (peggiori: `appstore_card.dart`, `review_card.dart`, `panel_health.dart`, `reviewer_key_row.dart`, `needs_you_card.dart`).
- Le 47 chiavi mancanti in es/fr/ar vengono tradotte; `l10n.yaml` riceve `untranslated-messages-file`; nuovo test: tutte le lingue hanno le stesse chiavi.
- Riscrittura: via "evoca/summon"; "API keys & models" → "Intelligenze artificiali"; APK → "file da installare", AAB → "file per Google Play" (sigla tra parentesi); "Runner" visibile solo in Avanzate. Le guide lunghe (`playConnectGuide`, `pubFinish`, `adsSteps`, `connectHowTo`) diventano passi numerati con `StepsList`.
- Prima apertura: lingua del dispositivo se è una delle cinque, altrimenti inglese (`core/locale.dart:18-41`).

## Fase 8 — Accessibilità, arabo, movimento, tema chiaro

- **Arabo**: `EdgeInsetsDirectional` e `AlignmentDirectional` al posto di sinistra/destra (bolle chat, albero file, ~25 punti); `BackButton` al posto di `Icons.arrow_back`.
- **Accessibilità**: tooltip sui 23 `IconButton` senza; aree di tocco ≥ 48; `Semantics` su simbolo, pallino di connessione e stati a solo colore; nessuna altezza fissa che taglia il testo ingrandito.
- **Movimento**: cambi di stato con `AnimatedSwitcher`, aperture con `AnimatedSize`, durate dai token, rispetto di "riduci movimento" ovunque.
- **Tema chiaro**: scelta Sistema/Chiaro/Scuro in Impostazioni (oggi `ThemeMode.dark` fisso, `main.dart:96`). Terminale, log, mockup e anteprima a tutto schermo restano sempre scuri tramite `EmberColors.codeSurface`.

## Fase 9 — Pulizia e documenti

- Codice morto, dopo verifica con ricerca: `create/app_content_card.dart`, `_CompatibleTile` (`settings_screen.dart:178-264`).
- Resti del modello Flutter: nome iOS "Ide" (`ios/Runner/Info.plist:7-8`), descrizione "A new Flutter project." (`web/index.html:21`), colori di `web/manifest.json` allineati al tema.
- `docs/ROADMAP.md` e `docs/ARCHITECTURE.md` aggiornati (schermate, cartella `lib/ui`, cinque lingue); schermate "dopo" in `docs/ux/dopo/`.

---

## Verifica

Dopo ogni fase, da `C:\Users\kmrnn\ember\apps\ide`:

```
C:\Users\kmrnn\tools\flutter\bin\flutter.bat analyze
C:\Users\kmrnn\tools\flutter\bin\flutter.bat test
```

Nuovi test (oggi solo 6 test toccano l'interfaccia, nessuno le schermate principali):
- `test/ui_smoke_test.dart`: home, centro app (in costruzione / pronta / fallita), scheda Play, impostazioni, a 390, 900 e 1280 px, in inglese e in arabo, senza errori di overflow.
- `test/l10n_complete_test.dart`: le cinque lingue hanno le stesse chiavi.
- `test/tokens_test.dart`: nessun `Color(0x` o `Colors.` in `lib/features` (con elenco di eccezioni per le superfici sempre scure).

Prova a mano, percorso completo: accesso → descrivi → mockup → nome → costruzione → apri app → cambia qualcosa → icona → Google Play → cronologia, su Chrome (`flutter run -d chrome`) e Windows (`-d windows`), finestra stretta e larga, italiano e arabo.

**Blocco noto per la prova a mano**: il Runner richiede Node 22 e su questo PC c'è Node 20.12.2. Se il Runner non è già in esecuzione, serve aggiornare Node prima della prova; analisi e test non ne hanno bisogno.

Alla fine: tabella "Obiettivi misurabili" ricontrollata con gli stessi conteggi usati per scrivere questo piano.
