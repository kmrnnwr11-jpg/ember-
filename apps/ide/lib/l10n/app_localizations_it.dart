// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Ember – App Maker';

  @override
  String get loginTitle => 'Accedi';

  @override
  String get loginSubtitle =>
      'Crea app Flutter da qualsiasi dispositivo, con l\'AI.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get runnerUrl => 'URL Runner';

  @override
  String get signIn => 'Accedi';

  @override
  String get signUp => 'Registrati';

  @override
  String get devLoginHint =>
      'Modalità sviluppo: Supabase non configurato, accesso solo con email tramite il Runner.';

  @override
  String get invalidEmail => 'Email non valida';

  @override
  String get passwordTooShort => 'Almeno 6 caratteri';

  @override
  String get signOut => 'Esci';

  @override
  String get projects => 'Le tue app';

  @override
  String get noProjects => 'Nessuna app evocata. Descrivine una qui sopra.';

  @override
  String get newProject => 'Nuovo progetto';

  @override
  String get projectName => 'Nome progetto';

  @override
  String get projectNameHelp => 'minuscolo, lettere/numeri/_ (es. my_app)';

  @override
  String get create => 'Crea';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get rename => 'Rinomina';

  @override
  String get retry => 'Riprova';

  @override
  String get statusCreating => 'In creazione…';

  @override
  String get statusReady => 'Pronto';

  @override
  String get statusError => 'Errore';

  @override
  String creatingProject(String name) {
    return 'Creazione di $name';
  }

  @override
  String get files => 'File';

  @override
  String get editor => 'Editor';

  @override
  String get newFile => 'Nuovo file';

  @override
  String get newFolder => 'Nuova cartella';

  @override
  String get fileName => 'Nome';

  @override
  String deleteConfirm(String path) {
    return 'Eliminare $path?';
  }

  @override
  String get save => 'Salva';

  @override
  String get saved => 'Salvato';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String get discard => 'Scarta';

  @override
  String get noFileOpen => 'Apri un file dall\'albero a sinistra.';

  @override
  String get conflictTitle => 'File modificato altrove';

  @override
  String conflictBody(String path) {
    return '$path è cambiato sul Runner dopo che l\'hai aperto.';
  }

  @override
  String get reload => 'Ricarica';

  @override
  String get overwrite => 'Sovrascrivi';

  @override
  String get connected => 'Connesso';

  @override
  String get connecting => 'Connessione…';

  @override
  String get disconnected => 'Disconnesso';

  @override
  String error(String message) {
    return 'Errore: $message';
  }

  @override
  String get binaryFile =>
      'File binario o troppo grande: non modificabile nell\'editor.';

  @override
  String get terminal => 'Terminale';

  @override
  String get newTerminal => 'Nuovo terminale';

  @override
  String get toggleTerminal => 'Mostra/nascondi terminale';

  @override
  String get restart => 'Riavvia';

  @override
  String get preview => 'Anteprima';

  @override
  String get togglePreview => 'Mostra/nascondi anteprima';

  @override
  String get runWeb => 'Avvia Web';

  @override
  String get building => 'Compilazione…';

  @override
  String get buildFailed => 'Compilazione fallita: controlla il log qui sotto.';

  @override
  String get reloadPreview => 'Ricarica anteprima';

  @override
  String get device => 'Dispositivo';

  @override
  String get openInBrowser => 'Apri nel browser';

  @override
  String get openOnOtherDevice => 'Apri su un altro dispositivo';

  @override
  String get qrLocalhostWarning =>
      'Questo indirizzo funziona solo su questo computer. Usa l\'IP di rete del Runner (es. http://192.168.1.20:8787) per aprirlo dal telefono.';

  @override
  String get copy => 'Copia';

  @override
  String get close => 'Chiudi';

  @override
  String get console => 'Console';

  @override
  String get autoRebuild => 'Ricompila al salvataggio';

  @override
  String get previewEmpty =>
      'Premi «Avvia Web» per compilare l\'app e vederla qui. Ogni salvataggio aggiorna l\'anteprima.';

  @override
  String get ai => 'AI';

  @override
  String get toggleAi => 'Mostra/nascondi pannello AI';

  @override
  String get aiSettings => 'Chiavi API e modelli';

  @override
  String get apiKeysHint =>
      'Le chiavi restano cifrate su questo dispositivo (archivio sicuro). Con il proxy attivo passano dal tuo Runner solo per la singola richiesta e non vengono salvate né registrate nei log.';

  @override
  String get useRunnerProxy => 'Passa dal Runner (proxy)';

  @override
  String get useRunnerProxyHint =>
      'Consigliato. Disattiva per chiamare i provider direttamente da questo dispositivo.';

  @override
  String get useRunnerProxyWeb =>
      'Sul web è obbligatorio: il browser non può chiamare i provider direttamente.';

  @override
  String get apiKey => 'Chiave API';

  @override
  String get apiKeyOptional => 'Chiave API (se richiesta)';

  @override
  String get replaceApiKey => 'Sostituisci chiave';

  @override
  String get testKey => 'Prova';

  @override
  String get testing => 'Prova in corso…';

  @override
  String keyWorks(String model) {
    return 'Funziona ✓ ($model)';
  }

  @override
  String get getKey => 'Ottieni una chiave';

  @override
  String get addModelId => 'Aggiungi ID modello';

  @override
  String get selectModel => 'Scegli modello';

  @override
  String get keyPresent => 'chiave presente';

  @override
  String get notConfigured => 'non configurato';

  @override
  String get per1k => 'per 1k token (in/out)';

  @override
  String applyTo(String path) {
    return 'Applica a $path';
  }

  @override
  String get noChanges => 'Nessuna differenza rispetto al file attuale.';

  @override
  String get accept => 'Accetta';

  @override
  String get reject => 'Rifiuta';

  @override
  String get apply => 'Applica';

  @override
  String applied(String path) {
    return 'Modifica applicata a $path: controlla e salva.';
  }

  @override
  String get applyNoTarget =>
      'Apri un file o chiedi all\'AI di indicare il percorso del file.';

  @override
  String get clearChat => 'Svuota chat';

  @override
  String get chatEmpty =>
      'Chiedi qualcosa sul tuo progetto. Il file aperto viene inviato come contesto.';

  @override
  String get chatNoKeys =>
      'Per usare l\'AI inserisci almeno una chiave API (Claude, ChatGPT o Gemini).';

  @override
  String get attachOpenFile => 'Allega il file aperto come contesto';

  @override
  String get askAi => 'Chiedi all\'AI…  (Ctrl+Invio per inviare)';

  @override
  String get send => 'Invia';

  @override
  String get stop => 'Ferma';

  @override
  String get copied => 'Copiato';

  @override
  String get truncated => 'risposta troncata (limite token)';

  @override
  String get refused => 'rifiutata dal modello';

  @override
  String get stopped => 'interrotta';

  @override
  String get badgeFreeTier => 'gratis*';

  @override
  String get badgeSubscription => 'abbonamento';

  @override
  String get badgePaid => 'a pagamento';

  @override
  String needsKey(String name) {
    return 'Serve una chiave API $name: aggiungila nelle impostazioni.';
  }

  @override
  String get claudeCodeUnavailable =>
      'Claude Code non è disponibile su questo Runner (serve Claude Code installato e con login sul PC del Runner).';

  @override
  String get appPromptHint =>
      'Es.: un\'app di ricette con foto, lista della spesa e timer…';

  @override
  String get chooseAi => 'Scegli il motore';

  @override
  String get createApp => 'Ember App';

  @override
  String get openEditor => 'Editor';

  @override
  String get describeYourApp => 'Evoca la tua app';

  @override
  String get describeYourAppHint =>
      'Descrivi cosa deve fare e come deve essere. Ember la scrive, la verifica e te la mostra. (*Gemini: quota gratuita di Google con limiti giornalieri)';

  @override
  String get improveApp => 'Cosa vuoi aggiungere o migliorare?';

  @override
  String get improveAppHint =>
      'Descrivi le prossime funzioni o modifiche, es.: aggiungi le videochiamate, il login con Google, le stanze private… Puoi anche incollare qui le chiavi che ti chiede l\'AI.';

  @override
  String get applyChange => 'Applica modifica';

  @override
  String get buildLog => 'Dettagli';

  @override
  String get stepClaudeCode => 'Claude Code scrive e verifica il codice';

  @override
  String stepWriting(int count) {
    return 'Scrittura del codice ($count file)';
  }

  @override
  String get stepDependencies => 'Installazione dipendenze';

  @override
  String get stepChecking => 'Controllo errori';

  @override
  String stepFixing(int round) {
    return 'Correzione errori (tentativo $round)';
  }

  @override
  String get stepBuilding => 'Compilazione dell\'app';

  @override
  String get stepReady => 'Pronta';

  @override
  String get appReadyTitle => 'La tua app è pronta 🎉';

  @override
  String get openApp => 'Apri app';

  @override
  String get viewCode => 'Vedi codice';

  @override
  String get buildCancelled => 'Creazione interrotta';

  @override
  String get buildFailedTitle => 'Non sono riuscito a completare l\'app';

  @override
  String get bestQuality => 'Potenza massima';

  @override
  String get bestQualityOn =>
      'Il motore più potente: più lento, per app complesse';

  @override
  String get bestQualityOff =>
      'Veloce (consigliato): va bene per la maggior parte delle app';

  @override
  String get androidFileQuestion => 'Vuoi il file per Android?';

  @override
  String get androidFileHint =>
      'APK: da installare sul telefono. AAB: da caricare sulla Google Play Console. Entrambi firmati.';

  @override
  String get generateApk => 'Genera APK';

  @override
  String get generateAab => 'Genera AAB';

  @override
  String androidBuilding(String kind) {
    return 'Genero $kind… la prima volta può richiedere 3-5 minuti.';
  }

  @override
  String get downloadApk => 'Scarica e installa APK';

  @override
  String get downloadAab => 'Scarica AAB';

  @override
  String get apkInstallHint =>
      'APK firmato. Se Android lo chiede, consenti l\'installazione da questa fonte.';

  @override
  String get aabHint =>
      'AAB firmato con la chiave di caricamento di questa app: pronto per la Google Play Console. Il numero di versione sale da solo a ogni build.';

  @override
  String get androidFailed => 'Generazione non riuscita:';

  @override
  String get backupSigningKey => 'Salva chiave di firma';

  @override
  String get backupSigningKeyHint =>
      'Conserva il file della chiave e la password in un posto sicuro (es. Google Drive): servono per pubblicare gli aggiornamenti di questa app sul Play Store. Il link funziona una sola volta per 10 minuti.';

  @override
  String get downloadKeystore => 'Scarica file chiave';

  @override
  String get fullscreenExitHint =>
      'Scorri o premi indietro per tornare a Ember';

  @override
  String get runFullscreen => 'Avvia a schermo intero';

  @override
  String cliNotInstalled(String name) {
    return 'non installato sul Runner ($name)';
  }

  @override
  String get terminalCliHint =>
      'Claude Code, Codex e Gemini usano il login fatto sul PC del Runner. La prima volta segui le istruzioni nel terminale per accedere.';

  @override
  String get generatingMockups => 'Creo 5 stili grafici…';

  @override
  String designingStyle(String style) {
    return 'Disegno lo stile «$style»…';
  }

  @override
  String get chooseMockup => 'Scegli questo';

  @override
  String get editMockup => 'Modifica questo mockup';

  @override
  String get editMockupHint =>
      'Es.: più scuro, bottoni arrotondati, logo rosa…';

  @override
  String get newMockups => 'Nuovi mockup (5 stili diversi)';

  @override
  String get previousMockups => 'Mockup precedenti';

  @override
  String mockupSet(int n) {
    return 'Serie $n';
  }

  @override
  String get skipMockups => 'Salta i mockup e crea l\'app';

  @override
  String get playAskUpload => 'Vuoi caricare l\'app sul Google Play Store?';

  @override
  String get playYesUpload => 'Sì, carica sul Play Store';

  @override
  String get playNotNow => 'Non ora';

  @override
  String get playFeeNotice =>
      'Serve un account sviluppatore Google Play Console. Costo: 25 \$ una sola volta (non è un abbonamento), pagati direttamente a Google, non a Ember.';

  @override
  String get playPublishTitle => 'Pubblica su Google Play';

  @override
  String get playStepAccount => 'Account Google Play Console';

  @override
  String get playOpenSignup => 'Crea account Play Console';

  @override
  String get playHaveAccount => 'Ho già un account Play Console attivo';

  @override
  String get next => 'Avanti';

  @override
  String get playStepCreateApp => 'Crea l\'app nel Play Console';

  @override
  String get playCreateAppGuide =>
      'Google richiede questo passaggio a mano, solo la prima volta:\n1. Apri **Play Console** → **Crea app**\n2. Nome app, lingua predefinita **Italiano**, tipo **App**, **Gratuita**\n3. Accetta le dichiarazioni e premi **Crea app**\n\nIl package name verrà associato automaticamente al primo caricamento: usa quello qui sotto.';

  @override
  String get playPackageName => 'Package name';

  @override
  String get playOpenConsole => 'Apri Play Console';

  @override
  String get playAppCreated => 'Ho creato l\'app nel Play Console';

  @override
  String get playStepConnect => 'Collega Ember a Google Play';

  @override
  String get playConnectGuide =>
      'Serve una **chiave di account di servizio** (una sola volta per tutte le tue app):\n1. Apri **Google Cloud** e attiva l\'API **Google Play Android Developer API**\n2. Vai su **Account di servizio** → **Crea account di servizio** → poi **Chiavi** → **Aggiungi chiave** → **JSON** (si scarica un file)\n3. Nel **Play Console** → **Utenti e autorizzazioni** → **Invita nuovi utenti** → incolla l\'email dell\'account di servizio → dai i permessi di **rilascio** per le tue app\n4. Apri il file JSON scaricato e **incolla qui tutto il contenuto**\n\nLa chiave resta salvata cifrata su questo dispositivo e viene usata solo per il caricamento.';

  @override
  String get playOpenApiLibrary => 'Attiva API Google Play';

  @override
  String get playOpenServiceAccounts => 'Account di servizio';

  @override
  String get playServiceAccountJson =>
      'Contenuto del file JSON dell\'account di servizio';

  @override
  String get playStepListing => 'Scheda dello store e caricamento';

  @override
  String get playGenerateWithAi =>
      'Genera scheda, privacy policy e risposte con l\'AI';

  @override
  String get playTitle => 'Titolo (max 30)';

  @override
  String get playShortDescription => 'Descrizione breve (max 80)';

  @override
  String get playFullDescription => 'Descrizione completa';

  @override
  String get playReleaseNotes => 'Note di versione';

  @override
  String get playContactEmail =>
      'Email di contatto (obbligatoria su Play Store)';

  @override
  String get playPrivacyUrl => 'Link privacy policy';

  @override
  String get playTrack => 'Dove pubblicare';

  @override
  String get playTrackInternal => 'Test interno (consigliato per iniziare)';

  @override
  String get playTrackClosed => 'Test chiuso';

  @override
  String get playTrackProduction => 'Produzione (pubblico)';

  @override
  String get playUpload => 'Carica su Google Play';

  @override
  String get playStepFinish => 'Completa nel Play Console';

  @override
  String playUploaded(String version, String track, String draft) {
    return '✅ Caricata! Versione $version sulla traccia «$track». $draft';
  }

  @override
  String get playDraftNote =>
      'Poiché l\'app non è ancora mai stata pubblicata, Google l\'ha salvata come bozza: completa i passaggi qui sotto e premi «Invia per la revisione» nel Play Console.';

  @override
  String get playReviewNotSent =>
      'Google non ha potuto inviare le modifiche in revisione automaticamente. Sono salvate: apri Play Console e premi \"Invia per la revisione\" per pubblicare.';

  @override
  String playManualChecklist(String privacyUrl) {
    return 'Google richiede di confermare a mano queste voci nel Play Console (le risposte pronte sono qui sotto):\n- **Norme sulla privacy** → incolla il link: $privacyUrl\n- **Sicurezza dei dati**\n- **Classificazione dei contenuti** (questionario)\n- **Pubblico di destinazione e contenuti**\n- **Annunci** e **Accesso all\'app** (se serve il login, fornisci un account di prova)\n- **Scheda dello store**: icona 512×512 e almeno 2 screenshot\n- Account personali nuovi: Google può richiedere un **test chiuso** con un numero minimo di tester prima della produzione';
  }

  @override
  String get playDataSafety => 'Risposte per «Sicurezza dei dati»';

  @override
  String get playContentRating =>
      'Risposte per «Classificazione dei contenuti»';

  @override
  String get playOtherDeclarations => 'Pubblico, annunci e accesso all\'app';

  @override
  String get assistantTitle => 'Chiedi a Ember';

  @override
  String get assistantFree => 'Gratis';

  @override
  String get assistantEmpty =>
      'Ciao, sono Ember! Chiedimi quello che vuoi: idee per la tua app, come pubblicarla sul Play Store, come configurare login e database…';

  @override
  String get assistantUnconfigured =>
      'L\'assistente gratuito non è ancora attivo su questo server (manca la chiave Gemini del Runner).';

  @override
  String get assistantHint => 'Chiedi qualcosa a Ember…';

  @override
  String get assistantSuggest1 => 'Che app posso creare per il mio negozio?';

  @override
  String get assistantSuggest2 => 'Come pubblico un\'app sul Play Store?';

  @override
  String get assistantSuggest3 => 'Come funziona il login con Google?';

  @override
  String get language => 'Lingua';

  @override
  String get find => 'Cerca';

  @override
  String get replace => 'Sostituisci';

  @override
  String get replaceAll => 'Tutti';

  @override
  String get baseUrl => 'URL base';

  @override
  String fontLabel(String font) {
    return 'Font: $font';
  }

  @override
  String get styleMinimal => 'Minimal chiaro';

  @override
  String get styleDark => 'Dark premium';

  @override
  String get stylePlayful => 'Colorato & giocoso';

  @override
  String get styleGlass => 'Glassmorphism';

  @override
  String get styleMaterial => 'Material 3';

  @override
  String get styleNeumorph => 'Neumorphism';

  @override
  String get styleLuxury => 'Lusso elegante';

  @override
  String get styleBrutal => 'Bold brutalista';

  @override
  String get stylePastel => 'Pastello morbido';

  @override
  String get styleTech => 'Tech futuristico';

  @override
  String get styleNature => 'Natura';

  @override
  String get styleIos => 'Stile iOS';

  @override
  String get styleRetro => 'Retro anni 80';

  @override
  String get styleMono => 'Monocromatico';

  @override
  String get styleCorporate => 'Professionale';

  @override
  String bWriting(String model) {
    return 'Scrivo il codice con $model…';
  }

  @override
  String bApplying(String change, String model) {
    return 'Applico la modifica con $model: $change';
  }

  @override
  String get bNoModel => 'Nessun modello selezionato';

  @override
  String get bNoFiles =>
      'L\'AI non ha prodotto file: riprova o cambia modello.';

  @override
  String bErrorsRemain(int count, String problems) {
    return 'Restano errori dopo $count tentativi di correzione:\n$problems';
  }

  @override
  String bFixing(int max, int round) {
    return 'Correggo gli errori (tentativo $round di $max)…';
  }

  @override
  String bNoFixes(String problems) {
    return 'L\'AI non ha proposto correzioni per:\n$problems';
  }

  @override
  String bIncompleteFile(String path) {
    return 'File incompleto ignorato: $path';
  }

  @override
  String bPathNotAllowed(String path) {
    return 'Percorso non consentito ignorato: $path';
  }

  @override
  String get bTruncated =>
      'Risposta troncata dal limite di token: i file incompleti verranno ricreati nella correzione.';

  @override
  String get bRefused => 'Il modello ha rifiutato la richiesta.';

  @override
  String get bPubGet => 'Installo le dipendenze (flutter pub get)…';

  @override
  String get bPubGetFailed => 'flutter pub get non riuscito';

  @override
  String get bAnalyze => 'Controllo errori (flutter analyze)…';

  @override
  String get bNoErrors => 'Nessun errore ✓';

  @override
  String bErrorsFound(int count) {
    return '$count errori trovati';
  }

  @override
  String get bClaudeApplying => 'Claude Code applica la modifica…';

  @override
  String get bClaudeBuilding => 'Claude Code costruisce l\'app sul PC…';

  @override
  String statusBuilding(String progress) {
    return 'In creazione… $progress file';
  }

  @override
  String get bClaudeFailed =>
      'Claude Code non ha completato l\'app: controlla il log.';

  @override
  String resumeFromHere(int count) {
    return 'Riprendi da qui ($count file)';
  }

  @override
  String get startOver => 'Ricomincia da capo';

  @override
  String bClaudeStoppedCarryOn(int count) {
    return 'Si e\' fermato con $count file gia\' scritti: vado avanti e sistemo quello che manca.';
  }

  @override
  String get bWebBuilding => 'Compilo l\'app per il web (circa 30 secondi)…';

  @override
  String bWebFailed(String log) {
    return 'La compilazione web non è riuscita:\n$log';
  }

  @override
  String get bApk =>
      'Genero l\'APK (la prima volta può richiedere alcuni minuti)…';

  @override
  String get bAab => 'Genero l\'AAB per il Play Store…';

  @override
  String get chooseDesignAi => 'Chi disegna (logo, mockup, schermate)';

  @override
  String get chooseDesignAiHint =>
      'Gemini disegna bene ed è gratis; il motore qui sopra scrive il codice.';

  @override
  String get bLookingAtModel => 'Guardo l\'app da copiare…';

  @override
  String get bIpa => 'Genero l\'app per iPhone (IPA)…';

  @override
  String get nameTitle => 'Come si chiama la tua app?';

  @override
  String get nameHint =>
      'Questo nome va sul Play Store, nell\'informativa privacy e dentro il nome pacchetto, che dopo non si cambia più.';

  @override
  String get nameYourOwn => 'Oppure scrivi il tuo nome';

  @override
  String get nameMore => 'Altri nomi';

  @override
  String get nameUse => 'Usa questo nome';

  @override
  String bReferenceShots(int count) {
    return 'Salvate $count schermate dell\'app da copiare: il motore la vede, non solo la legge';
  }

  @override
  String get bReferenceShotsFailed =>
      'Non sono riuscito a scaricare le schermate dell\'app da copiare: vado solo con la descrizione';

  @override
  String bMissingTopics(String topics) {
    return 'Mancano rispetto all\'app da copiare: $topics. Le aggiungo adesso…';
  }

  @override
  String get bIosReady => 'App iPhone pronta ✓';

  @override
  String get bIosFailed => 'Generazione app iPhone non riuscita';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iPhone';

  @override
  String get iosTitle => 'App per iPhone';

  @override
  String get iosHint =>
      'La stessa app per iPhone e iPad: stesso nome, stesse schermate, stessi annunci. Il file (IPA) va su App Store Connect.';

  @override
  String get iosNeedsMac =>
      'L\'app per iPhone si può creare solo su un Mac. Salva l\'app su GitHub, apri Ember sul Mac e creala lì. Tutto il resto lo fai da qui.';

  @override
  String get iosBuild => 'Crea app iPhone';

  @override
  String get iosBuilding => 'Sto creando l\'app per iPhone…';

  @override
  String get iosReady =>
      'App iPhone pronta. È firmata col tuo account Apple e può andare su App Store Connect.';

  @override
  String get iosAppleAccount =>
      'Account Apple Developer: 99 dollari l\'anno, pagati ad Apple.';

  @override
  String get ascTitle => 'Manda all\'App Store';

  @override
  String get ascHint =>
      'Ember scrive su Apple quello che scrive su Google: titolo, descrizione, novità, link privacy e le risposte sulla privacy, in tutte le lingue della tua scheda.';

  @override
  String get ascKeyHelp =>
      'In App Store Connect: Utenti e accessi → Integrazioni → App Store Connect API → + . Scegli il ruolo App Manager, poi scarica il file .p8 (Apple te lo fa scaricare una volta sola).';

  @override
  String get ascKeyId => 'Key ID';

  @override
  String get ascIssuerId => 'Issuer ID';

  @override
  String get ascPrivateKey => 'Contenuto del file AuthKey_….p8';

  @override
  String get ascUploadBuild => 'Manda anche il file iPhone (serve il Mac)';

  @override
  String get ascSubmit => 'Manda alla revisione di Apple quando è tutto pronto';

  @override
  String get ascPublish => 'Pubblica sull\'App Store';

  @override
  String get ascWorking => 'Sto parlando con App Store Connect…';

  @override
  String ascDone(String version, String languages) {
    return 'Fatto su Apple: versione $version, lingue: $languages';
  }

  @override
  String get ascOpen => 'Apri App Store Connect';

  @override
  String get ascForget => 'Dimentica la chiave Apple';

  @override
  String get ascManual =>
      'Su Apple restano a mano: gli screenshot (misure iPhone), le domande sull\'età, prezzo e paesi.';

  @override
  String bAndroidFailed(String kind) {
    return 'Generazione $kind non riuscita';
  }

  @override
  String bAndroidReady(String kind) {
    return '$kind pronto ✓';
  }

  @override
  String get bStopped => 'Interrotto';

  @override
  String get bAppReady => 'App pronta ✓';

  @override
  String get bReviewStart =>
      'Altre AI stanno controllando l’app per conto loro…';

  @override
  String get bReviewClean =>
      'I revisori non hanno trovato niente da correggere.';

  @override
  String bReviewFound(int count) {
    return '$count problemi trovati dai revisori: li sto correggendo.';
  }

  @override
  String get bAppUpdated => 'App aggiornata ✓';

  @override
  String actWrites(String file) {
    return 'Scrive $file';
  }

  @override
  String actEdits(String file) {
    return 'Modifica $file';
  }

  @override
  String actReads(String file) {
    return 'Legge $file';
  }

  @override
  String get actPubGet => 'Installa le dipendenze';

  @override
  String get actAnalyze => 'Controlla gli errori';

  @override
  String get forgeTitle => 'Ember sta evocando la tua app';

  @override
  String forgeFiles(int count) {
    return '$count file evocati';
  }

  @override
  String researchingApp(String name) {
    return 'Studio “$name” su Google Play…';
  }

  @override
  String get pickReferenceApp => 'Quale app intendi?';

  @override
  String get pickReferenceAppHint =>
      'Ember studierà le sue funzioni su Google Play e creerà un\'app che fa le stesse cose, con nome e grafica tuoi.';

  @override
  String get referenceNone => 'Nessuna di queste, continua senza';

  @override
  String forgeFilesOf(int count, int total) {
    return '$count di $total file evocati';
  }

  @override
  String forgeEta(int minutes) {
    return 'circa $minutes min rimanenti';
  }

  @override
  String forgeEstimated(int minutes) {
    return 'tempo stimato circa $minutes min';
  }

  @override
  String forgeElapsed(String time) {
    return '$time trascorsi';
  }

  @override
  String get forgeBackground =>
      'Puoi spegnere lo schermo o usare altre app: Ember continua a lavorare e finisce l\'app.';

  @override
  String get buyCredits => 'Compra crediti API';

  @override
  String get getSubscription => 'Compra abbonamento';

  @override
  String get connectSubscription => 'Collega il mio abbonamento';

  @override
  String get accessTitle => 'Accesso e pagamenti';

  @override
  String get accessPaidOutside =>
      'I pagamenti si fanno sul sito del fornitore, non in Ember.';

  @override
  String subscriptionNotConnected(String name) {
    return '$name non è collegato: accedi con il tuo abbonamento sul PC del Runner.';
  }

  @override
  String connectHowTo(String plan, String command) {
    return 'Ember usa il tuo abbonamento $plan, con l\'accesso fatto sul PC dove gira il Runner (nessuna chiave API, nessun costo in più).\n\n1. Su quel PC apri un terminale (anche quello di Ember).\n2. Scrivi: $command\n3. Completa l\'accesso nel browser con il tuo account.\n\nTorna qui: il motore si attiva entro un minuto.';
  }

  @override
  String get connectPersonalNote =>
      'Gli abbonamenti sono personali: usali per le tue app, non per creare app per altre persone.';

  @override
  String get grokNoCli =>
      'Gli abbonamenti Grok (SuperGrok) non si possono ancora collegare ad altre app: usa una chiave API xAI.';

  @override
  String subscriptionConnected(String plan) {
    return 'Collegato al tuo abbonamento $plan: nessuna chiave API e nessun costo in più.';
  }

  @override
  String haveSubscription(String plan) {
    return 'Hai già $plan?';
  }

  @override
  String subscriptionReadyUse(String engine) {
    return 'Crea con $engine usando il tuo abbonamento, senza comprare crediti API.';
  }

  @override
  String subscriptionConnectFirst(String engine) {
    return 'Collegalo una volta per creare con $engine senza costi in più.';
  }

  @override
  String get useSubscription => 'Usalo';

  @override
  String get bResumeChat =>
      'Riprendi la creazione interrotta da dove si era fermata';

  @override
  String get backToEmber => 'Torna a Ember';

  @override
  String get productsTitle => 'Acquisti in app da attivare su Google Play';

  @override
  String get productsHint =>
      'Ember crea e attiva questi prodotti in Play Console per te, con i prezzi convertiti per ogni paese.';

  @override
  String get productsActivate => 'Crea e attiva su Play Console';

  @override
  String get productsNeedKey =>
      'Prima collega Google Play (chiave dell\'account di servizio): apri i passaggi di pubblicazione.';

  @override
  String get productsBefore =>
      'Prima di attivare, una sola volta per account/app:\n1. Play Console → Configurazione → Profilo pagamenti (conto bancario, dati fiscali)\n2. Carica l\'AAB di quest\'app nel test interno (Google vuole una versione con i pagamenti)\n3. Utenti e autorizzazioni → dai all\'account di servizio \"Gestisci ordini e abbonamenti\"';

  @override
  String get productsOpenPayments => 'Profilo pagamenti';

  @override
  String get productsUploadFirst => 'Carica AAB';

  @override
  String get productsActive => 'Attivo su Google Play ✓';

  @override
  String productPerPeriod(String price, String period) {
    return '$price / $period';
  }

  @override
  String productTrial(int days) {
    return 'prova gratuita di $days giorni';
  }

  @override
  String get logoTitle => 'Logo dell\'app';

  @override
  String get logoHint =>
      'Ember disegna 6 proposte. Non ti convincono? Premi “Altri loghi” quante volte vuoi. Quello che scegli diventa l\'icona dell\'app e l\'icona e il banner del Play Store.';

  @override
  String get logoDescribe => 'Descrivi il logo (facoltativo)';

  @override
  String get logoDescribeHint =>
      'Es.: scudo blu con una penna, moderno, senza scritte';

  @override
  String get logoGenerate => 'Genera 6 loghi';

  @override
  String get logoMore => 'Altri loghi';

  @override
  String get logoUse => 'Usa questo logo';

  @override
  String get logoApplied =>
      'Logo impostato: sto generando le icone dell\'app, l\'anteprima si aggiornerà.';

  @override
  String get shotsTitle => 'Screenshot per il Play Store';

  @override
  String get shotsHint =>
      'Ember apre l\'app come un telefono e fa 6 screenshot delle schermate principali (1080×1920), pronti per Google Play.';

  @override
  String get shotsPreparing =>
      'Ember sta preparando l\'app per gli screenshot (una modalità dimostrativa per ogni schermata): le foto partono da sole appena finisce.';

  @override
  String get shotsPreparingChat =>
      'Prepara l\'app per gli screenshot del Play Store';

  @override
  String get shotsGenerate => 'Fai 6 screenshot';

  @override
  String get shotsAgain => 'Rifai gli screenshot';

  @override
  String shotsSaved(int count) {
    return '$count screenshot salvati per Google Play.';
  }

  @override
  String get pubTitle => 'Pubblica con Ember';

  @override
  String pubAccountAsk(String app) {
    return 'Ciao! Ti guido a pubblicare **$app** su Google Play, un passo alla volta, e le parti tecniche le faccio io.\n\nPrima domanda: hai già un **account sviluppatore Google Play Console**?';
  }

  @override
  String get pubYesHaveIt => 'Sì, ce l\'ho';

  @override
  String get pubNoHowTo => 'No, come lo creo?';

  @override
  String get pubAccountHow =>
      'Crearlo richiede 10 minuti:\n1. Apri la pagina di registrazione (pulsante qui sotto) con il tuo account Google\n2. Scegli **Personale** (o Organizzazione se hai un\'azienda)\n3. Paga **25 \$ una sola volta**: vanno a Google, non a Ember\n4. Verifica l\'identità con un documento: di solito Google conferma in 1-2 giorni\n\nQuando l\'account è attivo, torna qui.';

  @override
  String get pubNowIHaveIt => 'Fatto, l\'account è attivo';

  @override
  String pubCreateApp(String package) {
    return 'Ora crea l\'app in Play Console (solo la prima volta):\n1. Premi **Apri Play Console** qui sotto, poi **Crea app**\n2. Nome dell\'app, lingua predefinita, tipo **App**, **Gratuita**\n3. Spunta le dichiarazioni e premi **Crea app**\n\nIl nome del pacchetto di quest\'app è `$package`: Google lo collega da solo al primo caricamento.';
  }

  @override
  String get pubDone => 'Fatto';

  @override
  String get pubConnect =>
      'Ora collego Ember a Google Play, così posso caricare le tue app. **Lo faccio io**: creo una chiave speciale nel tuo account Google su questo PC (progetto Google Cloud, API di Play e chiave). Serve solo per caricare le app e resta sul tuo dispositivo.';

  @override
  String get pubDoItEmber => 'Fallo tu, Ember';

  @override
  String get pubManual => 'Preferisco farlo a mano';

  @override
  String get pubKeyWorking =>
      'Creo il progetto Google Cloud, attivo l\'API di Play e creo la chiave (circa 1-2 minuti)…';

  @override
  String get pubInvite =>
      'Chiave creata ✓\n\nUltimo collegamento: la chiave deve avere il permesso di pubblicare nel **tuo** Play Console.\n1. Premi **Apri Play Console** qui sotto\n2. Copia l\'indirizzo della pagina che vedi (qualsiasi pagina) e **incollalo qui in chat**\n\nPoi si apre una volta il browser del PC: accedi con lo stesso account Google e premi **Consenti**. L\'invito lo mando io.';

  @override
  String get pubInviteBadLink =>
      'Quel link non contiene il numero dell\'account Play Console. Apri play.google.com/console e incolla l\'indirizzo di quella pagina.';

  @override
  String get pubInviteWorking =>
      'Invito la chiave nel tuo Play Console… se si apre il browser del PC, accedi e premi Consenti.';

  @override
  String pubInviteManual(String email) {
    return 'Non sono riuscito a mandare l\'invito da solo, facciamolo insieme (2 minuti):\n1. **Apri Play Console**, poi **Utenti e autorizzazioni** e **Invita nuovi utenti**\n2. Incolla questa email: `$email`\n3. **Autorizzazioni account**: spunta release, presenza nello store, contenuti dell\'app e ordini\n4. Premi **Invita utente**, poi **Fatto** qui';
  }

  @override
  String get pubGraphics =>
      'Collegato a Google Play ✓\n\nPer la pagina dello store Google vuole l\'**icona 512×512**, il **banner 1024×500** e almeno **2 screenshot**. Se non li hai ancora fatti, torna alla schermata dell\'app: in **Logo dell\'app** e **Screenshot per il Play Store** Ember li crea con un tocco. Li carico io in automatico insieme all\'app.';

  @override
  String get pubContinue => 'Continua';

  @override
  String get pubBackToApp => 'Torna all\'app';

  @override
  String get pubUpload =>
      'Ora la pagina dello store e il caricamento: scrivo titolo, descrizioni e privacy policy, preparo le risposte per i moduli di Google, poi carico l\'AAB firmato con icona, banner e screenshot.\n\nPrima genera l\'**AAB** dalla schermata dell\'app, se non l\'hai ancora fatto.';

  @override
  String get pubPrepareUpload => 'Prepara e carica';

  @override
  String get pubFinish =>
      'Ottimo, l\'app è su Google Play ✓\n\nGoogle chiede ancora di confermare a mano alcuni moduli in Play Console (**Sicurezza dei dati**, **Classificazione dei contenuti**, **Pubblico di destinazione**, **Annunci**, **Accesso all\'app**): le risposte pronte sono nell\'ultima schermata. Gli account personali nuovi devono anche fare un **test chiuso con 12 tester per 14 giorni** prima di andare pubblici.\n\nHai dubbi? Chiedimi qui sotto.';

  @override
  String get pubReviewAnswers => 'Vedi le risposte pronte';

  @override
  String get pubPasteLink => 'Incolla qui il link di Play Console…';

  @override
  String get pubAskAnything =>
      'Chiedi a Ember qualsiasi cosa sulla pubblicazione…';

  @override
  String get adsTitle => 'Pubblicità AdMob';

  @override
  String get adsHint =>
      'L\'app mostra già annunci di TEST di Google (sicuri durante lo sviluppo) e chiede il consenso UE. Per guadagnare crea le unità vere in AdMob e incolla qui gli ID: Ember li inserisce nell\'app.';

  @override
  String get adsSteps =>
      'In AdMob (5 minuti, una volta per app):\n1. App → Aggiungi app → Android → \"L\'app è su Google Play?\" (No se non è ancora pubblicata) → nome → Aggiungi\n2. Copia l\'ID app (ca-app-pub-…~…)\n3. Unità pubblicitarie → Aggiungi unità → scegli ogni formato qui sotto → Crea → copia il suo ID (ca-app-pub-…/…)\n4. Dopo la pubblicazione collega l\'app alla scheda del Play Store in AdMob e aggiungi app-ads.txt se AdMob lo chiede';

  @override
  String get adsOpenAdmob => 'Apri AdMob';

  @override
  String get adsAppId => 'ID app AdMob';

  @override
  String adsUnitId(String format) {
    return 'ID unità $format';
  }

  @override
  String get adsApply => 'Inserisci gli ID veri nell\'app';

  @override
  String get adsInvalid =>
      'Gli ID devono essere come ca-app-pub-1234567890123456~1234567890 (app) e ca-app-pub-1234567890123456/1234567890 (unità).';

  @override
  String get adsChat => 'Inserisci gli ID AdMob veri';

  @override
  String get pubNothingUploaded =>
      'Non è stato caricato niente su Google Play: nella schermata successiva premi \"Carica su Google Play\" e aspetta la conferma, poi torna qui.';

  @override
  String upListing(String languages) {
    return '✓ Scheda dello store (titolo e descrizioni): $languages';
  }

  @override
  String get upNoListing =>
      '✗ Scheda dello store non scritta (titolo e descrizioni erano vuoti)';

  @override
  String get upIcon => '✓ Icona 512×512';

  @override
  String get upNoIcon =>
      '✗ Icona mancante: prima scegli un logo in \"Logo dell\'app\"';

  @override
  String get upFeature => '✓ Banner 1024×500';

  @override
  String get upNoFeature =>
      '✗ Banner mancante: prima scegli un logo in \"Logo dell\'app\"';

  @override
  String upShots(int count) {
    return '✓ $count screenshot del telefono';
  }

  @override
  String get upNoShots =>
      '✗ Screenshot mancanti: prima falli in \"Screenshot per il Play Store\"';

  @override
  String get upTitle => 'Google Play';

  @override
  String get upHint =>
      'Per quest\'app è tutto salvato. Cambia quello che vuoi, poi manda una nuova versione: Ember crea un nuovo AAB firmato (versione più alta) e lo carica con scheda, logo e screenshot.';

  @override
  String get upStateLogo => 'Logo';

  @override
  String upStateShots(int count) {
    return 'Screenshot: $count';
  }

  @override
  String get upStateListing => 'Titolo e descrizioni';

  @override
  String get upEditListing => 'Modifica titolo e descrizioni';

  @override
  String get upNewVersion => 'Nuova versione su Google Play';

  @override
  String get upBuilding => 'Creo il nuovo AAB firmato…';

  @override
  String get upUploading => 'Carico su Google Play…';

  @override
  String get upNeedsSetup =>
      'Prima collega Google Play e scrivi la scheda una volta: apri la guida alla pubblicazione.';

  @override
  String get upOpenGuide => 'Guida alla pubblicazione';

  @override
  String get pubPasteConsoleLink =>
      'Consiglio: apri una volta Play Console e incolla qui in chat l\'indirizzo di quella pagina. Da quel momento ogni pulsante apre direttamente il **tuo** account, senza chiederti quale.';

  @override
  String get privacyPublicHint =>
      'Incolla un link pubblico che Google possa aprire (per esempio un gist GitHub o una pagina del tuo sito).';

  @override
  String get privacyLocalWarning =>
      'Questo indirizzo funziona solo su questo computer: Google non può aprirlo. Incolla invece un link pubblico.';

  @override
  String get consoleLinkLabel =>
      'Link della tua Play Console (incollalo una volta)';

  @override
  String get consoleLinkHint =>
      'Apri Play Console, scegli il tuo account sviluppatore, poi copia l\'indirizzo di quella pagina e incollalo qui: i pulsanti apriranno direttamente il tuo account e la tua app.';

  @override
  String consoleLinkSaved(String id) {
    return 'Salvato ✓ account sviluppatore $id: i pulsanti ora aprono direttamente la tua console.';
  }

  @override
  String get upStateConnected =>
      'Google Play collegato (chiave su questo dispositivo)';

  @override
  String get upNeedsKey =>
      'Google Play non è collegato su questo dispositivo: apri la guida alla pubblicazione e premi “Fallo tu, Ember” per creare la chiave (1 minuto).';

  @override
  String get upNeedsListing =>
      'Scrivi la scheda dello store una volta: premi “Modifica titolo e descrizioni”.';

  @override
  String get upConnectPlay => 'Collega Google Play';

  @override
  String get dsButton => 'Compila Sicurezza dei dati';

  @override
  String get dsWorking =>
      'Leggo cosa raccoglie l\'app e compilo il modulo Sicurezza dei dati…';

  @override
  String get dsDone =>
      'Sicurezza dei dati inviata a Google Play ✓ — controllala in Play Console → Contenuti dell\'app → Sicurezza dei dati e premi Invia.';

  @override
  String get dsNeedsCsv =>
      'Prima esporta il modulo da Play Console: Contenuti dell\'app → Sicurezza dei dati → Esporta in CSV. Salvalo in Download, poi premi di nuovo questo pulsante.';

  @override
  String get driveBackup => 'Salva su Google Drive';

  @override
  String get driveSaving =>
      'Chiedo il permesso a Google e salvo la chiave sul tuo Drive…';

  @override
  String get driveSaved => 'Keystore e password salvati sul tuo Google Drive ✓';

  @override
  String get driveOpenFolder => 'Apri la cartella su Drive';

  @override
  String get acAskPrivacy => 'Scrivi la privacy policy di questa app';

  @override
  String get acAskAdmob => 'Come aggiungo la pubblicità AdMob a questa app?';

  @override
  String get acAskContent =>
      'Cosa rispondo in Contenuti dell\'app su Play Console?';

  @override
  String get acAssistant => 'Chiedi a Ember di questa app';

  @override
  String get acTitle => 'Contenuti dell\'app (Play Console)';

  @override
  String get acHint =>
      'Google fa queste domande prima di pubblicare l\'app. Ember ha la risposta per ognuna: copiala e selezionala in Play Console.';

  @override
  String get acOpenConsole => 'Apri Contenuti dell\'app';

  @override
  String get acCopy => 'Copia risposta';

  @override
  String get acCopied => 'Copiato';

  @override
  String get acAuto => 'Lo fa Ember';

  @override
  String get paste => 'Incolla';

  @override
  String get ghSavedOn => 'Salvato su GitHub';

  @override
  String get ghTitle => 'Salva su GitHub';

  @override
  String get ghHint =>
      'Tiene una copia del codice di questa app in un tuo repository GitHub. La chiave di firma, la cartella build e i file Google non vengono mai caricati.';

  @override
  String get ghToken => 'Token GitHub';

  @override
  String get ghTokenHelp =>
      'Un token personale con il permesso \"repo\". Resta cifrato su questo dispositivo e serve solo per caricare questa app.';

  @override
  String get ghGetToken => 'Crea un token su GitHub';

  @override
  String get ghRestoreTitle => 'Apri un\'app salvata su GitHub';

  @override
  String get ghRestoreHint =>
      'Le app che hai salvato su GitHub tornano su questo computer con tutto quello che avevano. Così lavori sulla stessa app da Windows e dal Mac.';

  @override
  String get ghRestoreLoad => 'Mostra le mie app';

  @override
  String get ghRestoreNone =>
      'Su questo account GitHub non c\'è ancora nessuna app salvata da Ember.';

  @override
  String get ghRestoreHere => 'Già su questo computer';

  @override
  String get ghRestoreAction => 'Da GitHub';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get ghSave => 'Salva su GitHub';

  @override
  String get ghSaving => 'Carico l\'app su GitHub…';

  @override
  String get ghOpen => 'Apri il repository';

  @override
  String get ghForgetToken => 'Dimentica il token';

  @override
  String get ghNeedsToken => 'Prima incolla un token GitHub.';

  @override
  String ghCreated(String repo) {
    return 'Repository $repo creato e app caricata ✓';
  }

  @override
  String ghUpdated(String repo) {
    return 'App caricata su $repo ✓';
  }

  @override
  String get acCopyForExtension => 'Copia per l\'estensione';

  @override
  String get acFillForMe => 'Compila su Play Console';

  @override
  String get acFilling =>
      'Ember sta rispondendo alle domande nella finestra di Chrome che ha aperto. Guardalo, e prendi il comando quando vuoi.';

  @override
  String acFilled(int done, int total) {
    return 'Salvate $done sezioni su $total.';
  }

  @override
  String get acNeedsAppLink =>
      'Ember non sa ancora qual è questa app su Play Console: aprila lì, copia l\'indirizzo dal browser e incollalo nella schermata di pubblicazione.';

  @override
  String get acAppLink => 'Indirizzo di questa app su Play Console';

  @override
  String get acLinkNotUnderstood =>
      'Quell\'indirizzo non indica un\'app. Apri l\'app su Play Console e copia tutto l\'indirizzo dalla barra del browser.';

  @override
  String get adsAdd => 'Aggiungi pubblicità AdMob';

  @override
  String get adsAddHint =>
      'Ember mette la pubblicità su ogni schermata che può portarla, entro i limiti che tengono vivo un account AdMob, e usa gli annunci di prova di Google finché non incolli i tuoi identificativi.';

  @override
  String get adsAddChat =>
      'Aggiungi la pubblicità AdMob con gli annunci di prova';

  @override
  String get adsYes => 'Sì, metti la pubblicità';

  @override
  String get adsNo => 'Niente pubblicità';

  @override
  String get adsDeclined =>
      'Nessuna pubblicità in questa app. Chiedila a Ember quando cambi idea.';

  @override
  String get adsRemove => 'Togli la pubblicità';

  @override
  String get adsRemoveChat => 'Togli AdMob da questa app';

  @override
  String get adsAppIdHelp =>
      'Il codice con la ~ , quello accanto all\'icona Android. È lo stesso per tutte le unità.';

  @override
  String get adsUnitHelp =>
      'Il codice con la / , quello accanto all\'icona della scheda. Uno diverso per ogni formato.';

  @override
  String get checkTitle => 'Ember ha controllato questa app';

  @override
  String get checkAllGood =>
      'Tutto quello che serve per far funzionare l\'app c\'è.';

  @override
  String checkFound(int count) {
    return '$count cose non funzionano ancora. Quelle con l\'icona della chiave Ember le sistema, se glielo dici tu.';
  }

  @override
  String checkFixNow(int count) {
    return 'Sistema $count cose';
  }

  @override
  String get checkFixing => 'Sto sistemando…';

  @override
  String get checkAgain => 'Controlla di nuovo';

  @override
  String get checkAskEmber => 'Fallo sistemare a Ember';

  @override
  String get checkAsked =>
      'Chiesto. Ember ci sta lavorando: guarda la chat qui sotto.';

  @override
  String get previewLoginInBrowser =>
      'Google non fa accedere dentro questa finestra, e un login fatto nel browser non vale qui. In questa finestra usa email e password; il login Google funziona nel browser e sul telefono.';

  @override
  String get phoneTitle => 'Il tuo telefono';

  @override
  String get phoneHint =>
      'Ember installa l\'app sul telefono collegato a questo computer e la apre. Login Google, notifiche e pubblicità si comportano davvero come devono solo lì.';

  @override
  String phoneRunOn(String name) {
    return 'Avvia su $name';
  }

  @override
  String phoneUnauthorized(String name) {
    return '$name: sbloccalo e consenti il debug USB';
  }

  @override
  String get phoneBuilding => 'Preparo l\'app per il telefono…';

  @override
  String get phoneInstalling => 'Installo sul telefono…';

  @override
  String get phoneLookAgain => 'Cerca di nuovo i telefoni';

  @override
  String get phoneOpenHere => 'Apri subito sul telefono';

  @override
  String get phoneSameWifi =>
      'Inquadra il codice con la fotocamera del telefono. Il telefono deve essere sullo stesso Wi-Fi di questo computer.';

  @override
  String get playLanguages => 'Lingue della scheda';

  @override
  String get playTranslating => 'Scrivo la scheda nelle altre lingue…';
}
