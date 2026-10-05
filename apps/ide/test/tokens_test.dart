import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The look of the app lives in lib/ui. A colour written by hand in a screen
/// is a colour that will not follow the theme (or the light/dark switch).
void main() {
  // The Ember mark is a drawing with its own colours.
  const artwork = {'lib/widgets/ember_logo.dart'};

  Iterable<File> sources() sync* {
    for (final dir in ['lib/features', 'lib/widgets', 'lib/core']) {
      yield* Directory(dir).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    }
    yield File('lib/main.dart');
    yield File('lib/router.dart');
  }

  String rel(File f) => f.path.replaceAll('\\', '/');

  test('no colour is written by hand outside lib/ui', () {
    final literal = RegExp(r'Color\(0x|Colors\.(?!transparent\b)\w+');
    final found = <String>[];
    for (final file in sources()) {
      if (artwork.contains(rel(file))) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (literal.hasMatch(lines[i])) found.add('${rel(file)}:${i + 1}');
      }
    }
    expect(found, isEmpty, reason: 'use context.scheme / context.ember instead');
  });

  test('no field draws its own border: the theme does', () {
    final found = <String>[];
    for (final file in sources()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('OutlineInputBorder(')) found.add('${rel(file)}:${i + 1}');
      }
    }
    expect(found, isEmpty);
  });

  test('screens stay small enough to read', () {
    final long = <String>[];
    for (final file in Directory('lib/features').listSync(recursive: true).whereType<File>()) {
      final name = rel(file);
      // Screens and cards; controllers and builders are logic and are not counted here.
      if (!RegExp(r'_(screen|card|panel|view|sheet|dialog)\.dart$').hasMatch(name)) continue;
      final lines = file.readAsLinesSync().length;
      if (lines > 500) long.add('$name ($lines lines)');
    }
    expect(long, isEmpty);
  });
}
