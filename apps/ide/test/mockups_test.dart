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
    expect(c.current.length, MockupController.setSize);
    expect(c.current.every((m) => m.status == MockupStatus.ready), isTrue);
    // Four at a time: quick, without asking a free tier for seven long answers at once.
    expect(maxInFlight, 4);
    final firstNames = c.current.map((m) => m.style.id).toSet();
    expect(firstNames.length, MockupController.setSize);
    // Each proposal is a different build, not the same page recoloured.
    expect(prompts.where((p) => p.contains('grid of square tiles')), hasLength(1));
    expect(prompts.where((p) => p.contains('vertical list of wide rows')), hasLength(1));

    await c.generateSet();
    expect(c.sets.length, 2);
    expect(c.current.map((m) => m.style.id).toSet().intersection(firstNames), isEmpty);
    c.showSet(0);
    expect(c.current.first.style.id, 'minimal');
    // Two sets of MockupController.setSize proposals, at 0.01 each.
    expect(c.costUsd, closeTo(0.01 * 2 * MockupController.setSize, 1e-9));
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

  test('each proposal commits to its own colour, and the subject leads', () {
    final first = mockupUserPrompt('app PDF', mockupStylePool.first, accent: mockupAccents.first);
    final second = mockupUserPrompt('app PDF', mockupStylePool[1], accent: mockupAccents[1]);
    expect(first, contains('red / crimson'));
    expect(second, contains('deep blue'));
    expect(first, contains('the subject of the app calls for its own colour, which always wins'));
    expect(mockupSystemPrompt, contains('PDF and documents red'));
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
    final a = panelMember('a', allScored(8, 6, 'ingrandisci il titolo'));
    final b = panelMember('b', allScored(8, 8, 'togli la cornice'));
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

    // Round-robin: neither model drew the whole set.
    expect(c.current.where((m) => m.authorLabel == 'A').length, 4);
    expect(c.current.where((m) => m.authorLabel == 'B').length, 4);
    // Scored by both, so the average of 6 and 8.
    expect(c.current.every((m) => m.score == 7.0), isTrue);
    // A note counts only when it comes from a different model.
    expect(c.current.firstWhere((m) => m.authorLabel == 'A').notes, ['B: togli la cornice']);
    expect(c.current.every((m) => m.refined), isTrue);
    // Each member: 4 drawings + 1 critique + 4 redraws.
    expect(a.calls.where((p) => p.contains('THE DESIGN PANEL HAS REVIEWED')).length, 4);
    expect(c.panelStatus, isEmpty);
  });

  test('a critic that is down does not stop the set', () async {
    final a = panelMember('a', 'not json');
    final b = panelMember('b', allScored(8, 9, ''));
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

    expect(c.current.where((m) => m.status == MockupStatus.ready).length, 8);
    // Only B voted, and it left no instruction, so nothing is redrawn.
    expect(c.current.every((m) => m.score == 9.0), isTrue);
    expect(c.current.every((m) => m.notes.isEmpty && !m.refined), isTrue);
  });
}
