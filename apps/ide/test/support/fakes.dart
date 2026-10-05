import 'dart:async';
import 'dart:typed_data';

import 'package:ai_connect/ai_connect.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ide/core/runner_api.dart';
import 'package:ide/core/runner_socket.dart';
import 'package:ide/core/session.dart';
import 'package:ide/core/settings_store.dart';
import 'package:ide/features/ai/ai_settings.dart';
import 'package:ide/features/create/app_builder.dart';
import 'package:ide/features/create/app_session.dart';
import 'package:ide/features/projects/build_watch.dart';
import 'package:ide/features/projects/history_panel.dart';
import 'package:ide/features/projects/projects_screen.dart';
import 'package:ide/features/review/reviewers.dart';
import 'package:ide/l10n/app_localizations.dart';
import 'package:ide_core/ide_core.dart';

const fakeRunnerUrl = 'http://runner.test';

class MemoryStore implements KeyValueStore {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// Refuses every HTTP call before a socket is opened.
class _NoNetwork implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) =>
      throw DioException(requestOptions: options, message: 'no network in tests: ${options.path}');

  @override
  void close({bool force = false}) {}
}

/// The Runner's REST side, answered from memory. Anything not listed here fails at once.
class FakeRunnerApi extends RunnerApi {
  FakeRunnerApi({this.projectList = const [], this.healthInfo = const {}, this.priorLog = ''}) : super(fakeRunnerUrl, token: 't', dio: Dio()..httpClientAdapter = _NoNetwork());

  final List<Project> projectList;
  final Map<String, dynamic> healthInfo;
  final String priorLog;
  final saved = <String, String>{};

  @override
  Future<Map<String, String>> settings() async => {...saved};
  @override
  Future<void> patchSettings(Map<String, String?> values) async {
    for (final e in values.entries) {
      e.value == null ? saved.remove(e.key) : saved[e.key] = e.value!;
    }
  }

  @override
  Future<Map<String, dynamic>> health() async => healthInfo;
  @override
  Future<void> forgetDevLast() async {}
  @override
  Future<List<Workspace>> workspaces() async => [fakeWorkspace];
  @override
  Future<List<Project>> projects(String workspaceId) async => [...projectList];
  @override
  Future<Project> project(String id) async => projectList.firstWhere((p) => p.id == id);
  @override
  Future<Map<String, dynamic>> checkApp(String projectId, {String? previewUrl}) async => {'findings': <Map<String, dynamic>>[]};
  @override
  Future<String> jobLog(String jobId) async => priorLog;
}

/// The Runner's socket without a connection: events are pushed by the test.
class FakeRunnerSocket extends RunnerSocket {
  FakeRunnerSocket({SocketState initial = SocketState.connected}) : super(runnerUrl: fakeRunnerUrl, tokenProvider: () async => 't') {
    state.value = initial;
  }

  final _pushed = StreamController<WsFrame>.broadcast();
  final requests = <String>[];

  void push(String type, Map<String, dynamic> payload) => _pushed.add(WsFrame(type: type, payload: payload));

  @override
  Stream<WsFrame> get events => _pushed.stream;
  @override
  Future<void> connect() async {}
  @override
  Future<Map<String, dynamic>> request(String type, Map<String, dynamic> payload, {Duration? timeout}) async {
    requests.add(type);
    if (type == MsgType.agentRunning) return {'runs': <Map<String, dynamic>>[]};
    throw RunnerException('unsupported', type);
  }

  @override
  Future<void> watch(String projectId) async {}
  @override
  Future<void> unwatch(String projectId) async {}
  @override
  Future<void> dispose() async {
    await _pushed.close();
    await super.dispose();
  }
}

class FakeSession extends SessionController {
  FakeSession(this.session);
  final Session? session;
  @override
  Future<Session?> build() async => session;
  @override
  Future<void> signIn({required String runnerUrl, required String email, String? password, bool signUp = false}) async {}
  @override
  Future<void> signOut() async => state = const AsyncData(null);
}

class FakeDrafts extends Drafts {
  FakeDrafts(this.list);
  final List<Draft> list;
  @override
  Future<List<Draft>> build() async => [...list];
  @override
  Future<void> put(String id, String prompt) async {}
  @override
  Future<void> remove(String id) async => state = AsyncData([...?state.value?.where((d) => d.id != id)]);
  @override
  Future<void> removeByPrompt(String prompt) async {}
}

/// What each project is doing, fixed: the real one asks the Runner every four seconds.
class FakeBuildWatch extends BuildWatch {
  FakeBuildWatch(this.live);
  final Map<String, BuildState> live;
  @override
  Future<Map<String, BuildState>> build() async => live;
  @override
  Future<void> refresh() async {}
}

class FakeAiSettings extends AiSettingsController {
  FakeAiSettings(this.settings);
  final AiSettings settings;
  @override
  Future<AiSettings> build() async => settings;
  @override
  Future<void> setKey(AiProviderId p, String key) async {}
  @override
  Future<void> updateSettings({String? compatibleBaseUrl, bool? useProxy, String? defaultModel, List<String>? customModels}) async {}
}

class FakeReviewerSettings extends ReviewerSettingsController {
  FakeReviewerSettings(this.settings);
  final ReviewerSettings settings;
  @override
  Future<ReviewerSettings> build() async => settings;
  @override
  Future<void> setKey(String id, String key) async {}
  @override
  Future<void> edit(String id, {String? label, String? baseUrl, String? model}) async {}
}

final fakeWorkspace = Workspace.fromJson(const {'id': 'w1', 'name': 'default', 'status': 'running', 'createdAt': '2026-01-01T00:00:00.000Z'});
const fakeSession = Session(runnerUrl: fakeRunnerUrl, email: 'someone.with.a.rather.long.address@example-company.dev', devToken: 't');

/// A Runner with its own Gemini and the Claude and Google subscriptions logged in; ChatGPT is not.
const fakeHealth = <String, dynamic>{
  'engines': {'claudeCode': true, 'serverGemini': true, 'codex': false, 'geminiCli': true},
  'cliModels': {
    'claude-code': [
      {'id': 'fast', 'label': 'Sonnet', 'description': 'Quick and cheap, good for most apps and for every small change that follows the first build'},
      {'id': 'best', 'label': 'Opus', 'description': 'Slower, for the large apps'},
    ],
  },
};

Project fakeProject(String id, String name, {String status = 'ready', String? title, Duration age = Duration.zero}) =>
    Project(id: id, workspaceId: 'w1', name: name, template: 'empty', status: status, createdAt: DateTime.now().subtract(age), title: title);

/// Everything a signed-in screen reads, answered from memory: no socket, no HTTP.
List<Override> signedIn({
  List<Project> projects = const [],
  List<Draft> drafts = const [],
  Map<String, BuildState> live = const {},
  Map<String, dynamic> health = fakeHealth,
  AiSettings ai = const AiSettings(),
  Session? session = fakeSession,
  FakeRunnerSocket? socket,
  FakeRunnerApi? api,
}) {
  final runner = api ?? FakeRunnerApi(projectList: projects, healthInfo: health);
  return [
    keyValueStoreProvider.overrideWithValue(MemoryStore()),
    settingsStoreProvider.overrideWithValue(MemoryStore()),
    sessionProvider.overrideWith(() => FakeSession(session)),
    runnerApiProvider.overrideWith((ref) async => runner),
    runnerHealthProvider.overrideWith((ref) async => health),
    runnerSocketProvider.overrideWith((ref) {
      final s = socket ?? FakeRunnerSocket();
      ref.onDispose(s.dispose);
      return s;
    }),
    workspaceProvider.overrideWith((ref) async => fakeWorkspace),
    projectsProvider.overrideWith((ref) async => [...projects]),
    projectByIdProvider.overrideWith((ref, id) async => projects.firstWhere((p) => p.id == id)),
    draftsProvider.overrideWith(() => FakeDrafts(drafts)),
    buildWatchProvider.overrideWith(() => FakeBuildWatch(live)),
    aiSettingsProvider.overrideWith(() => FakeAiSettings(ai)),
    aiCatalogProvider.overrideWith((ref) async => builtInCatalog),
    reviewerSettingsProvider.overrideWith(() => FakeReviewerSettings(const ReviewerSettings(reviewers: reviewerPresets))),
  ];
}

class ScriptedProvider implements AiProvider {
  ScriptedProvider(this.replies);
  final List<String> replies;

  @override
  AiProviderId get id => AiProviderId.gemini;

  @override
  Stream<AiEvent> chat({required String model, required List<AiMessage> messages, String? system, List<AiTool> tools = const [], int maxTokens = 16000}) async* {
    yield AiTextDelta(replies.removeAt(0));
    yield const AiUsage(inputTokens: 1000, outputTokens: 2000);
    yield const AiStop('end');
  }

  @override
  Future<String> complete({required String model, required String prefix, String suffix = '', int maxTokens = 256}) async => '';
  @override
  Future<List<List<double>>> embed({required String model, required List<String> inputs}) async => const [];
}

/// In-memory Runner for a build: files, jobs (analyze fails while main.dart contains BROKEN), preview.
/// With [hang] the jobs never finish, so the build stays in progress.
class FakeBuildRunner {
  FakeBuildRunner({this.hang = false});
  final bool hang;
  final events = StreamController<WsFrame>.broadcast();
  final files = <String, String>{'pubspec.yaml': 'name: demo_app\n', 'lib/main.dart': 'void main() {}\n'};
  final jobLogs = <String, String>{};
  int _n = 0;

  Future<Map<String, dynamic>> call(String type, Map<String, dynamic> p) async {
    switch (type) {
      case MsgType.fsWrite:
        files[p['path'] as String] = p['content'] as String;
        return {'mtimeMs': 1};
      case MsgType.fsDelete:
        if (files.remove(p['path']) == null) throw const RunnerException('not_found', 'nope');
        return {};
      case MsgType.fsRead:
        return {'content': files[p['path']]!, 'mtimeMs': 1};
      case MsgType.fsList:
        final dir = p['path'] as String;
        final names = files.keys.where((f) => f.startsWith('$dir/')).toList();
        if (names.isEmpty) throw const RunnerException('not_found', 'nope');
        return {
          'entries': [for (final f in names) {'path': f, 'name': f.split('/').last, 'isDir': false}],
        };
      case MsgType.jobStart:
        final id = 'j${++_n}';
        final kind = p['kind'] as String;
        if (hang) return {'jobId': id, 'kind': kind, 'status': 'queued'};
        final broken = files['lib/main.dart']!.contains('BROKEN');
        jobLogs[id] = kind == 'analyze' && broken ? "  error • Undefined name 'BROKEN' • lib/main.dart:1:1 • undefined_identifier\n" : 'No issues found!';
        final status = kind == 'analyze' && broken ? 'failed' : 'succeeded';
        scheduleMicrotask(() => events.add(WsFrame(type: MsgType.jobStatus, payload: {'jobId': id, 'kind': kind, 'status': status, 'exitCode': status == 'failed' ? 1 : 0})));
        return {'jobId': id, 'kind': kind, 'status': 'queued'};
      case MsgType.jobCancel:
        return {};
      case MsgType.previewStart:
        scheduleMicrotask(() => events.add(WsFrame(type: MsgType.previewReady, payload: {'projectId': p['projectId'], 'path': '/preview/w/p1/', 'built': true})));
        return {'job': {'jobId': 'build1', 'kind': 'build_web', 'status': 'queued'}, 'preview': {'projectId': p['projectId'], 'path': '/preview/w/p1/'}};
      default:
        throw RunnerException('unsupported', type);
    }
  }
}

enum AppState { building, ready, failed }

/// A real [AppBuilder] taken to [state] against the in-memory Runner, and the
/// build still in flight when there is one. Uses real timers: call it inside
/// `tester.runAsync`, and [stop] the same way before the test ends.
class BuiltApp {
  BuiltApp(this.builder, this._pending);
  final AppBuilder builder;
  final Future<void>? _pending;

  Future<void> stop() async {
    await builder.cancel();
    await _pending?.timeout(const Duration(seconds: 2));
  }

  static Future<BuiltApp> at(AppState state, {required String projectId, required String projectName, required String prompt, required Locale locale, String? designName}) async {
    final runner = FakeBuildRunner(hang: state == AppState.building);
    final replies = switch (state) {
      AppState.failed => List.filled(3, '```dart lib/main.dart\nvoid main() { BROKEN; }\n```', growable: true),
      _ => ['PLAN_FILES: 12\nA recipe book with a shopping list.\n```dart lib/main.dart\nvoid main() {}\n```\n```dart lib/home_screen.dart\nclass Home {}\n```'],
    };
    final b = AppBuilder(
      projectId: projectId,
      projectName: projectName,
      request: runner.call,
      events: runner.events.stream,
      fetchJobLog: (id) async => runner.jobLogs[id] ?? '',
      resolveProvider: (_) async => ScriptedProvider(replies),
      strings: lookupAppLocalizations(locale),
      maxFixRounds: 2,
    );
    final gemini = builtInCatalog.firstWhere((m) => m.provider == AiProviderId.gemini);
    final building = b.build(prompt: prompt, engine: BuildEngine.gemini, model: gemini, designName: designName);
    if (state != AppState.building) {
      await building;
      return BuiltApp(b, null);
    }
    for (var i = 0; i < 400 && b.phase != BuildPhase.dependencies; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return BuiltApp(b, building);
  }
}
