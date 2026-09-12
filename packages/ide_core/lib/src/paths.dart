/// POSIX path helpers for project-relative paths. Mirrors the Runner's
/// confinement rules so the client rejects bad paths before sending them.
abstract final class ProjectPath {
  /// Normalizes [input] to a project-relative POSIX path without leading
  /// slash. Throws [ArgumentError] if it escapes the project root.
  static String normalize(String input) {
    final parts = <String>[];
    for (final seg in input.replaceAll('\\', '/').split('/')) {
      if (seg.isEmpty || seg == '.') continue;
      if (seg == '..') {
        if (parts.isEmpty) {
          throw ArgumentError.value(input, 'path', 'escapes project root');
        }
        parts.removeLast();
      } else {
        parts.add(seg);
      }
    }
    return parts.join('/');
  }

  static String basename(String path) {
    final n = normalize(path);
    final i = n.lastIndexOf('/');
    return i < 0 ? n : n.substring(i + 1);
  }

  static String dirname(String path) {
    final n = normalize(path);
    final i = n.lastIndexOf('/');
    return i < 0 ? '' : n.substring(0, i);
  }

  static String join(String a, String b) =>
      normalize(a.isEmpty ? b : '$a/$b');

  /// Editor language id from file extension.
  static String languageOf(String path) {
    final name = basename(path).toLowerCase();
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 ? '' : name.substring(dot + 1);
    return switch (ext) {
      'dart' => 'dart',
      'yaml' || 'yml' => 'yaml',
      'json' || 'arb' => 'json',
      'html' || 'htm' => 'html',
      'md' || 'markdown' => 'markdown',
      _ => 'plaintext',
    };
  }
}
