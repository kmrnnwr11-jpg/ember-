import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/review/panel_health.dart';
import 'package:ide/features/review/reviewers.dart' show PanelPing;

void main() {
  group('the user is told which models are down, by name', () {
    test('one model', () {
      expect(panelDownTitle(['Groq']), 'Groq non sta funzionando');
    });

    test('two models', () {
      expect(panelDownTitle(['Groq', 'Gemini']), 'Groq e Gemini non stanno funzionando');
    });

    test('three models: every name is said', () {
      expect(
        panelDownTitle(['Groq', 'Gemini', 'OpenRouter']),
        'Groq, Gemini e OpenRouter non stanno funzionando',
      );
    });

    test('nothing to say when they all answered', () {
      expect(panelDownTitle([]), isEmpty);
    });
  });

  group('what is left is stated plainly', () {
    test('two or more left: the panel still works', () {
      expect(panelDownExplanation(3), contains('Restano 3 AI'));
      expect(panelDownExplanation(2), contains('si controllano a vicenda'));
    });

    test('one left: nobody checks its work, and it says so', () {
      expect(panelDownExplanation(1), contains('nessuno controllerà'));
    });

    test('none left: the main engine draws, unchecked', () {
      expect(panelDownExplanation(0), contains('senza controlli'));
    });
  });

  /// Opens the real dialog and returns what the user's tap answered.
  Future<bool?> showIt(WidgetTester tester, List<PanelPing> down, int working) async {
    bool? answer;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showDialog<bool>(
                context: context,
                builder: (_) => PanelDownDialog(down: down, workingCount: working),
              );
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return answer;
  }

  const groq = (id: 'groq', label: 'Groq', ok: false, error: 'HTTP 403');
  const gemini = (id: 'gemini', label: 'Gemini', ok: false, error: 'quota finita');

  testWidgets('names both models and shows why each one failed', (tester) async {
    await showIt(tester, const [groq, gemini], 2);

    expect(find.text('Groq e Gemini non stanno funzionando'), findsOneWidget);
    expect(find.text('• Groq: HTTP 403'), findsOneWidget);
    expect(find.text('• Gemini: quota finita'), findsOneWidget);
    expect(find.textContaining('Restano 2 AI'), findsOneWidget);
  });

  testWidgets('Sì means go on', (tester) async {
    await showIt(tester, const [groq], 3);
    await tester.tap(find.text('Sì, procedi'));
    await tester.pumpAndSettle();

    expect(find.byType(PanelDownDialog), findsNothing);
  });

  testWidgets('No answers false, which is what closes Ember', (tester) async {
    bool? answer;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showDialog<bool>(
                context: context,
                builder: (_) => const PanelDownDialog(down: [groq], workingCount: 1),
              );
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No, chiudi Ember'));
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });
}
