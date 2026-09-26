import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/store/default_policy.dart';

void main() {
  test('the policy is long enough to be accepted and says who to write to', () {
    final p = defaultPrivacyPolicy(appName: 'Card Studio', email: 'me@example.com');
    // The Runner refuses anything under 50 characters, and Google refuses a
    // policy with no contact.
    expect(p.length, greaterThan(50));
    expect(p, contains('Card Studio'));
    expect(p, contains('me@example.com'));
    expect(p, contains('GDPR'));
  });

  test('it claims only what the app was actually built with', () {
    final plain = defaultPrivacyPolicy(appName: 'Notes', email: 'a@b.c');
    expect(plain, isNot(contains('AdMob')));
    expect(plain, isNot(contains('Billing')));
    expect(plain, contains('works without sending your data to any third party'));

    final full = defaultPrivacyPolicy(appName: 'Notes', email: 'a@b.c', ads: true, purchases: true);
    expect(full, contains('AdMob'));
    expect(full, contains('Google Play Billing'));
    // Consent in the EU is not optional where ads are shown.
    expect(full, contains('consent'));
  });

  test('a missing email leaves a blank a person can see, not a wrong address', () {
    final p = defaultPrivacyPolicy(appName: 'X', email: '  ');
    expect(p, contains('[EMAIL]'));
  });

  test('the date is the day it was written', () {
    final p = defaultPrivacyPolicy(appName: 'X', email: 'a@b.c', today: DateTime(2026, 3, 7));
    expect(p, contains('2026-03-07'));
  });
}
