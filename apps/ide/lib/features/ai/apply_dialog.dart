import 'package:flutter/material.dart';
import 'package:ide_core/ide_core.dart';

import '../../l10n/app_localizations.dart';

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
        width: 760,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('+$added  −$removed', style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Expanded(
              child: hunks.isEmpty
                  ? Center(child: Text(l.noChanges))
                  : Container(
                      color: const Color(0xFF1E1E1E),
                      child: ListView(
                        children: [
                          for (final h in hunks) ...[
                            for (final line in h.lines) _DiffRow(line: line),
                            const Divider(height: 12, color: Colors.white24),
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
    final (bg, sign) = switch (line.kind) {
      DiffKind.added => (const Color(0x3325A244), '+'),
      DiffKind.removed => (const Color(0x33E5484D), '-'),
      DiffKind.same => (Colors.transparent, ' '),
    };
    final num = (line.kind == DiffKind.added ? line.newLine : line.oldLine)?.toString() ?? '';
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '${num.padLeft(4)} $sign ${line.text}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70, height: 1.35),
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
    );
  }
}
