import 'dart:math';

import 'package:ide_core/ide_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses flutter and dart analyzer output', () {
    const log = '''
Analyzing smoke...

  error • Undefined name 'foo' • lib/main.dart:12:7 • undefined_identifier
warning • Unused import • lib/a.dart:1:8 • unused_import
   info - lib\\b.dart:3:1 - Prefer const. - prefer_const_constructors
  error - lib\\c.dart:9:2 - Expected ';'. - expected_token

4 issues found.''';
    final issues = BuildSupport.parseAnalyzer(log);
    expect(issues.length, 4);
    expect(issues.first.toString(), "lib/main.dart:12:7 error: Undefined name 'foo' (undefined_identifier)");
    expect(issues[2].path, 'lib/b.dart');
    final errors = BuildSupport.errorsOnly(log);
    expect(errors.map((e) => e.path), ['lib/main.dart', 'lib/c.dart']);
    expect(BuildSupport.errorsOnly('No issues found!'), isEmpty);
  });

  test('project name from prompt is a valid Dart package name', () {
    final r = Random(1);
    final valid = RegExp(r'^[a-z][a-z0-9_]{0,63}$');
    for (final p in ["Crea un'app completa di makeup foto", 'Fammi un\'app per gestire le presenze', '123 !!!', '', 'Ricette è più facile']) {
      final name = BuildSupport.projectNameFromPrompt(p, random: r);
      expect(valid.hasMatch(name), isTrue, reason: name);
    }
    expect(BuildSupport.projectNameFromPrompt("Crea un'app completa di makeup foto", random: Random(2)), startsWith('app_makeup_foto_'));
  });

  test('AI write allowlist and package name enforcement', () {
    for (final ok in ['lib/main.dart', 'lib/src/a.dart', 'pubspec.yaml', 'test/widget_test.dart', 'assets/i.png', 'web/index.html']) {
      expect(BuildSupport.isWritableByAi(ok), isTrue, reason: ok);
    }
    for (final bad in ['android/app/build.gradle', '../x.dart', '.git/config', 'build/web/main.dart.js', 'ios/Runner/Info.plist']) {
      expect(BuildSupport.isWritableByAi(bad), isFalse, reason: bad);
    }
    expect(BuildSupport.enforcePackageName('name: ricette\ndescription: x', 'app_ricette_123'), 'name: app_ricette_123\ndescription: x');
    expect(BuildSupport.enforcePackageName('description: x', 'n'), 'name: n\ndescription: x');
  });
}
