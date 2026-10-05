import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every language says everything: a key missing from one file would show
/// English in the middle of an Arabic or Spanish screen.
void main() {
  const languages = ['en', 'it', 'es', 'fr', 'ar'];
  Map<String, dynamic> load(String code) => jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync()) as Map<String, dynamic>;
  Set<String> keysOf(Map<String, dynamic> arb) => {
    for (final k in arb.keys)
      if (!k.startsWith('@')) k,
  };
  Set<String> placeholders(String text) => {for (final m in RegExp(r'\{(\w+)\}').allMatches(text)) m.group(1)!};

  final english = load('en');

  for (final code in languages.skip(1)) {
    test('$code has every string English has, and no stray ones', () {
      final other = keysOf(load(code));
      expect(keysOf(english).difference(other), isEmpty, reason: 'missing in app_$code.arb');
      expect(other.difference(keysOf(english)), isEmpty, reason: 'only in app_$code.arb');
    });

    test('$code keeps the placeholders of each string', () {
      final other = load(code);
      final wrong = <String>[];
      for (final key in keysOf(english)) {
        final value = other[key];
        if (value is! String) continue;
        final expected = placeholders(english[key] as String);
        // ICU plurals and selects name their variable once and repeat words inside.
        if ((english[key] as String).contains(RegExp(r'\{\w+,\s*(plural|select)'))) continue;
        if (!placeholders(value).containsAll(expected)) wrong.add(key);
      }
      expect(wrong, isEmpty, reason: 'placeholders differ from English');
    });
  }

  test('no string is left empty', () {
    for (final code in languages) {
      final arb = load(code);
      final empty = [
        for (final k in keysOf(arb))
          if ((arb[k] as String).trim().isEmpty) k,
      ];
      expect(empty, isEmpty, reason: 'empty in app_$code.arb');
    }
  });
}
