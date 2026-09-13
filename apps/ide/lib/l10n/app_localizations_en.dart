// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FlutterCursor';

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
  String get projects => 'Projects';

  @override
  String get noProjects => 'No projects yet. Create one to get started.';

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
      'E.g.: a recipe app with photos, shopping list and cooking timer, warm colors…';

  @override
  String get chooseAi => 'Which AI?';

  @override
  String get createApp => 'Create app';

  @override
  String get openEditor => 'Editor';

  @override
  String get describeYourApp => 'Describe your app';

  @override
  String get describeYourAppHint =>
      'Say what it should do and look like: the AI builds the complete app, checks errors and shows it to you. (*Gemini: Google\'s free tier with daily limits)';

  @override
  String get improveApp => 'Want to change something?';

  @override
  String get improveAppHint => 'E.g.: add dark mode, make photos bigger…';

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
  String get bestQuality => 'Best quality';

  @override
  String get bestQualityOn => 'Most capable model: slower, for complex apps';

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
}
