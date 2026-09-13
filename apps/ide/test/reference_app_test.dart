import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/create/reference_app.dart';

void main() {
  test('finds the app a request is modelled on', () {
    expect(referenceQuery('creami app come bonus italia che è un app su playstore'), 'bonus italia');
    expect(referenceQuery('fammi una chat simile a Badoo con videochiamate'), 'Badoo');
    expect(referenceQuery('build an app like Duolingo for kids'), 'Duolingo');
    expect(referenceQuery('una app come l\'app Satispay, ma per i negozi'), 'Satispay');
    expect(referenceQuery('vedi https://play.google.com/store/apps/details?id=it.bonusx.app.prod&hl=it'), 'id:it.bonusx.app.prod');
    expect(referenceQuery('un\'app di ricette con timer'), isNull);
  });

  test('brief asks for the same features with original branding', () {
    const a = ReferenceApp(id: 'x.y', title: 'BonusX', developer: 'BonusX Srl', icon: '', url: 'https://play.google.com/store/apps/details?id=x.y', description: 'Trova bonus e ISEE');
    final b = a.brief();
    expect(b, contains('Trova bonus e ISEE'));
    expect(b, contains('never copy its name'));
  });
}
