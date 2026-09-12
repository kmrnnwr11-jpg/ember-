import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/connection_badge.dart';
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

final _projectProvider = FutureProvider.autoDispose.family<Project, String>((ref, id) async {
  final api = await ref.watch(runnerApiProvider.future);
  return api.project(id);
});

/// Responsive IDE shell: side-by-side panels on wide screens, tabs on phones.
class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key, required this.projectId});

  final String projectId;

  static const wideBreakpoint = 840.0;

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  int _mobileTab = 0;
  double _treeWidth = 280;

  Future<void> _open(String path) async {
    final c = ref.read(projectControllerProvider(widget.projectId));
    final binaryMsg = AppLocalizations.of(context).binaryFile;
    try {
      await c.open(path);
      if (mounted) setState(() => _mobileTab = 1);
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

  void _snack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = ref.watch(projectControllerProvider(widget.projectId));
    final project = ref.watch(_projectProvider(widget.projectId));
    final tree = FileTree(controller: controller, onOpen: _open);
    final editor = EditorPane(controller: controller, onSave: _save);

    return LayoutBuilder(
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
              const ConnectionBadge(),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    SizedBox(width: _treeWidth, child: tree),
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (d) =>
                            setState(() => _treeWidth = (_treeWidth + d.delta.dx).clamp(180, constraints.maxWidth * 0.5)),
                        child: const VerticalDivider(width: 6, thickness: 1),
                      ),
                    ),
                    Expanded(child: editor),
                  ],
                )
              : IndexedStack(index: _mobileTab, children: [tree, editor]),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _mobileTab,
                  onDestinationSelected: (i) => setState(() => _mobileTab = i),
                  destinations: [
                    NavigationDestination(icon: const Icon(Icons.folder_outlined), label: l.files),
                    NavigationDestination(icon: const Icon(Icons.code), label: l.editor),
                  ],
                ),
        );
      },
    );
  }
}
