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
