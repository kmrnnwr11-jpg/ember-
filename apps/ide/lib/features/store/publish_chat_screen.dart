import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/ember_logo.dart';
import '../ai/chat_controller.dart';
import 'play_links.dart';
import 'play_publish_screen.dart' show uploadSummary;

/// Free questions while publishing, answered by Ember (Gemini on the Runner key).
final publishAssistantProvider = ChangeNotifierProvider.family<ChatController, String>((ref, projectId) {
  return ChatController(
    projectId: '_publish_$projectId',
    resolveProvider: (_) async {
      final session = ref.read(sessionProvider).value;
      if (session == null) throw const AiException('Sign in first');
      return GeminiProvider(AiEndpoint.proxy(apiKey: '', runnerUrl: session.runnerUrl, runnerToken: await session.token(), proxyPath: 'assistant'));
    },
    systemPrompt:
        'You are Ember, guiding a non-technical user step by step to publish their Android app on Google Play (Play Console account, creating the app, '
        'service account connection, store listing, screenshots, data safety, content rating, target audience, testing tracks, 12 testers for 14 days on new personal accounts, review). '
        'Answer in the user\'s language, very simply, with numbered steps and exact button names and direct links.',
    attachFiles: false,
  )..selectModel(const AiModel(provider: AiProviderId.gemini, id: 'gemini-2.5-flash', label: 'Gemini', inputPerMTok: 0, outputPerMTok: 0));
});

enum _Step { account, accountHow, createApp, connect, invite, graphics, upload, finish }

/// "Publish with Ember": one question at a time, Ember does the technical parts itself.
class PublishChatScreen extends ConsumerStatefulWidget {
  const PublishChatScreen({super.key, required this.projectId, required this.appDescription});
  final String projectId;
  final String appDescription;

  @override
  ConsumerState<PublishChatScreen> createState() => _PublishChatScreenState();
}

class _PublishChatScreenState extends ConsumerState<PublishChatScreen> {
  static const _saKey = 'play_service_account';
  _Step _step = _Step.account;
  final _done = <_Step>[];
  String? _packageName;
  String? _saEmail;
  String? _busyText;
  String? _error;
  bool _manualInvite = false;
  Map<String, dynamic>? _uploadResult;
  PlayConsoleLink _console = const PlayConsoleLink();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  String get _stateKey => 'publish_chat_${widget.projectId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_stateKey);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _step = _Step.values.byName(j['step'] as String);
        _done.addAll((j['done'] as List).map((s) => _Step.values.byName(s as String)));
      }
    } catch (_) {}
    _console = await PlayConsoleLink.load();
    final sa = await ref.read(keyValueStoreProvider).read(_saKey);
    if (sa != null) {
      try {
        _saEmail = (jsonDecode(sa) as Map<String, dynamic>)['client_email'] as String?;
      } catch (_) {}
    }
    try {
      final info = await (await ref.read(runnerApiProvider.future)).androidInfo(widget.projectId);
      _packageName = info['applicationId'] as String?;
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _go(_Step next) async {
    setState(() {
      if (!_done.contains(_step)) _done.add(_step);
      _step = next;
      _error = null;
    });
    try {
      await (await SharedPreferences.getInstance()).setString(_stateKey, jsonEncode({'step': next.name, 'done': _done.map((s) => s.name).toList()}));
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Future<void> _createKey() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busyText = l.pubKeyWorking;
      _error = null;
    });
    try {
      final res = await (await ref.read(runnerApiProvider.future)).playCreateKey();
      await ref.read(keyValueStoreProvider).write(_saKey, res['key'] as String);
      _saEmail = res['email'] as String?;
      await _go(_Step.invite);
    } on RunnerException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busyText = null);
    }
  }

  Future<void> _invite(String pastedLink) async {
    final l = AppLocalizations.of(context);
    if (_saEmail == null) {
      await _go(_Step.connect);
      return;
    }
    // Remember the account and developer id: every button then opens the user's own console.
    final link = PlayConsoleLink.parse(pastedLink)?.merge(_console);
    if (link != null) {
      _console = link;
      await link.save();
    }
    final id = link?.developerId;
    if (id == null) {
      setState(() => _error = l.pubInviteBadLink);
      return;
    }
    setState(() {
      _busyText = l.pubInviteWorking;
      _error = null;
    });
    try {
      await (await ref.read(runnerApiProvider.future)).playInvite(id, _saEmail!);
      _input.clear();
      await _go(_Step.graphics);
    } on RunnerException catch (e) {
      setState(() {
        _error = e.message;
        _manualInvite = true;
      });
    } finally {
      if (mounted) setState(() => _busyText = null);
    }
  }

  /// What Ember says at each step, with the buttons the user can press.
  ({String text, List<Widget> actions}) _say(_Step s, AppLocalizations l) {
    final app = widget.appDescription.split('\n').first;
    Widget btn(String label, VoidCallback? onTap, {bool primary = false}) =>
        primary ? FilledButton(onPressed: onTap, child: Text(label)) : OutlinedButton(onPressed: onTap, child: Text(label));
    switch (s) {
      case _Step.account:
        return (text: l.pubAccountAsk(app.length > 60 ? '${app.substring(0, 60)}…' : app), actions: [
          btn(l.pubYesHaveIt, () => _go(_Step.createApp), primary: true),
          btn(l.pubNoHowTo, () => _go(_Step.accountHow)),
        ]);
      case _Step.accountHow:
        return (text: l.pubAccountHow, actions: [
          btn(l.playOpenSignup, () => _open('https://play.google.com/console/signup')),
          btn(l.pubNowIHaveIt, () => _go(_Step.createApp), primary: true),
        ]);
      case _Step.createApp:
        return (text: [l.pubCreateApp(_packageName ?? '…'), _console.developerId == null ? l.pubPasteConsoleLink : l.consoleLinkSaved(_console.developerId!)].join('\n\n'), actions: [
          btn(l.playOpenConsole, () => _open(_console.createApp)),
          if (_packageName != null) btn(l.copy, () => Clipboard.setData(ClipboardData(text: _packageName!))),
          btn(l.pubDone, () => _go(_saEmail != null ? _Step.invite : _Step.connect), primary: true),
        ]);
      case _Step.connect:
        return (text: l.pubConnect, actions: [
          btn(l.pubDoItEmber, _busyText == null ? _createKey : null, primary: true),
          btn(l.pubManual, () => context.push('/projects/${widget.projectId}/play/details', extra: widget.appDescription)),
        ]);
      case _Step.invite:
        return (text: _manualInvite ? l.pubInviteManual(_saEmail ?? '') : l.pubInvite, actions: [
          btn(l.playOpenConsole, () => _open(_console.appList(_packageName))),
          if (_manualInvite) ...[
            btn(l.copy, () => Clipboard.setData(ClipboardData(text: _saEmail ?? ''))),
            btn(l.pubDone, () => _go(_Step.graphics), primary: true),
          ],
        ]);
      case _Step.graphics:
        return (text: l.pubGraphics, actions: [
          btn(l.pubContinue, () => _go(_Step.upload), primary: true),
          btn(l.pubBackToApp, () => context.go('/projects/${widget.projectId}/create')),
        ]);
      case _Step.upload:
        return (text: l.pubUpload, actions: [
          btn(l.pubPrepareUpload, () async {
            final result = await context.push<Map<String, dynamic>?>('/projects/${widget.projectId}/play/details', extra: widget.appDescription);
            if (!mounted) return;
            if (result == null) {
              // Nothing reached Google Play: never claim success.
              setState(() => _error = l.pubNothingUploaded);
              return;
            }
            setState(() => _uploadResult = result);
            await _go(_Step.finish);
          }, primary: true),
        ]);
      case _Step.finish:
        return (text: _uploadResult == null ? l.pubFinish : '${l.playUploaded('${_uploadResult!['versionCode']}', '${_uploadResult!['track']}', _uploadResult!['downgradedToDraft'] == true ? l.playDraftNote : '')}\n\n${uploadSummary(l, _uploadResult!)}\n\n${l.pubFinish}', actions: [
          btn(l.playOpenConsole, () => _open(_console.appList(_packageName))),
          btn(l.pubReviewAnswers, () => context.push('/projects/${widget.projectId}/play/details', extra: widget.appDescription)),
        ]);
    }
  }

  Widget _bubble(BuildContext context, String text, {bool user = false, List<Widget> actions = const []}) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!user) const Padding(padding: EdgeInsets.only(right: 8, top: 4), child: EmberMark(size: 30, animate: false)),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              constraints: const BoxConstraints(maxWidth: 680),
              decoration: BoxDecoration(
                color: user ? scheme.surfaceContainerHighest : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(data: text, selectable: true, onTapLink: (_, href, _) => href == null ? null : _open(href)),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final assistant = ref.watch(publishAssistantProvider(widget.projectId));
    final history = [..._done.where((s) => s != _step)];
    final current = _say(_step, l);
    final waitingLink = (_step == _Step.invite && !_manualInvite) || (_step == _Step.createApp && _console.developerId == null);
    return Scaffold(
      appBar: AppBar(title: Text(l.pubTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                for (final s in history) Opacity(opacity: 0.55, child: _bubble(context, _say(s, l).text)),
                _bubble(context, current.text, actions: current.actions),
                if (_busyText != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 10), Expanded(child: Text(_busyText!))]),
                  ),
                if (_error != null) _bubble(context, '⚠️ $_error'),
                for (final e in assistant.entries)
                  _bubble(context, e.text.isEmpty && e.streaming ? '…' : e.text.replaceFirst(RegExp(r'^\[Publishing step: \w+\] '), ''), user: e.role == AiRole.user),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('publishInput'),
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(hintText: waitingLink ? l.pubPasteLink : l.pubAskAnything, border: const OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _busyText != null
                        ? null
                        : () {
                            final text = _input.text.trim();
                            if (text.isEmpty) return;
                            // A pasted Play Console link always updates the saved account.
                            final pasted = text.contains('play.google.com/console') ? PlayConsoleLink.parse(text) : null;
                            if (pasted != null) {
                              final link = pasted.merge(_console);
                              link.save();
                              setState(() {
                                _console = link;
                                _error = null;
                                _input.clear();
                              });
                              if (_step == _Step.invite && !_manualInvite) _invite(text);
                              return;
                            }
                            if (waitingLink && text.contains('play.google.com')) {
                              setState(() => _error = l.pubInviteBadLink);
                              return;
                            } else {
                              _input.clear();
                              assistant.send('[Publishing step: ${_step.name}] $text');
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
