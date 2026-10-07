import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/core/locale.dart';
import 'package:ide/core/theme_mode.dart';
import 'package:ide/features/factory/factory_controller.dart';
import 'package:ide/features/factory/factory_models.dart';
import 'package:ide/features/factory/factory_screen.dart';
import 'package:ide/features/factory/factory_shell.dart';
import 'package:ide/features/factory/factory_topbar.dart';
import 'package:ide/l10n/app_localizations.dart';

import 'support/factory_fakes.dart';
import 'support/fakes.dart';
import 'ui_smoke_test.dart' show Smoke, Variant, phone, smoke, wide;

extension on Variant {
  AppLocalizations get l => lookupAppLocalizations(locale);
}

const Variant _english = (size: phone, locale: Locale('en'), brightness: Brightness.dark);
const Variant _englishWide = (size: wide, locale: Locale('en'), brightness: Brightness.light);

List<Override> _overrides({String google = 'connected', String apple = 'missing', bool paused = false, int count = 12}) => [
  ...signedIn(api: FakeFactoryApi(connections: fakeConnectionsJson, stores: fakeStoresJson(google: google, apple: apple))),
  factoryProvider.overrideWith(() => FakeFactory(FactoryData.fromJson(fakeFactoryJson(count: count, paused: paused)))),
];

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _open(WidgetTester tester, Smoke s, {List<Override>? overrides}) async {
  await s.show(tester, const FactoryShell(location: '/factory', child: FactoryScreen()), overrides: overrides ?? _overrides(), at: '/factory');
  await _settle(tester);
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('factoryTopMenu')));
  await _settle(tester);
}

void main() {
  group('the top bar', () {
    smoke('the title, the places, the stores and the menu', (tester, s) async {
      await _open(tester, s);
      s.expectClean(tester);
      expect(find.byType(FactoryTopBar), findsOneWidget, reason: s.where);
      expect(find.text(s.v.l.fxTitle), findsOneWidget, reason: s.where);
      expect(find.byKey(const Key('storeChipGoogle')), findsOneWidget, reason: s.where);
      expect(find.byKey(const Key('storeChipApple')), findsOneWidget, reason: s.where);
      expect(find.byKey(const Key('factoryPause')), findsOneWidget, reason: s.where);
      expect(find.byKey(const Key('factoryTopMenu')), findsOneWidget, reason: s.where);
      // Wide: the places are tabs up here. Narrow: they are a bar under the page.
      final tabs = find.byKey(const Key('factoryTab0')).evaluate().isNotEmpty;
      final bar = find.byType(NavigationBar).evaluate().isNotEmpty;
      expect(tabs != bar, isTrue, reason: '${s.where}: tabs $tabs, bottom bar $bar');
      expect(find.byType(NavigationRail), findsNothing, reason: '${s.where}: the side rail is gone');
      expect(find.byType(Badge), findsWidgets, reason: '${s.where}: what waits for the owner sits on its place');
    });

    smoke('the tabs go to the places', (tester, s) async {
      await _open(tester, s);
      expect(find.text(s.v.l.fxNavOverview), findsWidgets, reason: s.where);
      // The test font is wider than the real one: the last tab may sit past the edge, where it slides into view.
      await tester.ensureVisible(find.byKey(const Key('factoryTab3')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('factoryTab3')));
      await _settle(tester);
      expect(find.text('route /factory/links'), findsOneWidget, reason: s.where);
    }, only: [_englishWide]);

    smoke('the stores say how they are, with a dot', (tester, s) async {
      await _open(tester, s, overrides: _overrides(google: 'connected', apple: 'invalid'));
      s.expectClean(tester);
      expect(find.byTooltip('${s.v.l.fxcGoogleName} · ${s.v.l.fxcStateConnected}'), findsOneWidget, reason: s.where);
      expect(find.byTooltip('${s.v.l.fxcAppleName} · ${s.v.l.fxcStateInvalid}'), findsOneWidget, reason: s.where);
      await tester.tap(find.byKey(const Key('storeChipApple')));
      await _settle(tester);
      expect(find.text('route /factory/links'), findsOneWidget, reason: '${s.where}: a tap goes to where it is connected');
    }, only: [_english, _englishWide]);

    smoke('a line under the bar shows how far the factory has got', (tester, s) async {
      await _open(tester, s);
      expect(find.byKey(const Key('factoryTopProgress')), findsOneWidget, reason: s.where);
      final line = tester.widget<LinearProgressIndicator>(find.byKey(const Key('factoryTopProgress')));
      expect(line.value, closeTo(0.31, 0.001), reason: s.where);
    }, only: [_english, _englishWide]);

    smoke('no work, no line', (tester, s) async {
      await _open(tester, s, overrides: _overrides(count: 0));
      expect(find.byKey(const Key('factoryTopProgress')), findsNothing, reason: s.where);
    }, only: [_english]);

    smoke('pause shows what a press does', (tester, s) async {
      await _open(tester, s, overrides: _overrides(paused: true));
      s.expectClean(tester);
      expect(find.text(s.v.l.fxResume), findsWidgets, reason: s.where);
    }, only: [_englishWide]);
  });

  group('the menu of choices', () {
    smoke('everything that can be chosen is in it', (tester, s) async {
      await _open(tester, s);
      await _openMenu(tester);
      expect(find.byKey(const Key('menuProjects')), findsOneWidget, reason: s.where);
      for (final m in ['system', 'light', 'dark']) {
        expect(find.byKey(Key('menuTheme_$m')), findsOneWidget, reason: '${s.where}: $m');
      }
      for (final (code, _) in appLanguages) {
        expect(find.byKey(Key('menuLang_$code')), findsOneWidget, reason: '${s.where}: $code');
      }
      expect(find.byKey(const Key('menuSettings')), findsOneWidget, reason: s.where);
      s.expectClean(tester, 'menu');
    }, only: [_english, _englishWide]);

    smoke('choosing light, dark or a language changes the app', (tester, s) async {
      await _open(tester, s);
      final container = ProviderScope.containerOf(tester.element(find.byType(FactoryTopBar)));
      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('menuTheme_dark')));
      await _settle(tester);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('menuLang_it')));
      await _settle(tester);
      expect(container.read(localeProvider).languageCode, 'it');
    }, only: [_english]);

    smoke('your apps are one tap away', (tester, s) async {
      await _open(tester, s);
      await _openMenu(tester);
      await tester.tap(find.byKey(const Key('menuProjects')));
      await _settle(tester);
      expect(find.text('route /projects'), findsOneWidget, reason: s.where);
    }, only: [_english]);
  });
}
