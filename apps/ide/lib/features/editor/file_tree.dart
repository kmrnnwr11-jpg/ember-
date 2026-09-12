import 'package:flutter/material.dart';
import 'package:ide_core/ide_core.dart';

import '../../l10n/app_localizations.dart';
import 'project_controller.dart';

enum _Action { newFile, newFolder, rename, delete }

class FileTree extends StatelessWidget {
  const FileTree({super.key, required this.controller, required this.onOpen});

  final ProjectController controller;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final rows = <Widget>[];
        void addDir(String dir, int depth) {
          for (final e in controller.children[dir] ?? const <FsEntry>[]) {
            rows.add(_row(context, e, depth));
            if (e.isDir && controller.expanded.contains(e.path)) {
              if (controller.children.containsKey(e.path)) {
                addDir(e.path, depth + 1);
              } else {
                rows.add(Padding(
                  padding: EdgeInsets.only(left: 28.0 + depth * 14, top: 4, bottom: 4),
                  child: const SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                ));
              }
            }
          }
        }

        addDir('', 0);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              child: Row(
                children: [
                  Expanded(child: Text(l.files.toUpperCase(), style: Theme.of(context).textTheme.labelSmall)),
                  IconButton(
                    tooltip: l.newFile,
                    iconSize: 18,
                    icon: const Icon(Icons.note_add_outlined),
                    onPressed: () => _prompt(context, l.newFile, '', (n) => controller.createFile('', n)),
                  ),
                  IconButton(
                    tooltip: l.newFolder,
                    iconSize: 18,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    onPressed: () => _prompt(context, l.newFolder, '', (n) => controller.createFolder('', n)),
                  ),
                  IconButton(
                    tooltip: l.reload,
                    iconSize: 18,
                    icon: const Icon(Icons.refresh),
                    onPressed: () => controller.loadDir(''),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: controller.children.containsKey('')
                  ? ListView(children: rows)
                  : controller.error != null
                  ? Center(child: Text(l.error(controller.error.toString())))
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, FsEntry e, int depth) {
    final open = controller.expanded.contains(e.path);
    final isActive = controller.activeFile?.path == e.path;
    return InkWell(
      key: ValueKey('tree:${e.path}'),
      onTap: () => e.isDir ? controller.toggleDir(e.path) : onOpen(e.path),
      onLongPress: () => _menu(context, e, null),
      onSecondaryTapUp: (d) => _menu(context, e, d.globalPosition),
      child: Container(
        color: isActive ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : null,
        padding: EdgeInsets.only(left: 8.0 + depth * 14, top: 6, bottom: 6, right: 8),
        child: Row(
          children: [
            Icon(
              e.isDir ? (open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right) : Icons.description_outlined,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(e.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, FsEntry e, Offset? at) async {
    final l = AppLocalizations.of(context);
    final items = [
      if (e.isDir) PopupMenuItem(value: _Action.newFile, child: Text(l.newFile)),
      if (e.isDir) PopupMenuItem(value: _Action.newFolder, child: Text(l.newFolder)),
      PopupMenuItem(value: _Action.rename, child: Text(l.rename)),
      PopupMenuItem(value: _Action.delete, child: Text(l.delete)),
    ];
    final box = context.findRenderObject() as RenderBox;
    final pos = at ?? box.localToGlobal(box.size.center(Offset.zero));
    final action = await showMenu<_Action>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      items: items,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _Action.newFile:
        await _prompt(context, l.newFile, '', (n) => controller.createFile(e.path, n));
      case _Action.newFolder:
        await _prompt(context, l.newFolder, '', (n) => controller.createFolder(e.path, n));
      case _Action.rename:
        await _prompt(context, l.rename, e.name, (n) => controller.rename(e, n));
      case _Action.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            content: Text(l.deleteConfirm(e.path)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
            ],
          ),
        );
        if (ok == true && context.mounted) await _guard(context, () => controller.delete(e));
    }
  }

  static Future<void> _prompt(BuildContext context, String title, String initial, Future<void> Function(String) run) async {
    final l = AppLocalizations.of(context);
    final text = TextEditingController(text: initial);
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: text,
          autofocus: true,
          decoration: InputDecoration(labelText: l.fileName),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, text.text), child: Text(l.create)),
        ],
      ),
    );
    text.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.contains('/') || trimmed.contains(r'\') || !context.mounted) return;
    await _guard(context, () => run(trimmed));
  }

  static Future<void> _guard(BuildContext context, Future<void> Function() fn) async {
    try {
      await fn();
    } on RunnerException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).error(e.message))));
      }
    }
  }
}
