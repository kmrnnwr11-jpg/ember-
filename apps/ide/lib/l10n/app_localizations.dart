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
