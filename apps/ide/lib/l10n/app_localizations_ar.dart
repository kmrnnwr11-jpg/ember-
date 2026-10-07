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
  String get loginSubtitle => 'أنشئ تطبيقات من أي جهاز، بالذكاء الاصطناعي.';

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
      'وضع التطوير: Supabase غير مُعدّ، لذا تسجّل الدخول بالبريد الإلكتروني فقط عبر الحاسوب الذي يعمل عليه Ember.';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String get passwordTooShort => '6 أحرف على الأقل';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get projects => 'تطبيقاتك';

  @override
  String get noProjects => 'لا توجد تطبيقات بعد. صِف واحدًا في الأعلى.';

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
    return 'تغيّر $path على الحاسوب الذي يعمل عليه Ember بعد أن فتحته.';
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
      'هذا العنوان يعمل على هذا الحاسوب فقط. لفتحه من الهاتف استخدم عنوان الشبكة للحاسوب الذي يعمل عليه Ember (مثال: http://192.168.1.20:8787).';

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
  String get aiSettings => 'أضف مفتاحًا';

  @override
  String get apiKeysHint =>
      'تبقى المفاتيح مشفّرة على هذا الجهاز. عندما تمر الطلبات عبر الحاسوب الذي يعمل عليه Ember، تمر المفاتيح به لذلك الطلب فقط ولا تُحفظ أبدًا.';

  @override
  String get useRunnerProxy => 'المرور عبر الحاسوب الذي يعمل عليه Ember';

  @override
  String get useRunnerProxyHint =>
      'موصى به. عطّله للاتصال بخدمات الذكاء الاصطناعي مباشرة من هذا الجهاز.';

  @override
  String get useRunnerProxyWeb =>
      'مفعّل دائمًا في المتصفح: صفحة الويب لا تستطيع الاتصال بخدمات الذكاء الاصطناعي مباشرة.';

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
    return 'يعمل ($model)';
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
      'Claude Code غير متاح: يجب أن يكون مثبّتًا ومسجّل الدخول على الحاسوب الذي يعمل عليه Ember.';

  @override
  String get appPromptHint => 'مثال: تطبيق وصفات مع صور وقائمة تسوّق ومؤقّت…';

  @override
  String get chooseAi => 'من يكتب الكود';

  @override
  String get createApp => 'أنشئ التطبيق';

  @override
  String get openEditor => 'المحرر';

  @override
  String get describeYourApp => 'ما التطبيق الذي تريد إنشاءه؟';

  @override
  String get describeYourAppHint =>
      'اكتب ما يجب أن يفعله وكيف تتخيّله. Ember يبنيه ويتحقق منه ويعرضه لك.';

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
  String get appReadyTitle => 'تطبيقك جاهز';

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
  String get androidFileQuestion => 'هل تريد ملف Android؟';

  @override
  String get androidFileHint =>
      'ملف التثبيت (APK): يُثبَّت على الهاتف. ملف Google Play (AAB): يُرفع إلى Google Play Console. كلاهما موقّع.';

  @override
  String get generateApk => 'أنشئ ملف التثبيت (APK)';

  @override
  String get generateAab => 'أنشئ ملف Google Play (AAB)';

  @override
  String androidBuilding(String kind) {
    return 'جارٍ إنشاء ملف $kind… قد تستغرق المرة الأولى 3-5 دقائق.';
  }

  @override
  String get downloadApk => 'نزّل الملف وثبّته (APK)';

  @override
  String get downloadAab => 'نزّل ملف Google Play (AAB)';

  @override
  String get apkInstallHint =>
      'ملف التثبيت (APK) موقّع. إذا طلب Android ذلك، اسمح بالتثبيت من هذا المصدر.';

  @override
  String get aabHint =>
      'ملف Google Play (AAB) موقّع بمفتاح الرفع الخاص بهذا التطبيق وجاهز لـ Google Play Console. يزداد رقم الإصدار تلقائيًا في كل مرة.';

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
    return 'غير مثبّت على الحاسوب الذي يعمل عليه Ember ($name)';
  }

  @override
  String get terminalCliHint =>
      'يستخدم Claude Code و Codex و Gemini تسجيل الدخول الموجود على الحاسوب الذي يعمل عليه Ember. في المرة الأولى اتبع التعليمات في الطرفية لتسجيل الدخول.';

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
      '1. افتح **Google Cloud**: ستنشئ **مفتاح حساب خدمة**، مرة واحدة لكل تطبيقاتك.\n2. فعّل **Google Play Android Developer API**.\n3. اذهب إلى **حسابات الخدمة** واضغط **إنشاء**.\n4. افتح **المفاتيح** ← **إضافة مفتاح** ← **JSON**. سيُنزَّل ملف.\n5. في **Play Console** اذهب إلى **المستخدمون والأذونات** ← **دعوة مستخدمين جدد**.\n6. الصق بريد حساب الخدمة وامنحه أذونات **النشر**.\n7. افتح ملف JSON الذي نزّلته و**الصق محتواه بالكامل هنا**.\n8. انتهيت: يبقى المفتاح مشفّرًا على هذا الجهاز ويُستخدم للرفع فقط.';

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
    return 'تم الرفع. الإصدار $version على مسار «$track». $draft';
  }

  @override
  String get playDraftNote =>
      'لأن التطبيق لم يُنشر من قبل، حفظته Google كمسودة: أكمل الخطوات أدناه واضغط «إرسال للمراجعة» في Play Console.';

  @override
  String get playReviewNotSent =>
      'تعذّر على Google إرسال التغييرات للمراجعة تلقائيًا. تم حفظها: افتح Play Console واضغط على \"إرسال للمراجعة\" للنشر.';

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
      'المساعد المجاني غير مفعّل بعد: مفتاح Gemini غير موجود على الحاسوب الذي يعمل عليه Ember.';

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
  String get bNoErrors => 'لا توجد أخطاء';

  @override
  String bErrorsFound(int count) {
    return 'تم العثور على $count أخطاء';
  }

  @override
  String get bClaudeApplying => 'يقوم Claude Code بتطبيق التعديل…';

  @override
  String get bClaudeBuilding => 'يقوم Claude Code ببناء التطبيق على الكمبيوتر…';

  @override
  String statusBuilding(String progress) {
    return 'جارٍ الإنشاء… $progress ملفات';
  }

  @override
  String get bClaudeFailed => 'لم يُكمل Claude Code التطبيق: راجع السجل.';

  @override
  String resumeFromHere(int count) {
    return 'أكمل من هنا ($count ملفات)';
  }

  @override
  String get startOver => 'ابدأ من جديد';

  @override
  String bClaudeStoppedCarryOn(int count) {
    return 'توقّف بعد كتابة $count ملفات: أتابع وأصلح ما تبقّى.';
  }

  @override
  String get bWebBuilding => 'جارٍ بناء التطبيق للويب (حوالي 30 ثانية)…';

  @override
  String bWebFailed(String log) {
    return 'فشل بناء نسخة الويب:\n$log';
  }

  @override
  String get bApk =>
      'أنشئ ملف التثبيت (APK). قد تستغرق المرة الأولى بضع دقائق…';

  @override
  String get bAab => 'أنشئ ملف Google Play (AAB)…';

  @override
  String get chooseDesignAi => 'من يرسم (الشعار، النماذج، الشاشات)';

  @override
  String get chooseDesignAiHint =>
      'اختر من يرسم: كل واحد يصنع نموذجين، والشعارات الخمسة تتوزع بينهم. المحرك أعلاه يكتب الكود.';

  @override
  String get bLookingAtModel => 'أتفحّص التطبيق المراد نسخه…';

  @override
  String get bIpa => 'أنشئ تطبيق iPhone (IPA)…';

  @override
  String get nameTitle => 'ما اسم تطبيقك؟';

  @override
  String get nameHint =>
      'يظهر هذا الاسم في متجر Play وفي سياسة الخصوصية وداخل اسم الحزمة، ولا يمكن تغييره بعد ذلك.';

  @override
  String get nameYourOwn => 'أو اكتب اسمك الخاص';

  @override
  String get nameMore => 'أسماء أخرى';

  @override
  String get nameUse => 'استخدم هذا الاسم';

  @override
  String bReferenceShots(int count) {
    return 'تم حفظ $count شاشات من التطبيق المراد نسخه: المحرّك يراه ولا يكتفي بقراءة وصفه';
  }

  @override
  String get bReferenceShotsFailed =>
      'لم أتمكن من تنزيل شاشات التطبيق المراد نسخه: أتابع اعتمادًا على الوصف فقط';

  @override
  String bMissingTopics(String topics) {
    return 'ينقص مقارنةً بالتطبيق المراد نسخه: $topics. أضيفه الآن…';
  }

  @override
  String get bIosReady => 'تطبيق iPhone جاهز';

  @override
  String get bIosFailed => 'تعذّر إنشاء تطبيق iPhone';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iPhone';

  @override
  String get iosTitle => 'تطبيق iPhone';

  @override
  String get iosHint =>
      'التطبيق نفسه لـ iPhone و iPad: الاسم نفسه والشاشات نفسها والإعلانات نفسها. الملف (IPA) يُرسل إلى App Store Connect.';

  @override
  String get iosNeedsMac =>
      'لا يمكن إنشاء تطبيق iPhone إلا على Mac. احفظ التطبيق على GitHub، ثم افتح Ember على Mac وأنشئه هناك. كل ما عدا ذلك تفعله من هنا.';

  @override
  String get iosBuild => 'أنشئ تطبيق iPhone';

  @override
  String get iosBuilding => 'جارٍ إنشاء تطبيق iPhone…';

  @override
  String get iosReady =>
      'تطبيق iPhone جاهز. تم توقيعه بحسابك في Apple ويمكن إرساله إلى App Store Connect.';

  @override
  String get iosAppleAccount =>
      'حساب Apple Developer: ‏99 دولارًا في السنة، تُدفع لـ Apple.';

  @override
  String get ascTitle => 'أرسل إلى App Store';

  @override
  String get ascHint =>
      'يكتب Ember لدى Apple ما يكتبه لدى Google: العنوان والوصف والجديد ورابط الخصوصية وإجابات الخصوصية، بكل لغات صفحة تطبيقك.';

  @override
  String get ascKeyHelp =>
      '1. افتح App Store Connect واذهب إلى المستخدمون والوصول ← التكاملات ← App Store Connect API.\n2. اضغط + واختر دور App Manager.\n3. نزّل ملف p8. تسمح Apple بتنزيله مرة واحدة فقط.';

  @override
  String get ascKeyId => 'Key ID';

  @override
  String get ascIssuerId => 'Issuer ID';

  @override
  String get ascPrivateKey => 'محتوى الملف AuthKey_….p8';

  @override
  String get ascUploadBuild => 'أرسل ملف iPhone أيضًا (يلزم Mac)';

  @override
  String get ascSubmit => 'أرسل إلى مراجعة Apple عندما يجهز كل شيء';

  @override
  String get ascPublish => 'انشر على App Store';

  @override
  String get ascWorking => 'جارٍ التواصل مع App Store Connect…';

  @override
  String ascDone(String version, String languages) {
    return 'تم لدى Apple: الإصدار $version، اللغات: $languages';
  }

  @override
  String get ascOpen => 'افتح App Store Connect';

  @override
  String get ascForget => 'انسَ مفتاح Apple';

  @override
  String get ascManual =>
      'يبقى عليك يدويًا لدى Apple: لقطات الشاشة (مقاسات iPhone)، وأسئلة الفئة العمرية، والسعر والبلدان.';

  @override
  String bAndroidFailed(String kind) {
    return 'فشل إنشاء $kind';
  }

  @override
  String bAndroidReady(String kind) {
    return 'ملف $kind جاهز';
  }

  @override
  String get bStopped => 'تم الإيقاف';

  @override
  String get bAppReady => 'التطبيق جاهز';

  @override
  String get bReviewStart => 'ذكاءات اصطناعية أخرى تفحص التطبيق…';

  @override
  String get bReviewClean => 'لم يجد المراجعون شيئًا لإصلاحه.';

  @override
  String bReviewFound(int count) {
    return '$count مشاكل وجدها المراجعون: جارٍ إصلاحها.';
  }

  @override
  String get bAppUpdated => 'تم تحديث التطبيق';

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
  String get forgeTitle => 'Ember ينشئ تطبيقك';

  @override
  String forgeFiles(int count) {
    return 'تمت كتابة $count ملفات';
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
    return 'تمت كتابة $count من $total ملفات';
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
    return '$name غير متصل: سجّل الدخول باشتراكك على الحاسوب الذي يعمل عليه Ember.';
  }

  @override
  String connectHowTo(String plan, String command) {
    return '1. انتقل إلى الحاسوب الذي يعمل عليه Ember وافتح طرفية (طرفية Ember تصلح أيضًا).\n2. اكتب: $command\n3. أكمل تسجيل الدخول في المتصفح بحسابك في $plan: بلا مفتاح API وبلا تكلفة إضافية.\n4. عد إلى هنا: يصبح جاهزًا خلال دقيقة.';
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
      '1. قبل التفعيل، افتح Play Console. تُنفَّذ هذه الخطوات مرة واحدة لكل حساب ولكل تطبيق.\n2. اذهب إلى الإعداد ← ملف الدفعات وأضف الحساب البنكي والبيانات الضريبية.\n3. ارفع ملف Google Play (AAB) لهذا التطبيق إلى الاختبار الداخلي: تشترط Google نسخة تتضمن المدفوعات.\n4. في المستخدمون والأذونات، امنح حساب الخدمة إذن «إدارة الطلبات والاشتراكات».';

  @override
  String get productsOpenPayments => 'ملف الدفعات';

  @override
  String get productsUploadFirst => 'ارفع ملف Google Play (AAB)';

  @override
  String get productsActive => 'مفعّل على Google Play';

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
      '1. الآن أربط Ember بـ Google Play لأتمكن من رفع تطبيقاتك.\n2. **سأقوم بذلك بنفسي**: أنشئ مفتاحًا خاصًا في حسابك على Google، على هذا الكمبيوتر.\n3. لذلك أجهّز مشروع Google Cloud وواجهة Play والمفتاح.\n4. يُستخدم المفتاح لرفع التطبيقات فقط ويبقى على جهازك.';

  @override
  String get pubDoItEmber => 'افعلها أنت يا Ember';

  @override
  String get pubManual => 'أفضّل القيام بذلك يدويًا';

  @override
  String get pubKeyWorking =>
      'جارٍ إنشاء مشروع Google Cloud وتفعيل واجهة Play وإنشاء المفتاح (دقيقة أو دقيقتان)…';

  @override
  String get pubInvite =>
      'تم إنشاء المفتاح.\n\nآخر ربط: يجب أن يُسمح للمفتاح بالنشر في Play Console **الخاص بك**.\n1. اضغط **فتح Play Console** أدناه\n2. انسخ عنوان الصفحة التي تراها (أي صفحة) و**الصقه هنا في المحادثة**\n\nبعدها سيفتح متصفح الكمبيوتر مرة واحدة: سجّل الدخول بنفس حساب Google واضغط **سماح**. سأرسل الدعوة بنفسي.';

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
      'تم الربط بـ Google Play.\n\nتطلب Google لصفحة المتجر **أيقونة 512×512** و**بانر 1024×500** و**لقطتي شاشة** على الأقل. إن لم تنشئها بعد، عد إلى شاشة التطبيق: في **شعار التطبيق** و**لقطات شاشة لمتجر Play** ينشئها Ember بلمسة. سأرفعها تلقائيًا مع التطبيق.';

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
      '1. تطبيقك على Google Play. بقيت بعض النماذج: افتح **Play Console**.\n2. أكّد يدويًا **أمان البيانات** و**تصنيف المحتوى** و**الجمهور المستهدف** و**الإعلانات** و**الوصول إلى التطبيق**.\n3. انسخ الإجابات من الشاشة الأخيرة: إنها جاهزة.\n4. إن كان حسابك الشخصي جديدًا، أجرِ **اختبارًا مغلقًا مع 12 مختبرًا لمدة 14 يومًا** قبل النشر العام.\n5. لديك سؤال؟ اسألني بالأسفل.';

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
      '1. افتح AdMob. يستغرق ذلك 5 دقائق، مرة واحدة لكل تطبيق.\n2. اذهب إلى التطبيقات ← إضافة تطبيق ← Android.\n3. عند سؤال «هل التطبيق على Google Play؟» أجب بـ «لا» إن لم يُنشر بعد.\n4. اكتب الاسم واضغط إضافة.\n5. انسخ معرّف التطبيق (ca-app-pub-…~…).\n6. اذهب إلى الوحدات الإعلانية ← إضافة وحدة واختر تنسيقًا من القائمة أدناه.\n7. اضغط إنشاء وانسخ معرّفها (ca-app-pub-…/…). كرّر ذلك لكل تنسيق.\n8. بعد النشر، اربط التطبيق بصفحته في متجر Play داخل AdMob.\n9. أضف app-ads.txt إن طلبه AdMob.';

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
  String get upBuilding => 'أنشئ الملف الجديد لـ Google Play (AAB)…';

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
    return 'تم حفظ حساب المطوّر $id: تفتح الأزرار الآن وحدة تحكمك مباشرةً.';
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
      'تم إرسال أمان البيانات إلى Google Play — راجعه في Play Console ← محتوى التطبيق ← أمان البيانات واضغط إرسال.';

  @override
  String get dsNeedsCsv =>
      'صدّر النموذج أولًا من Play Console: محتوى التطبيق ← أمان البيانات ← تصدير إلى CSV. احفظه في مجلد التنزيلات ثم اضغط الزر مرة أخرى.';

  @override
  String get driveBackup => 'الحفظ في Google Drive';

  @override
  String get driveSaving => 'طلب الإذن من Google وحفظ المفتاح في Drive…';

  @override
  String get driveSaved => 'تم حفظ ملف المفاتيح وكلمة المرور في Google Drive';

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
  String get ghSavedOn => 'محفوظ على GitHub';

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
  String get ghRestoreTitle => 'افتح تطبيقًا محفوظًا على GitHub';

  @override
  String get ghRestoreHint =>
      'التطبيقات التي حفظتها على GitHub تعود إلى هذا الحاسوب بكل ما كان فيها. هكذا تعمل على التطبيق نفسه من Windows ومن Mac.';

  @override
  String get ghRestoreLoad => 'اعرض تطبيقاتي';

  @override
  String get ghRestoreNone =>
      'لا يوجد بعد أي تطبيق محفوظ من Ember في حساب GitHub هذا.';

  @override
  String get ghRestoreHere => 'موجود على هذا الحاسوب';

  @override
  String get ghRestoreAction => 'من GitHub';

  @override
  String get refresh => 'تحديث';

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
    return 'تم إنشاء المستودع $repo ورفع التطبيق';
  }

  @override
  String ghUpdated(String repo) {
    return 'تم رفع التطبيق إلى $repo';
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

  @override
  String get previewLoginInBrowser =>
      'لا تسمح Google بتسجيل الدخول داخل هذه النافذة، وتسجيل الدخول من المتصفح لا ينتقل إلى هنا. استخدم البريد وكلمة المرور هنا؛ ودخول Google يعمل في المتصفح وعلى الهاتف.';

  @override
  String get phoneTitle => 'هاتفك';

  @override
  String get phoneHint =>
      'يثبّت Ember التطبيق على الهاتف الموصول بهذا الحاسوب ويفتحه. دخول Google والإشعارات والإعلانات تعمل كما ينبغي هناك فقط.';

  @override
  String phoneRunOn(String name) {
    return 'التشغيل على $name';
  }

  @override
  String phoneUnauthorized(String name) {
    return '$name: افتح قفله واسمح بتصحيح USB';
  }

  @override
  String get phoneBuilding => 'تحضير التطبيق للهاتف…';

  @override
  String get phoneInstalling => 'جارٍ التثبيت على الهاتف…';

  @override
  String get phoneLookAgain => 'ابحث عن الهواتف مجددًا';

  @override
  String get phoneOpenHere => 'افتحه الآن على الهاتف';

  @override
  String get phoneSameWifi =>
      'وجّه كاميرا الهاتف نحو الرمز. يجب أن يكون الهاتف على نفس شبكة Wi-Fi لهذا الحاسوب.';

  @override
  String get playLanguages => 'لغات صفحة المتجر';

  @override
  String get playTranslating => 'جارٍ كتابة الصفحة باللغات الأخرى…';

  @override
  String get logoDelete => 'حذف';

  @override
  String get logoDeleted => 'تم حذف الشعار';

  @override
  String get logoDropHint => 'اسحب شعارًا هنا للحصول على 5 نسخ منه';

  @override
  String get logoVariantsOf => 'نسخ من هذا الشعار';

  @override
  String get playUpdateListingOnly => 'تحديث صفحة المتجر فقط';

  @override
  String get playUpdateListingOnlyHint =>
      'لتطبيق موجود على Google Play: النصوص وكل اللغات والصور بدون إصدار جديد.';

  @override
  String get playTranslationsStale =>
      'تغيّر النص: اللغات الأخرى ما زالت بالنص القديم.';

  @override
  String get playTranslateAgain => 'ترجمة من جديد';

  @override
  String get playLanguageIncluded => 'نشر هذه اللغة على Google Play';

  @override
  String get playLanguageNotTranslated =>
      'لم تُترجم بعد: تُكتب عند الحفظ مع تفعيل هذه اللغة.';

  @override
  String get playListingSaved =>
      'تم حفظ الصفحة: لا حاجة للتوليد. عدّل النص إن أردت ثم ارفع.';

  @override
  String get playRewriteWithAi => 'إعادة الكتابة بالذكاء الاصطناعي';

  @override
  String get historyTitle => 'السجل';

  @override
  String get historyNewApp => 'تطبيق جديد';

  @override
  String get historyDrafts => 'المسودات';

  @override
  String get historyToday => 'اليوم';

  @override
  String get historyYesterday => 'أمس';

  @override
  String get historyLast7Days => 'آخر 7 أيام';

  @override
  String get historyOlder => 'الأقدم';

  @override
  String get historyEmpty =>
      'لا شيء هنا بعد. التطبيقات التي تبدأها والمسودات التي تكتبها تظهر هنا.';

  @override
  String get brandTagline => 'صانع التطبيقات';

  @override
  String get showSecret => 'إظهار';

  @override
  String get hideSecret => 'إخفاء';

  @override
  String get ok => 'موافق';

  @override
  String get details => 'التفاصيل';

  @override
  String get more => 'المزيد';

  @override
  String get advanced => 'متقدم';

  @override
  String get done => 'تم';

  @override
  String madeWith(String engine) {
    return 'تُنشأ بواسطة $engine · خيارات';
  }

  @override
  String get buildOptionsTitle => 'من يبني تطبيقك';

  @override
  String get homeMenu => 'طرق أخرى للبدء';

  @override
  String get emptyProject => 'مشروع فارغ';

  @override
  String get settings => 'الإعدادات';

  @override
  String get hubNextSteps => 'الخطوات التالية';

  @override
  String get hubTest => 'جرّبه على هاتفك';

  @override
  String get hubTestHint => 'افتحه برمز QR أو ثبّته';

  @override
  String get hubImages => 'الأيقونة والصور';

  @override
  String get hubImagesHint => 'الشعار ولقطات المتجر';

  @override
  String get hubChecks => 'الفحوصات';

  @override
  String get hubChecksHint => 'ما وجده Ember والمراجعون';

  @override
  String hubChecksCount(int count) {
    return '$count للإصلاح';
  }

  @override
  String get hubPlay => 'Google Play';

  @override
  String get hubPlayHint => 'انشر أو حدّث على أندرويد';

  @override
  String get hubAppStore => 'App Store';

  @override
  String get hubAppStoreHint => 'انشر للآيفون';

  @override
  String get hubMore => 'المزيد';

  @override
  String get hubMoreHint => 'النسخ الاحتياطي، الإعلانات، المشتريات، الكود';

  @override
  String get techDetails => 'التفاصيل التقنية';

  @override
  String get changeHint => 'ماذا تريد أن تغيّر؟';

  @override
  String get installFileTitle => 'ملف للتثبيت (APK)';

  @override
  String get installFileHint => 'ملف يمكنك إرساله إلى أي هاتف أندرويد وتثبيته.';

  @override
  String get storeFileTitle => 'ملف لـ Google Play (AAB)';

  @override
  String get storeFileHint =>
      'مطلوب فقط إذا كنت ترفع يدويًا إلى Play Console: يجهّزه Ember عند النشر.';

  @override
  String get makeFile => 'جهّز الملف';

  @override
  String get openCodeTitle => 'الكود';

  @override
  String get openCodeHint => 'افتح المحرر لقراءة الملفات أو تعديلها يدويًا.';

  @override
  String get backToApp => 'العودة إلى التطبيق';

  @override
  String designChosen(String name) {
    return 'التصميم: $name';
  }

  @override
  String get reviewFixLabel => 'تصحيح من المراجعين';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get themeSystem => 'مثل الجهاز';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get settingsAi => 'الذكاء الاصطناعي';

  @override
  String get settingsAccounts => 'الحسابات المرتبطة';

  @override
  String get settingsAccountsHint =>
      'تُربط عند أول حاجة إليها من صفحة التطبيق. هنا يمكنك رؤيتها وفصلها.';

  @override
  String accountConnected(String name) {
    return '$name: مرتبط';
  }

  @override
  String accountNotConnected(String name) {
    return '$name: غير مرتبط';
  }

  @override
  String get disconnect => 'فصل';

  @override
  String get runnerAddress => 'أين يعمل Ember';

  @override
  String get runnerAddressHint =>
      'عنوان الحاسوب الذي يبني تطبيقاتك (Runner). غيّره فقط إذا طُلب منك ذلك.';

  @override
  String signedInAs(String email) {
    return 'تم الدخول باسم $email';
  }

  @override
  String get reviewersTitle => 'مراجعو التطبيق';

  @override
  String get reviewersHint =>
      'عند انتهاء التطبيق تقرؤه هذه النماذج بنفسها وتخبرك بما هو مزيّف وما ينقص وما لا يعمل؛ وتعود التصحيحات تلقائيًا إلى من كتب التطبيق. تُضبط مرة واحدة وتُستخدم لكل التطبيقات.';

  @override
  String get aiKeysTitle => 'المفاتيح';

  @override
  String plLanguagesOn(int count) {
    return 'اللغات: $count مفعّلة';
  }

  @override
  String get plManage => 'إدارة';

  @override
  String get plLanguagesHint =>
      'فعّل لغة لنشر صفحة المتجر بها. اضغط على لغة لقراءة نصها أو تصحيحه.';

  @override
  String get plSearchLanguage => 'ابحث عن لغة';

  @override
  String get plNoLanguageFound => 'لا توجد لغة بهذا الاسم.';

  @override
  String get plEnglish => 'الإنجليزية';

  @override
  String get plMainLanguage => 'اللغة الرئيسية، مفعّلة دائمًا';

  @override
  String get plLangReady => 'مترجمة';

  @override
  String get plLangOld => 'نص قديم';

  @override
  String get plLangMissing => 'لم تُكتب بعد';

  @override
  String get plLangWriting => 'جارٍ الكتابة…';

  @override
  String get plGenerating => 'Ember يكتب صفحة المتجر…';

  @override
  String get plFeeTitle => 'Google يطلب 25 دولارًا مرة واحدة';

  @override
  String get plAiBadAnswer =>
      'أعطى الذكاء الاصطناعي إجابة لم يستطع Ember قراءتها. حاول مرة أخرى.';

  @override
  String get plNoAi =>
      'لم يتم إعداد أي ذكاء اصطناعي بعد: أضف واحدًا من الإعدادات.';

  @override
  String get plPrivacyLocalOnly =>
      'سياسة الخصوصية محفوظة على هذا الحاسوب فقط: لا يستطيع Google فتحها. اربط GitHub في Ember، أو الصق رابطًا خاصًا بك في الأسفل.';

  @override
  String plPrivacyNotPublished(String error) {
    return 'لم تُنشر سياسة الخصوصية: $error. تم حفظ باقي صفحة المتجر؛ الصق رابطًا خاصًا بك في الأسفل.';
  }

  @override
  String get asConnTitle => 'مفتاح Apple الخاص بك';

  @override
  String get asConnHint =>
      'يستخدمه Ember للنشر بدلاً منك. تحفظه مرة واحدة ويصلح لكل تطبيقاتك.';

  @override
  String asKeySaved(String file) {
    return 'تم حفظ المفتاح: $file';
  }

  @override
  String get asChangeKey => 'تغيير المفتاح';

  @override
  String get asTeamId => 'Team ID (اختياري)';

  @override
  String get asTeamIdHelp =>
      'يلزم لتوقيع تطبيق iPhone. اتركه فارغاً وسيقرؤه Ember من Apple باستخدام مفتاحك.';

  @override
  String get asP8KeepHelp => 'اتركه فارغاً للاحتفاظ بالمفتاح المحفوظ.';

  @override
  String get asLoadP8 => 'تحميل ملف ‎.p8';

  @override
  String get asSaveKey => 'حفظ المفتاح';

  @override
  String get asP8FileType => 'مفتاح Apple ‏(‎.p8)';

  @override
  String get asVerify => 'التحقق من الاتصال';

  @override
  String get asVerifyOk => 'الاتصال يعمل';

  @override
  String get asVerifyOkReached =>
      'الاتصال يعمل: وصل Ember إلى App Store Connect';

  @override
  String asVerifyTeam(String team) {
    return 'Team $team';
  }

  @override
  String get asBadKeyId =>
      'هذا الـ Key ID غير صالح. هو الرمز القصير بجانب المفتاح، مثل Z47GM3ZDZ6.';

  @override
  String get asBadIssuerId =>
      'هذا الـ Issuer ID غير صالح. هو الرمز الطويل أعلى صفحة المفاتيح.';

  @override
  String get asBadP8 =>
      'هذا ليس محتوى المفتاح. الصق ملف AuthKey_….p8 كاملاً، من السطر -----BEGIN PRIVATE KEY----- إلى -----END PRIVATE KEY-----. اسم الملف وحده لا يكفي.';

  @override
  String asP8ReadFailed(String error) {
    return 'تعذّر على Ember قراءة ملف ‎.p8: $error';
  }

  @override
  String get asSaveKeyFirst =>
      'احفظ مفتاح Apple أولاً: Key ID و Issuer ID وملف ‎.p8.';

  @override
  String get asFillTitle => 'ما يملؤه Ember عنك';

  @override
  String get asFillHint =>
      'عند النشر يضبط Ember بنفسه الفئة العمرية (4+) وإقرار التشفير وإجابات الخصوصية. وإذا اخترتها هنا، يضبط أيضاً الفئة والسعر ولقطات الشاشة.';

  @override
  String get asCategory => 'فئة App Store';

  @override
  String get asCategoryNone => 'عدم التحديد';

  @override
  String get asFree => 'تطبيق مجاني (في كل البلدان)';

  @override
  String get asScreenshots => 'إنشاء ورفع لقطات شاشة iPhone و iPad';

  @override
  String get asScreenshotsHelp =>
      'تؤخذ من المعاينة على الويب. يحتاج التطبيق إلى «وضع لقطات الشاشة».';

  @override
  String get asReviewTitle => 'بيانات لمراجعة Apple (اختيارية)';

  @override
  String get asReviewEmail => 'بريد التواصل';

  @override
  String get asReviewEmailHelp => 'اتركه فارغاً لاستخدام بريد حسابك.';

  @override
  String get asMarketingUrl => 'موقعك (Marketing URL)';

  @override
  String get asMarketingUrlHelp =>
      'يبحث AdMob هنا عن ملف app-ads.txt. يُحفظ لكل تطبيقاتك.';

  @override
  String get asReviewPhone => 'هاتف التواصل';

  @override
  String get asReviewPhoneHelp =>
      'تطلبه Apple، مثل ‎+39 333 1234567. لا يراه إلا من يراجع التطبيق. يتذكره Ember لتطبيقاتك القادمة.';

  @override
  String get asReviewNotes => 'ملاحظات للمراجع';

  @override
  String get asDemoUser => 'حساب تجريبي (إذا كان التطبيق يتطلب تسجيل الدخول)';

  @override
  String get asDemoPass => 'كلمة مرور الحساب التجريبي';

  @override
  String get asChecksTitle => 'قبل الإرسال';

  @override
  String get asChecksNone => 'لا توجد مشاكل لدى Apple.';

  @override
  String asChecksBlock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مشكلة تمنع الإرسال.',
      few: '$count مشاكل تمنع الإرسال.',
      two: 'مشكلتان تمنعان الإرسال.',
      one: 'مشكلة واحدة تمنع الإرسال.',
    );
    return '$_temp0';
  }

  @override
  String get asChecksWarn => 'تنبيهات فقط: يمكن الإرسال.';

  @override
  String get asBlocks => 'يمنع الإرسال';

  @override
  String get asWarning => 'تنبيه';

  @override
  String asFixDone(String message) {
    return 'تم الإصلاح: $message';
  }

  @override
  String asFixFailed(String message) {
    return 'لم يتم الإصلاح: $message';
  }

  @override
  String asCanClose(int minutes) {
    return 'يمكنك إغلاق هذه الصفحة: يواصل Ember بنفسه ويرسل التطبيق للمراجعة فور انتهاء Apple ($minutes د).';
  }

  @override
  String asRunningFor(int minutes) {
    return 'جارٍ منذ $minutes د.';
  }

  @override
  String get asDoneExport => 'تم ضبط إقرار التشفير';

  @override
  String get asDoneAge => 'تم ملء الفئة العمرية';

  @override
  String get asDoneCategory => 'تم ضبط الفئة';

  @override
  String get asDoneReview => 'تم حفظ بيانات المراجعة';

  @override
  String get asDoneFree => 'السعر: مجاني في كل البلدان';

  @override
  String get asDonePrivacy => 'تم ملء إجابات الخصوصية';

  @override
  String asDoneShots(int count) {
    return 'لقطات الشاشة المرفوعة: $count';
  }

  @override
  String get asCatUtilities => 'أدوات مساعدة';

  @override
  String get asCatProductivity => 'الإنتاجية';

  @override
  String get asCatBusiness => 'الأعمال';

  @override
  String get asCatEducation => 'التعليم';

  @override
  String get asCatEntertainment => 'الترفيه';

  @override
  String get asCatFinance => 'المالية';

  @override
  String get asCatFoodAndDrink => 'الطعام والشراب';

  @override
  String get asCatHealthAndFitness => 'الصحة واللياقة';

  @override
  String get asCatLifestyle => 'نمط الحياة';

  @override
  String get asCatMusic => 'الموسيقى';

  @override
  String get asCatNavigation => 'الملاحة';

  @override
  String get asCatNews => 'الأخبار';

  @override
  String get asCatPhotoAndVideo => 'الصور والفيديو';

  @override
  String get asCatReference => 'المراجع';

  @override
  String get asCatShopping => 'التسوق';

  @override
  String get asCatSocial => 'التواصل الاجتماعي';

  @override
  String get asCatSports => 'الرياضة';

  @override
  String get asCatTravel => 'السفر';

  @override
  String get asCatWeather => 'الطقس';

  @override
  String get asCatBooks => 'الكتب';

  @override
  String get asCatDeveloperTools => 'أدوات المطورين';

  @override
  String get asCatGraphicsAndDesign => 'الرسومات والتصميم';

  @override
  String get asCatGames => 'الألعاب';

  @override
  String get reviewTitle => 'فحص التطبيق';

  @override
  String get reviewHintNone =>
      'دع عدة أنظمة ذكاء اصطناعي تفحص التطبيق بعد اكتماله: كل واحد يقرؤه بمفرده ويقول ما هو زائف وما ينقص وما لا يعمل. أضف مراجعًا واحدًا على الأقل في الأسفل.';

  @override
  String reviewHintReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مراجعين جاهزون',
      two: 'مراجعان جاهزان',
      one: 'مراجع واحد جاهز',
    );
    return '$_temp0. كل واحد يقرأ التطبيق بمفرده؛ وما يلاحظه أكثر من واحد يظهر في أعلى القائمة.';
  }

  @override
  String get reviewReviewers => 'المراجعون';

  @override
  String get reviewReading => 'المراجعون يقرؤون التطبيق…';

  @override
  String reviewNoAnswer(String name) {
    return '$name: لا يستجيب';
  }

  @override
  String get reviewNothingFound => 'لم يجد المراجعون أي مشكلة.';

  @override
  String get reviewAddReviewer => 'أضف مراجعًا';

  @override
  String get reviewRun => 'افحص التطبيق';

  @override
  String get reviewKeySavedMask => '•••••• (المفتاح محفوظ)';

  @override
  String get reviewPasteKeyHint => 'الصق المفتاح هنا';

  @override
  String get reviewRemoveKey => 'أزل المفتاح';

  @override
  String get reviewFixedRecheck => 'تم التصحيح: يحتاج إلى فحص جديد';

  @override
  String get reviewFixing => 'جارٍ التصحيح…';

  @override
  String get reviewFix => 'صحّح';

  @override
  String get reviewPasteKeyFirst => 'الصق المفتاح أولًا.';

  @override
  String get reviewKeySaved => 'تم حفظ المفتاح.';

  @override
  String get reviewKeyRemoved => 'تمت إزالة المفتاح.';

  @override
  String needsYouTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مطلوب منك $count أمور',
      two: 'مطلوب منك أمران',
      one: 'مطلوب منك أمر واحد',
    );
    return '$_temp0';
  }

  @override
  String get needsYouHint =>
      'لا يستطيع Ember إنجازها وحده (تسجيل دخول، مفتاح، حساب). أنجزها واضغط «تم»: يتابع من حيث توقف.';

  @override
  String get needsYouIgnore => 'تجاهل';

  @override
  String listAnd(String first, String last) {
    return '$first و$last';
  }

  @override
  String panelDownOne(String names) {
    return '$names لا يعمل';
  }

  @override
  String panelDownMany(String names) {
    return '$names لا تعمل';
  }

  @override
  String get panelNoneLeft =>
      'لم يبقَ أي ذكاء اصطناعي: لا يمكن رسم أو فحص أي شيء. أعد المحاولة أو أغلق.';

  @override
  String get panelOneLeft =>
      'لم يبقَ إلا ذكاء اصطناعي واحد: سيرسم وحده ولن يفحص أحد عمله.';

  @override
  String panelSomeLeft(int count) {
    return 'بقي $count من أنظمة الذكاء الاصطناعي تعمل معًا ويفحص بعضها بعضًا.';
  }

  @override
  String panelProceedWithout(String name) {
    return 'تابع بدون $name';
  }

  @override
  String panelProceedWithoutMany(int count) {
    return 'تابع بدون $count من أنظمة الذكاء الاصطناعي';
  }

  @override
  String get panelAllOk => 'كل أنظمة الذكاء الاصطناعي تعمل';

  @override
  String get panelHoldNote =>
      'لا يبدأ شيء قبل أن تقرر. إن كانت المشكلة في تسجيل الدخول أو في المفتاح، أصلحها الآن واضغط إعادة المحاولة: عندما يعود إلى الأخضر يتابع الجميع معًا.';

  @override
  String get panelRetryAll => 'أعد محاولة الجميع';

  @override
  String get panelContinueAll => 'تابع مع الجميع';

  @override
  String get panelTrying => 'جارٍ المحاولة…';

  @override
  String get pingNoAnswer => 'لا توجد إجابة';

  @override
  String get pingTimeout => 'لا يستجيب (25 ثانية)';

  @override
  String get mockupRefined => 'أُعيد رسمه وفق الملاحظات';

  @override
  String mockupPanelNotes(String notes) {
    return 'ملاحظات اللجنة: $notes';
  }

  @override
  String mockupAgreeing(int count) {
    return 'أنظمة الذكاء الاصطناعي ($count) تختار معًا الاتجاهات الثمانية…';
  }

  @override
  String mockupComparing(int count, int mockups) {
    return 'المصممون ($count) يقارنون النماذج ($mockups)…';
  }

  @override
  String get mockupRedrawing => 'كل مصمم يعيد رسم نموذجه وفق ملاحظات الآخرين…';

  @override
  String get mockupInvalid => 'لم يُرجع النموذج تصميمًا صالحًا';

  @override
  String get assistantSignIn => 'سجّل الدخول لاستخدام المساعد';

  @override
  String get imagesLabel => 'الصور';

  @override
  String assistantImageTooLarge(String name) {
    return '$name: الصورة كبيرة جدًا (الحد الأقصى 3.5 ميغابايت)';
  }

  @override
  String get assistantAddImage => 'أضف صورة';

  @override
  String get assistantFixApp => 'أصلح التطبيق بهذا الطلب';

  @override
  String get findPrevious => 'النتيجة السابقة';

  @override
  String get findNext => 'النتيجة التالية';

  @override
  String get toggleReplace => 'إظهار أو إخفاء الاستبدال';

  @override
  String get clearConsole => 'امسح السجل';

  @override
  String get stopAutoRebuild => 'أوقف إعادة البناء عند الحفظ';

  @override
  String get deviceTablet => 'جهاز لوحي';

  @override
  String get deviceDesktop => 'حاسوب';

  @override
  String get checkEmailToConfirm => 'تحقق من بريدك الإلكتروني لتأكيد التسجيل.';

  @override
  String get offlineTitle => 'Ember غير مُشغَّل';

  @override
  String get offlineHint =>
      'شغّل Ember على حاسوبك ثم اضغط إعادة المحاولة. لا حاجة لتسجيل الدخول.';

  @override
  String get flowDescribe => 'صِف';

  @override
  String get flowStyle => 'اختر الشكل';

  @override
  String get flowName => 'سمِّه';

  @override
  String get flowBuild => 'Ember يبنيه';

  @override
  String get homeEyebrow => 'من فكرة إلى تطبيق';

  @override
  String get subsTitle => 'اشتراكاتك في Claude وChatGPT وGemini وQwen';

  @override
  String get subsHint =>
      'يبني Ember بالاشتراكات التي تدفعها بالفعل. تسجّل الدخول مرة واحدة على هذا الحاسوب ويبقى مسجّلًا: بلا مفاتيح وبلا تكلفة إضافية.';

  @override
  String get subsConnect => 'ربط';

  @override
  String get subsOpenWindow => 'افتح نافذة تسجيل الدخول';

  @override
  String subsLoginOpened(String name) {
    return 'انفتحت نافذة على هذا الحاسوب: سجّل الدخول إلى $name هناك ثم عُد. سيلاحظ Ember ذلك تلقائيًا.';
  }

  @override
  String get fxTitle => 'المصنع';

  @override
  String get fxNavOverview => 'نظرة عامة';

  @override
  String get fxNavNew => 'دفعة جديدة';

  @override
  String get fxNavNeeds => 'يحتاجك';

  @override
  String get fxNavLinks => 'الاتصالات';

  @override
  String get fxPause => 'إيقاف مؤقت';

  @override
  String get fxResume => 'استئناف';

  @override
  String get fxLoading => 'جارٍ تحميل المصنع…';

  @override
  String get fxLess => 'أقل';

  @override
  String get fxMore => 'أكثر';

  @override
  String get fxStageCreate => 'إنشاء المشروع';

  @override
  String get fxStageCode => 'كتابة التطبيق';

  @override
  String get fxStageVerify => 'فحص الكود';

  @override
  String get fxStagePreview => 'إعداد المعاينة';

  @override
  String get fxStageLogo => 'رسم الشعار';

  @override
  String get fxStageListing => 'كتابة نصوص المتجر';

  @override
  String get fxStageShots => 'التقاط لقطات الشاشة';

  @override
  String get fxStageAndroid => 'بناء ملف أندرويد';

  @override
  String get fxStagePlay => 'الرفع إلى Google Play (مسودة، اختبار)';

  @override
  String get fxStageIos => 'بناء تطبيق آيفون';

  @override
  String get fxStageAppStore => 'الرفع إلى App Store (TestFlight)';

  @override
  String get fxStagePending => 'لم يبدأ';

  @override
  String get fxStageSkipped => 'تم التخطي';

  @override
  String get fxStatusQueued => 'في الانتظار';

  @override
  String get fxStatusRunning => 'قيد العمل';

  @override
  String get fxStatusNeedsYou => 'يحتاجك';

  @override
  String get fxStatusDone => 'جاهز';

  @override
  String get fxStatusFailed => 'فشل';

  @override
  String get fxStatusCancelled => 'أُلغي';

  @override
  String fxStagesDone(int done, int total) {
    return 'اكتملت $done من $total خطوات';
  }

  @override
  String get fxHeadDone => 'جاهز';

  @override
  String get fxHeadNeedsYou => 'ينتظرك';

  @override
  String fxHeadFailed(String stage) {
    return 'فشل: $stage';
  }

  @override
  String fxHeadRunning(String stage) {
    return 'الآن: $stage';
  }

  @override
  String fxHeadQueued(String stage) {
    return 'تنتظر دورها: $stage';
  }

  @override
  String fxHeadWaitingTomorrow(String stage) {
    return 'جاهزة، تنتظر الحد اليومي: $stage';
  }

  @override
  String fxWaitsUntil(String when) {
    return 'تنتظر حتى $when';
  }

  @override
  String get fxNeedPlayAppTitle => 'أنشئ التطبيق في Google Play Console';

  @override
  String get fxNeedPlayAppDetail =>
      '1. افتح Google Play Console واضغط «إنشاء تطبيق».\n2. الصق الاسم واختر اللغة و«تطبيق» و«مجاني».\n3. وافق على الإقرارات واضغط «إنشاء تطبيق».\n4. ارجع إلى هنا واضغط «تم، تابع»: يبدأ الرفع تلقائياً.';

  @override
  String get fxNeedAppleAppTitle => 'أنشئ التطبيق في App Store Connect';

  @override
  String get fxNeedAppleAppDetail =>
      '1. افتح App Store Connect وانتقل إلى «Apps» واضغط «+» ثم «New App».\n2. الصق الاسم ومعرّف الحزمة (Bundle ID) ورمز SKU أدناه.\n3. اضغط «Create».\n4. ارجع إلى هنا واضغط «تم، تابع».';

  @override
  String get fxNeedMacTitle => 'تطبيق آيفون يحتاج إلى جهاز Mac';

  @override
  String get fxNeedMacDetail =>
      'تسمح Apple ببناء تطبيق آيفون على جهاز Mac فقط. الكود محفوظ: افتح Ember على جهاز Mac واستعد التطبيق من GitHub وسيتم جزء آيفون هناك.';

  @override
  String get fxNeedPlayKeyTitle => 'اربط مفتاح Google Play';

  @override
  String get fxNeedPlayKeyDetail =>
      '1. اضغط «اربط الآن».\n2. اختر ملف مفتاح حساب الخدمة.\n3. تكمل التطبيقات المنتظرة طريقها بنفسها.';

  @override
  String get fxNeedAppleKeyTitle => 'اربط مفتاح App Store Connect';

  @override
  String get fxNeedAppleKeyDetail =>
      '1. اضغط «اربط الآن».\n2. أدخل Issuer ID وKey ID واختر ملف .p8.\n3. تكمل التطبيقات المنتظرة طريقها بنفسها.';

  @override
  String fxNeedLoginTitle(String engine) {
    return 'سجّل الدخول مجدداً إلى $engine';
  }

  @override
  String get fxNeedLoginDetail =>
      'انتهت صلاحية تسجيل الدخول. افتح صفحة الاتصالات واضغط «اتصال» بجانب المحرك وسجّل الدخول. ثم اضغط «تم، تابع».';

  @override
  String get fxDataName => 'الاسم';

  @override
  String get fxDataPackage => 'اسم الحزمة';

  @override
  String get fxDataShort => 'وصف قصير';

  @override
  String get fxDataCategory => 'الفئة';

  @override
  String get fxDataBundleId => 'معرّف الحزمة (Bundle ID)';

  @override
  String get fxDataSku => 'SKU';

  @override
  String get fxDataEngine => 'المحرك';

  @override
  String get fxNeedsDone => 'تم، تابع';

  @override
  String get fxNeedsSkip => 'تخطَّ هذه الخطوة';

  @override
  String get fxNeedsEmpty => 'لا شيء يحتاجك الآن.';

  @override
  String get fxNeedsIntro =>
      'هذه أمور لا يستطيع فعلها سواك. عندما تنهي أحدها اضغط «تم، تابع» ويتابع المصنع عمله.';

  @override
  String get fxEmpty =>
      'لا توجد تطبيقات في المصنع بعد. ابدأ دفعة وصِف حتى 100 تطبيق دفعة واحدة.';

  @override
  String get fxNoMatch => 'لا يوجد تطبيق مطابق.';

  @override
  String get fxSearch => 'ابحث في التطبيقات';

  @override
  String get fxFilterAll => 'الكل';

  @override
  String get fxStatTotal => 'التطبيقات';

  @override
  String get fxOnPlay => 'على Google Play';

  @override
  String get fxOnAppStore => 'على App Store';

  @override
  String get fxPausedTitle => 'المصنع متوقف مؤقتاً';

  @override
  String get fxPausedHint => 'لن يبدأ شيء جديد حتى تستأنف.';

  @override
  String get fxPausedRestart =>
      'أُغلق Ember أو أُعيد تشغيله أثناء صنع التطبيقات. لا يُستأنف شيء تلقائياً، فلا يُستهلك أي اشتراك دون علمك.';

  @override
  String get fxLowDiskTitle => 'القرص شبه ممتلئ';

  @override
  String get fxLowDiskHint =>
      'لن يبدأ أي تطبيق جديد حتى تتوفر مساحة. التطبيقات المنتهية تحرر مجلدات البناء الخاصة بها تلقائياً.';

  @override
  String get fxSimulatedTitle => 'وضع التجربة: التطبيقات وهمية';

  @override
  String get fxSimulatedHint =>
      'لا يُبنى أو يُرفع أو يُدفع شيء فعلياً. هذا فقط لتجربة هذه الشاشة.';

  @override
  String fxProgress(int percent) {
    return 'اكتمل $percent%';
  }

  @override
  String fxProgressEta(int percent, String eta) {
    return 'اكتمل $percent% · المتبقي نحو $eta';
  }

  @override
  String fxMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقيقة',
      few: '$count دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
    );
    return '$_temp0';
  }

  @override
  String fxHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعة',
      few: '$count ساعات',
      two: 'ساعتين',
      one: 'ساعة',
    );
    return '$_temp0';
  }

  @override
  String fxDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوماً',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String fxDailyLine(int playUsed, int playCap, int storeUsed, int storeCap) {
    return 'عمليات الرفع اليوم: Google Play $playUsed من $playCap، App Store $storeUsed من $storeCap. يتابع الباقي غداً.';
  }

  @override
  String get fxRetryFailed => 'أعد محاولة كل ما فشل';

  @override
  String fxCancelBatch(String name) {
    return 'إلغاء الدفعة «$name»';
  }

  @override
  String fxSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديد $count تطبيقاً',
      few: 'تم تحديد $count تطبيقات',
      two: 'تم تحديد تطبيقين',
      one: 'تم تحديد تطبيق',
    );
    return '$_temp0';
  }

  @override
  String fxRemoveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إزالة $count تطبيقاً من المصنع؟',
      few: 'إزالة $count تطبيقات من المصنع؟',
      two: 'إزالة هذين التطبيقين من المصنع؟',
      one: 'إزالة هذا التطبيق من المصنع؟',
    );
    return '$_temp0';
  }

  @override
  String get fxRemoveBody =>
      'تختفي من هذه القائمة. تبقى ملفات التطبيقات على حاسوبك.';

  @override
  String get fxAppGone => 'لم يعد هذا التطبيق في المصنع.';

  @override
  String get fxSteps => 'الخطوات';

  @override
  String get fxLog => 'ما الذي حدث';

  @override
  String fxCost(String amount) {
    return 'التكلفة حتى الآن: $amount دولار';
  }

  @override
  String fxRetryFrom(String stage) {
    return 'أعد المحاولة من «$stage»';
  }

  @override
  String get fxStepIdeas => 'الأفكار';

  @override
  String get fxStepRecipe => 'الطريقة';

  @override
  String get fxStepReview => 'المراجعة';

  @override
  String get fxBack => 'رجوع';

  @override
  String get fxContinue => 'متابعة';

  @override
  String get fxBoxTitle => 'أخبر المصنع بكل شيء';

  @override
  String get fxBoxHint =>
      'الصق أفكاراً أو قوائم أو خططاً أو تعليمات أو مستندات كاملة، أو أضف ملفات. يقرأ مشرف كل شيء ويستخرج منه حتى 100 تطبيق مختلف ويعرضها عليك قبل أن يبدأ أي شيء.';

  @override
  String get fxModeMine => 'لدي أفكار';

  @override
  String get fxModeInvent => 'اخترعها لي';

  @override
  String get fxBoxPlaceholder =>
      'الصق هنا: فكرة في كل سطر، أو خطة، أو وصفاً طويلاً، أو أي شيء…';

  @override
  String get fxAttach => 'إضافة ملفات';

  @override
  String get fxFilesLabel => 'ملفات نصية';

  @override
  String get fxFileTooBig =>
      'ملف كبير جداً (أكثر من 400 كيلوبايت) ولم تتم إضافته.';

  @override
  String get fxThemeLabel => 'الموضوع';

  @override
  String get fxThemeHint =>
      'مثلاً: أدوات بسيطة للياقة البدنية، ألعاب للأطفال، مشاريع صغيرة…';

  @override
  String get fxHowMany => 'عدد التطبيقات';

  @override
  String get fxBoxFootnote =>
      'لم يُبنَ شيء بعد. سترى التطبيقات أولاً وتختار ما تريد بدءه.';

  @override
  String get fxRecipeTitle => 'كيف تُصنع؟';

  @override
  String get fxEnginesTitle => 'من يكتب التطبيقات';

  @override
  String get fxEnginesHint =>
      'تُوزَّع التطبيقات بهذه النسبة. تذهب التطبيقات الكبيرة أولاً إلى المحرك الأقوى.';

  @override
  String get fxNotConnected => 'غير متصل بعد';

  @override
  String fxSharePercent(int percent) {
    return '$percent% من التطبيقات';
  }

  @override
  String get fxLogoTitle => 'من يرسم الشعارات';

  @override
  String get fxLogoAuto => 'تلقائي';

  @override
  String get fxGoalTitle => 'إلى أي مدى';

  @override
  String get fxGoalApp => 'التطبيق فقط';

  @override
  String get fxGoalAssets => 'التطبيق والشعار ولقطات الشاشة ونصوص المتجر';

  @override
  String get fxGoalAndroid => 'مع ملف أندرويد و Google Play (مسودة، اختبار)';

  @override
  String get fxGoalIos => 'مع تطبيق آيفون و App Store (TestFlight)';

  @override
  String get fxDailyTitle => 'موزَّع على الأيام';

  @override
  String get fxDailyHint =>
      'يمكن بناء كل التطبيقات اليوم، لكن المتاجر تمتلئ ببطء: يبقى الباقي جاهزاً حتى الغد.';

  @override
  String get fxDailyLabel => 'عمليات الرفع لكل متجر يومياً';

  @override
  String get fxSafeTitle => 'دائماً مسودة ودائماً في الاختبار';

  @override
  String get fxSafeBody =>
      'تستلم Google Play التطبيق كمسودة في الاختبار الداخلي و App Store عبر TestFlight. لا ينشر Ember أي تطبيق ولا يرسله للمراجعة أبداً: يبقى هذا قرارك أنت، تطبيقاً تلو الآخر.';

  @override
  String get fxSupervisorReading => 'المشرف يقرأ ويختار التطبيقات…';

  @override
  String get fxNoIdeas =>
      'لم يجد المشرف أي تطبيق ليصنعه. أضف مزيداً من التفاصيل وحاول مجدداً.';

  @override
  String fxReviewTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تطبيقاً مقترحاً',
      few: '$count تطبيقات مقترحة',
      two: 'تطبيقان مقترحان',
      one: 'تطبيق واحد مقترح',
    );
    return '$_temp0';
  }

  @override
  String get fxReviewHint =>
      'ألغِ تحديد ما لا تريده. اضغط على اسم لتغييره. اضغط على الحجم للتبديل بين صغير وكبير.';

  @override
  String get fxBatchName => 'اسم الدفعة';

  @override
  String fxBatchDefaultName(String date) {
    return 'دفعة $date';
  }

  @override
  String fxDroppedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فكرة مستبعدة',
      few: '$count أفكار مستبعدة',
      two: 'فكرتان مستبعدتان',
      one: 'فكرة واحدة مستبعدة',
    );
    return '$_temp0';
  }

  @override
  String fxDropDuplicate(String name) {
    return '$name: الاسم نفسه لتطبيق آخر';
  }

  @override
  String fxDropSimilar(String name, String kept) {
    return '$name: يشبه «$kept» كثيراً وقد أُبقي عليه';
  }

  @override
  String fxDropTooMany(String name) {
    return '$name: تتسع الدفعة لـ 100 تطبيق كحد أقصى';
  }

  @override
  String get fxWarnNoAi =>
      'لا يوجد محرك ذكاء اصطناعي متصل، لذلك قُرئت القائمة سطراً سطراً: تطبيق في كل سطر.';

  @override
  String get fxSizeSmall => 'صغير';

  @override
  String get fxSizeBig => 'كبير';

  @override
  String get fxSizeTooltip => 'التبديل بين صغير وكبير';

  @override
  String fxEstimateStores(int limit, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوماً',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم',
    );
    return 'تُبنى الآن وتذهب إلى المتاجر $limit يومياً: نحو $_temp0 لملئها.';
  }

  @override
  String fxStartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بدء $count تطبيقاً؟',
      few: 'بدء $count تطبيقات؟',
      two: 'بدء تطبيقين؟',
      one: 'بدء تطبيق واحد؟',
    );
    return '$_temp0';
  }

  @override
  String get fxStartBody => 'تُصنع التطبيقات الآن. لا يُنشر شيء.';

  @override
  String fxStartBodyStores(int limit) {
    return 'تُصنع التطبيقات الآن وتُرسل إلى Google Play و App Store كمسودات اختبار، $limit يومياً. لا يُنشر شيء ولا يُرسل شيء للمراجعة.';
  }

  @override
  String get fxStart => 'ابدأ';

  @override
  String fxStartCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ابدأ $count تطبيقاً',
      few: 'ابدأ $count تطبيقات',
      two: 'ابدأ تطبيقين',
      one: 'ابدأ تطبيقاً واحداً',
    );
    return '$_temp0';
  }

  @override
  String fxStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بدأ $count تطبيقاً',
      few: 'بدأت $count تطبيقات',
      two: 'بدأ تطبيقان',
      one: 'بدأ تطبيق واحد',
    );
    return '$_temp0';
  }

  @override
  String get fxLinksTitle => 'الاتصالات والقدرة';

  @override
  String get fxLinksEngines => 'محركات الذكاء الاصطناعي';

  @override
  String get fxLinksTools => 'الأدوات والحسابات';

  @override
  String get fxConnect => 'اتصال';

  @override
  String get fxSignInOpened =>
      'فُتحت نافذة تسجيل دخول على الحاسوب الذي يعمل عليه Ember.';

  @override
  String get fxLinkAndroid => 'أدوات أندرويد';

  @override
  String get fxLinkChrome => 'Chrome (للقطات الشاشة)';

  @override
  String get fxLinkPlayKey => 'مفتاح Google Play';

  @override
  String get fxLinkAppleKey => 'مفتاح App Store Connect';

  @override
  String get fxLinkMac => 'جهاز Mac لتطبيق آيفون';

  @override
  String get fxWhyNotInstalled => 'غير مثبّت';

  @override
  String get fxWhyNotSignedIn => 'لم يتم تسجيل الدخول';

  @override
  String get fxWhyMissing => 'غير موجود';

  @override
  String get fxWhyOnlyMac => 'على جهاز Mac فقط';

  @override
  String get fxCapacityTitle => 'هذا الحاسوب';

  @override
  String fxCapacityBody(int cpus, String ram, int disk) {
    return '$cpus أنوية، $ram غيغابايت من الذاكرة الحرة، $disk غيغابايت حرة على القرص.';
  }

  @override
  String fxCapacitySlots(int agents, int builds) {
    return 'في الوقت نفسه: حتى $agents وكلاء ذكاء اصطناعي و$builds عمليات بناء.';
  }

  @override
  String get fxLimitsTitle => 'الحدود';

  @override
  String get fxLimitInFlight => 'التطبيقات قيد الصنع في الوقت نفسه';

  @override
  String get fxNeedAndroidSdkTitle => 'ثبّت أدوات أندرويد';

  @override
  String get fxNeedAndroidSdkDetail =>
      '1. ثبّت Android Studio (يأتي معه أدوات أندرويد).\n2. افتحه مرة واحدة ووافق على التراخيص.\n3. ارجع إلى هنا واضغط «تم، تابع».';

  @override
  String get fxcTitle => 'حسابات المتاجر';

  @override
  String get fxcIntro =>
      'اربط Google Play وApp Store مرة واحدة فقط. يُبقيهما Ember مرتبطين ويرفع كل تطبيق بنفسه.';

  @override
  String get fxcGoogleName => 'Google Play';

  @override
  String get fxcAppleName => 'App Store';

  @override
  String get fxcStateConnected => 'مرتبط';

  @override
  String get fxcStateMissing => 'غير مرتبط';

  @override
  String get fxcStateInvalid => 'يلزم الربط من جديد';

  @override
  String get fxcStateUnreachable => 'المتجر لا يستجيب';

  @override
  String get fxcConnect => 'ربط';

  @override
  String get fxcReconnect => 'ربط من جديد';

  @override
  String get fxcChange => 'تغيير';

  @override
  String get fxcVerify => 'تحقق الآن';

  @override
  String get fxcDisconnect => 'فصل';

  @override
  String fxcDisconnectTitle(String name) {
    return 'فصل $name؟';
  }

  @override
  String get fxcDisconnectBody =>
      'التطبيقات المرفوعة تبقى كما هي. تنتظر عمليات الرفع الجديدة حتى تربط من جديد.';

  @override
  String fxcAccountGoogle(String email) {
    return 'الحساب: $email';
  }

  @override
  String fxcAccountApple(String keyId) {
    return 'المفتاح $keyId';
  }

  @override
  String fxcAccountTeam(String team) {
    return 'الفريق $team';
  }

  @override
  String get fxcChecking => 'جارٍ التحقق مع المتجر…';

  @override
  String get fxcWhyBadKey => 'هذا ليس ملف مفتاح صالحًا.';

  @override
  String get fxcWhyRefused =>
      'رفض المتجر هذا المفتاح. ربما حُذف أو استُبدل: أنشئ مفتاحًا جديدًا.';

  @override
  String get fxcWhyNoRole =>
      'المفتاح بلا صلاحيات. امنحه في App Store Connect دور App Manager.';

  @override
  String get fxcWhyOffline =>
      'تعذّر الوصول إلى المتجر. تحقق من اتصال الإنترنت.';

  @override
  String get fxcWhyDeveloperId =>
      'معرّف المطوّر هو الرقم الطويل في عنوان Play Console.';

  @override
  String get fxcBannerTitle => 'اربط Google Play وApp Store';

  @override
  String get fxcBannerBody => 'ما لم يكونا مرتبطين، تتوقف التطبيقات قبل الرفع.';

  @override
  String get fxcConnectNow => 'اربط الآن';

  @override
  String get fxcGoogleTitle => 'ربط Google Play';

  @override
  String get fxcGoogleStep1 =>
      'في Google Cloud أنشئ حساب خدمة وفعّل «Google Play Android Developer API».';

  @override
  String get fxcGoogleStep2 =>
      'افتح ذلك الحساب ثم المفاتيح ← إضافة مفتاح ← JSON. يُحفظ ملف على حاسوبك.';

  @override
  String get fxcGoogleStep3 =>
      'في Play Console افتح المستخدمون والأذونات وادعُ بريد الحساب مع إذن نشر التطبيقات.';

  @override
  String get fxcGoogleStep4 =>
      'اختر ملف .json أدناه. يتحقق منه Ember مع Google ويحفظه.';

  @override
  String get fxcOpenGoogleCloud => 'فتح Google Cloud';

  @override
  String get fxcOpenPlayConsole => 'فتح Play Console';

  @override
  String get fxcChooseJson => 'اختيار ملف .json';

  @override
  String get fxcPasteKey => 'أو الصق المفتاح هنا';

  @override
  String get fxcDeveloperId => 'معرّف المطوّر (اختياري)';

  @override
  String get fxcDeveloperIdHelp =>
      'الرقم الطويل في عنوان Play Console بعد /developers/.';

  @override
  String get fxcCheckSave => 'تحقق واحفظ';

  @override
  String get fxcAuto => 'ربط تلقائي';

  @override
  String get fxcAutoHelp =>
      'يستخدم حساب Google المسجّل في أدوات Google Cloud على هذا الحاسوب. يحتاج إلى معرّف المطوّر.';

  @override
  String get fxcAutoWorking => 'جارٍ تجهيز Google Play… قد يستغرق بضع دقائق';

  @override
  String fxcConnectedOk(String name) {
    return 'تم ربط $name';
  }

  @override
  String fxcFileChosen(String name) {
    return 'الملف: $name';
  }

  @override
  String get fxcAppleTitle => 'ربط App Store';

  @override
  String get fxcAppleStep1 =>
      'في App Store Connect افتح المستخدمون والوصول ← التكاملات ← واجهة App Store Connect وأنشئ مفتاحًا بدور App Manager.';

  @override
  String get fxcAppleStep2 => 'انسخ Issuer ID (أعلى الصفحة) وKey ID.';

  @override
  String get fxcAppleStep3 => 'نزّل ملف .p8: تسمح Apple بتنزيله مرة واحدة فقط.';

  @override
  String get fxcOpenAppStoreConnect => 'فتح App Store Connect';

  @override
  String get fxcIssuerId => 'Issuer ID';

  @override
  String get fxcIssuerHelp => 'الرمز الطويل في أعلى صفحة المفاتيح.';

  @override
  String get fxcKeyId => 'Key ID';

  @override
  String get fxcKeyIdHelp => 'الرمز القصير بجانب المفتاح، مثل Z47GM3ZDZ6.';

  @override
  String get fxcChooseP8 => 'اختيار ملف .p8';

  @override
  String get fxcKeepSavedKey =>
      'اترك الملف فارغًا للإبقاء على المفتاح المحفوظ.';

  @override
  String get fxcTeamId => 'Team ID (اختياري)';

  @override
  String get fxcTeamIdHelp => 'عشرة أحرف. يجده Ember بنفسه عندما يستطيع.';
}
