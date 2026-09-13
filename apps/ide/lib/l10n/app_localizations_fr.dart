// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Ember – App Maker';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginSubtitle =>
      'Créez des apps Flutter depuis n\'importe quel appareil, avec l\'IA.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get runnerUrl => 'URL du Runner';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get devLoginHint =>
      'Mode développement : Supabase non configuré, connexion par e-mail uniquement via le Runner.';

  @override
  String get invalidEmail => 'E-mail invalide';

  @override
  String get passwordTooShort => 'Au moins 6 caractères';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get projects => 'Vos apps';

  @override
  String get noProjects => 'Aucune app invoquée. Décrivez-en une ci-dessus.';

  @override
  String get newProject => 'Nouveau projet';

  @override
  String get projectName => 'Nom du projet';

  @override
  String get projectNameHelp => 'minuscules, lettres/chiffres/_ (ex. my_app)';

  @override
  String get create => 'Créer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get rename => 'Renommer';

  @override
  String get retry => 'Réessayer';

  @override
  String get statusCreating => 'Création…';

  @override
  String get statusReady => 'Prêt';

  @override
  String get statusError => 'Erreur';

  @override
  String creatingProject(String name) {
    return 'Création de $name';
  }

  @override
  String get files => 'Fichiers';

  @override
  String get editor => 'Éditeur';

  @override
  String get newFile => 'Nouveau fichier';

  @override
  String get newFolder => 'Nouveau dossier';

  @override
  String get fileName => 'Nom';

  @override
  String deleteConfirm(String path) {
    return 'Supprimer $path ?';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get saved => 'Enregistré';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get discard => 'Ignorer';

  @override
  String get noFileOpen => 'Ouvrez un fichier depuis l\'arborescence.';

  @override
  String get conflictTitle => 'Fichier modifié ailleurs';

  @override
  String conflictBody(String path) {
    return '$path a changé sur le Runner après son ouverture.';
  }

  @override
  String get reload => 'Recharger';

  @override
  String get overwrite => 'Écraser';

  @override
  String get connected => 'Connecté';

  @override
  String get connecting => 'Connexion…';

  @override
  String get disconnected => 'Déconnecté';

  @override
  String error(String message) {
    return 'Erreur : $message';
  }

  @override
  String get binaryFile =>
      'Fichier binaire ou trop volumineux : modification impossible.';

  @override
  String get terminal => 'Terminal';

  @override
  String get newTerminal => 'Nouveau terminal';

  @override
  String get toggleTerminal => 'Afficher/masquer le terminal';

  @override
  String get restart => 'Redémarrer';

  @override
  String get preview => 'Aperçu';

  @override
  String get togglePreview => 'Afficher/masquer l\'aperçu';

  @override
  String get runWeb => 'Lancer Web';

  @override
  String get building => 'Compilation…';

  @override
  String get buildFailed =>
      'La compilation a échoué : consultez le journal ci-dessous.';

  @override
  String get reloadPreview => 'Recharger l\'aperçu';

  @override
  String get device => 'Appareil';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get openOnOtherDevice => 'Ouvrir sur un autre appareil';

  @override
  String get qrLocalhostWarning =>
      'Cette adresse ne fonctionne que sur cet ordinateur. Utilisez l\'IP réseau du Runner (ex. http://192.168.1.20:8787) pour l\'ouvrir depuis un téléphone.';

  @override
  String get copy => 'Copier';

  @override
  String get close => 'Fermer';

  @override
  String get console => 'Console';

  @override
  String get autoRebuild => 'Recompiler à l\'enregistrement';

  @override
  String get previewEmpty =>
      'Appuyez sur « Lancer Web » pour compiler l\'app et la voir ici. Chaque enregistrement met à jour l\'aperçu.';

  @override
  String get ai => 'IA';

  @override
  String get toggleAi => 'Afficher/masquer le panneau IA';

  @override
  String get aiSettings => 'Clés API et modèles';

  @override
  String get apiKeysHint =>
      'Les clés restent chiffrées sur cet appareil (stockage sécurisé). Avec le proxy activé, elles transitent par votre Runner uniquement pour chaque requête et ne sont jamais enregistrées ni journalisées.';

  @override
  String get useRunnerProxy => 'Passer par le Runner (proxy)';

  @override
  String get useRunnerProxyHint =>
      'Recommandé. Désactivez pour appeler les fournisseurs directement depuis cet appareil.';

  @override
  String get useRunnerProxyWeb =>
      'Obligatoire sur le web : les navigateurs ne peuvent pas appeler les fournisseurs directement.';

  @override
  String get apiKey => 'Clé API';

  @override
  String get apiKeyOptional => 'Clé API (si nécessaire)';

  @override
  String get replaceApiKey => 'Remplacer la clé';

  @override
  String get testKey => 'Tester';

  @override
  String get testing => 'Test en cours…';

  @override
  String keyWorks(String model) {
    return 'Fonctionne ✓ ($model)';
  }

  @override
  String get getKey => 'Obtenir une clé';

  @override
  String get addModelId => 'Ajouter un ID de modèle';

  @override
  String get selectModel => 'Choisir un modèle';

  @override
  String get keyPresent => 'clé présente';

  @override
  String get notConfigured => 'non configuré';

  @override
  String get per1k => 'pour 1k jetons (entrée/sortie)';

  @override
  String applyTo(String path) {
    return 'Appliquer à $path';
  }

  @override
  String get noChanges => 'Aucune différence avec le fichier actuel.';

  @override
  String get accept => 'Accepter';

  @override
  String get reject => 'Refuser';

  @override
  String get apply => 'Appliquer';

  @override
  String applied(String path) {
    return 'Modification appliquée à $path : vérifiez et enregistrez.';
  }

  @override
  String get applyNoTarget =>
      'Ouvrez un fichier ou demandez à l\'IA d\'indiquer le chemin du fichier.';

  @override
  String get clearChat => 'Vider la conversation';

  @override
  String get chatEmpty =>
      'Posez une question sur votre projet. Le fichier ouvert est envoyé comme contexte.';

  @override
  String get chatNoKeys =>
      'Ajoutez au moins une clé API (Claude, ChatGPT ou Gemini) pour utiliser l\'IA.';

  @override
  String get attachOpenFile => 'Joindre le fichier ouvert comme contexte';

  @override
  String get askAi => 'Demandez à l\'IA…  (Ctrl+Entrée pour envoyer)';

  @override
  String get send => 'Envoyer';

  @override
  String get stop => 'Arrêter';

  @override
  String get copied => 'Copié';

  @override
  String get truncated => 'réponse tronquée (limite de jetons)';

  @override
  String get refused => 'refusée par le modèle';

  @override
  String get stopped => 'interrompue';

  @override
  String get badgeFreeTier => 'gratuit*';

  @override
  String get badgeSubscription => 'abonnement';

  @override
  String get badgePaid => 'payant';

  @override
  String needsKey(String name) {
    return 'Nécessite une clé API $name : ajoutez-la dans les paramètres.';
  }

  @override
  String get claudeCodeUnavailable =>
      'Claude Code n\'est pas disponible sur ce Runner (il doit être installé et connecté sur le PC du Runner).';

  @override
  String get appPromptHint =>
      'Ex. : une app de recettes avec photos, liste de courses et minuteur…';

  @override
  String get chooseAi => 'Choisissez le moteur';

  @override
  String get createApp => 'Invoquer l\'app';

  @override
  String get openEditor => 'Éditeur';

  @override
  String get describeYourApp => 'Invoquez votre app';

  @override
  String get describeYourAppHint =>
      'Décrivez ce qu\'elle doit faire et à quoi elle doit ressembler. Ember l\'écrit, la vérifie et vous la montre. (*Gemini : quota gratuit de Google avec limites quotidiennes)';

  @override
  String get improveApp => 'Que voulez-vous ajouter ou améliorer ?';

  @override
  String get improveAppHint =>
      'Décrivez les prochaines fonctions ou modifications, ex. : ajoute les appels vidéo, la connexion Google, les salons privés… Vous pouvez aussi coller ici les clés demandées par l\'IA.';

  @override
  String get applyChange => 'Appliquer la modification';

  @override
  String get buildLog => 'Détails';

  @override
  String get stepClaudeCode => 'Claude Code écrit et vérifie le code';

  @override
  String stepWriting(int count) {
    return 'Écriture du code ($count fichiers)';
  }

  @override
  String get stepDependencies => 'Installation des dépendances';

  @override
  String get stepChecking => 'Vérification des erreurs';

  @override
  String stepFixing(int round) {
    return 'Correction des erreurs (tentative $round)';
  }

  @override
  String get stepBuilding => 'Compilation de l\'app';

  @override
  String get stepReady => 'Prête';

  @override
  String get appReadyTitle => 'Votre app est prête 🎉';

  @override
  String get openApp => 'Ouvrir l\'app';

  @override
  String get viewCode => 'Voir le code';

  @override
  String get buildCancelled => 'Création interrompue';

  @override
  String get buildFailedTitle => 'Je n\'ai pas pu terminer l\'app';

  @override
  String get bestQuality => 'Puissance maximale';

  @override
  String get bestQualityOn =>
      'Le moteur le plus puissant : plus lent, pour les apps complexes';

  @override
  String get bestQualityOff =>
      'Rapide (recommandé) : idéal pour la plupart des apps';

  @override
  String get androidFileQuestion => 'Voulez-vous le fichier Android ?';

  @override
  String get androidFileHint =>
      'APK : à installer sur le téléphone. AAB : à envoyer sur Google Play Console. Tous deux signés.';

  @override
  String get generateApk => 'Générer l\'APK';

  @override
  String get generateAab => 'Générer l\'AAB';

  @override
  String androidBuilding(String kind) {
    return 'Génération de $kind… la première fois peut prendre 3 à 5 minutes.';
  }

  @override
  String get downloadApk => 'Télécharger et installer l\'APK';

  @override
  String get downloadAab => 'Télécharger l\'AAB';

  @override
  String get apkInstallHint =>
      'APK signé. Si Android le demande, autorisez l\'installation depuis cette source.';

  @override
  String get aabHint =>
      'AAB signé avec la clé d\'importation de cette app : prêt pour Google Play Console. Le numéro de version augmente à chaque compilation.';

  @override
  String get androidFailed => 'La génération a échoué :';

  @override
  String get backupSigningKey => 'Sauvegarder la clé de signature';

  @override
  String get backupSigningKeyHint =>
      'Conservez le fichier de clé et le mot de passe en lieu sûr (ex. Google Drive) : ils sont nécessaires pour publier les mises à jour de cette app sur Google Play. Le lien fonctionne une seule fois pendant 10 minutes.';

  @override
  String get downloadKeystore => 'Télécharger le fichier de clé';

  @override
  String get fullscreenExitHint =>
      'Balayez ou appuyez sur retour pour revenir à Ember';

  @override
  String get runFullscreen => 'Lancer en plein écran';

  @override
  String cliNotInstalled(String name) {
    return 'non installé sur le Runner ($name)';
  }

  @override
  String get terminalCliHint =>
      'Claude Code, Codex et Gemini utilisent la connexion du PC du Runner. La première fois, suivez les instructions dans le terminal pour vous connecter.';

  @override
  String get generatingMockups => 'Création de 5 styles visuels…';

  @override
  String designingStyle(String style) {
    return 'Conception du style « $style »…';
  }

  @override
  String get chooseMockup => 'Choisir celui-ci';

  @override
  String get editMockup => 'Modifier cette maquette';

  @override
  String get editMockupHint =>
      'Ex. : plus sombre, boutons arrondis, logo rose…';

  @override
  String get newMockups => 'Nouvelles maquettes (5 styles différents)';

  @override
  String get previousMockups => 'Maquettes précédentes';

  @override
  String mockupSet(int n) {
    return 'Série $n';
  }

  @override
  String get skipMockups => 'Passer les maquettes et créer l\'app';

  @override
  String get playAskUpload =>
      'Voulez-vous publier l\'app sur Google Play Store ?';

  @override
  String get playYesUpload => 'Oui, publier sur le Play Store';

  @override
  String get playNotNow => 'Pas maintenant';

  @override
  String get playFeeNotice =>
      'Vous avez besoin d\'un compte développeur Google Play Console. Coût : 25 \$ une seule fois (ce n\'est pas un abonnement), payés directement à Google, pas à Ember.';

  @override
  String get playPublishTitle => 'Publier sur Google Play';

  @override
  String get playStepAccount => 'Compte Google Play Console';

  @override
  String get playOpenSignup => 'Créer un compte Play Console';

  @override
  String get playHaveAccount => 'J\'ai déjà un compte Play Console actif';

  @override
  String get next => 'Suivant';

  @override
  String get playStepCreateApp => 'Créez l\'app dans Play Console';

  @override
  String get playCreateAppGuide =>
      'Google exige cette étape manuellement, uniquement la première fois :\n1. Ouvrez **Play Console** → **Créer une application**\n2. Nom de l\'app, langue par défaut, type **Application**, **Gratuite**\n3. Acceptez les déclarations et appuyez sur **Créer l\'application**\n\nLe nom du package est associé lors du premier envoi : utilisez celui ci-dessous.';

  @override
  String get playPackageName => 'Nom du package';

  @override
  String get playOpenConsole => 'Ouvrir Play Console';

  @override
  String get playAppCreated => 'J\'ai créé l\'app dans Play Console';

  @override
  String get playStepConnect => 'Connectez Ember à Google Play';

  @override
  String get playConnectGuide =>
      'Vous avez besoin d\'une **clé de compte de service** (une seule fois pour toutes vos apps) :\n1. Ouvrez **Google Cloud** et activez **Google Play Android Developer API**\n2. **Comptes de service** → **Créer** → **Clés** → **Ajouter une clé** → **JSON** (un fichier est téléchargé)\n3. Dans **Play Console** → **Utilisateurs et autorisations** → **Inviter de nouveaux utilisateurs** → collez l\'e-mail du compte de service → accordez les autorisations de **publication**\n4. Ouvrez le JSON téléchargé et **collez ici tout son contenu**\n\nLa clé reste chiffrée sur cet appareil et n\'est utilisée que pour les envois.';

  @override
  String get playOpenApiLibrary => 'Activer l\'API Google Play';

  @override
  String get playOpenServiceAccounts => 'Comptes de service';

  @override
  String get playServiceAccountJson => 'Contenu JSON du compte de service';

  @override
  String get playStepListing => 'Fiche Play Store et envoi';

  @override
  String get playGenerateWithAi =>
      'Générer la fiche, la politique de confidentialité et les réponses avec l\'IA';

  @override
  String get playTitle => 'Titre (max. 30)';

  @override
  String get playShortDescription => 'Description courte (max. 80)';

  @override
  String get playFullDescription => 'Description complète';

  @override
  String get playReleaseNotes => 'Notes de version';

  @override
  String get playContactEmail =>
      'E-mail de contact (obligatoire sur le Play Store)';

  @override
  String get playPrivacyUrl => 'Lien de la politique de confidentialité';

  @override
  String get playTrack => 'Où publier';

  @override
  String get playTrackInternal => 'Tests internes (recommandé pour commencer)';

  @override
  String get playTrackClosed => 'Tests fermés';

  @override
  String get playTrackProduction => 'Production (public)';

  @override
  String get playUpload => 'Envoyer sur Google Play';

  @override
  String get playStepFinish => 'Finalisez dans Play Console';

  @override
  String playUploaded(String version, String track, String draft) {
    return '✅ Envoyée ! Version $version sur le canal « $track ». $draft';
  }

  @override
  String get playDraftNote =>
      'Comme l\'app n\'a jamais été publiée, Google l\'a enregistrée comme brouillon : terminez les étapes ci-dessous et appuyez sur « Envoyer pour examen » dans Play Console.';

  @override
  String playManualChecklist(String privacyUrl) {
    return 'Google exige de confirmer manuellement ces éléments dans Play Console (réponses prêtes ci-dessous) :\n- **Politique de confidentialité** → collez le lien : $privacyUrl\n- **Sécurité des données**\n- Questionnaire de **classification du contenu**\n- **Public cible et contenu**\n- **Annonces** et **Accès à l\'application** (fournissez un compte de test si une connexion est requise)\n- **Fiche Play Store** : icône 512×512 et au moins 2 captures d\'écran\n- Nouveaux comptes personnels : Google peut exiger des **tests fermés** avec un nombre minimal de testeurs avant la production';
  }

  @override
  String get playDataSafety => 'Réponses pour « Sécurité des données »';

  @override
  String get playContentRating => 'Réponses pour « Classification du contenu »';

  @override
  String get playOtherDeclarations => 'Public, annonces et accès à l\'app';

  @override
  String get assistantTitle => 'Demandez à Ember';

  @override
  String get assistantFree => 'Gratuit';

  @override
  String get assistantEmpty =>
      'Bonjour, je suis Ember ! Posez-moi n\'importe quelle question : idées d\'app, publication sur le Play Store, configuration de la connexion et des bases de données…';

  @override
  String get assistantUnconfigured =>
      'L\'assistant gratuit n\'est pas encore actif sur ce serveur (la clé Gemini du Runner est manquante).';

  @override
  String get assistantHint => 'Demandez n\'importe quoi à Ember…';

  @override
  String get assistantSuggest1 => 'Quelle app puis-je créer pour mon magasin ?';

  @override
  String get assistantSuggest2 => 'Comment publier une app sur le Play Store ?';

  @override
  String get assistantSuggest3 =>
      'Comment fonctionne la connexion avec Google ?';

  @override
  String get language => 'Langue';

  @override
  String get find => 'Rechercher';

  @override
  String get replace => 'Remplacer';

  @override
  String get replaceAll => 'Tout';

  @override
  String get baseUrl => 'URL de base';

  @override
  String fontLabel(String font) {
    return 'Police : $font';
  }

  @override
  String get styleMinimal => 'Minimal clair';

  @override
  String get styleDark => 'Sombre premium';

  @override
  String get stylePlayful => 'Coloré et ludique';

  @override
  String get styleGlass => 'Glassmorphism';

  @override
  String get styleMaterial => 'Material 3';

  @override
  String get styleNeumorph => 'Neumorphisme';

  @override
  String get styleLuxury => 'Luxe élégant';

  @override
  String get styleBrutal => 'Brutaliste audacieux';

  @override
  String get stylePastel => 'Pastel doux';

  @override
  String get styleTech => 'Tech futuriste';

  @override
  String get styleNature => 'Nature';

  @override
  String get styleIos => 'Style iOS';

  @override
  String get styleRetro => 'Rétro années 80';

  @override
  String get styleMono => 'Monochrome';

  @override
  String get styleCorporate => 'Professionnel';

  @override
  String bWriting(String model) {
    return 'Écriture du code avec $model…';
  }

  @override
  String bApplying(String change, String model) {
    return 'Application de la modification avec $model : $change';
  }

  @override
  String get bNoModel => 'Aucun modèle sélectionné';

  @override
  String get bNoFiles =>
      'L\'IA n\'a produit aucun fichier : réessayez ou changez de modèle.';

  @override
  String bErrorsRemain(int count, String problems) {
    return 'Des erreurs subsistent après $count tentatives de correction :\n$problems';
  }

  @override
  String bFixing(int max, int round) {
    return 'Correction des erreurs (tentative $round sur $max)…';
  }

  @override
  String bNoFixes(String problems) {
    return 'L\'IA n\'a proposé aucune correction pour :\n$problems';
  }

  @override
  String bIncompleteFile(String path) {
    return 'Fichier incomplet ignoré : $path';
  }

  @override
  String bPathNotAllowed(String path) {
    return 'Chemin non autorisé, ignoré : $path';
  }

  @override
  String get bTruncated =>
      'Réponse coupée par la limite de jetons : les fichiers incomplets seront recréés lors de la correction.';

  @override
  String get bRefused => 'Le modèle a refusé la demande.';

  @override
  String get bPubGet => 'Installation des dépendances (flutter pub get)…';

  @override
  String get bPubGetFailed => 'flutter pub get a échoué';

  @override
  String get bAnalyze => 'Vérification des erreurs (flutter analyze)…';

  @override
  String get bNoErrors => 'Aucune erreur ✓';

  @override
  String bErrorsFound(int count) {
    return '$count erreurs trouvées';
  }

  @override
  String get bClaudeApplying => 'Claude Code applique la modification…';

  @override
  String get bClaudeBuilding => 'Claude Code crée l\'application sur le PC…';

  @override
  String get bClaudeFailed =>
      'Claude Code n\'a pas terminé l\'application : consultez le journal.';

  @override
  String get bWebBuilding =>
      'Compilation de l\'application pour le web (environ 30 secondes)…';

  @override
  String bWebFailed(String log) {
    return 'La compilation web a échoué :\n$log';
  }

  @override
  String get bApk =>
      'Génération de l\'APK (la première fois peut prendre quelques minutes)…';

  @override
  String get bAab => 'Génération de l\'AAB pour le Play Store…';

  @override
  String bAndroidFailed(String kind) {
    return 'Échec de la génération de $kind';
  }

  @override
  String bAndroidReady(String kind) {
    return '$kind prêt ✓';
  }

  @override
  String get bStopped => 'Arrêté';

  @override
  String get bAppReady => 'Application prête ✓';

  @override
  String get bAppUpdated => 'Application mise à jour ✓';

  @override
  String actWrites(String file) {
    return 'Écriture de $file';
  }

  @override
  String actEdits(String file) {
    return 'Modification de $file';
  }

  @override
  String actReads(String file) {
    return 'Lecture de $file';
  }

  @override
  String get actPubGet => 'Installation des dépendances';

  @override
  String get actAnalyze => 'Vérification des erreurs';

  @override
  String get forgeTitle => 'Forge de votre app';

  @override
  String forgeFiles(int count) {
    return '$count fichiers forgés';
  }
}
