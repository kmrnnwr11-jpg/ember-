import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/create/app_builder.dart';

/// The ten languages are a standing rule, not a per-app request: see
/// docs/LINGUE.md. This test is what keeps the rule from quietly going missing
/// the next time the build prompt is rewritten.
void main() {
  group('every app Ember builds speaks ten languages', () {
    test('names all ten, with English as the default', () {
      const block = AppBuilder.languagesBlock;
      for (final code in ['en', 'it', 'es', 'pt-BR', 'fr', 'de', 'hi', 'ar', 'id', 'ru']) {
        expect(block, contains('($code'), reason: '$code is one of the ten languages');
      }
      expect(block, contains('the default and the fallback'));
    });

    test('asks for real localisation, not strings left in the widgets', () {
      const block = AppBuilder.languagesBlock;
      expect(block, contains('flutter_localizations'));
      expect(block, contains('.arb'));
      expect(block, contains('No user-facing text is written inline in a widget'));
    });

    test('remembers that Arabic reads the other way', () {
      expect(AppBuilder.languagesBlock, contains('right to left'));
    });
  });
}
