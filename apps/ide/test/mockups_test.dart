import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/create/app_builder.dart';
import 'package:ide/features/mockups/mockup_controller.dart';

String reply(String name) => '''
STYLE: {"name": "$name", "palette": ["#111111", "#FFD700"], "font": "Manrope", "tagline": "Elegante e scuro"}
```html mockup.html
<!DOCTYPE html><html><body><h1>$name</h1></body></html>
```''';

void main() {
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
    expect(c.current.length, 5);
    expect(c.current.every((m) => m.status == MockupStatus.ready), isTrue);
    expect(maxInFlight, 5);
    final firstNames = c.current.map((m) => m.style.id).toSet();
    expect(firstNames.length, 5);

    await c.generateSet();
    expect(c.sets.length, 2);
    expect(c.current.map((m) => m.style.id).toSet().intersection(firstNames), isEmpty);
    c.showSet(0);
    expect(c.current.first.style.id, 'minimal');
    expect(c.costUsd, closeTo(0.10, 1e-9));
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
}
