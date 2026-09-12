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
}
