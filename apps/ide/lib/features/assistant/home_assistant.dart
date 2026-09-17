import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
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
      if (session == null) throw const AiException('Accedi per usare l\'assistente');
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
      if (session == null) throw const AiException('Accedi per usare l\'assistente');
      return GeminiProvider(
        AiEndpoint.proxy(apiKey: '', runnerUrl: session.runnerUrl, runnerToken: await session.token(), proxyPath: 'assistant'),
      );
    },
    systemPrompt: '$assistantSystemPrompt\n\nThe user is working on their app "${app.name}". Assume every question is about that app unless they say otherwise.',
    attachFiles: false,
  )..selectModel(const AiModel(provider: AiProviderId.gemini, id: 'gemini-2.5-flash', label: 'Gemini 2.5 Flash', inputPerMTok: 0, outputPerMTok: 0));
});

class HomeAssistantPanel extends ConsumerStatefulWidget {
  const HomeAssistantPanel({super.key, this.onClose, this.app});

  final VoidCallback? onClose;

  /// When set, the assistant answers about this app instead of in general.
  final ({String id, String name})? app;

  @override
  ConsumerState<HomeAssistantPanel> createState() => _HomeAssistantPanelState();
}

class _HomeAssistantPanelState extends ConsumerState<HomeAssistantPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(ChatController c, [String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || c.busy) return;
    _input.clear();
    c.send(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.app == null ? ref.watch(homeAssistantProvider) : ref.watch(projectAssistantProvider(widget.app!));
    final scheme = Theme.of(context).colorScheme;
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
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
            child: Row(
              children: [
                const EmberMark(size: 30),
                const SizedBox(width: 8),
                Expanded(child: Text(l.assistantTitle, style: Theme.of(context).textTheme.titleSmall)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                  child: Text(l.assistantFree, style: const TextStyle(fontSize: 11, color: Colors.green)),
                ),
                IconButton(tooltip: l.clearChat, icon: const Icon(Icons.delete_sweep_outlined, size: 20), onPressed: c.entries.isEmpty ? null : c.clear),
                if (widget.onClose != null) IconButton(icon: const Icon(Icons.close, size: 20), onPressed: widget.onClose),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) => c.entries.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 24),
                        const Center(child: EmberMark(size: 96)),
                        const SizedBox(height: 12),
                        Text(enabled ? l.assistantEmpty : l.assistantUnconfigured, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        if (enabled)
                          for (final s in suggestions)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: OutlinedButton(onPressed: () => _send(c, s), child: Text(s, textAlign: TextAlign.center)),
                            ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(10),
                      itemCount: c.entries.length,
                      itemBuilder: (context, i) {
                        final e = c.entries[i];
                        final user = e.role == AiRole.user;
                        return Align(
                          alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(maxWidth: 520),
                            decoration: BoxDecoration(
                              color: user ? scheme.primaryContainer : scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                if (e.error != null) Text(e.error!, style: TextStyle(color: scheme.error)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): () => _send(c)},
                      child: TextField(
                        key: const Key('assistantInput'),
                        controller: _input,
                        enabled: enabled,
                        minLines: 1,
                        maxLines: 6,
                        decoration: InputDecoration(hintText: l.assistantHint, isDense: true, border: const OutlineInputBorder()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  c.busy
                      ? IconButton.filledTonal(icon: const Icon(Icons.stop), onPressed: c.stop)
                      : IconButton.filled(key: const Key('assistantSend'), icon: const Icon(Icons.arrow_upward), onPressed: enabled ? () => _send(c) : null),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
