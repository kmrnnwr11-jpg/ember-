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
import '../../ui/ui.dart';
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
                  ? EmptyState(icon: Icons.description_outlined, text: l.noFileOpen, compact: true)
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
    final l = AppLocalizations.of(context);
    return TabStrip(
      selected: controller.active,
      onSelect: controller.activate,
      onClose: (i) => _close(context, i),
      closeTooltip: l.close,
      items: [
        for (final t in controller.tabs)
          TabStripItem(
            label: t.name,
            status: t.saving
                ? const SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                : t.dirty
                ? Icon(Icons.circle, size: 8, color: context.scheme.primary, semanticLabel: l.unsavedChanges)
                : null,
          ),
      ],
    );
  }

  Future<void> _close(BuildContext context, int i) async {
    final t = controller.tabs[i];
    if (t.dirty) {
      final l = AppLocalizations.of(context);
      final discard = await showConfirm(context, title: l.unsavedChanges, message: t.path, confirmLabel: l.discard, destructive: true);
      if (!discard) return;
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
    Widget button(String tooltip, IconData icon, VoidCallback onPressed) =>
        IconButton(tooltip: tooltip, iconSize: 18, constraints: const BoxConstraints(minWidth: 40, minHeight: 40), icon: Icon(icon), onPressed: onPressed);
    return Material(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
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
                button(l.findPrevious, Icons.arrow_upward, controller.previousMatch),
                button(l.findNext, Icons.arrow_downward, controller.nextMatch),
                button(l.toggleReplace, Icons.find_replace, controller.toggleMode),
                button(l.close, Icons.close, controller.close),
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
