import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/mockups/mockup_controller.dart' show PanelMember;
import 'package:ide/features/review/panel_health.dart';
import 'package:ide/features/review/reviewers.dart' show PanelPing;

/// A model that fails until [worksAfter] retries, then answers.
PanelMember member(String id, String label, {int worksAfter = 0}) {
  var calls = 0;
  return (
    id: id,
    label: label,
    complete: (String system, String prompt) async {
      calls++;
      if (calls <= worksAfter) throw Exception('quota finita');
      return (text: 'OK', costUsd: null);
    },
  );
}

PanelPing ok(String id, String label) => (id: id, label: label, ok: true, error: '');
PanelPing down(String id, String label, String why) => (id: id, label: label, ok: false, error: why);

void main() {
  group('the user is told which models are down, by name', () {
    test('one model', () => expect(panelDownTitle(['Groq']), 'Groq non sta funzionando'));
    test('two models', () => expect(panelDownTitle(['Groq', 'Gemini']), 'Groq e Gemini non stanno funzionando'));
    test('three models: every name is said', () {
      expect(panelDownTitle(['Groq', 'Gemini', 'DeepSeek']), 'Groq, Gemini e DeepSeek non stanno funzionando');
    });
    test('nothing to say when they all answered', () => expect(panelDownTitle([]), isEmpty));
  });

  group('what is left, and what going on anyway would mean', () {
    test('several left: they still check each other', () {
      expect(panelDownExplanation(3), contains('Restano 3 AI'));
      expect(panelDownExplanation(2), contains('si controllano a vicenda'));
    });
    test('one left: nobody checks its work, and it says so', () {
      expect(panelDownExplanation(1), contains('nessuno controllerà'));
    });
    test('none left: nothing can be done at all', () {
      expect(panelDownExplanation(0), contains('Non resta nessun AI'));
    });
    test('the go-on button names who would be missing', () {
      expect(proceedWithoutLabel(['Gemini']), 'Vai avanti senza Gemini');
      expect(proceedWithoutLabel(['Gemini', 'Groq']), 'Vai avanti senza 2 AI');
    });
  });

  /// Opens the real dialog and returns what the user's taps answered.
  Future<({bool proceed, List<PanelPing> pings})?> show(
    WidgetTester tester,
    List<PanelMember> members,
    List<PanelPing> initial,
  ) async {
    ({bool proceed, List<PanelPing> pings})? answer;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showDialog<({bool proceed, List<PanelPing> pings})>(
                context: context,
                builder: (_) => PanelStatusDialog(members: members, initial: initial),
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

  testWidgets('every model is listed, with the reason the broken one failed', (tester) async {
    await show(
      tester,
      [member('claude', 'Claude'), member('groq', 'Groq')],
      [ok('claude', 'Claude'), down('groq', 'Groq', 'HTTP 403')],
    );

    expect(find.text('Groq non sta funzionando'), findsOneWidget);
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('HTTP 403'), findsOneWidget);
    // Nothing can start from here: there is no plain "continue".
    expect(find.text('Continua con tutti'), findsNothing);
    expect(find.text('Vai avanti senza Groq'), findsOneWidget);
  });

  testWidgets('Riprova on a model that comes back turns it green and unblocks everything', (tester) async {
    // Groq fails the first ping, then answers.
    final members = [member('claude', 'Claude'), member('groq', 'Groq')];
    await show(tester, members, [ok('claude', 'Claude'), down('groq', 'Groq', 'HTTP 403')]);

    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    // Green now: the warning is gone and the work may start with all of them.
    expect(find.text('Tutti gli AI funzionano'), findsOneWidget);
    expect(find.text('HTTP 403'), findsNothing);
    expect(find.text('Riprova'), findsNothing);
    expect(find.text('Continua con tutti'), findsOneWidget);
    expect(find.text('Vai avanti senza Groq'), findsNothing);
  });

  testWidgets('Riprova that fails again keeps everything held, with the new reason', (tester) async {
    final members = [member('claude', 'Claude'), member('groq', 'Groq', worksAfter: 5)];
    await show(tester, members, [ok('claude', 'Claude'), down('groq', 'Groq', 'HTTP 403')]);

    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Groq non sta funzionando'), findsOneWidget);
    expect(find.textContaining('quota finita'), findsOneWidget);
    expect(find.text('Continua con tutti'), findsNothing);
  });

  /// Opens the dialog, taps [button], and hands back what the dialog answered.
  Future<({bool proceed, List<PanelPing> pings})> answerOf(
    WidgetTester tester,
    List<PanelMember> members,
    List<PanelPing> initial,
    String button,
  ) async {
    ({bool proceed, List<PanelPing> pings})? answer;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showDialog<({bool proceed, List<PanelPing> pings})>(
                context: context,
                builder: (_) => PanelStatusDialog(members: members, initial: initial),
              );
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    return answer!;
  }

  testWidgets('going on anyway reports only the models that answered', (tester) async {
    final answer = await answerOf(
      tester,
      [member('claude', 'Claude'), member('groq', 'Groq')],
      [ok('claude', 'Claude'), down('groq', 'Groq', 'HTTP 403')],
      'Vai avanti senza Groq',
    );

    expect(answer.proceed, isTrue);
    expect([for (final p in answer.pings.where((p) => p.ok)) p.id], ['claude']);
  });

  testWidgets('Chiudi Ember answers no, which stops the work', (tester) async {
    final answer = await answerOf(
      tester,
      [member('groq', 'Groq')],
      [down('groq', 'Groq', 'HTTP 403')],
      'Chiudi Ember',
    );

    expect(answer.proceed, isFalse);
    expect(answer.pings.single.ok, isFalse);
  });

}
