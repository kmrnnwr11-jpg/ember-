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
}
