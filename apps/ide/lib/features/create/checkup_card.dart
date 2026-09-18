import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import 'app_builder.dart';

/// What Ember found wrong when the app was opened, and the offer to fix it.
///
/// Ember never repairs anything on its own: it says what is broken, what that
/// costs the user, and waits for a yes. The things it cannot fix alone are
/// listed too, because knowing about them is worth more than hiding them.
class CheckupCard extends ConsumerStatefulWidget {
  const CheckupCard({super.key, required this.projectId, required this.builder, this.previewUrl});
  final String projectId;

  /// The engine that wrote the app: it is what fixes the findings made of code.
  final AppBuilder builder;

  /// Where the built app can be opened, so the check can watch it run.
  final String? previewUrl;

  @override
  ConsumerState<CheckupCard> createState() => _CheckupCardState();
}

class _CheckupCardState extends ConsumerState<CheckupCard> {
  List<Map<String, dynamic>> _findings = const [];
  bool _busy = false;
  bool _done = false;
  String? _message;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final res = await (await ref.read(runnerApiProvider.future)).checkApp(widget.projectId, previewUrl: widget.previewUrl);
      final found = (res['findings'] as List? ?? const []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _findings = found;
          _done = found.isEmpty;
        });
      }
    } catch (_) {
      // A check that cannot run must never get in the way of the app itself.
    }
  }

  Future<void> _fix() async {
    final fixable = _findings.where((f) => f['fixable'] == true).map((f) => '${f['id']}').toList();
    if (fixable.isEmpty) return;
    setState(() {
      _busy = true;
      _message = null;
      _error = false;
    });
    try {
      final res = await (await ref.read(runnerApiProvider.future)).fixApp(widget.projectId, fixable);
      final done = (res['done'] as List? ?? const []).cast<Map<String, dynamic>>();
      setState(() {
        _message = done.map((d) => '${d['ok'] == true ? '✓' : '✗'} ${d['message']}').join('\n');
        _error = done.any((d) => d['ok'] != true);
      });
      await _check();
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
    if (_findings.isEmpty && !_done && _message == null) return const SizedBox.shrink();
    final fixable = _findings.where((f) => f['fixable'] == true).length;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: _findings.isEmpty ? null : theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_findings.isEmpty ? Icons.verified_outlined : Icons.report_problem_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(l.checkTitle, style: theme.textTheme.titleMedium)),
                IconButton(tooltip: l.checkAgain, icon: const Icon(Icons.refresh, size: 20), onPressed: _busy ? null : _check),
              ],
            ),
            const SizedBox(height: 4),
            Text(_findings.isEmpty ? l.checkAllGood : l.checkFound(_findings.length), style: theme.textTheme.bodySmall),
            for (final f in _findings) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(f['fixable'] == true ? Icons.build_circle_outlined : Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${f['title']}', style: theme.textTheme.titleSmall),
                        Text('${f['detail']}', style: theme.textTheme.bodySmall),
                        if ('${f['ask'] ?? ''}'.isNotEmpty)
                          TextButton.icon(
                            onPressed: widget.builder.running
                                ? null
                                : () {
                                    widget.builder.improve('${f['ask']}', display: '${f['title']}');
                                    setState(() => _message = l.checkAsked);
                                  },
                            icon: const Icon(Icons.auto_fix_high, size: 16),
                            label: Text(l.checkAskEmber),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 12),
              Row(children: [const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Expanded(child: Text(l.checkFixing))]),
            ],
            if (_message != null) ...[
              const SizedBox(height: 10),
              SelectableText(_message!, style: TextStyle(color: _error ? theme.colorScheme.error : null)),
            ],
            if (fixable > 0) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _fix,
                  icon: const Icon(Icons.build),
                  label: Text(l.checkFixNow(fixable)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
