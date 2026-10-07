import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/factory/connect_cards.dart';
import 'package:ide/features/factory/connect_controller.dart' show providerPath;
import 'package:ide/features/factory/connect_models.dart';
import 'package:ide/features/factory/factory_controller.dart';
import 'package:ide/features/factory/factory_links_screen.dart';
import 'package:ide/features/factory/factory_models.dart';
import 'package:ide/features/factory/factory_needs_screen.dart';
import 'package:ide/features/factory/factory_screen.dart';
import 'package:ide/l10n/app_localizations.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;

import 'support/factory_fakes.dart';
import 'support/fakes.dart';
import 'ui_smoke_test.dart' show Variant, pageScroll, phone, smoke, wide;

extension on Variant {
  AppLocalizations get l => lookupAppLocalizations(locale);
}

const Variant _english = (size: phone, locale: Locale('en'), brightness: Brightness.dark);
const Variant _englishWide = (size: wide, locale: Locale('en'), brightness: Brightness.light);

List<Override> _overrides(FakeFactoryApi api, {int count = 3}) => [
  ...signedIn(api: api),
  factoryProvider.overrideWith(() => FakeFactory(FactoryData.fromJson(fakeFactoryJson(count: count)))),
];

FakeFactoryApi _api({String google = 'missing', String apple = 'missing', bool gcloud = false, bool gcloudSignedIn = true}) =>
    FakeFactoryApi(connections: fakeConnectionsJson, stores: fakeStoresJson(google: google, apple: apple, gcloud: gcloud, gcloudSignedIn: gcloudSignedIn));

/// The windows are taller than a phone: bring the button into view, as a finger would by scrolling.
Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pump();
  await tester.tap(find.byKey(Key(key)));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('reading the accounts', () {
    test('what the Runner says about each store', () {
      final a = StoreAccounts.fromJson(fakeStoresJson(google: 'connected', apple: 'invalid', gcloud: true));
      expect(a.googlePlay.state, StoreState.connected);
      expect(a.googlePlay.account, 'ember@proj.iam.gserviceaccount.com');
      expect(a.apple.state, StoreState.invalid);
      expect(a.apple.detail, 'key_refused');
      expect(a.gcloudInstalled, isTrue);
      expect(a.allConnected, isFalse);
      expect(a.links['appStoreKeys'], contains('appstoreconnect'));
      expect(StoreAccounts.fromJson(fakeStoresJson(google: 'connected', apple: 'connected')).allConnected, isTrue);
    });

    test('anything unexpected is read as "not connected"', () {
      final a = StoreAccounts.fromJson({'googlePlay': 'what', 'apple': {'state': 'something new'}});
      expect(a.googlePlay.state, StoreState.missing);
      expect(a.apple.state, StoreState.missing);
      expect(a.gcloudInstalled, isFalse);
    });
  });

  group('the cards', () {
    smoke('nothing connected: a button for each store', (tester, s) async {
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(_api()), at: '/factory/links');
      await _settle(tester);
      s.expectClean(tester);
      expect(find.byKey(const Key('connectGooglePlay')), findsOneWidget, reason: s.where);
      expect(find.byKey(const Key('connectApple')), findsOneWidget, reason: s.where);
      expect(find.text(s.v.l.fxcStateMissing), findsNWidgets(2), reason: s.where);
      expect(find.byKey(const Key('verifyGooglePlay')), findsNothing, reason: 'nothing to check or forget yet');
      await s.sweep(tester, pageScroll());
    });

    smoke('connected: who it is, and what can be done', (tester, s) async {
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(_api(google: 'connected', apple: 'connected')), at: '/factory/links');
      await _settle(tester);
      s.expectClean(tester);
      expect(find.text(s.v.l.fxcStateConnected), findsNWidgets(2), reason: s.where);
      expect(find.text(s.v.l.fxcAccountGoogle('ember@proj.iam.gserviceaccount.com')), findsOneWidget, reason: s.where);
      expect(find.textContaining(s.v.l.fxcAccountApple('Z47GM3ZDZ6')), findsOneWidget, reason: s.where);
      expect(find.textContaining(s.v.l.fxcAccountTeam('ABCDE12345')), findsOneWidget, reason: s.where);
      for (final k in const ['verifyGooglePlay', 'disconnectGooglePlay', 'verifyApple', 'disconnectApple', 'reconnectApple']) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: '${s.where}: $k');
      }
      expect(find.byKey(const Key('connectApple')), findsNothing, reason: s.where);
    });

    smoke('a refused key says so and offers to connect again', (tester, s) async {
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(_api(google: 'invalid', apple: 'unreachable')), at: '/factory/links');
      await _settle(tester);
      s.expectClean(tester);
      expect(find.text(s.v.l.fxcStateInvalid), findsOneWidget, reason: s.where);
      expect(find.text(s.v.l.fxcWhyRefused), findsOneWidget, reason: s.where);
      expect(find.text(s.v.l.fxcStateUnreachable), findsOneWidget, reason: s.where);
      expect(find.text(s.v.l.fxcReconnect), findsOneWidget, reason: s.where);
    });

    smoke('checking again and disconnecting go to the Runner', (tester, s) async {
      final api = _api(google: 'connected');
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(api), at: '/factory/links');
      await _settle(tester);
      await tester.tap(find.byKey(const Key('verifyGooglePlay')));
      await _settle(tester);
      expect(api.storeCalls, ['verify:google-play']);
      await tester.tap(find.byKey(const Key('disconnectGooglePlay')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // It asks first: the apps already uploaded stay, new uploads wait.
      expect(find.text(s.v.l.fxcDisconnectBody), findsOneWidget, reason: s.where);
      await tester.tap(find.widgetWithText(FilledButton, s.v.l.fxcDisconnect));
      await _settle(tester);
      expect(api.storeCalls, ['verify:google-play', 'disconnect:google-play']);
      expect(find.text(s.v.l.fxcStateMissing), findsNWidgets(2), reason: '${s.where}: forgotten, and the card shows it');
    }, only: [_english]);
  });

  group('connecting Google Play', () {
    smoke('paste the key, check, save', (tester, s) async {
      final api = _api();
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(api), at: '/factory/links');
      await _settle(tester);
      await tester.tap(find.byKey(const Key('connectGooglePlay')));
      await _settle(tester);
      expect(find.text(s.v.l.fxcGoogleTitle), findsOneWidget, reason: s.where);
      expect(find.byKey(const Key('openGoogleCloud')), findsOneWidget, reason: s.where);
      expect(find.byKey(const Key('autoGoogle')), findsNothing, reason: 'no Google Cloud tools on this computer');
      // Nothing to save before a key is there.
      expect(tester.widget<FilledButton>(find.byKey(const Key('saveGoogle'))).onPressed, isNull, reason: s.where);
      await tester.enterText(find.widgetWithText(TextField, s.v.l.fxcPasteKey), '{"type":"service_account","client_email":"a@b.c","private_key":"x"}');
      await tester.enterText(find.byKey(const Key('developerId')), '1234567890123456789');
      await tester.pump();
      await _tapKey(tester, 'saveGoogle');
      await _settle(tester);
      expect(api.storeCalls.single, startsWith('google:'));
      expect(api.storeCalls.single, endsWith(':1234567890123456789'));
      // The window closed and the card shows the account.
      expect(find.byKey(const Key('saveGoogle')), findsNothing, reason: s.where);
      expect(find.text(s.v.l.fxcAccountGoogle('ember@proj.iam.gserviceaccount.com')), findsOneWidget, reason: s.where);
    }, only: [_english, _englishWide]);

    smoke('a refused key is explained and nothing closes', (tester, s) async {
      final api = _api()..storeError = const RunnerException('key_refused', 'Invalid JWT Signature.');
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(api), at: '/factory/links');
      await _settle(tester);
      await tester.tap(find.byKey(const Key('connectGooglePlay')));
      await _settle(tester);
      await tester.enterText(find.widgetWithText(TextField, s.v.l.fxcPasteKey), '{"type":"service_account"}');
      await tester.pump();
      await _tapKey(tester, 'saveGoogle');
      await _settle(tester);
      expect(find.textContaining(s.v.l.fxcWhyRefused), findsOneWidget, reason: s.where);
      expect(find.byKey(const Key('saveGoogle')), findsOneWidget, reason: '${s.where}: still open, to try again');
    }, only: [_english]);

    smoke('the Google Cloud tools not signed in: sign in first, and the window waits for it', (tester, s) async {
      final api = _api(gcloud: true, gcloudSignedIn: false);
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(api), at: '/factory/links');
      await _settle(tester);
      await tester.tap(find.byKey(const Key('connectGooglePlay')));
      await _settle(tester);
      expect(find.byKey(const Key('autoGoogle')), findsNothing, reason: '${s.where}: nobody is signed in yet');
      await _tapKey(tester, 'gcloudSignIn');
      await tester.pump();
      expect(api.storeCalls, ['gcloud-login']);
      expect(find.text(s.v.l.fxcGcloudWaiting), findsOneWidget, reason: s.where);
      // The owner signs in, in the window that opened; a few seconds later the screen knows.
      api.gcloudAccountNext = 'me@gmail.com';
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.byKey(const Key('autoGoogle')), findsOneWidget, reason: s.where);
      expect(find.text(s.v.l.fxcGcloudSignedIn('me@gmail.com')), findsOneWidget, reason: s.where);
    }, only: [_english]);

    smoke('the hands-free way appears only with the Google Cloud tools', (tester, s) async {
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(_api(gcloud: true)), at: '/factory/links');
      await _settle(tester);
      await tester.tap(find.byKey(const Key('connectGooglePlay')));
      await _settle(tester);
      expect(find.byKey(const Key('autoGoogle')), findsOneWidget, reason: s.where);
      // It needs the developer number: without it it says so instead of starting.
      await _tapKey(tester, 'autoGoogle');
      await _settle(tester);
      expect(find.text(s.v.l.fxcWhyDeveloperId), findsOneWidget, reason: s.where);
    }, only: [_english]);
  });

  group('connecting the App Store', () {
    smoke('the key file is needed the first time', (tester, s) async {
      final api = _api();
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(api), at: '/factory/links');
      await _settle(tester);
      await tester.tap(find.byKey(const Key('connectApple')));
      await _settle(tester);
      expect(find.text(s.v.l.fxcAppleTitle), findsOneWidget, reason: s.where);
      expect(find.byKey(const Key('openAppStoreConnect')), findsOneWidget, reason: s.where);
      await tester.enterText(find.byKey(const Key('appleIssuer')), '69a6de70-1111-47e3-e053-5b8c7c11a4d1');
      await tester.enterText(find.byKey(const Key('appleKeyId')), 'Z47GM3ZDZ6');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('saveApple'))).onPressed, isNull, reason: '${s.where}: no .p8 file yet');
      expect(find.text(s.v.l.fxcKeepSavedKey), findsNothing, reason: s.where);
    }, only: [_english]);

    smoke('a key already saved can be kept while the IDs change', (tester, s) async {
      final api = _api(apple: 'invalid');
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(api), at: '/factory/links');
      await _settle(tester);
      await tester.tap(find.byKey(const Key('connectApple')));
      await _settle(tester);
      expect(find.text(s.v.l.fxcKeepSavedKey), findsOneWidget, reason: s.where);
      // The Key ID is already filled in from the saved account.
      expect(tester.widget<TextField>(find.byKey(const Key('appleKeyId'))).controller!.text, 'Z47GM3ZDZ6');
      await tester.enterText(find.byKey(const Key('appleIssuer')), '69a6de70-1111-47e3-e053-5b8c7c11a4d1');
      await tester.pump();
      await _tapKey(tester, 'saveApple');
      await _settle(tester);
      expect(api.storeCalls.single, 'apple:Z47GM3ZDZ6:69a6de70-1111-47e3-e053-5b8c7c11a4d1:-:');
      expect(find.byKey(const Key('saveApple')), findsNothing, reason: '${s.where}: closed');
      expect(find.text(s.v.l.fxcStateConnected), findsOneWidget, reason: s.where);
    }, only: [_english]);

    smoke('Apple saying no is explained', (tester, s) async {
      final api = _api(apple: 'invalid')..storeError = const RunnerException('no_permission', 'This key may not do that.');
      await s.show(tester, const Scaffold(body: FactoryLinksScreen()), overrides: _overrides(api), at: '/factory/links');
      await _settle(tester);
      await tester.tap(find.byKey(const Key('connectApple')));
      await _settle(tester);
      await tester.enterText(find.byKey(const Key('appleIssuer')), '69a6de70-1111-47e3-e053-5b8c7c11a4d1');
      await tester.pump();
      await _tapKey(tester, 'saveApple');
      await _settle(tester);
      expect(find.textContaining(s.v.l.fxcWhyNoRole), findsOneWidget, reason: s.where);
    }, only: [_english]);
  });

  group('where it shows up', () {
    smoke('the dashboard reminds the owner until both are connected', (tester, s) async {
      await s.show(tester, const Scaffold(body: FactoryScreen()), overrides: _overrides(_api(google: 'connected')), at: '/factory');
      await _settle(tester);
      s.expectClean(tester);
      expect(find.byKey(const Key('storeAccountsBanner')), findsOneWidget, reason: s.where);
    }, only: [_english, _englishWide]);

    smoke('and says nothing once they are', (tester, s) async {
      await s.show(tester, const Scaffold(body: FactoryScreen()), overrides: _overrides(_api(google: 'connected', apple: 'connected')), at: '/factory');
      await _settle(tester);
      expect(find.byKey(const Key('storeAccountsBanner')), findsNothing, reason: s.where);
    }, only: [_english]);

    smoke('an app waiting for a key gets a Connect button instead of "done"', (tester, s) async {
      final json = fakeFactoryJson(count: 1);
      final app = (json['apps'] as List).first as Map<String, dynamic>;
      app
        ..['state'] = 'needs_you'
        ..['needs'] = [
          {'id': 'k1', 'kind': 'play_key', 'stage': 'play', 'title': 'Connect Google Play', 'detail': '', 'data': {}, 'createdAt': '2026-10-06T10:00:00.000Z'},
        ];
      json['needsYou'] = [
        {...(app['needs'] as List).first as Map<String, dynamic>, 'appId': app['id'], 'appName': app['name']},
      ];
      final api = _api();
      await s.show(
        tester,
        const Scaffold(body: FactoryNeedsScreen()),
        overrides: [...signedIn(api: api), factoryProvider.overrideWith(() => FakeFactory(FactoryData.fromJson(json)))],
        at: '/factory/needs',
      );
      await _settle(tester);
      s.expectClean(tester);
      expect(find.byKey(const Key('needConnect')), findsOneWidget, reason: s.where);
      expect(find.text(s.v.l.fxNeedsDone), findsNothing, reason: s.where);
      await tester.tap(find.byKey(const Key('needConnect')));
      await _settle(tester);
      expect(find.text(s.v.l.fxcGoogleTitle), findsOneWidget, reason: '${s.where}: the Google Play window opens');
    }, only: [_english]);
  });

  test('the Runner’s names for the two accounts', () {
    expect(providerPath('google_play'), 'google-play');
    expect(providerPath('apple'), 'apple');
    expect(storeTone(StoreState.invalid), isNot(storeTone(StoreState.connected)));
  });
}
