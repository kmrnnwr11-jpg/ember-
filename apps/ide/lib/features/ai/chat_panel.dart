import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../l10n/app_localizations.dart';
import 'ai_settings.dart';
import 'chat_controller.dart';
import 'model_picker.dart';

/// Called when the user presses Apply on a code block.
typedef ApplyCode = Future<void> Function(CodeSegment block);

class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({super.key, required this.controller, required this.openFile, required this.onApply});

  final ChatController controller;
  final ChatFileContext? Function() openFile;
  final ApplyCode onApply;

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  ChatController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_autoScroll);
    _restoreModel();
  }

  Future<void> _restoreModel() async {
    if (c.model != null) return;
    final catalog = await ref.read(aiCatalogProvider.future);
    final settings = await ref.read(aiSettingsProvider.future);
    final saved = await ProjectModelStore.get(c.projectId);
    final pick = catalog.where((m) => m.key == saved).firstOrNull ??
        catalog.where((m) => m.key == settings.defaultModel && settings.isConfigured(m.provider)).firstOrNull ??
        catalog.where((m) => settings.isConfigured(m.provider)).firstOrNull ??
        catalog.where((m) => m.tags.contains('default')).firstOrNull;
    if (pick != null && mounted && c.model == null) c.selectModel(pick);
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients && _scroll.position.maxScrollExtent - _scroll.offset < 200) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    c.removeListener(_autoScroll);
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty || c.busy) return;
    _input.clear();
    c.send(text, openFile: widget.openFile());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final catalog = ref.watch(aiCatalogProvider).value ?? builtInCatalog;
    final settings = ref.watch(aiSettingsProvider).value ?? const AiSettings();
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final file = widget.openFile();
        return Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: ModelPicker(
                        models: catalog,
                        settings: settings,
                        selected: c.model,
                        onSelected: (m) {
                          c.selectModel(m);
                          ProjectModelStore.set(c.projectId, m.key);
                        },
                        onOpenSettings: () => context.push('/settings'),
                      ),
                    ),
                    if (c.sessionCost > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text('≈\$${c.sessionCost.toStringAsFixed(4)}', style: Theme.of(context).textTheme.labelSmall),
                      ),
                    IconButton(tooltip: l.clearChat, icon: const Icon(Icons.delete_sweep_outlined), onPressed: c.entries.isEmpty ? null : c.clear),
                  ],
                ),
              ),
            ),
            Expanded(
              child: c.entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          settings.keys.isEmpty && settings.compatibleBaseUrl.isEmpty ? l.chatNoKeys : l.chatEmpty,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(8),
                      itemCount: c.entries.length,
                      itemBuilder: (_, i) => _MessageBubble(entry: c.entries[i], onApply: widget.onApply),
                    ),
            ),
            if (settings.keys.isEmpty && settings.compatibleBaseUrl.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.key),
                  label: Text(l.aiSettings),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (file != null)
                    FilterChip(
                      avatar: const Icon(Icons.description_outlined, size: 14),
                      label: Text(ProjectPath.basename(file.path)),
                      tooltip: l.attachOpenFile,
                      selected: c.attachOpenFile,
                      onSelected: (_) => c.toggleAttach(),
                      visualDensity: VisualDensity.compact,
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.enter, control: true): _send,
                            const SingleActivator(LogicalKeyboardKey.enter, meta: true): _send,
                          },
                          child: TextField(
                            key: const Key('chatInput'),
                            controller: _input,
                            focusNode: _focus,
                            minLines: 1,
                            maxLines: 8,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(hintText: l.askAi, isDense: true, border: const OutlineInputBorder()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      c.busy
                          ? IconButton.filledTonal(tooltip: l.stop, icon: const Icon(Icons.stop), onPressed: c.stop)
                          : IconButton.filled(
                              key: const Key('chatSend'),
                              tooltip: '${l.send} (Ctrl+Enter)',
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: c.model == null ? null : _send,
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry, required this.onApply});

  final ChatEntry entry;
  final ApplyCode onApply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final user = entry.role == AiRole.user;
    final segments = user ? <MessageSegment>[TextSegment(entry.text)] : CodeBlocks.parse(entry.text);
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 720),
        decoration: BoxDecoration(
          color: user ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.contextPath != null)
              Text('📎 ${entry.contextPath}', style: Theme.of(context).textTheme.labelSmall),
            for (final s in segments)
              switch (s) {
                TextSegment(:final markdown) => user
                    ? SelectableText(markdown)
                    : MarkdownBody(data: markdown, selectable: true, softLineBreak: true),
                CodeSegment() => _CodeBlock(block: s, onApply: onApply),
              },
            if (entry.streaming && entry.text.isEmpty)
              const Padding(padding: EdgeInsets.all(4), child: SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))),
            if (entry.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.error(entry.error!), style: TextStyle(color: scheme.error)),
              ),
            if (!user && !entry.streaming && entry.error == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    if (entry.model != null) entry.model!.split(':').last,
                    if (entry.outputTokens > 0) '${entry.inputTokens}→${entry.outputTokens} tok',
                    if (entry.costUsd != null) '≈\$${entry.costUsd!.toStringAsFixed(4)}',
                    if (entry.stopReason == 'max_tokens') l.truncated,
                    if (entry.stopReason == 'refusal') l.refused,
                    if (entry.stopReason == 'stopped') l.stopped,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.block, required this.onApply});

  final CodeSegment block;
  final ApplyCode onApply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    block.path ?? block.language ?? '',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: block.code));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied), duration: const Duration(seconds: 1)));
                  },
                  icon: const Icon(Icons.copy, size: 14),
                  label: Text(l.copy),
                ),
                TextButton.icon(
                  onPressed: block.complete ? () => onApply(block) : null,
                  icon: const Icon(Icons.playlist_add_check, size: 16),
                  label: Text(l.apply),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            child: SelectableText(
              block.code,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: Color(0xFFD4D4D4), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
