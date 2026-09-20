// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Ember – App Maker';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginSubtitle =>
      'Crea apps Flutter desde cualquier dispositivo, con IA.';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get runnerUrl => 'URL del Runner';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get devLoginHint =>
      'Modo desarrollo: Supabase no configurado, acceso solo con correo a través del Runner.';

  @override
  String get invalidEmail => 'Correo no válido';

  @override
  String get passwordTooShort => 'Al menos 6 caracteres';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get projects => 'Tus apps';

  @override
  String get noProjects =>
      'Aún no has invocado ninguna app. Describe una arriba.';

  @override
  String get newProject => 'Nuevo proyecto';

  @override
  String get projectName => 'Nombre del proyecto';

  @override
  String get projectNameHelp => 'minúsculas, letras/números/_ (p. ej. my_app)';

  @override
  String get create => 'Crear';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get rename => 'Renombrar';

  @override
  String get retry => 'Reintentar';

  @override
  String get statusCreating => 'Creando…';

  @override
  String get statusReady => 'Listo';

  @override
  String get statusError => 'Error';

  @override
  String creatingProject(String name) {
    return 'Creando $name';
  }

  @override
  String get files => 'Archivos';

  @override
  String get editor => 'Editor';

  @override
  String get newFile => 'Nuevo archivo';

  @override
  String get newFolder => 'Nueva carpeta';

  @override
  String get fileName => 'Nombre';

  @override
  String deleteConfirm(String path) {
    return '¿Eliminar $path?';
  }

  @override
  String get save => 'Guardar';

  @override
  String get saved => 'Guardado';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String get discard => 'Descartar';

  @override
  String get noFileOpen => 'Abre un archivo del árbol.';

  @override
  String get conflictTitle => 'Archivo modificado en otro lugar';

  @override
  String conflictBody(String path) {
    return '$path cambió en el Runner después de abrirlo.';
  }

  @override
  String get reload => 'Recargar';

  @override
  String get overwrite => 'Sobrescribir';

  @override
  String get connected => 'Conectado';

  @override
  String get connecting => 'Conectando…';

  @override
  String get disconnected => 'Desconectado';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get binaryFile =>
      'Archivo binario o demasiado grande: no se puede editar.';

  @override
  String get terminal => 'Terminal';

  @override
  String get newTerminal => 'Nueva terminal';

  @override
  String get toggleTerminal => 'Mostrar/ocultar terminal';

  @override
  String get restart => 'Reiniciar';

  @override
  String get preview => 'Vista previa';

  @override
  String get togglePreview => 'Mostrar/ocultar vista previa';

  @override
  String get runWeb => 'Ejecutar Web';

  @override
  String get building => 'Compilando…';

  @override
  String get buildFailed => 'La compilación falló: revisa el registro abajo.';

  @override
  String get reloadPreview => 'Recargar vista previa';

  @override
  String get device => 'Dispositivo';

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String get openOnOtherDevice => 'Abrir en otro dispositivo';

  @override
  String get qrLocalhostWarning =>
      'Esta dirección solo funciona en este ordenador. Usa la IP de red del Runner (p. ej. http://192.168.1.20:8787) para abrirla desde el teléfono.';

  @override
  String get copy => 'Copiar';

  @override
  String get close => 'Cerrar';

  @override
  String get console => 'Consola';

  @override
  String get autoRebuild => 'Recompilar al guardar';

  @override
  String get previewEmpty =>
      'Pulsa «Ejecutar Web» para compilar la app y verla aquí. Cada guardado actualiza la vista previa.';

  @override
  String get ai => 'IA';

  @override
  String get toggleAi => 'Mostrar/ocultar panel de IA';

  @override
  String get aiSettings => 'Claves API y modelos';

  @override
  String get apiKeysHint =>
      'Las claves permanecen cifradas en este dispositivo (almacenamiento seguro). Con el proxy activo pasan por tu Runner solo en cada solicitud y nunca se guardan ni se registran.';

  @override
  String get useRunnerProxy => 'Pasar por el Runner (proxy)';

  @override
  String get useRunnerProxyHint =>
      'Recomendado. Desactívalo para llamar a los proveedores directamente desde este dispositivo.';

  @override
  String get useRunnerProxyWeb =>
      'Obligatorio en la web: los navegadores no pueden llamar a los proveedores directamente.';

  @override
  String get apiKey => 'Clave API';

  @override
  String get apiKeyOptional => 'Clave API (si es necesaria)';

  @override
  String get replaceApiKey => 'Reemplazar clave';

  @override
  String get testKey => 'Probar';

  @override
  String get testing => 'Probando…';

  @override
  String keyWorks(String model) {
    return 'Funciona ✓ ($model)';
  }

  @override
  String get getKey => 'Obtener una clave';

  @override
  String get addModelId => 'Añadir ID de modelo';

  @override
  String get selectModel => 'Elegir modelo';

  @override
  String get keyPresent => 'clave presente';

  @override
  String get notConfigured => 'no configurado';

  @override
  String get per1k => 'por 1k tokens (entrada/salida)';

  @override
  String applyTo(String path) {
    return 'Aplicar a $path';
  }

  @override
  String get noChanges => 'Ninguna diferencia con el archivo actual.';

  @override
  String get accept => 'Aceptar';

  @override
  String get reject => 'Rechazar';

  @override
  String get apply => 'Aplicar';

  @override
  String applied(String path) {
    return 'Cambio aplicado a $path: revísalo y guarda.';
  }

  @override
  String get applyNoTarget =>
      'Abre un archivo o pide a la IA que indique la ruta del archivo.';

  @override
  String get clearChat => 'Vaciar chat';

  @override
  String get chatEmpty =>
      'Pregunta sobre tu proyecto. El archivo abierto se envía como contexto.';

  @override
  String get chatNoKeys =>
      'Añade al menos una clave API (Claude, ChatGPT o Gemini) para usar la IA.';

  @override
  String get attachOpenFile => 'Adjuntar el archivo abierto como contexto';

  @override
  String get askAi => 'Pregunta a la IA…  (Ctrl+Intro para enviar)';

  @override
  String get send => 'Enviar';

  @override
  String get stop => 'Detener';

  @override
  String get copied => 'Copiado';

  @override
  String get truncated => 'respuesta cortada (límite de tokens)';

  @override
  String get refused => 'rechazada por el modelo';

  @override
  String get stopped => 'detenida';

  @override
  String get badgeFreeTier => 'gratis*';

  @override
  String get badgeSubscription => 'suscripción';

  @override
  String get badgePaid => 'de pago';

  @override
  String needsKey(String name) {
    return 'Necesita una clave API de $name: añádela en los ajustes.';
  }

  @override
  String get claudeCodeUnavailable =>
      'Claude Code no está disponible en este Runner (debe estar instalado y con sesión iniciada en el PC del Runner).';

  @override
  String get appPromptHint =>
      'Ej.: una app de recetas con fotos, lista de la compra y temporizador…';

  @override
  String get chooseAi => 'Elige el motor';

  @override
  String get createApp => 'Ember App';

  @override
  String get openEditor => 'Editor';

  @override
  String get describeYourApp => 'Invoca tu app';

  @override
  String get describeYourAppHint =>
      'Describe qué debe hacer y cómo debe verse. Ember la escribe, la verifica y te la muestra. (*Gemini: cuota gratuita de Google con límites diarios)';

  @override
  String get improveApp => '¿Qué quieres añadir o mejorar?';

  @override
  String get improveAppHint =>
      'Describe las próximas funciones o cambios, p. ej.: añade videollamadas, inicio de sesión con Google, salas privadas… También puedes pegar aquí las claves que te pida la IA.';

  @override
  String get applyChange => 'Aplicar cambio';

  @override
  String get buildLog => 'Detalles';

  @override
  String get stepClaudeCode => 'Claude Code escribe y verifica el código';

  @override
  String stepWriting(int count) {
    return 'Escribiendo el código ($count archivos)';
  }

  @override
  String get stepDependencies => 'Instalando dependencias';

  @override
  String get stepChecking => 'Comprobando errores';

  @override
  String stepFixing(int round) {
    return 'Corrigiendo errores (intento $round)';
  }

  @override
  String get stepBuilding => 'Compilando la app';

  @override
  String get stepReady => 'Lista';

  @override
  String get appReadyTitle => 'Tu app está lista 🎉';

  @override
  String get openApp => 'Abrir app';

  @override
  String get viewCode => 'Ver código';

  @override
  String get buildCancelled => 'Creación detenida';

  @override
  String get buildFailedTitle => 'No pude terminar la app';

  @override
  String get bestQuality => 'Potencia máxima';

  @override
  String get bestQualityOn =>
      'El motor más potente: más lento, para apps complejas';

  @override
  String get bestQualityOff =>
      'Rápido (recomendado): ideal para la mayoría de las apps';

  @override
  String get androidFileQuestion => '¿Quieres el archivo para Android?';

  @override
  String get androidFileHint =>
      'APK: para instalar en el teléfono. AAB: para subir a Google Play Console. Ambos firmados.';

  @override
  String get generateApk => 'Generar APK';

  @override
  String get generateAab => 'Generar AAB';

  @override
  String androidBuilding(String kind) {
    return 'Generando $kind… la primera vez puede tardar 3-5 minutos.';
  }

  @override
  String get downloadApk => 'Descargar e instalar APK';

  @override
  String get downloadAab => 'Descargar AAB';

  @override
  String get apkInstallHint =>
      'APK firmado. Si Android lo pide, permite la instalación desde esta fuente.';

  @override
  String get aabHint =>
      'AAB firmado con la clave de subida de esta app: listo para Google Play Console. El número de versión aumenta en cada compilación.';

  @override
  String get androidFailed => 'La generación falló:';

  @override
  String get backupSigningKey => 'Guardar clave de firma';

  @override
  String get backupSigningKeyHint =>
      'Guarda el archivo de la clave y la contraseña en un lugar seguro (p. ej. Google Drive): los necesitas para publicar actualizaciones de esta app en Google Play. El enlace funciona una sola vez durante 10 minutos.';

  @override
  String get downloadKeystore => 'Descargar archivo de clave';

  @override
  String get fullscreenExitHint => 'Desliza o pulsa atrás para volver a Ember';

  @override
  String get runFullscreen => 'Ejecutar a pantalla completa';

  @override
  String cliNotInstalled(String name) {
    return 'no instalado en el Runner ($name)';
  }

  @override
  String get terminalCliHint =>
      'Claude Code, Codex y Gemini usan la sesión iniciada en el PC del Runner. La primera vez sigue las instrucciones en la terminal para iniciar sesión.';

  @override
  String get generatingMockups => 'Creando 5 estilos visuales…';

  @override
  String designingStyle(String style) {
    return 'Diseñando el estilo «$style»…';
  }

  @override
  String get chooseMockup => 'Elegir este';

  @override
  String get editMockup => 'Editar este mockup';

  @override
  String get editMockupHint =>
      'P. ej.: más oscuro, botones redondeados, logo rosa…';

  @override
  String get newMockups => 'Nuevos mockups (5 estilos diferentes)';

  @override
  String get previousMockups => 'Mockups anteriores';

  @override
  String mockupSet(int n) {
    return 'Serie $n';
  }

  @override
  String get skipMockups => 'Omitir los mockups y crear la app';

  @override
  String get playAskUpload => '¿Quieres subir la app a Google Play Store?';

  @override
  String get playYesUpload => 'Sí, subir a Play Store';

  @override
  String get playNotNow => 'Ahora no';

  @override
  String get playFeeNotice =>
      'Necesitas una cuenta de desarrollador de Google Play Console. Coste: 25 \$ una sola vez (no es una suscripción), pagados directamente a Google, no a Ember.';

  @override
  String get playPublishTitle => 'Publicar en Google Play';

  @override
  String get playStepAccount => 'Cuenta de Google Play Console';

  @override
  String get playOpenSignup => 'Crear cuenta de Play Console';

  @override
  String get playHaveAccount => 'Ya tengo una cuenta activa de Play Console';

  @override
  String get next => 'Siguiente';

  @override
  String get playStepCreateApp => 'Crea la app en Play Console';

  @override
  String get playCreateAppGuide =>
      'Google exige este paso manualmente, solo la primera vez:\n1. Abre **Play Console** → **Crear app**\n2. Nombre de la app, idioma predeterminado, tipo **App**, **Gratis**\n3. Acepta las declaraciones y pulsa **Crear app**\n\nEl nombre del paquete se vincula en la primera subida: usa el de abajo.';

  @override
  String get playPackageName => 'Nombre del paquete';

  @override
  String get playOpenConsole => 'Abrir Play Console';

  @override
  String get playAppCreated => 'He creado la app en Play Console';

  @override
  String get playStepConnect => 'Conecta Ember con Google Play';

  @override
  String get playConnectGuide =>
      'Necesitas una **clave de cuenta de servicio** (una sola vez para todas tus apps):\n1. Abre **Google Cloud** y activa **Google Play Android Developer API**\n2. **Cuentas de servicio** → **Crear** → **Claves** → **Añadir clave** → **JSON** (se descarga un archivo)\n3. En **Play Console** → **Usuarios y permisos** → **Invitar a nuevos usuarios** → pega el correo de la cuenta de servicio → concede permisos de **publicación**\n4. Abre el JSON descargado y **pega aquí todo su contenido**\n\nLa clave permanece cifrada en este dispositivo y solo se usa para las subidas.';

  @override
  String get playOpenApiLibrary => 'Activar la API de Google Play';

  @override
  String get playOpenServiceAccounts => 'Cuentas de servicio';

  @override
  String get playServiceAccountJson =>
      'Contenido JSON de la cuenta de servicio';

  @override
  String get playStepListing => 'Ficha de la tienda y subida';

  @override
  String get playGenerateWithAi =>
      'Generar ficha, política de privacidad y respuestas con IA';

  @override
  String get playTitle => 'Título (máx. 30)';

  @override
  String get playShortDescription => 'Descripción breve (máx. 80)';

  @override
  String get playFullDescription => 'Descripción completa';

  @override
  String get playReleaseNotes => 'Notas de la versión';

  @override
  String get playContactEmail =>
      'Correo de contacto (obligatorio en Play Store)';

  @override
  String get playPrivacyUrl => 'Enlace a la política de privacidad';

  @override
  String get playTrack => 'Dónde publicar';

  @override
  String get playTrackInternal => 'Pruebas internas (recomendado para empezar)';

  @override
  String get playTrackClosed => 'Pruebas cerradas';

  @override
  String get playTrackProduction => 'Producción (pública)';

  @override
  String get playUpload => 'Subir a Google Play';

  @override
  String get playStepFinish => 'Completa en Play Console';

  @override
  String playUploaded(String version, String track, String draft) {
    return '✅ ¡Subida! Versión $version en el canal «$track». $draft';
  }

  @override
  String get playDraftNote =>
      'Como la app nunca se ha publicado, Google la guardó como borrador: completa los pasos de abajo y pulsa «Enviar a revisión» en Play Console.';

  @override
  String playManualChecklist(String privacyUrl) {
    return 'Google exige confirmar manualmente estos puntos en Play Console (respuestas listas abajo):\n- **Política de privacidad** → pega el enlace: $privacyUrl\n- **Seguridad de los datos**\n- Cuestionario de **clasificación de contenido**\n- **Público objetivo y contenido**\n- **Anuncios** y **Acceso a la app** (proporciona una cuenta de prueba si se requiere inicio de sesión)\n- **Ficha de Play Store**: icono de 512×512 y al menos 2 capturas de pantalla\n- Cuentas personales nuevas: Google puede exigir **pruebas cerradas** con un número mínimo de testers antes de producción';
  }

  @override
  String get playDataSafety => 'Respuestas para «Seguridad de los datos»';

  @override
  String get playContentRating =>
      'Respuestas para «Clasificación de contenido»';

  @override
  String get playOtherDeclarations => 'Público, anuncios y acceso a la app';

  @override
  String get assistantTitle => 'Pregunta a Ember';

  @override
  String get assistantFree => 'Gratis';

  @override
  String get assistantEmpty =>
      '¡Hola, soy Ember! Pregúntame lo que quieras: ideas para tu app, cómo publicarla en Play Store, cómo configurar el inicio de sesión y las bases de datos…';

  @override
  String get assistantUnconfigured =>
      'El asistente gratuito aún no está activo en este servidor (falta la clave de Gemini del Runner).';

  @override
  String get assistantHint => 'Pregunta lo que quieras a Ember…';

  @override
  String get assistantSuggest1 => '¿Qué app puedo crear para mi tienda?';

  @override
  String get assistantSuggest2 => '¿Cómo publico una app en Play Store?';

  @override
  String get assistantSuggest3 =>
      '¿Cómo funciona el inicio de sesión con Google?';

  @override
  String get language => 'Idioma';

  @override
  String get find => 'Buscar';

  @override
  String get replace => 'Reemplazar';

  @override
  String get replaceAll => 'Todos';

  @override
  String get baseUrl => 'URL base';

  @override
  String fontLabel(String font) {
    return 'Fuente: $font';
  }

  @override
  String get styleMinimal => 'Minimalista claro';

  @override
  String get styleDark => 'Oscuro premium';

  @override
  String get stylePlayful => 'Colorido y divertido';

  @override
  String get styleGlass => 'Glassmorphism';

  @override
  String get styleMaterial => 'Material 3';

  @override
  String get styleNeumorph => 'Neumorfismo';

  @override
  String get styleLuxury => 'Lujo elegante';

  @override
  String get styleBrutal => 'Brutalista audaz';

  @override
  String get stylePastel => 'Pastel suave';

  @override
  String get styleTech => 'Tecnológico futurista';

  @override
  String get styleNature => 'Naturaleza';

  @override
  String get styleIos => 'Estilo iOS';

  @override
  String get styleRetro => 'Retro años 80';

  @override
  String get styleMono => 'Monocromático';

  @override
  String get styleCorporate => 'Profesional';

  @override
  String bWriting(String model) {
    return 'Escribiendo el código con $model…';
  }

  @override
  String bApplying(String change, String model) {
    return 'Aplicando el cambio con $model: $change';
  }

  @override
  String get bNoModel => 'Ningún modelo seleccionado';

  @override
  String get bNoFiles =>
      'La IA no generó ningún archivo: inténtalo de nuevo o cambia de modelo.';

  @override
  String bErrorsRemain(int count, String problems) {
    return 'Siguen quedando errores tras $count intentos de corrección:\n$problems';
  }

  @override
  String bFixing(int max, int round) {
    return 'Corrigiendo errores (intento $round de $max)…';
  }

  @override
  String bNoFixes(String problems) {
    return 'La IA no propuso correcciones para:\n$problems';
  }

  @override
  String bIncompleteFile(String path) {
    return 'Archivo incompleto ignorado: $path';
  }

  @override
  String bPathNotAllowed(String path) {
    return 'Ruta no permitida, ignorada: $path';
  }

  @override
  String get bTruncated =>
      'Respuesta cortada por el límite de tokens: los archivos incompletos se recrearán en la corrección.';

  @override
  String get bRefused => 'El modelo rechazó la solicitud.';

  @override
  String get bPubGet => 'Instalando dependencias (flutter pub get)…';

  @override
  String get bPubGetFailed => 'flutter pub get falló';

  @override
  String get bAnalyze => 'Comprobando errores (flutter analyze)…';

  @override
  String get bNoErrors => 'Sin errores ✓';

  @override
  String bErrorsFound(int count) {
    return '$count errores encontrados';
  }

  @override
  String get bClaudeApplying => 'Claude Code está aplicando el cambio…';

  @override
  String get bClaudeBuilding => 'Claude Code está creando la app en el PC…';

  @override
  String get bClaudeFailed =>
      'Claude Code no terminó la app: revisa el registro.';

  @override
  String get bWebBuilding =>
      'Compilando la app para la web (unos 30 segundos)…';

  @override
  String bWebFailed(String log) {
    return 'La compilación web falló:\n$log';
  }

  @override
  String get bApk =>
      'Generando el APK (la primera vez puede tardar unos minutos)…';

  @override
  String get bAab => 'Generando el AAB para Play Store…';

  @override
  String get chooseDesignAi => 'Who draws (logo, mockups, screens)';

  @override
  String get chooseDesignAiHint =>
      'Gemini draws well and is free; the engine above writes the code.';

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
    return 'Falló la generación de $kind';
  }

  @override
  String bAndroidReady(String kind) {
    return '$kind listo ✓';
  }

  @override
  String get bStopped => 'Detenido';

  @override
  String get bAppReady => 'App lista ✓';

  @override
  String get bAppUpdated => 'App actualizada ✓';

  @override
  String actWrites(String file) {
    return 'Escribiendo $file';
  }

  @override
  String actEdits(String file) {
    return 'Editando $file';
  }

  @override
  String actReads(String file) {
    return 'Leyendo $file';
  }

  @override
  String get actPubGet => 'Instalando dependencias';

  @override
  String get actAnalyze => 'Comprobando errores';

  @override
  String get forgeTitle => 'Ember está invocando tu app';

  @override
  String forgeFiles(int count) {
    return '$count archivos invocados';
  }

  @override
  String researchingApp(String name) {
    return 'Estudiando “$name” en Google Play…';
  }

  @override
  String get pickReferenceApp => '¿Qué app quieres decir?';

  @override
  String get pickReferenceAppHint =>
      'Ember estudiará sus funciones en Google Play y creará una app que hace lo mismo, con tu propio nombre y diseño.';

  @override
  String get referenceNone => 'Ninguna, continuar sin';

  @override
  String forgeFilesOf(int count, int total) {
    return '$count de $total archivos invocados';
  }

  @override
  String forgeEta(int minutes) {
    return 'quedan unos $minutes min';
  }

  @override
  String forgeEstimated(int minutes) {
    return 'tiempo estimado unos $minutes min';
  }

  @override
  String forgeElapsed(String time) {
    return '$time transcurridos';
  }

  @override
  String get forgeBackground =>
      'Puedes apagar la pantalla o usar otras apps: Ember sigue trabajando y termina la app.';

  @override
  String get buyCredits => 'Comprar créditos API';

  @override
  String get getSubscription => 'Comprar suscripción';

  @override
  String get connectSubscription => 'Conectar mi suscripción';

  @override
  String get accessTitle => 'Acceso y pagos';

  @override
  String get accessPaidOutside =>
      'Los pagos se hacen en el sitio del proveedor, no en Ember.';

  @override
  String subscriptionNotConnected(String name) {
    return '$name no está conectado: inicia sesión con tu suscripción en el PC del Runner.';
  }

  @override
  String connectHowTo(String plan, String command) {
    return 'Ember usa tu propia suscripción $plan, con la sesión iniciada en el PC donde se ejecuta el Runner (sin clave API ni costes extra).\n\n1. En ese PC abre una terminal (o la de Ember).\n2. Ejecuta: $command\n3. Completa el inicio de sesión en el navegador con tu cuenta.\n\nVuelve aquí: el motor se activa en un minuto.';
  }

  @override
  String get connectPersonalNote =>
      'Las suscripciones son personales: úsalas para tus apps, no para crear apps para otras personas.';

  @override
  String get grokNoCli =>
      'Las suscripciones de Grok (SuperGrok) aún no se pueden conectar a otras apps: usa una clave API de xAI.';

  @override
  String subscriptionConnected(String plan) {
    return 'Conectado con tu suscripción $plan: sin clave API ni costes extra.';
  }

  @override
  String haveSubscription(String plan) {
    return '¿Ya tienes $plan?';
  }

  @override
  String subscriptionReadyUse(String engine) {
    return 'Crea con $engine usando tu suscripción, sin comprar créditos API.';
  }

  @override
  String subscriptionConnectFirst(String engine) {
    return 'Conéctala una vez para crear con $engine sin costes extra.';
  }

  @override
  String get useSubscription => 'Usarla';

  @override
  String get bResumeChat =>
      'Continuar la creación interrumpida desde donde se detuvo';

  @override
  String get backToEmber => 'Volver a Ember';

  @override
  String get productsTitle => 'Compras en la app para activar en Google Play';

  @override
  String get productsHint =>
      'Ember crea y activa estos productos en Play Console por ti, con los precios convertidos para cada país.';

  @override
  String get productsActivate => 'Crear y activar en Play Console';

  @override
  String get productsNeedKey =>
      'Primero conecta Google Play (clave de la cuenta de servicio): abre los pasos de publicación.';

  @override
  String get productsBefore =>
      'Antes de activar, una vez por cuenta/app:\n1. Play Console → Configuración → Perfil de pagos (cuenta bancaria, datos fiscales)\n2. Sube el AAB de esta app a pruebas internas (Google exige una versión con facturación)\n3. Usuarios y permisos → da a la cuenta de servicio \"Gestionar pedidos y suscripciones\"';

  @override
  String get productsOpenPayments => 'Perfil de pagos';

  @override
  String get productsUploadFirst => 'Subir AAB';

  @override
  String get productsActive => 'Activo en Google Play ✓';

  @override
  String productPerPeriod(String price, String period) {
    return '$price / $period';
  }

  @override
  String productTrial(int days) {
    return 'prueba gratuita de $days días';
  }

  @override
  String get logoTitle => 'Logo de la app';

  @override
  String get logoHint =>
      'Ember dibuja 6 propuestas. ¿No te convencen? Pulsa “Más logos” las veces que quieras. El que elijas será el icono de la app y el icono y el banner de Play Store.';

  @override
  String get logoDescribe => 'Describe el logo (opcional)';

  @override
  String get logoDescribeHint =>
      'Ej.: escudo azul con una pluma, moderno, sin texto';

  @override
  String get logoGenerate => 'Generar 6 logos';

  @override
  String get logoMore => 'Más logos';

  @override
  String get logoUse => 'Usar este logo';

  @override
  String get logoApplied =>
      'Logo aplicado: se están generando los iconos y la vista previa se actualizará.';

  @override
  String get shotsTitle => 'Capturas para Play Store';

  @override
  String get shotsHint =>
      'Ember abre la app como un teléfono y hace 6 capturas de las pantallas principales (1080×1920), listas para Google Play.';

  @override
  String get shotsPreparing =>
      'Ember está preparando la app para las capturas (un modo demo por pantalla); las fotos empiezan solas al terminar.';

  @override
  String get shotsPreparingChat =>
      'Prepara la app para las capturas de Play Store';

  @override
  String get shotsGenerate => 'Hacer 6 capturas';

  @override
  String get shotsAgain => 'Repetir capturas';

  @override
  String shotsSaved(int count) {
    return '$count capturas guardadas para Google Play.';
  }

  @override
  String get pubTitle => 'Publicar con Ember';

  @override
  String pubAccountAsk(String app) {
    return '¡Hola! Te guío para publicar **$app** en Google Play, paso a paso, y las partes técnicas las hago yo.\n\nPrimera pregunta: ¿ya tienes una **cuenta de desarrollador de Google Play Console**?';
  }

  @override
  String get pubYesHaveIt => 'Sí, la tengo';

  @override
  String get pubNoHowTo => 'No, ¿cómo la creo?';

  @override
  String get pubAccountHow =>
      'Crearla lleva 10 minutos:\n1. Abre la página de registro (botón de abajo) con tu cuenta de Google\n2. Elige **Personal** (u Organización si tienes empresa)\n3. Paga **25 \$ una sola vez**: van a Google, no a Ember\n4. Verifica tu identidad con un documento: Google suele confirmar en 1-2 días\n\nCuando la cuenta esté activa, vuelve aquí.';

  @override
  String get pubNowIHaveIt => 'Hecho, la cuenta está activa';

  @override
  String pubCreateApp(String package) {
    return 'Ahora crea la app en Play Console (solo la primera vez):\n1. Pulsa **Abrir Play Console** abajo y luego **Crear app**\n2. Nombre, idioma predeterminado, tipo **App**, **Gratis**\n3. Marca las declaraciones y pulsa **Crear app**\n\nEl nombre del paquete de esta app es `$package`: Google lo vincula solo en la primera subida.';
  }

  @override
  String get pubDone => 'Hecho';

  @override
  String get pubConnect =>
      'Ahora conecto Ember a Google Play para poder subir tus apps. **Lo hago yo**: creo una clave especial en tu cuenta de Google en este PC (proyecto de Google Cloud, API de Play y clave). Solo sirve para subir apps y se queda en tu dispositivo.';

  @override
  String get pubDoItEmber => 'Hazlo tú, Ember';

  @override
  String get pubManual => 'Prefiero hacerlo a mano';

  @override
  String get pubKeyWorking =>
      'Creando el proyecto de Google Cloud, activando la API de Play y creando la clave (1-2 minutos)…';

  @override
  String get pubInvite =>
      'Clave creada ✓\n\nÚltima conexión: la clave debe tener permiso para publicar en **tu** Play Console.\n1. Pulsa **Abrir Play Console** abajo\n2. Copia la dirección de la página que ves (cualquiera) y **pégala aquí en el chat**\n\nLuego se abre una vez el navegador del PC: entra con la misma cuenta de Google y pulsa **Permitir**. La invitación la envío yo.';

  @override
  String get pubInviteBadLink =>
      'Ese enlace no contiene el número de la cuenta de Play Console. Abre play.google.com/console y pega la dirección de esa página.';

  @override
  String get pubInviteWorking =>
      'Invitando la clave a tu Play Console… si se abre el navegador del PC, entra y pulsa Permitir.';

  @override
  String pubInviteManual(String email) {
    return 'No pude enviar la invitación automáticamente, hagámoslo juntos (2 minutos):\n1. **Abrir Play Console**, luego **Usuarios y permisos** e **Invitar nuevos usuarios**\n2. Pega este email: `$email`\n3. **Permisos de cuenta**: marca versiones, presencia en la tienda, contenido de la app y pedidos\n4. Pulsa **Invitar usuario** y luego **Hecho** aquí';
  }

  @override
  String get pubGraphics =>
      'Conectado a Google Play ✓\n\nPara la ficha, Google pide el **icono 512×512**, el **banner 1024×500** y al menos **2 capturas**. Si aún no los tienes, vuelve a la pantalla de la app: en **Logo de la app** y **Capturas para Play Store** Ember los crea con un toque. Los subo yo automáticamente con la app.';

  @override
  String get pubContinue => 'Continuar';

  @override
  String get pubBackToApp => 'Volver a la app';

  @override
  String get pubUpload =>
      'Ahora la ficha y la subida: escribo título, descripciones y política de privacidad, preparo las respuestas para los formularios de Google y subo el AAB firmado con icono, banner y capturas.\n\nAntes genera el **AAB** desde la pantalla de la app si aún no lo has hecho.';

  @override
  String get pubPrepareUpload => 'Preparar y subir';

  @override
  String get pubFinish =>
      'Perfecto, la app está en Google Play ✓\n\nGoogle aún pide confirmar a mano algunos formularios en Play Console (**Seguridad de los datos**, **Clasificación de contenido**, **Público objetivo**, **Anuncios**, **Acceso a la app**): las respuestas están en la última pantalla. Las cuentas personales nuevas también deben hacer una **prueba cerrada con 12 testers durante 14 días** antes de publicar.\n\n¿Dudas? Pregúntame aquí abajo.';

  @override
  String get pubReviewAnswers => 'Ver las respuestas';

  @override
  String get pubPasteLink => 'Pega aquí el enlace de Play Console…';

  @override
  String get pubAskAnything =>
      'Pregunta a Ember lo que quieras sobre la publicación…';

  @override
  String get adsTitle => 'Anuncios de AdMob';

  @override
  String get adsHint =>
      'La app ya muestra anuncios de PRUEBA de Google (seguros durante el desarrollo) y pide el consentimiento UE. Para ganar dinero, crea los bloques reales en AdMob y pega aquí los ID: Ember los pone en la app.';

  @override
  String get adsSteps =>
      'En AdMob (5 minutos, una vez por app):\n1. Apps → Añadir app → Android → \"¿Está en Google Play?\" (No si aún no se ha publicado) → nombre → Añadir\n2. Copia el ID de la app (ca-app-pub-…~…)\n3. Bloques de anuncios → Añadir → elige cada formato de abajo → Crear → copia su ID (ca-app-pub-…/…)\n4. Tras publicar, vincula la app a su ficha de Play en AdMob y añade app-ads.txt si AdMob lo pide';

  @override
  String get adsOpenAdmob => 'Abrir AdMob';

  @override
  String get adsAppId => 'ID de app de AdMob';

  @override
  String adsUnitId(String format) {
    return 'ID de bloque $format';
  }

  @override
  String get adsApply => 'Poner los ID reales en la app';

  @override
  String get adsInvalid =>
      'Los ID deben ser como ca-app-pub-1234567890123456~1234567890 (app) y ca-app-pub-1234567890123456/1234567890 (bloques).';

  @override
  String get adsChat => 'Poner los ID reales de AdMob';

  @override
  String get pubNothingUploaded =>
      'No se subió nada a Google Play: en la siguiente pantalla pulsa \"Subir a Google Play\" y espera la confirmación, luego vuelve.';

  @override
  String upListing(String languages) {
    return '✓ Ficha de la tienda (título y descripciones): $languages';
  }

  @override
  String get upNoListing =>
      '✗ Ficha no escrita (título y descripciones vacíos)';

  @override
  String get upIcon => '✓ Icono 512×512';

  @override
  String get upNoIcon =>
      '✗ Falta el icono: elige antes un logo en \"Logo de la app\"';

  @override
  String get upFeature => '✓ Banner 1024×500';

  @override
  String get upNoFeature =>
      '✗ Falta el banner: elige antes un logo en \"Logo de la app\"';

  @override
  String upShots(int count) {
    return '✓ $count capturas de teléfono';
  }

  @override
  String get upNoShots =>
      '✗ Faltan capturas: hazlas antes en \"Capturas para Play Store\"';

  @override
  String get upTitle => 'Google Play';

  @override
  String get upHint =>
      'Todo está guardado para esta app. Cambia lo que quieras y envía una nueva versión: Ember crea un nuevo AAB firmado (versión mayor) y lo sube con la ficha, el logo y las capturas.';

  @override
  String get upStateLogo => 'Logo';

  @override
  String upStateShots(int count) {
    return 'Capturas: $count';
  }

  @override
  String get upStateListing => 'Título y descripciones';

  @override
  String get upEditListing => 'Editar título y descripciones';

  @override
  String get upNewVersion => 'Nueva versión en Google Play';

  @override
  String get upBuilding => 'Creando el nuevo AAB firmado…';

  @override
  String get upUploading => 'Subiendo a Google Play…';

  @override
  String get upNeedsSetup =>
      'Primero conecta Google Play y escribe la ficha una vez: abre la guía de publicación.';

  @override
  String get upOpenGuide => 'Guía de publicación';

  @override
  String get pubPasteConsoleLink =>
      'Consejo: abre Play Console una vez y pega aquí la dirección de esa página. A partir de entonces cada botón abrirá directamente **tu** cuenta, sin preguntar cuál.';

  @override
  String get privacyPublicHint =>
      'Pega un enlace público que Google pueda abrir (por ejemplo un gist de GitHub o una página de tu web).';

  @override
  String get privacyLocalWarning =>
      'Esta dirección solo funciona en este ordenador: Google no puede abrirla. Pega un enlace público.';

  @override
  String get consoleLinkLabel => 'Enlace de tu Play Console (pégalo una vez)';

  @override
  String get consoleLinkHint =>
      'Abre Play Console, elige tu cuenta de desarrollador, copia la dirección de esa página y pégala aquí: los botones abrirán directamente tu cuenta y tu app.';

  @override
  String consoleLinkSaved(String id) {
    return 'Guardado ✓ cuenta de desarrollador $id: los botones abren ya tu consola.';
  }

  @override
  String get upStateConnected =>
      'Google Play conectado (clave en este dispositivo)';

  @override
  String get upNeedsKey =>
      'Google Play no está conectado en este dispositivo: abre la guía de publicación y pulsa “Hazlo tú, Ember” para crear la clave (1 minuto).';

  @override
  String get upNeedsListing =>
      'Escribe la ficha una vez: pulsa “Editar título y descripciones”.';

  @override
  String get upConnectPlay => 'Conectar Google Play';

  @override
  String get dsButton => 'Rellenar Seguridad de los datos';

  @override
  String get dsWorking =>
      'Analizando qué recoge la app y rellenando el formulario…';

  @override
  String get dsDone =>
      'Seguridad de los datos enviada a Google Play ✓ — revísala en Play Console → Contenido de la app → Seguridad de los datos y pulsa Enviar.';

  @override
  String get dsNeedsCsv =>
      'Primero exporta el formulario desde Play Console: Contenido de la app → Seguridad de los datos → Exportar a CSV. Guárdalo en Descargas y pulsa otra vez.';

  @override
  String get driveBackup => 'Guardar en Google Drive';

  @override
  String get driveSaving =>
      'Pidiendo permiso a Google y guardando la clave en tu Drive…';

  @override
  String get driveSaved =>
      'Keystore y contraseña guardados en tu Google Drive ✓';

  @override
  String get driveOpenFolder => 'Abrir la carpeta en Drive';

  @override
  String get acAskPrivacy => 'Escribe la política de privacidad de esta app';

  @override
  String get acAskAdmob => '¿Cómo añado anuncios de AdMob a esta app?';

  @override
  String get acAskContent =>
      '¿Qué respondo en Contenido de la app en Play Console?';

  @override
  String get acAssistant => 'Pregunta a Ember sobre esta app';

  @override
  String get acTitle => 'Contenido de la app (Play Console)';

  @override
  String get acHint =>
      'Google hace estas preguntas antes de publicar la app. Ember tiene la respuesta a cada una: cópiala y selecciónala en Play Console.';

  @override
  String get acOpenConsole => 'Abrir Contenido de la app';

  @override
  String get acCopy => 'Copiar respuesta';

  @override
  String get acCopied => 'Copiado';

  @override
  String get acAuto => 'Lo hace Ember';

  @override
  String get paste => 'Pegar';

  @override
  String get ghTitle => 'Guardar en GitHub';

  @override
  String get ghHint =>
      'Guarda una copia del código de esta app en tu propio repositorio de GitHub. La clave de firma, la carpeta build y los archivos de Google nunca se suben.';

  @override
  String get ghToken => 'Token de GitHub';

  @override
  String get ghTokenHelp =>
      'Un token personal con el permiso \"repo\". Se guarda cifrado en este dispositivo y solo se usa para subir esta app.';

  @override
  String get ghGetToken => 'Crear un token en GitHub';

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
  String get ghSave => 'Guardar en GitHub';

  @override
  String get ghSaving => 'Subiendo la app a GitHub…';

  @override
  String get ghOpen => 'Abrir el repositorio';

  @override
  String get ghForgetToken => 'Olvidar el token';

  @override
  String get ghNeedsToken => 'Primero pega un token de GitHub.';

  @override
  String ghCreated(String repo) {
    return 'Repositorio $repo creado y app subida ✓';
  }

  @override
  String ghUpdated(String repo) {
    return 'App subida a $repo ✓';
  }

  @override
  String get acCopyForExtension => 'Copiar para la extensión';

  @override
  String get acFillForMe => 'Rellenar en Play Console';

  @override
  String get acFilling =>
      'Ember está respondiendo a las preguntas en la ventana de Chrome que ha abierto. Míralo y toma el control cuando quieras.';

  @override
  String acFilled(int done, int total) {
    return 'Guardadas $done de $total secciones.';
  }

  @override
  String get acNeedsAppLink =>
      'Ember aún no sabe cuál es esta app en Play Console: ábrela allí, copia la dirección del navegador y pégala en la pantalla de publicación.';

  @override
  String get acAppLink => 'Dirección de esta app en Play Console';

  @override
  String get acLinkNotUnderstood =>
      'Esa dirección no indica una app. Abre la app en Play Console y copia la dirección completa de la barra del navegador.';

  @override
  String get adsAdd => 'Añadir anuncios de AdMob';

  @override
  String get adsAddHint =>
      'Ember pone anuncios en cada pantalla que puede llevarlos, dentro de los límites que mantienen viva una cuenta de AdMob, y usa los anuncios de prueba de Google hasta que pegues tus identificadores.';

  @override
  String get adsAddChat =>
      'Añadir anuncios de AdMob con identificadores de prueba';

  @override
  String get adsYes => 'Sí, poner anuncios';

  @override
  String get adsNo => 'Sin anuncios';

  @override
  String get adsDeclined =>
      'Sin anuncios en esta app. Pídeselos a Ember cuando cambies de idea.';

  @override
  String get adsRemove => 'Quitar los anuncios';

  @override
  String get adsRemoveChat => 'Quitar AdMob de esta app';

  @override
  String get adsAppIdHelp =>
      'El código con la ~ , junto al icono de Android. Es el mismo para todas las unidades.';

  @override
  String get adsUnitHelp =>
      'El código con la / , junto al icono de la tarjeta. Uno distinto para cada formato.';

  @override
  String get checkTitle => 'Ember ha revisado esta app';

  @override
  String get checkAllGood => 'Está todo lo necesario para que la app funcione.';

  @override
  String checkFound(int count) {
    return '$count cosas aún no funcionan. Ember puede arreglar las que tienen el icono de la herramienta, si se lo pides.';
  }

  @override
  String checkFixNow(int count) {
    return 'Arreglar $count';
  }

  @override
  String get checkFixing => 'Arreglando…';

  @override
  String get checkAgain => 'Revisar otra vez';

  @override
  String get checkAskEmber => 'Que lo arregle Ember';

  @override
  String get checkAsked =>
      'Pedido. Ember está trabajando: mira el chat de abajo.';

  @override
  String get previewLoginInBrowser =>
      'Google no permite iniciar sesión dentro de esta ventana, y la sesión del navegador no se traslada aquí. En esta ventana usa email y contraseña; el acceso con Google funciona en el navegador y en el móvil.';

  @override
  String get phoneTitle => 'Tu teléfono';

  @override
  String get phoneHint =>
      'Ember instala la app en el teléfono conectado a este ordenador y la abre. El acceso con Google, las notificaciones y los anuncios solo funcionan de verdad allí.';

  @override
  String phoneRunOn(String name) {
    return 'Abrir en $name';
  }

  @override
  String phoneUnauthorized(String name) {
    return '$name: desbloquéalo y permite la depuración USB';
  }

  @override
  String get phoneBuilding => 'Preparando la app para el teléfono…';

  @override
  String get phoneInstalling => 'Instalando en el teléfono…';

  @override
  String get phoneLookAgain => 'Buscar teléfonos otra vez';

  @override
  String get phoneOpenHere => 'Abrir ahora en el teléfono';

  @override
  String get phoneSameWifi =>
      'Enfoca el código con la cámara del teléfono. El teléfono debe estar en el mismo Wi-Fi que este ordenador.';

  @override
  String get playLanguages => 'Idiomas de la ficha';

  @override
  String get playTranslating => 'Escribiendo la ficha en los demás idiomas…';
}
