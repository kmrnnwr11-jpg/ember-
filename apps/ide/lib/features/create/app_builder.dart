import 'dart:async';
import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/widgets.dart';
import 'package:ide_core/ide_core.dart';

import '../../l10n/app_localizations.dart';
import '../editor/project_controller.dart' show RunnerRequest;

/// Which AI builds the app (§1B "Crea App").
enum BuildEngine {
  gemini(AiProviderId.gemini, 'gemini-3.8-flash', 65536),
  openai(AiProviderId.openai, 'gpt-5', 64000),
  xai(AiProviderId.xai, 'grok-4', 32000),
  claude(AiProviderId.anthropic, 'claude-opus-5', 64000),
  claudeCode(null, null, 0, cli: 'claude-code'),
  // Subscriptions logged in on the Runner machine: ChatGPT plan (Codex CLI), Google account (Gemini CLI).
  codex(null, null, 0, cli: 'codex'),
  geminiCli(null, null, 0, cli: 'gemini-cli');

  const BuildEngine(this.provider, this.defaultModel, this.maxTokens, {this.cli});
  final AiProviderId? provider;
  final String? defaultModel;
  final int maxTokens;

  /// Runner CLI engine id for subscription engines.
  final String? cli;

  bool get isCli => cli != null;

  /// Display name of subscription engines.
  String get cliLabel => switch (this) {
    codex => 'Codex (ChatGPT)',
    geminiCli => 'Gemini CLI',
    _ => 'Claude Code',
  };
}

enum BuildPhase { idle, generating, dependencies, checking, fixing, building, ready, failed, cancelled }

class BuildLogLine {
  const BuildLogLine(this.text, {this.kind = 'info'});
  final String text;

  /// `info` | `file` | `tool` | `error` | `ai`.
  final String kind;
}

const appBuildSystemPrompt = '''
You are an expert Flutter engineer building a real app for a non-technical user who talks to you through a phone chat.
The project was created with `flutter create`; you replace/extend its content. Follow-up messages are change requests on the same app: keep what works and extend it.

Output format (strict):
- Start your answer with one line `PLAN_FILES: <n>`: how many files you will output.
- Output every created or changed file as a fenced code block whose info string is the language followed by the project-relative path, e.g.
```dart lib/main.dart
...complete file...
```
- On the first build always include `pubspec.yaml` (keep `name:` unchanged, sdk constraint `^3.9.0`, `flutter: uses-material-design: true`), `lib/main.dart` and `test/widget_test.dart` (minimal test that compiles).
- Only write files under lib/, test/, assets/ or pubspec.yaml. Every file must be complete: no placeholders, no "...", no TODO in place of logic.
- AFTER the last file, write the reply to the user (in their language, Markdown):
## Fatto
- what now works
## Da configurare
numbered step-by-step instructions for every external service still missing: full URL to open, what account/project to create, what to click, which values to copy and exactly what to paste back in the chat. Use the ANDROID APP INFO when provided (package name, SHA-1). Write "Niente da configurare" if nothing is needed.
## Prossimi passi suggeriti
- 2-4 concrete ideas
Then one professional question inviting the next request.

What to build:
- ADS (only when the user asks for ads/AdMob): use the google_mobile_ads package with the Google UMP consent form (required in the EU) shown before loading ads, the ad formats the user asked for (banner, interstitial with frequency capping, rewarded) placed where they do not break the UX, and no ads for users who bought premium. Keep the IDs in lib/config/ads_config.dart: AdMob app id and one ad unit id per format, defaulting to Google's official TEST ids so the app works before real ids exist; put the app id in android/app/src/main/AndroidManifest.xml (com.google.android.gms.ads.APPLICATION_ID) and ios/Runner/Info.plist (GADApplicationIdentifier). On web show nothing. When the user pastes real AdMob ids, write them in ads_config.dart and the manifests. At the very end of the final reply add ONE line starting with EMBER_ADS: followed by compact JSON listing the formats used, e.g. EMBER_ADS: {"banner":true,"interstitial":true,"rewarded":false}. Omit the line when the app has no ads.
- SCREENSHOT MODE (always include): on web, when the URL has the query parameter ember_screen=N (N = 0..5), open directly the app's N-th most representative screen (home, main feature, detail, list, profile/settings, premium…), filled with realistic demo content, skipping splash, login, onboarding and "configuration needed" screens, without dialogs or debug banners. Read it with Uri.base.queryParameters['ember_screen'] and keep the screen list in lib/config/screenshot_screens.dart. Normal launches are unchanged.
- PAYMENTS (only when the user asks for paid features, subscriptions, premium, packs or coins): implement Google Play Billing with the `in_app_purchase` package: a polished paywall screen with the products and prices loaded from the store, buy, restore purchases, pending/error states, entitlement saved locally that unlocks the paid features, and complete purchases (consumables for coins/packs). On web show that purchases are available in the Android app. Keep product ids in lib/config/monetization.dart. At the very end of the final reply add ONE line starting with EMBER_PRODUCTS: followed by a compact JSON array of every product the app uses, e.g. EMBER_PRODUCTS: [{"id":"premium_monthly","type":"subscription","title":"Premium","description":"All features","price":"4.99","currency":"EUR","period":"P1M","freeTrialDays":7},{"id":"coins_100","type":"inapp","title":"100 coins","description":"Coin pack","price":"0.99","currency":"EUR"}] (ids lowercase a-z 0-9 _ ; period P1W/P1M/P3M/P6M/P1Y; prices the user asked for, otherwise sensible ones). Omit the line when the app has no purchases.
- A complete, real product for the kind of app requested, not a single screen or a demo. For product-type apps include the core feature set users expect (e.g. a chat/dating app like Badoo: sign-up/login with email and Google, profile with photo, discovery/user list, conversations, private 1-to-1 chats and private rooms, real-time messages, logout). Simple utilities stay simple.
- Large extras not requested (video calls, payments…) are suggested in "Prossimi passi", not built.
- Real integrations only: Firebase Auth (email + Google Sign-In), Cloud Firestore, Firebase Storage, Agora or Jitsi for video, Firebase Messaging, Stripe, Google Maps. Never invent keys: keep all keys in lib/config/app_config.dart with empty defaults, initialize services only when configured, and show an in-app "Configurazione necessaria" screen describing what is missing so the app still runs. Initialize Firebase with FirebaseOptions from AppConfig (no flutterfire CLI). When the user pastes keys, write them into AppConfig.
- UI text in the user's language, polished Material 3 (or the APPROVED DESIGN when given). Must compile for web and Android; avoid code generation (no build_runner). Make sure every import resolves.''';

/// Instruction that makes the AI finish a build interrupted by closing the app.
String resumeRequest(String pending) => '''The previous build was interrupted (the app was closed) before it finished.
Continue exactly where it stopped: look at the files that already exist, create every file that is still missing, complete the unfinished ones, and make the whole app work as requested. Do not start over and do not remove working code.

Request being built:
$pending''';

String fixPrompt(String original, Map<String, String> files, String problems) {
  final buf = StringBuffer()
    ..writeln('The app requested was:')
    ..writeln(original)
    ..writeln()
    ..writeln('Current project files:');
  files.forEach((path, content) {
    buf
      ..writeln('```${ProjectPath.languageOf(path)} $path')
      ..writeln(content)
      ..writeln('```');
  });
  buf
    ..writeln()
    ..writeln('Running the Flutter toolchain reported these problems:')
    ..writeln(problems)
    ..writeln()
    ..writeln('Fix them. Output ONLY the complete corrected content of every file you change, in the same fenced format with paths. Do not output unchanged files. No reply sections.');
  return buf.toString();
}

String improvePrompt(String original, Map<String, String> files, String change) {
  final buf = StringBuffer()
    ..writeln('The app was built from this request:')
    ..writeln(original)
    ..writeln()
    ..writeln('Current project files:');
  files.forEach((path, content) {
    buf
      ..writeln('```${ProjectPath.languageOf(path)} $path')
      ..writeln(content)
      ..writeln('```');
  });
  buf
    ..writeln()
    ..writeln('The user now asks for this change:')
    ..writeln(change)
    ..writeln()
    ..writeln('Apply it. Output the complete content of every file you create or change, in the same fenced format with paths, then the reply sections (Fatto / Da configurare / Prossimi passi suggeriti).');
  return buf.toString();
}

/// Orchestrates "prompt → working app → preview" for one project.
///
/// API engines: generate files → pub get → analyze → fix loop (max
/// [maxFixRounds]) → web build. Claude Code: the CLI edits and verifies the
/// project itself on the Runner, then the web build runs.
class AppBuilder extends ChangeNotifier {
  AppBuilder({
    required this.projectId,
    required this.projectName,
    required RunnerRequest request,
    required Stream<WsFrame> events,
    required Future<String> Function(String jobId) fetchJobLog,
    required Future<AiProvider> Function(AiModel model) resolveProvider,
    this.androidInfo,
    this.saveReferenceShots,
    this.onSession,
    AppLocalizations? strings,
    this.maxFixRounds = 3,
    this.jobTimeout = const Duration(minutes: 15),
    this.pollInterval = const Duration(seconds: 10),
  }) : _request = request,
       _events = events,
       _fetchJobLog = fetchJobLog,
       _resolve = resolveProvider,
       strings = strings ?? lookupAppLocalizations(const Locale('en'));

  final String projectId;
  final String projectName;
  final RunnerRequest _request;
  final Stream<WsFrame> _events;
  final Future<String> Function(String jobId) _fetchJobLog;
  final Future<AiProvider> Function(AiModel model) _resolve;

  /// Returns a text block with package name and SHA-1s (for Firebase/Google Sign-In).
  final Future<String?> Function()? androidInfo;

  /// Puts the reference app's Play Store screenshots inside the project, so the
  /// engine copies screens it has seen instead of screens it imagined.
  final Future<int> Function(String playAppId)? saveReferenceShots;
  /// UI language for log lines and errors; updated when the user switches language.
  AppLocalizations strings;
  /// Called with [toSession] whenever the chat changes, so the app can be reopened later.
  final void Function(Map<String, dynamic> session)? onSession;
  final int maxFixRounds;
  final Duration jobTimeout;

  /// How often running work is re-checked on the Runner, in case push events were missed.
  final Duration pollInterval;

  BuildPhase phase = BuildPhase.idle;
  BuildEngine? engine;
  AiModel? model;
  String prompt = '';
  final List<BuildLogLine> log = [];
  final StringBuffer liveText = StringBuffer();
  final Set<String> writtenFiles = {};
  int fixRound = 0;
  double costUsd = 0;
  String? error;
  PreviewInfo? preview;
  String? summary;

  /// Play products the AI declared (`EMBER_PRODUCTS: [...]`), to activate on Google Play.
  List<Map<String, dynamic>> products = [];

  /// Ad formats the AI put in the app (`EMBER_ADS: {...}`), for the AdMob guide.
  Map<String, dynamic>? ads;

  static final _adsRe = RegExp(r'^\s*EMBER_ADS:\s*(\{.*\})\s*$', multiLine: true);

  static final _productsRe = RegExp(r'^\s*EMBER_PRODUCTS:\s*(\[.*\])\s*$', multiLine: true);

  /// Removes the EMBER_PRODUCTS line from a reply and keeps the products.
  String _takeProducts(String reply) {
    final m = _productsRe.firstMatch(reply);
    if (m != null) {
      try {
        final list = (jsonDecode(m.group(1)!) as List).whereType<Map<String, dynamic>>().toList();
        if (list.isNotEmpty) products = list;
      } catch (_) {}
    }
    var out = reply.replaceFirst(_productsRe, '').trim();
    final a = _adsRe.firstMatch(out);
    if (a != null) {
      try {
        ads = jsonDecode(a.group(1)!) as Map<String, dynamic>;
      } catch (_) {}
      out = out.replaceFirst(_adsRe, '').trim();
    }
    return out;
  }

  /// Files the AI announced it will write (`PLAN_FILES: n`), when known.
  int? expectedFiles;

  /// When the current build started (for the estimated time).
  DateTime? startedAt;

  static final _planRe = RegExp(r'PLAN_FILES:\s*(\d{1,3})');

  void _readPlan(String text) {
    if (expectedFiles != null) return;
    final m = _planRe.firstMatch(text);
    if (m != null) expectedFiles = int.parse(m.group(1)!);
  }

  /// Latest action reported by Claude Code (e.g. "Write lib/main.dart").
  String? currentAction;

  /// Claude Code only: `fast` (default) or `best`.
  String quality = 'fast';

  /// The chat with the user: their requests and the AI's replies (Markdown).
  final List<({String role, String text})> conversation = [];

  /// Chosen mockup brief (hidden from the UI, sent to the AI).
  String? design;
  String? designName;

  String? _replyText;

  Future<String> _androidBlock() async {
    try {
      final info = await androidInfo?.call();
      return info == null ? '' : '\n\n$info';
    } catch (_) {
      return '';
    }
  }

  bool _cancelled = false;
  Completer<void> _cancelSignal = Completer<void>();

  /// Waits for [f] unless the build is cancelled first.
  Future<T> _orCancel<T>(Future<T> f) async {
    await Future.any<Object?>([f, _cancelSignal.future]);
    _checkCancelled();
    return f;
  }
  StreamSubscription<AiEvent>? _aiSub;
  String? _currentJobId;
  String? _agentRunId;

  bool get running => const {BuildPhase.generating, BuildPhase.dependencies, BuildPhase.checking, BuildPhase.fixing, BuildPhase.building}.contains(phase);

  void _log(String text, {String kind = 'info'}) {
    log.add(BuildLogLine(text, kind: kind));
    if (log.length > 2000) log.removeRange(0, log.length - 2000);
    notifyListeners();
  }

  void _setPhase(BuildPhase p) {
    phase = p;
    notifyListeners();
  }

  /// Starts a build from scratch.
  Future<void> build({
    required String prompt,
    required BuildEngine engine,
    AiModel? model,
    String quality = 'fast',
    String? design,
    String? designName,
    String? referenceId,
    List<String> referenceTopics = const [],
  }) {
    this.quality = quality;
    this.design = design;
    this.designName = designName;
    this.referenceId = referenceId;
    this.referenceTopics = referenceTopics;
    _coverageChecked = false;
    return _run(prompt: prompt, engine: engine, model: model, change: null);
  }

  /// The Play Store app being copied, and the subjects its listing promises.
  String? referenceId;
  List<String> referenceTopics = const [];
  bool _coverageChecked = false;

  /// A subject is covered when some file written for the app is named after it.
  static String slug(String topic) => topic.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '');

  /// Subjects from the reference listing that no written file answers for.
  List<String> missingTopics() {
    if (referenceTopics.isEmpty || writtenFiles.isEmpty) return const [];
    final written = writtenFiles.map((f) => slug(f)).join(' ');
    return [
      for (final topic in referenceTopics)
        // First word is enough: "Fruits and Vegetables" lives in fruits_screen.dart.
        if (!written.contains(slug(topic.split(RegExp(r'[ /&]')).first)) && !written.contains(slug(topic))) topic,
    ];
  }

  /// Applies a follow-up change to an already built app.
  Future<void> improve(String change, {String? display}) {
    final e = engine;
    if (e == null) return Future.value();
    return _run(prompt: prompt, engine: e, model: model, change: change, display: display);
  }

  /// Request being worked on and whether it finished: lets a closed app resume where it stopped.
  String? _pending;
  String _status = 'idle';

  Future<void> _run({required String prompt, required BuildEngine engine, AiModel? model, String? change, String? display}) async {
    if (running) return;
    _pending = change ?? prompt;
    _status = 'building';
    this.prompt = prompt;
    this.engine = engine;
    this.model = model;
    _cancelled = false;
    _cancelSignal = Completer<void>();
    error = null;
    fixRound = 0;
    expectedFiles = null;
    startedAt = DateTime.now();
    liveText.clear();
    if (change == null) {
      log.clear();
      writtenFiles.clear();
      costUsd = 0;
      preview = null;
      conversation
        ..clear()
        ..add((role: 'user', text: prompt));
    } else {
      conversation.add((role: 'user', text: display ?? change));
    }
    _replyText = null;
    // Saved right away: if the app is closed mid-build, reopening the project picks the work up again.
    _saveSession();
    try {
      // Seeing the app being copied beats reading about it: the screenshots go
      // into the project before a single line is written.
      final refId = referenceId;
      if (change == null && refId != null && saveReferenceShots != null) {
        final saved = await saveReferenceShots!(refId).catchError((_) => 0);
        _log(saved > 0 ? strings.bReferenceShots(saved) : strings.bReferenceShotsFailed, kind: saved > 0 ? 'info' : 'error');
      }
      if (engine.isCli) {
        await _runClaudeCode('${change ?? '$prompt${design ?? ''}'}${await _androidBlock()}', resume: change != null);
      } else {
        await _runApiEngine(change: change);
      }
      if (_cancelled) return;
      await _buildUntilItWorks();
      if (_cancelled) return;
      conversation.add((role: 'assistant', text: _replyText?.trim().isNotEmpty == true ? _replyText!.trim() : strings.bAppUpdated));
      _status = 'done';
      _setPhase(BuildPhase.ready);
      _saveSession();
      _log(strings.bAppReady, kind: 'info');
      // An app copied from a listing is only done when every subject of that
      // listing exists: one automatic round finishes what the engine left out.
      if (change == null && !_coverageChecked) {
        _coverageChecked = true;
        final missing = missingTopics();
        if (missing.isNotEmpty && !_cancelled) {
          _log(strings.bMissingTopics(missing.join(', ')), kind: 'error');
          await improve(
            'The app is missing these subjects from the reference listing: ${missing.join(', ')}. '
            'Add one screen for each, reachable from the home screen, with real content and at least two things to do in it, '
            'drawn in code like the screens that already exist. Keep everything already built.',
            display: strings.bMissingTopics(missing.join(', ')),
          );
        }
      }
    } on _Cancelled {
      _status = 'cancelled';
      _saveSession();
      _setPhase(BuildPhase.cancelled);
    } catch (e) {
      if (_cancelled) {
        _status = 'cancelled';
        _saveSession();
        _setPhase(BuildPhase.cancelled);
        return;
      }
      _status = 'failed';
      error = e is AiException ? e.message : (e is RunnerException ? e.message : e.toString());
      conversation.add((role: 'assistant', text: '⚠️ $error'));
      _log(error!, kind: 'error');
      _setPhase(BuildPhase.failed);
      _saveSession();
    }
  }

  // ---------------------------------------------------------------- sessions

  void _saveSession() {
    if (engine != null) onSession?.call(toSession());
  }

  /// Everything needed to continue working on the app later.
  Map<String, dynamic> toSession() => {
    'prompt': prompt,
    'engine': engine?.name,
    'modelKey': model?.key,
    'quality': quality,
    'design': design,
    'designName': designName,
    'status': _status,
    'products': products,
    'ads': ads,
    'pending': _pending,
    'conversation': [
      for (final m in conversation.length > 60 ? conversation.sublist(conversation.length - 60) : conversation) {'role': m.role, 'text': m.text},
    ],
  };

  /// Reopens an app built earlier: restores the chat and rebuilds the preview, like opening a project on a PC.
  Future<void> reopen({required Map<String, dynamic> session, required BuildEngine engine, AiModel? model}) async {
    if (running || phase != BuildPhase.idle) return;
    prompt = session['prompt'] as String? ?? projectName;
    this.engine = engine;
    this.model = model;
    quality = session['quality'] as String? ?? 'fast';
    design = session['design'] as String?;
    designName = session['designName'] as String?;
    conversation
      ..clear()
      ..addAll([
        for (final m in (session['conversation'] as List? ?? const []).cast<Map<String, dynamic>>())
          (role: m['role'] as String, text: m['text'] as String),
      ]);
    if (conversation.isEmpty) conversation.add((role: 'user', text: prompt));
    _pending = session['pending'] as String?;
    products = (session['products'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
    ads = session['ads'] as Map<String, dynamic>?;
    _status = session['status'] as String? ?? 'done';
    _cancelled = false;
    _cancelSignal = Completer<void>();
    error = null;
    try {
      var attached = false;
      if (engine.isCli) {
        final res = await _request(MsgType.agentGet, {'projectId': projectId, 'withEvents': true});
        final run = res['run'] as Map<String, dynamic>?;
        if (run != null && run['status'] == 'running') {
          attached = true;
          startedAt = DateTime.tryParse(run['startedAt'] as String? ?? '') ?? DateTime.now();
          _setPhase(BuildPhase.generating);
          await _runClaudeCode('', resume: true, attachTo: run);
          if (_cancelled) return;
        }
      }
      if (!attached && _status == 'building') {
        // The app was closed mid-build: continue from the files already written.
        await _run(prompt: prompt, engine: engine, model: model, change: resumeRequest(_pending ?? prompt), display: strings.bResumeChat);
        return;
      }
      // A finished app opens instantly: rebuild only when there is no web build yet.
      final info = PreviewInfo.fromJson(await _request(MsgType.previewStatus, {'projectId': projectId}));
      if (attached || !info.built) {
        await _buildPreview();
      } else {
        preview = info;
      }
      if (_cancelled) return;
      _status = 'done';
      _setPhase(BuildPhase.ready);
      _saveSession();
    } on _Cancelled {
      _setPhase(BuildPhase.cancelled);
    } catch (e) {
      if (_cancelled) return;
      error = e is AiException ? e.message : (e is RunnerException ? e.message : e.toString());
      _log(error!, kind: 'error');
      _setPhase(BuildPhase.failed);
    }
  }

  void _checkCancelled() {
    if (_cancelled) throw const _Cancelled();
  }

  // ---------------------------------------------------------------- API engines

  Future<void> _runApiEngine({String? change}) async {
    final m = model;
    if (m == null) throw AiException(strings.bNoModel);
    final provider = await _resolve(m);
    final maxTokens = engine!.maxTokens;

    _setPhase(BuildPhase.generating);
    final String userMessage;
    if (change == null) {
      _log(strings.bWriting(m.label));
      userMessage = '$prompt${design ?? ''}\n\n(Project package name: $projectName)${await _androidBlock()}';
    } else {
      _log(strings.bApplying(m.label, change));
      userMessage = '${improvePrompt(prompt, await _readProjectFiles(), change)}${await _androidBlock()}';
    }
    var files = await _generate(provider, m, userMessage, maxTokens);
    // The prose around the files is the reply shown in the chat.
    final reply = CodeBlocks.parse(liveText.toString()).whereType<TextSegment>().map((t) => t.markdown.replaceAll(_planRe, '').trim()).where((t) => t.isNotEmpty).join('\n\n');
    if (reply.isNotEmpty) _replyText = _takeProducts(reply);
    if (files.isEmpty) throw AiException(strings.bNoFiles);
    await _writeFiles(files, removeDefaultTest: change == null);

    while (true) {
      _checkCancelled();
      final problems = await _verify();
      if (problems == null) return;
      if (fixRound >= maxFixRounds) {
        throw AiException(strings.bErrorsRemain(maxFixRounds, problems));
      }
      fixRound++;
      _setPhase(BuildPhase.fixing);
      _log(strings.bFixing(fixRound, maxFixRounds));
      files = await _generate(provider, m, fixPrompt(prompt, await _readProjectFiles(), problems), maxTokens);
      if (files.isEmpty) throw AiException(strings.bNoFixes(problems));
      await _writeFiles(files, removeDefaultTest: false);
    }
  }

  /// Streams one generation and returns the complete files it contains.
  Future<Map<String, String>> _generate(AiProvider provider, AiModel m, String userMessage, int maxTokens) async {
    liveText.clear();
    var input = 0, output = 0;
    String? stop;
    String? streamError;
    final done = Completer<void>();
    _aiSub = provider
        .chat(model: m.id, system: appBuildSystemPrompt, maxTokens: maxTokens, messages: [AiMessage.user(userMessage)])
        .listen(
          (e) {
            switch (e) {
              case AiTextDelta(:final text):
                liveText.write(text);
                if (expectedFiles == null && liveText.length < 400) _readPlan(liveText.toString());
                notifyListeners();
              case AiUsage(:final inputTokens, :final outputTokens):
                if (inputTokens > 0) input = inputTokens;
                if (outputTokens > 0) output = outputTokens;
              case AiStop(:final reason):
                stop = reason;
              case AiError(:final message):
                streamError = message;
              case AiToolCall():
                break;
            }
          },
          onDone: () => done.isCompleted ? null : done.complete(),
          onError: (Object e) {
            streamError = e.toString();
            if (!done.isCompleted) done.complete();
          },
        );
    await _orCancel(done.future);
    _aiSub = null;
    costUsd += m.estimateCost(input, output) ?? 0;
    if (streamError != null) throw AiException(streamError!);

    final segments = CodeBlocks.parse(liveText.toString());
    summary ??= segments.whereType<TextSegment>().firstOrNull?.markdown.trim();
    final files = <String, String>{};
    for (final s in segments.whereType<CodeSegment>()) {
      final path = s.path;
      if (path == null) continue;
      if (!s.complete) {
        _log(strings.bIncompleteFile(path), kind: 'error');
        continue;
      }
      if (!BuildSupport.isWritableByAi(path)) {
        _log(strings.bPathNotAllowed(path), kind: 'error');
        continue;
      }
      files[path] = s.code.endsWith('\n') ? s.code : '${s.code}\n';
    }
    if (stop == 'max_tokens') {
      _log(strings.bTruncated, kind: 'error');
    }
    if (stop == 'refusal') throw AiException(strings.bRefused);
    return files;
  }

  Future<void> _writeFiles(Map<String, String> files, {required bool removeDefaultTest}) async {
    for (final entry in files.entries) {
      _checkCancelled();
      var content = entry.value;
      if (entry.key == 'pubspec.yaml') content = BuildSupport.enforcePackageName(content, projectName);
      await _request(MsgType.fsWrite, {'projectId': projectId, 'path': entry.key, 'content': content});
      writtenFiles.add(entry.key);
      _log(entry.key, kind: 'file');
    }
    // The template's test references `MyApp`, which generated apps rarely keep.
    if (removeDefaultTest && !files.containsKey('test/widget_test.dart')) {
      try {
        await _request(MsgType.fsDelete, {'projectId': projectId, 'path': 'test/widget_test.dart'});
      } on RunnerException catch (e) {
        if (e.code != 'not_found') rethrow;
      }
    }
  }

  /// Runs pub get + analyze. Returns a problem report, or null if clean.
  Future<String?> _verify() async {
    _setPhase(BuildPhase.dependencies);
    _log(strings.bPubGet);
    final pub = await _runJob('pub_get');
    if (pub.status != 'succeeded') {
      final tail = _tail(await _fetchJobLog(pub.jobId), 60);
      _log(strings.bPubGetFailed, kind: 'error');
      return 'flutter pub get failed:\n$tail';
    }
    _setPhase(BuildPhase.checking);
    _log(strings.bAnalyze);
    final analyze = await _runJob('analyze');
    final logText = await _fetchJobLog(analyze.jobId);
    final errors = BuildSupport.errorsOnly(logText);
    if (errors.isEmpty) {
      if (analyze.status == 'succeeded' || analyze.exitCode == 0) {
        _log(strings.bNoErrors);
        return null;
      }
      return 'flutter analyze failed:\n${_tail(logText, 60)}';
    }
    _log(strings.bErrorsFound(errors.length), kind: 'error');
    return errors.take(40).map((e) => e.toString()).join('\n');
  }

  /// Starts a job and waits for it. Listens *before* starting: a job that
  /// fails instantly can report its final status before the start reply.
  Future<JobStatus> _runJob(String kind) async {
    final finished = <String, JobStatus>{};
    String? wanted;
    final c = Completer<JobStatus>();
    final sub = _events.where((f) => f.type == MsgType.jobStatus).listen((f) {
      final s = JobStatus.fromJson(f.payload);
      if (!s.isDone) return;
      if (s.jobId == wanted) {
        if (!c.isCompleted) c.complete(s);
      } else {
        finished[s.jobId] = s;
      }
    });
    try {
      final started = JobStatus.fromJson(await _request(MsgType.jobStart, {'projectId': projectId, 'kind': kind}));
      _currentJobId = wanted = started.jobId;
      final early = started.isDone ? started : finished[started.jobId];
      if (early != null) return early;
      final poll = Timer.periodic(pollInterval, (_) async {
        try {
          final s = JobStatus.fromJson(await _request(MsgType.jobGet, {'jobId': started.jobId}));
          if (s.isDone && !c.isCompleted) c.complete(s);
        } catch (_) {}
      });
      try {
        return await _orCancel(c.future.timeout(jobTimeout));
      } finally {
        poll.cancel();
      }
    } finally {
      _currentJobId = null;
      await sub.cancel();
    }
  }

  Future<Map<String, String>> _readProjectFiles() async {
    final out = <String, String>{};
    Future<void> walk(String dir) async {
      final res = await _request(MsgType.fsList, {'projectId': projectId, 'path': dir});
      for (final raw in res['entries'] as List) {
        final e = FsEntry.fromJson(raw as Map<String, dynamic>);
        if (e.isDir) {
          await walk(e.path);
        } else if (e.path.endsWith('.dart') || e.path.endsWith('.yaml') || e.path.endsWith('.json') || e.path.endsWith('.arb')) {
          final f = await _request(MsgType.fsRead, {'projectId': projectId, 'path': e.path});
          out[e.path] = f['content'] as String;
        }
      }
    }

    await walk('lib');
    try {
      await walk('test');
    } on RunnerException {
      // no test dir
    }
    final pubspec = await _request(MsgType.fsRead, {'projectId': projectId, 'path': 'pubspec.yaml'});
    out['pubspec.yaml'] = pubspec['content'] as String;
    return out;
  }

  // --------------------------------------------------------------- Claude Code

  Future<void> _runClaudeCode(String text, {required bool resume, Map<String, dynamic>? attachTo}) async {
    _setPhase(BuildPhase.generating);
    _log(resume ? strings.bClaudeApplying : strings.bClaudeBuilding);
    final done = Completer<String>();
    // Frames that arrive before agent.start replies are buffered, then replayed.
    final early = <WsFrame>[];
    late void Function(WsFrame) handle;
    final sub = _events.listen((f) {
      if (f.type != MsgType.agentEvent && f.type != MsgType.agentStatus) return;
      if (_agentRunId == null) {
        early.add(f);
      } else {
        handle(f);
      }
    });
    handle = (f) {
      if (f.type == MsgType.agentEvent && f.payload['runId'] == _agentRunId) {
        final ev = f.payload['event'] as Map<String, dynamic>;
        switch (ev['kind']) {
          case 'text':
            _readPlan(ev['text'] as String);
            _log((ev['text'] as String).replaceAll(_planRe, '').trim(), kind: 'ai');
          case 'tool':
            final name = ev['name'] as String;
            final summary = ev['summary'] as String? ?? '';
            if (name == 'Write' || name == 'Edit' || name == 'MultiEdit') writtenFiles.add(summary);
            // The CLI interleaves writing, pub get and analyze: show the live action
            // instead of jumping between step rows.
            currentAction = switch (name) {
              'Write' => strings.actWrites(summary),
              'Edit' || 'MultiEdit' => strings.actEdits(summary),
              'Read' || 'Glob' || 'Grep' => strings.actReads(summary),
              'Bash' when summary.contains('pub get') => strings.actPubGet,
              'Bash' when summary.contains('analyze') => strings.actAnalyze,
              _ => '$name $summary',
            };
            _log('$name ${summary.isEmpty ? '' : summary}', kind: name == 'Bash' ? 'tool' : 'file');
          case 'result':
            final cost = ev['costUsd'];
            if (cost is num) costUsd += cost.toDouble();
            if (ev['ok'] == true) {
              summary = ev['message'] as String?;
              _replyText = summary == null ? null : _takeProducts(summary!);
            }
          case 'error':
            _log(ev['message'] as String, kind: 'error');
        }
      } else if (f.type == MsgType.agentStatus && f.payload['id'] == _agentRunId) {
        final status = f.payload['status'] as String;
        if (status != 'running' && !done.isCompleted) done.complete(status);
      }
    };
    try {
      final run = attachTo ??
          await _request(MsgType.agentStart, {
            'projectId': projectId,
            'engine': engine!.cli,
            'prompt': text,
            'resume': resume,
            'quality': quality,
            if (quality != 'fast' && quality != 'best') 'model': quality,
          });
      _agentRunId = run['id'] as String;
      if (run['plannedFiles'] is int) expectedFiles = run['plannedFiles'] as int;
      // Replay what happened while this device was away.
      for (final ev in (run['events'] as List? ?? const [])) {
        handle(WsFrame(type: MsgType.agentEvent, payload: {'runId': _agentRunId, 'projectId': projectId, 'event': ev}));
      }
      if (run['status'] is String && run['status'] != 'running') done.complete(run['status'] as String);
      for (final f in early) {
        handle(f);
      }
      early.clear();
      final poll = Timer.periodic(pollInterval, (_) async {
        try {
          final res = await _request(MsgType.agentGet, {'runId': _agentRunId});
          final r = res['run'] as Map<String, dynamic>?;
          if (r == null) return;
          if (r['plannedFiles'] is int && expectedFiles == null) {
            expectedFiles = r['plannedFiles'] as int;
            notifyListeners();
          }
          if (r['status'] != 'running' && !done.isCompleted) done.complete(r['status'] as String);
        } catch (_) {}
      });
      final String status;
      try {
        status = await _orCancel(done.future.timeout(const Duration(hours: 1)));
      } finally {
        poll.cancel();
      }
      if (status != 'succeeded') throw AiException(strings.bClaudeFailed);
    } finally {
      await sub.cancel();
      _agentRunId = null;
    }
  }

  // ------------------------------------------------------------------- preview

  /// How many times a failed build is handed back to the engine to be fixed.
  static const _buildFixRounds = 2;

  /// Builds, and when the build fails lets the engine read the error and fix it.
  ///
  /// A build can fail for things the engine can put right on its own — packages
  /// whose versions do not fit together, a missing import, a typo in a platform
  /// file. Giving up on the first failure leaves the user with an app that does
  /// not run and an error they cannot act on.
  Future<void> _buildUntilItWorks() async {
    for (var round = 0; ; round++) {
      try {
        await _buildPreview();
        return;
      } on AiException catch (e) {
        if (_cancelled || round >= _buildFixRounds) rethrow;
        _log(strings.bFixing(round + 1, _buildFixRounds), kind: 'info');
        _setPhase(BuildPhase.fixing);
        final ask =
            'The build failed with the error below. Fix the cause in the project and make sure the app builds, '
            'without removing any feature. If packages disagree on versions, choose a set that works together.\n\n${e.message}';
        if (engine?.isCli ?? false) {
          await _runClaudeCode(ask, resume: true);
        } else {
          await _runApiEngine(change: ask);
        }
      }
    }
  }

  Future<void> _buildPreview() async {
    currentAction = null;
    _setPhase(BuildPhase.building);
    _log(strings.bWebBuilding);
    final c = Completer<WsFrame>();
    final sub = _events
        .where((f) => (f.type == MsgType.previewReady || f.type == MsgType.previewFailed) && f.payload['projectId'] == projectId)
        .listen((f) => c.isCompleted ? null : c.complete(f));
    try {
      final res = await _request(MsgType.previewStart, {'projectId': projectId, 'autoRebuild': true});
      _currentJobId = (res['job'] as Map<String, dynamic>)['jobId'] as String;
      final jobId = _currentJobId!;
      final poll = Timer.periodic(pollInterval, (_) async {
        try {
          final s = JobStatus.fromJson(await _request(MsgType.jobGet, {'jobId': jobId}));
          if (!s.isDone || c.isCompleted) return;
          if (s.status == 'succeeded') {
            final info = await _request(MsgType.previewStatus, {'projectId': projectId});
            if (!c.isCompleted) c.complete(WsFrame(type: MsgType.previewReady, payload: info));
          } else if (!c.isCompleted) {
            c.complete(WsFrame(type: MsgType.previewFailed, payload: {'projectId': projectId, 'jobId': jobId}));
          }
        } catch (_) {}
      });
      final WsFrame f;
      try {
        f = await _orCancel(c.future.timeout(jobTimeout));
      } finally {
        poll.cancel();
      }
      if (f.type == MsgType.previewFailed) {
        final tail = _buildErrors(await _fetchJobLog(f.payload['jobId'] as String), 12);
        throw AiException(strings.bWebFailed(tail));
      }
      preview = PreviewInfo.fromJson(f.payload);
    } finally {
      _currentJobId = null;
      await sub.cancel();
    }
  }

  // ------------------------------------------------------------ Android files

  /// `apk` or `aab` while/after building; null if never requested.
  String? androidKind;

  /// `building` | `ready` | `failed`.
  String? androidStatus;
  String? androidError;

  bool get androidBuilding => androidStatus == 'building';

  /// The user answered "Not now" to "Upload to Play Store?".
  bool playPromptDismissed = false;

  void dismissPlayPrompt() {
    playPromptDismissed = true;
    notifyListeners();
  }

  /// Runner-relative download path, e.g. `/artifacts/<ws>/<project>/app-release.apk`.
  String? get androidPath {
    final p = preview?.path;
    if (p == null || androidStatus != 'ready' || androidKind == null) return null;
    return '${p.replaceFirst('/preview/', '/artifacts/')}app-release.$androidKind';
  }

  /// Builds a release APK (installable) or AAB (Play Store) for the finished app.
  Future<void> buildAndroid(String kind) async {
    if (running || androidBuilding) return;
    androidKind = kind;
    androidStatus = 'building';
    playPromptDismissed = false;
    androidError = null;
    _cancelled = false;
    if (_cancelSignal.isCompleted) _cancelSignal = Completer<void>();
    _log(kind == 'apk' ? strings.bApk : strings.bAab);
    notifyListeners();
    try {
      // `apk_fast` is the one for trying the app on a phone: no shrinking, minutes quicker.
      final job = await _runJob(switch (kind) {
        'apk' => 'build_apk',
        'apk_fast' => 'build_apk_fast',
        _ => 'build_aab',
      });
      if (job.status != 'succeeded') {
        androidError = _tail(await _fetchJobLog(job.jobId), 30);
        androidStatus = 'failed';
        _log(strings.bAndroidFailed(kind.toUpperCase()), kind: 'error');
      } else {
        androidStatus = 'ready';
        _log(strings.bAndroidReady(kind.toUpperCase()));
      }
    } catch (e) {
      androidError = e is RunnerException ? e.message : e.toString();
      androidStatus = 'failed';
    }
    notifyListeners();
  }

  // -------------------------------------------------------------- iPhone file

  /// `building` | `ready` | `failed`; null if never requested.
  String? iosStatus;
  String? iosError;

  bool get iosBuilding => iosStatus == 'building';

  /// Builds the iPhone app (IPA). Only a Mac can do it: elsewhere the Runner
  /// answers `needs_mac` and the message explains what to do.
  Future<void> buildIos() async {
    if (running || iosBuilding) return;
    iosStatus = 'building';
    iosError = null;
    _cancelled = false;
    if (_cancelSignal.isCompleted) _cancelSignal = Completer<void>();
    _log(strings.bIpa);
    notifyListeners();
    try {
      final job = await _runJob('build_ipa');
      if (job.status != 'succeeded') {
        iosError = _tail(await _fetchJobLog(job.jobId), 30);
        iosStatus = 'failed';
        _log(strings.bIosFailed, kind: 'error');
      } else {
        iosStatus = 'ready';
        _log(strings.bIosReady);
      }
    } catch (e) {
      iosError = e is RunnerException ? e.message : e.toString();
      iosStatus = 'failed';
      _log(iosError!, kind: 'error');
    }
    notifyListeners();
  }

  Future<void> cancel() async {
    if (!running) return;
    _cancelled = true;
    if (!_cancelSignal.isCompleted) _cancelSignal.complete();
    unawaited(_aiSub?.cancel());
    _aiSub = null;
    final job = _currentJobId;
    if (job != null) unawaited(_request(MsgType.jobCancel, {'jobId': job}).catchError((_) => <String, dynamic>{}));
    final run = _agentRunId;
    if (run != null) unawaited(_request(MsgType.agentCancel, {'runId': run}).catchError((_) => <String, dynamic>{}));
    _log(strings.bStopped, kind: 'error');
    _setPhase(BuildPhase.cancelled);
  }

  /// The lines that explain a failed build, without Dart stack frames.
  static String _buildErrors(String log, int lines) {
    final useful = log
        .split('\n')
        .where((l) => !RegExp(r'^\s*(#\d+\s|<asynchronous suspension>)').hasMatch(l) && l.trim().isNotEmpty)
        .toList();
    final errors = useful.where((l) => RegExp(r'error', caseSensitive: false).hasMatch(l)).toList();
    final picked = errors.isNotEmpty ? errors : useful;
    return (picked.length <= lines ? picked : picked.sublist(picked.length - lines)).join('\n');
  }

  static String _tail(String s, int lines) {
    final all = s.trimRight().split('\n');
    return all.length <= lines ? all.join('\n') : all.sublist(all.length - lines).join('\n');
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}
