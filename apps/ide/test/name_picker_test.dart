import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/mockups/name_picker.dart';

void main() {
  test('reads the names even when the model wraps them in chatter', () async {
    final names = await suggestNames(
      (_, _) async => (text: 'Here you go:\n```json\n["Impara & Gioca Kids", "Boschetto Impara", "Piccoli Geni"]\n```', costUsd: 0.0),
      'app educativa per bambini',
    );
    expect(names, ['Impara & Gioca Kids', 'Boschetto Impara', 'Piccoli Geni']);
  });

  test('gives nothing rather than nonsense when the model does not answer', () async {
    expect(await suggestNames((_, _) async => (text: 'I cannot help with that', costUsd: null), 'x'), isEmpty);
    // A name longer than a store allows is dropped, not trimmed into gibberish.
    final long = 'x' * 40;
    expect(await suggestNames((_, _) async => (text: '["Ok", "$long"]', costUsd: null), 'x'), ['Ok']);
  });
}
