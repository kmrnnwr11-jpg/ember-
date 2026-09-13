import 'package:meta/meta.dart';

import 'paths.dart';

/// A piece of an AI message: prose (markdown) or a fenced code block.
@immutable
sealed class MessageSegment {
  const MessageSegment();
}

class TextSegment extends MessageSegment {
  const TextSegment(this.markdown);
  final String markdown;
}

class CodeSegment extends MessageSegment {
  const CodeSegment({required this.code, this.language, this.path, this.complete = true});

  final String code;
  final String? language;

  /// Project-relative target path from the info string (```dart lib/main.dart).
  final String? path;

  /// False while the closing fence has not streamed in yet.
  final bool complete;
}

/// Splits markdown into prose and fenced code blocks, keeping the full info
/// string (which markdown renderers discard) so "Apply" knows the target file.
abstract final class CodeBlocks {
  static final _fence = RegExp(r'^(\s*)(```+|~~~+)(.*)$');

  static List<MessageSegment> parse(String text) {
    final out = <MessageSegment>[];
    final prose = StringBuffer();
    final lines = text.split('\n');
    var i = 0;
    while (i < lines.length) {
      final m = _fence.firstMatch(lines[i]);
      if (m == null) {
        prose.writeln(lines[i]);
        i++;
        continue;
      }
      if (prose.toString().trim().isNotEmpty) out.add(TextSegment(prose.toString().trimRight()));
      prose.clear();
      final fence = m.group(2)!;
      final (language, path) = parseInfo(m.group(3)!);
      final code = <String>[];
      i++;
      var closed = false;
      while (i < lines.length) {
        final c = lines[i].trim();
        if (c.startsWith(fence) && c.replaceAll(fence[0], '').isEmpty) {
          closed = true;
          i++;
          break;
        }
        code.add(lines[i]);
        i++;
      }
      out.add(CodeSegment(code: code.join('\n'), language: language, path: path, complete: closed));
    }
    if (prose.toString().trim().isNotEmpty) out.add(TextSegment(prose.toString().trimRight()));
    return out;
  }

  /// `dart lib/main.dart`, `dart:lib/main.dart`, `lib/main.dart`, `dart title="lib/a.dart"`.
  static (String?, String?) parseInfo(String info) {
    var s = info.trim();
    if (s.isEmpty) return (null, null);
    final titled = RegExp(r'''(?:title|file|path)=["']?([^"'\s]+)''').firstMatch(s);
    String? path = titled?.group(1);
    if (titled != null) s = s.replaceFirst(titled.group(0)!, '').trim();
    final parts = s.split(RegExp(r'[\s:]+')).where((p) => p.isNotEmpty).toList();
    String? language;
    for (final p in parts) {
      if (path == null && (p.contains('/') || RegExp(r'\.\w{1,6}$').hasMatch(p))) {
        path = p;
      } else {
        language ??= p.toLowerCase();
      }
    }
    if (path != null) {
      try {
        path = ProjectPath.normalize(path);
        if (path.isEmpty) path = null;
      } on ArgumentError {
        path = null;
      }
    }
    language ??= path == null ? null : ProjectPath.languageOf(path);
    return (language, path);
  }
}
