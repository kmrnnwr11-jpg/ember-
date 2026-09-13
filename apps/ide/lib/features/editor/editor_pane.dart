import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ide_core/ide_core.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import '../../l10n/app_localizations.dart';
import 'project_controller.dart';

final _languages = {
  'dart': CodeHighlightThemeMode(mode: langDart),
  'yaml': CodeHighlightThemeMode(mode: langYaml),
  'json': CodeHighlightThemeMode(mode: langJson),
  'html': CodeHighlightThemeMode(mode: langXml),
  'markdown': CodeHighlightThemeMode(mode: langMarkdown),
};

class EditorPane extends StatelessWidget {
  const EditorPane({super.key, required this.controller, required this.onSave});

  final ProjectController controller;
  final ValueChanged<OpenFile> onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final file = controller.activeFile;
        return Column(
          children: [
            if (controller.tabs.isNotEmpty) _TabBar(controller: controller),
            Expanded(
              child: file == null
                  ? Center(child: Text(l.noFileOpen))
                  : _Editor(key: ObjectKey(file), file: file, onSave: () => onSave(file)),
            ),
          ],
        );
      },
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});

  final ProjectController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.tabs.length,
          itemBuilder: (context, i) {
            final t = controller.tabs[i];
            final selected = i == controller.active;
            return InkWell(
              onTap: () => controller.activate(i),
              child: Container(
                padding: const EdgeInsets.only(left: 12, right: 4),
                decoration: BoxDecoration(
                  color: selected ? scheme.surface : null,
                  border: Border(bottom: BorderSide(color: selected ? scheme.primary : Colors.transparent, width: 2)),
                ),
                child: Row(
                  children: [
                    Text(t.name),
                    const SizedBox(width: 4),
                    if (t.saving)
                      const SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                    else if (t.dirty)
                      Icon(Icons.circle, size: 8, color: scheme.primary),
                    IconButton(
                      iconSize: 14,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close),
                      onPressed: () => _close(context, i),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _close(BuildContext context, int i) async {
    final t = controller.tabs[i];
    if (t.dirty) {
      final l = AppLocalizations.of(context);
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l.unsavedChanges),
          content: Text(t.path),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.discard)),
          ],
        ),
      );
      if (discard != true) return;
    }
    controller.close(controller.tabs.indexOf(t));
  }
}

class _Editor extends StatefulWidget {
  const _Editor({super.key, required this.file, required this.onSave});

  final OpenFile file;
  final VoidCallback onSave;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final _find = CodeFindController(widget.file.controller);

  @override
  void dispose() {
    _find.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lang = ProjectPath.languageOf(widget.file.path);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): widget.onSave,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): widget.onSave,
      },
      child: CodeEditor(
        controller: widget.file.controller,
        findController: _find,
        wordWrap: false,
        style: CodeEditorStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          codeTheme: CodeHighlightTheme(
            languages: {if (_languages[lang] != null) lang: _languages[lang]!},
            theme: dark ? atomOneDarkTheme : atomOneLightTheme,
          ),
        ),
        indicatorBuilder: (context, editing, chunk, notifier) => Row(
          children: [
            DefaultCodeLineNumber(controller: editing, notifier: notifier),
            DefaultCodeChunkIndicator(width: 18, controller: chunk, notifier: notifier),
          ],
        ),
        findBuilder: (context, controller, readOnly) => _FindBar(controller: controller),
        sperator: Container(width: 1, color: Theme.of(context).dividerColor),
      ),
    );
  }
}

class _FindBar extends StatelessWidget implements PreferredSizeWidget {
  const _FindBar({required this.controller});

  final CodeFindController controller;

  @override
  Size get preferredSize => Size.fromHeight(controller.value == null ? 0 : (controller.value!.replaceMode ? 88 : 44));

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    if (value == null) return const SizedBox.shrink();
    final result = value.result;
    final l = AppLocalizations.of(context);
    final count = result == null ? '0/0' : '${result.index + 1}/${result.matches.length}';
    return Material(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.findInputController,
                    focusNode: controller.findInputFocusNode,
                    decoration: InputDecoration(isDense: true, hintText: l.find, border: InputBorder.none),
                  ),
                ),
                Text(count),
                IconButton(iconSize: 18, icon: const Icon(Icons.arrow_upward), onPressed: controller.previousMatch),
                IconButton(iconSize: 18, icon: const Icon(Icons.arrow_downward), onPressed: controller.nextMatch),
                IconButton(iconSize: 18, icon: const Icon(Icons.find_replace), onPressed: controller.toggleMode),
                IconButton(iconSize: 18, icon: const Icon(Icons.close), onPressed: controller.close),
              ],
            ),
            if (value.replaceMode)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.replaceInputController,
                      focusNode: controller.replaceInputFocusNode,
                      decoration: InputDecoration(isDense: true, hintText: l.replace, border: InputBorder.none),
                    ),
                  ),
                  TextButton(onPressed: controller.replaceMatch, child: Text(l.replace)),
                  TextButton(onPressed: controller.replaceAllMatches, child: Text(l.replaceAll)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
