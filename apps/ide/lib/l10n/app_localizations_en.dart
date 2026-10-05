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
  String get loginSubtitle => 'Build Flutter apps from any device, with AI.';

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
      'Development mode: Supabase not configured, email-only sign in through the Runner.';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordTooShort => 'At least 6 characters';

  @override
  String get signOut => 'Sign out';

  @override
  String get projects => 'Your apps';

  @override
  String get noProjects => 'No apps summoned yet. Describe one above.';

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
    return '$path changed on the Runner after you opened it.';
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
      'This address only works on this computer. Use the Runner\'s LAN IP (e.g. http://192.168.1.20:8787) to open it from a phone.';

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
  String get aiSettings => 'API keys & models';

  @override
  String get apiKeysHint =>
      'Keys stay encrypted on this device (secure storage). With the proxy on they pass through your Runner for each request only and are never stored or logged.';

  @override
  String get useRunnerProxy => 'Route through Runner (proxy)';

  @override
  String get useRunnerProxyHint =>
      'Recommended. Turn off to call providers directly from this device.';

  @override
  String get useRunnerProxyWeb =>
      'Required on web: browsers cannot call providers directly.';

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
    return 'Works ✓ ($model)';
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
      'Claude Code is not available on this Runner (it must be installed and logged in on the Runner\'s PC).';

  @override
  String get appPromptHint =>
      'E.g.: a recipe app with photos, shopping list and cooking timer…';

  @override
  String get chooseAi => 'Choose the engine';

  @override
  String get createApp => 'Ember App';

  @override
  String get openEditor => 'Editor';

  @override
  String get describeYourApp => 'Summon your app';

  @override
  String get describeYourAppHint =>
      'Describe what it should do and how it should look. Ember writes it, checks it and shows it to you. (*Gemini: Google\'s free tier with daily limits)';

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
  String get appReadyTitle => 'Your app is ready 🎉';

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
  String get androidFileQuestion => 'Do you want the Android file?';

  @override
  String get androidFileHint =>
      'APK: install on a phone. AAB: upload to Google Play Console. Both signed.';

  @override
  String get generateApk => 'Build APK';

  @override
  String get generateAab => 'Build AAB';

  @override
  String androidBuilding(String kind) {
    return 'Building $kind… the first time can take 3-5 minutes.';
  }

  @override
  String get downloadApk => 'Download & install APK';

  @override
  String get downloadAab => 'Download AAB';

  @override
  String get apkInstallHint =>
      'Signed APK. If Android asks, allow installs from this source.';

  @override
  String get aabHint =>
      'AAB signed with this app\'s upload key: ready for Google Play Console. The version code increases on every build.';

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
    return 'not installed on the Runner ($name)';
  }

  @override
  String get terminalCliHint =>
      'Claude Code, Codex and Gemini use the login on the Runner\'s machine. The first time, follow the instructions in the terminal to sign in.';

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
      'You need a **service account key** (once for all your apps):\n1. Open **Google Cloud** and enable **Google Play Android Developer API**\n2. **Service accounts** → **Create** → **Keys** → **Add key** → **JSON** (a file downloads)\n3. In **Play Console** → **Users and permissions** → **Invite new users** → paste the service account email → grant **release** permissions\n4. Open the downloaded JSON and **paste its whole content here**\n\nThe key stays encrypted on this device and is used only for uploads.';

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
    return '✅ Uploaded! Version $version on track “$track”. $draft';
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
      'The free assistant is not active on this server yet (the Runner\'s Gemini key is missing).';

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
  String get bNoErrors => 'No errors ✓';

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
      'Building the APK (the first time can take a few minutes)…';

  @override
  String get bAab => 'Building the AAB for the Play Store…';

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
  String get bIosReady => 'iPhone app ready ✓';

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
      'In App Store Connect: Users and Access → Integrations → App Store Connect API → + . Choose the App Manager role, then download the .p8 file (Apple lets you download it once).';

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
    return '$kind ready ✓';
  }

  @override
  String get bStopped => 'Stopped';

  @override
  String get bAppReady => 'App ready ✓';

  @override
  String get bReviewStart => 'Other AIs are now checking the app on their own…';

  @override
  String get bReviewClean => 'The reviewers found nothing to fix.';

  @override
  String bReviewFound(int count) {
    return '$count problems found by the reviewers: fixing them now.';
  }

  @override
  String get bAppUpdated => 'App updated ✓';

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
  String get forgeTitle => 'Ember is summoning your app';

  @override
  String forgeFiles(int count) {
    return '$count files summoned';
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
    return '$count of $total files summoned';
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
    return '$name is not connected: log in with your subscription on the Runner PC.';
  }

  @override
  String connectHowTo(String plan, String command) {
    return 'Ember uses your own $plan subscription, logged in on the PC where the Runner runs (no API key, no extra cost).\n\n1. On that PC open a terminal (or Ember\'s terminal).\n2. Run: $command\n3. Complete the login in the browser with your account.\n\nCome back here: the engine turns on within a minute.';
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
      'Before activating, once per account/app:\n1. Play Console → Setup → Payments profile (bank account, tax info)\n2. Upload this app\'s AAB to internal testing (Google requires a version with billing)\n3. Users and permissions → give the service account \"Manage orders and subscriptions\"';

  @override
  String get productsOpenPayments => 'Payments profile';

  @override
  String get productsUploadFirst => 'Upload AAB';

  @override
  String get productsActive => 'Active on Google Play ✓';

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
      'Now I connect Ember to Google Play, so I can upload your apps. **I do it myself**: I create a special key in your Google account on this PC (Google Cloud project, Play API and key). It is used only to upload apps and stays on your device.';

  @override
  String get pubDoItEmber => 'Do it for me, Ember';

  @override
  String get pubManual => 'I prefer to do it by hand';

  @override
  String get pubKeyWorking =>
      'Creating the Google Cloud project, enabling the Play API and creating the key (about 1-2 minutes)…';

  @override
  String get pubInvite =>
      'Key created ✓\n\nLast connection: the key must be allowed to publish in **your** Play Console.\n1. Press **Open Play Console** below\n2. Copy the address of the page you see (any page) and **paste it here in the chat**\n\nThen the PC browser opens once: sign in with the same Google account and press **Allow**. I send the invitation myself.';

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
      'Connected to Google Play ✓\n\nFor the store page Google wants the **512×512 icon**, the **1024×500 banner** and at least **2 screenshots**. If you haven\'t done them yet, go back to the app screen: in **App logo** and **Play Store screenshots** Ember makes them in one tap. I upload them automatically together with the app.';

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
      'Great, the app is on Google Play ✓\n\nGoogle still asks you to confirm a few forms by hand in Play Console (**Data safety**, **Content rating**, **Target audience**, **Ads**, **App access**): the ready answers are in the last screen. New personal accounts must also run a **closed test with 12 testers for 14 days** before going public.\n\nAny doubt? Ask me here below.';

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
      'In AdMob (5 minutes, once per app):\n1. Apps → Add app → Android → \"Is the app on Google Play?\" (No if not published yet) → name → Add\n2. Copy the App ID (ca-app-pub-…~…)\n3. Ad units → Add ad unit → choose each format below → Create → copy its ID (ca-app-pub-…/…)\n4. After publishing, link the app to its Play Store listing in AdMob and add app-ads.txt if AdMob asks';

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
  String get upBuilding => 'Building the new signed AAB…';

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
    return 'Saved ✓ developer account $id: the buttons now open your console directly.';
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
      'Data safety sent to Google Play ✓ — check it in Play Console → App content → Data safety and press Submit.';

  @override
  String get dsNeedsCsv =>
      'First export the form from Play Console: App content → Data safety → Export to CSV. Save it in Downloads, then press this button again.';

  @override
  String get driveBackup => 'Save to Google Drive';

  @override
  String get driveSaving =>
      'Asking Google for permission and saving the key on your Drive…';

  @override
  String get driveSaved => 'Keystore and password saved on your Google Drive ✓';

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
    return 'Repository $repo created and app uploaded ✓';
  }

  @override
  String ghUpdated(String repo) {
    return 'App uploaded to $repo ✓';
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
}
