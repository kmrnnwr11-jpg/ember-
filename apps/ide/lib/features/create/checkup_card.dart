import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'app_builder.dart';

/// What Ember found wrong when the app was opened, and the offer to fix it.
///
/// Ember never repairs anything on its own: it says what is broken, what that
/// costs the user, and waits for a yes. The things it cannot fix alone are
/// listed too, because knowing about them is worth more than hiding them.
class CheckupCard extends ConsumerStatefulWidget {
  const CheckupCard({super.key, required this.projectId, required this.builder, this.previewUrl, this.onlyProblems = false});
  final String projectId;

  /// Stay out of the way when the check found nothing (the app's home); the
  /// checks page shows the "all good" too.
  final bool onlyProblems;

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
    if (_findings.isEmpty && !_done && _message == null) return const SizedBox.shrink();
    if (widget.onlyProblems && _findings.isEmpty) return const SizedBox.shrink();
    final fixable = _findings.where((f) => f['fixable'] == true).length;

    return SectionCard(
      icon: _findings.isEmpty ? Icons.verified_outlined : Icons.report_problem_outlined,
      title: l.checkTitle,
      hint: _findings.isEmpty ? l.checkAllGood : l.checkFound(_findings.length),
      tone: _findings.isEmpty ? Tone.neutral : Tone.error,
      trailing: IconButton(tooltip: l.checkAgain, icon: const Icon(Icons.refresh, size: 20), onPressed: _busy ? null : _check),
      children: [
        for (final f in _findings) ...[
          Gap.vMd,
          FindingTile(
            title: '${f['title']}',
            detail: '${f['detail']}',
            fixable: f['fixable'] == true,
            action: '${f['ask'] ?? ''}'.isNotEmpty
                ? TextButton.icon(
                    onPressed: widget.builder.running
                        ? null
                        : () {
                            widget.builder.improve('${f['ask']}', display: '${f['title']}');
                            setState(() => _message = l.checkAsked);
                          },
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                    label: Text(l.checkAskEmber),
                  )
                : null,
          ),
        ],
        if (_busy) ...[
          Gap.vMd,
          BusyRow(l.checkFixing),
        ],
        if (_message != null) ...[
          Gap.vMd,
          InlineMessage(_message!, error: _error),
        ],
        if (fixable > 0) ...[
          Gap.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: _busy ? null : _fix,
              icon: const Icon(Icons.build_outlined),
              label: Text(l.checkFixNow(fixable)),
            ),
          ),
        ],
      ],
    );
  }
}
