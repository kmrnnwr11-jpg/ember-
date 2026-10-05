import 'package:flutter/material.dart';
import 'package:ide_core/ide_core.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';

/// Shows the line diff between the current file and the AI proposal.
/// Returns true when the user accepts.
Future<bool> showApplyDiff(BuildContext context, {required String path, required String oldText, required String newText}) async {
  final l = AppLocalizations.of(context);
  final lines = LineDiff.compute(oldText, newText);
  final hunks = LineDiff.hunks(lines);
  final added = lines.where((x) => x.kind == DiffKind.added).length;
  final removed = lines.where((x) => x.kind == DiffKind.removed).length;
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(l.applyTo(path)),
      content: SizedBox(
        width: Widths.page,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('+$added  −$removed', style: kMono),
            Gap.vSm,
            Expanded(
              child: hunks.isEmpty
                  ? Center(child: Text(l.noChanges))
                  : LogSurface(
                      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                      child: ListView(
                        children: [
                          for (final h in hunks) ...[
                            for (final line in h.lines) _DiffRow(line: line),
                            Divider(height: Gap.md, color: d.ember.codeMuted.withValues(alpha: 0.4)),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.reject)),
        FilledButton(onPressed: hunks.isEmpty ? null : () => Navigator.pop(d, true), child: Text(l.accept)),
      ],
    ),
  );
  return ok ?? false;
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({required this.line});
  final DiffLine line;

  @override
  Widget build(BuildContext context) {
    // Tints over the always-dark code surface.
    final (bg, sign) = switch (line.kind) {
      DiffKind.added => (context.ember.success.withValues(alpha: 0.2), '+'),
      DiffKind.removed => (context.scheme.error.withValues(alpha: 0.2), '-'),
      DiffKind.same => (Colors.transparent, ' '),
    };
    final num = (line.kind == DiffKind.added ? line.newLine : line.oldLine)?.toString() ?? '';
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
      child: Text(
        '${num.padLeft(4)} $sign ${line.text}',
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
    );
  }
}
