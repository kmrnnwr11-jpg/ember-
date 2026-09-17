import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../store/play_links.dart';

/// Play Console → App content: Ember's answer for each of Google's questions,
/// ready to copy. The rows Ember can send by itself are marked.
class AppContentCard extends ConsumerStatefulWidget {
  const AppContentCard({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<AppContentCard> createState() => _AppContentCardState();
}

class _AppContentCardState extends ConsumerState<AppContentCard> {
  List<Map<String, dynamic>> _items = const [];
  String? _copied;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await (await ref.read(runnerApiProvider.future)).appContent(widget.projectId);
      final items = (data['items'] as List? ?? const []).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _items = items);
    } catch (_) {}
  }

  Future<void> _copy(Map<String, dynamic> item) async {
    await Clipboard.setData(ClipboardData(text: '${item['answer']}'));
    if (mounted) setState(() => _copied = '${item['id']}');
  }

  Future<void> _openConsole() async {
    final link = await PlayConsoleLink.load();
    await link.open(link.appList());
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
            const SizedBox(height: 12),
            for (final item in _items) _row(context, l, item),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _openConsole, icon: const Icon(Icons.open_in_new), label: Text(l.acOpenConsole)),
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
