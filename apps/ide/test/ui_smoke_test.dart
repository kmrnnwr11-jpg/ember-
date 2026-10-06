import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ide/core/runner_socket.dart';
import 'package:ide/core/session.dart';
import 'package:ide/core/theme_mode.dart';
import 'package:ide/features/ai/ai_settings.dart';
import 'package:ide/features/auth/login_screen.dart';
import 'package:ide/features/create/app_builder.dart';
import 'package:ide/features/create/create_app_screen.dart';
import 'package:ide/features/create/hub/hub_widgets.dart';
import 'package:ide/features/create/needs_you_card.dart';
import 'package:ide/features/projects/build_watch.dart';
import 'package:ide/features/projects/history_panel.dart';
import 'package:ide/features/projects/projects_screen.dart';
import 'package:ide/features/settings/settings_screen.dart';
import 'package:ide/l10n/app_localizations.dart';
import 'package:ide/ui/ui.dart';
import 'package:ide_core/ide_core.dart';
import 'package:ai_connect/ai_connect.dart' show AiProviderId;
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

/// Long on purpose: a row that forgot to wrap or to cut its text overflows here, not on a phone.
const longText =
    'This sentence is long on purpose: it runs well past one hundred and fifty characters, so that any row which forgot to wrap or to cut its text overflows in this test and not on a phone.';
const longUrl = 'https://console.cloud.google.com/apis/credentials/consent/edit;newAppInternalUser=false?project=ember-demo-123456';
const arabicText =
    'هذه جملة طويلة عن قصد لاختبار الواجهة: يجب أن تتجاوز مئة وخمسين حرفاً حتى يظهر في الاختبار أي صف نسي أن يلفّ النص أو أن يقصّه، وليس على هاتف المستخدم الصغير بعد النشر.';

const phone = Size(390, 844);
const medium = Size(900, 800);
const wide = Size(1280, 800);

typedef Variant = ({Size size, Locale locale, Brightness brightness});

/// Phone, one side panel, two side panels; left-to-right and right-to-left; dark and light.
final variants = <Variant>[
  for (final size in const [phone, medium, wide])
    for (final code in const ['en', 'ar'])
      for (final brightness in Brightness.values.reversed) (size: size, locale: Locale(code), brightness: brightness),
];

extension on Variant {
  String get name => '${size.width.toInt()}x${size.height.toInt()} ${locale.languageCode} ${brightness.name}';
  bool get rtl => locale.languageCode == 'ar';
  AppLocalizations get l => lookupAppLocalizations(locale);
}

/// One screen at one size, language and theme.
class Smoke {
  Smoke(this.screen, this.v);
  final String screen;
  final Variant v;

  /// Everything reported while building and laying out, with the widget it came from.
  final reported = <FlutterErrorDetails>[];

  String get where => '$screen · ${v.name}';

  /// Puts [child] on screen as the app does: real theme, real strings, a router around it.
  Future<void> show(WidgetTester tester, Widget child, {List<Override> overrides = const [], String at = '/'}) async {
    final router = GoRouter(
      initialLocation: at,
      routes: [GoRoute(path: at, builder: (_, _) => child)],
      // Anywhere else the screen may go: a page that only says where it went.
      errorBuilder: (_, state) => Scaffold(body: Center(child: Text('route ${state.uri}'))),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: emberTheme(v.brightness),
          locale: v.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    // The Ember mark and the spinners animate forever, so pump frames instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Fails when anything was thrown while building or laying out (a RenderFlex overflow, mostly).
  void expectClean(WidgetTester tester, [String step = '']) {
    final thrown = tester.takeException();
    // The first few say it all: one broken layout sets off dozens of follow-up errors.
    final details = [for (final d in reported.take(3)) _short(d), if (reported.length > 3) '(and ${reported.length - 3} more)'].join('\n---\n');
    reported.clear();
    if (thrown == null && details.isEmpty) return;
    fail('$where${step.isEmpty ? '' : ' · $step'}: ${thrown ?? ''}\n$details');
  }

  static String _short(FlutterErrorDetails d) {
    final lines = d.toString().split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.take(14).join('\n');
  }

  /// Walks a lazy list from top to bottom, checking every stretch of it, and
  /// returns which of [keys] (and of the named finders in [also]) were met on
  /// the way. Stops at the bottom.
  Future<Set<String>> sweep(WidgetTester tester, Finder scrollable, {List<String> keys = const [], Map<String, Finder> also = const {}, String step = ''}) async {
    final seen = <String>{};
    final position = tester.state<ScrollableState>(scrollable).position;
    for (var i = 0; i < 100; i++) {
      expectClean(tester, '$step at ${position.pixels.toInt()}');
      seen.addAll(keys.where((k) => find.byKey(Key(k)).evaluate().isNotEmpty));
      seen.addAll(also.keys.where((k) => also[k]!.evaluate().isNotEmpty));
      if (position.pixels >= position.maxScrollExtent) break;
      position.jumpTo(math.min(position.pixels + 300, position.maxScrollExtent));
      await tester.pump();
    }
    return seen;
  }
}

/// Runs [body] once per variant, on a window of that size.
void smoke(String screen, Future<void> Function(WidgetTester tester, Smoke s) body, {List<Variant>? only}) {
  for (final v in only ?? variants) {
    testWidgets('$screen · ${v.name}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = v.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final s = Smoke(screen, v);
      final forward = FlutterError.onError;
      FlutterError.onError = (d) {
        s.reported.add(d);
        forward?.call(d);
      };
      try {
        await body(tester, s);
        // Take everything down while the fakes are alive: timers and animations stop here.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        s.expectClean(tester, 'closing');
      } finally {
        FlutterError.onError = forward;
      }
    });
  }
}

Finder pageScroll() => find.descendant(of: find.byType(PageBody), matching: find.byType(Scrollable)).first;

bool _isControl(Widget w) =>
    w is IconButton ||
    w is FilledButton ||
    w is TextButton ||
    w is OutlinedButton ||
    w is ElevatedButton ||
    w is PopupMenuButton ||
    w is DropdownButton ||
    w is TextField ||
    w is ChoiceChip ||
    w is FilterChip ||
    w is ActionChip ||
    w is InputChip ||
    w is Switch ||
    (w is ListTile && w.onTap != null);

bool _insideControl(Element e) {
  var inside = false;
  e.visitAncestorElements((a) {
    inside = _isControl(a.widget);
    return !inside;
  });
  return inside;
}

/// The things a user can tap or type in: buttons, menus, fields, chips, rows
/// that open something, and any other bare tappable surface. A button's own
/// parts (the icon button inside a menu button) are not counted twice.
List<String> controls(WidgetTester tester, {bool Function(Rect rect)? where}) => [
  for (final e in find.byElementPredicate((e) {
    final w = e.widget;
    final bare = w.runtimeType == InkWell && (w as InkWell).onTap != null;
    return (_isControl(w) || bare) && !_insideControl(e);
  }).evaluate())
    if (where == null || where(tester.getRect(find.byElementPredicate((x) => x == e)))) '${e.widget.runtimeType}${e.widget.key ?? ''}',
];

Widget gallery() {
  final field = TextEditingController();
  final busyField = TextEditingController(text: '$longText $arabicText');
  final secret = TextEditingController(text: 'sk-0123456789abcdef0123456789abcdef0123456789abcdef');
  final certificate = TextEditingController(text: '-----BEGIN PRIVATE KEY-----\n$longUrl\n-----END PRIVATE KEY-----');
  return Scaffold(
    appBar: AppBar(title: const Text('$longText $arabicText')),
    // Not a lazy list: every component is laid out, on screen or not.
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Widths.page),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final tone in Tone.values)
                SectionCard(
                  key: Key('card_${tone.name}'),
                  icon: Icons.fact_check_outlined,
                  title: '${tone.name}: $longText',
                  hint: arabicText,
                  tone: tone,
                  trailing: tone == Tone.neutral ? IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () {}) : Pill(tone.name, tone: tone),
                  children: [
                    Gap.vMd,
                    const BusyRow('$longText $arabicText'),
                    const InlineMessage('$longText $longUrl'),
                    const InlineMessage('$arabicText $longUrl', error: true),
                    const StatusRow(done: true, text: longText),
                    StatusRow(done: false, text: arabicText, trailing: TextButton(onPressed: () {}, child: const Text('Disconnect'))),
                    FindingTile(title: longText, detail: '$arabicText $longUrl', fixable: true, action: TextButton(onPressed: () {}, child: const Text(longText))),
                    const FindingTile(title: arabicText),
                    Gap.vSm,
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.xs,
                      children: [
                        for (final t in Tone.values) Pill('${t.name} $longText', icon: Icons.memory_outlined, tone: t),
                        const Pill(arabicText, onDark: true),
                        const Pill('3'),
                      ],
                    ),
                    Gap.vSm,
                    const StepsList([longText, arabicText, longUrl, 'Short']),
                    StepsList.parse('1. $longText\n2) $arabicText\n\n3. Done'),
                  ],
                ),
              Gap.vLg,
              const ChatBubble(isUser: true, child: SelectableText('$longText $arabicText $longUrl')),
              ChatBubble.text('$longText\n\n$arabicText\n\n$longUrl', avatar: const CircleAvatar(radius: 14, child: Icon(Icons.auto_awesome, size: 16))),
              ChatBubble.text(arabicText, dimmed: true),
              ChatBubble.text('ok', isUser: true),
              Gap.vLg,
              ChatComposer(
                controller: field,
                hint: '$longText $arabicText',
                sendTooltip: 'Send',
                onSend: () {},
                fieldKey: const Key('composerField'),
                sendKey: const Key('composerSend'),
                leading: [IconButton(tooltip: 'Attach', icon: const Icon(Icons.attach_file), onPressed: () {})],
                trailing: [IconButton(tooltip: 'Voice', icon: const Icon(Icons.mic_none), onPressed: () {})],
                above: Wrap(spacing: Gap.sm, children: [for (final name in const ['screenshot-of-the-home-screen-2026-10-05.png', longUrl]) Chip(label: Text(name))]),
              ),
              Gap.vMd,
              ChatComposer(controller: busyField, hint: 'Busy', sendTooltip: 'Send', onSend: () {}, busy: true, onStop: () {}, stopTooltip: 'Stop'),
              Gap.vLg,
              const LogSurface(
                height: 160,
                child: SingleChildScrollView(child: SelectableText('\$ flutter build web --release\n$longUrl\n$longText\n$arabicText')),
              ),
              Gap.vSm,
              LogSurface(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [Icon(Icons.warning_amber_outlined), Gap.hSm, Expanded(child: Text('$longText $longUrl'))],
                ),
              ),
              Gap.vLg,
              const EmptyState(text: '$longText $arabicText'),
              EmptyState(icon: Icons.inbox_outlined, text: arabicText, compact: true, action: FilledButton(onPressed: () {}, child: const Text(longText))),
              ErrorState(key: const Key('errorWithRetry'), message: '$longText $longUrl', onRetry: () {}),
              ErrorState(message: arabicText, onRetry: () {}, retryLabel: longText),
              const ErrorState(message: 'Short'),
              const LoadingState(),
              const LoadingState(text: '$longText $arabicText'),
              Gap.vLg,
              SecretField(controller: secret, label: longText, helper: '$arabicText $longText', hint: 'sk-…', getUrl: longUrl, getLabel: longText),
              Gap.vMd,
              SecretField(controller: certificate, label: arabicText, maxLines: 6),
              Gap.vMd,
              SecretField(controller: field, label: 'Token', obscure: false, enabled: false),
              Gap.vLg,
              for (final onDark in const [false, true])
                TabStrip(
                  items: [
                    for (var i = 0; i < 8; i++)
                      TabStripItem(
                        label: i == 2 ? arabicText : 'lib/features/create/a_rather_long_file_name_$i.dart',
                        icon: i.isEven ? Icons.description_outlined : null,
                        muted: i == 3,
                        status: i == 1 ? const Icon(Icons.circle, size: 8) : null,
                      ),
                  ],
                  selected: 1,
                  onSelect: (_) {},
                  onClose: (_) {},
                  closeTooltip: 'Close',
                  onDark: onDark,
                  trailing: [IconButton(tooltip: 'New', icon: const Icon(Icons.add), onPressed: () {})],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Twelve apps over two weeks, one being created and one that failed, with names of every length.
List<Project> twelveApps() => [
  for (var i = 1; i <= 12; i++)
    fakeProject(
      'p$i',
      switch (i) { 2 => 'a_very_long_project_folder_name_that_goes_on_and_on_and_on_$i', _ => 'app_$i' },
      title: switch (i) { 1 => '$longText $i', 3 => arabicText, _ => null },
      status: switch (i) { 5 => 'creating', 6 => 'error', _ => 'ready' },
      age: Duration(hours: 30 * (i - 1)),
    ),
];

List<Draft> twoDrafts() => [
  Draft(id: 'd1', prompt: '$longText\nsecond line', updatedAt: DateTime.now()),
  Draft(id: 'd2', prompt: arabicText, updatedAt: DateTime.now().subtract(const Duration(days: 1))),
];

void main() {
  smoke('shared components', (tester, s) async {
    await s.show(tester, gallery());
    s.expectClean(tester);
    for (final tone in Tone.values) {
      expect(find.byKey(Key('card_${tone.name}')), findsOneWidget, reason: s.where);
    }
    for (final type in const [SectionCard, BusyRow, InlineMessage, StatusRow, FindingTile, Pill, StepsList, ChatBubble, ChatComposer, LogSurface, EmptyState, ErrorState, LoadingState, SecretField, TabStrip]) {
      expect(find.byType(type), findsWidgets, reason: '${s.where}: $type');
    }
    expect(find.descendant(of: find.byKey(const Key('errorWithRetry')), matching: find.text(s.v.l.retry)), findsOneWidget, reason: s.where);
    expect(find.byKey(const Key('composerField')), findsOneWidget, reason: s.where);
    expect(find.byKey(const Key('composerSend')), findsOneWidget, reason: s.where);
    // Nothing may be wider than the window.
    for (final type in const [SectionCard, ChatBubble, ChatComposer, LogSurface, SecretField, TabStrip]) {
      for (final e in find.byType(type).evaluate()) {
        final rect = tester.getRect(find.byElementPredicate((x) => x == e));
        expect(rect.left >= 0 && rect.right <= s.v.size.width, isTrue, reason: '${s.where}: $type spans ${rect.left}..${rect.right}');
      }
    }
    // Typing a long message makes the composer taller, not wider.
    await tester.enterText(find.byKey(const Key('composerField')), '$longText\n$arabicText\n$longUrl');
    await tester.pump();
    s.expectClean(tester, 'after typing');
  });

  smoke('login', (tester, s) async {
    await s.show(tester, const LoginScreen(), overrides: [keyValueStoreProvider.overrideWithValue(MemoryStore()), sessionProvider.overrideWith(() => FakeSession(null))], at: '/login');
    s.expectClean(tester);
    expect(find.text('EMBER'), findsOneWidget, reason: s.where);
    expect(find.byKey(const Key('signIn')), findsOneWidget, reason: s.where);
    expect(find.byKey(const Key('email')), findsOneWidget, reason: s.where);
    expect(find.byKey(const Key('runnerUrl')), findsNothing, reason: '${s.where}: the Runner address starts folded away');

    await tester.tap(find.byKey(const Key('loginAdvanced')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    s.expectClean(tester, 'advanced open');
    expect(find.byKey(const Key('runnerUrl')), findsOneWidget, reason: s.where);

    // A wrong email shows its message under the field.
    await tester.ensureVisible(find.byKey(const Key('signIn')));
    await tester.tap(find.byKey(const Key('signIn')));
    await tester.pump();
    s.expectClean(tester, 'invalid email');
    expect(find.text(s.v.l.invalidEmail), findsOneWidget, reason: s.where);
  });

  for (final full in const [false, true]) {
    smoke(full ? 'home with 12 apps and 2 drafts' : 'home with no apps', (tester, s) async {
      final apps = full ? twelveApps() : <Project>[];
      await s.show(
        tester,
        const ProjectsScreen(),
        at: '/projects',
        overrides: signedIn(
          projects: apps,
          drafts: full ? twoDrafts() : const [],
          live: full ? const {'p4': BuildState(building: true, files: 3, plannedFiles: 32, needsYou: ['Sign in to Firebase'])} : const {},
        ),
      );
      s.expectClean(tester);
      for (final key in const ['appPrompt', 'createAppButton', 'engineOptions']) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: '${s.where}: $key');
      }

      // One list of apps, never two.
      expect(find.byType(HistoryList), findsOneWidget, reason: s.where);
      for (final p in apps) {
        expect(find.byKey(Key('history_${p.id}')), findsOneWidget, reason: '${s.where}: row of ${p.id}');
      }
      if (full) expect(find.byKey(const Key('draft_d1')), findsOneWidget, reason: s.where);
      if (!full) expect(find.text(s.v.l.historyEmpty), findsOneWidget, reason: s.where);

      final prompt = tester.getRect(find.byKey(const Key('appPrompt')));
      final list = tester.getRect(find.byType(HistoryList));
      if (s.v.size.width >= Breakpoints.expanded) {
        // Room for a column: the history sits beside the prompt box, at the start side.
        final newApp = tester.getRect(find.byKey(const Key('historyNewApp')));
        expect(s.v.rtl ? newApp.left >= prompt.right : newApp.right <= prompt.left, isTrue, reason: '${s.where}: history $newApp, prompt $prompt');
        expect(s.v.rtl ? list.left >= prompt.right : list.right <= prompt.left, isTrue, reason: '${s.where}: list $list, prompt $prompt');
      } else {
        // No room: the same list under the prompt box, and no drawer hiding it.
        expect(find.byKey(const Key('historyNewApp')), findsNothing, reason: s.where);
        expect(list.top >= prompt.bottom, isTrue, reason: '${s.where}: list $list, prompt $prompt');
        expect(find.byType(Drawer), findsNothing, reason: s.where);
        expect(find.byKey(const Key('openHistory')), findsNothing, reason: s.where);
        for (final scaffold in tester.widgetList<Scaffold>(find.byType(Scaffold))) {
          expect(scaffold.drawer, isNull, reason: s.where);
          expect(scaffold.endDrawer, isNull, reason: s.where);
        }
      }

      if (s.v.size == phone) {
        // What a newcomer has to take in before reaching their apps.
        final before = controls(tester, where: (r) => r.center.dy < list.top);
        expect(before.length, lessThanOrEqualTo(6), reason: '${s.where}: ${before.length} controls before the list: $before');
      }

      await s.sweep(tester, pageScroll(), step: 'page');
      tester.state<ScrollableState>(pageScroll()).position.jumpTo(0);
      await tester.pump();

      // Who builds the app: one tap away, and one tap to come back.
      await tester.tap(find.byKey(const Key('engineOptions')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      s.expectClean(tester, 'options open');
      for (final engine in const ['gemini', 'claudeCode', 'codex']) {
        expect(find.byKey(Key('engine_$engine')), findsOneWidget, reason: '${s.where}: engine_$engine');
      }
      final sheet = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first;
      for (final rect in [tester.getRect(find.byType(BottomSheet)), for (final e in find.byType(ChoiceChip).evaluate()) tester.getRect(find.byElementPredicate((x) => x == e))]) {
        expect(rect.left >= 0 && rect.right <= s.v.size.width, isTrue, reason: '${s.where}: options sheet spans ${rect.left}..${rect.right}');
      }
      // Each engine shows something different under the chips.
      for (final engine in const ['claudeCode', 'codex', 'claude', 'gemini']) {
        tester.state<ScrollableState>(sheet).position.jumpTo(0);
        await tester.pump();
        await tester.tap(find.byKey(Key('engine_$engine')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await s.sweep(tester, sheet, step: 'options with $engine');
      }
      expect(find.byKey(const Key('design_gemini_runner')), findsOneWidget, reason: s.where);
      await tester.tap(find.byKey(const Key('engineOptionsDone')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      s.expectClean(tester, 'options closed');
      expect(find.byKey(const Key('engine_gemini')), findsNothing, reason: '${s.where}: the options sheet is closed');
      expect(find.byKey(const Key('appPrompt')), findsOneWidget, reason: s.where);
    });
  }

  // Apart from the tests above, so that what it finds does not hide the rest of the home screen.
  smoke('home options, no subscription connected', (tester, s) async {
    const nothingConnected = <String, dynamic>{
      'engines': {'claudeCode': false, 'serverGemini': true, 'codex': false, 'geminiCli': false},
    };
    await s.show(tester, const ProjectsScreen(), at: '/projects', overrides: signedIn(health: nothingConnected));
    s.expectClean(tester);
    await tester.tap(find.byKey(const Key('engineOptions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Gemini is chosen: the sheet offers to connect the Google subscription instead.
    s.expectClean(tester, 'options open');
    final sheet = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first;
    for (final engine in const ['claudeCode', 'codex', 'geminiCli', 'claude', 'openai', 'xai', 'deepseek', 'qwen', 'gemini']) {
      tester.state<ScrollableState>(sheet).position.jumpTo(0);
      await tester.pump();
      await tester.tap(find.byKey(Key('engine_$engine')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await s.sweep(tester, sheet, step: 'options with $engine');
    }
  });

  for (final state in AppState.values) {
    smoke('app home ${state.name}', (tester, s) async {
      final apps = twelveApps();
      final app = (await tester.runAsync(() => BuiltApp.at(state, projectId: 'p1', projectName: 'app_1', prompt: '$longText\n$arabicText', locale: s.v.locale, designName: 'Aurora Borealis over a Midnight Glass Lake')))!;
      final b = app.builder;
      try {
        expect(b.phase, switch (state) { AppState.building => BuildPhase.dependencies, AppState.ready => BuildPhase.ready, AppState.failed => BuildPhase.failed }, reason: '${s.where}: ${b.error}');
        b.conversation
          ..add((role: 'user', text: '$longText $longUrl'))
          ..add((role: 'assistant', text: '## Done\n\n$longText\n\n- $arabicText\n- [the console]($longUrl)\n\n```\n$longUrl\n```'));
        b.note('$longText $longUrl');
        if (state == AppState.failed) b.needsYou.add('$longText $arabicText');

        await s.show(tester, const CreateAppScreen(projectId: 'p1'), at: '/projects/p1/create', overrides: [...signedIn(projects: apps), appBuilderProvider.overrideWith((ref, key) => b)]);
        s.expectClean(tester);
        expect(find.byKey(const Key('toggleAssistant')), findsOneWidget, reason: s.where);
        if (s.v.size.width >= Breakpoints.expanded) {
          expect(find.byKey(const Key('historyNewApp')), findsOneWidget, reason: s.where);
          expect(find.byKey(const Key('history_p2')), findsOneWidget, reason: s.where);
          expect(find.byKey(const Key('openHistory')), findsNothing, reason: s.where);
        } else {
          expect(find.byKey(const Key('openHistory')), findsOneWidget, reason: s.where);
          expect(find.byKey(const Key('historyNewApp')), findsNothing, reason: s.where);
        }

        const rows = ['step_test', 'step_images', 'step_checks', 'step_play', 'step_appStore', 'step_more'];
        final seen = await s.sweep(tester, pageScroll(), keys: const ['openPreview', 'stopBuild', 'resumeBuild', 'retryBuild', 'toggleLog', ...rows], also: {'prompt': find.byType(PromptCard), 'needsYou': find.descendant(of: find.byType(NeedsYouCard), matching: find.byType(SectionCard))}, step: 'page');
        expect(seen, containsAll(['prompt', 'toggleLog']), reason: s.where);
        expect(seen.contains('needsYou'), state == AppState.failed, reason: s.where);
        switch (state) {
          case AppState.building:
            expect(seen, contains('stopBuild'), reason: s.where);
            expect(seen.intersection(rows.toSet()), isEmpty, reason: '${s.where}: nothing to do next while it is being built');
            expect(find.byKey(const Key('nextRequest')), findsNothing, reason: s.where);
          case AppState.ready:
            expect(seen, containsAll(['openPreview', ...rows]), reason: s.where);
            expect(find.byKey(const Key('nextRequest')), findsOneWidget, reason: s.where);
            expect(find.byKey(const Key('sendRequest')), findsOneWidget, reason: s.where);
          case AppState.failed:
            expect(seen, containsAll(['resumeBuild', 'retryBuild']), reason: s.where);
            expect(find.byKey(const Key('nextRequest')), findsOneWidget, reason: s.where);
        }

        // The raw log, for whoever opens it.
        await tester.tap(find.byKey(const Key('toggleLog')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(BuildLogView), findsOneWidget, reason: s.where);
        await s.sweep(tester, pageScroll(), step: 'log open');

        // On a narrow window the history is a drawer here.
        if (s.v.size.width < Breakpoints.expanded) {
          await tester.tap(find.byKey(const Key('openHistory')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          s.expectClean(tester, 'history drawer');
          expect(find.byKey(const Key('historyNewApp')), findsOneWidget, reason: s.where);
          expect(find.byKey(const Key('history_p2')), findsOneWidget, reason: s.where);
        }

        if (state == AppState.building) {
          // Stopping the build turns the progress into "stopped", with a way to start again.
          await tester.runAsync(app.stop);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(b.phase, BuildPhase.cancelled, reason: s.where);
          await s.sweep(tester, pageScroll(), step: 'stopped');
        }
      } finally {
        if (b.running) await tester.runAsync(app.stop);
      }
    });
  }

  // Everything is laid out on a window this tall, so the count does not depend on scrolling.
  smoke('app home ready, controls', only: [
    for (final code in const ['en', 'ar']) (size: const Size(390, 2400), locale: Locale(code), brightness: Brightness.dark),
  ], (tester, s) async {
    final app = (await tester.runAsync(() => BuiltApp.at(AppState.ready, projectId: 'p1', projectName: 'app_1', prompt: longText, locale: s.v.locale)))!;
    await s.show(tester, const CreateAppScreen(projectId: 'p1'), at: '/projects/p1/create', overrides: [...signedIn(projects: twelveApps()), appBuilderProvider.overrideWith((ref, key) => app.builder)]);
    s.expectClean(tester);
    final all = controls(tester);
    for (final row in const ['step_test', 'step_images', 'step_checks', 'step_play', 'step_appStore', 'step_more']) {
      expect(find.byKey(Key(row)), findsOneWidget, reason: '${s.where}: $row');
    }
    // Top bar 3, "Open app" 1, six next-step rows, technical details 1, the change box 2.
    expect(all.length, lessThanOrEqualTo(13), reason: '${s.where}: ${all.length} controls on a finished app: $all');
  });

  smoke('settings', (tester, s) async {
    await s.show(tester, const SettingsScreen(), at: '/settings', overrides: signedIn(ai: const AiSettings(keys: {AiProviderId.gemini: 'AIzaSy-0123456789abcdef-1234'})));
    s.expectClean(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));
    expect(find.byKey(const Key('language_it')), findsOneWidget, reason: s.where);
    expect(find.byKey(const Key('theme_light')), findsOneWidget, reason: s.where);

    // Light is the default; the choice is the user's.
    expect(container.read(themeModeProvider), ThemeMode.light, reason: s.where);
    await tester.tap(find.byKey(const Key('theme_dark')));
    await tester.pump();
    expect(container.read(themeModeProvider), ThemeMode.dark, reason: s.where);
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('theme_dark'))).selected, isTrue, reason: s.where);
    s.expectClean(tester, 'theme chosen');

    final seen = await s.sweep(tester, pageScroll(), keys: const ['language_it', 'theme_light', 'key_gemini', 'settingsAdvanced', 'signOut'], step: 'page');
    expect(seen, containsAll(['key_gemini', 'settingsAdvanced', 'signOut']), reason: s.where);

    await tester.tap(find.byKey(const Key('settingsAdvanced')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await s.sweep(tester, pageScroll(), step: 'advanced open');
    expect(find.text(fakeRunnerUrl), findsOneWidget, reason: s.where);
  });

  smoke('job log dialog', (tester, s) async {
    final socket = FakeRunnerSocket(initial: SocketState.connected);
    await s.show(tester, Scaffold(body: JobLogDialog(title: s.v.l.creatingProject('a_very_long_project_folder_name_that_goes_on_and_on_and_on'), jobId: 'j1')), overrides: signedIn(socket: socket, api: FakeRunnerApi(priorLog: '\$ flutter create .\n$longUrl\n')));
    s.expectClean(tester, 'working');
    expect(find.byKey(const Key('jobLogDetails')), findsOneWidget, reason: s.where);
    expect(find.byType(LogSurface), findsNothing, reason: '${s.where}: the log starts folded away');

    await tester.tap(find.byKey(const Key('jobLogDetails')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    s.expectClean(tester, 'log open');
    final log = tester.getRect(find.byType(LogSurface));
    expect(log.left >= 0 && log.right <= s.v.size.width, isTrue, reason: '${s.where}: log spans ${log.left}..${log.right}');
    expect(find.textContaining('flutter create'), findsOneWidget, reason: '${s.where}: what was logged before the dialog opened');

    for (var i = 0; i < 40; i++) {
      socket.push(MsgType.jobLog, {'jobId': 'j1', 'chunk': 'line $i $longText\n'});
    }
    socket.push(MsgType.jobLog, {'jobId': 'someone-else', 'chunk': 'NOT MINE'});
    socket.push(MsgType.jobStatus, {'jobId': 'j1', 'kind': 'create', 'status': 'failed', 'exitCode': 1});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    s.expectClean(tester, 'failed');
    expect(find.textContaining('NOT MINE'), findsNothing, reason: s.where);
    expect(find.widgetWithText(FilledButton, s.v.l.cancel), findsOneWidget, reason: s.where);
    final dialog = tester.getRect(find.descendant(of: find.byType(AlertDialog), matching: find.byType(Material)).first);
    expect(dialog.left >= 0 && dialog.right <= s.v.size.width && dialog.bottom <= s.v.size.height, isTrue, reason: '${s.where}: dialog $dialog');
  });
}
