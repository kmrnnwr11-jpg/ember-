// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'FlutterCursor';

  @override
  String get loginTitle => 'Accedi';

  @override
  String get loginSubtitle =>
      'Crea app Flutter da qualsiasi dispositivo, con l\'AI.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get runnerUrl => 'URL Runner';

  @override
  String get signIn => 'Accedi';

  @override
  String get signUp => 'Registrati';

  @override
  String get devLoginHint =>
      'Modalità sviluppo: Supabase non configurato, accesso solo con email tramite il Runner.';

  @override
  String get invalidEmail => 'Email non valida';

  @override
  String get passwordTooShort => 'Almeno 6 caratteri';

  @override
  String get signOut => 'Esci';

  @override
  String get projects => 'Progetti';

  @override
  String get noProjects => 'Nessun progetto. Creane uno per iniziare.';

  @override
  String get newProject => 'Nuovo progetto';

  @override
  String get projectName => 'Nome progetto';

  @override
  String get projectNameHelp => 'minuscolo, lettere/numeri/_ (es. my_app)';

  @override
  String get create => 'Crea';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get rename => 'Rinomina';

  @override
  String get retry => 'Riprova';

  @override
  String get statusCreating => 'In creazione…';

  @override
  String get statusReady => 'Pronto';

  @override
  String get statusError => 'Errore';

  @override
  String creatingProject(String name) {
    return 'Creazione di $name';
  }

  @override
  String get files => 'File';

  @override
  String get editor => 'Editor';

  @override
  String get newFile => 'Nuovo file';

  @override
  String get newFolder => 'Nuova cartella';

  @override
  String get fileName => 'Nome';

  @override
  String deleteConfirm(String path) {
    return 'Eliminare $path?';
  }

  @override
  String get save => 'Salva';

  @override
  String get saved => 'Salvato';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String get discard => 'Scarta';

  @override
  String get noFileOpen => 'Apri un file dall\'albero a sinistra.';

  @override
  String get conflictTitle => 'File modificato altrove';

  @override
  String conflictBody(String path) {
    return '$path è cambiato sul Runner dopo che l\'hai aperto.';
  }

  @override
  String get reload => 'Ricarica';

  @override
  String get overwrite => 'Sovrascrivi';

  @override
  String get connected => 'Connesso';

  @override
  String get connecting => 'Connessione…';

  @override
  String get disconnected => 'Disconnesso';

  @override
  String error(String message) {
    return 'Errore: $message';
  }

  @override
  String get binaryFile =>
      'File binario o troppo grande: non modificabile nell\'editor.';

  @override
  String get terminal => 'Terminale';

  @override
  String get newTerminal => 'Nuovo terminale';

  @override
  String get toggleTerminal => 'Mostra/nascondi terminale';

  @override
  String get restart => 'Riavvia';

  @override
  String get preview => 'Anteprima';

  @override
  String get togglePreview => 'Mostra/nascondi anteprima';

  @override
  String get runWeb => 'Avvia Web';

  @override
  String get building => 'Compilazione…';

  @override
  String get buildFailed => 'Compilazione fallita: controlla il log qui sotto.';

  @override
  String get reloadPreview => 'Ricarica anteprima';

  @override
  String get device => 'Dispositivo';

  @override
  String get openInBrowser => 'Apri nel browser';

  @override
  String get openOnOtherDevice => 'Apri su un altro dispositivo';

  @override
  String get qrLocalhostWarning =>
      'Questo indirizzo funziona solo su questo computer. Usa l\'IP di rete del Runner (es. http://192.168.1.20:8787) per aprirlo dal telefono.';

  @override
  String get copy => 'Copia';

  @override
  String get close => 'Chiudi';

  @override
  String get console => 'Console';

  @override
  String get autoRebuild => 'Ricompila al salvataggio';

  @override
  String get previewEmpty =>
      'Premi «Avvia Web» per compilare l\'app e vederla qui. Ogni salvataggio aggiorna l\'anteprima.';
}
