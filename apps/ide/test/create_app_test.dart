import 'dart:async';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/create/app_builder.dart';
import 'package:ide_core/ide_core.dart';

class ScriptedProvider implements AiProvider {
  ScriptedProvider(this.replies);
  final List<String> replies;
  final prompts = <String>[];

  @override
  AiProviderId get id => AiProviderId.gemini;

  @override
  Stream<AiEvent> chat({required String model, required List<AiMessage> messages, String? system, List<AiTool> tools = const [], int maxTokens = 16000}) async* {
    prompts.add(messages.last.content);
    final text = replies.removeAt(0);
    for (var i = 0; i < text.length; i += 40) {
      yield AiTextDelta(text.substring(i, i + 40 > text.length ? text.length : i + 40));
    }
    yield const AiUsage(inputTokens: 1000, outputTokens: 2000);
    yield const AiStop('end');
  }

  @override
  Future<String> complete({required String model, required String prefix, String suffix = '', int maxTokens = 256}) async => '';
  @override
  Future<List<List<double>>> embed({required String model, required List<String> inputs}) async => const [];
}

/// In-memory Runner: files, jobs (analyze fails while main.dart contains BROKEN), preview.
class FakeRunner {
  final events = StreamController<WsFrame>.broadcast();
  final files = <String, String>{
    'pubspec.yaml': 'name: demo_app\n',
    'lib/main.dart': 'void main() {}\n',
    'test/widget_test.dart': 'MyApp',
  };
  final jobLogs = <String, String>{};
  final jobsRun = <String>[];
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
        jobsRun.add(kind);
        final broken = files['lib/main.dart']!.contains('BROKEN');
        jobLogs[id] = kind == 'analyze' && broken ? "  error • Undefined name 'BROKEN' • lib/main.dart:1:1 • undefined_identifier\n" : 'No issues found!';
        final status = kind == 'analyze' && broken ? 'failed' : 'succeeded';
        scheduleMicrotask(() => events.add(WsFrame(type: MsgType.jobStatus, payload: {'jobId': id, 'kind': kind, 'status': status, 'exitCode': status == 'failed' ? 1 : 0})));
        return {'jobId': id, 'kind': kind, 'status': 'queued'};
      case MsgType.previewStart:
        scheduleMicrotask(() => events.add(const WsFrame(type: MsgType.previewReady, payload: {'projectId': 'p1', 'path': '/preview/w/p1/', 'built': true})));
        return {'job': {'jobId': 'build1', 'kind': 'build_web', 'status': 'queued'}, 'preview': {'projectId': 'p1', 'path': '/preview/w/p1/'}};
      default:
        throw RunnerException('unsupported', type);
    }
  }
}

final gemini = builtInCatalog.firstWhere((m) => m.id == 'gemini-2.5-flash');

void main() {
  test('API engine: writes files, detects analyzer error, fixes it, builds preview', () async {
    final runner = FakeRunner();
    final provider = ScriptedProvider([
      'App ricette.\n```yaml pubspec.yaml\nname: ricette\ndependencies:\n  flutter:\n    sdk: flutter\n```\n```dart lib/main.dart\nvoid main() { BROKEN; }\n```\n```dart android/app/x.kt\nnope\n```',
      '```dart lib/main.dart\nvoid main() {}\n```',
    ]);
    const androidInfo = 'ANDROID APP INFO: package dev.x.demo_app, SHA-1 AA:BB';
    final b = AppBuilder(
      projectId: 'p1',
      projectName: 'demo_app',
      request: runner.call,
      events: runner.events.stream,
      fetchJobLog: (id) async => runner.jobLogs[id] ?? '',
      resolveProvider: (_) async => provider,
      androidInfo: () async => androidInfo,
    );

    await b.build(prompt: 'Crea un\'app di ricette', engine: BuildEngine.gemini, model: gemini);

    expect(b.phase, BuildPhase.ready, reason: b.error);
    expect(b.preview!.resolve('http://localhost:8787'), 'http://localhost:8787/preview/w/p1/');
    expect(runner.files['lib/main.dart'], 'void main() {}\n');
    expect(runner.files['pubspec.yaml'], startsWith('name: demo_app\n'), reason: 'package name enforced');
    expect(runner.files.containsKey('android/app/x.kt'), isFalse, reason: 'platform folders are off-limits');
    expect(runner.files.containsKey('test/widget_test.dart'), isFalse, reason: 'stale template test removed');
    expect(b.fixRound, 1);
    expect(runner.jobsRun, ['pub_get', 'analyze', 'pub_get', 'analyze']);
    expect(provider.prompts[1], contains("Undefined name 'BROKEN'"));
    expect(provider.prompts[1], contains('```dart lib/main.dart'));
    expect(b.costUsd, greaterThan(0));
    expect(b.summary, 'App ricette.');
    expect(provider.prompts.first, contains(androidInfo));
    expect(b.conversation.map((m) => m.role), ['user', 'assistant']);
    expect(b.conversation.first.text, "Crea un'app di ricette");
    expect(b.conversation.last.text, 'App ricette.');
  });

  test('gives up after max fix rounds with a clear error', () async {
    final runner = FakeRunner();
    final provider = ScriptedProvider(List.filled(3, growable: true,'```dart lib/main.dart\nvoid main() { BROKEN; }\n```'));
    final b = AppBuilder(
      projectId: 'p1',
      projectName: 'demo_app',
      request: runner.call,
      events: runner.events.stream,
      fetchJobLog: (id) async => runner.jobLogs[id] ?? '',
      resolveProvider: (_) async => provider,
      maxFixRounds: 2,
    );
    await b.build(prompt: 'x', engine: BuildEngine.gemini, model: gemini);
    expect(b.phase, BuildPhase.failed);
    expect(b.error, contains('after 2 fix attempts'));
  });

  test('no files from the AI fails fast; cancel during a job stops the build', () async {
    final runner = FakeRunner();
    final empty = AppBuilder(
      projectId: 'p1',
      projectName: 'demo_app',
      request: runner.call,
      events: runner.events.stream,
      fetchJobLog: (_) async => '',
      resolveProvider: (_) async => ScriptedProvider(['Mi dispiace, non posso.']),
    );
    await empty.build(prompt: 'x', engine: BuildEngine.gemini, model: gemini);
    expect(empty.phase, BuildPhase.failed);
    expect(empty.error, contains('did not produce any files'));

    // A runner whose jobs never finish: cancel must release the pending wait.
    final hanging = AppBuilder(
      projectId: 'p1',
      projectName: 'demo_app',
      request: (type, p) async => type == MsgType.jobStart
          ? {'jobId': 'j', 'kind': 'pub_get', 'status': 'queued'}
          : await runner.call(type, p),
      events: const Stream<WsFrame>.empty().asBroadcastStream(),
      fetchJobLog: (_) async => '',
      resolveProvider: (_) async => ScriptedProvider(['```dart lib/main.dart\nvoid main() {}\n```']),
    );
    final building = hanging.build(prompt: 'x', engine: BuildEngine.gemini, model: gemini);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(hanging.phase, BuildPhase.dependencies);
    await hanging.cancel();
    await building.timeout(const Duration(seconds: 2));
    expect(hanging.phase, BuildPhase.cancelled);
  });
}
