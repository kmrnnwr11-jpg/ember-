import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/factory/factory_app_sheet.dart';
import 'package:ide/features/factory/factory_controller.dart';
import 'package:ide/features/factory/factory_links_screen.dart';
import 'package:ide/features/factory/factory_models.dart';
import 'package:ide/features/factory/factory_needs_screen.dart';
import 'package:ide/features/factory/factory_new_screen.dart';
import 'package:ide/features/factory/factory_screen.dart';
import 'package:ide/features/factory/factory_shell.dart';
import 'package:ide/features/factory/factory_widgets.dart' show engineLabel;
import 'package:ide/l10n/app_localizations.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;

import 'support/factory_fakes.dart';
import 'support/fakes.dart';
import 'ui_smoke_test.dart' show Variant, longText, pageScroll, phone, smoke, wide;

extension on Variant {
  AppLocalizations get l => lookupAppLocalizations(locale);
}

/// One window for the tests that click through a screen.
const Variant _english = (size: phone, locale: Locale('en'), brightness: Brightness.dark);
const Variant _englishWide = (size: wide, locale: Locale('en'), brightness: Brightness.light);

List<Override> _overrides(FakeFactory fake, {FakeFactoryApi? api}) => [
  ...signedIn(
    // Both stores connected: the reminder to connect them has its own tests (connect_test.dart).
    api: api ?? FakeFactoryApi(plan: fakePlanJson(), connections: fakeConnectionsJson, stores: fakeStoresJson(google: 'connected', apple: 'connected')),
  ),
  factoryProvider.overrideWith(() => fake),
];

FakeFactory _factory({
  int count = 100,
  bool paused = false,
  bool interrupted = false,
  bool lowDisk = false,
  bool simulated = false,
}) => FakeFactory(
  FactoryData.fromJson(
    fakeFactoryJson(count: count, paused: paused, interrupted: interrupted, lowDisk: lowDisk, simulated: simulated),
  ),
);

void main() {
  group('reading what the Runner says', () {
    final data = FactoryData.fromJson(fakeFactoryJson());

    test('the summary, the daily limits and the apps', () {
      expect(data.summary.total, 100);
      expect(data.summary.onPlay, 4);
      expect(data.summary.etaSeconds, 5400);
      expect(data.apps, hasLength(100));
      expect(data.settings.dailyPlayCap, 10);
      expect(data.settings.dailyStoreCap, 10);
      expect(data.uploads.play, 4);
      expect(data.uploads.capAppstore, 10);
      expect(data.uploads.resetsAt, isNotNull);
      expect(data.batches.single.goal, Goal.android);
    });

    test('apps keep the Runner’s order and say where they are', () {
      expect([for (final a in data.apps.take(3)) a.order], [0, 1, 2]);
      final failed = data.apps.firstWhere((a) => a.status == AppStatus.failed);
      expect(failed.failedStage, 'verify');
      expect(failed.currentStage, 'verify');
      expect(failed.error, contains('analyze'));
      final running = data.apps.firstWhere((a) => a.status == AppStatus.running);
      expect(running.stage(running.currentStage!).status, StageStatus.running);
      expect(running.projectId, isNotNull);
    });

    test('an app waiting for tomorrow’s upload slot knows until when', () {
      final waiting = data.apps.firstWhere((a) => a.stage('play').until != null);
      expect(waiting.status, AppStatus.queued);
      expect(waiting.waitingUntil, isNotNull);
      expect(data.apps.firstWhere((a) => a.status == AppStatus.done).waitingUntil, isNull);
    });

    test('skipped stages do not count towards the progress of an app', () {
      final done = data.apps.firstWhere((a) => a.status == AppStatus.done);
      expect(done.plannedStages, 9);
      expect(done.progress, 1);
    });

    test('what only the owner can do, with the values to copy', () {
      expect(data.needs, isNotEmpty);
      final need = data.needs.first;
      expect(need.kind, 'play_console_app');
      expect(need.stage, 'play');
      expect(need.data['package'], startsWith('com.emberapps.'));
      expect(need.appId, isNotEmpty);
      expect(need.appName, isNotEmpty);
    });

    test('an empty or unknown answer never breaks anything', () {
      final empty = FactoryData.fromJson(const {});
      expect(empty.apps, isEmpty);
      expect(empty.settings.maxInFlight, 12);
      expect(empty.paused, isFalse);
      final odd = FactoryData.fromJson({
        'apps': [
          {
            'id': 'x',
            'name': 'X',
            'state': 'something new',
            'stages': {
              'create': {'state': 'weird'},
            },
            'newField': 1,
          },
        ],
        'newTop': true,
      });
      expect(odd.apps.single.status, AppStatus.queued);
      expect(odd.apps.single.stage('create').status, StageStatus.pending);
    });

    test('the supervisor’s plan and the reasons for what it left out', () {
      final plan = PlanResult.fromJson(fakePlanJson());
      expect(plan.proposals, hasLength(6));
      expect(plan.proposals.first.size, 'big');
      expect(plan.dropped.map((d) => d.reason), ['duplicate_name', 'similar_idea']);
      expect(plan.dropped.last.keptInstead, 'Idea 2');
      expect(plan.warnings, ['no_ai']);
      expect(plan.source, 'list');
    });

    test('a batch is sent as the Runner expects it', () {
      const recipe = BatchRecipe(
        engines: {'claude-code': 2, 'qwen-code': 1, 'codex': 0},
        logoBy: 'codex',
        goal: Goal.ios,
      );
      expect(recipe.toJson(), {
        'engines': {'claude-code': 2, 'qwen-code': 1},
        'quality': 'fast',
        'logoBy': 'codex',
        'goal': 'ios',
      });
      const p = AppProposal(name: 'Idea', summary: 'One line', size: 'big', engine: 'codex');
      expect(p.toJson(), {'name': 'Idea', 'summary': 'One line', 'size': 'big', 'engine': 'codex'});
    });

    test('connections: ready or not, and why', () {
      final c = FactoryConnections.fromJson(fakeConnectionsJson);
      expect(c.ready('claude'), isTrue);
      expect(c.ready('mac'), isFalse);
      expect(c.links.firstWhere((l) => l.id == 'mac').detail, 'windows');
      expect(c.readyOf(['qwen', 'qwen-code']), isFalse);
      expect(c.readyOf(['nothing']), isNull);
      expect(c.cpus, 16);
      expect(c.agentSlots, 6);
    });
  });

  group('the dashboard', () {
    smoke('100 apps in every state', (tester, s) async {
      await s.show(
        tester,
        const Scaffold(body: FactoryScreen()),
        overrides: _overrides(_factory()),
        at: '/factory',
      );
      s.expectClean(tester);
      expect(find.byKey(const Key('factoryEmpty')), findsNothing, reason: s.where);
      expect(find.text(s.v.l.fxStatusNeedsYou), findsWidgets, reason: s.where);
      final seen = await s.sweep(tester, pageScroll(), keys: ['factoryApp_a0', 'factoryApp_a2']);
      expect(seen, contains('factoryApp_a0'), reason: s.where);
    });

    smoke('paused after a restart, disk full, simulated', (tester, s) async {
      await s.show(
        tester,
        const Scaffold(body: FactoryScreen()),
        overrides: _overrides(_factory(count: 6, paused: true, interrupted: true, lowDisk: true, simulated: true)),
        at: '/factory',
      );
      s.expectClean(tester);
      for (final key in const ['factoryPaused', 'factoryLowDisk', 'factorySimulated']) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: '${s.where}: $key');
      }
      await s.sweep(tester, pageScroll());
    });

    smoke('no apps yet', (tester, s) async {
      await s.show(
        tester,
        const Scaffold(body: FactoryScreen()),
        overrides: _overrides(_factory(count: 0)),
        at: '/factory',
      );
      s.expectClean(tester);
      expect(find.byKey(const Key('factoryEmpty')), findsOneWidget, reason: s.where);
    });

    smoke('inside its frame', (tester, s) async {
      await s.show(
        tester,
        const FactoryShell(location: '/factory', child: FactoryScreen()),
        overrides: _overrides(_factory(count: 12)),
        at: '/factory',
      );
      s.expectClean(tester);
      expect(
        find.byType(NavigationRail).evaluate().isNotEmpty || find.byType(NavigationBar).evaluate().isNotEmpty,
        isTrue,
        reason: s.where,
      );
      expect(find.text(s.v.l.fxTitle), findsOneWidget, reason: s.where);
      // The number of things waiting for the owner sits on its entry.
      expect(find.byType(Badge), findsWidgets, reason: s.where);
    });

    smoke('one app opened', (tester, s) async {
      final fake = _factory(count: 12);
      for (final id in const ['a3', 'a4', 'a5', 'a2']) {
        await s.show(
          tester,
          Scaffold(
            body: FactoryAppSheet(appId: id, scroll: ScrollController()),
          ),
          overrides: _overrides(fake),
          at: '/factory',
        );
        s.expectClean(tester, id);
        await s.sweep(tester, find.byType(Scrollable).first, step: id);
        expect(find.text(s.v.l.fxSteps), findsOneWidget, reason: '${s.where} $id');
      }
    }, only: [_english, _englishWide]);

    smoke('tapping an app opens it', (tester, s) async {
      await s.show(
        tester,
        const Scaffold(body: FactoryScreen()),
        overrides: _overrides(_factory(count: 8)),
        at: '/factory',
      );
      await tester.tap(find.byKey(const Key('factoryApp_a0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      s.expectClean(tester, 'sheet');
      expect(find.byType(FactoryAppSheet), findsOneWidget, reason: s.where);
    }, only: [_english, _englishWide]);

    smoke('a long press selects, and the selection retries', (tester, s) async {
      final fake = _factory(count: 8);
      await s.show(
        tester,
        const Scaffold(body: FactoryScreen()),
        overrides: _overrides(fake),
        at: '/factory',
      );
      await tester.ensureVisible(find.byKey(const Key('factoryApp_a1')));
      await tester.pump();
      await tester.longPress(find.byKey(const Key('factoryApp_a1')));
      await tester.pump();
      expect(find.text(s.v.l.fxSelected(1)), findsOneWidget, reason: s.where);
      await tester.ensureVisible(find.byKey(const Key('factoryApp_a2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('factoryApp_a2')));
      await tester.pump();
      expect(find.text(s.v.l.fxSelected(2)), findsOneWidget, reason: s.where);
      await tester.tap(find.text(s.v.l.retry));
      await tester.pump();
      expect(fake.calls, ['bulk:retry:a1,a2']);
    }, only: [_english]);

    smoke('a failed app can be retried from the stage it failed at', (tester, s) async {
      final fake = _factory(count: 12);
      await s.show(
        tester,
        Scaffold(
          body: FactoryAppSheet(appId: 'a4', scroll: ScrollController()),
        ),
        overrides: _overrides(fake),
        at: '/factory',
      );
      await tester.tap(find.text(s.v.l.fxRetryFrom(s.v.l.fxStageVerify)));
      await tester.pump();
      expect(fake.calls, ['retry:a4:{from: verify}']);
    }, only: [_english]);
  });

  group('what needs the owner', () {
    smoke('the list, with the values to copy', (tester, s) async {
      await s.show(
        tester,
        const Scaffold(body: FactoryNeedsScreen()),
        overrides: _overrides(_factory(count: 24)),
        at: '/factory/needs',
      );
      s.expectClean(tester);
      expect(find.text(s.v.l.fxNeedPlayAppTitle), findsWidgets, reason: s.where);
      await s.sweep(tester, pageScroll());
    });

    smoke('nothing needs the owner', (tester, s) async {
      await s.show(
        tester,
        const Scaffold(body: FactoryNeedsScreen()),
        overrides: _overrides(_factory(count: 2)),
        at: '/factory/needs',
      );
      s.expectClean(tester);
      expect(find.byKey(const Key('factoryNeedsEmpty')), findsOneWidget, reason: s.where);
    });

    smoke('done and skip tell the Runner', (tester, s) async {
      final fake = _factory(count: 24);
      await s.show(
        tester,
        const Scaffold(body: FactoryNeedsScreen()),
        overrides: _overrides(fake),
        at: '/factory/needs',
      );
      await tester.ensureVisible(find.text(s.v.l.fxNeedsDone).first);
      await tester.tap(find.text(s.v.l.fxNeedsDone).first);
      await tester.pump();
      await tester.ensureVisible(find.text(s.v.l.fxNeedsSkip).first);
      await tester.tap(find.text(s.v.l.fxNeedsSkip).first);
      await tester.pump();
      expect(fake.calls, hasLength(2));
      expect(fake.calls.first, matches(RegExp(r'^resolve:a\d+:\{needId: n\d+\}$')));
      expect(fake.calls.last, matches(RegExp(r'^resolve:a\d+:\{needId: n\d+, skip: true\}$')));
    }, only: [_english]);
  });

  group('a new batch', () {
    smoke('the big box, both ways', (tester, s) async {
      await s.show(
        tester,
        const Scaffold(body: FactoryNewScreen()),
        overrides: _overrides(_factory(count: 0)),
        at: '/factory/new',
      );
      s.expectClean(tester);
      expect(find.byKey(const Key('factoryBox')), findsOneWidget, reason: s.where);
      // Nothing to send yet: the way on is closed.
      expect(tester.widget<FilledButton>(find.byKey(const Key('factoryNext'))).onPressed, isNull, reason: s.where);
      await tester.enterText(find.byKey(const Key('factoryBox')), '$longText\nعربي');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('factoryNext'))).onPressed, isNotNull, reason: s.where);
      s.expectClean(tester, 'typed');
      await tester.tap(find.text(s.v.l.fxModeInvent));
      await tester.pump();
      s.expectClean(tester, 'invent');
      expect(find.byKey(const Key('factoryTheme')), findsOneWidget, reason: s.where);
    });

    smoke('how they are made', (tester, s) async {
      await s.show(
        tester,
        const Scaffold(body: FactoryNewScreen()),
        overrides: _overrides(_factory(count: 0)),
        at: '/factory/new',
      );
      await tester.enterText(find.byKey(const Key('factoryBox')), 'one idea');
      await tester.pump();
      await tester.tap(find.byKey(const Key('factoryNext')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      s.expectClean(tester);
      expect(find.byKey(const Key('factorySafe')), findsOneWidget, reason: s.where);
      for (final goal in Goal.values) {
        expect(find.byKey(Key('factoryGoal_${goal.name}')), findsOneWidget, reason: '${s.where}: ${goal.name}');
      }
      await s.sweep(tester, pageScroll());
    });

    smoke('from the box to the start', (tester, s) async {
      final fake = _factory(count: 0);
      final api = FakeFactoryApi(plan: fakePlanJson(), connections: fakeConnectionsJson);
      await s.show(
        tester,
        const Scaffold(body: FactoryNewScreen()),
        overrides: _overrides(fake, api: api),
        at: '/factory/new',
      );
      await tester.enterText(find.byKey(const Key('factoryBox')), 'garden apps\nwater reminders');
      await tester.pump();
      await tester.tap(find.byKey(const Key('factoryNext')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('factoryNext')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      s.expectClean(tester, 'supervisor');
      // The supervisor was given the text and the engine weights.
      expect(api.planRequests.single['text'], 'garden apps\nwater reminders');
      expect(api.planRequests.single['count'], isNull);
      expect((api.planRequests.single['engines']! as Map).keys, ['claude-code']);

      expect(find.text(s.v.l.fxReviewTitle(6)), findsOneWidget, reason: s.where);
      expect(find.text(s.v.l.fxWarnNoAi), findsOneWidget, reason: s.where);
      expect(find.byKey(const Key('factoryProposal_5')), findsOneWidget, reason: s.where);
      // Leave one out, and make another big.
      final untick = find.descendant(of: find.byKey(const Key('factoryProposal_3')), matching: find.byType(Checkbox));
      await tester.ensureVisible(untick);
      await tester.pump();
      await tester.tap(untick);
      await tester.pump();
      final big = find.descendant(of: find.byKey(const Key('factoryProposal_1')), matching: find.byType(ActionChip));
      await tester.ensureVisible(big);
      await tester.pump();
      await tester.tap(big);
      await tester.pump();
      expect(find.text(s.v.l.fxStartCount(5)), findsOneWidget, reason: s.where);
      await tester.tap(find.byKey(const Key('factoryStart')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // It says plainly that nothing is published, then starts.
      expect(find.text(s.v.l.fxStartBodyStores(10)), findsOneWidget, reason: s.where);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(s.v.l.fxStart)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.calls, hasLength(1));
      final call = fake.calls.single;
      expect(call, startsWith('start:'));
      expect(call, contains('Idea 0|Idea 1|Idea 2|Idea 4|Idea 5'));
      expect(call, isNot(contains('Idea 3')));
      expect(call, contains('goal: android'));
    }, only: [_english]);

    smoke('the supervisor fails', (tester, s) async {
      final api = FakeFactoryApi(
        connections: fakeConnectionsJson,
        planError: RunnerException('no_ai', 'No AI engine is connected'),
      );
      await s.show(
        tester,
        const Scaffold(body: FactoryNewScreen()),
        overrides: _overrides(_factory(count: 0), api: api),
        at: '/factory/new',
      );
      await tester.enterText(find.byKey(const Key('factoryBox')), 'idea');
      await tester.pump();
      await tester.tap(find.byKey(const Key('factoryNext')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('factoryNext')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      s.expectClean(tester);
      expect(find.textContaining('No AI engine is connected'), findsOneWidget, reason: s.where);
      expect(find.text(s.v.l.retry), findsOneWidget, reason: s.where);
    }, only: [_english, _englishWide]);

    smoke('inventing ideas sends the theme and how many', (tester, s) async {
      final api = FakeFactoryApi(plan: fakePlanJson(), connections: fakeConnectionsJson);
      await s.show(
        tester,
        const Scaffold(body: FactoryNewScreen()),
        overrides: _overrides(_factory(count: 0), api: api),
        at: '/factory/new',
      );
      await tester.tap(find.text(s.v.l.fxModeInvent));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('factoryTheme')), 'apps for gardeners');
      await tester.pump();
      await tester.tap(find.byKey(const Key('factoryNext')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('factoryNext')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(api.planRequests.single['text'], 'apps for gardeners');
      expect(api.planRequests.single['count'], 20);
    }, only: [_english]);
  });

  group('connections', () {
    smoke('what is ready and what is not', (tester, s) async {
      await s.show(
        tester,
        const Scaffold(body: FactoryLinksScreen()),
        overrides: _overrides(_factory(count: 3)),
        at: '/factory/links',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      s.expectClean(tester);
      expect(find.text('${engineLabel('qwen-code')} · ${s.v.l.fxWhyNotInstalled}'), findsOneWidget, reason: s.where);
      expect(find.widgetWithText(TextButton, s.v.l.fxConnect), findsNWidgets(2), reason: '${s.where}: Qwen and Gemini can be connected');
      await s.sweep(tester, pageScroll());
    });

    smoke('connecting an engine and changing a limit', (tester, s) async {
      final fake = _factory(count: 3);
      final api = FakeFactoryApi(connections: fakeConnectionsJson);
      await s.show(
        tester,
        const Scaffold(body: FactoryLinksScreen()),
        overrides: _overrides(fake, api: api),
        at: '/factory/links',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(TextButton, s.v.l.fxConnect).first);
      await tester.pump();
      expect(api.signIns, ['gemini-cli'], reason: 'the first one not connected, in the order shown');
      await tester.scrollUntilVisible(find.text(s.v.l.fxLimitsTitle), 300, scrollable: pageScroll());
      await tester.tap(find.byTooltip(s.v.l.fxMore).last);
      await tester.pump();
      expect(fake.calls, ['dailyCap:11']);
    }, only: [_english]);
  });
}
