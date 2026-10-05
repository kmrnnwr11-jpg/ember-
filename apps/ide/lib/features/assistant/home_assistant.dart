import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/locale.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../ai/chat_controller.dart';
import '../../widgets/ember_logo.dart';

const assistantSystemPrompt = '''
You are Ember, the assistant inside the Ember app maker, a friendly expert helping non-technical people create and publish mobile apps.
Help with: app ideas and features, how to use Ember (describe app → mockups → build → changes in chat → APK/AAB → Play Store), Google Play Console and App Store steps, Firebase/Supabase/Google Sign-In setup, costs, privacy policy and GDPR basics, and general questions.
Answer in the user's language, concisely, with short steps and real links when useful. Be honest when something needs a paid account (e.g. Google Play Console 25 USD one-time, Apple Developer 99 USD/year) and say who is paid.''';

/// Free home assistant: Gemini through the Runner's own key (no user key needed).
final homeAssistantProvider = ChangeNotifierProvider<ChatController>((ref) {
  return ChatController(
    projectId: '_home_assistant',
    resolveProvider: (_) async {
      final session = ref.read(sessionProvider).value;
      if (session == null) throw AiException(ref.read(stringsProvider).assistantSignIn);
      return GeminiProvider(
        AiEndpoint.proxy(apiKey: '', runnerUrl: session.runnerUrl, runnerToken: await session.token(), proxyPath: 'assistant'),
      );
    },
    systemPrompt: assistantSystemPrompt,
    attachFiles: false,
  )..selectModel(const AiModel(provider: AiProviderId.gemini, id: 'gemini-2.5-flash', label: 'Gemini 2.5 Flash', inputPerMTok: 0, outputPerMTok: 0));
});

/// The same assistant, but told which app it is talking about, so answers are
/// about this app: its privacy policy, its AdMob setup, its Play Console rows.
final projectAssistantProvider = ChangeNotifierProvider.family<ChatController, ({String id, String name})>((ref, app) {
  return ChatController(
    projectId: 'assistant_${app.id}',
    resolveProvider: (_) async {
      final session = ref.read(sessionProvider).value;
      if (session == null) throw AiException(ref.read(stringsProvider).assistantSignIn);
      return GeminiProvider(
        AiEndpoint.proxy(apiKey: '', runnerUrl: session.runnerUrl, runnerToken: await session.token(), proxyPath: 'assistant'),
      );
    },
    systemPrompt: '''
$assistantSystemPrompt

The user is working on their app "${app.name}", made with Ember. You are connected to this app: below you get its REAL data, read live from the project.
Every question is about this app. Answer with the exact values from the data (package name, version, listing, Firebase, SHA-1...), never say you cannot see the app.
If a value is not in the data, say it is not set yet and which Ember button sets it.
Only talk about this app and apps made with Ember; politely decline unrelated topics.
The user may attach screenshots: read them carefully (Play Console pages, errors, the app's screens) and say exactly what to click or type.''',
    attachFiles: false,
    contextBuilder: () => appFacts(ref, app.id),
  )..selectModel(const AiModel(provider: AiProviderId.gemini, id: 'gemini-2.5-flash', label: 'Gemini 2.5 Flash', inputPerMTok: 0, outputPerMTok: 0));
});

/// Everything Ember knows about one app, as text for the assistant.
Future<String?> appFacts(Ref ref, String projectId) async {
  final api = await ref.read(runnerApiProvider.future);
  final out = StringBuffer('APP DATA (live):\n');
  Future<void> add(String label, Future<Object?> Function() read) async {
    try {
      final v = await read().timeout(const Duration(seconds: 20));
      out.writeln('$label: ${const JsonEncoder.withIndent(' ').convert(v)}');
    } catch (_) {
      out.writeln('$label: not available');
    }
  }

  await Future.wait([
    add('Project', () async {
      final p = await api.project(projectId);
      return {'appName': p.title ?? p.name, 'folder': p.name, 'createdAt': '${p.createdAt}'};
    }),
    add('Android (package name = applicationId, SHA-1 of the upload key and debug key)', () async {
      final info = await api.androidInfo(projectId);
      final id = info['applicationId'] as String? ?? '';
      return {
        ...info,
        if (id.startsWith('dev.fluttercursor.app.'))
          'note': 'Temporary placeholder: Ember replaces it with the final name (com.dreamcodestudio.<appname>) at the first release build (APK/AAB). After Play has it, it never changes.',
      };
    }),
    add('Store listing, logos, screenshots', () async {
      final s = await api.storeState(projectId);
      final listing = Map<String, dynamic>.of(s['listing'] as Map<String, dynamic>? ?? {});
      // Long JSON blobs would drown the useful fields.
      for (final k in ['dataSafety', 'contentRating', 'otherDeclarations', 'translations']) {
        final v = listing[k];
        if (v is String && v.length > 1500) listing[k] = '${v.substring(0, 1500)}…';
      }
      return {
        'listing': listing,
        'logoApplied': s['applied'] != null,
        'screenshots': (s['screenshots'] as List?)?.length ?? 0,
      };
    }),
    add('Play Console App content answers + detected data use', () => api.appContent(projectId)),
  ]);
  return out.toString();
}

class HomeAssistantPanel extends ConsumerStatefulWidget {
  const HomeAssistantPanel({super.key, this.onClose, this.app, this.onFixApp, this.fixing = false});

  final VoidCallback? onClose;

  /// When set, the assistant answers about this app instead of in general.
  final ({String id, String name})? app;

  /// When set, the chat can change the app: the message is sent to the builder,
  /// which edits the code and rebuilds. Used to fix a rejected app by chat.
  final void Function(String request)? onFixApp;

  /// True while the builder is applying a change, so the button waits.
  final bool fixing;

  @override
  ConsumerState<HomeAssistantPanel> createState() => _HomeAssistantPanelState();
}

class _HomeAssistantPanelState extends ConsumerState<HomeAssistantPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _images = <({String mimeType, Uint8List bytes})>[];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Enter sends the message; Shift+Enter goes to a new line.
  KeyEventResult _onKey(ChatController c, KeyEvent event) {
    if (event is! KeyDownEvent || !_focus.hasFocus) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter && event.logicalKey != LogicalKeyboardKey.numpadEnter) return KeyEventResult.ignored;
    final keys = HardwareKeyboard.instance;
    if (keys.isShiftPressed || keys.isControlPressed || keys.isMetaPressed || keys.isAltPressed) return KeyEventResult.ignored;
    // Enter that confirms a word being composed belongs to the keyboard.
    if (_input.value.composing.isValid) return KeyEventResult.ignored;
    _send(c);
    return KeyEventResult.handled;
  }

  Future<void> _pickImages() async {
    final l = AppLocalizations.of(context);
    final group = XTypeGroup(label: l.imagesLabel, extensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif']);
    final files = await openFiles(acceptedTypeGroups: [group]);
    for (final f in files) {
      final bytes = await f.readAsBytes();
      // The Runner accepts about 5 MB per request.
      if (bytes.length > 3500000) {
        if (mounted) showEmberSnack(context, l.assistantImageTooLarge(f.name), error: true);
        continue;
      }
      final ext = f.name.split('.').last.toLowerCase();
      final mime = switch (ext) { 'png' => 'image/png', 'webp' => 'image/webp', 'gif' => 'image/gif', _ => 'image/jpeg' };
      setState(() => _images.add((mimeType: mime, bytes: bytes)));
    }
  }

  void _send(ChatController c, [String? preset]) {
    final text = (preset ?? _input.text).trim();
    if ((text.isEmpty && _images.isEmpty) || c.busy) return;
    _input.clear();
    final images = List.of(_images);
    setState(_images.clear);
    c.send(text, images: images);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final duration = Motion.of(context);
      final end = _scroll.position.maxScrollExtent;
      if (duration == Duration.zero) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(end, duration: duration, curve: Motion.curve);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.app == null ? ref.watch(homeAssistantProvider) : ref.watch(projectAssistantProvider(widget.app!));
    final scheme = context.scheme;
    final health = ref.watch(runnerHealthProvider).value;
    final enabled = (health?['engines'] as Map?)?['assistant'] != false;
    final suggestions = widget.app == null
        ? [l.assistantSuggest1, l.assistantSuggest2, l.assistantSuggest3]
        : [l.acAskPrivacy, l.acAskAdmob, l.acAskContent];

    return Material(
      color: scheme.surfaceContainerLow,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
            child: Row(
              children: [
                const EmberMark(size: 30),
                Gap.hSm,
                Expanded(child: Text(l.assistantTitle, style: context.text.titleSmall)),
                Pill(l.assistantFree, tone: Tone.success),
                IconButton(tooltip: l.clearChat, icon: const Icon(Icons.delete_sweep_outlined, size: 20), onPressed: c.entries.isEmpty ? null : c.clear),
                if (widget.onClose != null) IconButton(tooltip: l.close, icon: const Icon(Icons.close_outlined, size: 20), onPressed: widget.onClose),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) => c.entries.isEmpty
                  ? SingleChildScrollView(
                      child: EmptyState(
                        compact: true,
                        text: enabled ? l.assistantEmpty : l.assistantUnconfigured,
                        action: !enabled
                            ? null
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final s in suggestions)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                                      child: OutlinedButton(onPressed: () => _send(c, s), child: Text(s, textAlign: TextAlign.center)),
                                    ),
                                ],
                              ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(Gap.sm),
                      itemCount: c.entries.length,
                      itemBuilder: (context, i) {
                        final e = c.entries[i];
                        final user = e.role == AiRole.user;
                        return ChatBubble(
                          isUser: user,
                          maxWidth: 520,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (e.images.isNotEmpty)
                                Wrap(
                                  spacing: Gap.xs,
                                  runSpacing: Gap.xs,
                                  children: [
                                    for (final b in e.images)
                                      ClipRRect(borderRadius: Radii.smAll, child: Image.memory(b, height: 120, fit: BoxFit.contain)),
                                  ],
                                ),
                              if (user)
                                SelectableText(e.text)
                              else if (e.text.isEmpty && e.streaming)
                                const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              else
                                MarkdownBody(
                                  data: e.text,
                                  selectable: true,
                                  onTapLink: (_, href, _) {
                                    if (href != null) launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
                                  },
                                ),
                              if (e.error != null) InlineMessage(e.error!, error: true),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(Gap.sm),
            child: ListenableBuilder(
              listenable: c,
              // Enter sends the message; Shift+Enter goes to a new line.
              builder: (context, _) => Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: (_, event) => _onKey(c, event),
                child: ChatComposer(
                  controller: _input,
                  focusNode: _focus,
                  fieldKey: const Key('assistantInput'),
                  sendKey: const Key('assistantSend'),
                  hint: l.assistantHint,
                  maxLines: 6,
                  enabled: enabled,
                  onSend: () => _send(c),
                  sendTooltip: l.send,
                  busy: c.busy,
                  onStop: c.stop,
                  stopTooltip: l.stop,
                  above: _images.isEmpty
                      ? null
                      : SizedBox(
                          height: 68,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (var i = 0; i < _images.length; i++)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                                  child: Stack(
                                    children: [
                                      ClipRRect(borderRadius: Radii.smAll, child: Image.memory(_images[i].bytes, height: 68, width: 68, fit: BoxFit.cover)),
                                      // A small disc to look at, a full-size target to hit.
                                      PositionedDirectional(
                                        top: 0,
                                        end: 0,
                                        child: IconButton(
                                          tooltip: l.delete,
                                          padding: const EdgeInsets.all(2),
                                          alignment: AlignmentDirectional.topEnd,
                                          constraints: const BoxConstraints.tightFor(width: kTapTarget, height: kTapTarget),
                                          onPressed: () => setState(() => _images.removeAt(i)),
                                          icon: DecoratedBox(
                                            decoration: BoxDecoration(color: context.ember.scrim, shape: BoxShape.circle),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: Icon(Icons.close_outlined, size: 14, color: context.ember.onCodeSurface),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                  leading: [
                    IconButton(
                      key: const Key('assistantImage'),
                      tooltip: l.assistantAddImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      onPressed: enabled && !c.busy ? _pickImages : null,
                    ),
                  ],
                  trailing: [
                    // "Fix the app": send the text to the builder so it changes
                    // the code, instead of just answering in the chat.
                    if (widget.onFixApp != null) ...[
                      Gap.hSm,
                      IconButton.filledTonal(
                        key: const Key('assistantFixApp'),
                        tooltip: l.assistantFixApp,
                        icon: widget.fixing
                            ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.auto_fix_high_outlined),
                        onPressed: widget.fixing || !enabled
                            ? null
                            : () {
                                final text = _input.text.trim();
                                if (text.isEmpty) return;
                                _input.clear();
                                widget.onFixApp!(text);
                              },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
