import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../store/play_links.dart';

/// Play Console App content: Ember's answer for each of Google's questions,
/// ready to copy. The rows Ember can send by itself are marked.
class AppContentCard extends ConsumerStatefulWidget {
  const AppContentCard({super.key, required this.projectId, required this.appName});
  final String projectId;
  final String appName;

  @override
  ConsumerState<AppContentCard> createState() => _AppContentCardState();
}

class _AppContentCardState extends ConsumerState<AppContentCard> {
  List<Map<String, dynamic>> _items = const [];
  Map<String, dynamic> _facts = const {};
  String? _copied;
  bool _busy = false;
  String? _message;
  bool _error = false;
  bool _askLink = false;
  final _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  /// Saves the Play Console address of this app, so Ember opens the right one.
  Future<void> _saveLink(String url) async {
    final l = AppLocalizations.of(context);
    final parsed = PlayConsoleLink.parse(url);
    if (parsed == null || parsed.appId == null) {
      setState(() {
        _message = l.acLinkNotUnderstood;
        _error = true;
      });
      return;
    }
    await parsed.merge(await PlayConsoleLink.load()).save();
    if (!mounted) return;
    setState(() {
      _askLink = false;
      _message = null;
      _error = false;
      _link.clear();
    });
    await _fillInConsole();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await (await ref.read(runnerApiProvider.future)).appContent(widget.projectId);
      final items = (data['items'] as List? ?? const []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _items = items;
          _facts = {...?(data['facts'] as Map?)?.cast<String, dynamic>(), 'email': data['email'] ?? ''};
        });
      }
    } catch (_) {}
  }

  Future<void> _copy(Map<String, dynamic> item) async {
    await Clipboard.setData(ClipboardData(text: '${item['answer']}'));
    if (mounted) setState(() => _copied = '${item['id']}');
  }

  /// Hands the browser helper the facts it needs, and the clipboard as a fallback.
  Future<void> _copyForExtension() async {
    final app = <String, dynamic>{'name': widget.appName, ..._facts};
    await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(app)));
    try {
      await (await ref.read(runnerApiProvider.future)).sendToHelper(widget.projectId);
    } on RunnerException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _error = true;
        });
      }
      return;
    }
    if (mounted) setState(() => _copied = '_extension');
  }

  Future<void> _openConsole() async {
    final link = await PlayConsoleLink.load();
    await link.open(link.appContent);
  }

  /// Ember opens Play Console in a Chrome window and answers the questions itself.
  Future<void> _fillInConsole() async {
    final l = AppLocalizations.of(context);
    final link = await PlayConsoleLink.load();
    if (!mounted) return;
    if (link.developerId == null || link.appId == null) {
      setState(() {
        _message = l.acNeedsAppLink;
        _error = true;
        _askLink = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = l.acFilling;
      _error = false;
    });
    try {
      final res = await (await ref.read(runnerApiProvider.future)).fillPlayAppContent(
        widget.projectId,
        developerId: link.developerId!,
        appId: link.appId!,
        userIndex: link.userIndex,
      );
      final rows = (res['results'] as List? ?? const []).cast<Map<String, dynamic>>();
      final done = rows.where((r) => r['saved'] == true).length;
      setState(() {
        _message = '${l.acFilled(done, rows.length)}\n${rows.map((r) => '${r['saved'] == true ? '[ok]' : '[--]'} ${r['row']} (${r['answered']})').join('\n')}';
        _error = false;
      });
    } on RunnerException catch (e) {
      setState(() {
        _message = e.message;
        _error = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_items.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [const Icon(Icons.fact_check_outlined), const SizedBox(width: 8), Expanded(child: Text(l.acTitle, style: theme.textTheme.titleMedium))]),
            const SizedBox(height: 4),
            Text(l.acHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            // The one button that starts the browser helper: at the top, where it is found.
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _copyForExtension,
                icon: Icon(_copied == '_extension' ? Icons.check : Icons.extension_outlined, size: 18),
                label: Text(_copied == '_extension' ? l.acCopied : l.acCopyForExtension),
              ),
            ),
            const SizedBox(height: 12),
            for (final item in _items) _row(context, l, item),
            const SizedBox(height: 12),
            if (_busy) ...[
              Row(children: [const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Expanded(child: Text(l.acFilling))]),
              const SizedBox(height: 8),
            ],
            if (_message != null) ...[
              SelectableText(_message!, style: TextStyle(color: _error ? theme.colorScheme.error : null)),
              const SizedBox(height: 8),
            ],
            if (_askLink) ...[
              TextField(
                controller: _link,
                decoration: InputDecoration(
                  labelText: l.acAppLink,
                  hintText: 'https://play.google.com/console/u/0/developers/…/app/…/app-dashboard',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l.paste,
                        icon: const Icon(Icons.content_paste),
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) _link.text = data!.text!.trim();
                        },
                      ),
                      IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => _saveLink(_link.text.trim())),
                    ],
                  ),
                ),
                onSubmitted: _saveLink,
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _fillInConsole,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(l.acFillForMe),
                ),
                OutlinedButton.icon(onPressed: _openConsole, icon: const Icon(Icons.open_in_new), label: Text(l.acOpenConsole)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AppLocalizations l, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final auto = item['automatic'] == true;
    final answer = '${item['answer']}';
    final copied = _copied == '${item['id']}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(auto ? Icons.auto_awesome : Icons.check_circle_outline, size: 16, color: auto ? theme.colorScheme.primary : Colors.greenAccent),
              const SizedBox(width: 6),
              Expanded(child: Text('${item['title']}', style: theme.textTheme.titleSmall)),
              if (auto) Text(l.acAuto, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (answer.isNotEmpty) SelectableText(answer),
                Text('${item['detail']}', style: theme.textTheme.bodySmall),
                if (!auto && answer.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _copy(item),
                    icon: Icon(copied ? Icons.check : Icons.copy, size: 16),
                    label: Text(copied ? l.acCopied : l.acCopy),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
