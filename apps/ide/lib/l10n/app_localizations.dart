import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'FlutterCursor'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Crea app Flutter da qualsiasi dispositivo, con l\'AI.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In it, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @runnerUrl.
  ///
  /// In it, this message translates to:
  /// **'URL Runner'**
  String get runnerUrl;

  /// No description provided for @signIn.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In it, this message translates to:
  /// **'Registrati'**
  String get signUp;

  /// No description provided for @devLoginHint.
  ///
  /// In it, this message translates to:
  /// **'Modalità sviluppo: Supabase non configurato, accesso solo con email tramite il Runner.'**
  String get devLoginHint;

  /// No description provided for @invalidEmail.
  ///
  /// In it, this message translates to:
  /// **'Email non valida'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In it, this message translates to:
  /// **'Almeno 6 caratteri'**
  String get passwordTooShort;

  /// No description provided for @signOut.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get signOut;

  /// No description provided for @projects.
  ///
  /// In it, this message translates to:
  /// **'Progetti'**
  String get projects;

  /// No description provided for @noProjects.
  ///
  /// In it, this message translates to:
  /// **'Nessun progetto. Creane uno per iniziare.'**
  String get noProjects;

  /// No description provided for @newProject.
  ///
  /// In it, this message translates to:
  /// **'Nuovo progetto'**
  String get newProject;

  /// No description provided for @projectName.
  ///
  /// In it, this message translates to:
  /// **'Nome progetto'**
  String get projectName;

  /// No description provided for @projectNameHelp.
  ///
  /// In it, this message translates to:
  /// **'minuscolo, lettere/numeri/_ (es. my_app)'**
  String get projectNameHelp;

  /// No description provided for @create.
  ///
  /// In it, this message translates to:
  /// **'Crea'**
  String get create;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In it, this message translates to:
  /// **'Rinomina'**
  String get rename;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get retry;

  /// No description provided for @statusCreating.
  ///
  /// In it, this message translates to:
  /// **'In creazione…'**
  String get statusCreating;

  /// No description provided for @statusReady.
  ///
  /// In it, this message translates to:
  /// **'Pronto'**
  String get statusReady;

  /// No description provided for @statusError.
  ///
  /// In it, this message translates to:
  /// **'Errore'**
  String get statusError;

  /// No description provided for @creatingProject.
  ///
  /// In it, this message translates to:
  /// **'Creazione di {name}'**
  String creatingProject(String name);

  /// No description provided for @files.
  ///
  /// In it, this message translates to:
  /// **'File'**
  String get files;

  /// No description provided for @editor.
  ///
  /// In it, this message translates to:
  /// **'Editor'**
  String get editor;

  /// No description provided for @newFile.
  ///
  /// In it, this message translates to:
  /// **'Nuovo file'**
  String get newFile;

  /// No description provided for @newFolder.
  ///
  /// In it, this message translates to:
  /// **'Nuova cartella'**
  String get newFolder;

  /// No description provided for @fileName.
  ///
  /// In it, this message translates to:
  /// **'Nome'**
  String get fileName;

  /// No description provided for @deleteConfirm.
  ///
  /// In it, this message translates to:
  /// **'Eliminare {path}?'**
  String deleteConfirm(String path);

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In it, this message translates to:
  /// **'Salvato'**
  String get saved;

  /// No description provided for @unsavedChanges.
  ///
  /// In it, this message translates to:
  /// **'Modifiche non salvate'**
  String get unsavedChanges;

  /// No description provided for @discard.
  ///
  /// In it, this message translates to:
  /// **'Scarta'**
  String get discard;

  /// No description provided for @noFileOpen.
  ///
  /// In it, this message translates to:
  /// **'Apri un file dall\'albero a sinistra.'**
  String get noFileOpen;

  /// No description provided for @conflictTitle.
  ///
  /// In it, this message translates to:
  /// **'File modificato altrove'**
  String get conflictTitle;

  /// No description provided for @conflictBody.
  ///
  /// In it, this message translates to:
  /// **'{path} è cambiato sul Runner dopo che l\'hai aperto.'**
  String conflictBody(String path);

  /// No description provided for @reload.
  ///
  /// In it, this message translates to:
  /// **'Ricarica'**
  String get reload;

  /// No description provided for @overwrite.
  ///
  /// In it, this message translates to:
  /// **'Sovrascrivi'**
  String get overwrite;

  /// No description provided for @connected.
  ///
  /// In it, this message translates to:
  /// **'Connesso'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In it, this message translates to:
  /// **'Connessione…'**
  String get connecting;

  /// No description provided for @disconnected.
  ///
  /// In it, this message translates to:
  /// **'Disconnesso'**
  String get disconnected;

  /// No description provided for @error.
  ///
  /// In it, this message translates to:
  /// **'Errore: {message}'**
  String error(String message);

  /// No description provided for @binaryFile.
  ///
  /// In it, this message translates to:
  /// **'File binario o troppo grande: non modificabile nell\'editor.'**
  String get binaryFile;

  /// No description provided for @terminal.
  ///
  /// In it, this message translates to:
  /// **'Terminale'**
  String get terminal;

  /// No description provided for @newTerminal.
  ///
  /// In it, this message translates to:
  /// **'Nuovo terminale'**
  String get newTerminal;

  /// No description provided for @toggleTerminal.
  ///
  /// In it, this message translates to:
  /// **'Mostra/nascondi terminale'**
  String get toggleTerminal;

  /// No description provided for @restart.
  ///
  /// In it, this message translates to:
  /// **'Riavvia'**
  String get restart;

  /// No description provided for @preview.
  ///
  /// In it, this message translates to:
  /// **'Anteprima'**
  String get preview;

  /// No description provided for @togglePreview.
  ///
  /// In it, this message translates to:
  /// **'Mostra/nascondi anteprima'**
  String get togglePreview;

  /// No description provided for @runWeb.
  ///
  /// In it, this message translates to:
  /// **'Avvia Web'**
  String get runWeb;

  /// No description provided for @building.
  ///
  /// In it, this message translates to:
  /// **'Compilazione…'**
  String get building;

  /// No description provided for @buildFailed.
  ///
  /// In it, this message translates to:
  /// **'Compilazione fallita: controlla il log qui sotto.'**
  String get buildFailed;

  /// No description provided for @reloadPreview.
  ///
  /// In it, this message translates to:
  /// **'Ricarica anteprima'**
  String get reloadPreview;

  /// No description provided for @device.
  ///
  /// In it, this message translates to:
  /// **'Dispositivo'**
  String get device;

  /// No description provided for @openInBrowser.
  ///
  /// In it, this message translates to:
  /// **'Apri nel browser'**
  String get openInBrowser;

  /// No description provided for @openOnOtherDevice.
  ///
  /// In it, this message translates to:
  /// **'Apri su un altro dispositivo'**
  String get openOnOtherDevice;

  /// No description provided for @qrLocalhostWarning.
  ///
  /// In it, this message translates to:
  /// **'Questo indirizzo funziona solo su questo computer. Usa l\'IP di rete del Runner (es. http://192.168.1.20:8787) per aprirlo dal telefono.'**
  String get qrLocalhostWarning;

  /// No description provided for @copy.
  ///
  /// In it, this message translates to:
  /// **'Copia'**
  String get copy;

  /// No description provided for @close.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get close;

  /// No description provided for @console.
  ///
  /// In it, this message translates to:
  /// **'Console'**
  String get console;

  /// No description provided for @autoRebuild.
  ///
  /// In it, this message translates to:
  /// **'Ricompila al salvataggio'**
  String get autoRebuild;

  /// No description provided for @previewEmpty.
  ///
  /// In it, this message translates to:
  /// **'Premi «Avvia Web» per compilare l\'app e vederla qui. Ogni salvataggio aggiorna l\'anteprima.'**
  String get previewEmpty;

  /// No description provided for @ai.
  ///
  /// In it, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @toggleAi.
  ///
  /// In it, this message translates to:
  /// **'Mostra/nascondi pannello AI'**
  String get toggleAi;

  /// No description provided for @aiSettings.
  ///
  /// In it, this message translates to:
  /// **'Chiavi API e modelli'**
  String get aiSettings;

  /// No description provided for @apiKeysHint.
  ///
  /// In it, this message translates to:
  /// **'Le chiavi restano cifrate su questo dispositivo (archivio sicuro). Con il proxy attivo passano dal tuo Runner solo per la singola richiesta e non vengono salvate né registrate nei log.'**
  String get apiKeysHint;

  /// No description provided for @useRunnerProxy.
  ///
  /// In it, this message translates to:
  /// **'Passa dal Runner (proxy)'**
  String get useRunnerProxy;

  /// No description provided for @useRunnerProxyHint.
  ///
  /// In it, this message translates to:
  /// **'Consigliato. Disattiva per chiamare i provider direttamente da questo dispositivo.'**
  String get useRunnerProxyHint;

  /// No description provided for @useRunnerProxyWeb.
  ///
  /// In it, this message translates to:
  /// **'Sul web è obbligatorio: il browser non può chiamare i provider direttamente.'**
  String get useRunnerProxyWeb;

  /// No description provided for @apiKey.
  ///
  /// In it, this message translates to:
  /// **'Chiave API'**
  String get apiKey;

  /// No description provided for @apiKeyOptional.
  ///
  /// In it, this message translates to:
  /// **'Chiave API (se richiesta)'**
  String get apiKeyOptional;

  /// No description provided for @replaceApiKey.
  ///
  /// In it, this message translates to:
  /// **'Sostituisci chiave'**
  String get replaceApiKey;

  /// No description provided for @testKey.
  ///
  /// In it, this message translates to:
  /// **'Prova'**
  String get testKey;

  /// No description provided for @testing.
  ///
  /// In it, this message translates to:
  /// **'Prova in corso…'**
  String get testing;

  /// No description provided for @keyWorks.
  ///
  /// In it, this message translates to:
  /// **'Funziona ✓ ({model})'**
  String keyWorks(String model);

  /// No description provided for @getKey.
  ///
  /// In it, this message translates to:
  /// **'Ottieni una chiave'**
  String get getKey;

  /// No description provided for @addModelId.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi ID modello'**
  String get addModelId;

  /// No description provided for @selectModel.
  ///
  /// In it, this message translates to:
  /// **'Scegli modello'**
  String get selectModel;

  /// No description provided for @keyPresent.
  ///
  /// In it, this message translates to:
  /// **'chiave presente'**
  String get keyPresent;

  /// No description provided for @notConfigured.
  ///
  /// In it, this message translates to:
  /// **'non configurato'**
  String get notConfigured;

  /// No description provided for @per1k.
  ///
  /// In it, this message translates to:
  /// **'per 1k token (in/out)'**
  String get per1k;

  /// No description provided for @applyTo.
  ///
  /// In it, this message translates to:
  /// **'Applica a {path}'**
  String applyTo(String path);

  /// No description provided for @noChanges.
  ///
  /// In it, this message translates to:
  /// **'Nessuna differenza rispetto al file attuale.'**
  String get noChanges;

  /// No description provided for @accept.
  ///
  /// In it, this message translates to:
  /// **'Accetta'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In it, this message translates to:
  /// **'Rifiuta'**
  String get reject;

  /// No description provided for @apply.
  ///
  /// In it, this message translates to:
  /// **'Applica'**
  String get apply;

  /// No description provided for @applied.
  ///
  /// In it, this message translates to:
  /// **'Modifica applicata a {path}: controlla e salva.'**
  String applied(String path);

  /// No description provided for @applyNoTarget.
  ///
  /// In it, this message translates to:
  /// **'Apri un file o chiedi all\'AI di indicare il percorso del file.'**
  String get applyNoTarget;

  /// No description provided for @clearChat.
  ///
  /// In it, this message translates to:
  /// **'Svuota chat'**
  String get clearChat;

  /// No description provided for @chatEmpty.
  ///
  /// In it, this message translates to:
  /// **'Chiedi qualcosa sul tuo progetto. Il file aperto viene inviato come contesto.'**
  String get chatEmpty;

  /// No description provided for @chatNoKeys.
  ///
  /// In it, this message translates to:
  /// **'Per usare l\'AI inserisci almeno una chiave API (Claude, ChatGPT o Gemini).'**
  String get chatNoKeys;

  /// No description provided for @attachOpenFile.
  ///
  /// In it, this message translates to:
  /// **'Allega il file aperto come contesto'**
  String get attachOpenFile;

  /// No description provided for @askAi.
  ///
  /// In it, this message translates to:
  /// **'Chiedi all\'AI…  (Ctrl+Invio per inviare)'**
  String get askAi;

  /// No description provided for @send.
  ///
  /// In it, this message translates to:
  /// **'Invia'**
  String get send;

  /// No description provided for @stop.
  ///
  /// In it, this message translates to:
  /// **'Ferma'**
  String get stop;

  /// No description provided for @copied.
  ///
  /// In it, this message translates to:
  /// **'Copiato'**
  String get copied;

  /// No description provided for @truncated.
  ///
  /// In it, this message translates to:
  /// **'risposta troncata (limite token)'**
  String get truncated;

  /// No description provided for @refused.
  ///
  /// In it, this message translates to:
  /// **'rifiutata dal modello'**
  String get refused;

  /// No description provided for @stopped.
  ///
  /// In it, this message translates to:
  /// **'interrotta'**
  String get stopped;

  /// No description provided for @badgeFreeTier.
  ///
  /// In it, this message translates to:
  /// **'gratis*'**
  String get badgeFreeTier;

  /// No description provided for @badgeSubscription.
  ///
  /// In it, this message translates to:
  /// **'abbonamento'**
  String get badgeSubscription;

  /// No description provided for @badgePaid.
  ///
  /// In it, this message translates to:
  /// **'a pagamento'**
  String get badgePaid;

  /// No description provided for @needsKey.
  ///
  /// In it, this message translates to:
  /// **'Serve una chiave API {name}: aggiungila nelle impostazioni.'**
  String needsKey(String name);

  /// No description provided for @claudeCodeUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Claude Code non è disponibile su questo Runner (serve Claude Code installato e con login sul PC del Runner).'**
  String get claudeCodeUnavailable;

  /// No description provided for @appPromptHint.
  ///
  /// In it, this message translates to:
  /// **'Es.: un\'app di ricette con foto, lista della spesa e timer di cottura, colori caldi…'**
  String get appPromptHint;

  /// No description provided for @chooseAi.
  ///
  /// In it, this message translates to:
  /// **'Con quale AI?'**
  String get chooseAi;

  /// No description provided for @createApp.
  ///
  /// In it, this message translates to:
  /// **'Crea app'**
  String get createApp;

  /// No description provided for @openEditor.
  ///
  /// In it, this message translates to:
  /// **'Editor'**
  String get openEditor;

  /// No description provided for @describeYourApp.
  ///
  /// In it, this message translates to:
  /// **'Descrivi la tua app'**
  String get describeYourApp;

  /// No description provided for @describeYourAppHint.
  ///
  /// In it, this message translates to:
  /// **'Scrivi cosa deve fare e come deve essere: l\'AI crea l\'app completa, controlla gli errori e te la mostra. (*Gemini: quota gratuita di Google con limiti giornalieri)'**
  String get describeYourAppHint;

  /// No description provided for @improveApp.
  ///
  /// In it, this message translates to:
  /// **'Cosa vuoi aggiungere o migliorare?'**
  String get improveApp;

  /// No description provided for @improveAppHint.
  ///
  /// In it, this message translates to:
  /// **'Descrivi le prossime funzioni o modifiche, es.: aggiungi le videochiamate, il login con Google, le stanze private… Puoi anche incollare qui le chiavi che ti chiede l\'AI.'**
  String get improveAppHint;

  /// No description provided for @applyChange.
  ///
  /// In it, this message translates to:
  /// **'Applica modifica'**
  String get applyChange;

  /// No description provided for @buildLog.
  ///
  /// In it, this message translates to:
  /// **'Dettagli'**
  String get buildLog;

  /// No description provided for @stepClaudeCode.
  ///
  /// In it, this message translates to:
  /// **'Claude Code scrive e verifica il codice'**
  String get stepClaudeCode;

  /// No description provided for @stepWriting.
  ///
  /// In it, this message translates to:
  /// **'Scrittura del codice ({count} file)'**
  String stepWriting(int count);

  /// No description provided for @stepDependencies.
  ///
  /// In it, this message translates to:
  /// **'Installazione dipendenze'**
  String get stepDependencies;

  /// No description provided for @stepChecking.
  ///
  /// In it, this message translates to:
  /// **'Controllo errori'**
  String get stepChecking;

  /// No description provided for @stepFixing.
  ///
  /// In it, this message translates to:
  /// **'Correzione errori (tentativo {round})'**
  String stepFixing(int round);

  /// No description provided for @stepBuilding.
  ///
  /// In it, this message translates to:
  /// **'Compilazione dell\'app'**
  String get stepBuilding;

  /// No description provided for @stepReady.
  ///
  /// In it, this message translates to:
  /// **'Pronta'**
  String get stepReady;

  /// No description provided for @appReadyTitle.
  ///
  /// In it, this message translates to:
  /// **'La tua app è pronta 🎉'**
  String get appReadyTitle;

  /// No description provided for @openApp.
  ///
  /// In it, this message translates to:
  /// **'Apri app'**
  String get openApp;

  /// No description provided for @viewCode.
  ///
  /// In it, this message translates to:
  /// **'Vedi codice'**
  String get viewCode;

  /// No description provided for @buildCancelled.
  ///
  /// In it, this message translates to:
  /// **'Creazione interrotta'**
  String get buildCancelled;

  /// No description provided for @buildFailedTitle.
  ///
  /// In it, this message translates to:
  /// **'Non sono riuscito a completare l\'app'**
  String get buildFailedTitle;

  /// No description provided for @bestQuality.
  ///
  /// In it, this message translates to:
  /// **'Qualità massima'**
  String get bestQuality;

  /// No description provided for @bestQualityOn.
  ///
  /// In it, this message translates to:
  /// **'Modello più potente: più lento, per app complesse'**
  String get bestQualityOn;

  /// No description provided for @bestQualityOff.
  ///
  /// In it, this message translates to:
  /// **'Veloce (consigliato): ideale per la maggior parte delle app'**
  String get bestQualityOff;

  /// No description provided for @androidFileQuestion.
  ///
  /// In it, this message translates to:
  /// **'Vuoi il file per Android?'**
  String get androidFileQuestion;

  /// No description provided for @androidFileHint.
  ///
  /// In it, this message translates to:
  /// **'APK: da installare sul telefono. AAB: da caricare sulla Google Play Console. Entrambi firmati.'**
  String get androidFileHint;

  /// No description provided for @generateApk.
  ///
  /// In it, this message translates to:
  /// **'Genera APK'**
  String get generateApk;

  /// No description provided for @generateAab.
  ///
  /// In it, this message translates to:
  /// **'Genera AAB'**
  String get generateAab;

  /// No description provided for @androidBuilding.
  ///
  /// In it, this message translates to:
  /// **'Genero {kind}… la prima volta può richiedere 3-5 minuti.'**
  String androidBuilding(String kind);

  /// No description provided for @downloadApk.
  ///
  /// In it, this message translates to:
  /// **'Scarica e installa APK'**
  String get downloadApk;

  /// No description provided for @downloadAab.
  ///
  /// In it, this message translates to:
  /// **'Scarica AAB'**
  String get downloadAab;

  /// No description provided for @apkInstallHint.
  ///
  /// In it, this message translates to:
  /// **'APK firmato. Se Android lo chiede, consenti l\'installazione da questa fonte.'**
  String get apkInstallHint;

  /// No description provided for @aabHint.
  ///
  /// In it, this message translates to:
  /// **'AAB firmato con la chiave di caricamento di questa app: pronto per la Google Play Console. Il numero di versione sale da solo a ogni build.'**
  String get aabHint;

  /// No description provided for @androidFailed.
  ///
  /// In it, this message translates to:
  /// **'Generazione non riuscita:'**
  String get androidFailed;

  /// No description provided for @backupSigningKey.
  ///
  /// In it, this message translates to:
  /// **'Salva chiave di firma'**
  String get backupSigningKey;

  /// No description provided for @backupSigningKeyHint.
  ///
  /// In it, this message translates to:
  /// **'Conserva il file della chiave e la password in un posto sicuro (es. Google Drive): servono per pubblicare gli aggiornamenti di questa app sul Play Store. Il link funziona una sola volta per 10 minuti.'**
  String get backupSigningKeyHint;

  /// No description provided for @downloadKeystore.
  ///
  /// In it, this message translates to:
  /// **'Scarica file chiave'**
  String get downloadKeystore;

  /// No description provided for @fullscreenExitHint.
  ///
  /// In it, this message translates to:
  /// **'Scorri o premi indietro per tornare a FlutterCursor'**
  String get fullscreenExitHint;

  /// No description provided for @runFullscreen.
  ///
  /// In it, this message translates to:
  /// **'Avvia a schermo intero'**
  String get runFullscreen;

  /// No description provided for @cliNotInstalled.
  ///
  /// In it, this message translates to:
  /// **'non installato sul Runner ({name})'**
  String cliNotInstalled(String name);

  /// No description provided for @terminalCliHint.
  ///
  /// In it, this message translates to:
  /// **'Claude Code, Codex e Gemini usano il login fatto sul PC del Runner. La prima volta segui le istruzioni nel terminale per accedere.'**
  String get terminalCliHint;

  /// No description provided for @generatingMockups.
  ///
  /// In it, this message translates to:
  /// **'Creo 5 stili grafici…'**
  String get generatingMockups;

  /// No description provided for @designingStyle.
  ///
  /// In it, this message translates to:
  /// **'Disegno lo stile «{style}»…'**
  String designingStyle(String style);

  /// No description provided for @chooseMockup.
  ///
  /// In it, this message translates to:
  /// **'Scegli questo'**
  String get chooseMockup;

  /// No description provided for @editMockup.
  ///
  /// In it, this message translates to:
  /// **'Modifica questo mockup'**
  String get editMockup;

  /// No description provided for @editMockupHint.
  ///
  /// In it, this message translates to:
  /// **'Es.: più scuro, bottoni arrotondati, logo rosa…'**
  String get editMockupHint;

  /// No description provided for @newMockups.
  ///
  /// In it, this message translates to:
  /// **'Nuovi mockup (5 stili diversi)'**
  String get newMockups;

  /// No description provided for @previousMockups.
  ///
  /// In it, this message translates to:
  /// **'Mockup precedenti'**
  String get previousMockups;

  /// No description provided for @mockupSet.
  ///
  /// In it, this message translates to:
  /// **'Serie {n}'**
  String mockupSet(int n);

  /// No description provided for @skipMockups.
  ///
  /// In it, this message translates to:
  /// **'Salta i mockup e crea l\'app'**
  String get skipMockups;

  /// No description provided for @playAskUpload.
  ///
  /// In it, this message translates to:
  /// **'Vuoi caricare l\'app sul Google Play Store?'**
  String get playAskUpload;

  /// No description provided for @playYesUpload.
  ///
  /// In it, this message translates to:
  /// **'Sì, carica sul Play Store'**
  String get playYesUpload;

  /// No description provided for @playNotNow.
  ///
  /// In it, this message translates to:
  /// **'Non ora'**
  String get playNotNow;

  /// No description provided for @playFeeNotice.
  ///
  /// In it, this message translates to:
  /// **'Serve un account sviluppatore Google Play Console. Costo: 25 \$ una sola volta (non è un abbonamento), pagati direttamente a Google, non a FlutterCursor.'**
  String get playFeeNotice;

  /// No description provided for @playPublishTitle.
  ///
  /// In it, this message translates to:
  /// **'Pubblica su Google Play'**
  String get playPublishTitle;

  /// No description provided for @playStepAccount.
  ///
  /// In it, this message translates to:
  /// **'Account Google Play Console'**
  String get playStepAccount;

  /// No description provided for @playOpenSignup.
  ///
  /// In it, this message translates to:
  /// **'Crea account Play Console'**
  String get playOpenSignup;

  /// No description provided for @playHaveAccount.
  ///
  /// In it, this message translates to:
  /// **'Ho già un account Play Console attivo'**
  String get playHaveAccount;

  /// No description provided for @next.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get next;

  /// No description provided for @playStepCreateApp.
  ///
  /// In it, this message translates to:
  /// **'Crea l\'app nel Play Console'**
  String get playStepCreateApp;

  /// No description provided for @playCreateAppGuide.
  ///
  /// In it, this message translates to:
  /// **'Google richiede questo passaggio a mano, solo la prima volta:\n1. Apri **Play Console** → **Crea app**\n2. Nome app, lingua predefinita **Italiano**, tipo **App**, **Gratuita**\n3. Accetta le dichiarazioni e premi **Crea app**\n\nIl package name verrà associato automaticamente al primo caricamento: usa quello qui sotto.'**
  String get playCreateAppGuide;

  /// No description provided for @playPackageName.
  ///
  /// In it, this message translates to:
  /// **'Package name'**
  String get playPackageName;

  /// No description provided for @playOpenConsole.
  ///
  /// In it, this message translates to:
  /// **'Apri Play Console'**
  String get playOpenConsole;

  /// No description provided for @playAppCreated.
  ///
  /// In it, this message translates to:
  /// **'Ho creato l\'app nel Play Console'**
  String get playAppCreated;

  /// No description provided for @playStepConnect.
  ///
  /// In it, this message translates to:
  /// **'Collega FlutterCursor a Google Play'**
  String get playStepConnect;

  /// No description provided for @playConnectGuide.
  ///
  /// In it, this message translates to:
  /// **'Serve una **chiave di account di servizio** (una sola volta per tutte le tue app):\n1. Apri **Google Cloud** e attiva l\'API **Google Play Android Developer API**\n2. Vai su **Account di servizio** → **Crea account di servizio** → poi **Chiavi** → **Aggiungi chiave** → **JSON** (si scarica un file)\n3. Nel **Play Console** → **Utenti e autorizzazioni** → **Invita nuovi utenti** → incolla l\'email dell\'account di servizio → dai i permessi di **rilascio** per le tue app\n4. Apri il file JSON scaricato e **incolla qui tutto il contenuto**\n\nLa chiave resta salvata cifrata su questo dispositivo e viene usata solo per il caricamento.'**
  String get playConnectGuide;

  /// No description provided for @playOpenApiLibrary.
  ///
  /// In it, this message translates to:
  /// **'Attiva API Google Play'**
  String get playOpenApiLibrary;

  /// No description provided for @playOpenServiceAccounts.
  ///
  /// In it, this message translates to:
  /// **'Account di servizio'**
  String get playOpenServiceAccounts;

  /// No description provided for @playServiceAccountJson.
  ///
  /// In it, this message translates to:
  /// **'Contenuto del file JSON dell\'account di servizio'**
  String get playServiceAccountJson;

  /// No description provided for @playStepListing.
  ///
  /// In it, this message translates to:
  /// **'Scheda dello store e caricamento'**
  String get playStepListing;

  /// No description provided for @playGenerateWithAi.
  ///
  /// In it, this message translates to:
  /// **'Genera scheda, privacy policy e risposte con l\'AI'**
  String get playGenerateWithAi;

  /// No description provided for @playTitle.
  ///
  /// In it, this message translates to:
  /// **'Titolo (max 30)'**
  String get playTitle;

  /// No description provided for @playShortDescription.
  ///
  /// In it, this message translates to:
  /// **'Descrizione breve (max 80)'**
  String get playShortDescription;

  /// No description provided for @playFullDescription.
  ///
  /// In it, this message translates to:
  /// **'Descrizione completa'**
  String get playFullDescription;

  /// No description provided for @playReleaseNotes.
  ///
  /// In it, this message translates to:
  /// **'Note di versione'**
  String get playReleaseNotes;

  /// No description provided for @playContactEmail.
  ///
  /// In it, this message translates to:
  /// **'Email di contatto (obbligatoria su Play Store)'**
  String get playContactEmail;

  /// No description provided for @playPrivacyUrl.
  ///
  /// In it, this message translates to:
  /// **'Link privacy policy'**
  String get playPrivacyUrl;

  /// No description provided for @playTrack.
  ///
  /// In it, this message translates to:
  /// **'Dove pubblicare'**
  String get playTrack;

  /// No description provided for @playTrackInternal.
  ///
  /// In it, this message translates to:
  /// **'Test interno (consigliato per iniziare)'**
  String get playTrackInternal;

  /// No description provided for @playTrackClosed.
  ///
  /// In it, this message translates to:
  /// **'Test chiuso'**
  String get playTrackClosed;

  /// No description provided for @playTrackProduction.
  ///
  /// In it, this message translates to:
  /// **'Produzione (pubblico)'**
  String get playTrackProduction;

  /// No description provided for @playUpload.
  ///
  /// In it, this message translates to:
  /// **'Carica su Google Play'**
  String get playUpload;

  /// No description provided for @playStepFinish.
  ///
  /// In it, this message translates to:
  /// **'Completa nel Play Console'**
  String get playStepFinish;

  /// No description provided for @playUploaded.
  ///
  /// In it, this message translates to:
  /// **'✅ Caricata! Versione {version} sulla traccia «{track}». {draft}'**
  String playUploaded(String version, String track, String draft);

  /// No description provided for @playDraftNote.
  ///
  /// In it, this message translates to:
  /// **'Poiché l\'app non è ancora mai stata pubblicata, Google l\'ha salvata come bozza: completa i passaggi qui sotto e premi «Invia per la revisione» nel Play Console.'**
  String get playDraftNote;

  /// No description provided for @playManualChecklist.
  ///
  /// In it, this message translates to:
  /// **'Google richiede di confermare a mano queste voci nel Play Console (le risposte pronte sono qui sotto):\n- **Norme sulla privacy** → incolla il link: {privacyUrl}\n- **Sicurezza dei dati**\n- **Classificazione dei contenuti** (questionario)\n- **Pubblico di destinazione e contenuti**\n- **Annunci** e **Accesso all\'app** (se serve il login, fornisci un account di prova)\n- **Scheda dello store**: icona 512×512 e almeno 2 screenshot\n- Account personali nuovi: Google può richiedere un **test chiuso** con un numero minimo di tester prima della produzione'**
  String playManualChecklist(String privacyUrl);

  /// No description provided for @playDataSafety.
  ///
  /// In it, this message translates to:
  /// **'Risposte per «Sicurezza dei dati»'**
  String get playDataSafety;

  /// No description provided for @playContentRating.
  ///
  /// In it, this message translates to:
  /// **'Risposte per «Classificazione dei contenuti»'**
  String get playContentRating;

  /// No description provided for @playOtherDeclarations.
  ///
  /// In it, this message translates to:
  /// **'Pubblico, annunci e accesso all\'app'**
  String get playOtherDeclarations;

  /// No description provided for @assistantTitle.
  ///
  /// In it, this message translates to:
  /// **'Assistente AI'**
  String get assistantTitle;

  /// No description provided for @assistantFree.
  ///
  /// In it, this message translates to:
  /// **'Gratis'**
  String get assistantFree;

  /// No description provided for @assistantEmpty.
  ///
  /// In it, this message translates to:
  /// **'Ciao! Chiedimi qualsiasi cosa: idee per la tua app, come pubblicarla sul Play Store, come configurare login e database…'**
  String get assistantEmpty;

  /// No description provided for @assistantUnconfigured.
  ///
  /// In it, this message translates to:
  /// **'L\'assistente gratuito non è ancora attivo su questo server (manca la chiave Gemini del Runner).'**
  String get assistantUnconfigured;

  /// No description provided for @assistantHint.
  ///
  /// In it, this message translates to:
  /// **'Scrivi una domanda…'**
  String get assistantHint;

  /// No description provided for @assistantSuggest1.
  ///
  /// In it, this message translates to:
  /// **'Che app posso creare per il mio negozio?'**
  String get assistantSuggest1;

  /// No description provided for @assistantSuggest2.
  ///
  /// In it, this message translates to:
  /// **'Come pubblico un\'app sul Play Store?'**
  String get assistantSuggest2;

  /// No description provided for @assistantSuggest3.
  ///
  /// In it, this message translates to:
  /// **'Come funziona il login con Google?'**
  String get assistantSuggest3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
