import 'dart:async';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/widgets.dart';
import 'package:ide_core/ide_core.dart';

import '../../l10n/app_localizations.dart';
import '../editor/project_controller.dart' show RunnerRequest;

/// Which AI builds the app (§1B "Crea App").
enum BuildEngine {
  gemini(AiProviderId.gemini, 'gemini-2.5-flash', 65536),
  openai(AiProviderId.openai, 'gpt-5', 64000),
  xai(AiProviderId.xai, 'grok-4', 32000),
  claude(AiProviderId.anthropic, 'claude-opus-5', 64000),
  claudeCode(null, null, 0);

  const BuildEngine(this.provider, this.defaultModel, this.maxTokens);
  final AiProviderId? provider;
  final String? defaultModel;
  final int maxTokens;

  bool get isCli => this == claudeCode;
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
- A complete, real product for the kind of app requested, not a single screen or a demo. For product-type apps include the core feature set users expect (e.g. a chat/dating app like Badoo: sign-up/login with email and Google, profile with photo, discovery/user list, conversations, private 1-to-1 chats and private rooms, real-time messages, logout). Simple utilities stay simple.
- Large extras not requested (video calls, payments…) are suggested in "Prossimi passi", not built.
- Real integrations only: Firebase Auth (email + Google Sign-In), Cloud Firestore, Firebase Storage, Agora or Jitsi for video, Firebase Messaging, Stripe, Google Maps. Never invent keys: keep all keys in lib/config/app_config.dart with empty defaults, initialize services only when configured, and show an in-app "Configurazione necessaria" screen describing what is missing so the app still runs. Initialize Firebase with FirebaseOptions from AppConfig (no flutterfire CLI). When the user pastes keys, write them into AppConfig.
- UI text in the user's language, polished Material 3 (or the APPROVED DESIGN when given). Must compile for web and Android; avoid code generation (no build_runner). Make sure every import resolves.''';

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
    AppLocalizations? strings,
    this.maxFixRounds = 3,
    this.jobTimeout = const Duration(minutes: 15),
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
  /// UI language for log lines and errors; updated when the user switches language.
  AppLocalizations strings;
  final int maxFixRounds;
  final Duration jobTimeout;

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
  }) {
    this.quality = quality;
    this.design = design;
    this.designName = designName;
    return _run(prompt: prompt, engine: engine, model: model, change: null);
  }

  /// Applies a follow-up change to an already built app.
  Future<void> improve(String change) {
    final e = engine;
    if (e == null) return Future.value();
    return _run(prompt: prompt, engine: e, model: model, change: change);
  }

  Future<void> _run({required String prompt, required BuildEngine engine, AiModel? model, String? change}) async {
    if (running) return;
    this.prompt = prompt;
    this.engine = engine;
    this.model = model;
    _cancelled = false;
    _cancelSignal = Completer<void>();
    error = null;
    fixRound = 0;
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
      conversation.add((role: 'user', text: change));
    }
    _replyText = null;
    try {
      if (engine.isCli) {
        await _runClaudeCode('${change ?? '$prompt${design ?? ''}'}${await _androidBlock()}', resume: change != null);
      } else {
        await _runApiEngine(change: change);
      }
      if (_cancelled) return;
      await _buildPreview();
      if (_cancelled) return;
      conversation.add((role: 'assistant', text: _replyText?.trim().isNotEmpty == true ? _replyText!.trim() : strings.bAppUpdated));
      _setPhase(BuildPhase.ready);
      _log(strings.bAppReady, kind: 'info');
    } on _Cancelled {
      _setPhase(BuildPhase.cancelled);
    } catch (e) {
      if (_cancelled) {
        _setPhase(BuildPhase.cancelled);
        return;
      }
      error = e is AiException ? e.message : (e is RunnerException ? e.message : e.toString());
      conversation.add((role: 'assistant', text: '⚠️ $error'));
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
    final reply = CodeBlocks.parse(liveText.toString()).whereType<TextSegment>().map((t) => t.markdown.trim()).where((t) => t.isNotEmpty).join('\n\n');
    if (reply.isNotEmpty) _replyText = reply;
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
      return await _orCancel(c.future.timeout(jobTimeout));
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

  Future<void> _runClaudeCode(String text, {required bool resume}) async {
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
            _log((ev['text'] as String).trim(), kind: 'ai');
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
              _replyText = summary;
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
      final run = await _request(MsgType.agentStart, {
        'projectId': projectId,
        'engine': 'claude-code',
        'prompt': text,
        'resume': resume,
        'quality': quality,
      });
      _agentRunId = run['id'] as String;
      for (final f in early) {
        handle(f);
      }
      early.clear();
      final status = await _orCancel(done.future.timeout(const Duration(hours: 1)));
      if (status != 'succeeded') throw AiException(strings.bClaudeFailed);
    } finally {
      await sub.cancel();
      _agentRunId = null;
    }
  }

  // ------------------------------------------------------------------- preview

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
      final f = await _orCancel(c.future.timeout(jobTimeout));
      if (f.type == MsgType.previewFailed) {
        final tail = _tail(await _fetchJobLog(f.payload['jobId'] as String), 40);
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
      final job = await _runJob(kind == 'apk' ? 'build_apk' : 'build_aab');
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

  static String _tail(String s, int lines) {
    final all = s.trimRight().split('\n');
    return all.length <= lines ? all.join('\n') : all.sublist(all.length - lines).join('\n');
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}
