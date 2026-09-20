import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
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
Reply with ONE JSON object only (no markdown fences), with these keys. Write the store texts (title, descriptions, release notes) in ENGLISH: it is the listing's main language and the one Google shows wherever there is no local page. The guides and the privacy policy stay in the owner's language.
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
  bool _generating = false;
  bool _publishing = false;
  String? _error;
  Map<String, dynamic>? _result;

  static const _saKey = 'play_service_account';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _console = await PlayConsoleLink.load();
    _consoleLink.text = _console.developerId == null ? '' : _console.appList();
    if (mounted) setState(() {});
    final saved = await ref.read(keyValueStoreProvider).read(_saKey);
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
          _loadTranslations('${listing['translations'] ?? ''}');
        });
      }
    } catch (_) {}
    try {
      final info = await (await ref.read(runnerApiProvider.future)).androidInfo(widget.projectId);
      if (mounted) setState(() => _packageName = info['applicationId'] as String?);
    } catch (_) {}
    // An app with nothing written yet gets its listing written now: the user came
    // here to publish, not to face five empty boxes.
    if (mounted && _title.text.trim().isEmpty && !_generating) await _generate();
  }

  @override
  void dispose() {
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

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final complete = await _completer();
      final res = await complete(storeKitSystemPrompt, 'Package name: $_packageName\n\nApp description and features:\n${widget.appDescription}');
      final text = res.text.trim();
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start < 0 || end <= start) throw const FormatException('Risposta AI non valida');
      final j = jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
      _title.text = '${j['title'] ?? ''}';
      _short.text = '${j['shortDescription'] ?? ''}';
      _full.text = '${j['fullDescription'] ?? ''}';
      _notes.text = '${j['releaseNotes'] ?? ''}';
      _privacy = '${j['privacyPolicyMarkdown'] ?? ''}';
      _dataSafety = '${j['dataSafetyGuide'] ?? ''}';
      _contentRating = '${j['contentRatingGuide'] ?? ''}';
      _otherDeclarations = '${j['otherDeclarationsGuide'] ?? ''}';
      final api = await ref.read(runnerApiProvider.future);
      final saved = await api.savePrivacyPolicy(widget.projectId, _privacy, _title.text, email: _email.text.trim());
      final session = ref.read(sessionProvider).value!;
      // The published page is what Google can open; the local one only works on this computer.
      _privacyUrl = saved.publicUrl ?? '${session.runnerUrl}${saved.path}';
      final current = _privacyLink.text.trim();
      if (current.isEmpty || current.contains('localhost') || current.contains('127.0.0.1')) _privacyLink.text = _privacyUrl!;
      // A new listing means new translations: the old ones describe other words.
      _translations = {};
      await _saveListing();
    } catch (e) {
      _error = e is RunnerException ? e.message : e.toString();
    }
    if (mounted) setState(() => _generating = false);
    await _translate();
  }

  /// The listing's own language: English, the one Google falls back to for a
  /// country with no page of its own, so it reaches everyone.
  static const mainLanguage = 'en-US';

  /// The other store languages offered, as Google Play names them. All on by
  /// default: a page in the reader's language costs nothing and sells more.
  static const storeLanguages = <String, String>{
    'it-IT': 'Italiano',
    'fr-FR': 'Français',
    'es-ES': 'Español',
    'ar': 'العربية',
    'de-DE': 'Deutsch',
    'pt-BR': 'Português',
    'tr-TR': 'Türkçe',
    'hi-IN': 'हिन्दी',
    'ru-RU': 'Русский',
  };
  final Set<String> _languages = {...storeLanguages.keys};

  /// The listing in each language, as {language: {title, shortDescription, fullDescription}}.
  Map<String, Map<String, String>> _translations = {};
  bool _translating = false;

  void _loadTranslations(String saved) {
    if (saved.isEmpty) return;
    try {
      final j = jsonDecode(saved) as Map<String, dynamic>;
      final langs = (j['languages'] as List?)?.cast<String>();
      if (langs != null) {
        _languages
          ..clear()
          ..addAll(langs);
      }
      _translations = {
        for (final e in ((j['pages'] as Map?) ?? const {}).entries) '${e.key}': (e.value as Map).map((k, v) => MapEntry('$k', '$v')),
      };
    } catch (_) {
      // An unreadable old value just means translating again.
    }
  }

  /// Writes the listing in the chosen languages, from the English one on screen.
  ///
  /// One call for all of them: the same model keeps the same tone and the same
  /// app name in every language, which separate calls tend not to.
  Future<void> _translate() async {
    final wanted = _languages.where((l) => !_translations.containsKey(l)).toList();
    if (wanted.isEmpty || _title.text.trim().isEmpty) return;
    setState(() => _translating = true);
    try {
      final complete = await _completer();
      final prompt = [
        'Translate this Google Play store listing into these languages: ${wanted.join(', ')}.',
        'Keep the app name "${_title.text.trim().split(':').first.trim()}" unchanged in every language.',
        'Limits: title 30 characters, shortDescription 80, fullDescription 4000. Write naturally for each market, not word for word.',
        'Reply with JSON only: {"<language code>": {"title": "...", "shortDescription": "...", "fullDescription": "..."}}',
        '',
        'title: ${_title.text.trim()}',
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
        final v = (entry.value as Map).cast<String, dynamic>();
        _translations[entry.key] = {
          'title': '${v['title'] ?? ''}',
          'shortDescription': '${v['shortDescription'] ?? ''}',
          'fullDescription': '${v['fullDescription'] ?? ''}',
        };
      }
      await _saveListing();
    } catch (e) {
      _error = e is RunnerException ? e.message : e.toString();
    }
    if (mounted) setState(() => _translating = false);
  }

  Future<void> _saveListing() async {
    try {
      await (await ref.read(runnerApiProvider.future)).saveListing(widget.projectId, {
        'title': _title.text.trim(),
        'shortDescription': _short.text.trim(),
        'fullDescription': _full.text.trim(),
        'releaseNotes': _notes.text.trim(),
        'contactEmail': _email.text.trim(),
        'privacyUrl': _privacyLink.text.trim(),
        'dataSafety': _dataSafety,
        'contentRating': _contentRating,
        'otherDeclarations': _otherDeclarations,
        'translations': jsonEncode({'languages': _languages.toList(), 'pages': _translations}),
      });
    } catch (_) {}
  }

  Future<void> _publish() async {
    setState(() {
      _publishing = true;
      _error = null;
    });
    // Languages switched on after the listing was written still need their page.
    await _translate();
    await _saveListing();
    try {
      await ref.read(keyValueStoreProvider).write(_saKey, _sa.text.trim());
      final api = await ref.read(runnerApiProvider.future);
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
      });
      _step = 4;
    } on RunnerException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _publishing = false);
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
                          avatar: _translations.containsKey(e.key) ? const Icon(Icons.check, size: 16) : null,
                          onSelected: _translating
                              ? null
                              : (on) {
                                  setState(() => on ? _languages.add(e.key) : _languages.remove(e.key));
                                  if (on) _translate();
                                },
                        ),
                    ],
                  ),
                  if (_translating) ...[
                    const SizedBox(height: 6),
                    Row(children: [const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Text(l.playTranslating)]),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _title,
                    maxLength: 30,
                    decoration: InputDecoration(labelText: l.playTitle, border: const OutlineInputBorder()),
                  ),
                  TextField(
                    controller: _short,
                    maxLength: 80,
                    decoration: InputDecoration(labelText: l.playShortDescription, border: const OutlineInputBorder()),
                  ),
                  TextField(
                    controller: _full,
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
                          '${l.playUploaded('${_result!['versionCode']}', '${_result!['track']}', _result!['downgradedToDraft'] == true ? l.playDraftNote : '')}\n${uploadSummary(l, _result!)}',
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
