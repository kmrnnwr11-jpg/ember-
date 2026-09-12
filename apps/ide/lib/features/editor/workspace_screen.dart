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
import '../../widgets/connection_badge.dart';
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
  const WorkspaceScreen({super.key, required this.projectId});

  final String projectId;

  static const wideBreakpoint = 840.0;

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

enum _MobileTab { files, editor, terminal, preview }

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  _MobileTab _mobileTab = _MobileTab.files;
  double _treeWidth = 260;
  double _terminalHeight = 240;
  double _previewWidth = 440;
  bool _terminalOpen = false;
  bool _previewOpen = false;

  Future<void> _open(String path) async {
    final c = ref.read(projectControllerProvider(widget.projectId));
    final binaryMsg = AppLocalizations.of(context).binaryFile;
    try {
      await c.open(path);
      if (mounted) setState(() => _mobileTab = _MobileTab.editor);
    } on RunnerException catch (e) {
      _snack(e.code == 'binary' || e.code == 'too_large' ? binaryMsg : e.message);
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
      _snack(l.error(e.message));
    }
  }

  void _toggleTerminal() {
    final t = ref.read(terminalsControllerProvider(widget.projectId));
    setState(() {
      _terminalOpen = !_terminalOpen;
      _mobileTab = _MobileTab.terminal;
    });
    if (_terminalOpen && t.sessions.isEmpty) t.open();
  }

  void _runWeb() {
    setState(() {
      _previewOpen = true;
      _mobileTab = _MobileTab.preview;
    });
    ref.read(previewControllerProvider(widget.projectId)).run();
  }

  void _snack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.backquote, control: true): _toggleTerminal,
        const SingleActivator(LogicalKeyboardKey.f5): _runWeb,
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= WorkspaceScreen.wideBreakpoint;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/projects')),
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
                    isSelected: _previewOpen,
                    icon: const Icon(Icons.phone_iphone),
                    onPressed: () => setState(() => _previewOpen = !_previewOpen),
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
                        onDrag: (d) => setState(() => _treeWidth = (_treeWidth + d).clamp(180, constraints.maxWidth * 0.4)),
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
                      if (_previewOpen) ...[
                        _Splitter.vertical(
                          onDrag: (d) => setState(() => _previewWidth = (_previewWidth - d).clamp(320, constraints.maxWidth * 0.6)),
                        ),
                        SizedBox(width: _previewWidth, child: previewPanel),
                      ],
                    ],
                  )
                : IndexedStack(
                    index: _mobileTab.index,
                    children: [tree, editor, terminalPanel, previewPanel],
                  ),
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: _mobileTab.index,
                    onDestinationSelected: (i) {
                      setState(() => _mobileTab = _MobileTab.values[i]);
                      if (_MobileTab.values[i] == _MobileTab.terminal && terminals.sessions.isEmpty) terminals.open();
                    },
                    destinations: [
                      NavigationDestination(icon: const Icon(Icons.folder_outlined), label: l.files),
                      NavigationDestination(icon: const Icon(Icons.code), label: l.editor),
                      NavigationDestination(icon: const Icon(Icons.terminal), label: l.terminal),
                      NavigationDestination(icon: const Icon(Icons.phone_iphone), label: l.preview),
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
        child: vertical ? const VerticalDivider(width: 6, thickness: 1) : const Divider(height: 6, thickness: 1),
      ),
    );
  }
}
