import 'dart:async';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/ai/chat_controller.dart';

class FakeProvider implements AiProvider {
  FakeProvider(this.script);

  /// Events to emit; a `null` entry pauses until [release] completes.
  final List<AiEvent?> script;
  final release = Completer<void>();
  List<AiMessage>? lastMessages;
  String? lastSystem;

  @override
  AiProviderId get id => AiProviderId.anthropic;

  @override
  Stream<AiEvent> chat({required String model, required List<AiMessage> messages, String? system, List<AiTool> tools = const [], int maxTokens = 16000}) async* {
    lastMessages = messages;
    lastSystem = system;
    for (final e in script) {
      if (e == null) {
        await release.future;
      } else {
        yield e;
      }
    }
  }

  @override
  Future<String> complete({required String model, required String prefix, String suffix = '', int maxTokens = 256}) async => '';

  @override
  Future<List<List<double>>> embed({required String model, required List<String> inputs}) async => const [];
}

final opus = builtInCatalog.firstWhere((m) => m.id == 'claude-opus-5');

void main() {
  test('streams a reply with file context, usage, cost, and persists', () async {
    final provider = FakeProvider(const [
      AiTextDelta('Ecco '),
      AiTextDelta('fatto'),
      AiUsage(inputTokens: 1000, outputTokens: 200),
      AiStop('end'),
    ]);
    List<Map<String, dynamic>>? saved;
    final c = ChatController(projectId: 'p', resolveProvider: (_) async => provider, saveHistory: (rows) async => saved = rows)
      ..selectModel(opus);

    await c.send('Aggiungi un bottone', openFile: const ChatFileContext('lib/main.dart', 'void main() {}'));

    expect(c.entries.length, 2);
    final reply = c.entries.last;
    expect((reply.text, reply.streaming, reply.stopReason), ('Ecco fatto', false, 'end'));
    expect(reply.costUsd, closeTo((1000 * 5 + 200 * 25) / 1e6, 1e-12));
    expect(c.entries.first.contextPath, 'lib/main.dart');
    final userMsg = provider.lastMessages!.last.content;
    expect(userMsg, contains('```dart lib/main.dart\nvoid main() {}\n```'));
    expect(userMsg, endsWith('Aggiungi un bottone'));
    expect(provider.lastSystem, contains('project-relative path'));
    expect(saved!.length, 2);
  });

  test('history excludes failed replies; oversized file is announced, not truncated', () {
    final history = [
      ChatEntry(role: AiRole.user, text: 'a'),
      ChatEntry(role: AiRole.assistant, text: '', error: 'boom'),
      ChatEntry(role: AiRole.assistant, text: 'ok'),
    ];
    final big = 'x' * (maxContextChars + 1);
    final msgs = ChatController.buildMessages(history, 'q', ChatFileContext('lib/big.dart', big));
    expect(msgs.map((m) => m.content).take(2), ['a', 'ok']);
    expect(msgs.last.content, contains('too large to attach'));
    expect(msgs.last.content.length, lessThan(200));
  });

  test('stop keeps partial text and releases send()', () async {
    final provider = FakeProvider(const [AiTextDelta('parziale'), null, AiTextDelta(' mai')]);
    final c = ChatController(projectId: 'p', resolveProvider: (_) async => provider)..selectModel(opus);
    final sending = c.send('ciao');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.busy, isTrue);
    await c.stop();
    await sending.timeout(const Duration(seconds: 1));
    expect((c.entries.last.text, c.entries.last.stopReason, c.busy), ('parziale', 'stopped', false));
  });

  test('provider errors and missing keys surface on the reply', () async {
    final c = ChatController(projectId: 'p', resolveProvider: (_) async => FakeProvider(const [AiError('invalid x-api-key', statusCode: 401)]))
      ..selectModel(opus);
    await c.send('ciao');
    expect(c.entries.last.error, 'invalid x-api-key');

    final noKey = ChatController(projectId: 'p', resolveProvider: (_) async => throw const AiException('No API key configured for Anthropic'))
      ..selectModel(opus);
    await noKey.send('ciao');
    expect(noKey.entries.last.error, contains('No API key'));
    expect(noKey.busy, isFalse);
  });

  test('toJson round-trip keeps cost and stop reason', () {
    final e = ChatEntry(role: AiRole.assistant, text: 't', model: opus.key, costUsd: 0.01, stopReason: 'max_tokens');
    final back = ChatEntry.fromJson(e.toJson());
    expect((back.text, back.costUsd, back.stopReason, back.model), ('t', 0.01, 'max_tokens', 'anthropic:claude-opus-5'));
  });
}
