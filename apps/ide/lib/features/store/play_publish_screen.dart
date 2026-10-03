import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/runner_api.dart';
import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../l10n/app_localizations.dart';
import 'default_policy.dart';
import 'play_links.dart';
import '../ai/ai_settings.dart';
import '../mockups/mockup_controller.dart' show CompleteText, apiCompleter, claudeCodeCompleter;

const _playConsoleSignup = 'https://play.google.com/console/signup';

const _cloudServiceAccounts = 'https://console.cloud.google.com/iam-admin/serviceaccounts';
const _enablePublisherApi = 'https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com';

/// Google's limits are hard: a translated title of 31 characters stops the
/// whole upload. Better a title one word shorter than a publish that fails.
Map<String, String> fitToStore(Map<String, String> page) {
  String cut(String? text, int max) {
    final String t = (text ?? '').trim();
    if (t.length <= max) return t;
    final String short = t.substring(0, max);
    final int space = short.lastIndexOf(' ');
    return (space > max - 12 ? short.substring(0, space) : short).trim();
  }

  return <String, String>{
    'title': cut(page['title'], 30),
    'shortDescription': cut(page['shortDescription'], 80),
    'fullDescription': cut(page['fullDescription'], 4000),
  };
}

const storeKitSystemPrompt = '''
You prepare everything needed to publish an Android app on Google Play, for a non-technical owner.
Reply with ONE JSON object only (no markdown fences), with these keys.

THE STORE TEXTS ARE WRITTEN IN ENGLISH. The title, the short description, the
full description and the release notes are English and nothing else: English is
the listing's main language and what Google shows wherever there is no page in
the reader's own. Do not write them in the owner's language, however the app
itself is written and whatever language this instruction is answered in — a
listing that arrives in the wrong language has to be rewritten by hand before
it can be published.
Only the guides and the privacy policy follow the owner's language.
{
 "title": "max 30 chars",
 "shortDescription": "max 80 chars",
 "fullDescription": "max 4000 chars, engaging, with feature bullets using • and line breaks",
 "releaseNotes": "max 500 chars",
 "privacyPolicyMarkdown": "complete privacy policy in Markdown (who we are placeholder [NOME TITOLARE] and [EMAIL], data collected, purposes, third-party services actually used by the app e.g. Firebase/Google Sign-In/Agora, retention, user rights under GDPR, contacts, date)",
 "dataSafetyGuide": "Markdown checklist answering Play Console 'Data safety' questions based on what the app really uses: data types collected/shared, purposes, encryption in transit, account deletion method",
 "contentRatingGuide": "Markdown list of suggested answers for the IARC content rating questionnaire",
 "otherDeclarationsGuide": "Markdown: target audience and content, ads (yes/no), app access instructions for reviewers if login is required (test account placeholder), government/financial/health declarations if relevant"
}
Be accurate: only declare data the app actually handles based on the description and files. Never invent certifications.''';

/// Guided "Publish to Google Play" flow after a signed AAB is ready.
/// What Google Play actually received, in plain words.
String uploadSummary(AppLocalizations l, Map<String, dynamic> result) {
  final u = (result['uploaded'] as Map?) ?? const {};
  final shots = (u['screenshots'] as num?)?.toInt() ?? 0;
  return [
    u['listing'] == true ? l.upListing((u['languages'] as List? ?? const []).join(', ')) : l.upNoListing,
    u['icon'] == true ? l.upIcon : l.upNoIcon,
    u['featureGraphic'] == true ? l.upFeature : l.upNoFeature,
    shots > 0 ? l.upShots(shots) : l.upNoShots,
  ].join('\n');
}

class PlayPublishScreen extends ConsumerStatefulWidget {
  const PlayPublishScreen({super.key, required this.projectId, required this.appDescription, this.initialStep = 0});

  /// Opened from the Ember publishing chat at the listing step, when everything before is done.
  final int initialStep;
  final String projectId;
  final String appDescription;

  @override
  ConsumerState<PlayPublishScreen> createState() => _PlayPublishScreenState();
}

class _PlayPublishScreenState extends ConsumerState<PlayPublishScreen> {
  PlayConsoleLink _console = const PlayConsoleLink();
  late int _step = widget.initialStep;
  late bool _hasAccount = widget.initialStep > 0;
  late bool _appCreated = widget.initialStep > 1;
  String? _packageName;

  /// What the app calls itself, read from the project rather than guessed
  /// from the folder or the package.
  String? _appLabel;
  final _sa = TextEditingController();
  final _title = TextEditingController();
  final _short = TextEditingController();
  final _full = TextEditingController();
  final _notes = TextEditingController();
  final _email = TextEditingController();
  final _privacyLink = TextEditingController();
  final _consoleLink = TextEditingController();
  String _privacy = '';
  String _dataSafety = '';
  String _contentRating = '';
  String _otherDeclarations = '';
  String? _privacyUrl;
  String _track = 'internal';
  // The long work (writing, translating, uploading) lives in a job that
  // outlives this screen: leaving does not stop it, coming back shows it.
  late final PublishJob _job = PublishJob.of(widget.projectId);
  bool get _generating => _job.generating;
  set _generating(bool v) => _job.generating = v;
  bool get _publishing => _job.publishing;
  set _publishing(bool v) => _job.publishing = v;
  String? get _error => _job.error;
  set _error(String? v) => _job.error = v;
  Map<String, dynamic>? get _result => _job.result;
  set _result(Map<String, dynamic>? v) => _job.result = v;

  /// Changes job state and shows it here (and on this screen if reopened).
  void _update([VoidCallback? change]) {
    change?.call();
    _job.changed();
  }

  void _onJob() {
    if (!mounted) return;
    setState(() {
      if (_result != null && _step < 4) _step = 4;
    });
  }

  static const _saKey = 'play_service_account';

  @override
  void initState() {
    super.initState();
    _job.addListener(_onJob);
    if (_result != null) _step = 4;
    _load();
  }

  Future<void> _load() async {
    _console = await PlayConsoleLink.load();
    _consoleLink.text = _console.developerId == null ? '' : _console.appList();
    if (mounted) setState(() {});
    final saved = await ref.read(settingsStoreProvider).read(_saKey);
    if (saved != null) _sa.text = saved;
    try {
      final listing = (await (await ref.read(runnerApiProvider.future)).storeState(widget.projectId))['listing'] as Map<String, dynamic>?;
      if (listing != null && mounted) {
        setState(() {
          _title.text = '${listing['title'] ?? ''}';
          _short.text = '${listing['shortDescription'] ?? ''}';
          _full.text = '${listing['fullDescription'] ?? ''}';
          _notes.text = '${listing['releaseNotes'] ?? ''}';
          _email.text = '${listing['contactEmail'] ?? ''}';
          _privacyUrl = (listing['privacyUrl'] as String?)?.isEmpty == true ? null : listing['privacyUrl'] as String?;
          _privacyLink.text = _privacyUrl ?? '';
          _dataSafety = '${listing['dataSafety'] ?? ''}';
          _contentRating = '${listing['contentRating'] ?? ''}';
          _otherDeclarations = '${listing['otherDeclarations'] ?? ''}';
          // Reopened while Ember works on it: the job holds the newer state.
          if (!_job.loaded) _loadTranslations('${listing['translations'] ?? ''}');
          _job.loaded = true;
        });
      }
    } catch (_) {}
    try {
      final info = await (await ref.read(runnerApiProvider.future)).androidInfo(widget.projectId);
      if (mounted) {
        setState(() {
          _packageName = info['applicationId'] as String?;
          _appLabel = (info['appLabel'] as String?)?.trim();
        });
      }
    } catch (_) {}
    // An app with nothing written yet gets its listing written now: the user came
    // here to publish, not to face five empty boxes.
    if (mounted && _title.text.trim().isEmpty && !_generating) await _generate();
  }

  @override
  void dispose() {
    _job.removeListener(_onJob);
    for (final c in [_sa, _title, _short, _full, _notes, _email, _privacyLink, _consoleLink]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<CompleteText> _completer() async {
    final health = await ref.read(runnerHealthProvider.future);
    if ((health['engines'] as Map?)?['claudeCode'] == true) {
      final socket = ref.read(runnerSocketProvider);
      return claudeCodeCompleter((t, p) => socket.request(t, p, timeout: const Duration(minutes: 6)));
    }
    final settings = await ref.read(aiSettingsProvider.future);
    final catalog = await ref.read(aiCatalogProvider.future);
    final model = catalog.firstWhere(
      (m) => m.tags.contains('fast') && canUseProvider(settings, m.provider, health),
      orElse: () => catalog.firstWhere((m) => canUseProvider(settings, m.provider, health), orElse: () => throw const AiException('Nessuna AI configurata')),
    );
    return apiCompleter(ref.read(aiProviderFactory), model);
  }

  /// Whether this app was built with ads and with purchases, as recorded by
  /// the build itself rather than guessed from its description.
  Future<({bool ads, bool purchases})> _whatWasBuilt() async {
    try {
      final raw = await Settings.instance.read('ember_session_${widget.projectId}');
      if (raw == null) return (ads: false, purchases: false);
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final ads = m['ads'];
      final products = m['products'];
      return (
        ads: ads is Map && ads.values.any((v) => v == true),
        purchases: products is List && products.isNotEmpty,
      );
    } catch (_) {
      return (ads: false, purchases: false);
    }
  }

  Future<void> _generate() async {
    _update(() {
      _generating = true;
      _error = null;
    });
    try {
      final complete = _job.complete = await _completer();
      _job.api ??= await ref.read(runnerApiProvider.future);
      // The name is stated as a fact before anything else: left to infer it
      // from the package, the writer invented one from the folder name and an
      // app called PrintGo was published as StampaFacile.
      // A title the user typed is theirs: the writer keeps it word for word
      // and names the app as it does. Generating again used to put the
      // project's name back over it.
      final typedTitle = _title.text.trim();
      final named = typedTitle.isNotEmpty ? typedTitle.split(':').first.trim() : (_appLabel ?? '').trim();
      final naming = named.isEmpty
          ? ''
          : 'The app is called "$named". Use exactly this name in the title '
              'and wherever the listing names the app. Do not translate it, '
              'shorten it, or invent another one.\n'
              '${typedTitle.isNotEmpty ? 'The store title is exactly "$typedTitle": return it unchanged as "title".\n' : ''}\n';
      final res = await complete(storeKitSystemPrompt,
          '${naming}Package name: $_packageName\n\nApp description and features:\n${widget.appDescription}');
      final text = res.text.trim();
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start < 0 || end <= start) throw const FormatException('Risposta AI non valida');
      final j = jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
      _title.text = typedTitle.isNotEmpty ? typedTitle : '${j['title'] ?? ''}';
      _short.text = '${j['shortDescription'] ?? ''}';
      _full.text = '${j['fullDescription'] ?? ''}';
      _notes.text = '${j['releaseNotes'] ?? ''}';
      _privacy = '${j['privacyPolicyMarkdown'] ?? ''}';
      _dataSafety = '${j['dataSafetyGuide'] ?? ''}';
      _contentRating = '${j['contentRatingGuide'] ?? ''}';
      _otherDeclarations = '${j['otherDeclarationsGuide'] ?? ''}';
      final api = _job.api!;
      // Google will not take an app without a policy at a public address, so a
      // model that answered everything else and skipped this one must not cost
      // the upload: write a true one from what the app actually does.
      if (_privacy.trim().length < 50) {
        // What the app actually ships with, recorded by the build: a policy
        // must not claim ads or purchases the app does not have, nor stay
        // silent about the ones it does.
        final built = await _whatWasBuilt();
        _privacy = defaultPrivacyPolicy(
          appName: _title.text,
          email: _email.text.trim(),
          ads: built.ads,
          purchases: built.purchases,
        );
      }
      // Its own try: publishing the policy can fail on its own (GitHub not
      // signed in, network down) and that must not throw away the listing the
      // model just wrote, which was the whole point of the step.
      try {
        final saved = await api.savePrivacyPolicy(widget.projectId, _privacy, _title.text, email: _email.text.trim());
        final session = ref.read(sessionProvider).value!;
        // The published page is what Google can open; the local one only works on this computer.
        _privacyUrl = saved.publicUrl ?? '${session.runnerUrl}${saved.path}';
        final current = _privacyLink.text.trim();
        if (current.isEmpty || current.contains('localhost') || current.contains('127.0.0.1')) _privacyLink.text = _privacyUrl!;
        // A local address is not an address Google can open: say so here
        // rather than letting the upload fail at review.
        if (saved.publicUrl == null) {
          _error = "La privacy e salvata solo su questo computer: Google non puo aprirla. "
              "Collega GitHub in Ember, oppure incolla qui sotto un link tuo.";
        }
      } catch (e) {
        _error = "Privacy non pubblicata: ${e is RunnerException ? e.message : e}. "
            "Il resto della scheda e stato salvato; incolla un link tuo qui sotto.";
      }
      // A new listing means new translations: the old ones describe other words.
      _translations = {};
      await _saveListing();
    } catch (e) {
      _error = e is RunnerException ? e.message : e.toString();
    }
    _update(() => _generating = false);
    await _translate();
  }

  /// The listing's own language: English, the one Google falls back to for a
  /// country with no page of its own, so it reaches everyone.
  static const mainLanguage = 'en-US';

  /// Every store language Google Play has (82 besides the main English one),
  /// as Google Play names them: the ten languages every Ember app speaks
  /// first, then the rest. All on by default: a page in the reader's language
  /// costs nothing and sells more. The English variants copy the main text.
  static const storeLanguages = <String, String>{
    'it-IT': 'Italiano',
    'es-ES': 'Español',
    'pt-BR': 'Português (BR)',
    'fr-FR': 'Français',
    'de-DE': 'Deutsch',
    'hi-IN': 'हिन्दी',
    'ar': 'العربية',
    'id': 'Bahasa Indonesia',
    'ru-RU': 'Русский',
    'tr-TR': 'Türkçe',
    'vi': 'Tiếng Việt',
    'th': 'ไทย',
    'ja-JP': '日本語',
    'ko-KR': '한국어',
    'pl-PL': 'Polski',
    'nl-NL': 'Nederlands',
    'fil': 'Filipino',
    'ms': 'Bahasa Melayu',
    'bn-BD': 'বাংলা',
    'ta-IN': 'தமிழ்',
    'te-IN': 'తెలుగు',
    'mr-IN': 'मराठी',
    'uk': 'Українська',
    'es-419': 'Español (Latinoamérica)',
    'zh-TW': '繁體中文',
    'ur': 'اردو',
    'pa': 'ਪੰਜਾਬੀ',
    'zh-CN': '简体中文',
    'zh-HK': '繁體中文 (香港)',
    'pt-PT': 'Português (PT)',
    'es-US': 'Español (EE. UU.)',
    'fr-CA': 'Français (Canada)',
    'gu': 'ગુજરાતી',
    'kn-IN': 'ಕನ್ನಡ',
    'ml-IN': 'മലയാളം',
    'ne-NP': 'नेपाली',
    'si-LK': 'සිංහල',
    'fa': 'فارسی',
    'iw-IL': 'עברית',
    'el-GR': 'Ελληνικά',
    'ro': 'Română',
    'cs-CZ': 'Čeština',
    'sk': 'Slovenčina',
    'hu-HU': 'Magyar',
    'bg': 'Български',
    'sr': 'Српски',
    'hr': 'Hrvatski',
    'sl': 'Slovenščina',
    'mk-MK': 'Македонски',
    'sq': 'Shqip',
    'sv-SE': 'Svenska',
    'da-DK': 'Dansk',
    'no-NO': 'Norsk',
    'fi-FI': 'Suomi',
    'is-IS': 'Íslenska',
    'et': 'Eesti',
    'lv': 'Latviešu',
    'lt': 'Lietuvių',
    'be': 'Беларуская',
    'ka-GE': 'ქართული',
    'hy-AM': 'Հայերեն',
    'az-AZ': 'Azərbaycan',
    'kk': 'Қазақ',
    'ky-KG': 'Кыргызча',
    'mn-MN': 'Монгол',
    'my-MM': 'မြန်မာ',
    'km-KH': 'ខ្មែរ',
    'lo-LA': 'ລາວ',
    'sw': 'Kiswahili',
    'am': 'አማርኛ',
    'zu': 'isiZulu',
    'af': 'Afrikaans',
    'ca': 'Català',
    'eu-ES': 'Euskara',
    'gl-ES': 'Galego',
    'rm': 'Rumantsch',
    'en-GB': 'English (UK)',
    'en-AU': 'English (Australia)',
    'en-CA': 'English (Canada)',
    'en-IN': 'English (India)',
    'en-SG': 'English (Singapore)',
    'en-ZA': 'English (South Africa)',
  };
  Set<String> get _languages => _job.languages;

  /// The listing in each language, as {language: {title, shortDescription, fullDescription}}.
  Map<String, Map<String, String>> get _translations => _job.translations;
  set _translations(Map<String, Map<String, String>> v) => _job.translations = v;
  bool get _translating => _job.translating;
  set _translating(bool v) => _job.translating = v;

  /// The English text the translations were written from. When the title or
  /// a description changes, the translations still carry the old words (the
  /// old app name in 82 languages): they are written again.
  String? get _translatedFrom => _job.translatedFrom;
  set _translatedFrom(String? v) => _job.translatedFrom = v;
  String get _source => '${_title.text.trim()}\u0001${_short.text.trim()}\u0001${_full.text.trim()}';
  bool get _translationsStale => _translations.isNotEmpty && _translatedFrom != null && _translatedFrom != _source;

  void _loadTranslations(String saved) {
    if (saved.isEmpty) return;
    try {
      final j = jsonDecode(saved) as Map<String, dynamic>;
      final langs = (j['languages'] as List?)?.cast<String>();
      if (langs != null) {
        // A listing saved when Ember offered fewer languages gets the new
        // ones too (they are translated next time); a language the user
        // switched off among those offered back then stays off.
        const before = {'it-IT', 'fr-FR', 'es-ES', 'ar', 'de-DE', 'pt-BR', 'tr-TR', 'hi-IN', 'ru-RU'};
        _languages
          ..clear()
          ..addAll(langs)
          ..addAll(storeLanguages.keys.where((l) => !before.contains(l)));
      }
      _translations = {
        for (final e in ((j['pages'] as Map?) ?? const {}).entries) '${e.key}': (e.value as Map).map((k, v) => MapEntry('$k', '$v')),
      };
      // Saved before Ember remembered the source: take them as matching it.
      _translatedFrom = j['from'] as String? ?? _source;
      // The name is the same in every language (older listings translated it).
      final name = _title.text.trim();
      if (name.isNotEmpty) {
        for (final page in _translations.values) {
          page['title'] = name;
        }
      }
    } catch (_) {
      // An unreadable old value just means translating again.
    }
  }

  /// Writes the listing in the chosen languages, from the English one on screen.
  ///
  /// One call for all of them: the same model keeps the same tone and the same
  /// app name in every language, which separate calls tend not to.
  Future<void> _translate() async {
    // The English text changed since the translations were written: they are redone.
    if (_translationsStale) _translations = {};
    if (_title.text.trim().isNotEmpty) _translatedFrom = _source;
    // English pages for other countries say what the main page says.
    if (_title.text.trim().isNotEmpty) {
      for (final l in _languages.where((l) => l.startsWith('en-') && !_translations.containsKey(l)).toList()) {
        _translations[l] = {'title': _title.text.trim(), 'shortDescription': _short.text.trim(), 'fullDescription': _full.text.trim()};
      }
    }
    final wanted = _languages.where((l) => !_translations.containsKey(l)).toList();
    if (wanted.isEmpty || _title.text.trim().isEmpty) return;
    _update(() => _translating = true);
    try {
      final complete = _job.complete ?? (_job.complete = await _completer());
      // A few languages per call: 25 full listings in one answer are far past
      // what a model writes in one go, and one cut answer lost them all.
      const group = 4;
      final batches = [for (var i = 0; i < wanted.length; i += group) wanted.sublist(i, i + group > wanted.length ? wanted.length : i + group)];
      String? lastError;
      for (var i = 0; i < batches.length; i += 3) {
        final results = await Future.wait(
          batches.skip(i).take(3).map((langs) => _translateGroup(complete, langs).then<Object?>((_) => null, onError: (Object e) => e)),
        );
        for (final r in results) {
          if (r != null) lastError = r is RunnerException ? r.message : r.toString();
        }
        await _saveListing();
        _update(() {});
      }
      if (lastError != null && wanted.any((l) => !_translations.containsKey(l))) _error = lastError;
    } catch (e) {
      _error = e is RunnerException ? e.message : e.toString();
    }
    _update(() => _translating = false);
  }

  Future<void> _translateGroup(CompleteText complete, List<String> langs) async {
    final prompt = [
      'Translate this Google Play store listing into these languages: ${langs.join(', ')}.',
      'The title is the app name: it stays exactly "${_title.text.trim()}" in every language. Translate only the descriptions.',
      'Limits: shortDescription 80 characters, fullDescription 4000. Write naturally for each market, not word for word.',
      'Reply with JSON only: {"<language code>": {"shortDescription": "...", "fullDescription": "..."}}',
      '',
      'shortDescription: ${_short.text.trim()}',
      'fullDescription:',
      _full.text.trim(),
    ].join('\n');
    final res = await complete('You translate app store listings for Google Play. You answer with JSON only.', prompt);
    final text = res.text.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) throw const FormatException('Risposta AI non valida');
    final j = jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
    for (final entry in j.entries) {
      if (!langs.contains(entry.key)) continue;
      final v = (entry.value as Map).cast<String, dynamic>();
      // The name is the same on every store page: the one the user wrote.
      _translations[entry.key] = {
        'title': _title.text.trim(),
        'shortDescription': '${v['shortDescription'] ?? ''}',
        'fullDescription': '${v['fullDescription'] ?? ''}',
      };
    }
  }

  /// One store page in one language: the name (the same everywhere), the
  /// two descriptions as they will appear, editable, and whether this
  /// language goes on Google Play at all.
  Future<void> _openLanguage(String code, String name) async {
    final l = AppLocalizations.of(context);
    final page = _translations[code];
    final short = TextEditingController(text: page?['shortDescription'] ?? '');
    final full = TextEditingController(text: page?['fullDescription'] ?? '');
    var included = _languages.contains(code);
    final rtl = const {'ar', 'ur', 'fa', 'iw-IL'}.contains(code);
    final saved = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setD) => AlertDialog(
          title: Text('$name  ·  $code'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: included,
                    onChanged: (v) => setD(() => included = v),
                    title: Text(l.playLanguageIncluded),
                  ),
                  if (page == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l.playLanguageNotTranslated),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: InputDecoration(labelText: l.playTitle, border: const OutlineInputBorder()),
                      child: Text(page['title'] ?? _title.text.trim(), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: short,
                      maxLength: 80,
                      textDirection: rtl ? TextDirection.rtl : null,
                      decoration: InputDecoration(labelText: l.playShortDescription, border: const OutlineInputBorder()),
                    ),
                    TextField(
                      controller: full,
                      maxLength: 4000,
                      minLines: 6,
                      maxLines: 16,
                      textDirection: rtl ? TextDirection.rtl : null,
                      decoration: InputDecoration(labelText: l.playFullDescription, border: const OutlineInputBorder()),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(d).pop(false), child: Text(MaterialLocalizations.of(d).cancelButtonLabel)),
            FilledButton(onPressed: () => Navigator.of(d).pop(true), child: Text(MaterialLocalizations.of(d).saveButtonLabel)),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        included ? _languages.add(code) : _languages.remove(code);
        if (page != null) {
          _translations[code] = {
            'title': _title.text.trim(),
            'shortDescription': short.text.trim(),
            'fullDescription': full.text.trim(),
          };
        }
      });
      await _saveListing();
      // Switched on and not written yet: write it now.
      if (included && page == null && !_translating) await _translate();
    }
    short.dispose();
    full.dispose();
  }

  Future<void> _saveListing() async {
    try {
      var api = _job.api;
      if (api == null) {
        api = await ref.read(runnerApiProvider.future);
        _job.api = api;
      }
      await api!.saveListing(widget.projectId, {
        'title': _title.text.trim(),
        'shortDescription': _short.text.trim(),
        'fullDescription': _full.text.trim(),
        'releaseNotes': _notes.text.trim(),
        'contactEmail': _email.text.trim(),
        'privacyUrl': _privacyLink.text.trim(),
        'dataSafety': _dataSafety,
        'contentRating': _contentRating,
        'otherDeclarations': _otherDeclarations,
        'translations': jsonEncode({'languages': _languages.toList(), 'pages': _translations, 'from': _translatedFrom}),
      });
    } catch (_) {}
  }

  Future<void> _publish({bool listingOnly = false}) async {
    _update(() {
      _publishing = true;
      _error = null;
    });
    final store = ref.read(settingsStoreProvider);
    _job.api ??= await ref.read(runnerApiProvider.future);
    _job.complete ??= await _completer().then<CompleteText?>((c) => c, onError: (Object _) => null);
    // Languages switched on after the listing was written still need their page.
    await _translate();
    await _saveListing();
    try {
      await store.write(_saKey, _sa.text.trim());
      final api = _job.api!;
      _result = await api.publishToPlay(widget.projectId, {
        'serviceAccount': _sa.text.trim(),
        'track': _track,
        'status': 'completed',
        'listing': {
          'language': mainLanguage,
          if (_title.text.trim().isNotEmpty) 'title': _title.text.trim(),
          if (_short.text.trim().isNotEmpty) 'shortDescription': _short.text.trim(),
          if (_full.text.trim().isNotEmpty) 'fullDescription': _full.text.trim(),
        },
        'translations': [
          for (final lang in _languages)
            if (_translations[lang] != null) {'language': lang, ...fitToStore(_translations[lang]!)},
        ],
        if (_notes.text.trim().isNotEmpty) 'releaseNotes': {'language': mainLanguage, 'text': _notes.text.trim()},
        if (_email.text.trim().isNotEmpty) 'contactEmail': _email.text.trim(),
        // Only the store page of an app already on Google Play: no new version.
        if (listingOnly) 'listingOnly': true,
      });
      if (mounted) _step = 4;
    } on RunnerException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }
    _update(() => _publishing = false);
  }

  /// Saves the pasted Play Console address so every button opens the user's own account.
  Future<void> _saveConsoleLink(String url) async {
    final parsed = PlayConsoleLink.parse(url);
    if (parsed == null) return;
    final link = parsed.merge(await PlayConsoleLink.load());
    await link.save();
    if (mounted) setState(() => _console = link);
  }

  Widget _consoleLinkField(AppLocalizations l) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: TextField(
      controller: _consoleLink,
      keyboardType: TextInputType.url,
      onChanged: _saveConsoleLink,
      decoration: InputDecoration(
        labelText: l.consoleLinkLabel,
        hintText: 'https://play.google.com/console/u/0/developers/…',
        suffixIcon: IconButton(
          tooltip: l.paste,
          icon: const Icon(Icons.content_paste, size: 18),
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            final text = data?.text?.trim();
            if (text == null || text.isEmpty) return;
            _consoleLink.text = text;
            await _saveConsoleLink(text);
          },
        ),
        helperText: _console.developerId == null ? l.consoleLinkHint : l.consoleLinkSaved(_console.developerId!),
        helperMaxLines: 3,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  Widget _link(String label, String url) => TextButton.icon(
    onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    icon: const Icon(Icons.open_in_new, size: 16),
    label: Text(label),
  );

  Widget _copyRow(String label, String value) => Row(
    children: [
      Expanded(
        child: SelectableText('$label: $value', style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      IconButton(
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () => Clipboard.setData(ClipboardData(text: value)),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final saValid = _sa.text.contains('"service_account"') && _sa.text.contains('private_key');
    // Going back hands the upload result (or null) to the publishing chat.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_result);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.playPublishTitle),
          leading: BackButton(onPressed: () => Navigator.of(context).pop(_result)),
        ),
        body: Stepper(
          currentStep: _step,
          onStepTapped: (i) => setState(() => _step = i),
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: [
            Step(
              title: Text(l.playStepAccount),
              isActive: _step >= 0,
              state: _hasAccount ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: Padding(padding: const EdgeInsets.all(12), child: Text(l.playFeeNotice)),
                  ),
                  _link(l.playOpenSignup, _playConsoleSignup),
                  CheckboxListTile(value: _hasAccount, onChanged: (v) => setState(() => _hasAccount = v ?? false), title: Text(l.playHaveAccount), contentPadding: EdgeInsets.zero),
                  FilledButton(onPressed: _hasAccount ? () => setState(() => _step = 1) : null, child: Text(l.next)),
                ],
              ),
            ),
            Step(
              title: Text(l.playStepCreateApp),
              isActive: _step >= 1,
              state: _appCreated ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(data: l.playCreateAppGuide),
                  const SizedBox(height: 8),
                  if (_packageName != null) _copyRow(l.playPackageName, _packageName!),
                  _link(l.playOpenConsole, _console.appList(_packageName)),
                  _consoleLinkField(l),
                  CheckboxListTile(value: _appCreated, onChanged: (v) => setState(() => _appCreated = v ?? false), title: Text(l.playAppCreated), contentPadding: EdgeInsets.zero),
                  FilledButton(onPressed: _appCreated ? () => setState(() => _step = 2) : null, child: Text(l.next)),
                ],
              ),
            ),
            Step(
              title: Text(l.playStepConnect),
              isActive: _step >= 2,
              state: saValid ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(data: l.playConnectGuide),
                  Wrap(children: [_link(l.playOpenApiLibrary, _enablePublisherApi), _link(l.playOpenServiceAccounts, _cloudServiceAccounts), _link(l.playOpenConsole, _console.appList(_packageName))]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sa,
                    minLines: 3,
                    maxLines: 8,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: InputDecoration(labelText: l.playServiceAccountJson, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: saValid ? () => setState(() => _step = 3) : null, child: Text(l.next)),
                ],
              ),
            ),
            Step(
              title: Text(l.playStepListing),
              isActive: _step >= 3,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _generating ? null : _generate,
                    icon: _generating ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                    label: Text(l.playGenerateWithAi),
                  ),
                  const SizedBox(height: 12),
                  // The other store pages: English is the one below, these are written from it.
                  Text(l.playLanguages, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      const Chip(label: Text('English')),
                      for (final e in storeLanguages.entries)
                        FilterChip(
                          label: Text(e.value),
                          selected: _languages.contains(e.key),
                          avatar: _translations.containsKey(e.key) && !_translationsStale ? const Icon(Icons.check, size: 16) : null,
                          // A tap opens that language's page: read it, fix it, or leave the language out.
                          onSelected: (_) => _openLanguage(e.key, e.value),
                        ),
                    ],
                  ),
                  if (_translationsStale && !_translating) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: Text(l.playTranslationsStale, style: Theme.of(context).textTheme.bodySmall)),
                        TextButton.icon(onPressed: _translate, icon: const Icon(Icons.translate), label: Text(l.playTranslateAgain)),
                      ],
                    ),
                  ],
                  if (_translating) ...[
                    const SizedBox(height: 6),
                    Row(children: [const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Text(l.playTranslating)]),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _title,
                    onChanged: (_) => setState(() {}),
                    maxLength: 30,
                    decoration: InputDecoration(labelText: l.playTitle, border: const OutlineInputBorder()),
                  ),
                  TextField(
                    controller: _short,
                    onChanged: (_) => setState(() {}),
                    maxLength: 80,
                    decoration: InputDecoration(labelText: l.playShortDescription, border: const OutlineInputBorder()),
                  ),
                  TextField(
                    controller: _full,
                    onChanged: (_) => setState(() {}),
                    maxLength: 4000,
                    minLines: 4,
                    maxLines: 12,
                    decoration: InputDecoration(labelText: l.playFullDescription, border: const OutlineInputBorder()),
                  ),
                  TextField(
                    controller: _notes,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: l.playReleaseNotes, border: const OutlineInputBorder()),
                  ),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l.playContactEmail, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _privacyLink,
                    keyboardType: TextInputType.url,
                    onChanged: (v) => setState(() => _privacyUrl = v.trim().isEmpty ? null : v.trim()),
                    decoration: InputDecoration(
                      labelText: l.playPrivacyUrl,
                      hintText: 'https://…',
                      helperText: _privacyLink.text.contains('localhost') || _privacyLink.text.contains('127.0.0.1') ? l.privacyLocalWarning : l.privacyPublicHint,
                      helperMaxLines: 3,
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l.paste,
                            icon: const Icon(Icons.content_paste, size: 18),
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              final text = data?.text?.trim();
                              if (text == null || text.isEmpty) return;
                              setState(() {
                                _privacyLink.text = text;
                                _privacyUrl = text;
                              });
                            },
                          ),
                          IconButton(tooltip: l.copy, icon: const Icon(Icons.copy, size: 18), onPressed: () => Clipboard.setData(ClipboardData(text: _privacyLink.text))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _track,
                    decoration: InputDecoration(labelText: l.playTrack, border: const OutlineInputBorder()),
                    items: [
                      DropdownMenuItem(value: 'internal', child: Text(l.playTrackInternal)),
                      DropdownMenuItem(value: 'alpha', child: Text(l.playTrackClosed)),
                      DropdownMenuItem(value: 'production', child: Text(l.playTrackProduction)),
                    ],
                    onChanged: (v) => setState(() => _track = v ?? 'internal'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('publishToPlay'),
                    onPressed: _publishing || !saValid ? null : _publish,
                    icon: _publishing ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload),
                    label: Padding(padding: const EdgeInsets.all(10), child: Text(l.playUpload)),
                  ),
                  const SizedBox(height: 8),
                  // For apps already on Google Play: new languages, new texts or
                  // graphics go live without building and sending a new version.
                  OutlinedButton.icon(
                    key: const Key('updateListingOnly'),
                    onPressed: _publishing || !saValid ? null : () => _publish(listingOnly: true),
                    icon: const Icon(Icons.translate),
                    label: Padding(padding: const EdgeInsets.all(10), child: Text(l.playUpdateListingOnly)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l.playUpdateListingOnlyHint, style: Theme.of(context).textTheme.bodySmall),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                ],
              ),
            ),
            Step(
              title: Text(l.playStepFinish),
              isActive: _step >= 4,
              state: _result != null ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_result != null)
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${l.playUploaded('${_result!['versionCode']}', '${_result!['track']}', _result!['downgradedToDraft'] == true ? l.playDraftNote : '')}\n${uploadSummary(l, _result!)}${_result!['reviewNotSent'] == true ? '\n\n${l.playReviewNotSent}' : ''}',
                        ),
                      ),
                    ),
                  MarkdownBody(data: l.playManualChecklist(_privacyLink.text.trim().isEmpty ? '—' : _privacyLink.text.trim())),
                  if (_dataSafety.isNotEmpty)
                    ExpansionTile(
                      title: Text(l.playDataSafety),
                      children: [MarkdownBody(data: _dataSafety, selectable: true)],
                    ),
                  if (_contentRating.isNotEmpty)
                    ExpansionTile(
                      title: Text(l.playContentRating),
                      children: [MarkdownBody(data: _contentRating, selectable: true)],
                    ),
                  if (_otherDeclarations.isNotEmpty)
                    ExpansionTile(
                      title: Text(l.playOtherDeclarations),
                      children: [MarkdownBody(data: _otherDeclarations, selectable: true)],
                    ),
                  _link(l.playOpenConsole, _console.appList(_packageName)),
                  _consoleLinkField(l),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// The publishing work of one app, alive as long as Ember runs. Writing the
/// listing, translating it into every language and uploading it take minutes:
/// the user goes to another screen meanwhile, and the work must not stop
/// there. The screen shows the job and gives it its texts; reopened, it shows
/// where the job is.
class PublishJob extends ChangeNotifier {
  PublishJob._();

  static final Map<String, PublishJob> _all = {};
  static PublishJob of(String projectId) => _all.putIfAbsent(projectId, PublishJob._);

  final Set<String> languages = {..._PlayPublishScreenState.storeLanguages.keys};
  Map<String, Map<String, String>> translations = {};
  String? translatedFrom;
  bool generating = false;
  bool translating = false;
  bool publishing = false;
  String? error;
  Map<String, dynamic>? result;

  /// The saved listing was read into this job once; later opens keep the job's.
  bool loaded = false;

  /// Taken while the screen was open, used after it closed.
  RunnerApi? api;
  CompleteText? complete;

  bool get busy => generating || translating || publishing;

  void changed() => notifyListeners();
}
