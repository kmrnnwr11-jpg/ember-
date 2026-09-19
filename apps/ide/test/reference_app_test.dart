import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/create/reference_app.dart';
import 'package:ide/features/mockups/mockup_controller.dart';

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
    expect(b, contains('Never the reference\'s name'));
  });

  test('reads every subject the listing promises, so none is left out', () {
    const kids = ReferenceApp(
      id: 'com.kids.preschool.learning.games',
      title: 'Kids Preschool Learning Games',
      developer: 'GunjanApps Studios',
      icon: '',
      url: 'u',
      description: '''
This app has over 150 games that cover topics, such as:

Alphabets: Learn to recognize and write letters.
Numbers: Learn to count and trace numbers.
Colors: Learn to name and match colors.
Shapes: Learn to recognize basic shapes.
Animals: Learn to name animals.
Bedtime Stories: Listen to soothing stories.

All the games are designed with interactive graphics.''',
    );

    expect(kids.topics(), ['Alphabets', 'Numbers', 'Colors', 'Shapes', 'Animals', 'Bedtime Stories']);
    final b = kids.brief();
    expect(b, contains('none left out (6)'));
    expect(b, contains('6. Bedtime Stories'));
    // The size the listing brags about, so three examples per subject is not enough.
    expect(b, contains('150 games'));
    // Look and law: drawings instead of emoji, animation, and no copied branding.
    expect(b, contains('never stand in for the artwork'));
    expect(b, contains('animate yours'));
    expect(b, contains('reference/'));
    expect(b, contains('5% different'));
  });

  test('the pasted link decides how the mockups look, not a generic style list', () {
    const kids = ReferenceApp(id: 'a.b', title: 'Kids Preschool Learning Games', developer: 'Gunjan', icon: '', url: 'u', description: 'Learning games for toddlers aged 2 to 5.');
    expect(kids.audience, 'kids');
    expect(kids.visualDirection(), contains('AUDIENCE: kids'));
    expect(kids.visualDirection(), contains('No white minimalism'));
    expect(stylePoolFor(kids.visualDirection()).take(3).map((s) => s.id), ['playful', 'pastel', 'retro']);

    const bank = ReferenceApp(id: 'a.b', title: 'Fatture in Cloud', developer: '', icon: '', url: 'u', description: 'Gestisci fatture, tasse e il conto della tua attività.');
    expect(bank.audience, 'serious');
    expect(bank.visualDirection(), contains('sober and trustworthy'));
    expect(stylePoolFor(bank.visualDirection()).take(3).map((s) => s.id), ['corporate', 'material', 'minimal']);

    // Every reference still carries its own listing into the mockups.
    expect(bank.visualDirection(), contains('Fatture in Cloud'));
    // Without a reference, the usual styles stay as they are.
    expect(stylePoolFor('').first.id, mockupStylePool.first.id);
  });

  test('copies how the model app earns, because that is part of the app', () {
    const free = ReferenceApp(id: 'x.y', title: 'Demo', developer: '', icon: '', url: 'u');
    expect(free.brief(), contains('shows no ads and sells nothing'));

    const withAds = ReferenceApp(id: 'x.y', title: 'Demo', developer: '', icon: '', url: 'u', ads: true);
    expect(withAds.brief(), contains('google_mobile_ads'));
    expect(withAds.brief(), contains('EMBER_ADS: banner,interstitial,rewarded'));
    expect(withAds.brief(), isNot(contains('in_app_purchase')));

    const both = ReferenceApp(id: 'x.y', title: 'Demo', developer: '', icon: '', url: 'u', ads: true, purchases: true, priceRange: '\$0.99 - \$49.99 per item');
    expect(both.brief(), contains('in_app_purchase'));
    expect(both.brief(), contains('\$0.99 - \$49.99'));
    expect(both.brief(), contains('EMBER_PRODUCTS'));
  });
}
