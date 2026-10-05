// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ember – App Maker';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Create apps from any device, with AI.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get runnerUrl => 'Runner URL';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get devLoginHint =>
      'Development mode: Supabase is not set up, so you sign in with email only, through the computer where Ember runs.';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordTooShort => 'At least 6 characters';

  @override
  String get signOut => 'Sign out';

  @override
  String get projects => 'Your apps';

  @override
  String get noProjects => 'No apps yet. Describe one above.';

  @override
  String get newProject => 'New project';

  @override
  String get projectName => 'Project name';

  @override
  String get projectNameHelp => 'lowercase, letters/digits/_ (e.g. my_app)';

  @override
  String get create => 'Create';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get retry => 'Retry';

  @override
  String get statusCreating => 'Creating…';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusError => 'Error';

  @override
  String creatingProject(String name) {
    return 'Creating $name';
  }

  @override
  String get files => 'Files';

  @override
  String get editor => 'Editor';

  @override
  String get newFile => 'New file';

  @override
  String get newFolder => 'New folder';

  @override
  String get fileName => 'Name';

  @override
  String deleteConfirm(String path) {
    return 'Delete $path?';
  }

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get discard => 'Discard';

  @override
  String get noFileOpen => 'Open a file from the tree.';

  @override
  String get conflictTitle => 'File changed elsewhere';

  @override
  String conflictBody(String path) {
    return '$path changed on the computer where Ember runs after you opened it.';
  }

  @override
  String get reload => 'Reload';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting…';

  @override
  String get disconnected => 'Disconnected';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get binaryFile => 'Binary or too large: cannot be edited.';

  @override
  String get terminal => 'Terminal';

  @override
  String get newTerminal => 'New terminal';

  @override
  String get toggleTerminal => 'Toggle terminal';

  @override
  String get restart => 'Restart';

  @override
  String get preview => 'Preview';

  @override
  String get togglePreview => 'Toggle preview';

  @override
  String get runWeb => 'Run Web';

  @override
  String get building => 'Building…';

  @override
  String get buildFailed => 'Build failed: see the log below.';

  @override
  String get reloadPreview => 'Reload preview';

  @override
  String get device => 'Device';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get openOnOtherDevice => 'Open on another device';

  @override
  String get qrLocalhostWarning =>
      'This address only works on this computer. To open it from a phone, use the network address of the computer where Ember runs (e.g. http://192.168.1.20:8787).';

  @override
  String get copy => 'Copy';

  @override
  String get close => 'Close';

  @override
  String get console => 'Console';

  @override
  String get autoRebuild => 'Rebuild on save';

  @override
  String get previewEmpty =>
      'Press “Run Web” to build the app and see it here. Every save refreshes the preview.';

  @override
  String get ai => 'AI';

  @override
  String get toggleAi => 'Toggle AI panel';

  @override
  String get aiSettings => 'Add a key';

  @override
  String get apiKeysHint =>
      'Keys stay encrypted on this device. When requests go through the computer where Ember runs, the keys pass through it for that request only and are never saved.';

  @override
  String get useRunnerProxy => 'Go through the computer where Ember runs';

  @override
  String get useRunnerProxyHint =>
      'Recommended. Turn it off to contact the AI services straight from this device.';

  @override
  String get useRunnerProxyWeb =>
      'Always on in the browser: a web page cannot contact the AI services directly.';

  @override
  String get apiKey => 'API key';

  @override
  String get apiKeyOptional => 'API key (if required)';

  @override
  String get replaceApiKey => 'Replace key';

  @override
  String get testKey => 'Test';

  @override
  String get testing => 'Testing…';

  @override
  String keyWorks(String model) {
    return 'Works ($model)';
  }

  @override
  String get getKey => 'Get a key';

  @override
  String get addModelId => 'Add model ID';

  @override
  String get selectModel => 'Select model';

  @override
  String get keyPresent => 'key present';

  @override
  String get notConfigured => 'not configured';

  @override
  String get per1k => 'per 1k tokens (in/out)';

  @override
  String applyTo(String path) {
    return 'Apply to $path';
  }

  @override
  String get noChanges => 'No differences from the current file.';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get apply => 'Apply';

  @override
  String applied(String path) {
    return 'Change applied to $path: review and save.';
  }

  @override
  String get applyNoTarget =>
      'Open a file or ask the AI to include the file path.';

  @override
  String get clearChat => 'Clear chat';

  @override
  String get chatEmpty =>
      'Ask about your project. The open file is sent as context.';

  @override
  String get chatNoKeys =>
      'Add at least one API key (Claude, ChatGPT or Gemini) to use AI.';

  @override
  String get attachOpenFile => 'Attach the open file as context';

  @override
  String get askAi => 'Ask AI…  (Ctrl+Enter to send)';

  @override
  String get send => 'Send';

  @override
  String get stop => 'Stop';

  @override
  String get copied => 'Copied';

  @override
  String get truncated => 'truncated (token limit)';

  @override
  String get refused => 'declined by the model';

  @override
  String get stopped => 'stopped';

  @override
  String get badgeFreeTier => 'free*';

  @override
  String get badgeSubscription => 'subscription';

  @override
  String get badgePaid => 'paid';

  @override
  String needsKey(String name) {
    return 'Needs a $name API key: add it in settings.';
  }

  @override
  String get claudeCodeUnavailable =>
      'Claude Code is not available: it must be installed and signed in on the computer where Ember runs.';

  @override
  String get appPromptHint =>
      'E.g.: a recipe app with photos, shopping list and cooking timer…';

  @override
  String get chooseAi => 'Who writes the code';

  @override
  String get createApp => 'Create app';

  @override
  String get openEditor => 'Editor';

  @override
  String get describeYourApp => 'What app do you want to create?';

  @override
  String get describeYourAppHint =>
      'Write what it should do and how you picture it. Ember builds it, checks it and shows it to you.';

  @override
  String get improveApp => 'What would you like to add or improve?';

  @override
  String get improveAppHint =>
      'Describe the next features or changes, e.g.: add video calls, Google login, private rooms… You can also paste the keys the AI asks for here.';

  @override
  String get applyChange => 'Apply change';

  @override
  String get buildLog => 'Details';

  @override
  String get stepClaudeCode => 'Claude Code writes and verifies the code';

  @override
  String stepWriting(int count) {
    return 'Writing code ($count files)';
  }

  @override
  String get stepDependencies => 'Installing dependencies';

  @override
  String get stepChecking => 'Checking for errors';

  @override
  String stepFixing(int round) {
    return 'Fixing errors (attempt $round)';
  }

  @override
  String get stepBuilding => 'Building the app';

  @override
  String get stepReady => 'Ready';

  @override
  String get appReadyTitle => 'Your app is ready';

  @override
  String get openApp => 'Open app';

  @override
  String get viewCode => 'View code';

  @override
  String get buildCancelled => 'Build stopped';

  @override
  String get buildFailedTitle => 'I couldn\'t finish the app';

  @override
  String get bestQuality => 'Maximum power';

  @override
  String get bestQualityOn => 'Most powerful engine: slower, for complex apps';

  @override
  String get bestQualityOff => 'Fast (recommended): right for most apps';

  @override
  String get androidFileQuestion => 'Do you want the file for Android?';

  @override
  String get androidFileHint =>
      'File to install (APK): goes on a phone. File for Google Play (AAB): goes to Google Play Console. Both are signed.';

  @override
  String get generateApk => 'Create the file to install (APK)';

  @override
  String get generateAab => 'Create the file for Google Play (AAB)';

  @override
  String androidBuilding(String kind) {
    return 'Creating the $kind file… the first time can take 3-5 minutes.';
  }

  @override
  String get downloadApk => 'Download and install the file (APK)';

  @override
  String get downloadAab => 'Download the file for Google Play (AAB)';

  @override
  String get apkInstallHint =>
      'The file to install (APK) is signed. If Android asks, allow installs from this source.';

  @override
  String get aabHint =>
      'The file for Google Play (AAB) is signed with this app\'s upload key and ready for Google Play Console. The version number goes up by itself every time.';

  @override
  String get androidFailed => 'Build failed:';

  @override
  String get backupSigningKey => 'Save signing key';

  @override
  String get backupSigningKeyHint =>
      'Keep the key file and password somewhere safe (e.g. Google Drive): you need them to publish updates of this app on Google Play. The link works once, for 10 minutes.';

  @override
  String get downloadKeystore => 'Download key file';

  @override
  String get fullscreenExitHint => 'Swipe or press back to return to Ember';

  @override
  String get runFullscreen => 'Run full screen';

  @override
  String cliNotInstalled(String name) {
    return 'not installed on the computer where Ember runs ($name)';
  }

  @override
  String get terminalCliHint =>
      'Claude Code, Codex and Gemini use the sign-in made on the computer where Ember runs. The first time, follow the instructions in the terminal to sign in.';

  @override
  String get generatingMockups => 'Creating 5 visual styles…';

  @override
  String designingStyle(String style) {
    return 'Designing “$style”…';
  }

  @override
  String get chooseMockup => 'Choose this';

  @override
  String get editMockup => 'Edit this mockup';

  @override
  String get editMockupHint => 'E.g.: darker, rounded buttons, pink logo…';

  @override
  String get newMockups => 'New mockups (5 different styles)';

  @override
  String get previousMockups => 'Previous mockups';

  @override
  String mockupSet(int n) {
    return 'Set $n';
  }

  @override
  String get skipMockups => 'Skip mockups and build the app';

  @override
  String get playAskUpload => 'Upload the app to Google Play Store?';

  @override
  String get playYesUpload => 'Yes, upload to Play Store';

  @override
  String get playNotNow => 'Not now';

  @override
  String get playFeeNotice =>
      'You need a Google Play Console developer account. Cost: \$25 one time (not a subscription), paid directly to Google, not to Ember.';

  @override
  String get playPublishTitle => 'Publish to Google Play';

  @override
  String get playStepAccount => 'Google Play Console account';

  @override
  String get playOpenSignup => 'Create Play Console account';

  @override
  String get playHaveAccount => 'I already have an active Play Console account';

  @override
  String get next => 'Next';

  @override
  String get playStepCreateApp => 'Create the app in Play Console';

  @override
  String get playCreateAppGuide =>
      'Google requires this step manually, only the first time:\n1. Open **Play Console** → **Create app**\n2. App name, default language, type **App**, **Free**\n3. Accept the declarations and press **Create app**\n\nThe package name is linked on the first upload: use the one below.';

  @override
  String get playPackageName => 'Package name';

  @override
  String get playOpenConsole => 'Open Play Console';

  @override
  String get playAppCreated => 'I created the app in Play Console';

  @override
  String get playStepConnect => 'Connect Ember to Google Play';

  @override
  String get playConnectGuide =>
      '1. Open **Google Cloud**: you create a **service account key**, once for all your apps.\n2. Turn on **Google Play Android Developer API**.\n3. Go to **Service accounts** and press **Create**.\n4. Open **Keys** → **Add key** → **JSON**. A file downloads.\n5. In **Play Console** go to **Users and permissions** → **Invite new users**.\n6. Paste the service account email and grant the **release** permissions.\n7. Open the downloaded JSON file and **paste its whole content here**.\n8. Done: the key stays encrypted on this device and is used only for uploads.';

  @override
  String get playOpenApiLibrary => 'Enable Google Play API';

  @override
  String get playOpenServiceAccounts => 'Service accounts';

  @override
  String get playServiceAccountJson => 'Service account JSON content';

  @override
  String get playStepListing => 'Store listing and upload';

  @override
  String get playGenerateWithAi =>
      'Generate listing, privacy policy and answers with AI';

  @override
  String get playTitle => 'Title (max 30)';

  @override
  String get playShortDescription => 'Short description (max 80)';

  @override
  String get playFullDescription => 'Full description';

  @override
  String get playReleaseNotes => 'Release notes';

  @override
  String get playContactEmail => 'Contact email (required on Play Store)';

  @override
  String get playPrivacyUrl => 'Privacy policy link';

  @override
  String get playTrack => 'Where to publish';

  @override
  String get playTrackInternal => 'Internal testing (recommended first)';

  @override
  String get playTrackClosed => 'Closed testing';

  @override
  String get playTrackProduction => 'Production (public)';

  @override
  String get playUpload => 'Upload to Google Play';

  @override
  String get playStepFinish => 'Finish in Play Console';

  @override
  String playUploaded(String version, String track, String draft) {
    return 'Uploaded. Version $version on track “$track”. $draft';
  }

  @override
  String get playDraftNote =>
      'Because the app was never published, Google saved it as a draft: complete the steps below and press “Send for review” in Play Console.';

  @override
  String get playReviewNotSent =>
      'Google could not send the changes for review automatically. They are committed: open Play Console and press \"Send for review\" to publish.';

  @override
  String playManualChecklist(String privacyUrl) {
    return 'Google requires confirming these manually in Play Console (ready answers below):\n- **Privacy policy** → paste the link: $privacyUrl\n- **Data safety**\n- **Content rating** questionnaire\n- **Target audience and content**\n- **Ads** and **App access** (provide a test account if login is required)\n- **Store listing**: 512×512 icon and at least 2 screenshots\n- New personal accounts: Google may require **closed testing** with a minimum number of testers before production';
  }

  @override
  String get playDataSafety => 'Answers for “Data safety”';

  @override
  String get playContentRating => 'Answers for “Content rating”';

  @override
  String get playOtherDeclarations => 'Audience, ads and app access';

  @override
  String get assistantTitle => 'Ask Ember';

  @override
  String get assistantFree => 'Free';

  @override
  String get assistantEmpty =>
      'Hi, I\'m Ember! Ask me anything: app ideas, how to publish on Play Store, how to set up login and databases…';

  @override
  String get assistantUnconfigured =>
      'The free assistant is not active yet: the Gemini key is missing on the computer where Ember runs.';

  @override
  String get assistantHint => 'Ask Ember anything…';

  @override
  String get assistantSuggest1 => 'What app can I build for my shop?';

  @override
  String get assistantSuggest2 => 'How do I publish an app on Play Store?';

  @override
  String get assistantSuggest3 => 'How does Google login work?';

  @override
  String get language => 'Language';

  @override
  String get find => 'Find';

  @override
  String get replace => 'Replace';

  @override
  String get replaceAll => 'All';

  @override
  String get baseUrl => 'Base URL';

  @override
  String fontLabel(String font) {
    return 'Font: $font';
  }

  @override
  String get styleMinimal => 'Light minimal';

  @override
  String get styleDark => 'Dark premium';

  @override
  String get stylePlayful => 'Colorful & playful';

  @override
  String get styleGlass => 'Glassmorphism';

  @override
  String get styleMaterial => 'Material 3';

  @override
  String get styleNeumorph => 'Neumorphism';

  @override
  String get styleLuxury => 'Elegant luxury';

  @override
  String get styleBrutal => 'Bold brutalist';

  @override
  String get stylePastel => 'Soft pastel';

  @override
  String get styleTech => 'Futuristic tech';

  @override
  String get styleNature => 'Nature';

  @override
  String get styleIos => 'iOS style';

  @override
  String get styleRetro => '80s retro';

  @override
  String get styleMono => 'Monochrome';

  @override
  String get styleCorporate => 'Professional';

  @override
  String bWriting(String model) {
    return 'Writing the code with $model…';
  }

  @override
  String bApplying(String change, String model) {
    return 'Applying the change with $model: $change';
  }

  @override
  String get bNoModel => 'No model selected';

  @override
  String get bNoFiles =>
      'The AI did not produce any files: try again or change model.';

  @override
  String bErrorsRemain(int count, String problems) {
    return 'Errors remain after $count fix attempts:\n$problems';
  }

  @override
  String bFixing(int max, int round) {
    return 'Fixing errors (attempt $round of $max)…';
  }

  @override
  String bNoFixes(String problems) {
    return 'The AI did not propose fixes for:\n$problems';
  }

  @override
  String bIncompleteFile(String path) {
    return 'Incomplete file ignored: $path';
  }

  @override
  String bPathNotAllowed(String path) {
    return 'Path not allowed, ignored: $path';
  }

  @override
  String get bTruncated =>
      'Response cut by the token limit: incomplete files will be recreated during fixing.';

  @override
  String get bRefused => 'The model declined the request.';

  @override
  String get bPubGet => 'Installing dependencies (flutter pub get)…';

  @override
  String get bPubGetFailed => 'flutter pub get failed';

  @override
  String get bAnalyze => 'Checking for errors (flutter analyze)…';

  @override
  String get bNoErrors => 'No errors';

  @override
  String bErrorsFound(int count) {
    return '$count errors found';
  }

  @override
  String get bClaudeApplying => 'Claude Code is applying the change…';

  @override
  String get bClaudeBuilding => 'Claude Code is building the app on the PC…';

  @override
  String statusBuilding(String progress) {
    return 'Creating… $progress files';
  }

  @override
  String get bClaudeFailed =>
      'Claude Code did not finish the app: check the log.';

  @override
  String resumeFromHere(int count) {
    return 'Carry on from here ($count files)';
  }

  @override
  String get startOver => 'Start over';

  @override
  String bClaudeStoppedCarryOn(int count) {
    return 'It stopped with $count files already written: carrying on and fixing what is left.';
  }

  @override
  String get bWebBuilding => 'Building the app for the web (about 30 seconds)…';

  @override
  String bWebFailed(String log) {
    return 'The web build failed:\n$log';
  }

  @override
  String get bApk =>
      'Creating the file to install (APK). The first time can take a few minutes…';

  @override
  String get bAab => 'Creating the file for Google Play (AAB)…';

  @override
  String get chooseDesignAi => 'Who draws (logo, mockups, screens)';

  @override
  String get chooseDesignAiHint =>
      'Pick who draws: each one makes 2 mockups, and the 5 logos rotate among them. The engine above writes the code.';

  @override
  String get bLookingAtModel => 'Looking at the app being copied…';

  @override
  String get bIpa => 'Building the iPhone app (IPA)…';

  @override
  String get nameTitle => 'What is your app called?';

  @override
  String get nameHint =>
      'This name goes on the Play Store, in the privacy policy and into the package name, which can never change once Google has it.';

  @override
  String get nameYourOwn => 'Or write your own name';

  @override
  String get nameMore => 'Other names';

  @override
  String get nameUse => 'Use this name';

  @override
  String bReferenceShots(int count) {
    return '$count screens of the app to copy saved: the engine can see it, not just read about it';
  }

  @override
  String get bReferenceShotsFailed =>
      'Could not fetch the screens of the app to copy: working from its description only';

  @override
  String bMissingTopics(String topics) {
    return 'Missing from the app to copy: $topics. Adding them now…';
  }

  @override
  String get bIosReady => 'iPhone app ready';

  @override
  String get bIosFailed => 'iPhone build failed';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iPhone';

  @override
  String get iosTitle => 'iPhone app';

  @override
  String get iosHint =>
      'The same app for iPhone and iPad: same name, same screens, same ads. The file (IPA) goes to App Store Connect.';

  @override
  String get iosNeedsMac =>
      'Only a Mac can build the iPhone app. Save this app on GitHub, open Ember on your Mac and build it there. Everything else works from here.';

  @override
  String get iosBuild => 'Build iPhone app';

  @override
  String get iosBuilding => 'Building the iPhone app…';

  @override
  String get iosReady =>
      'iPhone app ready. It is signed with your Apple account and can go to App Store Connect.';

  @override
  String get iosAppleAccount =>
      'Apple Developer account: 99 USD a year, paid to Apple.';

  @override
  String get ascTitle => 'Send to the App Store';

  @override
  String get ascHint =>
      'Ember writes on Apple what it writes on Google: title, description, what\'s new, privacy address and the privacy answers, in every language of your listing.';

  @override
  String get ascKeyHelp =>
      '1. Open App Store Connect and go to Users and Access → Integrations → App Store Connect API.\n2. Press + and choose the App Manager role.\n3. Download the .p8 file. Apple lets you download it only once.';

  @override
  String get ascKeyId => 'Key ID';

  @override
  String get ascIssuerId => 'Issuer ID';

  @override
  String get ascPrivateKey => 'Contents of the AuthKey_….p8 file';

  @override
  String get ascUploadBuild => 'Send the iPhone file too (needs a Mac)';

  @override
  String get ascSubmit => 'Send for Apple\'s review when everything is set';

  @override
  String get ascPublish => 'Publish on the App Store';

  @override
  String get ascWorking => 'Talking to App Store Connect…';

  @override
  String ascDone(String version, String languages) {
    return 'Done on Apple: version $version, languages: $languages';
  }

  @override
  String get ascOpen => 'Open App Store Connect';

  @override
  String get ascForget => 'Forget the Apple key';

  @override
  String get ascManual =>
      'What stays manual on Apple: the screenshots (iPhone sizes), the age rating questions, price and countries.';

  @override
  String bAndroidFailed(String kind) {
    return '$kind build failed';
  }

  @override
  String bAndroidReady(String kind) {
    return '$kind file ready';
  }

  @override
  String get bStopped => 'Stopped';

  @override
  String get bAppReady => 'App ready';

  @override
  String get bReviewStart => 'Other AIs are now checking the app on their own…';

  @override
  String get bReviewClean => 'The reviewers found nothing to fix.';

  @override
  String bReviewFound(int count) {
    return '$count problems found by the reviewers: fixing them now.';
  }

  @override
  String get bAppUpdated => 'App updated';

  @override
  String actWrites(String file) {
    return 'Writing $file';
  }

  @override
  String actEdits(String file) {
    return 'Editing $file';
  }

  @override
  String actReads(String file) {
    return 'Reading $file';
  }

  @override
  String get actPubGet => 'Installing dependencies';

  @override
  String get actAnalyze => 'Checking for errors';

  @override
  String get forgeTitle => 'Ember is creating your app';

  @override
  String forgeFiles(int count) {
    return '$count files written';
  }

  @override
  String researchingApp(String name) {
    return 'Studying “$name” on Google Play…';
  }

  @override
  String get pickReferenceApp => 'Which app do you mean?';

  @override
  String get pickReferenceAppHint =>
      'Ember will study its features on Google Play and build an app that does the same, with your own name and design.';

  @override
  String get referenceNone => 'None of these, continue without';

  @override
  String forgeFilesOf(int count, int total) {
    return '$count of $total files written';
  }

  @override
  String forgeEta(int minutes) {
    return 'about $minutes min left';
  }

  @override
  String forgeEstimated(int minutes) {
    return 'estimated time about $minutes min';
  }

  @override
  String forgeElapsed(String time) {
    return '$time elapsed';
  }

  @override
  String get forgeBackground =>
      'You can lock the screen or use other apps: Ember keeps working and finishes the app.';

  @override
  String get buyCredits => 'Buy API credits';

  @override
  String get getSubscription => 'Buy a subscription';

  @override
  String get connectSubscription => 'Connect my subscription';

  @override
  String get accessTitle => 'Access & payments';

  @override
  String get accessPaidOutside =>
      'Payments happen on the provider\'s site, not in Ember.';

  @override
  String subscriptionNotConnected(String name) {
    return '$name is not connected: sign in with your subscription on the computer where Ember runs.';
  }

  @override
  String connectHowTo(String plan, String command) {
    return '1. Go to the computer where Ember runs and open a terminal (Ember\'s own works too).\n2. Type: $command\n3. Finish signing in in the browser with your $plan account: no API key, no extra cost.\n4. Come back here: within a minute it is ready to use.';
  }

  @override
  String get connectPersonalNote =>
      'Subscriptions are personal: use them for your own apps, not to build apps for other people.';

  @override
  String get grokNoCli =>
      'Grok subscriptions (SuperGrok) cannot be connected to other apps yet: use an xAI API key.';

  @override
  String subscriptionConnected(String plan) {
    return 'Connected with your $plan subscription: no API key and no extra cost.';
  }

  @override
  String haveSubscription(String plan) {
    return 'Already have $plan?';
  }

  @override
  String subscriptionReadyUse(String engine) {
    return 'Build with $engine on your subscription, without buying API credits.';
  }

  @override
  String subscriptionConnectFirst(String engine) {
    return 'Connect it once to build with $engine at no extra cost.';
  }

  @override
  String get useSubscription => 'Use it';

  @override
  String get bResumeChat =>
      'Continue the interrupted build from where it stopped';

  @override
  String get backToEmber => 'Back to Ember';

  @override
  String get productsTitle => 'In-app purchases to activate on Google Play';

  @override
  String get productsHint =>
      'Ember creates and activates these products in Play Console for you, with prices converted for every country.';

  @override
  String get productsActivate => 'Create and activate on Play Console';

  @override
  String get productsNeedKey =>
      'Connect Google Play first (service account key): open the publish steps.';

  @override
  String get productsBefore =>
      '1. Before activating, open Play Console. You do these steps once per account and per app.\n2. Go to Setup → Payments profile and add your bank account and tax details.\n3. Upload this app\'s file for Google Play (AAB) to internal testing: Google wants a version with payments.\n4. In Users and permissions, give the service account \"Manage orders and subscriptions\".';

  @override
  String get productsOpenPayments => 'Payments profile';

  @override
  String get productsUploadFirst => 'Upload the file for Google Play (AAB)';

  @override
  String get productsActive => 'Active on Google Play';

  @override
  String productPerPeriod(String price, String period) {
    return '$price / $period';
  }

  @override
  String productTrial(int days) {
    return '$days-day free trial';
  }

  @override
  String get logoTitle => 'App logo';

  @override
  String get logoHint =>
      'Ember draws 6 proposals. Not convinced? Tap “More logos” as many times as you like. The one you choose becomes the app icon and the Play Store icon and banner.';

  @override
  String get logoDescribe => 'Describe the logo (optional)';

  @override
  String get logoDescribeHint =>
      'E.g.: blue shield with a pen, modern, no text';

  @override
  String get logoGenerate => 'Generate 6 logos';

  @override
  String get logoMore => 'More logos';

  @override
  String get logoUse => 'Use this logo';

  @override
  String get logoApplied =>
      'Logo set: app icons are being generated and the preview will update.';

  @override
  String get shotsTitle => 'Play Store screenshots';

  @override
  String get shotsHint =>
      'Ember opens the app like a phone and takes 6 screenshots of the main screens (1080×1920), ready for Google Play.';

  @override
  String get shotsPreparing =>
      'Ember is preparing the app for screenshots (a demo mode for each screen); the photos start automatically when it is done.';

  @override
  String get shotsPreparingChat => 'Prepare the app for Play Store screenshots';

  @override
  String get shotsGenerate => 'Take 6 screenshots';

  @override
  String get shotsAgain => 'Take them again';

  @override
  String shotsSaved(int count) {
    return '$count screenshots saved for Google Play.';
  }

  @override
  String get pubTitle => 'Publish with Ember';

  @override
  String pubAccountAsk(String app) {
    return 'Hi! I will guide you to publish **$app** on Google Play, one step at a time, and I will do the technical parts myself.\n\nFirst question: do you already have a **Google Play Console developer account**?';
  }

  @override
  String get pubYesHaveIt => 'Yes, I have it';

  @override
  String get pubNoHowTo => 'No, how do I create it?';

  @override
  String get pubAccountHow =>
      'Creating it takes 10 minutes:\n1. Open the sign-up page (button below) with your Google account\n2. Choose **Personal** (or Organization if you have a company)\n3. Pay **25 \$ once**: it goes to Google, not to Ember\n4. Verify your identity with a document: Google usually confirms in 1-2 days\n\nWhen your account is active, come back here.';

  @override
  String get pubNowIHaveIt => 'Done, my account is active';

  @override
  String pubCreateApp(String package) {
    return 'Now create the app in Play Console (only the first time):\n1. Press **Open Play Console** below, then **Create app**\n2. App name, default language, type **App**, **Free**\n3. Tick the declarations and press **Create app**\n\nThis app\'s package name is `$package`: Google links it automatically on the first upload.';
  }

  @override
  String get pubDone => 'Done';

  @override
  String get pubConnect =>
      '1. Now I connect Ember to Google Play, so I can upload your apps.\n2. **I do it myself**: I create a special key in your Google account, on this PC.\n3. For that I set up a Google Cloud project, the Play API and the key.\n4. The key is used only to upload apps and stays on your device.';

  @override
  String get pubDoItEmber => 'Do it for me, Ember';

  @override
  String get pubManual => 'I prefer to do it by hand';

  @override
  String get pubKeyWorking =>
      'Creating the Google Cloud project, enabling the Play API and creating the key (about 1-2 minutes)…';

  @override
  String get pubInvite =>
      'Key created.\n\nLast connection: the key must be allowed to publish in **your** Play Console.\n1. Press **Open Play Console** below\n2. Copy the address of the page you see (any page) and **paste it here in the chat**\n\nThen the PC browser opens once: sign in with the same Google account and press **Allow**. I send the invitation myself.';

  @override
  String get pubInviteBadLink =>
      'That link does not contain the Play Console account number. Open play.google.com/console and paste the address of that page.';

  @override
  String get pubInviteWorking =>
      'Inviting the key into your Play Console… if the PC browser opens, sign in and press Allow.';

  @override
  String pubInviteManual(String email) {
    return 'I could not send the invitation automatically, so let\'s do it together (2 minutes):\n1. **Open Play Console**, then **Users and permissions** and **Invite new users**\n2. Paste this email: `$email`\n3. **Account permissions**: tick releases, store presence, app content and orders\n4. Press **Invite user**, then **Done** here';
  }

  @override
  String get pubGraphics =>
      'Connected to Google Play.\n\nFor the store page Google wants the **512×512 icon**, the **1024×500 banner** and at least **2 screenshots**. If you haven\'t done them yet, go back to the app screen: in **App logo** and **Play Store screenshots** Ember makes them in one tap. I upload them automatically together with the app.';

  @override
  String get pubContinue => 'Continue';

  @override
  String get pubBackToApp => 'Back to the app';

  @override
  String get pubUpload =>
      'Now the store page and the upload: I write title, descriptions and privacy policy, prepare the answers for Google\'s forms, then upload the signed AAB with icon, banner and screenshots.\n\nFirst generate the **AAB** from the app screen if you haven\'t yet.';

  @override
  String get pubPrepareUpload => 'Prepare and upload';

  @override
  String get pubFinish =>
      '1. Your app is on Google Play. A few forms are left: open **Play Console**.\n2. Confirm by hand **Data safety**, **Content rating**, **Target audience**, **Ads** and **App access**.\n3. Copy the answers from the last screen: they are ready.\n4. If your personal account is new, run a **closed test with 12 testers for 14 days** before going public.\n5. Any doubt? Ask me here below.';

  @override
  String get pubReviewAnswers => 'See the ready answers';

  @override
  String get pubPasteLink => 'Paste the Play Console link here…';

  @override
  String get pubAskAnything => 'Ask Ember anything about publishing…';

  @override
  String get adsTitle => 'AdMob ads';

  @override
  String get adsHint =>
      'The app already shows Google TEST ads (safe while developing) and asks for EU consent. To earn money, create the real ad units in AdMob and paste the IDs here: Ember puts them in the app.';

  @override
  String get adsSteps =>
      '1. Open AdMob. It takes 5 minutes, once per app.\n2. Go to Apps → Add app → Android.\n3. At \"Is the app on Google Play?\" answer No if it is not published yet.\n4. Write the name and press Add.\n5. Copy the App ID (ca-app-pub-…~…).\n6. Go to Ad units → Add ad unit and choose a format from the list below.\n7. Press Create and copy its ID (ca-app-pub-…/…). Repeat for each format.\n8. After publishing, link the app to its Play Store listing in AdMob.\n9. Add app-ads.txt if AdMob asks for it.';

  @override
  String get adsOpenAdmob => 'Open AdMob';

  @override
  String get adsAppId => 'AdMob App ID';

  @override
  String adsUnitId(String format) {
    return '$format ad unit ID';
  }

  @override
  String get adsApply => 'Put the real IDs in the app';

  @override
  String get adsInvalid =>
      'IDs must look like ca-app-pub-1234567890123456~1234567890 (app) and ca-app-pub-1234567890123456/1234567890 (ad units).';

  @override
  String get adsChat => 'Set the real AdMob IDs';

  @override
  String get pubNothingUploaded =>
      'Nothing was uploaded to Google Play: press \"Upload to Google Play\" in the next screen and wait for the confirmation, then come back.';

  @override
  String upListing(String languages) {
    return '✓ Store listing (title and descriptions): $languages';
  }

  @override
  String get upNoListing =>
      '✗ Store listing not written (title and descriptions were empty)';

  @override
  String get upIcon => '✓ 512×512 icon';

  @override
  String get upNoIcon => '✗ Icon missing: choose a logo in \"App logo\" first';

  @override
  String get upFeature => '✓ 1024×500 banner';

  @override
  String get upNoFeature =>
      '✗ Banner missing: choose a logo in \"App logo\" first';

  @override
  String upShots(int count) {
    return '✓ $count phone screenshots';
  }

  @override
  String get upNoShots =>
      '✗ Screenshots missing: take them in \"Play Store screenshots\" first';

  @override
  String get upTitle => 'Google Play';

  @override
  String get upHint =>
      'Everything is saved for this app. Change what you need, then send a new version: Ember builds a new signed AAB (higher version) and uploads it with the listing, logo and screenshots.';

  @override
  String get upStateLogo => 'Logo';

  @override
  String upStateShots(int count) {
    return 'Screenshots: $count';
  }

  @override
  String get upStateListing => 'Title and descriptions';

  @override
  String get upEditListing => 'Edit title and descriptions';

  @override
  String get upNewVersion => 'New version on Google Play';

  @override
  String get upBuilding => 'Creating the new file for Google Play (AAB)…';

  @override
  String get upUploading => 'Uploading to Google Play…';

  @override
  String get upNeedsSetup =>
      'First connect Google Play and write the listing once: open the publishing guide.';

  @override
  String get upOpenGuide => 'Publishing guide';

  @override
  String get pubPasteConsoleLink =>
      'Tip: open Play Console once and paste the address of that page here in the chat. From then on every button opens **your** account directly, without asking which one.';

  @override
  String get privacyPublicHint =>
      'Paste a public link Google can open (e.g. a GitHub gist or a page on your site).';

  @override
  String get privacyLocalWarning =>
      'This address only works on this computer: Google cannot open it. Paste a public link instead.';

  @override
  String get consoleLinkLabel => 'Your Play Console link (paste once)';

  @override
  String get consoleLinkHint =>
      'Open Play Console, choose your developer account, then copy the address of that page and paste it here: the buttons will then open your account and your app directly.';

  @override
  String consoleLinkSaved(String id) {
    return 'Developer account $id saved: the buttons now open your console directly.';
  }

  @override
  String get upStateConnected => 'Google Play connected (key on this device)';

  @override
  String get upNeedsKey =>
      'Google Play is not connected on this device: open the publishing guide and press “Do it for me, Ember” to create the key (1 minute).';

  @override
  String get upNeedsListing =>
      'Write the store listing once: press “Edit title and descriptions”.';

  @override
  String get upConnectPlay => 'Connect Google Play';

  @override
  String get dsButton => 'Fill Data safety';

  @override
  String get dsWorking =>
      'Reading what the app collects and filling the Data safety form…';

  @override
  String get dsDone =>
      'Data safety sent to Google Play — check it in Play Console → App content → Data safety and press Submit.';

  @override
  String get dsNeedsCsv =>
      'First export the form from Play Console: App content → Data safety → Export to CSV. Save it in Downloads, then press this button again.';

  @override
  String get driveBackup => 'Save to Google Drive';

  @override
  String get driveSaving =>
      'Asking Google for permission and saving the key on your Drive…';

  @override
  String get driveSaved => 'Keystore and password saved on your Google Drive';

  @override
  String get driveOpenFolder => 'Open the folder on Drive';

  @override
  String get acAskPrivacy => 'Write the privacy policy for this app';

  @override
  String get acAskAdmob => 'How do I add AdMob ads to this app?';

  @override
  String get acAskContent => 'What do I answer in Play Console App content?';

  @override
  String get acAssistant => 'Ask Ember about this app';

  @override
  String get acTitle => 'App content (Play Console)';

  @override
  String get acHint =>
      'Google asks these questions before the app can go public. Ember has the answer for each one: copy it and click it in Play Console.';

  @override
  String get acOpenConsole => 'Open App content';

  @override
  String get acCopy => 'Copy answer';

  @override
  String get acCopied => 'Copied';

  @override
  String get acAuto => 'Ember does this one';

  @override
  String get paste => 'Paste';

  @override
  String get ghSavedOn => 'Saved on GitHub';

  @override
  String get ghTitle => 'Save on GitHub';

  @override
  String get ghHint =>
      'Keeps a copy of this app\'s source in your own GitHub repository. The signing key, the build folder and the Google files are never uploaded.';

  @override
  String get ghToken => 'GitHub token';

  @override
  String get ghTokenHelp =>
      'A personal access token with the \"repo\" permission. It is stored encrypted on this device and used only to upload this app.';

  @override
  String get ghGetToken => 'Create a token on GitHub';

  @override
  String get ghRestoreTitle => 'Open an app saved on GitHub';

  @override
  String get ghRestoreHint =>
      'The apps you saved on GitHub come back onto this computer, with everything they had. This is how you work on the same app from Windows and from a Mac.';

  @override
  String get ghRestoreLoad => 'Show my apps';

  @override
  String get ghRestoreNone =>
      'No app saved from Ember yet on this GitHub account.';

  @override
  String get ghRestoreHere => 'Already on this computer';

  @override
  String get ghRestoreAction => 'From GitHub';

  @override
  String get refresh => 'Refresh';

  @override
  String get ghSave => 'Save on GitHub';

  @override
  String get ghSaving => 'Uploading the app to GitHub…';

  @override
  String get ghOpen => 'Open the repository';

  @override
  String get ghForgetToken => 'Forget the token';

  @override
  String get ghNeedsToken => 'Paste a GitHub token first.';

  @override
  String ghCreated(String repo) {
    return 'Repository $repo created and app uploaded';
  }

  @override
  String ghUpdated(String repo) {
    return 'App uploaded to $repo';
  }

  @override
  String get acCopyForExtension => 'Copy for the browser helper';

  @override
  String get acFillForMe => 'Fill in Play Console';

  @override
  String get acFilling =>
      'Ember is answering the questions in the Chrome window it opened. Watch it, and take over whenever you want.';

  @override
  String acFilled(int done, int total) {
    return 'Saved $done of $total sections.';
  }

  @override
  String get acNeedsAppLink =>
      'Ember does not know this app on Play Console yet: open your app there, copy the address from the browser and paste it in the publishing screen.';

  @override
  String get acAppLink => 'Address of this app in Play Console';

  @override
  String get acLinkNotUnderstood =>
      'That address does not name an app. Open the app in Play Console and copy the whole address from the browser bar.';

  @override
  String get adsAdd => 'Add AdMob ads';

  @override
  String get adsAddHint =>
      'Ember puts ads on every screen that can carry one, within the limits that keep an AdMob account alive, and shows Google test ads until you paste your own ids.';

  @override
  String get adsAddChat => 'Add AdMob ads with test ids';

  @override
  String get adsYes => 'Yes, show ads';

  @override
  String get adsNo => 'No ads';

  @override
  String get adsDeclined =>
      'No ads in this app. Ask Ember for them whenever you change your mind.';

  @override
  String get adsRemove => 'Remove the ads';

  @override
  String get adsRemoveChat => 'Remove AdMob from this app';

  @override
  String get adsAppIdHelp =>
      'The code with the ~ , next to the Android icon. The same one for every ad unit.';

  @override
  String get adsUnitHelp =>
      'The code with the / , next to the card icon. A different one for each format.';

  @override
  String get checkTitle => 'Ember checked this app';

  @override
  String get checkAllGood =>
      'Everything needed for the app to work is in place.';

  @override
  String checkFound(int count) {
    return '$count things do not work yet. Ember can put right the ones with the tool icon, once you say so.';
  }

  @override
  String checkFixNow(int count) {
    return 'Fix $count of them';
  }

  @override
  String get checkFixing => 'Fixing…';

  @override
  String get checkAgain => 'Check again';

  @override
  String get checkAskEmber => 'Have Ember fix it';

  @override
  String get checkAsked =>
      'Asked. Ember is working on it: watch the chat below.';

  @override
  String get previewLoginInBrowser =>
      'Google will not sign anyone in inside this window, and a login done in the browser does not carry over here. In this window use email and password; Google sign-in works in the browser and on a phone.';

  @override
  String get phoneTitle => 'Your phone';

  @override
  String get phoneHint =>
      'Ember installs the app on the phone plugged into this computer and opens it. Google sign-in, notifications and ads only behave properly there.';

  @override
  String phoneRunOn(String name) {
    return 'Run on $name';
  }

  @override
  String phoneUnauthorized(String name) {
    return '$name: unlock it and allow USB debugging';
  }

  @override
  String get phoneBuilding => 'Building the app for the phone…';

  @override
  String get phoneInstalling => 'Installing on the phone…';

  @override
  String get phoneLookAgain => 'Look for phones again';

  @override
  String get phoneOpenHere => 'Open on the phone now';

  @override
  String get phoneSameWifi =>
      'Point the phone camera at the code. The phone must be on the same Wi-Fi as this computer.';

  @override
  String get playLanguages => 'Store languages';

  @override
  String get playTranslating => 'Writing the listing in the other languages…';

  @override
  String get logoDelete => 'Delete';

  @override
  String get logoDeleted => 'Logo deleted';

  @override
  String get logoDropHint => 'Drag a logo here for 5 variants of it';

  @override
  String get logoVariantsOf => 'Variants of this logo';

  @override
  String get playUpdateListingOnly => 'Update only the store page';

  @override
  String get playUpdateListingOnlyHint =>
      'For an app already on Google Play: texts, all languages and graphics go live without a new version.';

  @override
  String get playTranslationsStale =>
      'The text changed: the other languages still have the old one.';

  @override
  String get playTranslateAgain => 'Translate again';

  @override
  String get playLanguageIncluded => 'Publish this language on Google Play';

  @override
  String get playLanguageNotTranslated =>
      'Not translated yet: it is written when you save with this language on.';

  @override
  String get playListingSaved =>
      'Listing saved: nothing to generate. Change the text only if you want, then upload.';

  @override
  String get playRewriteWithAi => 'Write it again with AI';

  @override
  String get historyTitle => 'History';

  @override
  String get historyNewApp => 'New app';

  @override
  String get historyDrafts => 'Drafts';

  @override
  String get historyToday => 'Today';

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String get historyLast7Days => 'Last 7 days';

  @override
  String get historyOlder => 'Older';

  @override
  String get historyEmpty =>
      'Nothing here yet. The apps you start and the drafts you write show up here.';

  @override
  String get brandTagline => 'APP MAKER';

  @override
  String get showSecret => 'Show';

  @override
  String get hideSecret => 'Hide';

  @override
  String get ok => 'OK';

  @override
  String get details => 'Details';

  @override
  String get more => 'More';

  @override
  String get advanced => 'Advanced';

  @override
  String get done => 'Done';

  @override
  String madeWith(String engine) {
    return 'Made with $engine · Options';
  }

  @override
  String get buildOptionsTitle => 'Who builds your app';

  @override
  String get homeMenu => 'Other ways to start';

  @override
  String get emptyProject => 'Empty project';

  @override
  String get settings => 'Settings';

  @override
  String get hubNextSteps => 'Next steps';

  @override
  String get hubTest => 'Try it on your phone';

  @override
  String get hubTestHint => 'Open it with a QR code or install it';

  @override
  String get hubImages => 'Icon and pictures';

  @override
  String get hubImagesHint => 'The logo and the store screenshots';

  @override
  String get hubChecks => 'Checks';

  @override
  String get hubChecksHint => 'What Ember and the reviewers found';

  @override
  String hubChecksCount(int count) {
    return '$count to fix';
  }

  @override
  String get hubPlay => 'Google Play';

  @override
  String get hubPlayHint => 'Publish or update on Android';

  @override
  String get hubAppStore => 'App Store';

  @override
  String get hubAppStoreHint => 'Publish for iPhone';

  @override
  String get hubMore => 'More';

  @override
  String get hubMoreHint => 'Backup, ads, purchases, the code';

  @override
  String get techDetails => 'Technical details';

  @override
  String get changeHint => 'What do you want to change?';

  @override
  String get installFileTitle => 'File to install (APK)';

  @override
  String get installFileHint =>
      'A file you can send to any Android phone and install.';

  @override
  String get storeFileTitle => 'File for Google Play (AAB)';

  @override
  String get storeFileHint =>
      'Only needed if you upload to the Play Console by hand: Ember makes it for you when it publishes.';

  @override
  String get makeFile => 'Make the file';

  @override
  String get openCodeTitle => 'The code';

  @override
  String get openCodeHint =>
      'Open the editor to read or change the files by hand.';

  @override
  String get backToApp => 'Back to the app';

  @override
  String designChosen(String name) {
    return 'Design: $name';
  }

  @override
  String get reviewFixLabel => 'Fix from the reviewers';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'Same as the device';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsAi => 'Artificial intelligences';

  @override
  String get settingsAccounts => 'Connected accounts';

  @override
  String get settingsAccountsHint =>
      'You connect them the first time you need them, from the app\'s page. Here you can see them and disconnect them.';

  @override
  String accountConnected(String name) {
    return '$name: connected';
  }

  @override
  String accountNotConnected(String name) {
    return '$name: not connected';
  }

  @override
  String get disconnect => 'Disconnect';

  @override
  String get runnerAddress => 'Where Ember runs';

  @override
  String get runnerAddressHint =>
      'The address of the computer that builds your apps (the Runner). Change it only if you were told to.';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get reviewersTitle => 'App reviewers';

  @override
  String get reviewersHint =>
      'When an app is finished, these models read it on their own and say what is fake, what is missing and what does not work; the fixes go back by themselves to whoever wrote the app. You set them once and they are used for every app.';

  @override
  String get aiKeysTitle => 'Keys';

  @override
  String plLanguagesOn(int count) {
    return 'Languages: $count on';
  }

  @override
  String get plManage => 'Manage';

  @override
  String get plLanguagesHint =>
      'Turn a language on to publish the store page in it. Tap a language to read or fix its text.';

  @override
  String get plSearchLanguage => 'Search a language';

  @override
  String get plNoLanguageFound => 'No language with this name.';

  @override
  String get plEnglish => 'English';

  @override
  String get plMainLanguage => 'Main language, always on';

  @override
  String get plLangReady => 'Translated';

  @override
  String get plLangOld => 'Old text';

  @override
  String get plLangMissing => 'To write';

  @override
  String get plLangWriting => 'Writing…';

  @override
  String get plGenerating => 'Ember is writing the store page…';

  @override
  String get plFeeTitle => 'Google asks for \$25, once';

  @override
  String get plAiBadAnswer =>
      'The AI gave an answer Ember could not read. Try again.';

  @override
  String get plNoAi => 'No AI is set up yet: add one in Settings.';

  @override
  String get plPrivacyLocalOnly =>
      'The privacy policy is saved only on this computer: Google cannot open it. Connect GitHub in Ember, or paste a link of your own below.';

  @override
  String plPrivacyNotPublished(String error) {
    return 'Privacy policy not published: $error. The rest of the store page was saved; paste a link of your own below.';
  }

  @override
  String get asConnTitle => 'Your Apple key';

  @override
  String get asConnHint =>
      'Ember uses it to publish for you. You save it once and it is ready for all your apps.';

  @override
  String asKeySaved(String file) {
    return 'Key saved: $file';
  }

  @override
  String get asChangeKey => 'Change key';

  @override
  String get asTeamId => 'Team ID (optional)';

  @override
  String get asTeamIdHelp =>
      'Needed to sign the iPhone app. Leave it empty and Ember reads it from Apple with your key.';

  @override
  String get asP8KeepHelp => 'Leave it empty to keep the key already saved.';

  @override
  String get asLoadP8 => 'Load .p8 file';

  @override
  String get asSaveKey => 'Save key';

  @override
  String get asP8FileType => 'Apple key (.p8)';

  @override
  String get asVerify => 'Check the connection';

  @override
  String get asVerifyOk => 'The connection works';

  @override
  String get asVerifyOkReached =>
      'The connection works: Ember reached App Store Connect';

  @override
  String asVerifyTeam(String team) {
    return 'Team $team';
  }

  @override
  String get asBadKeyId =>
      'This Key ID is not valid. It is the short code next to the key, for example Z47GM3ZDZ6.';

  @override
  String get asBadIssuerId =>
      'This Issuer ID is not valid. It is the long code at the top of the Keys page.';

  @override
  String get asBadP8 =>
      'This is not the content of the key. Paste the whole AuthKey_….p8 file, from the line -----BEGIN PRIVATE KEY----- to -----END PRIVATE KEY-----. The file name alone is not enough.';

  @override
  String asP8ReadFailed(String error) {
    return 'Ember could not read the .p8 file: $error';
  }

  @override
  String get asSaveKeyFirst =>
      'Save your Apple key first: Key ID, Issuer ID and the .p8 file.';

  @override
  String get asFillTitle => 'What Ember fills in for you';

  @override
  String get asFillHint =>
      'When you publish, Ember sets by itself the age rating (4+), the encryption declaration and the privacy answers. If you choose them here, also the category, the price and the screenshots.';

  @override
  String get asCategory => 'App Store category';

  @override
  String get asCategoryNone => 'Do not set';

  @override
  String get asFree => 'Free app (in every country)';

  @override
  String get asScreenshots => 'Create and upload iPhone and iPad screenshots';

  @override
  String get asScreenshotsHelp =>
      'Taken from the web preview. The app needs its \"screenshot mode\".';

  @override
  String get asReviewTitle => 'Details for Apple\'s review (optional)';

  @override
  String get asReviewEmail => 'Contact email';

  @override
  String get asReviewEmailHelp =>
      'Leave it empty to use the email of your account.';

  @override
  String get asMarketingUrl => 'Your website (Marketing URL)';

  @override
  String get asMarketingUrlHelp =>
      'AdMob looks for app-ads.txt here. Saved for all your apps.';

  @override
  String get asReviewPhone => 'Contact phone';

  @override
  String get asReviewPhoneHelp =>
      'Apple requires it, for example +39 333 1234567. Only the person reviewing the app sees it. Ember remembers it for your next apps.';

  @override
  String get asReviewNotes => 'Notes for the reviewer';

  @override
  String get asDemoUser => 'Demo account (if the app needs a login)';

  @override
  String get asDemoPass => 'Demo password';

  @override
  String get asChecksTitle => 'Before sending';

  @override
  String get asChecksNone => 'No problems for Apple.';

  @override
  String asChecksBlock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problems stop the app from being sent.',
      one: '1 problem stops the app from being sent.',
    );
    return '$_temp0';
  }

  @override
  String get asChecksWarn => 'Only warnings: the app can be sent.';

  @override
  String get asBlocks => 'Stops sending';

  @override
  String get asWarning => 'Warning';

  @override
  String asFixDone(String message) {
    return 'Fixed: $message';
  }

  @override
  String asFixFailed(String message) {
    return 'Not fixed: $message';
  }

  @override
  String asCanClose(int minutes) {
    return 'You can close this page: Ember carries on by itself and sends the app for review as soon as Apple has finished ($minutes min).';
  }

  @override
  String asRunningFor(int minutes) {
    return 'Running for $minutes min.';
  }

  @override
  String get asDoneExport => 'Encryption declaration set';

  @override
  String get asDoneAge => 'Age rating filled in';

  @override
  String get asDoneCategory => 'Category set';

  @override
  String get asDoneReview => 'Review details saved';

  @override
  String get asDoneFree => 'Price: free in every country';

  @override
  String get asDonePrivacy => 'Privacy answers filled in';

  @override
  String asDoneShots(int count) {
    return 'Screenshots uploaded: $count';
  }

  @override
  String get asCatUtilities => 'Utilities';

  @override
  String get asCatProductivity => 'Productivity';

  @override
  String get asCatBusiness => 'Business';

  @override
  String get asCatEducation => 'Education';

  @override
  String get asCatEntertainment => 'Entertainment';

  @override
  String get asCatFinance => 'Finance';

  @override
  String get asCatFoodAndDrink => 'Food & Drink';

  @override
  String get asCatHealthAndFitness => 'Health & Fitness';

  @override
  String get asCatLifestyle => 'Lifestyle';

  @override
  String get asCatMusic => 'Music';

  @override
  String get asCatNavigation => 'Navigation';

  @override
  String get asCatNews => 'News';

  @override
  String get asCatPhotoAndVideo => 'Photo & Video';

  @override
  String get asCatReference => 'Reference';

  @override
  String get asCatShopping => 'Shopping';

  @override
  String get asCatSocial => 'Social Networking';

  @override
  String get asCatSports => 'Sports';

  @override
  String get asCatTravel => 'Travel';

  @override
  String get asCatWeather => 'Weather';

  @override
  String get asCatBooks => 'Books';

  @override
  String get asCatDeveloperTools => 'Developer Tools';

  @override
  String get asCatGraphicsAndDesign => 'Graphics & Design';

  @override
  String get asCatGames => 'Games';

  @override
  String get reviewTitle => 'App check';

  @override
  String get reviewHintNone =>
      'Have the finished app checked by several AIs: each one reads it on its own and says what is fake, what is missing and what does not work. Add at least one reviewer below.';

  @override
  String reviewHintReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviewers ready',
      one: '1 reviewer ready',
    );
    return '$_temp0. Each one reads the app on its own; what more than one of them sees goes to the top of the list.';
  }

  @override
  String get reviewReviewers => 'Reviewers';

  @override
  String get reviewReading => 'The reviewers are reading the app…';

  @override
  String reviewNoAnswer(String name) {
    return '$name: no answer';
  }

  @override
  String get reviewNothingFound => 'The reviewers found no problems.';

  @override
  String get reviewAddReviewer => 'Add a reviewer';

  @override
  String get reviewRun => 'Check the app';

  @override
  String get reviewKeySavedMask => '•••••• (key saved)';

  @override
  String get reviewPasteKeyHint => 'paste the key here';

  @override
  String get reviewRemoveKey => 'Remove the key';

  @override
  String get reviewFixedRecheck => 'Fixed: check it again';

  @override
  String get reviewFixing => 'Fixing…';

  @override
  String get reviewFix => 'Fix';

  @override
  String get reviewPasteKeyFirst => 'Paste the key first.';

  @override
  String get reviewKeySaved => 'Key saved.';

  @override
  String get reviewKeyRemoved => 'Key removed.';

  @override
  String needsYouTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things are needed from you',
      one: 'One thing is needed from you',
    );
    return '$_temp0';
  }

  @override
  String get needsYouHint =>
      'Ember cannot do them alone (a sign-in, a key, an account). Do them and tap \"Done\": it carries on from where it stopped.';

  @override
  String get needsYouIgnore => 'Ignore';

  @override
  String listAnd(String first, String last) {
    return '$first and $last';
  }

  @override
  String panelDownOne(String names) {
    return '$names is not working';
  }

  @override
  String panelDownMany(String names) {
    return '$names are not working';
  }

  @override
  String get panelNoneLeft =>
      'No AI is left: nothing can be drawn or checked. Try again, or close.';

  @override
  String get panelOneLeft =>
      'Only 1 AI is left: it will draw alone and nobody will check its work.';

  @override
  String panelSomeLeft(int count) {
    return '$count AIs are left: they work together and check each other.';
  }

  @override
  String panelProceedWithout(String name) {
    return 'Go on without $name';
  }

  @override
  String panelProceedWithoutMany(int count) {
    return 'Go on without $count AIs';
  }

  @override
  String get panelAllOk => 'All the AIs are working';

  @override
  String get panelHoldNote =>
      'Nothing starts until you decide. If it is a sign-in or key problem, fix it now and press Retry: when it turns green, everyone goes on together.';

  @override
  String get panelRetryAll => 'Retry all';

  @override
  String get panelContinueAll => 'Continue with all';

  @override
  String get panelTrying => 'Trying…';

  @override
  String get pingNoAnswer => 'no answer';

  @override
  String get pingTimeout => 'not answering (25s)';

  @override
  String get mockupRefined => 'redrawn with the notes';

  @override
  String mockupPanelNotes(String notes) {
    return 'Notes from the panel: $notes';
  }

  @override
  String mockupAgreeing(int count) {
    return 'The $count AIs are choosing the 8 directions together…';
  }

  @override
  String mockupComparing(int count, int mockups) {
    return 'The $count designers are comparing the $mockups mockups…';
  }

  @override
  String get mockupRedrawing =>
      'Each designer is redrawing its mockup with the others\' notes…';

  @override
  String get mockupInvalid => 'The model did not return a valid mockup';

  @override
  String get assistantSignIn => 'Sign in to use the assistant';

  @override
  String get imagesLabel => 'Images';

  @override
  String assistantImageTooLarge(String name) {
    return '$name: image too large (max 3.5 MB)';
  }

  @override
  String get assistantAddImage => 'Add an image';

  @override
  String get assistantFixApp => 'Fix the app with this request';

  @override
  String get findPrevious => 'Previous result';

  @override
  String get findNext => 'Next result';

  @override
  String get toggleReplace => 'Show or hide replace';

  @override
  String get clearConsole => 'Clear the console';

  @override
  String get stopAutoRebuild => 'Stop rebuilding on save';

  @override
  String get deviceTablet => 'Tablet';

  @override
  String get deviceDesktop => 'Computer';

  @override
  String get checkEmailToConfirm =>
      'Check your email to confirm your registration.';
}
