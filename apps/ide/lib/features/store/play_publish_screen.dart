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

const storeKitSystemPrompt = '''
You prepare everything needed to publish an Android app on Google Play, for a non-technical owner.
Reply with ONE JSON object only (no markdown fences), in the app's language, with these keys:
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
        });
      }
    } catch (_) {}
    try {
      final info = await (await ref.read(runnerApiProvider.future)).androidInfo(widget.projectId);
      if (mounted) setState(() => _packageName = info['applicationId'] as String?);
    } catch (_) {}
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
      final path = await api.savePrivacyPolicy(widget.projectId, _privacy, _title.text);
      final session = ref.read(sessionProvider).value!;
      // Only as a suggestion: the Runner address is not reachable by Google, the user pastes a public link.
      _privacyUrl = '${session.runnerUrl}$path';
      if (_privacyLink.text.trim().isEmpty) _privacyLink.text = _privacyUrl!;
      await _saveListing();
    } catch (e) {
      _error = e is RunnerException ? e.message : e.toString();
    }
    if (mounted) setState(() => _generating = false);
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
      });
    } catch (_) {}
  }

  Future<void> _publish() async {
    setState(() {
      _publishing = true;
      _error = null;
    });
    await _saveListing();
    try {
      await ref.read(keyValueStoreProvider).write(_saKey, _sa.text.trim());
      final api = await ref.read(runnerApiProvider.future);
      _result = await api.publishToPlay(widget.projectId, {
        'serviceAccount': _sa.text.trim(),
        'track': _track,
        'status': 'completed',
        'listing': {
          'language': 'it-IT',
          if (_title.text.trim().isNotEmpty) 'title': _title.text.trim(),
          if (_short.text.trim().isNotEmpty) 'shortDescription': _short.text.trim(),
          if (_full.text.trim().isNotEmpty) 'fullDescription': _full.text.trim(),
        },
        if (_notes.text.trim().isNotEmpty) 'releaseNotes': {'language': 'it-IT', 'text': _notes.text.trim()},
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
    final link = PlayConsoleLink.parse(url);
    if (link == null) return;
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
                      suffixIcon: IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () => Clipboard.setData(ClipboardData(text: _privacyLink.text))),
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
