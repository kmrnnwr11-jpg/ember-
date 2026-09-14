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
  String get bClaudeFailed =>
      'Claude Code did not finish the app: check the log.';

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
}
