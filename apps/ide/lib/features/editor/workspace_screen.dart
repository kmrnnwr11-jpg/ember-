import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/runner_socket.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../../widgets/connection_badge.dart';
import '../ai/ai_settings.dart';
import '../ai/apply_dialog.dart';
import '../ai/chat_controller.dart';
import '../ai/chat_panel.dart';
import '../preview/preview_controller.dart';
import '../preview/preview_panel.dart';
import '../terminal/terminal_panel.dart';
import '../terminal/terminals_controller.dart';
import 'editor_pane.dart';
import 'file_tree.dart';
import 'project_controller.dart';

final projectControllerProvider = ChangeNotifierProvider.autoDispose.family<ProjectController, String>((ref, projectId) {
  final socket = ref.watch(runnerSocketProvider);
  final c = ProjectController(projectId: projectId, request: socket.request, events: socket.events);
  c.loadDir('');
  socket.watch(projectId).catchError((_) {});
  ref.onDispose(() => socket.unwatch(projectId).catchError((_) {}));
  return c;
});

final terminalsControllerProvider = ChangeNotifierProvider.autoDispose.family<TerminalsController, String>((ref, projectId) {
  final socket = ref.watch(runnerSocketProvider);
  final connected = _ConnectedNotifier(socket.state);
  ref.onDispose(connected.dispose);
  return TerminalsController(projectId: projectId, request: socket.request, events: socket.events, connected: connected);
});

final previewControllerProvider = ChangeNotifierProvider.autoDispose.family<PreviewController, String>((ref, projectId) {
  final socket = ref.watch(runnerSocketProvider);
  final session = ref.watch(sessionProvider).value!;
  final c = PreviewController(
    projectId: projectId,
    runnerUrl: session.runnerUrl,
    request: socket.request,
    events: socket.events,
  );
  c.refreshStatus();
  return c;
});

final chatControllerProvider = ChangeNotifierProvider.family<ChatController, String>((ref, projectId) {
  final factory = ref.watch(aiProviderFactory);
  return ChatController(
    projectId: projectId,
    resolveProvider: factory,
    loadHistory: () => ChatHistoryStore.load(projectId),
    saveHistory: (rows) => ChatHistoryStore.save(projectId, rows),
  );
});

class _ConnectedNotifier extends ValueNotifier<bool> {
  _ConnectedNotifier(this._state) : super(_state.value == SocketState.connected) {
    _state.addListener(_sync);
  }
  final ValueListenable<SocketState> _state;
  void _sync() => value = _state.value == SocketState.connected;
  @override
  void dispose() {
    _state.removeListener(_sync);
    super.dispose();
  }
}

final _projectProvider = FutureProvider.autoDispose.family<Project, String>((ref, id) async {
  final api = await ref.watch(runnerApiProvider.future);
  return api.project(id);
});

/// Responsive IDE shell: tree | editor + terminal | preview on wide screens,
/// bottom navigation on phones.
class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key, required this.projectId, this.initialPanel});

  final String projectId;

  /// `preview` or `ai` to open that side panel on arrival.
  final String? initialPanel;

  static const wideBreakpoint = Breakpoints.medium;

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

enum _MobileTab { files, editor, terminal, preview, ai }

enum _SidePanel { preview, ai }

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  _MobileTab _mobileTab = _MobileTab.files;
  double _treeWidth = Widths.rail;
  double _terminalHeight = 240;
  double _sideWidth = 440;
  bool _terminalOpen = false;
  _SidePanel? _side;

  @override
  void initState() {
    super.initState();
    switch (widget.initialPanel) {
      case 'preview':
        _side = _SidePanel.preview;
        _mobileTab = _MobileTab.preview;
      case 'ai':
        _side = _SidePanel.ai;
        _mobileTab = _MobileTab.ai;
    }
  }

  void _toggleSide(_SidePanel panel) => setState(() {
    _side = _side == panel ? null : panel;
    _mobileTab = panel == _SidePanel.ai ? _MobileTab.ai : _MobileTab.preview;
  });

  ChatFileContext? _openFileContext() {
    final f = ref.read(projectControllerProvider(widget.projectId)).activeFile;
    return f == null ? null : ChatFileContext(f.path, f.controller.text);
  }

  /// Apply an AI code block: diff against the target file, then load it into
  /// the editor (unsaved) so the user reviews and saves (§1.3).
  Future<void> _applyCode(CodeSegment block) async {
    final l = AppLocalizations.of(context);
    final c = ref.read(projectControllerProvider(widget.projectId));
    final path = block.path ?? c.activeFile?.path;
    if (path == null) return _snack(l.applyNoTarget, error: true);

    var exists = true;
    try {
      await c.open(path);
    } on RunnerException catch (e) {
      if (e.code != 'not_found') return _snack(l.error(e.message), error: true);
      exists = false;
    }
    final tab = exists ? c.tabs.firstWhere((t) => t.path == path) : null;
    if (!mounted) return;
    final accepted = await showApplyDiff(context, path: path, oldText: tab?.controller.text ?? '', newText: block.code);
    if (!accepted) return;
    try {
      if (tab == null) {
        await c.createFile(ProjectPath.dirname(path), ProjectPath.basename(path));
      }
      final target = c.tabs.firstWhere((t) => t.path == path);
      target.controller.text = block.code;
      c.activate(c.tabs.indexOf(target));
      if (mounted) setState(() => _mobileTab = _MobileTab.editor);
      _snack(l.applied(path));
    } on RunnerException catch (e) {
      _snack(l.error(e.message), error: true);
    }
  }

  Future<void> _open(String path) async {
    final c = ref.read(projectControllerProvider(widget.projectId));
    final binaryMsg = AppLocalizations.of(context).binaryFile;
    try {
      await c.open(path);
      if (mounted) setState(() => _mobileTab = _MobileTab.editor);
    } on RunnerException catch (e) {
      _snack(e.code == 'binary' || e.code == 'too_large' ? binaryMsg : e.message, error: true);
    }
  }

  Future<void> _save(OpenFile file) async {
    final l = AppLocalizations.of(context);
    final c = ref.read(projectControllerProvider(widget.projectId));
    try {
      await c.save(file);
    } on SaveConflict {
      if (!mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(l.conflictTitle),
          content: Text(l.conflictBody(file.path)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
            TextButton(onPressed: () => Navigator.pop(d, 'reload'), child: Text(l.reload)),
            FilledButton(onPressed: () => Navigator.pop(d, 'overwrite'), child: Text(l.overwrite)),
          ],
        ),
      );
      if (choice == 'reload') await c.reload(file);
      if (choice == 'overwrite') await c.save(file, force: true);
    } on RunnerException catch (e) {
      _snack(l.error(e.message), error: true);
    }
  }

  void _toggleTerminal() {
    setState(() {
      _terminalOpen = !_terminalOpen;
      _mobileTab = _MobileTab.terminal;
    });
  }

  void _runWeb() {
    setState(() {
      _side = _SidePanel.preview;
      _mobileTab = _MobileTab.preview;
    });
    ref.read(previewControllerProvider(widget.projectId)).run();
  }

  void _snack(String msg, {bool error = false}) {
    if (mounted) showEmberSnack(context, msg, error: error);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = ref.watch(projectControllerProvider(widget.projectId));
    final terminals = ref.watch(terminalsControllerProvider(widget.projectId));
    final preview = ref.watch(previewControllerProvider(widget.projectId));
    final project = ref.watch(_projectProvider(widget.projectId));
    final tree = FileTree(controller: controller, onOpen: _open);
    final editor = EditorPane(controller: controller, onSave: _save);
    final terminalPanel = TerminalPanel(controller: terminals);
    final previewPanel = PreviewPanel(controller: preview);
    final chatPanel = ChatPanel(
      controller: ref.watch(chatControllerProvider(widget.projectId)),
      openFile: _openFileContext,
      onApply: _applyCode,
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.backquote, control: true): _toggleTerminal,
        const SingleActivator(LogicalKeyboardKey.f5): _runWeb,
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): () => _toggleSide(_SidePanel.ai),
        const SingleActivator(LogicalKeyboardKey.keyL, meta: true): () => _toggleSide(_SidePanel.ai),
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= WorkspaceScreen.wideBreakpoint;
          // Panels are mirrored in right-to-left languages, and so is the drag that resizes them.
          final dir = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.go('/projects')),
              title: Text(project.value?.name ?? ''),
              actions: [
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final f = controller.activeFile;
                    return IconButton(
                      tooltip: '${l.save} (Ctrl+S)',
                      icon: const Icon(Icons.save_outlined),
                      onPressed: f != null && f.dirty && !f.saving ? () => _save(f) : null,
                    );
                  },
                ),
                IconButton(
                  key: const Key('appBarRunWeb'),
                  tooltip: '${l.runWeb} (F5)',
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _runWeb,
                ),
                if (wide) ...[
                  IconButton(
                    tooltip: '${l.toggleTerminal} (Ctrl+`)',
                    isSelected: _terminalOpen,
                    icon: const Icon(Icons.terminal),
                    onPressed: _toggleTerminal,
                  ),
                  IconButton(
                    tooltip: l.togglePreview,
                    isSelected: _side == _SidePanel.preview,
                    icon: const Icon(Icons.phone_iphone),
                    onPressed: () => _toggleSide(_SidePanel.preview),
                  ),
                  IconButton(
                    key: const Key('toggleAi'),
                    tooltip: '${l.toggleAi} (Ctrl+L)',
                    isSelected: _side == _SidePanel.ai,
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: () => _toggleSide(_SidePanel.ai),
                  ),
                ],
                const ConnectionBadge(),
              ],
            ),
            body: wide
                ? Row(
                    children: [
                      SizedBox(width: _treeWidth, child: tree),
                      _Splitter.vertical(
                        onDrag: (d) => setState(() => _treeWidth = (_treeWidth + d * dir).clamp(180, constraints.maxWidth * 0.4)),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: editor),
                            if (_terminalOpen) ...[
                              _Splitter.horizontal(
                                onDrag: (d) => setState(
                                  () => _terminalHeight = (_terminalHeight - d).clamp(120, constraints.maxHeight * 0.7),
                                ),
                              ),
                              SizedBox(height: _terminalHeight, child: terminalPanel),
                            ],
                          ],
                        ),
                      ),
                      if (_side != null) ...[
                        _Splitter.vertical(
                          onDrag: (d) => setState(() => _sideWidth = (_sideWidth - d * dir).clamp(320, constraints.maxWidth * 0.6)),
                        ),
                        SizedBox(
                          width: _sideWidth,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(Gap.sm),
                                child: SegmentedButton<_SidePanel>(
                                  segments: [
                                    ButtonSegment(value: _SidePanel.preview, icon: const Icon(Icons.phone_iphone), label: Text(l.preview)),
                                    ButtonSegment(value: _SidePanel.ai, icon: const Icon(Icons.auto_awesome), label: Text(l.ai)),
                                  ],
                                  selected: {_side!},
                                  onSelectionChanged: (s) => setState(() => _side = s.first),
                                ),
                              ),
                              Expanded(
                                child: IndexedStack(
                                  index: _side!.index,
                                  children: [previewPanel, chatPanel],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                : IndexedStack(
                    index: _mobileTab.index,
                    children: [tree, editor, terminalPanel, previewPanel, chatPanel],
                  ),
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: _mobileTab.index,
                    onDestinationSelected: (i) {
                      setState(() => _mobileTab = _MobileTab.values[i]);
                    },
                    destinations: [
                      NavigationDestination(icon: const Icon(Icons.folder_outlined), label: l.files),
                      NavigationDestination(icon: const Icon(Icons.code), label: l.editor),
                      NavigationDestination(icon: const Icon(Icons.terminal), label: l.terminal),
                      NavigationDestination(icon: const Icon(Icons.phone_iphone), label: l.preview),
                      NavigationDestination(icon: const Icon(Icons.auto_awesome), label: l.ai),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _Splitter extends StatelessWidget {
  const _Splitter.vertical({required this.onDrag}) : axis = Axis.vertical;
  const _Splitter.horizontal({required this.onDrag}) : axis = Axis.horizontal;

  final Axis axis;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final vertical = axis == Axis.vertical;
    return MouseRegion(
      cursor: vertical ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: vertical ? (d) => onDrag(d.delta.dx) : null,
        onVerticalDragUpdate: vertical ? null : (d) => onDrag(d.delta.dy),
        child: vertical ? const VerticalDivider(width: Gap.sm, thickness: 1) : const Divider(height: Gap.sm, thickness: 1),
      ),
    );
  }
}
