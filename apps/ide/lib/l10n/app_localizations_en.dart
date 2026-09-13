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
}
