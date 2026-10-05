import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
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
    // Without a model nothing can be sent: keep what was typed.
    if (text.trim().isEmpty || c.busy || c.model == null) return;
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
              color: context.scheme.surfaceContainer,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: kTapTarget),
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
                        padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                        child: Text('≈\$${c.sessionCost.toStringAsFixed(4)}', style: context.text.labelSmall),
                      ),
                    IconButton(tooltip: l.clearChat, icon: const Icon(Icons.delete_sweep_outlined), onPressed: c.entries.isEmpty ? null : c.clear),
                  ],
                ),
              ),
            ),
            Expanded(
              child: c.entries.isEmpty
                  ? SingleChildScrollView(
                      child: EmptyState(
                        compact: true,
                        text: settings.keys.isEmpty && settings.compatibleBaseUrl.isEmpty ? l.chatNoKeys : l.chatEmpty,
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(Gap.sm),
                      itemCount: c.entries.length,
                      itemBuilder: (_, i) => _MessageBubble(entry: c.entries[i], onApply: widget.onApply),
                    ),
            ),
            if (settings.keys.isEmpty && settings.compatibleBaseUrl.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Gap.sm),
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.key_outlined),
                  label: Text(l.aiSettings),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Gap.sm),
              // The send button stays lit without a model, where it used to be
              // greyed out: ChatComposer can only disable it together with the
              // field, and typing must stay possible. _send does nothing then.
              child: ChatComposer(
                controller: _input,
                focusNode: _focus,
                fieldKey: const Key('chatInput'),
                sendKey: const Key('chatSend'),
                hint: l.askAi,
                maxLines: 8,
                onSend: _send,
                sendTooltip: '${l.send} (Ctrl+Enter)',
                busy: c.busy,
                onStop: c.stop,
                stopTooltip: l.stop,
                above: file == null
                    ? null
                    : Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FilterChip(
                          avatar: const Icon(Icons.description_outlined, size: 14),
                          label: Text(ProjectPath.basename(file.path)),
                          tooltip: l.attachOpenFile,
                          selected: c.attachOpenFile,
                          onSelected: (_) => c.toggleAttach(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
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
    final user = entry.role == AiRole.user;
    final segments = user ? <MessageSegment>[TextSegment(entry.text)] : CodeBlocks.parse(entry.text);
    return ChatBubble(
      isUser: user,
      maxWidth: Widths.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.contextPath != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_file_outlined, size: 14),
                Gap.hXs,
                Flexible(child: Text(entry.contextPath!, style: context.text.labelSmall, overflow: TextOverflow.ellipsis)),
              ],
            ),
          for (final s in segments)
            switch (s) {
              TextSegment(:final markdown) => user
                  ? SelectableText(markdown)
                  : MarkdownBody(data: markdown, selectable: true, softLineBreak: true),
              CodeSegment() => _CodeBlock(block: s, onApply: onApply),
            },
          if (entry.streaming && entry.text.isEmpty)
            const Padding(padding: EdgeInsets.all(Gap.xs), child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))),
          if (entry.error != null)
            Padding(
              padding: const EdgeInsets.only(top: Gap.sm),
              child: InlineMessage(l.error(entry.error!), error: true),
            ),
          if (!user && !entry.streaming && entry.error == null)
            Padding(
              padding: const EdgeInsets.only(top: Gap.xs),
              child: Text(
                [
                  if (entry.model != null) entry.model!.split(':').last,
                  if (entry.outputTokens > 0) '${entry.inputTokens}→${entry.outputTokens} tok',
                  if (entry.costUsd != null) '≈\$${entry.costUsd!.toStringAsFixed(4)}',
                  if (entry.stopReason == 'max_tokens') l.truncated,
                  if (entry.stopReason == 'refusal') l.refused,
                  if (entry.stopReason == 'stopped') l.stopped,
                ].join(' · '),
                style: context.text.labelSmall,
              ),
            ),
        ],
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
    final ember = context.ember;
    // Readable on the always-dark surface in both themes.
    final onDark = TextButton.styleFrom(foregroundColor: ember.onCodeSurface, disabledForegroundColor: ember.codeMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: LogSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsetsDirectional.only(start: Gap.md),
              decoration: BoxDecoration(
                color: ember.onCodeSurface.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sm)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      block.path ?? block.language ?? '',
                      style: TextStyle(color: ember.codeMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    style: onDark,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: block.code));
                      showEmberSnack(context, l.copied);
                    },
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: Text(l.copy),
                  ),
                  TextButton.icon(
                    style: onDark,
                    onPressed: block.complete ? () => onApply(block) : null,
                    icon: const Icon(Icons.playlist_add_check_outlined, size: 16),
                    label: Text(l.apply),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(Gap.md),
              child: SelectableText(block.code),
            ),
          ],
        ),
      ),
    );
  }
}
