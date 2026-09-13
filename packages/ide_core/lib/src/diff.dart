import 'package:meta/meta.dart';

enum DiffKind { same, added, removed }

@immutable
class DiffLine {
  const DiffLine(this.kind, this.text, {this.oldLine, this.newLine});

  final DiffKind kind;
  final String text;

  /// 1-based line numbers in the old/new text (null when not applicable).
  final int? oldLine;
  final int? newLine;

  @override
  String toString() => '${switch (kind) { DiffKind.same => ' ', DiffKind.added => '+', DiffKind.removed => '-' }}$text';
}

/// A contiguous block of changes with surrounding context.
@immutable
class DiffHunk {
  const DiffHunk(this.lines);
  final List<DiffLine> lines;

  int get added => lines.where((l) => l.kind == DiffKind.added).length;
  int get removed => lines.where((l) => l.kind == DiffKind.removed).length;
}

/// Line-based diff (LCS over lines after trimming common prefix/suffix).
abstract final class LineDiff {
  /// Above this many cells the LCS table is skipped and the changed middle
  /// is reported as a whole-block replacement.
  static const maxCells = 4000000;

  static List<String> splitLines(String s) => s.isEmpty ? const [] : s.replaceAll('\r\n', '\n').split('\n');

  static List<DiffLine> compute(String oldText, String newText) {
    final a = splitLines(oldText);
    final b = splitLines(newText);
    var start = 0;
    while (start < a.length && start < b.length && a[start] == b[start]) {
      start++;
    }
    var endA = a.length, endB = b.length;
    while (endA > start && endB > start && a[endA - 1] == b[endB - 1]) {
      endA--;
      endB--;
    }

    final out = <DiffLine>[];
    for (var i = 0; i < start; i++) {
      out.add(DiffLine(DiffKind.same, a[i], oldLine: i + 1, newLine: i + 1));
    }

    final n = endA - start, m = endB - start;
    if (n * m > maxCells) {
      for (var i = start; i < endA; i++) {
        out.add(DiffLine(DiffKind.removed, a[i], oldLine: i + 1));
      }
      for (var j = start; j < endB; j++) {
        out.add(DiffLine(DiffKind.added, b[j], newLine: j + 1));
      }
    } else if (n > 0 || m > 0) {
      // lcs[i][j] = LCS length of a[start+i..endA) and b[start+j..endB)
      final lcs = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
      for (var i = n - 1; i >= 0; i--) {
        for (var j = m - 1; j >= 0; j--) {
          lcs[i][j] = a[start + i] == b[start + j] ? lcs[i + 1][j + 1] + 1 : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
        }
      }
      var i = 0, j = 0;
      while (i < n || j < m) {
        if (i < n && j < m && a[start + i] == b[start + j]) {
          out.add(DiffLine(DiffKind.same, a[start + i], oldLine: start + i + 1, newLine: start + j + 1));
          i++;
          j++;
        } else if (i < n && (j >= m || lcs[i + 1][j] >= lcs[i][j + 1])) {
          // On ties emit removals first so replacements read "-old +new".
          out.add(DiffLine(DiffKind.removed, a[start + i], oldLine: start + i + 1));
          i++;
        } else {
          out.add(DiffLine(DiffKind.added, b[start + j], newLine: start + j + 1));
          j++;
        }
      }
    }

    for (var k = 0; k < a.length - endA; k++) {
      out.add(DiffLine(DiffKind.same, a[endA + k], oldLine: endA + k + 1, newLine: endB + k + 1));
    }
    return out;
  }

  /// Groups changes into hunks with [context] unchanged lines around them.
  static List<DiffHunk> hunks(List<DiffLine> lines, {int context = 3}) {
    final changed = [for (var i = 0; i < lines.length; i++) if (lines[i].kind != DiffKind.same) i];
    if (changed.isEmpty) return const [];
    final hunks = <DiffHunk>[];
    var from = (changed.first - context).clamp(0, lines.length);
    var to = (changed.first + context + 1).clamp(0, lines.length);
    for (final idx in changed.skip(1)) {
      if (idx - context <= to) {
        to = (idx + context + 1).clamp(0, lines.length);
      } else {
        hunks.add(DiffHunk(lines.sublist(from, to)));
        from = (idx - context).clamp(0, lines.length);
        to = (idx + context + 1).clamp(0, lines.length);
      }
    }
    hunks.add(DiffHunk(lines.sublist(from, to)));
    return hunks;
  }
}
