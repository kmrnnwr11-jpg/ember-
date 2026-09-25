import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
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
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ember – App Maker'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build Flutter apps from any device, with AI.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @runnerUrl.
  ///
  /// In en, this message translates to:
  /// **'Runner URL'**
  String get runnerUrl;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @devLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Development mode: Supabase not configured, email-only sign in through the Runner.'**
  String get devLoginHint;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Your apps'**
  String get projects;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No apps summoned yet. Describe one above.'**
  String get noProjects;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @projectNameHelp.
  ///
  /// In en, this message translates to:
  /// **'lowercase, letters/digits/_ (e.g. my_app)'**
  String get projectNameHelp;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @statusCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get statusCreating;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// No description provided for @creatingProject.
  ///
  /// In en, this message translates to:
  /// **'Creating {name}'**
  String creatingProject(String name);

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// No description provided for @newFile.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get newFile;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fileName;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {path}?'**
  String deleteConfirm(String path);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @noFileOpen.
  ///
  /// In en, this message translates to:
  /// **'Open a file from the tree.'**
  String get noFileOpen;

  /// No description provided for @conflictTitle.
  ///
  /// In en, this message translates to:
  /// **'File changed elsewhere'**
  String get conflictTitle;

  /// No description provided for @conflictBody.
  ///
  /// In en, this message translates to:
  /// **'{path} changed on the Runner after you opened it.'**
  String conflictBody(String path);

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// No description provided for @binaryFile.
  ///
  /// In en, this message translates to:
  /// **'Binary or too large: cannot be edited.'**
  String get binaryFile;

  /// No description provided for @terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// No description provided for @newTerminal.
  ///
  /// In en, this message translates to:
  /// **'New terminal'**
  String get newTerminal;

  /// No description provided for @toggleTerminal.
  ///
  /// In en, this message translates to:
  /// **'Toggle terminal'**
  String get toggleTerminal;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @togglePreview.
  ///
  /// In en, this message translates to:
  /// **'Toggle preview'**
  String get togglePreview;

  /// No description provided for @runWeb.
  ///
  /// In en, this message translates to:
  /// **'Run Web'**
  String get runWeb;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building…'**
  String get building;

  /// No description provided for @buildFailed.
  ///
  /// In en, this message translates to:
  /// **'Build failed: see the log below.'**
  String get buildFailed;

  /// No description provided for @reloadPreview.
  ///
  /// In en, this message translates to:
  /// **'Reload preview'**
  String get reloadPreview;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @openOnOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'Open on another device'**
  String get openOnOtherDevice;

  /// No description provided for @qrLocalhostWarning.
  ///
  /// In en, this message translates to:
  /// **'This address only works on this computer. Use the Runner\'s LAN IP (e.g. http://192.168.1.20:8787) to open it from a phone.'**
  String get qrLocalhostWarning;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @console.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get console;

  /// No description provided for @autoRebuild.
  ///
  /// In en, this message translates to:
  /// **'Rebuild on save'**
  String get autoRebuild;

  /// No description provided for @previewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Press “Run Web” to build the app and see it here. Every save refreshes the preview.'**
  String get previewEmpty;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @toggleAi.
  ///
  /// In en, this message translates to:
  /// **'Toggle AI panel'**
  String get toggleAi;

  /// No description provided for @aiSettings.
  ///
  /// In en, this message translates to:
  /// **'API keys & models'**
  String get aiSettings;

  /// No description provided for @apiKeysHint.
  ///
  /// In en, this message translates to:
  /// **'Keys stay encrypted on this device (secure storage). With the proxy on they pass through your Runner for each request only and are never stored or logged.'**
  String get apiKeysHint;

  /// No description provided for @useRunnerProxy.
  ///
  /// In en, this message translates to:
  /// **'Route through Runner (proxy)'**
  String get useRunnerProxy;

  /// No description provided for @useRunnerProxyHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended. Turn off to call providers directly from this device.'**
  String get useRunnerProxyHint;

  /// No description provided for @useRunnerProxyWeb.
  ///
  /// In en, this message translates to:
  /// **'Required on web: browsers cannot call providers directly.'**
  String get useRunnerProxyWeb;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @apiKeyOptional.
  ///
  /// In en, this message translates to:
  /// **'API key (if required)'**
  String get apiKeyOptional;

  /// No description provided for @replaceApiKey.
  ///
  /// In en, this message translates to:
  /// **'Replace key'**
  String get replaceApiKey;

  /// No description provided for @testKey.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get testKey;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get testing;

  /// No description provided for @keyWorks.
  ///
  /// In en, this message translates to:
  /// **'Works ✓ ({model})'**
  String keyWorks(String model);

  /// No description provided for @getKey.
  ///
  /// In en, this message translates to:
  /// **'Get a key'**
  String get getKey;

  /// No description provided for @addModelId.
  ///
  /// In en, this message translates to:
  /// **'Add model ID'**
  String get addModelId;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select model'**
  String get selectModel;

  /// No description provided for @keyPresent.
  ///
  /// In en, this message translates to:
  /// **'key present'**
  String get keyPresent;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'not configured'**
  String get notConfigured;

  /// No description provided for @per1k.
  ///
  /// In en, this message translates to:
  /// **'per 1k tokens (in/out)'**
  String get per1k;

  /// No description provided for @applyTo.
  ///
  /// In en, this message translates to:
  /// **'Apply to {path}'**
  String applyTo(String path);

  /// No description provided for @noChanges.
  ///
  /// In en, this message translates to:
  /// **'No differences from the current file.'**
  String get noChanges;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @applied.
  ///
  /// In en, this message translates to:
  /// **'Change applied to {path}: review and save.'**
  String applied(String path);

  /// No description provided for @applyNoTarget.
  ///
  /// In en, this message translates to:
  /// **'Open a file or ask the AI to include the file path.'**
  String get applyNoTarget;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get clearChat;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ask about your project. The open file is sent as context.'**
  String get chatEmpty;

  /// No description provided for @chatNoKeys.
  ///
  /// In en, this message translates to:
  /// **'Add at least one API key (Claude, ChatGPT or Gemini) to use AI.'**
  String get chatNoKeys;

  /// No description provided for @attachOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Attach the open file as context'**
  String get attachOpenFile;

  /// No description provided for @askAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI…  (Ctrl+Enter to send)'**
  String get askAi;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @truncated.
  ///
  /// In en, this message translates to:
  /// **'truncated (token limit)'**
  String get truncated;

  /// No description provided for @refused.
  ///
  /// In en, this message translates to:
  /// **'declined by the model'**
  String get refused;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'stopped'**
  String get stopped;

  /// No description provided for @badgeFreeTier.
  ///
  /// In en, this message translates to:
  /// **'free*'**
  String get badgeFreeTier;

  /// No description provided for @badgeSubscription.
  ///
  /// In en, this message translates to:
  /// **'subscription'**
  String get badgeSubscription;

  /// No description provided for @badgePaid.
  ///
  /// In en, this message translates to:
  /// **'paid'**
  String get badgePaid;

  /// No description provided for @needsKey.
  ///
  /// In en, this message translates to:
  /// **'Needs a {name} API key: add it in settings.'**
  String needsKey(String name);

  /// No description provided for @claudeCodeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Claude Code is not available on this Runner (it must be installed and logged in on the Runner\'s PC).'**
  String get claudeCodeUnavailable;

  /// No description provided for @appPromptHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: a recipe app with photos, shopping list and cooking timer…'**
  String get appPromptHint;

  /// No description provided for @chooseAi.
  ///
  /// In en, this message translates to:
  /// **'Choose the engine'**
  String get chooseAi;

  /// No description provided for @createApp.
  ///
  /// In en, this message translates to:
  /// **'Ember App'**
  String get createApp;

  /// No description provided for @openEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get openEditor;

  /// No description provided for @describeYourApp.
  ///
  /// In en, this message translates to:
  /// **'Summon your app'**
  String get describeYourApp;

  /// No description provided for @describeYourAppHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what it should do and how it should look. Ember writes it, checks it and shows it to you. (*Gemini: Google\'s free tier with daily limits)'**
  String get describeYourAppHint;

  /// No description provided for @improveApp.
  ///
  /// In en, this message translates to:
  /// **'What would you like to add or improve?'**
  String get improveApp;

  /// No description provided for @improveAppHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the next features or changes, e.g.: add video calls, Google login, private rooms… You can also paste the keys the AI asks for here.'**
  String get improveAppHint;

  /// No description provided for @applyChange.
  ///
  /// In en, this message translates to:
  /// **'Apply change'**
  String get applyChange;

  /// No description provided for @buildLog.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get buildLog;

  /// No description provided for @stepClaudeCode.
  ///
  /// In en, this message translates to:
  /// **'Claude Code writes and verifies the code'**
  String get stepClaudeCode;

  /// No description provided for @stepWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing code ({count} files)'**
  String stepWriting(int count);

  /// No description provided for @stepDependencies.
  ///
  /// In en, this message translates to:
  /// **'Installing dependencies'**
  String get stepDependencies;

  /// No description provided for @stepChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for errors'**
  String get stepChecking;

  /// No description provided for @stepFixing.
  ///
  /// In en, this message translates to:
  /// **'Fixing errors (attempt {round})'**
  String stepFixing(int round);

  /// No description provided for @stepBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building the app'**
  String get stepBuilding;

  /// No description provided for @stepReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get stepReady;

  /// No description provided for @appReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your app is ready 🎉'**
  String get appReadyTitle;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open app'**
  String get openApp;

  /// No description provided for @viewCode.
  ///
  /// In en, this message translates to:
  /// **'View code'**
  String get viewCode;

  /// No description provided for @buildCancelled.
  ///
  /// In en, this message translates to:
  /// **'Build stopped'**
  String get buildCancelled;

  /// No description provided for @buildFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t finish the app'**
  String get buildFailedTitle;

  /// No description provided for @bestQuality.
  ///
  /// In en, this message translates to:
  /// **'Maximum power'**
  String get bestQuality;

  /// No description provided for @bestQualityOn.
  ///
  /// In en, this message translates to:
  /// **'Most powerful engine: slower, for complex apps'**
  String get bestQualityOn;

  /// No description provided for @bestQualityOff.
  ///
  /// In en, this message translates to:
  /// **'Fast (recommended): right for most apps'**
  String get bestQualityOff;

  /// No description provided for @androidFileQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want the Android file?'**
  String get androidFileQuestion;

  /// No description provided for @androidFileHint.
  ///
  /// In en, this message translates to:
  /// **'APK: install on a phone. AAB: upload to Google Play Console. Both signed.'**
  String get androidFileHint;

  /// No description provided for @generateApk.
  ///
  /// In en, this message translates to:
  /// **'Build APK'**
  String get generateApk;

  /// No description provided for @generateAab.
  ///
  /// In en, this message translates to:
  /// **'Build AAB'**
  String get generateAab;

  /// No description provided for @androidBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building {kind}… the first time can take 3-5 minutes.'**
  String androidBuilding(String kind);

  /// No description provided for @downloadApk.
  ///
  /// In en, this message translates to:
  /// **'Download & install APK'**
  String get downloadApk;

  /// No description provided for @downloadAab.
  ///
  /// In en, this message translates to:
  /// **'Download AAB'**
  String get downloadAab;

  /// No description provided for @apkInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Signed APK. If Android asks, allow installs from this source.'**
  String get apkInstallHint;

  /// No description provided for @aabHint.
  ///
  /// In en, this message translates to:
  /// **'AAB signed with this app\'s upload key: ready for Google Play Console. The version code increases on every build.'**
  String get aabHint;

  /// No description provided for @androidFailed.
  ///
  /// In en, this message translates to:
  /// **'Build failed:'**
  String get androidFailed;

  /// No description provided for @backupSigningKey.
  ///
  /// In en, this message translates to:
  /// **'Save signing key'**
  String get backupSigningKey;

  /// No description provided for @backupSigningKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Keep the key file and password somewhere safe (e.g. Google Drive): you need them to publish updates of this app on Google Play. The link works once, for 10 minutes.'**
  String get backupSigningKeyHint;

  /// No description provided for @downloadKeystore.
  ///
  /// In en, this message translates to:
  /// **'Download key file'**
  String get downloadKeystore;

  /// No description provided for @fullscreenExitHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe or press back to return to Ember'**
  String get fullscreenExitHint;

  /// No description provided for @runFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Run full screen'**
  String get runFullscreen;

  /// No description provided for @cliNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'not installed on the Runner ({name})'**
  String cliNotInstalled(String name);

  /// No description provided for @terminalCliHint.
  ///
  /// In en, this message translates to:
  /// **'Claude Code, Codex and Gemini use the login on the Runner\'s machine. The first time, follow the instructions in the terminal to sign in.'**
  String get terminalCliHint;

  /// No description provided for @generatingMockups.
  ///
  /// In en, this message translates to:
  /// **'Creating 5 visual styles…'**
  String get generatingMockups;

  /// No description provided for @designingStyle.
  ///
  /// In en, this message translates to:
  /// **'Designing “{style}”…'**
  String designingStyle(String style);

  /// No description provided for @chooseMockup.
  ///
  /// In en, this message translates to:
  /// **'Choose this'**
  String get chooseMockup;

  /// No description provided for @editMockup.
  ///
  /// In en, this message translates to:
  /// **'Edit this mockup'**
  String get editMockup;

  /// No description provided for @editMockupHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: darker, rounded buttons, pink logo…'**
  String get editMockupHint;

  /// No description provided for @newMockups.
  ///
  /// In en, this message translates to:
  /// **'New mockups (5 different styles)'**
  String get newMockups;

  /// No description provided for @previousMockups.
  ///
  /// In en, this message translates to:
  /// **'Previous mockups'**
  String get previousMockups;

  /// No description provided for @mockupSet.
  ///
  /// In en, this message translates to:
  /// **'Set {n}'**
  String mockupSet(int n);

  /// No description provided for @skipMockups.
  ///
  /// In en, this message translates to:
  /// **'Skip mockups and build the app'**
  String get skipMockups;

  /// No description provided for @playAskUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload the app to Google Play Store?'**
  String get playAskUpload;

  /// No description provided for @playYesUpload.
  ///
  /// In en, this message translates to:
  /// **'Yes, upload to Play Store'**
  String get playYesUpload;

  /// No description provided for @playNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get playNotNow;

  /// No description provided for @playFeeNotice.
  ///
  /// In en, this message translates to:
  /// **'You need a Google Play Console developer account. Cost: \$25 one time (not a subscription), paid directly to Google, not to Ember.'**
  String get playFeeNotice;

  /// No description provided for @playPublishTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish to Google Play'**
  String get playPublishTitle;

  /// No description provided for @playStepAccount.
  ///
  /// In en, this message translates to:
  /// **'Google Play Console account'**
  String get playStepAccount;

  /// No description provided for @playOpenSignup.
  ///
  /// In en, this message translates to:
  /// **'Create Play Console account'**
  String get playOpenSignup;

  /// No description provided for @playHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an active Play Console account'**
  String get playHaveAccount;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @playStepCreateApp.
  ///
  /// In en, this message translates to:
  /// **'Create the app in Play Console'**
  String get playStepCreateApp;

  /// No description provided for @playCreateAppGuide.
  ///
  /// In en, this message translates to:
  /// **'Google requires this step manually, only the first time:\n1. Open **Play Console** → **Create app**\n2. App name, default language, type **App**, **Free**\n3. Accept the declarations and press **Create app**\n\nThe package name is linked on the first upload: use the one below.'**
  String get playCreateAppGuide;

  /// No description provided for @playPackageName.
  ///
  /// In en, this message translates to:
  /// **'Package name'**
  String get playPackageName;

  /// No description provided for @playOpenConsole.
  ///
  /// In en, this message translates to:
  /// **'Open Play Console'**
  String get playOpenConsole;

  /// No description provided for @playAppCreated.
  ///
  /// In en, this message translates to:
  /// **'I created the app in Play Console'**
  String get playAppCreated;

  /// No description provided for @playStepConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Ember to Google Play'**
  String get playStepConnect;

  /// No description provided for @playConnectGuide.
  ///
  /// In en, this message translates to:
  /// **'You need a **service account key** (once for all your apps):\n1. Open **Google Cloud** and enable **Google Play Android Developer API**\n2. **Service accounts** → **Create** → **Keys** → **Add key** → **JSON** (a file downloads)\n3. In **Play Console** → **Users and permissions** → **Invite new users** → paste the service account email → grant **release** permissions\n4. Open the downloaded JSON and **paste its whole content here**\n\nThe key stays encrypted on this device and is used only for uploads.'**
  String get playConnectGuide;

  /// No description provided for @playOpenApiLibrary.
  ///
  /// In en, this message translates to:
  /// **'Enable Google Play API'**
  String get playOpenApiLibrary;

  /// No description provided for @playOpenServiceAccounts.
  ///
  /// In en, this message translates to:
  /// **'Service accounts'**
  String get playOpenServiceAccounts;

  /// No description provided for @playServiceAccountJson.
  ///
  /// In en, this message translates to:
  /// **'Service account JSON content'**
  String get playServiceAccountJson;

  /// No description provided for @playStepListing.
  ///
  /// In en, this message translates to:
  /// **'Store listing and upload'**
  String get playStepListing;

  /// No description provided for @playGenerateWithAi.
  ///
  /// In en, this message translates to:
  /// **'Generate listing, privacy policy and answers with AI'**
  String get playGenerateWithAi;

  /// No description provided for @playTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (max 30)'**
  String get playTitle;

  /// No description provided for @playShortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description (max 80)'**
  String get playShortDescription;

  /// No description provided for @playFullDescription.
  ///
  /// In en, this message translates to:
  /// **'Full description'**
  String get playFullDescription;

  /// No description provided for @playReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release notes'**
  String get playReleaseNotes;

  /// No description provided for @playContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email (required on Play Store)'**
  String get playContactEmail;

  /// No description provided for @playPrivacyUrl.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy link'**
  String get playPrivacyUrl;

  /// No description provided for @playTrack.
  ///
  /// In en, this message translates to:
  /// **'Where to publish'**
  String get playTrack;

  /// No description provided for @playTrackInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal testing (recommended first)'**
  String get playTrackInternal;

  /// No description provided for @playTrackClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed testing'**
  String get playTrackClosed;

  /// No description provided for @playTrackProduction.
  ///
  /// In en, this message translates to:
  /// **'Production (public)'**
  String get playTrackProduction;

  /// No description provided for @playUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload to Google Play'**
  String get playUpload;

  /// No description provided for @playStepFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish in Play Console'**
  String get playStepFinish;

  /// No description provided for @playUploaded.
  ///
  /// In en, this message translates to:
  /// **'✅ Uploaded! Version {version} on track “{track}”. {draft}'**
  String playUploaded(String version, String track, String draft);

  /// No description provided for @playDraftNote.
  ///
  /// In en, this message translates to:
  /// **'Because the app was never published, Google saved it as a draft: complete the steps below and press “Send for review” in Play Console.'**
  String get playDraftNote;

  /// No description provided for @playReviewNotSent.
  ///
  /// In en, this message translates to:
  /// **'Google could not send the changes for review automatically. They are committed: open Play Console and press \"Send for review\" to publish.'**
  String get playReviewNotSent;

  /// No description provided for @playManualChecklist.
  ///
  /// In en, this message translates to:
  /// **'Google requires confirming these manually in Play Console (ready answers below):\n- **Privacy policy** → paste the link: {privacyUrl}\n- **Data safety**\n- **Content rating** questionnaire\n- **Target audience and content**\n- **Ads** and **App access** (provide a test account if login is required)\n- **Store listing**: 512×512 icon and at least 2 screenshots\n- New personal accounts: Google may require **closed testing** with a minimum number of testers before production'**
  String playManualChecklist(String privacyUrl);

  /// No description provided for @playDataSafety.
  ///
  /// In en, this message translates to:
  /// **'Answers for “Data safety”'**
  String get playDataSafety;

  /// No description provided for @playContentRating.
  ///
  /// In en, this message translates to:
  /// **'Answers for “Content rating”'**
  String get playContentRating;

  /// No description provided for @playOtherDeclarations.
  ///
  /// In en, this message translates to:
  /// **'Audience, ads and app access'**
  String get playOtherDeclarations;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask Ember'**
  String get assistantTitle;

  /// No description provided for @assistantFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get assistantFree;

  /// No description provided for @assistantEmpty.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m Ember! Ask me anything: app ideas, how to publish on Play Store, how to set up login and databases…'**
  String get assistantEmpty;

  /// No description provided for @assistantUnconfigured.
  ///
  /// In en, this message translates to:
  /// **'The free assistant is not active on this server yet (the Runner\'s Gemini key is missing).'**
  String get assistantUnconfigured;

  /// No description provided for @assistantHint.
  ///
  /// In en, this message translates to:
  /// **'Ask Ember anything…'**
  String get assistantHint;

  /// No description provided for @assistantSuggest1.
  ///
  /// In en, this message translates to:
  /// **'What app can I build for my shop?'**
  String get assistantSuggest1;

  /// No description provided for @assistantSuggest2.
  ///
  /// In en, this message translates to:
  /// **'How do I publish an app on Play Store?'**
  String get assistantSuggest2;

  /// No description provided for @assistantSuggest3.
  ///
  /// In en, this message translates to:
  /// **'How does Google login work?'**
  String get assistantSuggest3;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @find.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get find;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @replaceAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get replaceAll;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @fontLabel.
  ///
  /// In en, this message translates to:
  /// **'Font: {font}'**
  String fontLabel(String font);

  /// No description provided for @styleMinimal.
  ///
  /// In en, this message translates to:
  /// **'Light minimal'**
  String get styleMinimal;

  /// No description provided for @styleDark.
  ///
  /// In en, this message translates to:
  /// **'Dark premium'**
  String get styleDark;

  /// No description provided for @stylePlayful.
  ///
  /// In en, this message translates to:
  /// **'Colorful & playful'**
  String get stylePlayful;

  /// No description provided for @styleGlass.
  ///
  /// In en, this message translates to:
  /// **'Glassmorphism'**
  String get styleGlass;

  /// No description provided for @styleMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material 3'**
  String get styleMaterial;

  /// No description provided for @styleNeumorph.
  ///
  /// In en, this message translates to:
  /// **'Neumorphism'**
  String get styleNeumorph;

  /// No description provided for @styleLuxury.
  ///
  /// In en, this message translates to:
  /// **'Elegant luxury'**
  String get styleLuxury;

  /// No description provided for @styleBrutal.
  ///
  /// In en, this message translates to:
  /// **'Bold brutalist'**
  String get styleBrutal;

  /// No description provided for @stylePastel.
  ///
  /// In en, this message translates to:
  /// **'Soft pastel'**
  String get stylePastel;

  /// No description provided for @styleTech.
  ///
  /// In en, this message translates to:
  /// **'Futuristic tech'**
  String get styleTech;

  /// No description provided for @styleNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get styleNature;

  /// No description provided for @styleIos.
  ///
  /// In en, this message translates to:
  /// **'iOS style'**
  String get styleIos;

  /// No description provided for @styleRetro.
  ///
  /// In en, this message translates to:
  /// **'80s retro'**
  String get styleRetro;

  /// No description provided for @styleMono.
  ///
  /// In en, this message translates to:
  /// **'Monochrome'**
  String get styleMono;

  /// No description provided for @styleCorporate.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get styleCorporate;

  /// No description provided for @bWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing the code with {model}…'**
  String bWriting(String model);

  /// No description provided for @bApplying.
  ///
  /// In en, this message translates to:
  /// **'Applying the change with {model}: {change}'**
  String bApplying(String change, String model);

  /// No description provided for @bNoModel.
  ///
  /// In en, this message translates to:
  /// **'No model selected'**
  String get bNoModel;

  /// No description provided for @bNoFiles.
  ///
  /// In en, this message translates to:
  /// **'The AI did not produce any files: try again or change model.'**
  String get bNoFiles;

  /// No description provided for @bErrorsRemain.
  ///
  /// In en, this message translates to:
  /// **'Errors remain after {count} fix attempts:\n{problems}'**
  String bErrorsRemain(int count, String problems);

  /// No description provided for @bFixing.
  ///
  /// In en, this message translates to:
  /// **'Fixing errors (attempt {round} of {max})…'**
  String bFixing(int max, int round);

  /// No description provided for @bNoFixes.
  ///
  /// In en, this message translates to:
  /// **'The AI did not propose fixes for:\n{problems}'**
  String bNoFixes(String problems);

  /// No description provided for @bIncompleteFile.
  ///
  /// In en, this message translates to:
  /// **'Incomplete file ignored: {path}'**
  String bIncompleteFile(String path);

  /// No description provided for @bPathNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Path not allowed, ignored: {path}'**
  String bPathNotAllowed(String path);

  /// No description provided for @bTruncated.
  ///
  /// In en, this message translates to:
  /// **'Response cut by the token limit: incomplete files will be recreated during fixing.'**
  String get bTruncated;

  /// No description provided for @bRefused.
  ///
  /// In en, this message translates to:
  /// **'The model declined the request.'**
  String get bRefused;

  /// No description provided for @bPubGet.
  ///
  /// In en, this message translates to:
  /// **'Installing dependencies (flutter pub get)…'**
  String get bPubGet;

  /// No description provided for @bPubGetFailed.
  ///
  /// In en, this message translates to:
  /// **'flutter pub get failed'**
  String get bPubGetFailed;

  /// No description provided for @bAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Checking for errors (flutter analyze)…'**
  String get bAnalyze;

  /// No description provided for @bNoErrors.
  ///
  /// In en, this message translates to:
  /// **'No errors ✓'**
  String get bNoErrors;

  /// No description provided for @bErrorsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} errors found'**
  String bErrorsFound(int count);

  /// No description provided for @bClaudeApplying.
  ///
  /// In en, this message translates to:
  /// **'Claude Code is applying the change…'**
  String get bClaudeApplying;

  /// No description provided for @bClaudeBuilding.
  ///
  /// In en, this message translates to:
  /// **'Claude Code is building the app on the PC…'**
  String get bClaudeBuilding;

  /// No description provided for @bClaudeFailed.
  ///
  /// In en, this message translates to:
  /// **'Claude Code did not finish the app: check the log.'**
  String get bClaudeFailed;

  /// No description provided for @bWebBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building the app for the web (about 30 seconds)…'**
  String get bWebBuilding;

  /// No description provided for @bWebFailed.
  ///
  /// In en, this message translates to:
  /// **'The web build failed:\n{log}'**
  String bWebFailed(String log);

  /// No description provided for @bApk.
  ///
  /// In en, this message translates to:
  /// **'Building the APK (the first time can take a few minutes)…'**
  String get bApk;

  /// No description provided for @bAab.
  ///
  /// In en, this message translates to:
  /// **'Building the AAB for the Play Store…'**
  String get bAab;

  /// No description provided for @chooseDesignAi.
  ///
  /// In en, this message translates to:
  /// **'Who draws (logo, mockups, screens)'**
  String get chooseDesignAi;

  /// No description provided for @chooseDesignAiHint.
  ///
  /// In en, this message translates to:
  /// **'Gemini draws well and is free; the engine above writes the code.'**
  String get chooseDesignAiHint;

  /// No description provided for @bLookingAtModel.
  ///
  /// In en, this message translates to:
  /// **'Looking at the app being copied…'**
  String get bLookingAtModel;

  /// No description provided for @bIpa.
  ///
  /// In en, this message translates to:
  /// **'Building the iPhone app (IPA)…'**
  String get bIpa;

  /// No description provided for @nameTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your app called?'**
  String get nameTitle;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'This name goes on the Play Store, in the privacy policy and into the package name, which can never change once Google has it.'**
  String get nameHint;

  /// No description provided for @nameYourOwn.
  ///
  /// In en, this message translates to:
  /// **'Or write your own name'**
  String get nameYourOwn;

  /// No description provided for @nameMore.
  ///
  /// In en, this message translates to:
  /// **'Other names'**
  String get nameMore;

  /// No description provided for @nameUse.
  ///
  /// In en, this message translates to:
  /// **'Use this name'**
  String get nameUse;

  /// No description provided for @bReferenceShots.
  ///
  /// In en, this message translates to:
  /// **'{count} screens of the app to copy saved: the engine can see it, not just read about it'**
  String bReferenceShots(int count);

  /// No description provided for @bReferenceShotsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch the screens of the app to copy: working from its description only'**
  String get bReferenceShotsFailed;

  /// No description provided for @bMissingTopics.
  ///
  /// In en, this message translates to:
  /// **'Missing from the app to copy: {topics}. Adding them now…'**
  String bMissingTopics(String topics);

  /// No description provided for @bIosReady.
  ///
  /// In en, this message translates to:
  /// **'iPhone app ready ✓'**
  String get bIosReady;

  /// No description provided for @bIosFailed.
  ///
  /// In en, this message translates to:
  /// **'iPhone build failed'**
  String get bIosFailed;

  /// No description provided for @platformAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get platformAndroid;

  /// No description provided for @platformIos.
  ///
  /// In en, this message translates to:
  /// **'iPhone'**
  String get platformIos;

  /// No description provided for @iosTitle.
  ///
  /// In en, this message translates to:
  /// **'iPhone app'**
  String get iosTitle;

  /// No description provided for @iosHint.
  ///
  /// In en, this message translates to:
  /// **'The same app for iPhone and iPad: same name, same screens, same ads. The file (IPA) goes to App Store Connect.'**
  String get iosHint;

  /// No description provided for @iosNeedsMac.
  ///
  /// In en, this message translates to:
  /// **'Only a Mac can build the iPhone app. Save this app on GitHub, open Ember on your Mac and build it there. Everything else works from here.'**
  String get iosNeedsMac;

  /// No description provided for @iosBuild.
  ///
  /// In en, this message translates to:
  /// **'Build iPhone app'**
  String get iosBuild;

  /// No description provided for @iosBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building the iPhone app…'**
  String get iosBuilding;

  /// No description provided for @iosReady.
  ///
  /// In en, this message translates to:
  /// **'iPhone app ready. It is signed with your Apple account and can go to App Store Connect.'**
  String get iosReady;

  /// No description provided for @iosAppleAccount.
  ///
  /// In en, this message translates to:
  /// **'Apple Developer account: 99 USD a year, paid to Apple.'**
  String get iosAppleAccount;

  /// No description provided for @ascTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to the App Store'**
  String get ascTitle;

  /// No description provided for @ascHint.
  ///
  /// In en, this message translates to:
  /// **'Ember writes on Apple what it writes on Google: title, description, what\'s new, privacy address and the privacy answers, in every language of your listing.'**
  String get ascHint;

  /// No description provided for @ascKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'In App Store Connect: Users and Access → Integrations → App Store Connect API → + . Choose the App Manager role, then download the .p8 file (Apple lets you download it once).'**
  String get ascKeyHelp;

  /// No description provided for @ascKeyId.
  ///
  /// In en, this message translates to:
  /// **'Key ID'**
  String get ascKeyId;

  /// No description provided for @ascIssuerId.
  ///
  /// In en, this message translates to:
  /// **'Issuer ID'**
  String get ascIssuerId;

  /// No description provided for @ascPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Contents of the AuthKey_….p8 file'**
  String get ascPrivateKey;

  /// No description provided for @ascUploadBuild.
  ///
  /// In en, this message translates to:
  /// **'Send the iPhone file too (needs a Mac)'**
  String get ascUploadBuild;

  /// No description provided for @ascSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send for Apple\'s review when everything is set'**
  String get ascSubmit;

  /// No description provided for @ascPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish on the App Store'**
  String get ascPublish;

  /// No description provided for @ascWorking.
  ///
  /// In en, this message translates to:
  /// **'Talking to App Store Connect…'**
  String get ascWorking;

  /// No description provided for @ascDone.
  ///
  /// In en, this message translates to:
  /// **'Done on Apple: version {version}, languages: {languages}'**
  String ascDone(String version, String languages);

  /// No description provided for @ascOpen.
  ///
  /// In en, this message translates to:
  /// **'Open App Store Connect'**
  String get ascOpen;

  /// No description provided for @ascForget.
  ///
  /// In en, this message translates to:
  /// **'Forget the Apple key'**
  String get ascForget;

  /// No description provided for @ascManual.
  ///
  /// In en, this message translates to:
  /// **'What stays manual on Apple: the screenshots (iPhone sizes), the age rating questions, price and countries.'**
  String get ascManual;

  /// No description provided for @bAndroidFailed.
  ///
  /// In en, this message translates to:
  /// **'{kind} build failed'**
  String bAndroidFailed(String kind);

  /// No description provided for @bAndroidReady.
  ///
  /// In en, this message translates to:
  /// **'{kind} ready ✓'**
  String bAndroidReady(String kind);

  /// No description provided for @bStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get bStopped;

  /// No description provided for @bAppReady.
  ///
  /// In en, this message translates to:
  /// **'App ready ✓'**
  String get bAppReady;

  /// No description provided for @bReviewStart.
  ///
  /// In en, this message translates to:
  /// **'Other AIs are now checking the app on their own…'**
  String get bReviewStart;

  /// No description provided for @bReviewClean.
  ///
  /// In en, this message translates to:
  /// **'The reviewers found nothing to fix.'**
  String get bReviewClean;

  /// No description provided for @bReviewFound.
  ///
  /// In en, this message translates to:
  /// **'{count} problems found by the reviewers: fixing them now.'**
  String bReviewFound(int count);

  /// No description provided for @bAppUpdated.
  ///
  /// In en, this message translates to:
  /// **'App updated ✓'**
  String get bAppUpdated;

  /// No description provided for @actWrites.
  ///
  /// In en, this message translates to:
  /// **'Writing {file}'**
  String actWrites(String file);

  /// No description provided for @actEdits.
  ///
  /// In en, this message translates to:
  /// **'Editing {file}'**
  String actEdits(String file);

  /// No description provided for @actReads.
  ///
  /// In en, this message translates to:
  /// **'Reading {file}'**
  String actReads(String file);

  /// No description provided for @actPubGet.
  ///
  /// In en, this message translates to:
  /// **'Installing dependencies'**
  String get actPubGet;

  /// No description provided for @actAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Checking for errors'**
  String get actAnalyze;

  /// No description provided for @forgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ember is summoning your app'**
  String get forgeTitle;

  /// No description provided for @forgeFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} files summoned'**
  String forgeFiles(int count);

  /// No description provided for @researchingApp.
  ///
  /// In en, this message translates to:
  /// **'Studying “{name}” on Google Play…'**
  String researchingApp(String name);

  /// No description provided for @pickReferenceApp.
  ///
  /// In en, this message translates to:
  /// **'Which app do you mean?'**
  String get pickReferenceApp;

  /// No description provided for @pickReferenceAppHint.
  ///
  /// In en, this message translates to:
  /// **'Ember will study its features on Google Play and build an app that does the same, with your own name and design.'**
  String get pickReferenceAppHint;

  /// No description provided for @referenceNone.
  ///
  /// In en, this message translates to:
  /// **'None of these, continue without'**
  String get referenceNone;

  /// No description provided for @forgeFilesOf.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} files summoned'**
  String forgeFilesOf(int count, int total);

  /// No description provided for @forgeEta.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min left'**
  String forgeEta(int minutes);

  /// No description provided for @forgeEstimated.
  ///
  /// In en, this message translates to:
  /// **'estimated time about {minutes} min'**
  String forgeEstimated(int minutes);

  /// No description provided for @forgeElapsed.
  ///
  /// In en, this message translates to:
  /// **'{time} elapsed'**
  String forgeElapsed(String time);

  /// No description provided for @forgeBackground.
  ///
  /// In en, this message translates to:
  /// **'You can lock the screen or use other apps: Ember keeps working and finishes the app.'**
  String get forgeBackground;

  /// No description provided for @buyCredits.
  ///
  /// In en, this message translates to:
  /// **'Buy API credits'**
  String get buyCredits;

  /// No description provided for @getSubscription.
  ///
  /// In en, this message translates to:
  /// **'Buy a subscription'**
  String get getSubscription;

  /// No description provided for @connectSubscription.
  ///
  /// In en, this message translates to:
  /// **'Connect my subscription'**
  String get connectSubscription;

  /// No description provided for @accessTitle.
  ///
  /// In en, this message translates to:
  /// **'Access & payments'**
  String get accessTitle;

  /// No description provided for @accessPaidOutside.
  ///
  /// In en, this message translates to:
  /// **'Payments happen on the provider\'s site, not in Ember.'**
  String get accessPaidOutside;

  /// No description provided for @subscriptionNotConnected.
  ///
  /// In en, this message translates to:
  /// **'{name} is not connected: log in with your subscription on the Runner PC.'**
  String subscriptionNotConnected(String name);

  /// No description provided for @connectHowTo.
  ///
  /// In en, this message translates to:
  /// **'Ember uses your own {plan} subscription, logged in on the PC where the Runner runs (no API key, no extra cost).\n\n1. On that PC open a terminal (or Ember\'s terminal).\n2. Run: {command}\n3. Complete the login in the browser with your account.\n\nCome back here: the engine turns on within a minute.'**
  String connectHowTo(String plan, String command);

  /// No description provided for @connectPersonalNote.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are personal: use them for your own apps, not to build apps for other people.'**
  String get connectPersonalNote;

  /// No description provided for @grokNoCli.
  ///
  /// In en, this message translates to:
  /// **'Grok subscriptions (SuperGrok) cannot be connected to other apps yet: use an xAI API key.'**
  String get grokNoCli;

  /// No description provided for @subscriptionConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected with your {plan} subscription: no API key and no extra cost.'**
  String subscriptionConnected(String plan);

  /// No description provided for @haveSubscription.
  ///
  /// In en, this message translates to:
  /// **'Already have {plan}?'**
  String haveSubscription(String plan);

  /// No description provided for @subscriptionReadyUse.
  ///
  /// In en, this message translates to:
  /// **'Build with {engine} on your subscription, without buying API credits.'**
  String subscriptionReadyUse(String engine);

  /// No description provided for @subscriptionConnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect it once to build with {engine} at no extra cost.'**
  String subscriptionConnectFirst(String engine);

  /// No description provided for @useSubscription.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get useSubscription;

  /// No description provided for @bResumeChat.
  ///
  /// In en, this message translates to:
  /// **'Continue the interrupted build from where it stopped'**
  String get bResumeChat;

  /// No description provided for @backToEmber.
  ///
  /// In en, this message translates to:
  /// **'Back to Ember'**
  String get backToEmber;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'In-app purchases to activate on Google Play'**
  String get productsTitle;

  /// No description provided for @productsHint.
  ///
  /// In en, this message translates to:
  /// **'Ember creates and activates these products in Play Console for you, with prices converted for every country.'**
  String get productsHint;

  /// No description provided for @productsActivate.
  ///
  /// In en, this message translates to:
  /// **'Create and activate on Play Console'**
  String get productsActivate;

  /// No description provided for @productsNeedKey.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Play first (service account key): open the publish steps.'**
  String get productsNeedKey;

  /// No description provided for @productsBefore.
  ///
  /// In en, this message translates to:
  /// **'Before activating, once per account/app:\n1. Play Console → Setup → Payments profile (bank account, tax info)\n2. Upload this app\'s AAB to internal testing (Google requires a version with billing)\n3. Users and permissions → give the service account \"Manage orders and subscriptions\"'**
  String get productsBefore;

  /// No description provided for @productsOpenPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments profile'**
  String get productsOpenPayments;

  /// No description provided for @productsUploadFirst.
  ///
  /// In en, this message translates to:
  /// **'Upload AAB'**
  String get productsUploadFirst;

  /// No description provided for @productsActive.
  ///
  /// In en, this message translates to:
  /// **'Active on Google Play ✓'**
  String get productsActive;

  /// No description provided for @productPerPeriod.
  ///
  /// In en, this message translates to:
  /// **'{price} / {period}'**
  String productPerPeriod(String price, String period);

  /// No description provided for @productTrial.
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial'**
  String productTrial(int days);

  /// No description provided for @logoTitle.
  ///
  /// In en, this message translates to:
  /// **'App logo'**
  String get logoTitle;

  /// No description provided for @logoHint.
  ///
  /// In en, this message translates to:
  /// **'Ember draws 6 proposals. Not convinced? Tap “More logos” as many times as you like. The one you choose becomes the app icon and the Play Store icon and banner.'**
  String get logoHint;

  /// No description provided for @logoDescribe.
  ///
  /// In en, this message translates to:
  /// **'Describe the logo (optional)'**
  String get logoDescribe;

  /// No description provided for @logoDescribeHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: blue shield with a pen, modern, no text'**
  String get logoDescribeHint;

  /// No description provided for @logoGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate 6 logos'**
  String get logoGenerate;

  /// No description provided for @logoMore.
  ///
  /// In en, this message translates to:
  /// **'More logos'**
  String get logoMore;

  /// No description provided for @logoUse.
  ///
  /// In en, this message translates to:
  /// **'Use this logo'**
  String get logoUse;

  /// No description provided for @logoApplied.
  ///
  /// In en, this message translates to:
  /// **'Logo set: app icons are being generated and the preview will update.'**
  String get logoApplied;

  /// No description provided for @shotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Play Store screenshots'**
  String get shotsTitle;

  /// No description provided for @shotsHint.
  ///
  /// In en, this message translates to:
  /// **'Ember opens the app like a phone and takes 6 screenshots of the main screens (1080×1920), ready for Google Play.'**
  String get shotsHint;

  /// No description provided for @shotsPreparing.
  ///
  /// In en, this message translates to:
  /// **'Ember is preparing the app for screenshots (a demo mode for each screen); the photos start automatically when it is done.'**
  String get shotsPreparing;

  /// No description provided for @shotsPreparingChat.
  ///
  /// In en, this message translates to:
  /// **'Prepare the app for Play Store screenshots'**
  String get shotsPreparingChat;

  /// No description provided for @shotsGenerate.
  ///
  /// In en, this message translates to:
  /// **'Take 6 screenshots'**
  String get shotsGenerate;

  /// No description provided for @shotsAgain.
  ///
  /// In en, this message translates to:
  /// **'Take them again'**
  String get shotsAgain;

  /// No description provided for @shotsSaved.
  ///
  /// In en, this message translates to:
  /// **'{count} screenshots saved for Google Play.'**
  String shotsSaved(int count);

  /// No description provided for @pubTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish with Ember'**
  String get pubTitle;

  /// No description provided for @pubAccountAsk.
  ///
  /// In en, this message translates to:
  /// **'Hi! I will guide you to publish **{app}** on Google Play, one step at a time, and I will do the technical parts myself.\n\nFirst question: do you already have a **Google Play Console developer account**?'**
  String pubAccountAsk(String app);

  /// No description provided for @pubYesHaveIt.
  ///
  /// In en, this message translates to:
  /// **'Yes, I have it'**
  String get pubYesHaveIt;

  /// No description provided for @pubNoHowTo.
  ///
  /// In en, this message translates to:
  /// **'No, how do I create it?'**
  String get pubNoHowTo;

  /// No description provided for @pubAccountHow.
  ///
  /// In en, this message translates to:
  /// **'Creating it takes 10 minutes:\n1. Open the sign-up page (button below) with your Google account\n2. Choose **Personal** (or Organization if you have a company)\n3. Pay **25 \$ once**: it goes to Google, not to Ember\n4. Verify your identity with a document: Google usually confirms in 1-2 days\n\nWhen your account is active, come back here.'**
  String get pubAccountHow;

  /// No description provided for @pubNowIHaveIt.
  ///
  /// In en, this message translates to:
  /// **'Done, my account is active'**
  String get pubNowIHaveIt;

  /// No description provided for @pubCreateApp.
  ///
  /// In en, this message translates to:
  /// **'Now create the app in Play Console (only the first time):\n1. Press **Open Play Console** below, then **Create app**\n2. App name, default language, type **App**, **Free**\n3. Tick the declarations and press **Create app**\n\nThis app\'s package name is `{package}`: Google links it automatically on the first upload.'**
  String pubCreateApp(String package);

  /// No description provided for @pubDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pubDone;

  /// No description provided for @pubConnect.
  ///
  /// In en, this message translates to:
  /// **'Now I connect Ember to Google Play, so I can upload your apps. **I do it myself**: I create a special key in your Google account on this PC (Google Cloud project, Play API and key). It is used only to upload apps and stays on your device.'**
  String get pubConnect;

  /// No description provided for @pubDoItEmber.
  ///
  /// In en, this message translates to:
  /// **'Do it for me, Ember'**
  String get pubDoItEmber;

  /// No description provided for @pubManual.
  ///
  /// In en, this message translates to:
  /// **'I prefer to do it by hand'**
  String get pubManual;

  /// No description provided for @pubKeyWorking.
  ///
  /// In en, this message translates to:
  /// **'Creating the Google Cloud project, enabling the Play API and creating the key (about 1-2 minutes)…'**
  String get pubKeyWorking;

  /// No description provided for @pubInvite.
  ///
  /// In en, this message translates to:
  /// **'Key created ✓\n\nLast connection: the key must be allowed to publish in **your** Play Console.\n1. Press **Open Play Console** below\n2. Copy the address of the page you see (any page) and **paste it here in the chat**\n\nThen the PC browser opens once: sign in with the same Google account and press **Allow**. I send the invitation myself.'**
  String get pubInvite;

  /// No description provided for @pubInviteBadLink.
  ///
  /// In en, this message translates to:
  /// **'That link does not contain the Play Console account number. Open play.google.com/console and paste the address of that page.'**
  String get pubInviteBadLink;

  /// No description provided for @pubInviteWorking.
  ///
  /// In en, this message translates to:
  /// **'Inviting the key into your Play Console… if the PC browser opens, sign in and press Allow.'**
  String get pubInviteWorking;

  /// No description provided for @pubInviteManual.
  ///
  /// In en, this message translates to:
  /// **'I could not send the invitation automatically, so let\'s do it together (2 minutes):\n1. **Open Play Console**, then **Users and permissions** and **Invite new users**\n2. Paste this email: `{email}`\n3. **Account permissions**: tick releases, store presence, app content and orders\n4. Press **Invite user**, then **Done** here'**
  String pubInviteManual(String email);

  /// No description provided for @pubGraphics.
  ///
  /// In en, this message translates to:
  /// **'Connected to Google Play ✓\n\nFor the store page Google wants the **512×512 icon**, the **1024×500 banner** and at least **2 screenshots**. If you haven\'t done them yet, go back to the app screen: in **App logo** and **Play Store screenshots** Ember makes them in one tap. I upload them automatically together with the app.'**
  String get pubGraphics;

  /// No description provided for @pubContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get pubContinue;

  /// No description provided for @pubBackToApp.
  ///
  /// In en, this message translates to:
  /// **'Back to the app'**
  String get pubBackToApp;

  /// No description provided for @pubUpload.
  ///
  /// In en, this message translates to:
  /// **'Now the store page and the upload: I write title, descriptions and privacy policy, prepare the answers for Google\'s forms, then upload the signed AAB with icon, banner and screenshots.\n\nFirst generate the **AAB** from the app screen if you haven\'t yet.'**
  String get pubUpload;

  /// No description provided for @pubPrepareUpload.
  ///
  /// In en, this message translates to:
  /// **'Prepare and upload'**
  String get pubPrepareUpload;

  /// No description provided for @pubFinish.
  ///
  /// In en, this message translates to:
  /// **'Great, the app is on Google Play ✓\n\nGoogle still asks you to confirm a few forms by hand in Play Console (**Data safety**, **Content rating**, **Target audience**, **Ads**, **App access**): the ready answers are in the last screen. New personal accounts must also run a **closed test with 12 testers for 14 days** before going public.\n\nAny doubt? Ask me here below.'**
  String get pubFinish;

  /// No description provided for @pubReviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'See the ready answers'**
  String get pubReviewAnswers;

  /// No description provided for @pubPasteLink.
  ///
  /// In en, this message translates to:
  /// **'Paste the Play Console link here…'**
  String get pubPasteLink;

  /// No description provided for @pubAskAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask Ember anything about publishing…'**
  String get pubAskAnything;

  /// No description provided for @adsTitle.
  ///
  /// In en, this message translates to:
  /// **'AdMob ads'**
  String get adsTitle;

  /// No description provided for @adsHint.
  ///
  /// In en, this message translates to:
  /// **'The app already shows Google TEST ads (safe while developing) and asks for EU consent. To earn money, create the real ad units in AdMob and paste the IDs here: Ember puts them in the app.'**
  String get adsHint;

  /// No description provided for @adsSteps.
  ///
  /// In en, this message translates to:
  /// **'In AdMob (5 minutes, once per app):\n1. Apps → Add app → Android → \"Is the app on Google Play?\" (No if not published yet) → name → Add\n2. Copy the App ID (ca-app-pub-…~…)\n3. Ad units → Add ad unit → choose each format below → Create → copy its ID (ca-app-pub-…/…)\n4. After publishing, link the app to its Play Store listing in AdMob and add app-ads.txt if AdMob asks'**
  String get adsSteps;

  /// No description provided for @adsOpenAdmob.
  ///
  /// In en, this message translates to:
  /// **'Open AdMob'**
  String get adsOpenAdmob;

  /// No description provided for @adsAppId.
  ///
  /// In en, this message translates to:
  /// **'AdMob App ID'**
  String get adsAppId;

  /// No description provided for @adsUnitId.
  ///
  /// In en, this message translates to:
  /// **'{format} ad unit ID'**
  String adsUnitId(String format);

  /// No description provided for @adsApply.
  ///
  /// In en, this message translates to:
  /// **'Put the real IDs in the app'**
  String get adsApply;

  /// No description provided for @adsInvalid.
  ///
  /// In en, this message translates to:
  /// **'IDs must look like ca-app-pub-1234567890123456~1234567890 (app) and ca-app-pub-1234567890123456/1234567890 (ad units).'**
  String get adsInvalid;

  /// No description provided for @adsChat.
  ///
  /// In en, this message translates to:
  /// **'Set the real AdMob IDs'**
  String get adsChat;

  /// No description provided for @pubNothingUploaded.
  ///
  /// In en, this message translates to:
  /// **'Nothing was uploaded to Google Play: press \"Upload to Google Play\" in the next screen and wait for the confirmation, then come back.'**
  String get pubNothingUploaded;

  /// No description provided for @upListing.
  ///
  /// In en, this message translates to:
  /// **'✓ Store listing (title and descriptions): {languages}'**
  String upListing(String languages);

  /// No description provided for @upNoListing.
  ///
  /// In en, this message translates to:
  /// **'✗ Store listing not written (title and descriptions were empty)'**
  String get upNoListing;

  /// No description provided for @upIcon.
  ///
  /// In en, this message translates to:
  /// **'✓ 512×512 icon'**
  String get upIcon;

  /// No description provided for @upNoIcon.
  ///
  /// In en, this message translates to:
  /// **'✗ Icon missing: choose a logo in \"App logo\" first'**
  String get upNoIcon;

  /// No description provided for @upFeature.
  ///
  /// In en, this message translates to:
  /// **'✓ 1024×500 banner'**
  String get upFeature;

  /// No description provided for @upNoFeature.
  ///
  /// In en, this message translates to:
  /// **'✗ Banner missing: choose a logo in \"App logo\" first'**
  String get upNoFeature;

  /// No description provided for @upShots.
  ///
  /// In en, this message translates to:
  /// **'✓ {count} phone screenshots'**
  String upShots(int count);

  /// No description provided for @upNoShots.
  ///
  /// In en, this message translates to:
  /// **'✗ Screenshots missing: take them in \"Play Store screenshots\" first'**
  String get upNoShots;

  /// No description provided for @upTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Play'**
  String get upTitle;

  /// No description provided for @upHint.
  ///
  /// In en, this message translates to:
  /// **'Everything is saved for this app. Change what you need, then send a new version: Ember builds a new signed AAB (higher version) and uploads it with the listing, logo and screenshots.'**
  String get upHint;

  /// No description provided for @upStateLogo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get upStateLogo;

  /// No description provided for @upStateShots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots: {count}'**
  String upStateShots(int count);

  /// No description provided for @upStateListing.
  ///
  /// In en, this message translates to:
  /// **'Title and descriptions'**
  String get upStateListing;

  /// No description provided for @upEditListing.
  ///
  /// In en, this message translates to:
  /// **'Edit title and descriptions'**
  String get upEditListing;

  /// No description provided for @upNewVersion.
  ///
  /// In en, this message translates to:
  /// **'New version on Google Play'**
  String get upNewVersion;

  /// No description provided for @upBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building the new signed AAB…'**
  String get upBuilding;

  /// No description provided for @upUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading to Google Play…'**
  String get upUploading;

  /// No description provided for @upNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'First connect Google Play and write the listing once: open the publishing guide.'**
  String get upNeedsSetup;

  /// No description provided for @upOpenGuide.
  ///
  /// In en, this message translates to:
  /// **'Publishing guide'**
  String get upOpenGuide;

  /// No description provided for @pubPasteConsoleLink.
  ///
  /// In en, this message translates to:
  /// **'Tip: open Play Console once and paste the address of that page here in the chat. From then on every button opens **your** account directly, without asking which one.'**
  String get pubPasteConsoleLink;

  /// No description provided for @privacyPublicHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a public link Google can open (e.g. a GitHub gist or a page on your site).'**
  String get privacyPublicHint;

  /// No description provided for @privacyLocalWarning.
  ///
  /// In en, this message translates to:
  /// **'This address only works on this computer: Google cannot open it. Paste a public link instead.'**
  String get privacyLocalWarning;

  /// No description provided for @consoleLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Play Console link (paste once)'**
  String get consoleLinkLabel;

  /// No description provided for @consoleLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Open Play Console, choose your developer account, then copy the address of that page and paste it here: the buttons will then open your account and your app directly.'**
  String get consoleLinkHint;

  /// No description provided for @consoleLinkSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved ✓ developer account {id}: the buttons now open your console directly.'**
  String consoleLinkSaved(String id);

  /// No description provided for @upStateConnected.
  ///
  /// In en, this message translates to:
  /// **'Google Play connected (key on this device)'**
  String get upStateConnected;

  /// No description provided for @upNeedsKey.
  ///
  /// In en, this message translates to:
  /// **'Google Play is not connected on this device: open the publishing guide and press “Do it for me, Ember” to create the key (1 minute).'**
  String get upNeedsKey;

  /// No description provided for @upNeedsListing.
  ///
  /// In en, this message translates to:
  /// **'Write the store listing once: press “Edit title and descriptions”.'**
  String get upNeedsListing;

  /// No description provided for @upConnectPlay.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Play'**
  String get upConnectPlay;

  /// No description provided for @dsButton.
  ///
  /// In en, this message translates to:
  /// **'Fill Data safety'**
  String get dsButton;

  /// No description provided for @dsWorking.
  ///
  /// In en, this message translates to:
  /// **'Reading what the app collects and filling the Data safety form…'**
  String get dsWorking;

  /// No description provided for @dsDone.
  ///
  /// In en, this message translates to:
  /// **'Data safety sent to Google Play ✓ — check it in Play Console → App content → Data safety and press Submit.'**
  String get dsDone;

  /// No description provided for @dsNeedsCsv.
  ///
  /// In en, this message translates to:
  /// **'First export the form from Play Console: App content → Data safety → Export to CSV. Save it in Downloads, then press this button again.'**
  String get dsNeedsCsv;

  /// No description provided for @driveBackup.
  ///
  /// In en, this message translates to:
  /// **'Save to Google Drive'**
  String get driveBackup;

  /// No description provided for @driveSaving.
  ///
  /// In en, this message translates to:
  /// **'Asking Google for permission and saving the key on your Drive…'**
  String get driveSaving;

  /// No description provided for @driveSaved.
  ///
  /// In en, this message translates to:
  /// **'Keystore and password saved on your Google Drive ✓'**
  String get driveSaved;

  /// No description provided for @driveOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open the folder on Drive'**
  String get driveOpenFolder;

  /// No description provided for @acAskPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Write the privacy policy for this app'**
  String get acAskPrivacy;

  /// No description provided for @acAskAdmob.
  ///
  /// In en, this message translates to:
  /// **'How do I add AdMob ads to this app?'**
  String get acAskAdmob;

  /// No description provided for @acAskContent.
  ///
  /// In en, this message translates to:
  /// **'What do I answer in Play Console App content?'**
  String get acAskContent;

  /// No description provided for @acAssistant.
  ///
  /// In en, this message translates to:
  /// **'Ask Ember about this app'**
  String get acAssistant;

  /// No description provided for @acTitle.
  ///
  /// In en, this message translates to:
  /// **'App content (Play Console)'**
  String get acTitle;

  /// No description provided for @acHint.
  ///
  /// In en, this message translates to:
  /// **'Google asks these questions before the app can go public. Ember has the answer for each one: copy it and click it in Play Console.'**
  String get acHint;

  /// No description provided for @acOpenConsole.
  ///
  /// In en, this message translates to:
  /// **'Open App content'**
  String get acOpenConsole;

  /// No description provided for @acCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy answer'**
  String get acCopy;

  /// No description provided for @acCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get acCopied;

  /// No description provided for @acAuto.
  ///
  /// In en, this message translates to:
  /// **'Ember does this one'**
  String get acAuto;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @ghSavedOn.
  ///
  /// In en, this message translates to:
  /// **'Saved on GitHub'**
  String get ghSavedOn;

  /// No description provided for @ghTitle.
  ///
  /// In en, this message translates to:
  /// **'Save on GitHub'**
  String get ghTitle;

  /// No description provided for @ghHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps a copy of this app\'s source in your own GitHub repository. The signing key, the build folder and the Google files are never uploaded.'**
  String get ghHint;

  /// No description provided for @ghToken.
  ///
  /// In en, this message translates to:
  /// **'GitHub token'**
  String get ghToken;

  /// No description provided for @ghTokenHelp.
  ///
  /// In en, this message translates to:
  /// **'A personal access token with the \"repo\" permission. It is stored encrypted on this device and used only to upload this app.'**
  String get ghTokenHelp;

  /// No description provided for @ghGetToken.
  ///
  /// In en, this message translates to:
  /// **'Create a token on GitHub'**
  String get ghGetToken;

  /// No description provided for @ghRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Open an app saved on GitHub'**
  String get ghRestoreTitle;

  /// No description provided for @ghRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'The apps you saved on GitHub come back onto this computer, with everything they had. This is how you work on the same app from Windows and from a Mac.'**
  String get ghRestoreHint;

  /// No description provided for @ghRestoreLoad.
  ///
  /// In en, this message translates to:
  /// **'Show my apps'**
  String get ghRestoreLoad;

  /// No description provided for @ghRestoreNone.
  ///
  /// In en, this message translates to:
  /// **'No app saved from Ember yet on this GitHub account.'**
  String get ghRestoreNone;

  /// No description provided for @ghRestoreHere.
  ///
  /// In en, this message translates to:
  /// **'Already on this computer'**
  String get ghRestoreHere;

  /// No description provided for @ghRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'From GitHub'**
  String get ghRestoreAction;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @ghSave.
  ///
  /// In en, this message translates to:
  /// **'Save on GitHub'**
  String get ghSave;

  /// No description provided for @ghSaving.
  ///
  /// In en, this message translates to:
  /// **'Uploading the app to GitHub…'**
  String get ghSaving;

  /// No description provided for @ghOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the repository'**
  String get ghOpen;

  /// No description provided for @ghForgetToken.
  ///
  /// In en, this message translates to:
  /// **'Forget the token'**
  String get ghForgetToken;

  /// No description provided for @ghNeedsToken.
  ///
  /// In en, this message translates to:
  /// **'Paste a GitHub token first.'**
  String get ghNeedsToken;

  /// No description provided for @ghCreated.
  ///
  /// In en, this message translates to:
  /// **'Repository {repo} created and app uploaded ✓'**
  String ghCreated(String repo);

  /// No description provided for @ghUpdated.
  ///
  /// In en, this message translates to:
  /// **'App uploaded to {repo} ✓'**
  String ghUpdated(String repo);

  /// No description provided for @acCopyForExtension.
  ///
  /// In en, this message translates to:
  /// **'Copy for the browser helper'**
  String get acCopyForExtension;

  /// No description provided for @acFillForMe.
  ///
  /// In en, this message translates to:
  /// **'Fill in Play Console'**
  String get acFillForMe;

  /// No description provided for @acFilling.
  ///
  /// In en, this message translates to:
  /// **'Ember is answering the questions in the Chrome window it opened. Watch it, and take over whenever you want.'**
  String get acFilling;

  /// No description provided for @acFilled.
  ///
  /// In en, this message translates to:
  /// **'Saved {done} of {total} sections.'**
  String acFilled(int done, int total);

  /// No description provided for @acNeedsAppLink.
  ///
  /// In en, this message translates to:
  /// **'Ember does not know this app on Play Console yet: open your app there, copy the address from the browser and paste it in the publishing screen.'**
  String get acNeedsAppLink;

  /// No description provided for @acAppLink.
  ///
  /// In en, this message translates to:
  /// **'Address of this app in Play Console'**
  String get acAppLink;

  /// No description provided for @acLinkNotUnderstood.
  ///
  /// In en, this message translates to:
  /// **'That address does not name an app. Open the app in Play Console and copy the whole address from the browser bar.'**
  String get acLinkNotUnderstood;

  /// No description provided for @adsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add AdMob ads'**
  String get adsAdd;

  /// No description provided for @adsAddHint.
  ///
  /// In en, this message translates to:
  /// **'Ember puts ads on every screen that can carry one, within the limits that keep an AdMob account alive, and shows Google test ads until you paste your own ids.'**
  String get adsAddHint;

  /// No description provided for @adsAddChat.
  ///
  /// In en, this message translates to:
  /// **'Add AdMob ads with test ids'**
  String get adsAddChat;

  /// No description provided for @adsYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, show ads'**
  String get adsYes;

  /// No description provided for @adsNo.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get adsNo;

  /// No description provided for @adsDeclined.
  ///
  /// In en, this message translates to:
  /// **'No ads in this app. Ask Ember for them whenever you change your mind.'**
  String get adsDeclined;

  /// No description provided for @adsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove the ads'**
  String get adsRemove;

  /// No description provided for @adsRemoveChat.
  ///
  /// In en, this message translates to:
  /// **'Remove AdMob from this app'**
  String get adsRemoveChat;

  /// No description provided for @adsAppIdHelp.
  ///
  /// In en, this message translates to:
  /// **'The code with the ~ , next to the Android icon. The same one for every ad unit.'**
  String get adsAppIdHelp;

  /// No description provided for @adsUnitHelp.
  ///
  /// In en, this message translates to:
  /// **'The code with the / , next to the card icon. A different one for each format.'**
  String get adsUnitHelp;

  /// No description provided for @checkTitle.
  ///
  /// In en, this message translates to:
  /// **'Ember checked this app'**
  String get checkTitle;

  /// No description provided for @checkAllGood.
  ///
  /// In en, this message translates to:
  /// **'Everything needed for the app to work is in place.'**
  String get checkAllGood;

  /// No description provided for @checkFound.
  ///
  /// In en, this message translates to:
  /// **'{count} things do not work yet. Ember can put right the ones with the tool icon, once you say so.'**
  String checkFound(int count);

  /// No description provided for @checkFixNow.
  ///
  /// In en, this message translates to:
  /// **'Fix {count} of them'**
  String checkFixNow(int count);

  /// No description provided for @checkFixing.
  ///
  /// In en, this message translates to:
  /// **'Fixing…'**
  String get checkFixing;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @checkAskEmber.
  ///
  /// In en, this message translates to:
  /// **'Have Ember fix it'**
  String get checkAskEmber;

  /// No description provided for @checkAsked.
  ///
  /// In en, this message translates to:
  /// **'Asked. Ember is working on it: watch the chat below.'**
  String get checkAsked;

  /// No description provided for @previewLoginInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Google will not sign anyone in inside this window, and a login done in the browser does not carry over here. In this window use email and password; Google sign-in works in the browser and on a phone.'**
  String get previewLoginInBrowser;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone'**
  String get phoneTitle;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Ember installs the app on the phone plugged into this computer and opens it. Google sign-in, notifications and ads only behave properly there.'**
  String get phoneHint;

  /// No description provided for @phoneRunOn.
  ///
  /// In en, this message translates to:
  /// **'Run on {name}'**
  String phoneRunOn(String name);

  /// No description provided for @phoneUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'{name}: unlock it and allow USB debugging'**
  String phoneUnauthorized(String name);

  /// No description provided for @phoneBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building the app for the phone…'**
  String get phoneBuilding;

  /// No description provided for @phoneInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing on the phone…'**
  String get phoneInstalling;

  /// No description provided for @phoneLookAgain.
  ///
  /// In en, this message translates to:
  /// **'Look for phones again'**
  String get phoneLookAgain;

  /// No description provided for @phoneOpenHere.
  ///
  /// In en, this message translates to:
  /// **'Open on the phone now'**
  String get phoneOpenHere;

  /// No description provided for @phoneSameWifi.
  ///
  /// In en, this message translates to:
  /// **'Point the phone camera at the code. The phone must be on the same Wi-Fi as this computer.'**
  String get phoneSameWifi;

  /// No description provided for @playLanguages.
  ///
  /// In en, this message translates to:
  /// **'Store languages'**
  String get playLanguages;

  /// No description provided for @playTranslating.
  ///
  /// In en, this message translates to:
  /// **'Writing the listing in the other languages…'**
  String get playTranslating;
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
      <String>['ar', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
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
