// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'FlutterCursor';

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
  String get projects => 'Progetti';

  @override
  String get noProjects => 'Nessun progetto. Creane uno per iniziare.';

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
      'Es.: un\'app di ricette con foto, lista della spesa e timer di cottura, colori caldi…';

  @override
  String get chooseAi => 'Con quale AI?';

  @override
  String get createApp => 'Crea app';

  @override
  String get openEditor => 'Editor';

  @override
  String get describeYourApp => 'Descrivi la tua app';

  @override
  String get describeYourAppHint =>
      'Scrivi cosa deve fare e come deve essere: l\'AI crea l\'app completa, controlla gli errori e te la mostra. (*Gemini: quota gratuita di Google con limiti giornalieri)';

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
  String get bestQuality => 'Qualità massima';

  @override
  String get bestQualityOn =>
      'Modello più potente: più lento, per app complesse';

  @override
  String get bestQualityOff =>
      'Veloce (consigliato): ideale per la maggior parte delle app';

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
      'Scorri o premi indietro per tornare a FlutterCursor';

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
      'Serve un account sviluppatore Google Play Console. Costo: 25 \$ una sola volta (non è un abbonamento), pagati direttamente a Google, non a FlutterCursor.';

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
  String get playStepConnect => 'Collega FlutterCursor a Google Play';

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
}
