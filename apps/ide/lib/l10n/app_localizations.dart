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
  /// **'FlutterCursor'**
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
  /// **'Projects'**
  String get projects;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet. Create one to get started.'**
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
  /// **'E.g.: a recipe app with photos, shopping list and cooking timer, warm colors…'**
  String get appPromptHint;

  /// No description provided for @chooseAi.
  ///
  /// In en, this message translates to:
  /// **'Which AI?'**
  String get chooseAi;

  /// No description provided for @createApp.
  ///
  /// In en, this message translates to:
  /// **'Create app'**
  String get createApp;

  /// No description provided for @openEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get openEditor;

  /// No description provided for @describeYourApp.
  ///
  /// In en, this message translates to:
  /// **'Describe your app'**
  String get describeYourApp;

  /// No description provided for @describeYourAppHint.
  ///
  /// In en, this message translates to:
  /// **'Say what it should do and look like: the AI builds the complete app, checks errors and shows it to you. (*Gemini: Google\'s free tier with daily limits)'**
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
  /// **'Best quality'**
  String get bestQuality;

  /// No description provided for @bestQualityOn.
  ///
  /// In en, this message translates to:
  /// **'Most capable model: slower, for complex apps'**
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
  /// **'Swipe or press back to return to FlutterCursor'**
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
  /// **'You need a Google Play Console developer account. Cost: \$25 one time (not a subscription), paid directly to Google, not to FlutterCursor.'**
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
  /// **'Connect FlutterCursor to Google Play'**
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
  /// **'AI assistant'**
  String get assistantTitle;

  /// No description provided for @assistantFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get assistantFree;

  /// No description provided for @assistantEmpty.
  ///
  /// In en, this message translates to:
  /// **'Hi! Ask me anything: app ideas, how to publish on Play Store, how to set up login and databases…'**
  String get assistantEmpty;

  /// No description provided for @assistantUnconfigured.
  ///
  /// In en, this message translates to:
  /// **'The free assistant is not active on this server yet (the Runner\'s Gemini key is missing).'**
  String get assistantUnconfigured;

  /// No description provided for @assistantHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a question…'**
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
  /// **'Forging your app'**
  String get forgeTitle;

  /// No description provided for @forgeFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} files forged'**
  String forgeFiles(int count);
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
