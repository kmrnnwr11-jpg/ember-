// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Ember – App Maker';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle =>
      'أنشئ تطبيقات Flutter من أي جهاز، باستخدام الذكاء الاصطناعي.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get runnerUrl => 'عنوان Runner';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get devLoginHint =>
      'وضع التطوير: Supabase غير مُعدّ، تسجيل الدخول بالبريد الإلكتروني فقط عبر Runner.';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String get passwordTooShort => '6 أحرف على الأقل';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get projects => 'تطبيقاتك';

  @override
  String get noProjects => 'لم تستدعِ أي تطبيق بعد. صِف واحدًا في الأعلى.';

  @override
  String get newProject => 'مشروع جديد';

  @override
  String get projectName => 'اسم المشروع';

  @override
  String get projectNameHelp => 'أحرف إنجليزية صغيرة وأرقام و_ (مثال: my_app)';

  @override
  String get create => 'إنشاء';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get statusCreating => 'جارٍ الإنشاء…';

  @override
  String get statusReady => 'جاهز';

  @override
  String get statusError => 'خطأ';

  @override
  String creatingProject(String name) {
    return 'جارٍ إنشاء $name';
  }

  @override
  String get files => 'الملفات';

  @override
  String get editor => 'المحرر';

  @override
  String get newFile => 'ملف جديد';

  @override
  String get newFolder => 'مجلد جديد';

  @override
  String get fileName => 'الاسم';

  @override
  String deleteConfirm(String path) {
    return 'حذف $path؟';
  }

  @override
  String get save => 'حفظ';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get unsavedChanges => 'تغييرات غير محفوظة';

  @override
  String get discard => 'تجاهل';

  @override
  String get noFileOpen => 'افتح ملفًا من شجرة الملفات.';

  @override
  String get conflictTitle => 'تم تعديل الملف في مكان آخر';

  @override
  String conflictBody(String path) {
    return 'تغيّر $path على Runner بعد أن فتحته.';
  }

  @override
  String get reload => 'إعادة تحميل';

  @override
  String get overwrite => 'استبدال';

  @override
  String get connected => 'متصل';

  @override
  String get connecting => 'جارٍ الاتصال…';

  @override
  String get disconnected => 'غير متصل';

  @override
  String error(String message) {
    return 'خطأ: $message';
  }

  @override
  String get binaryFile => 'ملف ثنائي أو كبير جدًا: لا يمكن تعديله.';

  @override
  String get terminal => 'الطرفية';

  @override
  String get newTerminal => 'طرفية جديدة';

  @override
  String get toggleTerminal => 'إظهار/إخفاء الطرفية';

  @override
  String get restart => 'إعادة التشغيل';

  @override
  String get preview => 'المعاينة';

  @override
  String get togglePreview => 'إظهار/إخفاء المعاينة';

  @override
  String get runWeb => 'تشغيل الويب';

  @override
  String get building => 'جارٍ البناء…';

  @override
  String get buildFailed => 'فشل البناء: راجع السجل أدناه.';

  @override
  String get reloadPreview => 'إعادة تحميل المعاينة';

  @override
  String get device => 'الجهاز';

  @override
  String get openInBrowser => 'فتح في المتصفح';

  @override
  String get openOnOtherDevice => 'فتح على جهاز آخر';

  @override
  String get qrLocalhostWarning =>
      'هذا العنوان يعمل على هذا الكمبيوتر فقط. استخدم عنوان IP الخاص بـ Runner على الشبكة (مثال: http://192.168.1.20:8787) لفتحه من الهاتف.';

  @override
  String get copy => 'نسخ';

  @override
  String get close => 'إغلاق';

  @override
  String get console => 'وحدة التحكم';

  @override
  String get autoRebuild => 'إعادة البناء عند الحفظ';

  @override
  String get previewEmpty =>
      'اضغط «تشغيل الويب» لبناء التطبيق ورؤيته هنا. كل عملية حفظ تُحدّث المعاينة.';

  @override
  String get ai => 'الذكاء الاصطناعي';

  @override
  String get toggleAi => 'إظهار/إخفاء لوحة الذكاء الاصطناعي';

  @override
  String get aiSettings => 'مفاتيح API والنماذج';

  @override
  String get apiKeysHint =>
      'تبقى المفاتيح مشفّرة على هذا الجهاز (تخزين آمن). عند تفعيل الوكيل تمر عبر Runner الخاص بك لكل طلب فقط ولا تُحفظ أو تُسجّل أبدًا.';

  @override
  String get useRunnerProxy => 'المرور عبر Runner (وكيل)';

  @override
  String get useRunnerProxyHint =>
      'موصى به. عطّله للاتصال بالمزوّدين مباشرة من هذا الجهاز.';

  @override
  String get useRunnerProxyWeb =>
      'إلزامي على الويب: لا تستطيع المتصفحات الاتصال بالمزوّدين مباشرة.';

  @override
  String get apiKey => 'مفتاح API';

  @override
  String get apiKeyOptional => 'مفتاح API (إن كان مطلوبًا)';

  @override
  String get replaceApiKey => 'استبدال المفتاح';

  @override
  String get testKey => 'اختبار';

  @override
  String get testing => 'جارٍ الاختبار…';

  @override
  String keyWorks(String model) {
    return 'يعمل ✓ ($model)';
  }

  @override
  String get getKey => 'الحصول على مفتاح';

  @override
  String get addModelId => 'إضافة معرّف نموذج';

  @override
  String get selectModel => 'اختر النموذج';

  @override
  String get keyPresent => 'المفتاح موجود';

  @override
  String get notConfigured => 'غير مُعدّ';

  @override
  String get per1k => 'لكل 1000 رمز (إدخال/إخراج)';

  @override
  String applyTo(String path) {
    return 'تطبيق على $path';
  }

  @override
  String get noChanges => 'لا توجد اختلافات عن الملف الحالي.';

  @override
  String get accept => 'قبول';

  @override
  String get reject => 'رفض';

  @override
  String get apply => 'تطبيق';

  @override
  String applied(String path) {
    return 'تم تطبيق التعديل على $path: راجِعه واحفظه.';
  }

  @override
  String get applyNoTarget =>
      'افتح ملفًا أو اطلب من الذكاء الاصطناعي تحديد مسار الملف.';

  @override
  String get clearChat => 'مسح المحادثة';

  @override
  String get chatEmpty => 'اسأل عن مشروعك. يُرسل الملف المفتوح كسياق.';

  @override
  String get chatNoKeys =>
      'أضف مفتاح API واحدًا على الأقل (Claude أو ChatGPT أو Gemini) لاستخدام الذكاء الاصطناعي.';

  @override
  String get attachOpenFile => 'إرفاق الملف المفتوح كسياق';

  @override
  String get askAi => 'اسأل الذكاء الاصطناعي…  (Ctrl+Enter للإرسال)';

  @override
  String get send => 'إرسال';

  @override
  String get stop => 'إيقاف';

  @override
  String get copied => 'تم النسخ';

  @override
  String get truncated => 'الرد مقطوع (حد الرموز)';

  @override
  String get refused => 'رفضه النموذج';

  @override
  String get stopped => 'تم الإيقاف';

  @override
  String get badgeFreeTier => 'مجاني*';

  @override
  String get badgeSubscription => 'اشتراك';

  @override
  String get badgePaid => 'مدفوع';

  @override
  String needsKey(String name) {
    return 'يحتاج مفتاح API لـ $name: أضفه في الإعدادات.';
  }

  @override
  String get claudeCodeUnavailable =>
      'Claude Code غير متاح على هذا Runner (يجب أن يكون مثبّتًا ومسجّل الدخول على كمبيوتر Runner).';

  @override
  String get appPromptHint => 'مثال: تطبيق وصفات مع صور وقائمة تسوّق ومؤقّت…';

  @override
  String get chooseAi => 'اختر المحرّك';

  @override
  String get createApp => 'Ember App';

  @override
  String get openEditor => 'المحرر';

  @override
  String get describeYourApp => 'استدعِ تطبيقك';

  @override
  String get describeYourAppHint =>
      'صِف ما يجب أن يفعله وكيف يجب أن يبدو. يكتبه Ember ويتحقق منه ويعرضه لك. (*Gemini: حصة Google المجانية بحدود يومية)';

  @override
  String get improveApp => 'ماذا تريد أن تضيف أو تحسّن؟';

  @override
  String get improveAppHint =>
      'صِف الميزات أو التعديلات التالية، مثال: أضف مكالمات الفيديو، تسجيل الدخول بحساب Google، الغرف الخاصة… يمكنك أيضًا لصق المفاتيح التي يطلبها الذكاء الاصطناعي هنا.';

  @override
  String get applyChange => 'تطبيق التعديل';

  @override
  String get buildLog => 'التفاصيل';

  @override
  String get stepClaudeCode => 'يكتب Claude Code الكود ويتحقق منه';

  @override
  String stepWriting(int count) {
    return 'كتابة الكود ($count ملفات)';
  }

  @override
  String get stepDependencies => 'تثبيت الاعتماديات';

  @override
  String get stepChecking => 'التحقق من الأخطاء';

  @override
  String stepFixing(int round) {
    return 'إصلاح الأخطاء (المحاولة $round)';
  }

  @override
  String get stepBuilding => 'بناء التطبيق';

  @override
  String get stepReady => 'جاهز';

  @override
  String get appReadyTitle => 'تطبيقك جاهز 🎉';

  @override
  String get openApp => 'فتح التطبيق';

  @override
  String get viewCode => 'عرض الكود';

  @override
  String get buildCancelled => 'تم إيقاف الإنشاء';

  @override
  String get buildFailedTitle => 'لم أتمكن من إكمال التطبيق';

  @override
  String get bestQuality => 'أقصى قوة';

  @override
  String get bestQualityOn => 'أقوى محرّك: أبطأ، للتطبيقات المعقدة';

  @override
  String get bestQualityOff => 'سريع (موصى به): مناسب لمعظم التطبيقات';

  @override
  String get androidFileQuestion => 'هل تريد ملف أندرويد؟';

  @override
  String get androidFileHint =>
      'APK: للتثبيت على الهاتف. AAB: للرفع إلى Google Play Console. كلاهما موقّع.';

  @override
  String get generateApk => 'إنشاء APK';

  @override
  String get generateAab => 'إنشاء AAB';

  @override
  String androidBuilding(String kind) {
    return 'جارٍ إنشاء $kind… قد تستغرق المرة الأولى 3-5 دقائق.';
  }

  @override
  String get downloadApk => 'تنزيل وتثبيت APK';

  @override
  String get downloadAab => 'تنزيل AAB';

  @override
  String get apkInstallHint =>
      'ملف APK موقّع. إذا طلب أندرويد ذلك، اسمح بالتثبيت من هذا المصدر.';

  @override
  String get aabHint =>
      'ملف AAB موقّع بمفتاح الرفع الخاص بهذا التطبيق: جاهز لـ Google Play Console. يزداد رقم الإصدار مع كل بناء.';

  @override
  String get androidFailed => 'فشل الإنشاء:';

  @override
  String get backupSigningKey => 'حفظ مفتاح التوقيع';

  @override
  String get backupSigningKeyHint =>
      'احتفظ بملف المفتاح وكلمة المرور في مكان آمن (مثل Google Drive): تحتاج إليهما لنشر تحديثات هذا التطبيق على Google Play. يعمل الرابط مرة واحدة فقط لمدة 10 دقائق.';

  @override
  String get downloadKeystore => 'تنزيل ملف المفتاح';

  @override
  String get fullscreenExitHint => 'اسحب أو اضغط رجوع للعودة إلى Ember';

  @override
  String get runFullscreen => 'تشغيل بملء الشاشة';

  @override
  String cliNotInstalled(String name) {
    return 'غير مثبّت على Runner ($name)';
  }

  @override
  String get terminalCliHint =>
      'يستخدم Claude Code وCodex وGemini تسجيل الدخول الموجود على كمبيوتر Runner. في المرة الأولى اتبع التعليمات في الطرفية لتسجيل الدخول.';

  @override
  String get generatingMockups => 'جارٍ إنشاء 5 أنماط تصميم…';

  @override
  String designingStyle(String style) {
    return 'جارٍ تصميم نمط «$style»…';
  }

  @override
  String get chooseMockup => 'اختر هذا';

  @override
  String get editMockup => 'تعديل هذا النموذج';

  @override
  String get editMockupHint => 'مثال: أغمق، أزرار دائرية، شعار وردي…';

  @override
  String get newMockups => 'نماذج جديدة (5 أنماط مختلفة)';

  @override
  String get previousMockups => 'النماذج السابقة';

  @override
  String mockupSet(int n) {
    return 'المجموعة $n';
  }

  @override
  String get skipMockups => 'تخطَّ النماذج وأنشئ التطبيق';

  @override
  String get playAskUpload => 'هل تريد رفع التطبيق إلى متجر Google Play؟';

  @override
  String get playYesUpload => 'نعم، ارفعه إلى متجر Play';

  @override
  String get playNotNow => 'ليس الآن';

  @override
  String get playFeeNotice =>
      'تحتاج إلى حساب مطوّر في Google Play Console. التكلفة: 25 دولارًا مرة واحدة فقط (ليست اشتراكًا)، تُدفع مباشرة إلى Google وليس إلى Ember.';

  @override
  String get playPublishTitle => 'النشر على Google Play';

  @override
  String get playStepAccount => 'حساب Google Play Console';

  @override
  String get playOpenSignup => 'إنشاء حساب Play Console';

  @override
  String get playHaveAccount => 'لدي بالفعل حساب Play Console نشط';

  @override
  String get next => 'التالي';

  @override
  String get playStepCreateApp => 'أنشئ التطبيق في Play Console';

  @override
  String get playCreateAppGuide =>
      'تطلب Google هذه الخطوة يدويًا، في المرة الأولى فقط:\n1. افتح **Play Console** ← **إنشاء تطبيق**\n2. اسم التطبيق، اللغة الافتراضية، النوع **تطبيق**، **مجاني**\n3. وافق على الإقرارات واضغط **إنشاء تطبيق**\n\nيُربط اسم الحزمة عند الرفع الأول: استخدم الاسم أدناه.';

  @override
  String get playPackageName => 'اسم الحزمة';

  @override
  String get playOpenConsole => 'فتح Play Console';

  @override
  String get playAppCreated => 'أنشأت التطبيق في Play Console';

  @override
  String get playStepConnect => 'اربط Ember بـ Google Play';

  @override
  String get playConnectGuide =>
      'تحتاج إلى **مفتاح حساب خدمة** (مرة واحدة لكل تطبيقاتك):\n1. افتح **Google Cloud** وفعّل **Google Play Android Developer API**\n2. **حسابات الخدمة** ← **إنشاء** ← **المفاتيح** ← **إضافة مفتاح** ← **JSON** (يتم تنزيل ملف)\n3. في **Play Console** ← **المستخدمون والأذونات** ← **دعوة مستخدمين جدد** ← الصق بريد حساب الخدمة ← امنح أذونات **النشر**\n4. افتح ملف JSON الذي تم تنزيله و**الصق محتواه بالكامل هنا**\n\nيبقى المفتاح مشفّرًا على هذا الجهاز ويُستخدم للرفع فقط.';

  @override
  String get playOpenApiLibrary => 'تفعيل Google Play API';

  @override
  String get playOpenServiceAccounts => 'حسابات الخدمة';

  @override
  String get playServiceAccountJson => 'محتوى JSON لحساب الخدمة';

  @override
  String get playStepListing => 'صفحة المتجر والرفع';

  @override
  String get playGenerateWithAi =>
      'إنشاء صفحة المتجر وسياسة الخصوصية والإجابات بالذكاء الاصطناعي';

  @override
  String get playTitle => 'العنوان (30 حرفًا كحد أقصى)';

  @override
  String get playShortDescription => 'الوصف القصير (80 حرفًا كحد أقصى)';

  @override
  String get playFullDescription => 'الوصف الكامل';

  @override
  String get playReleaseNotes => 'ملاحظات الإصدار';

  @override
  String get playContactEmail => 'بريد التواصل (إلزامي في متجر Play)';

  @override
  String get playPrivacyUrl => 'رابط سياسة الخصوصية';

  @override
  String get playTrack => 'مكان النشر';

  @override
  String get playTrackInternal => 'اختبار داخلي (موصى به للبدء)';

  @override
  String get playTrackClosed => 'اختبار مغلق';

  @override
  String get playTrackProduction => 'الإنتاج (عام)';

  @override
  String get playUpload => 'الرفع إلى Google Play';

  @override
  String get playStepFinish => 'أكمل في Play Console';

  @override
  String playUploaded(String version, String track, String draft) {
    return '✅ تم الرفع! الإصدار $version على مسار «$track». $draft';
  }

  @override
  String get playDraftNote =>
      'لأن التطبيق لم يُنشر من قبل، حفظته Google كمسودة: أكمل الخطوات أدناه واضغط «إرسال للمراجعة» في Play Console.';

  @override
  String playManualChecklist(String privacyUrl) {
    return 'تطلب Google تأكيد هذه البنود يدويًا في Play Console (الإجابات الجاهزة أدناه):\n- **سياسة الخصوصية** ← الصق الرابط: $privacyUrl\n- **أمان البيانات**\n- استبيان **تصنيف المحتوى**\n- **الجمهور المستهدف والمحتوى**\n- **الإعلانات** و**الوصول إلى التطبيق** (قدّم حساب اختبار إذا كان تسجيل الدخول مطلوبًا)\n- **صفحة المتجر**: أيقونة 512×512 ولقطتا شاشة على الأقل\n- الحسابات الشخصية الجديدة: قد تطلب Google **اختبارًا مغلقًا** بعدد أدنى من المختبرين قبل الإنتاج';
  }

  @override
  String get playDataSafety => 'إجابات «أمان البيانات»';

  @override
  String get playContentRating => 'إجابات «تصنيف المحتوى»';

  @override
  String get playOtherDeclarations => 'الجمهور والإعلانات والوصول إلى التطبيق';

  @override
  String get assistantTitle => 'اسأل Ember';

  @override
  String get assistantFree => 'مجاني';

  @override
  String get assistantEmpty =>
      'مرحبًا، أنا Ember! اسألني أي شيء: أفكار لتطبيقك، كيفية نشره على متجر Play، كيفية إعداد تسجيل الدخول وقواعد البيانات…';

  @override
  String get assistantUnconfigured =>
      'المساعد المجاني غير مفعّل بعد على هذا الخادم (مفتاح Gemini الخاص بـ Runner غير موجود).';

  @override
  String get assistantHint => 'اسأل Ember عن أي شيء…';

  @override
  String get assistantSuggest1 => 'ما التطبيق الذي يمكنني إنشاؤه لمتجري؟';

  @override
  String get assistantSuggest2 => 'كيف أنشر تطبيقًا على متجر Play؟';

  @override
  String get assistantSuggest3 => 'كيف يعمل تسجيل الدخول بحساب Google؟';

  @override
  String get language => 'اللغة';

  @override
  String get find => 'بحث';

  @override
  String get replace => 'استبدال';

  @override
  String get replaceAll => 'الكل';

  @override
  String get baseUrl => 'عنوان URL الأساسي';

  @override
  String fontLabel(String font) {
    return 'الخط: $font';
  }

  @override
  String get styleMinimal => 'بسيط فاتح';

  @override
  String get styleDark => 'داكن فاخر';

  @override
  String get stylePlayful => 'ملوّن ومرح';

  @override
  String get styleGlass => 'زجاجي شفاف';

  @override
  String get styleMaterial => 'Material 3';

  @override
  String get styleNeumorph => 'نيومورفيزم';

  @override
  String get styleLuxury => 'فخامة أنيقة';

  @override
  String get styleBrutal => 'بروتالي جريء';

  @override
  String get stylePastel => 'ألوان باستيل ناعمة';

  @override
  String get styleTech => 'تقني مستقبلي';

  @override
  String get styleNature => 'طبيعة';

  @override
  String get styleIos => 'نمط iOS';

  @override
  String get styleRetro => 'ريترو الثمانينات';

  @override
  String get styleMono => 'أحادي اللون';

  @override
  String get styleCorporate => 'احترافي';

  @override
  String bWriting(String model) {
    return 'جارٍ كتابة الكود باستخدام $model…';
  }

  @override
  String bApplying(String change, String model) {
    return 'جارٍ تطبيق التعديل باستخدام $model: $change';
  }

  @override
  String get bNoModel => 'لم يتم اختيار أي نموذج';

  @override
  String get bNoFiles =>
      'لم ينتج الذكاء الاصطناعي أي ملفات: أعد المحاولة أو غيّر النموذج.';

  @override
  String bErrorsRemain(int count, String problems) {
    return 'لا تزال هناك أخطاء بعد $count محاولات إصلاح:\n$problems';
  }

  @override
  String bFixing(int max, int round) {
    return 'جارٍ إصلاح الأخطاء (المحاولة $round من $max)…';
  }

  @override
  String bNoFixes(String problems) {
    return 'لم يقترح الذكاء الاصطناعي إصلاحات لـ:\n$problems';
  }

  @override
  String bIncompleteFile(String path) {
    return 'تم تجاهل ملف غير مكتمل: $path';
  }

  @override
  String bPathNotAllowed(String path) {
    return 'مسار غير مسموح به، تم تجاهله: $path';
  }

  @override
  String get bTruncated =>
      'تم قطع الرد بسبب حد الرموز: ستُعاد كتابة الملفات غير المكتملة أثناء الإصلاح.';

  @override
  String get bRefused => 'رفض النموذج الطلب.';

  @override
  String get bPubGet => 'جارٍ تثبيت الاعتماديات (flutter pub get)…';

  @override
  String get bPubGetFailed => 'فشل flutter pub get';

  @override
  String get bAnalyze => 'جارٍ التحقق من الأخطاء (flutter analyze)…';

  @override
  String get bNoErrors => 'لا توجد أخطاء ✓';

  @override
  String bErrorsFound(int count) {
    return 'تم العثور على $count أخطاء';
  }

  @override
  String get bClaudeApplying => 'يقوم Claude Code بتطبيق التعديل…';

  @override
  String get bClaudeBuilding => 'يقوم Claude Code ببناء التطبيق على الكمبيوتر…';

  @override
  String get bClaudeFailed => 'لم يُكمل Claude Code التطبيق: راجع السجل.';

  @override
  String get bWebBuilding => 'جارٍ بناء التطبيق للويب (حوالي 30 ثانية)…';

  @override
  String bWebFailed(String log) {
    return 'فشل بناء نسخة الويب:\n$log';
  }

  @override
  String get bApk =>
      'جارٍ إنشاء ملف APK (قد يستغرق بضع دقائق في المرة الأولى)…';

  @override
  String get bAab => 'جارٍ إنشاء ملف AAB لمتجر Play…';

  @override
  String bAndroidFailed(String kind) {
    return 'فشل إنشاء $kind';
  }

  @override
  String bAndroidReady(String kind) {
    return '$kind جاهز ✓';
  }

  @override
  String get bStopped => 'تم الإيقاف';

  @override
  String get bAppReady => 'التطبيق جاهز ✓';

  @override
  String get bAppUpdated => 'تم تحديث التطبيق ✓';

  @override
  String actWrites(String file) {
    return 'كتابة $file';
  }

  @override
  String actEdits(String file) {
    return 'تعديل $file';
  }

  @override
  String actReads(String file) {
    return 'قراءة $file';
  }

  @override
  String get actPubGet => 'تثبيت الاعتماديات';

  @override
  String get actAnalyze => 'التحقق من الأخطاء';

  @override
  String get forgeTitle => 'Ember يستدعي تطبيقك';

  @override
  String forgeFiles(int count) {
    return 'تم استدعاء $count ملفات';
  }

  @override
  String researchingApp(String name) {
    return 'جارٍ دراسة «$name» على Google Play…';
  }

  @override
  String get pickReferenceApp => 'أي تطبيق تقصد؟';

  @override
  String get pickReferenceAppHint =>
      'سيدرس Ember ميزاته على Google Play وينشئ تطبيقًا يقوم بالشيء نفسه، باسمك وتصميمك الخاص.';

  @override
  String get referenceNone => 'لا شيء منها، تابع بدون';

  @override
  String forgeFilesOf(int count, int total) {
    return 'تم استدعاء $count من $total ملفات';
  }

  @override
  String forgeEta(int minutes) {
    return 'متبقٍ حوالي $minutes دقيقة';
  }

  @override
  String forgeEstimated(int minutes) {
    return 'الوقت المقدَّر حوالي $minutes دقيقة';
  }

  @override
  String forgeElapsed(String time) {
    return 'مضى $time';
  }

  @override
  String get forgeBackground =>
      'يمكنك إطفاء الشاشة أو استخدام تطبيقات أخرى: يواصل Ember العمل وينهي التطبيق.';

  @override
  String get buyCredits => 'شراء أرصدة API';

  @override
  String get getSubscription => 'اشترِ اشتراكًا';

  @override
  String get connectSubscription => 'اربط اشتراكي';

  @override
  String get accessTitle => 'الوصول والمدفوعات';

  @override
  String get accessPaidOutside =>
      'تتم المدفوعات على موقع المزوّد، وليس داخل Ember.';

  @override
  String subscriptionNotConnected(String name) {
    return '$name غير متصل: سجّل الدخول باشتراكك على كمبيوتر Runner.';
  }

  @override
  String connectHowTo(String plan, String command) {
    return 'يستخدم Ember اشتراكك الخاص في $plan، مع تسجيل الدخول على الكمبيوتر الذي يعمل عليه Runner (بدون مفتاح API وبدون تكلفة إضافية).\n\n1. على ذلك الكمبيوتر افتح طرفية (أو طرفية Ember).\n2. نفّذ: $command\n3. أكمل تسجيل الدخول في المتصفح بحسابك.\n\nعد إلى هنا: سيتفعّل المحرّك خلال دقيقة.';
  }

  @override
  String get connectPersonalNote =>
      'الاشتراكات شخصية: استخدمها لتطبيقاتك، لا لإنشاء تطبيقات لأشخاص آخرين.';

  @override
  String get grokNoCli =>
      'لا يمكن ربط اشتراكات Grok (SuperGrok) بتطبيقات أخرى بعد: استخدم مفتاح API من xAI.';

  @override
  String subscriptionConnected(String plan) {
    return 'متصل باشتراكك في $plan: بدون مفتاح API وبدون تكلفة إضافية.';
  }

  @override
  String haveSubscription(String plan) {
    return 'هل لديك $plan بالفعل؟';
  }

  @override
  String subscriptionReadyUse(String engine) {
    return 'أنشئ باستخدام $engine عبر اشتراكك، دون شراء أرصدة API.';
  }

  @override
  String subscriptionConnectFirst(String engine) {
    return 'اربطه مرة واحدة لتنشئ باستخدام $engine دون تكلفة إضافية.';
  }

  @override
  String get useSubscription => 'استخدمه';

  @override
  String get bResumeChat => 'تابِع الإنشاء المتوقف من حيث توقف';

  @override
  String get backToEmber => 'العودة إلى Ember';

  @override
  String get productsTitle =>
      'عمليات الشراء داخل التطبيق لتفعيلها على Google Play';

  @override
  String get productsHint =>
      'ينشئ Ember هذه المنتجات ويفعّلها في Play Console نيابةً عنك، مع تحويل الأسعار لكل دولة.';

  @override
  String get productsActivate => 'أنشئ وفعّل على Play Console';

  @override
  String get productsNeedKey =>
      'اربط Google Play أولًا (مفتاح حساب الخدمة): افتح خطوات النشر.';

  @override
  String get productsBefore =>
      'قبل التفعيل، مرة واحدة لكل حساب/تطبيق:\n1. Play Console ← الإعداد ← ملف الدفعات (الحساب البنكي والبيانات الضريبية)\n2. ارفع ملف AAB لهذا التطبيق إلى الاختبار الداخلي (تشترط Google نسخة تتضمن الفوترة)\n3. المستخدمون والأذونات ← امنح حساب الخدمة إذن «إدارة الطلبات والاشتراكات»';

  @override
  String get productsOpenPayments => 'ملف الدفعات';

  @override
  String get productsUploadFirst => 'رفع AAB';

  @override
  String get productsActive => 'مفعّل على Google Play ✓';

  @override
  String productPerPeriod(String price, String period) {
    return '$price / $period';
  }

  @override
  String productTrial(int days) {
    return 'تجربة مجانية لمدة $days يومًا';
  }

  @override
  String get logoTitle => 'شعار التطبيق';

  @override
  String get logoHint =>
      'يرسم Ember 6 مقترحات. لم تعجبك؟ اضغط «شعارات أخرى» كلما أردت. الشعار الذي تختاره يصبح أيقونة التطبيق وأيقونة وبانر متجر Play.';

  @override
  String get logoDescribe => 'صِف الشعار (اختياري)';

  @override
  String get logoDescribeHint => 'مثال: درع أزرق مع قلم، عصري، بدون نص';

  @override
  String get logoGenerate => 'أنشئ 6 شعارات';

  @override
  String get logoMore => 'شعارات أخرى';

  @override
  String get logoUse => 'استخدم هذا الشعار';

  @override
  String get logoApplied =>
      'تم تعيين الشعار: يجري إنشاء أيقونات التطبيق وسيتم تحديث المعاينة.';

  @override
  String get shotsTitle => 'لقطات شاشة لمتجر Play';

  @override
  String get shotsHint =>
      'يفتح Ember التطبيق كهاتف ويلتقط 6 صور للشاشات الرئيسية (1080×1920) جاهزة لـ Google Play.';

  @override
  String get shotsPreparing =>
      'يجهّز Ember التطبيق للقطات الشاشة (وضع عرض لكل شاشة)، وستبدأ الصور تلقائيًا عند الانتهاء.';

  @override
  String get shotsPreparingChat => 'جهّز التطبيق للقطات شاشة متجر Play';

  @override
  String get shotsGenerate => 'التقط 6 صور';

  @override
  String get shotsAgain => 'أعد التقاط الصور';

  @override
  String shotsSaved(int count) {
    return 'تم حفظ $count لقطات لـ Google Play.';
  }

  @override
  String get pubTitle => 'انشر مع Ember';

  @override
  String pubAccountAsk(String app) {
    return 'مرحبًا! سأرشدك لنشر **$app** على Google Play خطوة بخطوة، وسأتولى الأجزاء التقنية بنفسي.\n\nالسؤال الأول: هل لديك **حساب مطوّر في Google Play Console**؟';
  }

  @override
  String get pubYesHaveIt => 'نعم، لدي حساب';

  @override
  String get pubNoHowTo => 'لا، كيف أنشئه؟';

  @override
  String get pubAccountHow =>
      'يستغرق إنشاؤه 10 دقائق:\n1. افتح صفحة التسجيل (الزر أدناه) بحساب Google\n2. اختر **شخصي** (أو مؤسسة إن كانت لديك شركة)\n3. ادفع **25 دولارًا مرة واحدة**: تذهب إلى Google وليس إلى Ember\n4. أكّد هويتك بمستند: عادةً تؤكد Google خلال يوم أو يومين\n\nعندما يصبح الحساب نشطًا، عد إلى هنا.';

  @override
  String get pubNowIHaveIt => 'تم، الحساب نشط';

  @override
  String pubCreateApp(String package) {
    return 'الآن أنشئ التطبيق في Play Console (في المرة الأولى فقط):\n1. اضغط **فتح Play Console** أدناه ثم **إنشاء تطبيق**\n2. اسم التطبيق، اللغة الافتراضية، النوع **تطبيق**، **مجاني**\n3. حدّد الإقرارات واضغط **إنشاء تطبيق**\n\nاسم حزمة هذا التطبيق هو `$package`: تربطه Google تلقائيًا عند أول رفع.';
  }

  @override
  String get pubDone => 'تم';

  @override
  String get pubConnect =>
      'الآن أربط Ember بـ Google Play لأتمكن من رفع تطبيقاتك. **سأقوم بذلك بنفسي**: أنشئ مفتاحًا خاصًا في حساب Google على هذا الكمبيوتر (مشروع Google Cloud وواجهة Play والمفتاح). يُستخدم فقط لرفع التطبيقات ويبقى على جهازك.';

  @override
  String get pubDoItEmber => 'افعلها أنت يا Ember';

  @override
  String get pubManual => 'أفضّل القيام بذلك يدويًا';

  @override
  String get pubKeyWorking =>
      'جارٍ إنشاء مشروع Google Cloud وتفعيل واجهة Play وإنشاء المفتاح (دقيقة أو دقيقتان)…';

  @override
  String get pubInvite =>
      'تم إنشاء المفتاح ✓\n\nآخر ربط: يجب أن يُسمح للمفتاح بالنشر في Play Console **الخاص بك**.\n1. اضغط **فتح Play Console** أدناه\n2. انسخ عنوان الصفحة التي تراها (أي صفحة) و**الصقه هنا في المحادثة**\n\nبعدها سيفتح متصفح الكمبيوتر مرة واحدة: سجّل الدخول بنفس حساب Google واضغط **سماح**. سأرسل الدعوة بنفسي.';

  @override
  String get pubInviteBadLink =>
      'هذا الرابط لا يحتوي على رقم حساب Play Console. افتح play.google.com/console والصق عنوان تلك الصفحة.';

  @override
  String get pubInviteWorking =>
      'جارٍ دعوة المفتاح إلى Play Console… إذا فُتح متصفح الكمبيوتر، سجّل الدخول واضغط سماح.';

  @override
  String pubInviteManual(String email) {
    return 'لم أتمكن من إرسال الدعوة تلقائيًا، لنفعلها معًا (دقيقتان):\n1. **فتح Play Console** ثم **المستخدمون والأذونات** و**دعوة مستخدمين جدد**\n2. الصق هذا البريد: `$email`\n3. **أذونات الحساب**: حدّد الإصدارات والتواجد في المتجر ومحتوى التطبيق والطلبات\n4. اضغط **دعوة مستخدم** ثم **تم** هنا';
  }

  @override
  String get pubGraphics =>
      'تم الربط بـ Google Play ✓\n\nتطلب Google لصفحة المتجر **أيقونة 512×512** و**بانر 1024×500** و**لقطتي شاشة** على الأقل. إن لم تنشئها بعد، عد إلى شاشة التطبيق: في **شعار التطبيق** و**لقطات شاشة لمتجر Play** ينشئها Ember بلمسة. سأرفعها تلقائيًا مع التطبيق.';

  @override
  String get pubContinue => 'متابعة';

  @override
  String get pubBackToApp => 'العودة إلى التطبيق';

  @override
  String get pubUpload =>
      'الآن صفحة المتجر والرفع: أكتب العنوان والأوصاف وسياسة الخصوصية، وأجهّز إجابات نماذج Google، ثم أرفع ملف AAB الموقّع مع الأيقونة والبانر ولقطات الشاشة.\n\nأنشئ أولًا ملف **AAB** من شاشة التطبيق إن لم تفعل بعد.';

  @override
  String get pubPrepareUpload => 'جهّز وارفع';

  @override
  String get pubFinish =>
      'رائع، التطبيق على Google Play ✓\n\nلا تزال Google تطلب تأكيد بعض النماذج يدويًا في Play Console (**أمان البيانات** و**تصنيف المحتوى** و**الجمهور المستهدف** و**الإعلانات** و**الوصول إلى التطبيق**): الإجابات الجاهزة في الشاشة الأخيرة. كما يجب على الحسابات الشخصية الجديدة إجراء **اختبار مغلق مع 12 مختبرًا لمدة 14 يومًا** قبل النشر العام.\n\nلديك سؤال؟ اسألني بالأسفل.';

  @override
  String get pubReviewAnswers => 'عرض الإجابات الجاهزة';

  @override
  String get pubPasteLink => 'الصق رابط Play Console هنا…';

  @override
  String get pubAskAnything => 'اسأل Ember أي شيء عن النشر…';

  @override
  String get adsTitle => 'إعلانات AdMob';

  @override
  String get adsHint =>
      'يعرض التطبيق حاليًا إعلانات اختبار من Google (آمنة أثناء التطوير) ويطلب موافقة الاتحاد الأوروبي. لتحقيق الربح، أنشئ الوحدات الحقيقية في AdMob والصق المعرّفات هنا وسيضعها Ember في التطبيق.';

  @override
  String get adsSteps =>
      'في AdMob (5 دقائق، مرة لكل تطبيق):\n1. التطبيقات ← إضافة تطبيق ← Android ← «هل التطبيق على Google Play؟» (لا إن لم يُنشر بعد) ← الاسم ← إضافة\n2. انسخ معرّف التطبيق (ca-app-pub-…~…)\n3. الوحدات الإعلانية ← إضافة وحدة ← اختر كل تنسيق أدناه ← إنشاء ← انسخ معرّفها (ca-app-pub-…/…)\n4. بعد النشر، اربط التطبيق بصفحته في متجر Play داخل AdMob وأضف app-ads.txt إن طُلب';

  @override
  String get adsOpenAdmob => 'فتح AdMob';

  @override
  String get adsAppId => 'معرّف تطبيق AdMob';

  @override
  String adsUnitId(String format) {
    return 'معرّف وحدة $format';
  }

  @override
  String get adsApply => 'ضع المعرّفات الحقيقية في التطبيق';

  @override
  String get adsInvalid =>
      'يجب أن تكون المعرّفات مثل ca-app-pub-1234567890123456~1234567890 (للتطبيق) وca-app-pub-1234567890123456/1234567890 (للوحدات).';

  @override
  String get adsChat => 'ضع معرّفات AdMob الحقيقية';

  @override
  String get pubNothingUploaded =>
      'لم يُرفع أي شيء إلى Google Play: في الشاشة التالية اضغط «الرفع إلى Google Play» وانتظر التأكيد ثم عد.';

  @override
  String upListing(String languages) {
    return '✓ صفحة المتجر (العنوان والأوصاف): $languages';
  }

  @override
  String get upNoListing => '✗ لم تُكتب صفحة المتجر (العنوان والأوصاف فارغة)';

  @override
  String get upIcon => '✓ أيقونة 512×512';

  @override
  String get upNoIcon =>
      '✗ الأيقونة مفقودة: اختر شعارًا أولًا في «شعار التطبيق»';

  @override
  String get upFeature => '✓ بانر 1024×500';

  @override
  String get upNoFeature => '✗ البانر مفقود: اختر شعارًا أولًا';

  @override
  String upShots(int count) {
    return '✓ $count لقطات للهاتف';
  }

  @override
  String get upNoShots =>
      '✗ لقطات الشاشة مفقودة: التقطها أولًا في «لقطات شاشة لمتجر Play»';

  @override
  String get upTitle => 'Google Play';

  @override
  String get upHint =>
      'كل شيء محفوظ لهذا التطبيق. غيّر ما تريد ثم أرسل إصدارًا جديدًا: ينشئ Ember ملف AAB موقّعًا جديدًا (إصدار أعلى) ويرفعه مع صفحة المتجر والشعار ولقطات الشاشة.';

  @override
  String get upStateLogo => 'الشعار';

  @override
  String upStateShots(int count) {
    return 'لقطات الشاشة: $count';
  }

  @override
  String get upStateListing => 'العنوان والأوصاف';

  @override
  String get upEditListing => 'تعديل العنوان والأوصاف';

  @override
  String get upNewVersion => 'إصدار جديد على Google Play';

  @override
  String get upBuilding => 'جارٍ إنشاء ملف AAB الموقّع الجديد…';

  @override
  String get upUploading => 'جارٍ الرفع إلى Google Play…';

  @override
  String get upNeedsSetup =>
      'اربط Google Play أولًا واكتب صفحة المتجر مرة واحدة: افتح دليل النشر.';

  @override
  String get upOpenGuide => 'دليل النشر';

  @override
  String get pubPasteConsoleLink =>
      'نصيحة: افتح Play Console مرة واحدة والصق عنوان تلك الصفحة هنا في المحادثة. بعدها سيفتح كل زر حسابك **أنت** مباشرةً دون سؤال.';

  @override
  String get privacyPublicHint =>
      'الصق رابطًا عامًا يمكن لـ Google فتحه (مثل gist على GitHub أو صفحة في موقعك).';

  @override
  String get privacyLocalWarning =>
      'هذا العنوان يعمل على هذا الكمبيوتر فقط ولا تستطيع Google فتحه. الصق رابطًا عامًا بدلًا منه.';

  @override
  String get consoleLinkLabel => 'رابط Play Console الخاص بك (الصقه مرة واحدة)';

  @override
  String get consoleLinkHint =>
      'افتح Play Console واختر حساب المطوّر، ثم انسخ عنوان تلك الصفحة والصقه هنا: عندها ستفتح الأزرار حسابك وتطبيقك مباشرةً.';

  @override
  String consoleLinkSaved(String id) {
    return 'تم الحفظ ✓ حساب المطوّر $id: تفتح الأزرار الآن وحدة تحكمك مباشرةً.';
  }

  @override
  String get upStateConnected => 'تم ربط Google Play (المفتاح على هذا الجهاز)';

  @override
  String get upNeedsKey =>
      'Google Play غير مرتبط على هذا الجهاز: افتح دليل النشر واضغط «افعلها أنت يا Ember» لإنشاء المفتاح (دقيقة واحدة).';

  @override
  String get upNeedsListing =>
      'اكتب صفحة المتجر مرة واحدة: اضغط «تعديل العنوان والأوصاف».';

  @override
  String get upConnectPlay => 'اربط Google Play';

  @override
  String get dsButton => 'تعبئة أمان البيانات';

  @override
  String get dsWorking =>
      'جارٍ تحليل ما يجمعه التطبيق وتعبئة نموذج أمان البيانات…';

  @override
  String get dsDone =>
      'تم إرسال أمان البيانات إلى Google Play ✓ — راجعه في Play Console ← محتوى التطبيق ← أمان البيانات واضغط إرسال.';

  @override
  String get dsNeedsCsv =>
      'صدّر النموذج أولًا من Play Console: محتوى التطبيق ← أمان البيانات ← تصدير إلى CSV. احفظه في مجلد التنزيلات ثم اضغط الزر مرة أخرى.';

  @override
  String get driveBackup => 'الحفظ في Google Drive';

  @override
  String get driveSaving => 'طلب الإذن من Google وحفظ المفتاح في Drive…';

  @override
  String get driveSaved => 'تم حفظ ملف المفاتيح وكلمة المرور في Google Drive ✓';

  @override
  String get driveOpenFolder => 'فتح المجلد في Drive';

  @override
  String get acAskPrivacy => 'اكتب سياسة الخصوصية لهذا التطبيق';

  @override
  String get acAskAdmob => 'كيف أضيف إعلانات AdMob إلى هذا التطبيق؟';

  @override
  String get acAskContent => 'بماذا أجيب في قسم محتوى التطبيق في Play Console؟';

  @override
  String get acAssistant => 'اسأل Ember عن هذا التطبيق';

  @override
  String get acTitle => 'محتوى التطبيق (Play Console)';

  @override
  String get acHint =>
      'تطرح Google هذه الأسئلة قبل نشر التطبيق. لدى Ember إجابة لكل سؤال: انسخها واخترها في Play Console.';

  @override
  String get acOpenConsole => 'فتح محتوى التطبيق';

  @override
  String get acCopy => 'نسخ الإجابة';

  @override
  String get acCopied => 'تم النسخ';

  @override
  String get acAuto => 'يتولاها Ember';

  @override
  String get paste => 'لصق';

  @override
  String get ghTitle => 'الحفظ على GitHub';

  @override
  String get ghHint =>
      'يحتفظ بنسخة من كود التطبيق في مستودعك على GitHub. لا يتم رفع مفتاح التوقيع ولا مجلد build ولا ملفات Google.';

  @override
  String get ghToken => 'رمز GitHub';

  @override
  String get ghTokenHelp =>
      'رمز وصول شخصي بصلاحية \"repo\". يُحفظ مشفّرًا على هذا الجهاز ويُستخدم فقط لرفع هذا التطبيق.';

  @override
  String get ghGetToken => 'إنشاء رمز على GitHub';

  @override
  String get ghSave => 'الحفظ على GitHub';

  @override
  String get ghSaving => 'جارٍ رفع التطبيق إلى GitHub…';

  @override
  String get ghOpen => 'فتح المستودع';

  @override
  String get ghForgetToken => 'نسيان الرمز';

  @override
  String get ghNeedsToken => 'الصق رمز GitHub أولاً.';

  @override
  String ghCreated(String repo) {
    return 'تم إنشاء المستودع $repo ورفع التطبيق ✓';
  }

  @override
  String ghUpdated(String repo) {
    return 'تم رفع التطبيق إلى $repo ✓';
  }

  @override
  String get acCopyForExtension => 'نسخ لأجل الإضافة';

  @override
  String get acFillForMe => 'التعبئة في Play Console';

  @override
  String get acFilling =>
      'يجيب Ember عن الأسئلة في نافذة Chrome التي فتحها. راقبه وتولَّ الأمر متى شئت.';

  @override
  String acFilled(int done, int total) {
    return 'تم حفظ $done من $total أقسام.';
  }

  @override
  String get acNeedsAppLink =>
      'لا يعرف Ember بعد أي تطبيق هذا في Play Console: افتحه هناك وانسخ العنوان من المتصفح والصقه في شاشة النشر.';

  @override
  String get acAppLink => 'عنوان هذا التطبيق في Play Console';

  @override
  String get acLinkNotUnderstood =>
      'هذا العنوان لا يشير إلى تطبيق. افتح التطبيق في Play Console وانسخ العنوان كاملًا من شريط المتصفح.';

  @override
  String get adsAdd => 'إضافة إعلانات AdMob';

  @override
  String get adsAddHint =>
      'يضع Ember الإعلانات في كل شاشة تحتملها، ضمن الحدود التي تُبقي حساب AdMob آمنًا، ويستخدم إعلانات Google التجريبية حتى تلصق معرّفاتك.';

  @override
  String get adsAddChat => 'إضافة إعلانات AdMob بمعرّفات تجريبية';

  @override
  String get adsYes => 'نعم، اعرض الإعلانات';

  @override
  String get adsNo => 'بدون إعلانات';

  @override
  String get adsDeclined =>
      'لا إعلانات في هذا التطبيق. اطلبها من Ember متى غيّرت رأيك.';

  @override
  String get adsRemove => 'إزالة الإعلانات';

  @override
  String get adsRemoveChat => 'إزالة AdMob من هذا التطبيق';

  @override
  String get adsAppIdHelp =>
      'الرمز الذي يحتوي على ~ بجانب أيقونة Android. وهو نفسه لكل الوحدات.';

  @override
  String get adsUnitHelp =>
      'الرمز الذي يحتوي على / بجانب أيقونة البطاقة. رمز مختلف لكل صيغة.';

  @override
  String get checkTitle => 'فحص Ember هذا التطبيق';

  @override
  String get checkAllGood => 'كل ما يلزم لتشغيل التطبيق موجود.';

  @override
  String checkFound(int count) {
    return '$count أمور لا تعمل بعد. يستطيع Ember إصلاح ما يحمل أيقونة الأداة إذا طلبت ذلك.';
  }

  @override
  String checkFixNow(int count) {
    return 'إصلاح $count';
  }

  @override
  String get checkFixing => 'جارٍ الإصلاح…';

  @override
  String get checkAgain => 'افحص مرة أخرى';

  @override
  String get checkAskEmber => 'دع Ember يصلحها';

  @override
  String get checkAsked => 'تم الطلب. يعمل Ember عليها: تابع المحادثة بالأسفل.';
}
