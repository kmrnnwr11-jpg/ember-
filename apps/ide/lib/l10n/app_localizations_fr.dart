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
      'Crée des apps depuis n\'importe quel appareil, avec l\'IA.';

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
      'Mode développement : Supabase n\'est pas configuré, tu te connectes donc par e-mail uniquement, via l\'ordinateur où tourne Ember.';

  @override
  String get invalidEmail => 'E-mail invalide';

  @override
  String get passwordTooShort => 'Au moins 6 caractères';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get projects => 'Vos apps';

  @override
  String get noProjects => 'Pas encore d\'app. Décris-en une ci-dessus.';

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
    return '$path a changé sur l\'ordinateur où tourne Ember après que tu l\'as ouvert.';
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
      'Cette adresse ne fonctionne que sur cet ordinateur. Pour l\'ouvrir depuis un téléphone, utilise l\'adresse réseau de l\'ordinateur où tourne Ember (ex. http://192.168.1.20:8787).';

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
  String get aiSettings => 'Ajouter une clé';

  @override
  String get apiKeysHint =>
      'Les clés restent chiffrées sur cet appareil. Quand les demandes passent par l\'ordinateur où tourne Ember, les clés n\'y transitent que pour cette demande et ne sont jamais enregistrées.';

  @override
  String get useRunnerProxy => 'Passer par l\'ordinateur où tourne Ember';

  @override
  String get useRunnerProxyHint =>
      'Recommandé. Désactive-le pour contacter les services d\'IA directement depuis cet appareil.';

  @override
  String get useRunnerProxyWeb =>
      'Toujours actif dans le navigateur : une page web ne peut pas contacter directement les services d\'IA.';

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
    return 'Fonctionne ($model)';
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
      'Claude Code n\'est pas disponible : il doit être installé et connecté sur l\'ordinateur où tourne Ember.';

  @override
  String get appPromptHint =>
      'Ex. : une app de recettes avec photos, liste de courses et minuteur…';

  @override
  String get chooseAi => 'Qui écrit le code';

  @override
  String get createApp => 'Créer l\'app';

  @override
  String get openEditor => 'Éditeur';

  @override
  String get describeYourApp => 'Quelle app veux-tu créer ?';

  @override
  String get describeYourAppHint =>
      'Écris ce qu\'elle doit faire et comment tu l\'imagines. Ember la construit, la vérifie et te la montre.';

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
  String get appReadyTitle => 'Ton app est prête';

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
  String get androidFileQuestion => 'Veux-tu le fichier pour Android ?';

  @override
  String get androidFileHint =>
      'Fichier à installer (APK) : il va sur le téléphone. Fichier pour Google Play (AAB) : il va sur Google Play Console. Les deux sont signés.';

  @override
  String get generateApk => 'Créer le fichier à installer (APK)';

  @override
  String get generateAab => 'Créer le fichier pour Google Play (AAB)';

  @override
  String androidBuilding(String kind) {
    return 'Création du fichier $kind… la première fois peut prendre 3 à 5 minutes.';
  }

  @override
  String get downloadApk => 'Télécharger et installer le fichier (APK)';

  @override
  String get downloadAab => 'Télécharger le fichier pour Google Play (AAB)';

  @override
  String get apkInstallHint =>
      'Le fichier à installer (APK) est signé. Si Android le demande, autorise l\'installation depuis cette source.';

  @override
  String get aabHint =>
      'Le fichier pour Google Play (AAB) est signé avec la clé d\'importation de cette app et prêt pour Google Play Console. Le numéro de version augmente tout seul à chaque fois.';

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
    return 'non installé sur l\'ordinateur où tourne Ember ($name)';
  }

  @override
  String get terminalCliHint =>
      'Claude Code, Codex et Gemini utilisent la connexion faite sur l\'ordinateur où tourne Ember. La première fois, suis les instructions du terminal pour te connecter.';

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
      '1. Ouvre **Google Cloud** : tu crées une **clé de compte de service**, une seule fois pour toutes tes apps.\n2. Active **Google Play Android Developer API**.\n3. Va dans **Comptes de service** et appuie sur **Créer**.\n4. Ouvre **Clés** → **Ajouter une clé** → **JSON**. Un fichier se télécharge.\n5. Dans **Play Console**, va dans **Utilisateurs et autorisations** → **Inviter de nouveaux utilisateurs**.\n6. Colle l\'e-mail du compte de service et accorde les autorisations de **publication**.\n7. Ouvre le fichier JSON téléchargé et **colle ici tout son contenu**.\n8. C\'est fait : la clé reste chiffrée sur cet appareil et ne sert qu\'aux envois.';

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
    return 'Envoyée. Version $version sur le canal « $track ». $draft';
  }

  @override
  String get playDraftNote =>
      'Comme l\'app n\'a jamais été publiée, Google l\'a enregistrée comme brouillon : terminez les étapes ci-dessous et appuyez sur « Envoyer pour examen » dans Play Console.';

  @override
  String get playReviewNotSent =>
      'Google n’a pas pu envoyer les modifications en revision automatiquement. Elles sont enregistrees : ouvrez Play Console et appuyez sur \"Envoyer pour examen\" pour publier.';

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
      'L\'assistant gratuit n\'est pas encore actif : la clé Gemini manque sur l\'ordinateur où tourne Ember.';

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
  String get bNoErrors => 'Aucune erreur';

  @override
  String bErrorsFound(int count) {
    return '$count erreurs trouvées';
  }

  @override
  String get bClaudeApplying => 'Claude Code applique la modification…';

  @override
  String get bClaudeBuilding => 'Claude Code crée l\'application sur le PC…';

  @override
  String statusBuilding(String progress) {
    return 'Création… $progress fichiers';
  }

  @override
  String get bClaudeFailed =>
      'Claude Code n\'a pas terminé l\'application : consultez le journal.';

  @override
  String resumeFromHere(int count) {
    return 'Reprendre ici ($count fichiers)';
  }

  @override
  String get startOver => 'Recommencer';

  @override
  String bClaudeStoppedCarryOn(int count) {
    return 'Il s\'est arrêté avec $count fichiers déjà écrits : je continue et je corrige ce qui manque.';
  }

  @override
  String get bWebBuilding =>
      'Compilation de l\'application pour le web (environ 30 secondes)…';

  @override
  String bWebFailed(String log) {
    return 'La compilation web a échoué :\n$log';
  }

  @override
  String get bApk =>
      'Je crée le fichier à installer (APK). La première fois peut prendre quelques minutes…';

  @override
  String get bAab => 'Je crée le fichier pour Google Play (AAB)…';

  @override
  String get chooseDesignAi => 'Qui dessine (logo, maquettes, écrans)';

  @override
  String get chooseDesignAiHint =>
      'Choisissez qui dessine : chacun fait 2 maquettes, et les 5 logos tournent entre eux. Le moteur ci-dessus écrit le code.';

  @override
  String get bLookingAtModel => 'Je regarde l\'app à copier…';

  @override
  String get bIpa => 'Je crée l\'app pour iPhone (IPA)…';

  @override
  String get nameTitle => 'Comment s\'appelle ton app ?';

  @override
  String get nameHint =>
      'Ce nom va sur le Play Store, dans la politique de confidentialité et dans le nom du paquet, qui ne peut plus changer ensuite.';

  @override
  String get nameYourOwn => 'Ou écris ton propre nom';

  @override
  String get nameMore => 'D\'autres noms';

  @override
  String get nameUse => 'Utiliser ce nom';

  @override
  String bReferenceShots(int count) {
    return '$count écrans de l\'app à copier enregistrés : le moteur la voit, il ne fait pas que la lire';
  }

  @override
  String get bReferenceShotsFailed =>
      'Je n\'ai pas pu récupérer les écrans de l\'app à copier : je continue avec la description seule';

  @override
  String bMissingTopics(String topics) {
    return 'Il manque par rapport à l\'app à copier : $topics. Je l\'ajoute maintenant…';
  }

  @override
  String get bIosReady => 'App iPhone prête';

  @override
  String get bIosFailed => 'La création de l\'app iPhone a échoué';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iPhone';

  @override
  String get iosTitle => 'App pour iPhone';

  @override
  String get iosHint =>
      'La même app pour iPhone et iPad : même nom, mêmes écrans, mêmes annonces. Le fichier (IPA) va sur App Store Connect.';

  @override
  String get iosNeedsMac =>
      'L\'app pour iPhone ne peut être créée que sur un Mac. Enregistre l\'app sur GitHub, ouvre Ember sur le Mac et crée-la là-bas. Tout le reste se fait d\'ici.';

  @override
  String get iosBuild => 'Créer l\'app iPhone';

  @override
  String get iosBuilding => 'Je crée l\'app pour iPhone…';

  @override
  String get iosReady =>
      'App iPhone prête. Elle est signée avec ton compte Apple et peut aller sur App Store Connect.';

  @override
  String get iosAppleAccount =>
      'Compte Apple Developer : 99 dollars par an, payés à Apple.';

  @override
  String get ascTitle => 'Envoyer sur l\'App Store';

  @override
  String get ascHint =>
      'Ember écrit chez Apple ce qu\'il écrit chez Google : titre, description, nouveautés, lien de confidentialité et réponses sur la confidentialité, dans toutes les langues de ta fiche.';

  @override
  String get ascKeyHelp =>
      '1. Ouvre App Store Connect et va dans Utilisateurs et accès → Intégrations → App Store Connect API.\n2. Appuie sur + et choisis le rôle App Manager.\n3. Télécharge le fichier .p8. Apple ne permet de le télécharger qu\'une seule fois.';

  @override
  String get ascKeyId => 'Key ID';

  @override
  String get ascIssuerId => 'Issuer ID';

  @override
  String get ascPrivateKey => 'Contenu du fichier AuthKey_….p8';

  @override
  String get ascUploadBuild =>
      'Envoyer aussi le fichier iPhone (il faut un Mac)';

  @override
  String get ascSubmit =>
      'Envoyer à la validation d\'Apple quand tout est prêt';

  @override
  String get ascPublish => 'Publier sur l\'App Store';

  @override
  String get ascWorking => 'Je parle avec App Store Connect…';

  @override
  String ascDone(String version, String languages) {
    return 'C\'est fait chez Apple : version $version, langues : $languages';
  }

  @override
  String get ascOpen => 'Ouvrir App Store Connect';

  @override
  String get ascForget => 'Oublier la clé Apple';

  @override
  String get ascManual =>
      'Chez Apple, il reste à faire à la main : les captures d\'écran (tailles iPhone), les questions sur l\'âge, le prix et les pays.';

  @override
  String bAndroidFailed(String kind) {
    return 'Échec de la génération de $kind';
  }

  @override
  String bAndroidReady(String kind) {
    return 'Fichier $kind prêt';
  }

  @override
  String get bStopped => 'Arrêté';

  @override
  String get bAppReady => 'Application prête';

  @override
  String get bReviewStart =>
      'D’autres IA vérifient l’application de leur côté…';

  @override
  String get bReviewClean => 'Les relecteurs n’ont rien trouvé à corriger.';

  @override
  String bReviewFound(int count) {
    return '$count problèmes trouvés par les relecteurs : je les corrige.';
  }

  @override
  String get bAppUpdated => 'Application mise à jour';

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
  String get forgeTitle => 'Ember crée ton app';

  @override
  String forgeFiles(int count) {
    return '$count fichiers écrits';
  }

  @override
  String researchingApp(String name) {
    return 'Analyse de « $name » sur Google Play…';
  }

  @override
  String get pickReferenceApp => 'De quelle app parlez-vous ?';

  @override
  String get pickReferenceAppHint =>
      'Ember étudiera ses fonctions sur Google Play et créera une app qui fait la même chose, avec votre propre nom et design.';

  @override
  String get referenceNone => 'Aucune, continuer sans';

  @override
  String forgeFilesOf(int count, int total) {
    return '$count fichiers écrits sur $total';
  }

  @override
  String forgeEta(int minutes) {
    return 'environ $minutes min restantes';
  }

  @override
  String forgeEstimated(int minutes) {
    return 'temps estimé environ $minutes min';
  }

  @override
  String forgeElapsed(String time) {
    return '$time écoulées';
  }

  @override
  String get forgeBackground =>
      'Vous pouvez éteindre l\'écran ou utiliser d\'autres apps : Ember continue et termine l\'app.';

  @override
  String get buyCredits => 'Acheter des crédits API';

  @override
  String get getSubscription => 'Acheter un abonnement';

  @override
  String get connectSubscription => 'Connecter mon abonnement';

  @override
  String get accessTitle => 'Accès et paiements';

  @override
  String get accessPaidOutside =>
      'Les paiements se font sur le site du fournisseur, pas dans Ember.';

  @override
  String subscriptionNotConnected(String name) {
    return '$name n\'est pas connecté : connecte-toi avec ton abonnement sur l\'ordinateur où tourne Ember.';
  }

  @override
  String connectHowTo(String plan, String command) {
    return '1. Va sur l\'ordinateur où tourne Ember et ouvre un terminal (celui d\'Ember convient aussi).\n2. Écris : $command\n3. Termine la connexion dans le navigateur avec ton compte $plan : sans clé API ni coût en plus.\n4. Reviens ici : en une minute, c\'est prêt.';
  }

  @override
  String get connectPersonalNote =>
      'Les abonnements sont personnels : utilisez-les pour vos apps, pas pour créer des apps pour d\'autres.';

  @override
  String get grokNoCli =>
      'Les abonnements Grok (SuperGrok) ne peuvent pas encore être connectés à d\'autres apps : utilisez une clé API xAI.';

  @override
  String subscriptionConnected(String plan) {
    return 'Connecté à votre abonnement $plan : sans clé API ni coût supplémentaire.';
  }

  @override
  String haveSubscription(String plan) {
    return 'Vous avez déjà $plan ?';
  }

  @override
  String subscriptionReadyUse(String engine) {
    return 'Créez avec $engine grâce à votre abonnement, sans acheter de crédits API.';
  }

  @override
  String subscriptionConnectFirst(String engine) {
    return 'Connectez-le une fois pour créer avec $engine sans coût supplémentaire.';
  }

  @override
  String get useSubscription => 'L\'utiliser';

  @override
  String get bResumeChat =>
      'Reprendre la création interrompue là où elle s\'est arrêtée';

  @override
  String get backToEmber => 'Retour à Ember';

  @override
  String get productsTitle => 'Achats intégrés à activer sur Google Play';

  @override
  String get productsHint =>
      'Ember crée et active ces produits dans Play Console pour vous, avec les prix convertis pour chaque pays.';

  @override
  String get productsActivate => 'Créer et activer sur Play Console';

  @override
  String get productsNeedKey =>
      'Connectez d\'abord Google Play (clé du compte de service) : ouvrez les étapes de publication.';

  @override
  String get productsBefore =>
      '1. Avant d\'activer, ouvre Play Console. Ces étapes se font une seule fois par compte et par app.\n2. Va dans Configuration → Profil de paiement et ajoute le compte bancaire et les infos fiscales.\n3. Envoie le fichier pour Google Play (AAB) de cette app en test interne : Google veut une version avec paiements.\n4. Dans Utilisateurs et autorisations, donne au compte de service « Gérer les commandes et les abonnements ».';

  @override
  String get productsOpenPayments => 'Profil de paiement';

  @override
  String get productsUploadFirst => 'Envoyer le fichier pour Google Play (AAB)';

  @override
  String get productsActive => 'Actif sur Google Play';

  @override
  String productPerPeriod(String price, String period) {
    return '$price / $period';
  }

  @override
  String productTrial(int days) {
    return 'essai gratuit de $days jours';
  }

  @override
  String get logoTitle => 'Logo de l\'app';

  @override
  String get logoHint =>
      'Ember dessine 6 propositions. Pas convaincu ? Appuyez sur « Autres logos » autant de fois que vous voulez. Celui choisi devient l\'icône de l\'app et l\'icône et la bannière du Play Store.';

  @override
  String get logoDescribe => 'Décrivez le logo (facultatif)';

  @override
  String get logoDescribeHint =>
      'Ex. : bouclier bleu avec un stylo, moderne, sans texte';

  @override
  String get logoGenerate => 'Générer 6 logos';

  @override
  String get logoMore => 'Autres logos';

  @override
  String get logoUse => 'Utiliser ce logo';

  @override
  String get logoApplied =>
      'Logo appliqué : les icônes sont en cours de génération, l\'aperçu va se mettre à jour.';

  @override
  String get shotsTitle => 'Captures pour le Play Store';

  @override
  String get shotsHint =>
      'Ember ouvre l\'app comme un téléphone et prend 6 captures des écrans principaux (1080×1920), prêtes pour Google Play.';

  @override
  String get shotsPreparing =>
      'Ember prépare l\'app pour les captures (un mode démo par écran) ; les photos démarrent automatiquement ensuite.';

  @override
  String get shotsPreparingChat =>
      'Préparer l\'app pour les captures du Play Store';

  @override
  String get shotsGenerate => 'Prendre 6 captures';

  @override
  String get shotsAgain => 'Refaire les captures';

  @override
  String shotsSaved(int count) {
    return '$count captures enregistrées pour Google Play.';
  }

  @override
  String get pubTitle => 'Publier avec Ember';

  @override
  String pubAccountAsk(String app) {
    return 'Bonjour ! Je vous guide pour publier **$app** sur Google Play, étape par étape, et je m\'occupe des parties techniques.\n\nPremière question : avez-vous déjà un **compte développeur Google Play Console** ?';
  }

  @override
  String get pubYesHaveIt => 'Oui, je l\'ai';

  @override
  String get pubNoHowTo => 'Non, comment le créer ?';

  @override
  String get pubAccountHow =>
      'La création prend 10 minutes :\n1. Ouvrez la page d\'inscription (bouton ci-dessous) avec votre compte Google\n2. Choisissez **Personnel** (ou Organisation si vous avez une société)\n3. Payez **25 \$ une seule fois** : c\'est pour Google, pas pour Ember\n4. Vérifiez votre identité avec un document : Google confirme en général en 1-2 jours\n\nQuand le compte est actif, revenez ici.';

  @override
  String get pubNowIHaveIt => 'C\'est fait, le compte est actif';

  @override
  String pubCreateApp(String package) {
    return 'Créez maintenant l\'app dans Play Console (seulement la première fois) :\n1. Appuyez sur **Ouvrir Play Console** ci-dessous, puis **Créer une application**\n2. Nom, langue par défaut, type **Application**, **Gratuite**\n3. Cochez les déclarations et appuyez sur **Créer l\'application**\n\nLe nom du package est `$package` : Google le relie tout seul au premier envoi.';
  }

  @override
  String get pubDone => 'C\'est fait';

  @override
  String get pubConnect =>
      '1. Je connecte maintenant Ember à Google Play pour pouvoir envoyer tes apps.\n2. **Je m\'en occupe** : je crée une clé spéciale dans ton compte Google, sur ce PC.\n3. Pour cela, je prépare un projet Google Cloud, l\'API Play et la clé.\n4. La clé sert uniquement à envoyer les apps et reste sur ton appareil.';

  @override
  String get pubDoItEmber => 'Fais-le pour moi, Ember';

  @override
  String get pubManual => 'Je préfère le faire moi-même';

  @override
  String get pubKeyWorking =>
      'Création du projet Google Cloud, activation de l\'API Play et création de la clé (1-2 minutes)…';

  @override
  String get pubInvite =>
      'Clé créée.\n\nDernière connexion : la clé doit pouvoir publier dans **votre** Play Console.\n1. Appuyez sur **Ouvrir Play Console** ci-dessous\n2. Copiez l\'adresse de la page affichée (n\'importe laquelle) et **collez-la ici**\n\nLe navigateur du PC s\'ouvre ensuite une fois : connectez-vous avec le même compte Google et appuyez sur **Autoriser**. J\'envoie l\'invitation moi-même.';

  @override
  String get pubInviteBadLink =>
      'Ce lien ne contient pas le numéro du compte Play Console. Ouvrez play.google.com/console et collez l\'adresse de cette page.';

  @override
  String get pubInviteWorking =>
      'Invitation de la clé dans votre Play Console… si le navigateur du PC s\'ouvre, connectez-vous et appuyez sur Autoriser.';

  @override
  String pubInviteManual(String email) {
    return 'Je n\'ai pas pu envoyer l\'invitation automatiquement, faisons-le ensemble (2 minutes) :\n1. **Ouvrir Play Console**, puis **Utilisateurs et autorisations** et **Inviter de nouveaux utilisateurs**\n2. Collez cet e-mail : `$email`\n3. **Autorisations du compte** : cochez versions, présence sur le store, contenu de l\'app et commandes\n4. Appuyez sur **Inviter l\'utilisateur**, puis **C\'est fait** ici';
  }

  @override
  String get pubGraphics =>
      'Connecté à Google Play.\n\nPour la fiche, Google demande l\'**icône 512×512**, la **bannière 1024×500** et au moins **2 captures**. Si ce n\'est pas encore fait, retournez à l\'écran de l\'app : dans **Logo de l\'app** et **Captures pour le Play Store**, Ember les crée en un geste. Je les envoie automatiquement avec l\'app.';

  @override
  String get pubContinue => 'Continuer';

  @override
  String get pubBackToApp => 'Retour à l\'app';

  @override
  String get pubUpload =>
      'Maintenant la fiche et l\'envoi : j\'écris titre, descriptions et politique de confidentialité, je prépare les réponses aux formulaires de Google, puis j\'envoie l\'AAB signé avec icône, bannière et captures.\n\nGénérez d\'abord l\'**AAB** depuis l\'écran de l\'app si ce n\'est pas fait.';

  @override
  String get pubPrepareUpload => 'Préparer et envoyer';

  @override
  String get pubFinish =>
      '1. Ton app est sur Google Play. Il reste quelques formulaires : ouvre **Play Console**.\n2. Confirme à la main **Sécurité des données**, **Classification du contenu**, **Public cible**, **Annonces** et **Accès à l\'app**.\n3. Copie les réponses du dernier écran : elles sont prêtes.\n4. Si ton compte personnel est nouveau, fais un **test fermé avec 12 testeurs pendant 14 jours** avant de publier.\n5. Une question ? Pose-la ci-dessous.';

  @override
  String get pubReviewAnswers => 'Voir les réponses';

  @override
  String get pubPasteLink => 'Collez ici le lien Play Console…';

  @override
  String get pubAskAnything =>
      'Posez à Ember toute question sur la publication…';

  @override
  String get adsTitle => 'Annonces AdMob';

  @override
  String get adsHint =>
      'L\'app affiche déjà des annonces de TEST Google (sûres pendant le développement) et demande le consentement UE. Pour gagner de l\'argent, créez les vrais blocs dans AdMob et collez les ID ici : Ember les ajoute à l\'app.';

  @override
  String get adsSteps =>
      '1. Ouvre AdMob. Cela prend 5 minutes, une fois par app.\n2. Va dans Applications → Ajouter une application → Android.\n3. À « L\'app est-elle sur Google Play ? », réponds Non si elle n\'est pas encore publiée.\n4. Écris le nom et appuie sur Ajouter.\n5. Copie l\'ID d\'application (ca-app-pub-…~…).\n6. Va dans Blocs d\'annonces → Ajouter et choisis un format dans la liste ci-dessous.\n7. Appuie sur Créer et copie son ID (ca-app-pub-…/…). Recommence pour chaque format.\n8. Après la publication, associe l\'app à sa fiche Play Store dans AdMob.\n9. Ajoute app-ads.txt si AdMob le demande.';

  @override
  String get adsOpenAdmob => 'Ouvrir AdMob';

  @override
  String get adsAppId => 'ID d\'application AdMob';

  @override
  String adsUnitId(String format) {
    return 'ID du bloc $format';
  }

  @override
  String get adsApply => 'Mettre les vrais ID dans l\'app';

  @override
  String get adsInvalid =>
      'Les ID doivent ressembler à ca-app-pub-1234567890123456~1234567890 (app) et ca-app-pub-1234567890123456/1234567890 (blocs).';

  @override
  String get adsChat => 'Mettre les vrais ID AdMob';

  @override
  String get pubNothingUploaded =>
      'Rien n\'a été envoyé sur Google Play : dans l\'écran suivant appuyez sur « Envoyer sur Google Play » et attendez la confirmation, puis revenez.';

  @override
  String upListing(String languages) {
    return '✓ Fiche du store (titre et descriptions) : $languages';
  }

  @override
  String get upNoListing => '✗ Fiche non écrite (titre et descriptions vides)';

  @override
  String get upIcon => '✓ Icône 512×512';

  @override
  String get upNoIcon =>
      '✗ Icône manquante : choisissez d\'abord un logo dans « Logo de l\'app »';

  @override
  String get upFeature => '✓ Bannière 1024×500';

  @override
  String get upNoFeature =>
      '✗ Bannière manquante : choisissez d\'abord un logo';

  @override
  String upShots(int count) {
    return '✓ $count captures téléphone';
  }

  @override
  String get upNoShots =>
      '✗ Captures manquantes : prenez-les d\'abord dans « Captures pour le Play Store »';

  @override
  String get upTitle => 'Google Play';

  @override
  String get upHint =>
      'Tout est enregistré pour cette app. Modifiez ce que vous voulez puis envoyez une nouvelle version : Ember crée un nouvel AAB signé (version supérieure) et l\'envoie avec la fiche, le logo et les captures.';

  @override
  String get upStateLogo => 'Logo';

  @override
  String upStateShots(int count) {
    return 'Captures : $count';
  }

  @override
  String get upStateListing => 'Titre et descriptions';

  @override
  String get upEditListing => 'Modifier titre et descriptions';

  @override
  String get upNewVersion => 'Nouvelle version sur Google Play';

  @override
  String get upBuilding => 'Je crée le nouveau fichier pour Google Play (AAB)…';

  @override
  String get upUploading => 'Envoi sur Google Play…';

  @override
  String get upNeedsSetup =>
      'Connectez d\'abord Google Play et rédigez la fiche une fois : ouvrez le guide de publication.';

  @override
  String get upOpenGuide => 'Guide de publication';

  @override
  String get pubPasteConsoleLink =>
      'Astuce : ouvrez Play Console une fois et collez ici l\'adresse de cette page. Ensuite, chaque bouton ouvrira directement **votre** compte, sans demander lequel.';

  @override
  String get privacyPublicHint =>
      'Collez un lien public que Google peut ouvrir (par exemple un gist GitHub ou une page de votre site).';

  @override
  String get privacyLocalWarning =>
      'Cette adresse ne fonctionne que sur cet ordinateur : Google ne peut pas l\'ouvrir. Collez un lien public.';

  @override
  String get consoleLinkLabel =>
      'Lien de votre Play Console (collez-le une fois)';

  @override
  String get consoleLinkHint =>
      'Ouvrez Play Console, choisissez votre compte développeur, copiez l\'adresse de cette page et collez-la ici : les boutons ouvriront directement votre compte et votre app.';

  @override
  String consoleLinkSaved(String id) {
    return 'Compte développeur $id enregistré : les boutons ouvrent maintenant ta console.';
  }

  @override
  String get upStateConnected => 'Google Play connecté (clé sur cet appareil)';

  @override
  String get upNeedsKey =>
      'Google Play n\'est pas connecté sur cet appareil : ouvrez le guide de publication et appuyez sur « Fais-le pour moi, Ember » pour créer la clé (1 minute).';

  @override
  String get upNeedsListing =>
      'Rédigez la fiche une fois : appuyez sur « Modifier titre et descriptions ».';

  @override
  String get upConnectPlay => 'Connecter Google Play';

  @override
  String get dsButton => 'Remplir Sécurité des données';

  @override
  String get dsWorking =>
      'Analyse des données collectées et remplissage du formulaire…';

  @override
  String get dsDone =>
      'Sécurité des données envoyée à Google Play — vérifiez-la dans Play Console → Contenu de l\'app → Sécurité des données et appuyez sur Envoyer.';

  @override
  String get dsNeedsCsv =>
      'Exportez d\'abord le formulaire depuis Play Console : Contenu de l\'app → Sécurité des données → Exporter en CSV. Enregistrez-le dans Téléchargements, puis réappuyez.';

  @override
  String get driveBackup => 'Enregistrer sur Google Drive';

  @override
  String get driveSaving =>
      'Demande d\'autorisation à Google et sauvegarde de la clé sur votre Drive…';

  @override
  String get driveSaved =>
      'Keystore et mot de passe enregistrés sur votre Google Drive';

  @override
  String get driveOpenFolder => 'Ouvrir le dossier sur Drive';

  @override
  String get acAskPrivacy =>
      'Rédige la politique de confidentialité de cette app';

  @override
  String get acAskAdmob => 'Comment ajouter les annonces AdMob à cette app ?';

  @override
  String get acAskContent =>
      'Que répondre dans Contenu de l\'application sur Play Console ?';

  @override
  String get acAssistant => 'Interroger Ember sur cette app';

  @override
  String get acTitle => 'Contenu de l\'application (Play Console)';

  @override
  String get acHint =>
      'Google pose ces questions avant la publication. Ember a la réponse à chacune : copiez-la et sélectionnez-la dans Play Console.';

  @override
  String get acOpenConsole => 'Ouvrir Contenu de l\'application';

  @override
  String get acCopy => 'Copier la réponse';

  @override
  String get acCopied => 'Copié';

  @override
  String get acAuto => 'Ember s\'en charge';

  @override
  String get paste => 'Coller';

  @override
  String get ghSavedOn => 'Enregistré sur GitHub';

  @override
  String get ghTitle => 'Enregistrer sur GitHub';

  @override
  String get ghHint =>
      'Conserve une copie du code de cette app dans votre propre dépôt GitHub. La clé de signature, le dossier build et les fichiers Google ne sont jamais envoyés.';

  @override
  String get ghToken => 'Jeton GitHub';

  @override
  String get ghTokenHelp =>
      'Un jeton personnel avec l\'autorisation « repo ». Il reste chiffré sur cet appareil et sert uniquement à envoyer cette app.';

  @override
  String get ghGetToken => 'Créer un jeton sur GitHub';

  @override
  String get ghRestoreTitle => 'Ouvrir une app enregistrée sur GitHub';

  @override
  String get ghRestoreHint =>
      'Les apps que tu as enregistrées sur GitHub reviennent sur cet ordinateur avec tout ce qu\'elles contenaient. Tu travailles ainsi sur la même app depuis Windows et depuis le Mac.';

  @override
  String get ghRestoreLoad => 'Afficher mes apps';

  @override
  String get ghRestoreNone =>
      'Aucune app enregistrée par Ember sur ce compte GitHub pour l\'instant.';

  @override
  String get ghRestoreHere => 'Déjà sur cet ordinateur';

  @override
  String get ghRestoreAction => 'Depuis GitHub';

  @override
  String get refresh => 'Actualiser';

  @override
  String get ghSave => 'Enregistrer sur GitHub';

  @override
  String get ghSaving => 'Envoi de l\'app vers GitHub…';

  @override
  String get ghOpen => 'Ouvrir le dépôt';

  @override
  String get ghForgetToken => 'Oublier le jeton';

  @override
  String get ghNeedsToken => 'Collez d\'abord un jeton GitHub.';

  @override
  String ghCreated(String repo) {
    return 'Dépôt $repo créé et app envoyée';
  }

  @override
  String ghUpdated(String repo) {
    return 'App envoyée vers $repo';
  }

  @override
  String get acCopyForExtension => 'Copier pour l\'extension';

  @override
  String get acFillForMe => 'Remplir dans Play Console';

  @override
  String get acFilling =>
      'Ember répond aux questions dans la fenêtre Chrome qu\'il a ouverte. Regardez-le et reprenez la main quand vous voulez.';

  @override
  String acFilled(int done, int total) {
    return '$done sections enregistrées sur $total.';
  }

  @override
  String get acNeedsAppLink =>
      'Ember ne sait pas encore quelle est cette app dans Play Console : ouvrez-la là-bas, copiez l\'adresse du navigateur et collez-la dans l\'écran de publication.';

  @override
  String get acAppLink => 'Adresse de cette app dans Play Console';

  @override
  String get acLinkNotUnderstood =>
      'Cette adresse ne désigne pas une app. Ouvrez l\'app dans Play Console et copiez l\'adresse complète depuis la barre du navigateur.';

  @override
  String get adsAdd => 'Ajouter les annonces AdMob';

  @override
  String get adsAddHint =>
      'Ember place des annonces sur chaque écran qui peut en porter, dans les limites qui gardent un compte AdMob en vie, et utilise les annonces de test de Google jusqu\'à ce que vous colliez vos identifiants.';

  @override
  String get adsAddChat =>
      'Ajouter les annonces AdMob avec des identifiants de test';

  @override
  String get adsYes => 'Oui, afficher des annonces';

  @override
  String get adsNo => 'Pas d’annonces';

  @override
  String get adsDeclined =>
      'Pas d\'annonces dans cette app. Demandez-les à Ember quand vous changerez d\'avis.';

  @override
  String get adsRemove => 'Retirer les annonces';

  @override
  String get adsRemoveChat => 'Retirer AdMob de cette app';

  @override
  String get adsAppIdHelp =>
      'Le code avec le ~ , à côté de l\'icône Android. Le même pour toutes les unités.';

  @override
  String get adsUnitHelp =>
      'Le code avec le / , à côté de l\'icône de la carte. Un différent pour chaque format.';

  @override
  String get checkTitle => 'Ember a vérifié cette app';

  @override
  String get checkAllGood =>
      'Tout ce qu\'il faut pour que l\'app fonctionne est en place.';

  @override
  String checkFound(int count) {
    return '$count choses ne marchent pas encore. Ember peut réparer celles qui portent l\'icône outil, si vous le demandez.';
  }

  @override
  String checkFixNow(int count) {
    return 'Réparer $count choses';
  }

  @override
  String get checkFixing => 'Réparation…';

  @override
  String get checkAgain => 'Vérifier à nouveau';

  @override
  String get checkAskEmber => 'Faire corriger par Ember';

  @override
  String get checkAsked =>
      'Demandé. Ember s\'en occupe : regardez la discussion ci-dessous.';

  @override
  String get previewLoginInBrowser =>
      'Google ne connecte personne dans cette fenêtre, et une connexion faite dans le navigateur ne vaut pas ici. Dans cette fenêtre, utilisez e-mail et mot de passe ; la connexion Google marche dans le navigateur et sur un téléphone.';

  @override
  String get phoneTitle => 'Votre téléphone';

  @override
  String get phoneHint =>
      'Ember installe l\'app sur le téléphone branché à cet ordinateur et l\'ouvre. La connexion Google, les notifications et les annonces ne se comportent vraiment que là.';

  @override
  String phoneRunOn(String name) {
    return 'Lancer sur $name';
  }

  @override
  String phoneUnauthorized(String name) {
    return '$name : déverrouillez-le et autorisez le débogage USB';
  }

  @override
  String get phoneBuilding => 'Préparation de l\'app pour le téléphone…';

  @override
  String get phoneInstalling => 'Installation sur le téléphone…';

  @override
  String get phoneLookAgain => 'Chercher à nouveau les téléphones';

  @override
  String get phoneOpenHere => 'Ouvrir tout de suite sur le téléphone';

  @override
  String get phoneSameWifi =>
      'Visez le code avec la caméra du téléphone. Le téléphone doit être sur le même Wi-Fi que cet ordinateur.';

  @override
  String get playLanguages => 'Langues de la fiche';

  @override
  String get playTranslating =>
      'Rédaction de la fiche dans les autres langues…';

  @override
  String get logoDelete => 'Supprimer';

  @override
  String get logoDeleted => 'Logo supprimé';

  @override
  String get logoDropHint => 'Glisse un logo ici pour en avoir 5 variantes';

  @override
  String get logoVariantsOf => 'Variantes de ce logo';

  @override
  String get playUpdateListingOnly => 'Mettre à jour seulement la fiche';

  @override
  String get playUpdateListingOnlyHint =>
      'Pour une app déjà sur Google Play : textes, toutes les langues et visuels sans nouvelle version.';

  @override
  String get playTranslationsStale =>
      'Le texte a changé : les autres langues ont encore l\'ancien.';

  @override
  String get playTranslateAgain => 'Retraduire';

  @override
  String get playLanguageIncluded => 'Publier cette langue sur Google Play';

  @override
  String get playLanguageNotTranslated =>
      'Pas encore traduite : elle est écrite quand tu enregistres avec cette langue activée.';

  @override
  String get playListingSaved =>
      'Fiche enregistrée : rien à générer. Modifiez le texte si vous voulez, puis envoyez.';

  @override
  String get playRewriteWithAi => 'Réécrire avec l\'IA';

  @override
  String get historyTitle => 'Historique';

  @override
  String get historyNewApp => 'Nouvelle app';

  @override
  String get historyDrafts => 'Brouillons';

  @override
  String get historyToday => 'Aujourd\'hui';

  @override
  String get historyYesterday => 'Hier';

  @override
  String get historyLast7Days => '7 derniers jours';

  @override
  String get historyOlder => 'Plus anciennes';

  @override
  String get historyEmpty =>
      'Rien pour l\'instant. Les apps que vous commencez et les brouillons que vous écrivez apparaissent ici.';

  @override
  String get brandTagline => 'CRÉATEUR D\'APPS';

  @override
  String get showSecret => 'Afficher';

  @override
  String get hideSecret => 'Masquer';

  @override
  String get ok => 'OK';

  @override
  String get details => 'Détails';

  @override
  String get more => 'Plus';

  @override
  String get advanced => 'Avancé';

  @override
  String get done => 'Terminé';

  @override
  String madeWith(String engine) {
    return 'Créée avec $engine · Options';
  }

  @override
  String get buildOptionsTitle => 'Qui crée ton app';

  @override
  String get homeMenu => 'Autres façons de commencer';

  @override
  String get emptyProject => 'Projet vide';

  @override
  String get settings => 'Réglages';

  @override
  String get hubNextSteps => 'Étapes suivantes';

  @override
  String get hubTest => 'Essaie-la sur ton téléphone';

  @override
  String get hubTestHint => 'Ouvre-la avec un QR code ou installe-la';

  @override
  String get hubImages => 'Icône et images';

  @override
  String get hubImagesHint => 'Le logo et les captures pour le store';

  @override
  String get hubChecks => 'Vérifications';

  @override
  String get hubChecksHint => 'Ce qu\'Ember et les relecteurs ont trouvé';

  @override
  String hubChecksCount(int count) {
    return '$count à corriger';
  }

  @override
  String get hubPlay => 'Google Play';

  @override
  String get hubPlayHint => 'Publie ou mets à jour sur Android';

  @override
  String get hubAppStore => 'App Store';

  @override
  String get hubAppStoreHint => 'Publie pour iPhone';

  @override
  String get hubMore => 'Plus';

  @override
  String get hubMoreHint => 'Sauvegarde, publicités, achats, le code';

  @override
  String get techDetails => 'Détails techniques';

  @override
  String get changeHint => 'Que veux-tu changer ?';

  @override
  String get installFileTitle => 'Fichier à installer (APK)';

  @override
  String get installFileHint =>
      'Un fichier que tu peux envoyer à n\'importe quel téléphone Android et installer.';

  @override
  String get storeFileTitle => 'Fichier pour Google Play (AAB)';

  @override
  String get storeFileHint =>
      'Utile seulement si tu envoies toi-même sur la Play Console : Ember le prépare quand il publie.';

  @override
  String get makeFile => 'Préparer le fichier';

  @override
  String get openCodeTitle => 'Le code';

  @override
  String get openCodeHint =>
      'Ouvre l\'éditeur pour lire ou modifier les fichiers à la main.';

  @override
  String get backToApp => 'Retour à l\'app';

  @override
  String designChosen(String name) {
    return 'Design : $name';
  }

  @override
  String get reviewFixLabel => 'Correction des relecteurs';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get themeSystem => 'Comme l\'appareil';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsAi => 'Intelligences artificielles';

  @override
  String get settingsAccounts => 'Comptes connectés';

  @override
  String get settingsAccountsHint =>
      'Ils se connectent la première fois que tu en as besoin, depuis la page de l\'app. Ici tu peux les voir et les déconnecter.';

  @override
  String accountConnected(String name) {
    return '$name : connecté';
  }

  @override
  String accountNotConnected(String name) {
    return '$name : non connecté';
  }

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get runnerAddress => 'Où tourne Ember';

  @override
  String get runnerAddressHint =>
      'L\'adresse de l\'ordinateur qui crée tes apps (le Runner). Ne la change que si on te l\'a demandé.';

  @override
  String signedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get reviewersTitle => 'Relecteurs de l\'app';

  @override
  String get reviewersHint =>
      'Quand une app est terminée, ces modèles la lisent de leur côté et disent ce qui est faux, ce qui manque et ce qui ne marche pas ; les corrections repartent toutes seules vers celui qui a écrit l\'app. Tu les règles une fois, pour toutes les apps.';

  @override
  String get aiKeysTitle => 'Clés';

  @override
  String plLanguagesOn(int count) {
    return 'Langues : $count actives';
  }

  @override
  String get plManage => 'Gérer';

  @override
  String get plLanguagesHint =>
      'Activez une langue pour publier la fiche dans cette langue. Touchez une langue pour lire ou corriger son texte.';

  @override
  String get plSearchLanguage => 'Chercher une langue';

  @override
  String get plNoLanguageFound => 'Aucune langue avec ce nom.';

  @override
  String get plEnglish => 'Anglais';

  @override
  String get plMainLanguage => 'Langue principale, toujours active';

  @override
  String get plLangReady => 'Traduite';

  @override
  String get plLangOld => 'Ancien texte';

  @override
  String get plLangMissing => 'À écrire';

  @override
  String get plLangWriting => 'Rédaction…';

  @override
  String get plGenerating => 'Ember rédige la fiche…';

  @override
  String get plFeeTitle => 'Google demande 25 \$, une seule fois';

  @override
  String get plAiBadAnswer =>
      'L\'IA a donné une réponse qu\'Ember ne peut pas lire. Réessayez.';

  @override
  String get plNoAi =>
      'Aucune IA n\'est configurée : ajoutez-en une dans les Réglages.';

  @override
  String get plPrivacyLocalOnly =>
      'La politique de confidentialité est enregistrée seulement sur cet ordinateur : Google ne peut pas l\'ouvrir. Connectez GitHub dans Ember, ou collez ci-dessous un lien à vous.';

  @override
  String plPrivacyNotPublished(String error) {
    return 'Politique de confidentialité non publiée : $error. Le reste de la fiche a été enregistré ; collez ci-dessous un lien à vous.';
  }

  @override
  String get asConnTitle => 'Votre clé Apple';

  @override
  String get asConnHint =>
      'Ember l\'utilise pour publier à votre place. Vous l\'enregistrez une seule fois et elle sert pour toutes vos apps.';

  @override
  String asKeySaved(String file) {
    return 'Clé enregistrée : $file';
  }

  @override
  String get asChangeKey => 'Changer de clé';

  @override
  String get asTeamId => 'Team ID (facultatif)';

  @override
  String get asTeamIdHelp =>
      'Il sert à signer l\'app iPhone. Laissez-le vide et Ember le lit chez Apple avec votre clé.';

  @override
  String get asP8KeepHelp =>
      'Laissez-le vide pour garder la clé déjà enregistrée.';

  @override
  String get asLoadP8 => 'Charger le fichier .p8';

  @override
  String get asSaveKey => 'Enregistrer la clé';

  @override
  String get asP8FileType => 'Clé Apple (.p8)';

  @override
  String get asVerify => 'Vérifier la connexion';

  @override
  String get asVerifyOk => 'La connexion fonctionne';

  @override
  String get asVerifyOkReached =>
      'La connexion fonctionne : Ember a joint App Store Connect';

  @override
  String asVerifyTeam(String team) {
    return 'Team $team';
  }

  @override
  String get asBadKeyId =>
      'Ce Key ID n\'est pas valide. C\'est le code court à côté de la clé, par exemple Z47GM3ZDZ6.';

  @override
  String get asBadIssuerId =>
      'Cet Issuer ID n\'est pas valide. C\'est le code long en haut de la page Clés.';

  @override
  String get asBadP8 =>
      'Ce n\'est pas le contenu de la clé. Collez tout le fichier AuthKey_….p8, de la ligne -----BEGIN PRIVATE KEY----- jusqu\'à -----END PRIVATE KEY-----. Le nom du fichier seul ne suffit pas.';

  @override
  String asP8ReadFailed(String error) {
    return 'Ember n\'a pas pu lire le fichier .p8 : $error';
  }

  @override
  String get asSaveKeyFirst =>
      'Enregistrez d\'abord votre clé Apple : Key ID, Issuer ID et le fichier .p8.';

  @override
  String get asFillTitle => 'Ce qu\'Ember remplit pour vous';

  @override
  String get asFillHint =>
      'Quand vous publiez, Ember règle tout seul la tranche d\'âge (4+), la déclaration sur le chiffrement et les réponses sur la confidentialité. Si vous les choisissez ici, aussi la catégorie, le prix et les captures d\'écran.';

  @override
  String get asCategory => 'Catégorie App Store';

  @override
  String get asCategoryNone => 'Ne pas définir';

  @override
  String get asFree => 'App gratuite (dans tous les pays)';

  @override
  String get asScreenshots =>
      'Créer et envoyer les captures d\'écran iPhone et iPad';

  @override
  String get asScreenshotsHelp =>
      'Prises depuis l\'aperçu web. L\'app doit avoir le « mode captures d\'écran ».';

  @override
  String get asReviewTitle =>
      'Informations pour la vérification d\'Apple (facultatives)';

  @override
  String get asReviewEmail => 'E-mail de contact';

  @override
  String get asReviewEmailHelp =>
      'Laissez-le vide pour utiliser l\'e-mail de votre compte.';

  @override
  String get asMarketingUrl => 'Votre site web (Marketing URL)';

  @override
  String get asMarketingUrlHelp =>
      'AdMob cherche ici le fichier app-ads.txt. Enregistré pour toutes vos apps.';

  @override
  String get asReviewPhone => 'Téléphone de contact';

  @override
  String get asReviewPhoneHelp =>
      'Apple le demande, par exemple +39 333 1234567. Seule la personne qui vérifie l\'app le voit. Ember le retient pour vos prochaines apps.';

  @override
  String get asReviewNotes => 'Notes pour la personne qui vérifie l\'app';

  @override
  String get asDemoUser =>
      'Compte de démonstration (si l\'app demande une connexion)';

  @override
  String get asDemoPass => 'Mot de passe de démonstration';

  @override
  String get asChecksTitle => 'Avant l\'envoi';

  @override
  String get asChecksNone => 'Aucun problème pour Apple.';

  @override
  String asChecksBlock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problèmes bloquent l’envoi.',
      one: '1 problème bloque l’envoi.',
    );
    return '$_temp0';
  }

  @override
  String get asChecksWarn =>
      'Seulement des avertissements : l\'envoi est possible.';

  @override
  String get asBlocks => 'Bloque l\'envoi';

  @override
  String get asWarning => 'Avertissement';

  @override
  String asFixDone(String message) {
    return 'Corrigé : $message';
  }

  @override
  String asFixFailed(String message) {
    return 'Non corrigé : $message';
  }

  @override
  String asCanClose(int minutes) {
    return 'Vous pouvez fermer cette page : Ember continue tout seul et envoie l\'app en vérification dès qu\'Apple a terminé ($minutes min).';
  }

  @override
  String asRunningFor(int minutes) {
    return 'En cours depuis $minutes min.';
  }

  @override
  String get asDoneExport => 'Déclaration sur le chiffrement réglée';

  @override
  String get asDoneAge => 'Tranche d\'âge remplie';

  @override
  String get asDoneCategory => 'Catégorie réglée';

  @override
  String get asDoneReview => 'Informations pour la vérification enregistrées';

  @override
  String get asDoneFree => 'Prix : gratuit dans tous les pays';

  @override
  String get asDonePrivacy => 'Réponses sur la confidentialité remplies';

  @override
  String asDoneShots(int count) {
    return 'Captures d\'écran envoyées : $count';
  }

  @override
  String get asCatUtilities => 'Utilitaires';

  @override
  String get asCatProductivity => 'Productivité';

  @override
  String get asCatBusiness => 'Économie et entreprise';

  @override
  String get asCatEducation => 'Éducation';

  @override
  String get asCatEntertainment => 'Divertissement';

  @override
  String get asCatFinance => 'Finance';

  @override
  String get asCatFoodAndDrink => 'Cuisine et boissons';

  @override
  String get asCatHealthAndFitness => 'Forme et santé';

  @override
  String get asCatLifestyle => 'Style de vie';

  @override
  String get asCatMusic => 'Musique';

  @override
  String get asCatNavigation => 'Navigation';

  @override
  String get asCatNews => 'Actualités';

  @override
  String get asCatPhotoAndVideo => 'Photo et vidéo';

  @override
  String get asCatReference => 'Références';

  @override
  String get asCatShopping => 'Shopping';

  @override
  String get asCatSocial => 'Réseaux sociaux';

  @override
  String get asCatSports => 'Sports';

  @override
  String get asCatTravel => 'Voyages';

  @override
  String get asCatWeather => 'Météo';

  @override
  String get asCatBooks => 'Livres';

  @override
  String get asCatDeveloperTools => 'Outils de développement';

  @override
  String get asCatGraphicsAndDesign => 'Graphisme et design';

  @override
  String get asCatGames => 'Jeux';

  @override
  String get reviewTitle => 'Vérification de l\'app';

  @override
  String get reviewHintNone =>
      'Fais vérifier l\'app terminée par plusieurs intelligences artificielles : chacune la lit de son côté et dit ce qui est factice, ce qui manque et ce qui ne marche pas. Ajoute au moins un relecteur ci-dessous.';

  @override
  String reviewHintReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relecteurs prêts',
      one: '1 relecteur prêt',
    );
    return '$_temp0. Chacun lit l\'app de son côté ; ce que plusieurs remarquent passe en tête de liste.';
  }

  @override
  String get reviewReviewers => 'Relecteurs';

  @override
  String get reviewReading => 'Les relecteurs lisent l\'app…';

  @override
  String reviewNoAnswer(String name) {
    return '$name : pas de réponse';
  }

  @override
  String get reviewNothingFound =>
      'Les relecteurs n\'ont trouvé aucun problème.';

  @override
  String get reviewAddReviewer => 'Ajouter un relecteur';

  @override
  String get reviewRun => 'Vérifier l\'app';

  @override
  String get reviewKeySavedMask => '•••••• (clé enregistrée)';

  @override
  String get reviewPasteKeyHint => 'colle la clé ici';

  @override
  String get reviewRemoveKey => 'Retirer la clé';

  @override
  String get reviewFixedRecheck => 'Corrigé : à revérifier';

  @override
  String get reviewFixing => 'Correction en cours…';

  @override
  String get reviewFix => 'Corriger';

  @override
  String get reviewPasteKeyFirst => 'Colle d\'abord la clé.';

  @override
  String get reviewKeySaved => 'Clé enregistrée.';

  @override
  String get reviewKeyRemoved => 'Clé supprimée.';

  @override
  String needsYouTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il faut $count choses de ta part',
      one: 'Il faut une chose de ta part',
    );
    return '$_temp0';
  }

  @override
  String get needsYouHint =>
      'Ember ne peut pas les faire seul (une connexion, une clé, un compte). Fais-les et touche « Terminé » : il reprend là où il s\'était arrêté.';

  @override
  String get needsYouIgnore => 'Ignorer';

  @override
  String listAnd(String first, String last) {
    return '$first et $last';
  }

  @override
  String panelDownOne(String names) {
    return '$names ne fonctionne pas';
  }

  @override
  String panelDownMany(String names) {
    return '$names ne fonctionnent pas';
  }

  @override
  String get panelNoneLeft =>
      'Il ne reste aucune IA : rien ne peut être dessiné ni vérifié. Réessaie, ou ferme.';

  @override
  String get panelOneLeft =>
      'Il ne reste qu\'1 IA : elle dessinera seule et personne ne vérifiera son travail.';

  @override
  String panelSomeLeft(int count) {
    return 'Il reste $count IA qui travaillent ensemble et se vérifient entre elles.';
  }

  @override
  String panelProceedWithout(String name) {
    return 'Continuer sans $name';
  }

  @override
  String panelProceedWithoutMany(int count) {
    return 'Continuer sans $count IA';
  }

  @override
  String get panelAllOk => 'Toutes les IA fonctionnent';

  @override
  String get panelHoldNote =>
      'Rien ne démarre tant que tu n\'as pas décidé. Si c\'est un problème de connexion ou de clé, règle-le maintenant et appuie sur Réessayer : quand il repasse au vert, on continue avec tout le monde.';

  @override
  String get panelRetryAll => 'Tout réessayer';

  @override
  String get panelContinueAll => 'Continuer avec toutes';

  @override
  String get panelTrying => 'Essai en cours…';

  @override
  String get pingNoAnswer => 'pas de réponse';

  @override
  String get pingTimeout => 'ne répond pas (25 s)';

  @override
  String get mockupRefined => 'refait avec les notes';

  @override
  String mockupPanelNotes(String notes) {
    return 'Notes de la table : $notes';
  }

  @override
  String mockupAgreeing(int count) {
    return 'Les $count IA choisissent ensemble les 8 directions…';
  }

  @override
  String mockupComparing(int count, int mockups) {
    return 'Les $count designers comparent les $mockups maquettes…';
  }

  @override
  String get mockupRedrawing =>
      'Chaque designer refait sa maquette avec les notes des autres…';

  @override
  String get mockupInvalid => 'Le modèle n\'a pas renvoyé de maquette valide';

  @override
  String get assistantSignIn => 'Connecte-toi pour utiliser l\'assistant';

  @override
  String get imagesLabel => 'Images';

  @override
  String assistantImageTooLarge(String name) {
    return '$name : image trop lourde (3,5 Mo max)';
  }

  @override
  String get assistantAddImage => 'Ajouter une image';

  @override
  String get assistantFixApp => 'Corriger l\'app avec cette demande';

  @override
  String get findPrevious => 'Résultat précédent';

  @override
  String get findNext => 'Résultat suivant';

  @override
  String get toggleReplace => 'Afficher ou masquer Remplacer';

  @override
  String get clearConsole => 'Vider la console';

  @override
  String get stopAutoRebuild => 'Ne plus recompiler à l\'enregistrement';

  @override
  String get deviceTablet => 'Tablette';

  @override
  String get deviceDesktop => 'Ordinateur';

  @override
  String get checkEmailToConfirm =>
      'Vérifie ta boîte mail pour confirmer ton inscription.';
}
