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
  String get loginSubtitle => 'Crea apps desde cualquier dispositivo, con IA.';

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
      'Modo desarrollo: Supabase no está configurado, así que entras solo con el correo, a través del ordenador donde funciona Ember.';

  @override
  String get invalidEmail => 'Correo no válido';

  @override
  String get passwordTooShort => 'Al menos 6 caracteres';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get projects => 'Tus apps';

  @override
  String get noProjects => 'Aún no tienes ninguna app. Describe una arriba.';

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
    return '$path cambió en el ordenador donde funciona Ember después de que lo abrieras.';
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
      'Esta dirección solo funciona en este ordenador. Para abrirla desde el teléfono usa la dirección de red del ordenador donde funciona Ember (p. ej. http://192.168.1.20:8787).';

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
  String get aiSettings => 'Añadir una clave';

  @override
  String get apiKeysHint =>
      'Las claves permanecen cifradas en este dispositivo. Cuando las solicitudes pasan por el ordenador donde funciona Ember, las claves pasan por él solo para esa solicitud y nunca se guardan.';

  @override
  String get useRunnerProxy => 'Pasar por el ordenador donde funciona Ember';

  @override
  String get useRunnerProxyHint =>
      'Recomendado. Desactívalo para contactar con los servicios de IA directamente desde este dispositivo.';

  @override
  String get useRunnerProxyWeb =>
      'En el navegador siempre está activo: una página web no puede contactar directamente con los servicios de IA.';

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
    return 'Funciona ($model)';
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
      'Claude Code no está disponible: debe estar instalado y con la sesión iniciada en el ordenador donde funciona Ember.';

  @override
  String get appPromptHint =>
      'Ej.: una app de recetas con fotos, lista de la compra y temporizador…';

  @override
  String get chooseAi => 'Quién escribe el código';

  @override
  String get createApp => 'Crear app';

  @override
  String get openEditor => 'Editor';

  @override
  String get describeYourApp => '¿Qué app quieres crear?';

  @override
  String get describeYourAppHint =>
      'Escribe qué debe hacer y cómo te la imaginas. Ember la construye, la revisa y te la muestra.';

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
  String get appReadyTitle => 'Tu app está lista';

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
      'Archivo para instalar (APK): va al teléfono. Archivo para Google Play (AAB): va a Google Play Console. Los dos están firmados.';

  @override
  String get generateApk => 'Crear el archivo para instalar (APK)';

  @override
  String get generateAab => 'Crear el archivo para Google Play (AAB)';

  @override
  String androidBuilding(String kind) {
    return 'Creando el archivo $kind… la primera vez puede tardar 3-5 minutos.';
  }

  @override
  String get downloadApk => 'Descargar e instalar el archivo (APK)';

  @override
  String get downloadAab => 'Descargar el archivo para Google Play (AAB)';

  @override
  String get apkInstallHint =>
      'El archivo para instalar (APK) está firmado. Si Android lo pide, permite la instalación desde esta fuente.';

  @override
  String get aabHint =>
      'El archivo para Google Play (AAB) está firmado con la clave de subida de esta app y listo para Google Play Console. El número de versión sube solo cada vez.';

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
    return 'no instalado en el ordenador donde funciona Ember ($name)';
  }

  @override
  String get terminalCliHint =>
      'Claude Code, Codex y Gemini usan la sesión iniciada en el ordenador donde funciona Ember. La primera vez sigue las instrucciones de la terminal para iniciar sesión.';

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
      '1. Abre **Google Cloud**: creas una **clave de cuenta de servicio**, una sola vez para todas tus apps.\n2. Activa **Google Play Android Developer API**.\n3. Ve a **Cuentas de servicio** y pulsa **Crear**.\n4. Abre **Claves** → **Añadir clave** → **JSON**. Se descarga un archivo.\n5. En **Play Console** ve a **Usuarios y permisos** → **Invitar a nuevos usuarios**.\n6. Pega el correo de la cuenta de servicio y concede los permisos de **publicación**.\n7. Abre el archivo JSON descargado y **pega aquí todo su contenido**.\n8. Listo: la clave queda cifrada en este dispositivo y solo se usa para las subidas.';

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
    return 'Subida. Versión $version en el canal «$track». $draft';
  }

  @override
  String get playDraftNote =>
      'Como la app nunca se ha publicado, Google la guardó como borrador: completa los pasos de abajo y pulsa «Enviar a revisión» en Play Console.';

  @override
  String get playReviewNotSent =>
      'Google no pudo enviar los cambios a revision automaticamente. Estan guardados: abre Play Console y pulsa \"Enviar a revision\" para publicar.';

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
      'El asistente gratuito aún no está activo: falta la clave de Gemini en el ordenador donde funciona Ember.';

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
  String get bNoErrors => 'Sin errores';

  @override
  String bErrorsFound(int count) {
    return '$count errores encontrados';
  }

  @override
  String get bClaudeApplying => 'Claude Code está aplicando el cambio…';

  @override
  String get bClaudeBuilding => 'Claude Code está creando la app en el PC…';

  @override
  String statusBuilding(String progress) {
    return 'Creando… $progress archivos';
  }

  @override
  String get bClaudeFailed =>
      'Claude Code no terminó la app: revisa el registro.';

  @override
  String resumeFromHere(int count) {
    return 'Sigue desde aquí ($count archivos)';
  }

  @override
  String get startOver => 'Empezar de nuevo';

  @override
  String bClaudeStoppedCarryOn(int count) {
    return 'Se detuvo con $count archivos ya escritos: sigo adelante y arreglo lo que falta.';
  }

  @override
  String get bWebBuilding =>
      'Compilando la app para la web (unos 30 segundos)…';

  @override
  String bWebFailed(String log) {
    return 'La compilación web falló:\n$log';
  }

  @override
  String get bApk =>
      'Creo el archivo para instalar (APK). La primera vez puede tardar unos minutos…';

  @override
  String get bAab => 'Creo el archivo para Google Play (AAB)…';

  @override
  String get chooseDesignAi => 'Quién dibuja (logo, bocetos, pantallas)';

  @override
  String get chooseDesignAiHint =>
      'Elige quién dibuja: cada uno hace 2 bocetos y los 5 logos se reparten entre ellos. El motor de arriba escribe el código.';

  @override
  String get bLookingAtModel => 'Miro la app que hay que copiar…';

  @override
  String get bIpa => 'Creo la app para iPhone (IPA)…';

  @override
  String get nameTitle => '¿Cómo se llama tu app?';

  @override
  String get nameHint =>
      'Este nombre va en Play Store, en la política de privacidad y dentro del nombre del paquete, que después ya no se puede cambiar.';

  @override
  String get nameYourOwn => 'O escribe tu propio nombre';

  @override
  String get nameMore => 'Otros nombres';

  @override
  String get nameUse => 'Usar este nombre';

  @override
  String bReferenceShots(int count) {
    return 'Guardadas $count pantallas de la app que hay que copiar: el motor la ve, no solo la lee';
  }

  @override
  String get bReferenceShotsFailed =>
      'No he podido descargar las pantallas de la app que hay que copiar: sigo solo con la descripción';

  @override
  String bMissingTopics(String topics) {
    return 'Falta respecto a la app que hay que copiar: $topics. Lo añado ahora…';
  }

  @override
  String get bIosReady => 'App para iPhone lista';

  @override
  String get bIosFailed => 'No se ha podido crear la app para iPhone';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iPhone';

  @override
  String get iosTitle => 'App para iPhone';

  @override
  String get iosHint =>
      'La misma app para iPhone y iPad: mismo nombre, mismas pantallas, mismos anuncios. El archivo (IPA) va a App Store Connect.';

  @override
  String get iosNeedsMac =>
      'La app para iPhone solo se puede crear en un Mac. Guarda la app en GitHub, abre Ember en el Mac y créala allí. Todo lo demás lo haces desde aquí.';

  @override
  String get iosBuild => 'Crear app para iPhone';

  @override
  String get iosBuilding => 'Estoy creando la app para iPhone…';

  @override
  String get iosReady =>
      'App para iPhone lista. Está firmada con tu cuenta de Apple y puede ir a App Store Connect.';

  @override
  String get iosAppleAccount =>
      'Cuenta Apple Developer: 99 dólares al año, pagados a Apple.';

  @override
  String get ascTitle => 'Enviar al App Store';

  @override
  String get ascHint =>
      'Ember escribe en Apple lo mismo que escribe en Google: título, descripción, novedades, enlace de privacidad y las respuestas sobre privacidad, en todos los idiomas de tu ficha.';

  @override
  String get ascKeyHelp =>
      '1. Abre App Store Connect y ve a Usuarios y acceso → Integraciones → App Store Connect API.\n2. Pulsa + y elige el rol App Manager.\n3. Descarga el archivo .p8. Apple solo te deja descargarlo una vez.';

  @override
  String get ascKeyId => 'Key ID';

  @override
  String get ascIssuerId => 'Issuer ID';

  @override
  String get ascPrivateKey => 'Contenido del archivo AuthKey_….p8';

  @override
  String get ascUploadBuild =>
      'Enviar también el archivo para iPhone (hace falta un Mac)';

  @override
  String get ascSubmit =>
      'Enviar a la revisión de Apple cuando todo esté listo';

  @override
  String get ascPublish => 'Publicar en el App Store';

  @override
  String get ascWorking => 'Estoy hablando con App Store Connect…';

  @override
  String ascDone(String version, String languages) {
    return 'Hecho en Apple: versión $version, idiomas: $languages';
  }

  @override
  String get ascOpen => 'Abrir App Store Connect';

  @override
  String get ascForget => 'Olvidar la clave de Apple';

  @override
  String get ascManual =>
      'En Apple quedan a mano: las capturas (tamaños de iPhone), las preguntas sobre la edad, el precio y los países.';

  @override
  String bAndroidFailed(String kind) {
    return 'Falló la generación de $kind';
  }

  @override
  String bAndroidReady(String kind) {
    return 'Archivo $kind listo';
  }

  @override
  String get bStopped => 'Detenido';

  @override
  String get bAppReady => 'App lista';

  @override
  String get bReviewStart => 'Otras IA están revisando la app por su cuenta…';

  @override
  String get bReviewClean => 'Los revisores no encontraron nada que corregir.';

  @override
  String bReviewFound(int count) {
    return '$count problemas encontrados por los revisores: los estoy corrigiendo.';
  }

  @override
  String get bAppUpdated => 'App actualizada';

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
  String get forgeTitle => 'Ember está creando tu app';

  @override
  String forgeFiles(int count) {
    return '$count archivos escritos';
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
    return '$count de $total archivos escritos';
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
    return '$name no está conectado: inicia sesión con tu suscripción en el ordenador donde funciona Ember.';
  }

  @override
  String connectHowTo(String plan, String command) {
    return '1. Ve al ordenador donde funciona Ember y abre una terminal (también sirve la de Ember).\n2. Escribe: $command\n3. Completa el inicio de sesión en el navegador con tu cuenta de $plan: sin clave API ni costes extra.\n4. Vuelve aquí: en un minuto estará listo para usar.';
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
      '1. Antes de activar, abre Play Console. Estos pasos se hacen una sola vez por cuenta y por app.\n2. Ve a Configuración → Perfil de pagos y añade la cuenta bancaria y los datos fiscales.\n3. Sube el archivo para Google Play (AAB) de esta app a pruebas internas: Google pide una versión con pagos.\n4. En Usuarios y permisos, da a la cuenta de servicio \"Gestionar pedidos y suscripciones\".';

  @override
  String get productsOpenPayments => 'Perfil de pagos';

  @override
  String get productsUploadFirst => 'Subir el archivo para Google Play (AAB)';

  @override
  String get productsActive => 'Activo en Google Play';

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
      '1. Ahora conecto Ember a Google Play para poder subir tus apps.\n2. **Lo hago yo**: creo una clave especial en tu cuenta de Google, en este PC.\n3. Para ello preparo un proyecto de Google Cloud, la API de Play y la clave.\n4. La clave solo sirve para subir apps y se queda en tu dispositivo.';

  @override
  String get pubDoItEmber => 'Hazlo tú, Ember';

  @override
  String get pubManual => 'Prefiero hacerlo a mano';

  @override
  String get pubKeyWorking =>
      'Creando el proyecto de Google Cloud, activando la API de Play y creando la clave (1-2 minutos)…';

  @override
  String get pubInvite =>
      'Clave creada.\n\nÚltima conexión: la clave debe tener permiso para publicar en **tu** Play Console.\n1. Pulsa **Abrir Play Console** abajo\n2. Copia la dirección de la página que ves (cualquiera) y **pégala aquí en el chat**\n\nLuego se abre una vez el navegador del PC: entra con la misma cuenta de Google y pulsa **Permitir**. La invitación la envío yo.';

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
      'Conectado a Google Play.\n\nPara la ficha, Google pide el **icono 512×512**, el **banner 1024×500** y al menos **2 capturas**. Si aún no los tienes, vuelve a la pantalla de la app: en **Logo de la app** y **Capturas para Play Store** Ember los crea con un toque. Los subo yo automáticamente con la app.';

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
      '1. Tu app está en Google Play. Quedan algunos formularios: abre **Play Console**.\n2. Confirma a mano **Seguridad de los datos**, **Clasificación de contenido**, **Público objetivo**, **Anuncios** y **Acceso a la app**.\n3. Copia las respuestas de la última pantalla: ya están listas.\n4. Si tu cuenta personal es nueva, haz una **prueba cerrada con 12 testers durante 14 días** antes de publicar.\n5. ¿Dudas? Pregúntame aquí abajo.';

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
      '1. Abre AdMob. Son 5 minutos, una vez por app.\n2. Ve a Apps → Añadir app → Android.\n3. En \"¿Está en Google Play?\" responde No si aún no se ha publicado.\n4. Escribe el nombre y pulsa Añadir.\n5. Copia el ID de la app (ca-app-pub-…~…).\n6. Ve a Bloques de anuncios → Añadir y elige un formato de la lista de abajo.\n7. Pulsa Crear y copia su ID (ca-app-pub-…/…). Repite con cada formato.\n8. Tras publicar, vincula la app a su ficha de Play Store en AdMob.\n9. Añade app-ads.txt si AdMob lo pide.';

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
  String get upBuilding => 'Creo el nuevo archivo para Google Play (AAB)…';

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
    return 'Cuenta de desarrollador $id guardada: los botones abren ya tu consola.';
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
      'Seguridad de los datos enviada a Google Play — revísala en Play Console → Contenido de la app → Seguridad de los datos y pulsa Enviar.';

  @override
  String get dsNeedsCsv =>
      'Primero exporta el formulario desde Play Console: Contenido de la app → Seguridad de los datos → Exportar a CSV. Guárdalo en Descargas y pulsa otra vez.';

  @override
  String get driveBackup => 'Guardar en Google Drive';

  @override
  String get driveSaving =>
      'Pidiendo permiso a Google y guardando la clave en tu Drive…';

  @override
  String get driveSaved => 'Keystore y contraseña guardados en tu Google Drive';

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
  String get ghSavedOn => 'Guardado en GitHub';

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
  String get ghRestoreTitle => 'Abrir una app guardada en GitHub';

  @override
  String get ghRestoreHint =>
      'Las apps que guardaste en GitHub vuelven a este ordenador con todo lo que tenían. Así trabajas en la misma app desde Windows y desde el Mac.';

  @override
  String get ghRestoreLoad => 'Mostrar mis apps';

  @override
  String get ghRestoreNone =>
      'En esta cuenta de GitHub aún no hay ninguna app guardada por Ember.';

  @override
  String get ghRestoreHere => 'Ya está en este ordenador';

  @override
  String get ghRestoreAction => 'Desde GitHub';

  @override
  String get refresh => 'Actualizar';

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
    return 'Repositorio $repo creado y app subida';
  }

  @override
  String ghUpdated(String repo) {
    return 'App subida a $repo';
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

  @override
  String get logoDelete => 'Eliminar';

  @override
  String get logoDeleted => 'Logo eliminado';

  @override
  String get logoDropHint => 'Arrastra aquí un logo para 5 variantes';

  @override
  String get logoVariantsOf => 'Variantes de este logo';

  @override
  String get playUpdateListingOnly => 'Actualizar solo la ficha';

  @override
  String get playUpdateListingOnlyHint =>
      'Para una app ya en Google Play: textos, todos los idiomas y gráficos sin una nueva versión.';

  @override
  String get playTranslationsStale =>
      'El texto cambió: los otros idiomas aún tienen el anterior.';

  @override
  String get playTranslateAgain => 'Traducir de nuevo';

  @override
  String get playLanguageIncluded => 'Publicar este idioma en Google Play';

  @override
  String get playLanguageNotTranslated =>
      'Aún no traducido: se escribe al guardar con este idioma activo.';

  @override
  String get playListingSaved =>
      'Ficha guardada: no hace falta generar. Cambia el texto solo si quieres y sube.';

  @override
  String get playRewriteWithAi => 'Reescribir con IA';

  @override
  String get historyTitle => 'Historial';

  @override
  String get historyNewApp => 'Nueva app';

  @override
  String get historyDrafts => 'Borradores';

  @override
  String get historyToday => 'Hoy';

  @override
  String get historyYesterday => 'Ayer';

  @override
  String get historyLast7Days => 'Últimos 7 días';

  @override
  String get historyOlder => 'Más antiguas';

  @override
  String get historyEmpty =>
      'Aún no hay nada. Las apps que empiezas y los borradores que escribes aparecen aquí.';

  @override
  String get brandTagline => 'CREADOR DE APPS';

  @override
  String get showSecret => 'Mostrar';

  @override
  String get hideSecret => 'Ocultar';

  @override
  String get ok => 'Aceptar';

  @override
  String get details => 'Detalles';

  @override
  String get more => 'Más';

  @override
  String get advanced => 'Avanzado';

  @override
  String get done => 'Hecho';

  @override
  String madeWith(String engine) {
    return 'Creada con $engine · Opciones';
  }

  @override
  String get buildOptionsTitle => 'Quién crea tu app';

  @override
  String get homeMenu => 'Otras formas de empezar';

  @override
  String get emptyProject => 'Proyecto vacío';

  @override
  String get settings => 'Ajustes';

  @override
  String get hubNextSteps => 'Siguientes pasos';

  @override
  String get hubTest => 'Pruébala en tu teléfono';

  @override
  String get hubTestHint => 'Ábrela con un código QR o instálala';

  @override
  String get hubImages => 'Icono e imágenes';

  @override
  String get hubImagesHint => 'El logo y las capturas para la tienda';

  @override
  String get hubChecks => 'Revisiones';

  @override
  String get hubChecksHint => 'Lo que encontraron Ember y los revisores';

  @override
  String hubChecksCount(int count) {
    return '$count por arreglar';
  }

  @override
  String get hubPlay => 'Google Play';

  @override
  String get hubPlayHint => 'Publica o actualiza en Android';

  @override
  String get hubAppStore => 'App Store';

  @override
  String get hubAppStoreHint => 'Publica para iPhone';

  @override
  String get hubMore => 'Más';

  @override
  String get hubMoreHint => 'Copia de seguridad, anuncios, compras, el código';

  @override
  String get techDetails => 'Detalles técnicos';

  @override
  String get changeHint => '¿Qué quieres cambiar?';

  @override
  String get installFileTitle => 'Archivo para instalar (APK)';

  @override
  String get installFileHint =>
      'Un archivo que puedes enviar a cualquier teléfono Android e instalar.';

  @override
  String get storeFileTitle => 'Archivo para Google Play (AAB)';

  @override
  String get storeFileHint =>
      'Solo hace falta si subes a mano a Play Console: Ember lo prepara al publicar.';

  @override
  String get makeFile => 'Preparar el archivo';

  @override
  String get openCodeTitle => 'El código';

  @override
  String get openCodeHint =>
      'Abre el editor para leer o cambiar los archivos a mano.';

  @override
  String get backToApp => 'Volver a la app';

  @override
  String designChosen(String name) {
    return 'Diseño: $name';
  }

  @override
  String get reviewFixLabel => 'Corrección de los revisores';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get themeSystem => 'Como el dispositivo';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsAi => 'Inteligencias artificiales';

  @override
  String get settingsAccounts => 'Cuentas conectadas';

  @override
  String get settingsAccountsHint =>
      'Se conectan la primera vez que hacen falta, desde la página de la app. Aquí puedes verlas y desconectarlas.';

  @override
  String accountConnected(String name) {
    return '$name: conectada';
  }

  @override
  String accountNotConnected(String name) {
    return '$name: sin conectar';
  }

  @override
  String get disconnect => 'Desconectar';

  @override
  String get runnerAddress => 'Dónde funciona Ember';

  @override
  String get runnerAddressHint =>
      'La dirección del ordenador que crea tus apps (el Runner). Cámbiala solo si te lo han indicado.';

  @override
  String signedInAs(String email) {
    return 'Sesión iniciada como $email';
  }

  @override
  String get reviewersTitle => 'Revisores de la app';

  @override
  String get reviewersHint =>
      'Cuando una app está terminada, estos modelos la leen por su cuenta y dicen qué es falso, qué falta y qué no funciona; las correcciones vuelven solas a quien escribió la app. Se configuran una vez y sirven para todas las apps.';

  @override
  String get aiKeysTitle => 'Claves';

  @override
  String plLanguagesOn(int count) {
    return 'Idiomas: $count activos';
  }

  @override
  String get plManage => 'Gestionar';

  @override
  String get plLanguagesHint =>
      'Activa un idioma para publicar la ficha también en él. Toca un idioma para leer o corregir su texto.';

  @override
  String get plSearchLanguage => 'Buscar un idioma';

  @override
  String get plNoLanguageFound => 'Ningún idioma con ese nombre.';

  @override
  String get plEnglish => 'Inglés';

  @override
  String get plMainLanguage => 'Idioma principal, siempre activo';

  @override
  String get plLangReady => 'Traducido';

  @override
  String get plLangOld => 'Texto antiguo';

  @override
  String get plLangMissing => 'Por escribir';

  @override
  String get plLangWriting => 'Escribiendo…';

  @override
  String get plGenerating => 'Ember está escribiendo la ficha…';

  @override
  String get plFeeTitle => 'Google pide 25 \$, una sola vez';

  @override
  String get plAiBadAnswer =>
      'La IA dio una respuesta que Ember no puede leer. Inténtalo de nuevo.';

  @override
  String get plNoAi =>
      'Aún no hay ninguna IA configurada: añade una en Ajustes.';

  @override
  String get plPrivacyLocalOnly =>
      'La política de privacidad está guardada solo en este ordenador: Google no puede abrirla. Conecta GitHub en Ember o pega abajo un enlace tuyo.';

  @override
  String plPrivacyNotPublished(String error) {
    return 'Política de privacidad no publicada: $error. El resto de la ficha se guardó; pega abajo un enlace tuyo.';
  }

  @override
  String get asConnTitle => 'Tu clave de Apple';

  @override
  String get asConnHint =>
      'Ember la usa para publicar por ti. La guardas una sola vez y sirve para todas tus apps.';

  @override
  String asKeySaved(String file) {
    return 'Clave guardada: $file';
  }

  @override
  String get asChangeKey => 'Cambiar clave';

  @override
  String get asTeamId => 'Team ID (opcional)';

  @override
  String get asTeamIdHelp =>
      'Sirve para firmar la app de iPhone. Si lo dejas vacío, Ember lo lee de Apple con tu clave.';

  @override
  String get asP8KeepHelp =>
      'Déjalo vacío para conservar la clave ya guardada.';

  @override
  String get asLoadP8 => 'Cargar archivo .p8';

  @override
  String get asSaveKey => 'Guardar clave';

  @override
  String get asP8FileType => 'Clave de Apple (.p8)';

  @override
  String get asVerify => 'Comprobar la conexión';

  @override
  String get asVerifyOk => 'La conexión funciona';

  @override
  String get asVerifyOkReached =>
      'La conexión funciona: Ember ha llegado a App Store Connect';

  @override
  String asVerifyTeam(String team) {
    return 'Team $team';
  }

  @override
  String get asBadKeyId =>
      'Este Key ID no es válido. Es el código corto que está junto a la clave, por ejemplo Z47GM3ZDZ6.';

  @override
  String get asBadIssuerId =>
      'Este Issuer ID no es válido. Es el código largo que está arriba en la página Claves.';

  @override
  String get asBadP8 =>
      'Esto no es el contenido de la clave. Pega todo el archivo AuthKey_….p8, desde la línea -----BEGIN PRIVATE KEY----- hasta -----END PRIVATE KEY-----. El nombre del archivo solo no basta.';

  @override
  String asP8ReadFailed(String error) {
    return 'Ember no ha podido leer el archivo .p8: $error';
  }

  @override
  String get asSaveKeyFirst =>
      'Guarda primero tu clave de Apple: Key ID, Issuer ID y el archivo .p8.';

  @override
  String get asFillTitle => 'Lo que Ember rellena por ti';

  @override
  String get asFillHint =>
      'Al publicar, Ember pone por su cuenta la clasificación por edad (4+), la declaración sobre el cifrado y las respuestas de privacidad. Si las eliges aquí, también la categoría, el precio y las capturas.';

  @override
  String get asCategory => 'Categoría del App Store';

  @override
  String get asCategoryNone => 'No poner';

  @override
  String get asFree => 'App gratis (en todos los países)';

  @override
  String get asScreenshots => 'Crear y subir las capturas de iPhone y iPad';

  @override
  String get asScreenshotsHelp =>
      'Se toman de la vista previa web. La app necesita el \"modo capturas\".';

  @override
  String get asReviewTitle => 'Datos para la revisión de Apple (opcionales)';

  @override
  String get asReviewEmail => 'Correo de contacto';

  @override
  String get asReviewEmailHelp =>
      'Déjalo vacío para usar el correo de tu cuenta.';

  @override
  String get asMarketingUrl => 'Tu sitio web (Marketing URL)';

  @override
  String get asMarketingUrlHelp =>
      'AdMob busca aquí el archivo app-ads.txt. Se guarda para todas tus apps.';

  @override
  String get asReviewPhone => 'Teléfono de contacto';

  @override
  String get asReviewPhoneHelp =>
      'Apple lo exige, por ejemplo +39 333 1234567. Solo lo ve quien revisa la app. Ember lo recuerda para tus próximas apps.';

  @override
  String get asReviewNotes => 'Notas para quien revisa la app';

  @override
  String get asDemoUser => 'Cuenta de prueba (si la app pide iniciar sesión)';

  @override
  String get asDemoPass => 'Contraseña de prueba';

  @override
  String get asChecksTitle => 'Antes de enviar';

  @override
  String get asChecksNone => 'Ningún problema para Apple.';

  @override
  String asChecksBlock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problemas impiden el envío.',
      one: '1 problema impide el envío.',
    );
    return '$_temp0';
  }

  @override
  String get asChecksWarn => 'Solo avisos: se puede enviar.';

  @override
  String get asBlocks => 'Impide el envío';

  @override
  String get asWarning => 'Aviso';

  @override
  String asFixDone(String message) {
    return 'Arreglado: $message';
  }

  @override
  String asFixFailed(String message) {
    return 'No arreglado: $message';
  }

  @override
  String asCanClose(int minutes) {
    return 'Puedes cerrar esta página: Ember sigue por su cuenta y envía la app a revisión en cuanto Apple termine ($minutes min).';
  }

  @override
  String asRunningFor(int minutes) {
    return 'En marcha desde hace $minutes min.';
  }

  @override
  String get asDoneExport => 'Declaración sobre el cifrado puesta';

  @override
  String get asDoneAge => 'Clasificación por edad rellenada';

  @override
  String get asDoneCategory => 'Categoría puesta';

  @override
  String get asDoneReview => 'Datos para la revisión guardados';

  @override
  String get asDoneFree => 'Precio: gratis en todos los países';

  @override
  String get asDonePrivacy => 'Respuestas de privacidad rellenadas';

  @override
  String asDoneShots(int count) {
    return 'Capturas subidas: $count';
  }

  @override
  String get asCatUtilities => 'Utilidades';

  @override
  String get asCatProductivity => 'Productividad';

  @override
  String get asCatBusiness => 'Negocios';

  @override
  String get asCatEducation => 'Educación';

  @override
  String get asCatEntertainment => 'Entretenimiento';

  @override
  String get asCatFinance => 'Finanzas';

  @override
  String get asCatFoodAndDrink => 'Comida y bebida';

  @override
  String get asCatHealthAndFitness => 'Salud y forma física';

  @override
  String get asCatLifestyle => 'Estilo de vida';

  @override
  String get asCatMusic => 'Música';

  @override
  String get asCatNavigation => 'Navegación';

  @override
  String get asCatNews => 'Noticias';

  @override
  String get asCatPhotoAndVideo => 'Foto y vídeo';

  @override
  String get asCatReference => 'Referencia';

  @override
  String get asCatShopping => 'Compras';

  @override
  String get asCatSocial => 'Redes sociales';

  @override
  String get asCatSports => 'Deportes';

  @override
  String get asCatTravel => 'Viajes';

  @override
  String get asCatWeather => 'Tiempo';

  @override
  String get asCatBooks => 'Libros';

  @override
  String get asCatDeveloperTools => 'Herramientas para desarrolladores';

  @override
  String get asCatGraphicsAndDesign => 'Gráficos y diseño';

  @override
  String get asCatGames => 'Juegos';

  @override
  String get reviewTitle => 'Revisión de la app';

  @override
  String get reviewHintNone =>
      'Haz que varias inteligencias artificiales revisen la app terminada: cada una la lee por su cuenta y dice qué es falso, qué falta y qué no funciona. Añade al menos un revisor aquí abajo.';

  @override
  String reviewHintReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count revisores listos',
      one: '1 revisor listo',
    );
    return '$_temp0. Cada uno lee la app por su cuenta; lo que ve más de uno sube al principio de la lista.';
  }

  @override
  String get reviewReviewers => 'Revisores';

  @override
  String get reviewReading => 'Los revisores están leyendo la app…';

  @override
  String reviewNoAnswer(String name) {
    return '$name: no responde';
  }

  @override
  String get reviewNothingFound =>
      'Los revisores no han encontrado ningún problema.';

  @override
  String get reviewAddReviewer => 'Añadir un revisor';

  @override
  String get reviewRun => 'Revisar la app';

  @override
  String get reviewKeySavedMask => '•••••• (clave guardada)';

  @override
  String get reviewPasteKeyHint => 'pega aquí la clave';

  @override
  String get reviewRemoveKey => 'Quitar la clave';

  @override
  String get reviewFixedRecheck => 'Corregido: hay que revisarlo de nuevo';

  @override
  String get reviewFixing => 'Corrigiendo…';

  @override
  String get reviewFix => 'Corregir';

  @override
  String get reviewPasteKeyFirst => 'Pega primero la clave.';

  @override
  String get reviewKeySaved => 'Clave guardada.';

  @override
  String get reviewKeyRemoved => 'Clave eliminada.';

  @override
  String needsYouTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hacen falta $count cosas de tu parte',
      one: 'Hace falta una cosa de tu parte',
    );
    return '$_temp0';
  }

  @override
  String get needsYouHint =>
      'Ember no puede hacerlas solo (un inicio de sesión, una clave, una cuenta). Hazlas y toca \"Hecho\": sigue desde donde se detuvo.';

  @override
  String get needsYouIgnore => 'Ignorar';

  @override
  String listAnd(String first, String last) {
    return '$first y $last';
  }

  @override
  String panelDownOne(String names) {
    return '$names no está funcionando';
  }

  @override
  String panelDownMany(String names) {
    return '$names no están funcionando';
  }

  @override
  String get panelNoneLeft =>
      'No queda ninguna IA: no se puede dibujar ni revisar nada. Reintenta o cierra.';

  @override
  String get panelOneLeft =>
      'Solo queda 1 IA: dibujará sola y nadie revisará su trabajo.';

  @override
  String panelSomeLeft(int count) {
    return 'Quedan $count IA que trabajan juntas y se revisan entre sí.';
  }

  @override
  String panelProceedWithout(String name) {
    return 'Seguir sin $name';
  }

  @override
  String panelProceedWithoutMany(int count) {
    return 'Seguir sin $count IA';
  }

  @override
  String get panelAllOk => 'Todas las IA funcionan';

  @override
  String get panelHoldNote =>
      'Nada empieza hasta que tú decidas. Si es un problema de inicio de sesión o de clave, arréglalo ahora y pulsa Reintentar: cuando vuelva a verde se sigue con todas.';

  @override
  String get panelRetryAll => 'Reintentar todas';

  @override
  String get panelContinueAll => 'Seguir con todas';

  @override
  String get panelTrying => 'Probando…';

  @override
  String get pingNoAnswer => 'sin respuesta';

  @override
  String get pingTimeout => 'no responde (25 s)';

  @override
  String get mockupRefined => 'rehecho con las notas';

  @override
  String mockupPanelNotes(String notes) {
    return 'Notas de la mesa: $notes';
  }

  @override
  String mockupAgreeing(int count) {
    return 'Las $count IA están eligiendo juntas las 8 direcciones…';
  }

  @override
  String mockupComparing(int count, int mockups) {
    return 'Los $count diseñadores están comparando los $mockups bocetos…';
  }

  @override
  String get mockupRedrawing =>
      'Cada diseñador está rehaciendo su boceto con las notas de los demás…';

  @override
  String get mockupInvalid => 'El modelo no ha devuelto un boceto válido';

  @override
  String get assistantSignIn => 'Inicia sesión para usar el asistente';

  @override
  String get imagesLabel => 'Imágenes';

  @override
  String assistantImageTooLarge(String name) {
    return '$name: imagen demasiado grande (máx. 3,5 MB)';
  }

  @override
  String get assistantAddImage => 'Añadir una imagen';

  @override
  String get assistantFixApp => 'Arreglar la app con esta petición';

  @override
  String get findPrevious => 'Resultado anterior';

  @override
  String get findNext => 'Resultado siguiente';

  @override
  String get toggleReplace => 'Mostrar u ocultar Reemplazar';

  @override
  String get clearConsole => 'Vaciar la consola';

  @override
  String get stopAutoRebuild => 'Dejar de recompilar al guardar';

  @override
  String get deviceTablet => 'Tableta';

  @override
  String get deviceDesktop => 'Ordenador';

  @override
  String get checkEmailToConfirm =>
      'Revisa tu correo para confirmar el registro.';

  @override
  String get offlineTitle => 'Ember no está encendido';

  @override
  String get offlineHint =>
      'Inicia Ember en tu ordenador y pulsa Reintentar. No hace falta iniciar sesión.';

  @override
  String get flowDescribe => 'Describe';

  @override
  String get flowStyle => 'Elige el estilo';

  @override
  String get flowName => 'Ponle nombre';

  @override
  String get flowBuild => 'Ember la crea';

  @override
  String get homeEyebrow => 'De una idea a una app';

  @override
  String get subsTitle => 'Tus suscripciones de Claude, ChatGPT, Gemini y Qwen';

  @override
  String get subsHint =>
      'Ember crea con las suscripciones que ya pagas. Inicias sesión una vez en este ordenador y se mantiene: sin claves, sin coste extra.';

  @override
  String get subsConnect => 'Conectar';

  @override
  String get subsOpenWindow => 'Abrir la ventana de acceso';

  @override
  String subsLoginOpened(String name) {
    return 'Se abrió una ventana en este ordenador: inicia sesión en $name allí y vuelve. Ember lo detecta solo.';
  }

  @override
  String get fxTitle => 'Fábrica';

  @override
  String get fxNavOverview => 'Resumen';

  @override
  String get fxNavNew => 'Nuevo lote';

  @override
  String get fxNavNeeds => 'Te necesita';

  @override
  String get fxNavLinks => 'Conexiones';

  @override
  String get fxPause => 'Pausa';

  @override
  String get fxResume => 'Reanudar';

  @override
  String get fxLoading => 'Cargando la fábrica…';

  @override
  String get fxLess => 'Menos';

  @override
  String get fxMore => 'Más';

  @override
  String get fxStageCreate => 'Crear el proyecto';

  @override
  String get fxStageCode => 'Escribir la app';

  @override
  String get fxStageVerify => 'Revisar el código';

  @override
  String get fxStagePreview => 'Preparar la vista previa';

  @override
  String get fxStageLogo => 'Dibujar el logo';

  @override
  String get fxStageListing => 'Escribir los textos de la tienda';

  @override
  String get fxStageShots => 'Hacer las capturas';

  @override
  String get fxStageAndroid => 'Crear el archivo de Android';

  @override
  String get fxStagePlay => 'Subir a Google Play (borrador, pruebas)';

  @override
  String get fxStageIos => 'Crear la app para iPhone';

  @override
  String get fxStageAppStore => 'Subir a App Store (TestFlight)';

  @override
  String get fxStagePending => 'Sin empezar';

  @override
  String get fxStageSkipped => 'Omitido';

  @override
  String get fxStatusQueued => 'En espera';

  @override
  String get fxStatusRunning => 'Trabajando';

  @override
  String get fxStatusNeedsYou => 'Te necesita';

  @override
  String get fxStatusDone => 'Lista';

  @override
  String get fxStatusFailed => 'Fallida';

  @override
  String get fxStatusCancelled => 'Cancelada';

  @override
  String fxStagesDone(int done, int total) {
    return '$done de $total pasos hechos';
  }

  @override
  String get fxHeadDone => 'Lista';

  @override
  String get fxHeadNeedsYou => 'Te espera';

  @override
  String fxHeadFailed(String stage) {
    return 'Falló: $stage';
  }

  @override
  String fxHeadRunning(String stage) {
    return 'Ahora: $stage';
  }

  @override
  String fxHeadQueued(String stage) {
    return 'Espera su turno: $stage';
  }

  @override
  String fxHeadWaitingTomorrow(String stage) {
    return 'Lista, espera el límite diario: $stage';
  }

  @override
  String fxWaitsUntil(String when) {
    return 'Espera hasta $when';
  }

  @override
  String get fxNeedPlayAppTitle => 'Crea la app en Google Play Console';

  @override
  String get fxNeedPlayAppDetail =>
      '1. Abre Google Play Console y pulsa “Crear app”.\n2. Pega el nombre y elige el idioma, “App” y “Gratis”.\n3. Acepta las declaraciones y pulsa “Crear app”.\n4. Vuelve aquí y pulsa “Hecho, continuar”: la subida sigue sola.';

  @override
  String get fxNeedAppleAppTitle => 'Crea la app en App Store Connect';

  @override
  String get fxNeedAppleAppDetail =>
      '1. Abre App Store Connect, ve a “Apps” y pulsa “+”, luego “Nueva app”.\n2. Pega el nombre, el Bundle ID y el SKU de abajo.\n3. Pulsa “Crear”.\n4. Vuelve aquí y pulsa “Hecho, continuar”.';

  @override
  String get fxNeedMacTitle => 'La app para iPhone necesita un Mac';

  @override
  String get fxNeedMacDetail =>
      'Apple solo permite crear la app para iPhone en un Mac. El código está guardado: abre Ember en un Mac, recupera la app desde GitHub y la parte de iPhone se hace allí.';

  @override
  String get fxNeedPlayKeyTitle => 'Conecta tu clave de Google Play';

  @override
  String get fxNeedPlayKeyDetail =>
      '1. Pulsa “Conectar ahora”.\n2. Elige el archivo de la clave de la cuenta de servicio.\n3. Las apps que esperaban continúan solas.';

  @override
  String get fxNeedAppleKeyTitle => 'Conecta tu clave de App Store Connect';

  @override
  String get fxNeedAppleKeyDetail =>
      '1. Pulsa “Conectar ahora”.\n2. Escribe el Issuer ID y el Key ID y elige el archivo .p8.\n3. Las apps que esperaban continúan solas.';

  @override
  String fxNeedLoginTitle(String engine) {
    return 'Inicia sesión de nuevo en $engine';
  }

  @override
  String get fxNeedLoginDetail =>
      'El acceso caducó. Abre la página Conexiones, pulsa “Conectar” junto al motor e inicia sesión. Luego pulsa “Hecho, continuar”.';

  @override
  String get fxDataName => 'Nombre';

  @override
  String get fxDataPackage => 'Nombre del paquete';

  @override
  String get fxDataShort => 'Descripción corta';

  @override
  String get fxDataCategory => 'Categoría';

  @override
  String get fxDataBundleId => 'Bundle ID';

  @override
  String get fxDataSku => 'SKU';

  @override
  String get fxDataEngine => 'Motor';

  @override
  String get fxNeedsDone => 'Hecho, continuar';

  @override
  String get fxNeedsSkip => 'Omitir este paso';

  @override
  String get fxNeedsEmpty => 'Ahora no hace falta nada de ti.';

  @override
  String get fxNeedsIntro =>
      'Estas son cosas que solo tú puedes hacer. Cuando hagas una, pulsa “Hecho, continuar” y la fábrica sigue.';

  @override
  String get fxEmpty =>
      'Aún no hay apps en la fábrica. Empieza un lote y describe hasta 100 apps a la vez.';

  @override
  String get fxNoMatch => 'Ninguna app coincide.';

  @override
  String get fxSearch => 'Buscar apps';

  @override
  String get fxFilterAll => 'Todas';

  @override
  String get fxStatTotal => 'Apps';

  @override
  String get fxOnPlay => 'En Google Play';

  @override
  String get fxOnAppStore => 'En App Store';

  @override
  String get fxPausedTitle => 'La fábrica está en pausa';

  @override
  String get fxPausedHint => 'No empieza nada nuevo hasta que reanudes.';

  @override
  String get fxPausedRestart =>
      'Ember se cerró o se reinició mientras se hacían las apps. Nada se reanuda solo, así no se gasta ninguna suscripción a tus espaldas.';

  @override
  String get fxLowDiskTitle => 'El disco está casi lleno';

  @override
  String get fxLowDiskHint =>
      'No empieza ninguna app nueva hasta que haya espacio otra vez. Las apps terminadas liberan solas sus carpetas de compilación.';

  @override
  String get fxSimulatedTitle => 'Modo de prueba: las apps son simuladas';

  @override
  String get fxSimulatedHint =>
      'No se construye, sube ni paga nada de verdad. Sirve solo para probar esta pantalla.';

  @override
  String fxProgress(int percent) {
    return '$percent% completado';
  }

  @override
  String fxProgressEta(int percent, String eta) {
    return '$percent% completado · faltan unos $eta';
  }

  @override
  String fxMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String fxHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String fxDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String fxDailyLine(int playUsed, int playCap, int storeUsed, int storeCap) {
    return 'Subidas de hoy: Google Play $playUsed de $playCap, App Store $storeUsed de $storeCap. El resto sigue mañana.';
  }

  @override
  String get fxRetryFailed => 'Reintentar todas las fallidas';

  @override
  String fxCancelBatch(String name) {
    return 'Cancelar el lote “$name”';
  }

  @override
  String fxSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionadas',
      one: '1 seleccionada',
    );
    return '$_temp0';
  }

  @override
  String fxRemoveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Quitar $count apps de la fábrica?',
      one: '¿Quitar esta app de la fábrica?',
    );
    return '$_temp0';
  }

  @override
  String get fxRemoveBody =>
      'Desaparecen de esta lista. Los archivos de las apps se quedan en tu ordenador.';

  @override
  String get fxAppGone => 'Esta app ya no está en la fábrica.';

  @override
  String get fxSteps => 'Pasos';

  @override
  String get fxLog => 'Qué ha pasado';

  @override
  String fxCost(String amount) {
    return 'Coste hasta ahora: $amount USD';
  }

  @override
  String fxRetryFrom(String stage) {
    return 'Reintentar desde “$stage”';
  }

  @override
  String get fxStepIdeas => 'Ideas';

  @override
  String get fxStepRecipe => 'Cómo';

  @override
  String get fxStepReview => 'Revisión';

  @override
  String get fxBack => 'Atrás';

  @override
  String get fxContinue => 'Continuar';

  @override
  String get fxBoxTitle => 'Cuéntaselo todo a la fábrica';

  @override
  String get fxBoxHint =>
      'Pega ideas, listas, planes, prompts o documentos enteros, o añade archivos. Un supervisor lo lee todo, saca hasta 100 apps distintas y te las muestra antes de que empiece nada.';

  @override
  String get fxModeMine => 'Tengo ideas';

  @override
  String get fxModeInvent => 'Invéntalas tú';

  @override
  String get fxBoxPlaceholder =>
      'Pega aquí: una idea por línea, un plan, una descripción larga, lo que sea…';

  @override
  String get fxAttach => 'Añadir archivos';

  @override
  String get fxFilesLabel => 'Archivos de texto';

  @override
  String get fxFileTooBig =>
      'Un archivo es demasiado grande (más de 400 KB) y no se añadió.';

  @override
  String get fxThemeLabel => 'Tema';

  @override
  String get fxThemeHint =>
      'Por ejemplo: herramientas sencillas de fitness, juegos para niños, pequeños negocios…';

  @override
  String get fxHowMany => 'Cuántas apps';

  @override
  String get fxBoxFootnote =>
      'Todavía no se construye nada. Primero verás las apps y elegirás cuáles empezar.';

  @override
  String get fxRecipeTitle => '¿Cómo se hacen?';

  @override
  String get fxEnginesTitle => 'Quién escribe las apps';

  @override
  String get fxEnginesHint =>
      'Las apps se reparten en esta proporción. Las apps grandes van primero al motor más potente.';

  @override
  String get fxNotConnected => 'Aún no conectado';

  @override
  String fxSharePercent(int percent) {
    return '$percent% de las apps';
  }

  @override
  String get fxLogoTitle => 'Quién dibuja los logos';

  @override
  String get fxLogoAuto => 'Automático';

  @override
  String get fxGoalTitle => 'Hasta dónde llegar';

  @override
  String get fxGoalApp => 'Solo la app';

  @override
  String get fxGoalAssets =>
      'La app, el logo, las capturas y los textos de la tienda';

  @override
  String get fxGoalAndroid =>
      'También el archivo de Android y Google Play (borrador, pruebas)';

  @override
  String get fxGoalIos => 'También la app para iPhone y App Store (TestFlight)';

  @override
  String get fxDailyTitle => 'Repartido en los días';

  @override
  String get fxDailyHint =>
      'Todas las apps se pueden construir hoy, pero las tiendas se llenan despacio: el resto espera, listo, hasta mañana.';

  @override
  String get fxDailyLabel => 'Subidas por tienda al día';

  @override
  String get fxSafeTitle => 'Siempre borrador, siempre en pruebas';

  @override
  String get fxSafeBody =>
      'Google Play recibe la app como borrador en pruebas internas y App Store como TestFlight. Ember nunca publica ni envía una app a revisión: eso sigue siendo decisión tuya, app por app.';

  @override
  String get fxSupervisorReading =>
      'El supervisor está leyendo y eligiendo las apps…';

  @override
  String get fxNoIdeas =>
      'El supervisor no encontró ninguna app que hacer. Añade más detalles e inténtalo de nuevo.';

  @override
  String fxReviewTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps propuestas',
      one: '1 app propuesta',
    );
    return '$_temp0';
  }

  @override
  String get fxReviewHint =>
      'Desmarca las que no quieras. Toca un nombre para cambiarlo. Toca el tamaño para alternar entre pequeña y grande.';

  @override
  String get fxBatchName => 'Nombre del lote';

  @override
  String fxBatchDefaultName(String date) {
    return 'Lote $date';
  }

  @override
  String fxDroppedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ideas descartadas',
      one: '1 idea descartada',
    );
    return '$_temp0';
  }

  @override
  String fxDropDuplicate(String name) {
    return '$name: mismo nombre que otra app';
  }

  @override
  String fxDropSimilar(String name, String kept) {
    return '$name: demasiado parecida a “$kept”, que se mantuvo';
  }

  @override
  String fxDropTooMany(String name) {
    return '$name: un lote admite como máximo 100 apps';
  }

  @override
  String get fxWarnNoAi =>
      'No hay ningún motor de IA conectado, así que se leyó la lista línea por línea: una app por línea.';

  @override
  String get fxSizeSmall => 'Pequeña';

  @override
  String get fxSizeBig => 'Grande';

  @override
  String get fxSizeTooltip => 'Alternar entre pequeña y grande';

  @override
  String fxEstimateStores(int limit, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return 'Se construyen ahora y van a las tiendas $limit al día: unos $_temp0 para llenarlas.';
  }

  @override
  String fxStartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Empezar $count apps?',
      one: '¿Empezar 1 app?',
    );
    return '$_temp0';
  }

  @override
  String get fxStartBody => 'Las apps se hacen ahora. No se publica nada.';

  @override
  String fxStartBodyStores(int limit) {
    return 'Las apps se hacen ahora y van a Google Play y App Store como borradores en pruebas, $limit al día. No se publica nada ni se envía nada a revisión.';
  }

  @override
  String get fxStart => 'Empezar';

  @override
  String fxStartCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Empezar $count apps',
      one: 'Empezar 1 app',
    );
    return '$_temp0';
  }

  @override
  String fxStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps iniciadas',
      one: '1 app iniciada',
    );
    return '$_temp0';
  }

  @override
  String get fxLinksTitle => 'Conexiones y capacidad';

  @override
  String get fxLinksEngines => 'Motores de IA';

  @override
  String get fxLinksTools => 'Herramientas y cuentas';

  @override
  String get fxConnect => 'Conectar';

  @override
  String get fxSignInOpened =>
      'Se abrió una ventana de acceso en el ordenador donde corre Ember.';

  @override
  String get fxLinkAndroid => 'Herramientas de Android';

  @override
  String get fxLinkChrome => 'Chrome (para las capturas)';

  @override
  String get fxLinkPlayKey => 'Clave de Google Play';

  @override
  String get fxLinkAppleKey => 'Clave de App Store Connect';

  @override
  String get fxLinkMac => 'Un Mac para la app de iPhone';

  @override
  String get fxWhyNotInstalled => 'no instalado';

  @override
  String get fxWhyNotSignedIn => 'sin sesión iniciada';

  @override
  String get fxWhyMissing => 'falta';

  @override
  String get fxWhyOnlyMac => 'solo en un Mac';

  @override
  String get fxCapacityTitle => 'Este ordenador';

  @override
  String fxCapacityBody(int cpus, String ram, int disk) {
    return '$cpus núcleos, $ram GB de memoria libre, $disk GB libres en disco.';
  }

  @override
  String fxCapacitySlots(int agents, int builds) {
    return 'A la vez: hasta $agents agentes de IA y $builds compilaciones.';
  }

  @override
  String get fxLimitsTitle => 'Límites';

  @override
  String get fxLimitInFlight => 'Apps en marcha a la vez';

  @override
  String get fxNeedAndroidSdkTitle => 'Instala las herramientas de Android';

  @override
  String get fxNeedAndroidSdkDetail =>
      '1. Instala Android Studio (trae las herramientas de Android).\n2. Ábrelo una vez y acepta las licencias.\n3. Vuelve aquí y pulsa “Hecho, continuar”.';

  @override
  String get fxcTitle => 'Cuentas de las tiendas';

  @override
  String get fxcIntro =>
      'Conecta Google Play y la App Store una sola vez. Ember las mantiene conectadas y sube cada app por sí solo.';

  @override
  String get fxcGoogleName => 'Google Play';

  @override
  String get fxcAppleName => 'App Store';

  @override
  String get fxcStateConnected => 'Conectado';

  @override
  String get fxcStateMissing => 'No conectado';

  @override
  String get fxcStateInvalid => 'Hay que reconectar';

  @override
  String get fxcStateUnreachable => 'La tienda no responde';

  @override
  String get fxcConnect => 'Conectar';

  @override
  String get fxcReconnect => 'Conectar de nuevo';

  @override
  String get fxcChange => 'Cambiar';

  @override
  String get fxcVerify => 'Comprobar ahora';

  @override
  String get fxcDisconnect => 'Desconectar';

  @override
  String fxcDisconnectTitle(String name) {
    return '¿Desconectar $name?';
  }

  @override
  String get fxcDisconnectBody =>
      'Las apps ya subidas se quedan donde están. Las nuevas subidas esperan hasta que vuelvas a conectar.';

  @override
  String fxcAccountGoogle(String email) {
    return 'Cuenta: $email';
  }

  @override
  String fxcAccountApple(String keyId) {
    return 'Clave $keyId';
  }

  @override
  String fxcAccountTeam(String team) {
    return 'Equipo $team';
  }

  @override
  String get fxcChecking => 'Comprobando con la tienda…';

  @override
  String get fxcWhyBadKey => 'Ese no es un archivo de clave válido.';

  @override
  String get fxcWhyRefused =>
      'La tienda rechazó esta clave. Puede que la borraran o la cambiaran: crea una nueva.';

  @override
  String get fxcWhyNoRole =>
      'La clave no tiene permisos. En App Store Connect dale el rol App Manager.';

  @override
  String get fxcWhyOffline =>
      'No se pudo llegar a la tienda. Revisa la conexión a internet.';

  @override
  String get fxcWhyDeveloperId =>
      'El ID de desarrollador es el número largo de la dirección de Play Console.';

  @override
  String get fxcBannerTitle => 'Conecta Google Play y la App Store';

  @override
  String get fxcBannerBody =>
      'Mientras no estén conectadas, las apps se detienen antes de la subida.';

  @override
  String get fxcConnectNow => 'Conectar ahora';

  @override
  String get fxcGoogleTitle => 'Conectar Google Play';

  @override
  String get fxcGoogleStep1 =>
      'En Google Cloud crea una cuenta de servicio y activa la “Google Play Android Developer API”.';

  @override
  String get fxcGoogleStep2 =>
      'Abre esa cuenta, luego Claves → Añadir clave → JSON. Se guarda un archivo en tu ordenador.';

  @override
  String get fxcGoogleStep3 =>
      'En Play Console abre Usuarios y permisos e invita al correo de la cuenta con permiso para publicar apps.';

  @override
  String get fxcGoogleStep4 =>
      'Elige abajo el archivo .json. Ember lo comprueba con Google y lo guarda.';

  @override
  String get fxcOpenGoogleCloud => 'Abrir Google Cloud';

  @override
  String get fxcOpenPlayConsole => 'Abrir Play Console';

  @override
  String get fxcChooseJson => 'Elegir el archivo .json';

  @override
  String get fxcPasteKey => 'O pega aquí la clave';

  @override
  String get fxcDeveloperId => 'ID de desarrollador (opcional)';

  @override
  String get fxcDeveloperIdHelp =>
      'El número largo de la dirección de Play Console, después de /developers/.';

  @override
  String get fxcCheckSave => 'Comprobar y guardar';

  @override
  String get fxcAuto => 'Conectar automáticamente';

  @override
  String get fxcAutoHelp =>
      'Usa la cuenta de Google con la que están iniciadas las herramientas de Google Cloud de este ordenador. Necesita el ID de desarrollador.';

  @override
  String get fxcAutoWorking =>
      'Preparando Google Play… puede tardar unos minutos';

  @override
  String fxcConnectedOk(String name) {
    return '$name conectado';
  }

  @override
  String fxcFileChosen(String name) {
    return 'Archivo: $name';
  }

  @override
  String get fxcAppleTitle => 'Conectar la App Store';

  @override
  String get fxcAppleStep1 =>
      'En App Store Connect abre Usuarios y acceso → Integraciones → API de App Store Connect y crea una clave con el rol App Manager.';

  @override
  String get fxcAppleStep2 =>
      'Copia el Issuer ID (arriba en la página) y el Key ID.';

  @override
  String get fxcAppleStep3 =>
      'Descarga el archivo .p8: Apple solo permite descargarlo una vez.';

  @override
  String get fxcOpenAppStoreConnect => 'Abrir App Store Connect';

  @override
  String get fxcIssuerId => 'Issuer ID';

  @override
  String get fxcIssuerHelp =>
      'El código largo de la parte de arriba de la página de Claves.';

  @override
  String get fxcKeyId => 'Key ID';

  @override
  String get fxcKeyIdHelp =>
      'El código corto junto a la clave, como Z47GM3ZDZ6.';

  @override
  String get fxcChooseP8 => 'Elegir el archivo .p8';

  @override
  String get fxcKeepSavedKey =>
      'Deja el archivo vacío para conservar la clave guardada.';

  @override
  String get fxcTeamId => 'Team ID (opcional)';

  @override
  String get fxcTeamIdHelp =>
      'Diez caracteres. Ember lo encuentra solo cuando puede.';
}
