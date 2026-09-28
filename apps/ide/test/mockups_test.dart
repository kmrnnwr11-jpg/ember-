import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/create/app_builder.dart';
import 'package:ide/features/mockups/mockup_controller.dart';

String reply(String name) => '''
STYLE: {"name": "$name", "palette": ["#111111", "#FFD700"], "font": "Manrope", "tagline": "Elegante e scuro"}
```html mockup.html
<!DOCTYPE html><html><body><h1>$name</h1></body></html>
```''';

void main() {
  panelTests();
  test('parses STYLE line and html block; rejects incomplete output', () {
    final m = Mockup(mockupStylePool[1]);
    expect(m.apply(reply('Dark Gold')), isTrue);
    expect((m.name, m.font, m.tagline), ('Dark Gold', 'Manrope', 'Elegante e scuro'));
    expect(m.palette, ['#111111', '#FFD700']);
    expect(m.html, contains('<h1>Dark Gold</h1>'));
    expect(m.designBrief(), contains('#111111, #FFD700'));
    expect(m.designBrief(), contains('<h1>Dark Gold</h1>'));

    expect(Mockup(mockupStylePool[0]).apply('Scusa, non posso.'), isFalse);
    expect(Mockup(mockupStylePool[0]).apply('```html\n<html><body>troncato'), isFalse);
  });

  test('generates 5 distinct styles in parallel, new set uses 5 other styles, keeps history', () async {
    final prompts = <String>[];
    var inFlight = 0, maxInFlight = 0;
    final c = MockupController(
      description: 'App ricette',
      engine: BuildEngine.gemini,
      complete: (system, prompt) async {
        prompts.add(prompt);
        inFlight++;
        maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        inFlight--;
        final style = RegExp(r'Visual style: ([^—]+) —').firstMatch(prompt)!.group(1)!.trim();
        return (text: reply(style), costUsd: 0.01);
      },
    );
    await c.generateSet();
    expect(c.current.length, c.setSize);
    expect(c.current.every((m) => m.status == MockupStatus.ready), isTrue);
    // Four at a time: quick, without asking a free tier for seven long answers at once.
    expect(maxInFlight, 4);
    final firstNames = c.current.map((m) => m.style.id).toSet();
    expect(firstNames.length, c.setSize);
    // Each proposal carries its own direction: eight different styles, not one
    // page recoloured eight times.
    expect(c.current.map((m) => m.style.direction).toSet(), hasLength(c.setSize));

    await c.generateSet();
    expect(c.sets.length, 2);
    // A second set moves on through the pool. It cannot be entirely new: the
    // pool holds five dark looks and a set wants four of them, so by the
    // second set some must come round again. What must not happen is the same
    // eight over again.
    final secondNames = c.current.map((m) => m.style.id).toSet();
    expect(secondNames, isNot(equals(firstNames)));
    expect(secondNames.difference(firstNames), isNotEmpty);
    c.showSet(0);
    expect(c.current.first.style.id, 'minimal');
    // Two sets of c.setSize proposals, at 0.01 each.
    expect(c.costUsd, closeTo(0.01 * 2 * c.setSize, 1e-9));
  });

  test('edit keeps the previous mockup if regeneration fails', () async {
    var fail = false;
    final c = MockupController(
      description: 'x',
      engine: BuildEngine.gemini,
      complete: (s, p) async => fail ? throw Exception('quota') : (text: reply('A'), costUsd: null),
    );
    await c.generateSet();
    final m = c.current.first;
    fail = true;
    await c.edit(m, 'più scuro');
    expect(m.status, MockupStatus.ready);
    expect(m.html, contains('<h1>A</h1>'));
    expect(m.error, contains('quota'));
  });

  test('a whole website does not drown the drawing brief', () {
    final long = 'x' * (maxMockupDescription + 500);
    final prompt = mockupUserPrompt(long, mockupStylePool.first);
    expect(prompt.length, lessThan(maxMockupDescription + 1200));
    expect(prompt, contains('the rest of the brief goes to the build'));
    // A short description is passed whole.
    expect(mockupUserPrompt('app di ricette', mockupStylePool.first), contains('app di ricette'));
  });

  test('the subject still decides the colour, wherever the direction comes from', () {
    expect(mockupSystemPrompt, contains('PDF and documents red'));
    expect(directionSystem, contains('The subject decides the colour'));
    // With an app to copy, the directions must stay in its world.
    expect(directionSystem, contains("stays recognisably in that app's world"));
  });

  test('directions are read out of an answer wrapped in prose', () {
    final got = parseDirections('Sure!\n[{"name":"Quiet Ledger","direction":"A calm list of rows with the balance set large above them, thin line icons.","dark":false}]\nHope that helps.');
    expect(got, hasLength(1));
    expect(got.first.style.name, 'Quiet Ledger');
    expect(got.first.style.id, 'quiet_ledger');
    expect(got.first.dark, isFalse);
    // Too short to draw from, so not a direction.
    expect(parseDirections('[{"name":"X","direction":"nice"}]'), isEmpty);
    expect(parseDirections('I cannot do that.'), isEmpty);
  });

  test('a direction two models proposed leads, and light and dark stay balanced', () {
    Direction d(String name, String text, bool dark) =>
        (style: MockupStyle(name.toLowerCase(), name, text), dark: dark);
    // Groq and Gemini arrive at the same idea in different words.
    final merged = mergeDirections([
      (label: 'Groq', list: [
        d('Bold Ledger', 'A large balance dominates the screen above a quiet list of rows', false),
        d('Midnight', 'Near black ground with the accent glowing on the totals', true),
      ]),
      (label: 'Gemini', list: [
        d('Big Balance', 'The balance dominates the screen, a quiet list of rows below it', false),
        d('Paper', 'Cream ground, serif headings, generous margins like a printed statement', false),
      ]),
    ], count: 4);

    // The agreed one is first.
    expect(merged.first.style.name, 'Bold Ledger');
    // Both grounds are offered, not four of one kind.
    expect(merged.where((m) => m.dark), isNotEmpty);
    expect(merged.where((m) => !m.dark), isNotEmpty);
    // The two ways of saying the same thing counted once.
    expect(merged.map((m) => m.style.name), isNot(contains('Big Balance')));
  });

  test('the panel decides the directions, and they reach the drawings', () async {
    const answer = '[{"name":"Quiet Ledger","direction":"A calm list with the balance set large above it, thin line icons","dark":false},'
        '{"name":"Midnight","direction":"Near black ground with the accent glowing on the totals only","dark":true}]';
    final prompts = <String>[];
    ({String id, String label, CompleteText complete}) m(String id) => (
          id: id,
          label: id.toUpperCase(),
          complete: (system, prompt) async {
            if (system == directionSystem) return (text: answer, costUsd: null);
            prompts.add(prompt);
            if (prompt.contains('Score every proposal')) return (text: '[]', costUsd: null);
            final style = RegExp(r'Visual style: ([^—]+) —').firstMatch(prompt)!.group(1)!.trim();
            return (text: reply(style), costUsd: null);
          },
        );
    final a = m('a');
    final b = m('b');
    final c = MockupController(
      description: 'App conti di casa',
      engine: BuildEngine.gemini,
      complete: (s, p) async => (text: 'unused', costUsd: null),
      panel: [
        (id: a.id, label: a.label, complete: a.complete),
        (id: b.id, label: b.label, complete: b.complete),
      ],
    );

    await c.generateSet();

    // Every drawing carries a direction the panel agreed, not one from the
    // old fixed list of fifteen looks.
    expect(c.current.every((x) => x.style.name == 'Quiet Ledger' || x.style.name == 'Midnight'), isTrue);
    expect(prompts.any((p) => p.contains('A calm list with the balance')), isTrue);
    // Both grounds were asked for.
    expect(prompts.any((p) => p.contains('MUST be dark')), isTrue);
    expect(prompts.any((p) => p.contains('MUST be light')), isTrue);
  });

  test('nobody answers the direction round: the old pool still draws something', () async {
    final c = MockupController(
      description: 'App ricette',
      engine: BuildEngine.gemini,
      complete: (s, p) async => (text: 'unused', costUsd: null),
      panel: [
        (id: 'a', label: 'A', complete: (s, p) async => (text: 'no json here', costUsd: null)),
        (id: 'b', label: 'B', complete: (s, p) async => throw Exception('down')),
      ],
    );

    await c.generateSet();

    expect(c.current, hasLength(c.setSize));
    // Fell back to the pool rather than showing an empty gallery.
    expect(c.current.every((x) => mockupStylePool.any((s) => s.id == x.style.id)), isTrue);
  });
}

/// A member of the design table: it draws, and it always scores the same way.
({String id, String label, CompleteText complete, List<String> calls}) panelMember(String id, String critique) {
  final calls = <String>[];
  return (
    id: id,
    label: id.toUpperCase(),
    calls: calls,
    complete: (system, prompt) async {
      calls.add(prompt);
      if (prompt.contains('Score every proposal')) return (text: critique, costUsd: null);
      final style = RegExp(r'Visual style: ([^—]+) —').firstMatch(prompt)!.group(1)!.trim();
      return (text: '${reply(style)}\nDESIGN: big title, quiet grey subtext, one accent.', costUsd: null);
    },
  );
}

String allScored(int n, int score, String fix) =>
    '[${List.generate(n, (i) => '{"n": ${i + 1}, "score": $score, "fix": "$fix"}').join(',')}]';

void panelTests() {
  test('parseCritique reads scores out of prose and ignores what is not JSON', () {
    expect(parseCritique('Ecco:\n[{"n":2,"score":7,"fix":"ingrandisci il titolo"}]\nSpero aiuti.'),
        [(n: 2, score: 7.0, fix: 'ingrandisci il titolo')]);
    expect(parseCritique('[{"n":1,"score":50,"fix":"x"}]').single.score, 10);
    expect(parseCritique('Non posso.'), isEmpty);
  });

  test('the panel shares the drawing, scores it, and redraws with the others notes', () async {
    final a = panelMember('a', allScored(4, 6, 'ingrandisci il titolo'));
    final b = panelMember('b', allScored(4, 8, 'togli la cornice'));
    final c = MockupController(
      description: 'App ricette',
      engine: BuildEngine.gemini,
      complete: (s, p) async => (text: 'unused', costUsd: null),
      panel: [
        (id: a.id, label: a.label, complete: a.complete),
        (id: b.id, label: b.label, complete: b.complete),
      ],
    );

    await c.generateSet();

    // Two each: neither model drew the whole set.
    expect(c.current.where((m) => m.authorLabel == 'A').length, 2);
    expect(c.current.where((m) => m.authorLabel == 'B').length, 2);
    // Scored by both, so the average of 6 and 8.
    expect(c.current.every((m) => m.score == 7.0), isTrue);
    // A note counts only when it comes from a different model.
    expect(c.current.firstWhere((m) => m.authorLabel == 'A').notes, ['B: togli la cornice']);
    expect(c.current.every((m) => m.refined), isTrue);
    // Each member: 2 drawings + 1 critique + 2 redraws.
    expect(a.calls.where((p) => p.contains('THE DESIGN PANEL HAS REVIEWED')).length, 2);
    expect(c.panelStatus, isEmpty);
  });

  test('a critic that is down does not stop the set', () async {
    final a = panelMember('a', 'not json');
    final b = panelMember('b', allScored(4, 9, ''));
    final c = MockupController(
      description: 'App ricette',
      engine: BuildEngine.gemini,
      complete: (s, p) async => (text: 'unused', costUsd: null),
      panel: [
        (id: a.id, label: a.label, complete: a.complete),
        (id: b.id, label: b.label, complete: b.complete),
      ],
    );

    await c.generateSet();

    expect(c.current.where((m) => m.status == MockupStatus.ready).length, 4);
    // Only B voted, and it left no instruction, so nothing is redrawn.
    expect(c.current.every((m) => m.score == 9.0), isTrue);
    expect(c.current.every((m) => m.notes.isEmpty && !m.refined), isTrue);
  });

  test('two proposals for every model drawing', () {
    PanelMember m(String id) => (id: id, label: id, complete: (String s, String p) async => (text: '', costUsd: null));
    CompleteText solo = (s, p) async => (text: '', costUsd: null);
    expect(MockupController(description: 'x', engine: BuildEngine.gemini, complete: solo).setSize, 8);
    expect(MockupController(description: 'x', engine: BuildEngine.gemini, complete: solo, panel: [m('a'), m('b')]).setSize, 4);
    expect(MockupController(description: 'x', engine: BuildEngine.gemini, complete: solo, panel: [for (final i in 'abcde'.split('')) m(i)]).setSize, 10);
  });
}
