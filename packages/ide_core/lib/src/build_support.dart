import 'dart:math';

import 'package:meta/meta.dart';

import 'paths.dart';

@immutable
class AnalyzerIssue {
  const AnalyzerIssue({required this.severity, required this.message, this.path, this.line, this.column, this.code});

  /// `error` | `warning` | `info`.
  final String severity;
  final String message;
  final String? path;
  final int? line;
  final int? column;
  final String? code;

  @override
  String toString() => '${path ?? '?'}:${line ?? 0}:${column ?? 0} $severity: $message${code == null ? '' : ' ($code)'}';
}

abstract final class BuildSupport {
  // flutter analyze:  "  error • Undefined name 'x' • lib/main.dart:3:5 • undefined_identifier"
  static final _flutterFmt = RegExp(r'^\s*(error|warning|info)\s+•\s+(.+?)\s+•\s+(\S+?):(\d+):(\d+)\s+•\s+(\S+)\s*$');
  // dart analyze:     "  error - lib\main.dart:3:5 - Undefined name 'x'. - undefined_identifier"
  static final _dartFmt = RegExp(r'^\s*(error|warning|info)\s+-\s+(\S+?):(\d+):(\d+)\s+-\s+(.+?)\s+-\s+(\S+)\s*$');

  /// Parses analyzer output (flutter or dart format).
  static List<AnalyzerIssue> parseAnalyzer(String log) {
    final out = <AnalyzerIssue>[];
    for (final raw in log.split(RegExp(r'\r?\n'))) {
      final f = _flutterFmt.firstMatch(raw);
      if (f != null) {
        out.add(AnalyzerIssue(
          severity: f.group(1)!,
          message: f.group(2)!,
          path: f.group(3)!.replaceAll(r'\', '/'),
          line: int.parse(f.group(4)!),
          column: int.parse(f.group(5)!),
          code: f.group(6),
        ));
        continue;
      }
      final d = _dartFmt.firstMatch(raw);
      if (d != null) {
        out.add(AnalyzerIssue(
          severity: d.group(1)!,
          path: d.group(2)!.replaceAll(r'\', '/'),
          line: int.parse(d.group(3)!),
          column: int.parse(d.group(4)!),
          message: d.group(5)!,
          code: d.group(6),
        ));
      }
    }
    return out;
  }

  static List<AnalyzerIssue> errorsOnly(String log) => parseAnalyzer(log).where((i) => i.severity == 'error').toList();

  /// Derives a valid Dart package name from a free-text app description,
  /// e.g. "Crea un'app di ricette con foto" → `app_ricette_foto_482`.
  static String projectNameFromPrompt(String prompt, {Random? random}) {
    const stop = {
      'un', 'una', 'uno', 'il', 'lo', 'la', 'le', 'gli', 'i', 'di', 'da', 'del', 'della', 'per', 'con', 'che', 'e', 'a',
      'in', 'su', 'mi', 'fammi', 'crea', 'creare', 'voglio', 'vorrei', 'fai', 'fare', 'completa', 'completo', 'nuova',
      'the', 'an', 'of', 'for', 'with', 'and', 'to', 'make', 'create', 'build', 'me', 'my', 'please',
    };
    const accents = {'à': 'a', 'á': 'a', 'è': 'e', 'é': 'e', 'ì': 'i', 'í': 'i', 'ò': 'o', 'ó': 'o', 'ù': 'u', 'ú': 'u'};
    var s = prompt.toLowerCase();
    accents.forEach((k, v) => s = s.replaceAll(k, v));
    final words = s
        .replaceAll(RegExp(r"[^a-z0-9\s]"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !stop.contains(w))
        .take(3)
        .toList();
    var base = words.join('_');
    if (base.isEmpty || !RegExp(r'^[a-z]').hasMatch(base)) base = 'app${base.isEmpty ? '' : '_$base'}';
    if (base.length > 40) base = base.substring(0, 40).replaceAll(RegExp(r'_+$'), '');
    final suffix = (random ?? Random()).nextInt(900) + 100;
    return '${base}_$suffix';
  }

  /// Paths an AI build may write. Keeps generated code out of platform
  /// folders, build output and anything outside the project.
  static bool isWritableByAi(String path) {
    final String p;
    try {
      p = ProjectPath.normalize(path);
    } on ArgumentError {
      return false;
    }
    if (p == 'pubspec.yaml' || p == 'analysis_options.yaml' || p == 'README.md' || p == 'l10n.yaml') return true;
    return p.startsWith('lib/') || p.startsWith('test/') || p.startsWith('assets/') || p == 'web/index.html' || p == 'web/manifest.json';
  }

  /// Keeps the project's package name in an AI-written pubspec (imports
  /// like `package:<name>/...` and the Runner's project record depend on it).
  static String enforcePackageName(String pubspec, String name) {
    final re = RegExp(r'^name:\s*\S+\s*$', multiLine: true);
    return re.hasMatch(pubspec) ? pubspec.replaceFirst(re, 'name: $name') : 'name: $name\n$pubspec';
  }
}
