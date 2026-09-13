import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Fake HTTP server returning [sse] and capturing the request.
class Capture {
  http.BaseRequest? request;
  Map<String, dynamic>? body;

  MockClient client(String sse, {int status = 200}) => MockClient.streaming((req, bodyStream) async {
    request = req;
    final raw = await bodyStream.bytesToString();
    if (raw.isNotEmpty) body = jsonDecode(raw) as Map<String, dynamic>;
    return http.StreamedResponse(Stream.value(utf8.encode(sse)), status);
  });
}

Future<List<AiEvent>> collect(Stream<AiEvent> s) => s.toList();

String sse(List<Object> events, {bool named = false}) => events.map((e) {
  final data = jsonEncode(e);
  final type = named && e is Map ? 'event: ${e['type']}\n' : '';
  return '${type}data: $data\n\n';
}).join();

void main() {
  test('SSE parser handles CRLF, multi-line data and comments', () async {
    final raw = ': ping\r\nevent: a\r\ndata: 1\r\ndata: 2\r\n\r\ndata: x\n\n';
    final events = await parseSse(Stream.value(utf8.encode(raw))).toList();
    expect(events.map((e) => (e.event, e.data)), [('a', '1\n2'), (null, 'x')]);
  });

  group('Anthropic', () {
    test('streams text + tool call + usage, sends fallbacks for Opus 5', () async {
      final cap = Capture();
      final p = AnthropicProvider(
        const AiEndpoint.direct(apiKey: 'sk-ant-test'),
        client: cap.client(sse(named: true, [
          {'type': 'message_start', 'message': {'usage': {'input_tokens': 12}}},
          {'type': 'content_block_start', 'index': 0, 'content_block': {'type': 'text', 'text': ''}},
          {'type': 'content_block_delta', 'index': 0, 'delta': {'type': 'text_delta', 'text': 'Ciao'}},
          {'type': 'content_block_delta', 'index': 0, 'delta': {'type': 'text_delta', 'text': ' mondo'}},
          {'type': 'content_block_stop', 'index': 0},
          {'type': 'content_block_start', 'index': 1, 'content_block': {'type': 'tool_use', 'id': 'toolu_1', 'name': 'read_file'}},
          {'type': 'content_block_delta', 'index': 1, 'delta': {'type': 'input_json_delta', 'partial_json': '{"path":'}},
          {'type': 'content_block_delta', 'index': 1, 'delta': {'type': 'input_json_delta', 'partial_json': '"lib/main.dart"}'}},
          {'type': 'content_block_stop', 'index': 1},
          {'type': 'message_delta', 'delta': {'stop_reason': 'tool_use'}, 'usage': {'output_tokens': 30}},
          {'type': 'message_stop'},
        ])),
      );
      final events = await collect(p.chat(
        model: 'claude-opus-5',
        system: 'sys',
        messages: const [AiMessage.user('hi')],
        tools: const [AiTool(name: 'read_file', description: 'Read', parameters: {'type': 'object'})],
      ));

      expect(cap.request!.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(cap.request!.headers['x-api-key'], 'sk-ant-test');
      expect(cap.request!.headers['anthropic-version'], '2023-06-01');
      expect(cap.request!.headers['anthropic-beta'], 'server-side-fallback-2026-07-01');
      expect(cap.body!['fallbacks'], 'default');
      expect(cap.body!['system'], 'sys');
      expect(cap.body!.containsKey('temperature'), isFalse);
      expect(cap.body!['tools'][0]['input_schema'], {'type': 'object'});

      expect(events.whereType<AiTextDelta>().map((e) => e.text).join(), 'Ciao mondo');
      final call = events.whereType<AiToolCall>().single.call;
      expect((call.id, call.name), ('toolu_1', 'read_file'));
      expect(call.arguments, {'path': 'lib/main.dart'});
      final usage = events.whereType<AiUsage>().single;
      expect((usage.inputTokens, usage.outputTokens), (12, 30));
      expect(events.whereType<AiStop>().single.reason, 'tool_use');
    });

    test('no fallbacks for other models; tool results encoded as user tool_result', () async {
      final cap = Capture();
      final p = AnthropicProvider(const AiEndpoint.direct(apiKey: 'k'), client: cap.client(''));
      await collect(p.chat(model: 'claude-haiku-4-5', messages: const [
        AiMessage.user('go'),
        AiMessage.assistant('', toolCalls: [AiToolCallPart(id: 't1', name: 'x', arguments: {})]),
        AiMessage.toolResult(callId: 't1', name: 'x', result: 'ok'),
      ]));
      expect(cap.request!.headers.containsKey('anthropic-beta'), isFalse);
      expect(cap.body!.containsKey('fallbacks'), isFalse);
      final msgs = cap.body!['messages'] as List;
      expect(msgs[1]['content'][0], {'type': 'tool_use', 'id': 't1', 'name': 'x', 'input': {}});
      expect(msgs[2], {
        'role': 'user',
        'content': [{'type': 'tool_result', 'tool_use_id': 't1', 'content': 'ok'}],
      });
    });

    test('HTTP errors become AiError events, not exceptions', () async {
      final cap = Capture();
      final p = AnthropicProvider(
        const AiEndpoint.direct(apiKey: 'bad'),
        client: cap.client('{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}', status: 401),
      );
      final events = await collect(p.chat(model: 'claude-opus-5', messages: const [AiMessage.user('hi')]));
      final err = events.single as AiError;
      expect((err.statusCode, err.message), (401, 'invalid x-api-key'));
    });

    test('proxy mode sends runner auth + provider key header, not x-api-key', () async {
      final cap = Capture();
      final p = AnthropicProvider(
        const AiEndpoint.proxy(apiKey: 'sk-ant-x', runnerUrl: 'http://10.0.2.2:8787/', runnerToken: 'jwt'),
        client: cap.client(''),
      );
      await collect(p.chat(model: 'claude-opus-5', messages: const [AiMessage.user('hi')]));
      expect(cap.request!.url.toString(), 'http://10.0.2.2:8787/v1/ai/proxy/anthropic/v1/messages');
      expect(cap.request!.headers['authorization'], 'Bearer jwt');
      expect(cap.request!.headers['x-provider-key'], 'sk-ant-x');
      expect(cap.request!.headers.containsKey('x-api-key'), isFalse);
    });
  });

  group('OpenAI', () {
    test('streams text, assembles fragmented tool calls, usage and finish', () async {
      final cap = Capture();
      final p = OpenAiProvider(
        const AiEndpoint.direct(apiKey: 'sk-oa'),
        client: cap.client('${sse([
          {'choices': [{'index': 0, 'delta': {'role': 'assistant', 'content': 'He'}}]},
          {'choices': [{'index': 0, 'delta': {'content': 'llo'}}]},
          {'choices': [{'index': 0, 'delta': {'tool_calls': [{'index': 0, 'id': 'call_9', 'function': {'name': 'grep', 'arguments': '{"q":'}}]}}]},
          {'choices': [{'index': 0, 'delta': {'tool_calls': [{'index': 0, 'function': {'arguments': '"main"}'}}]}}]},
          {'choices': [{'index': 0, 'delta': {}, 'finish_reason': 'tool_calls'}]},
          {'choices': [], 'usage': {'prompt_tokens': 5, 'completion_tokens': 7}},
        ])}data: [DONE]\n\n'),
      );
      final events = await collect(p.chat(model: 'gpt-5', system: 's', messages: const [AiMessage.user('hi')]));
      expect(cap.request!.url.toString(), 'https://api.openai.com/v1/chat/completions');
      expect(cap.request!.headers['authorization'], 'Bearer sk-oa');
      expect(cap.body!['max_completion_tokens'], 16000);
      expect(cap.body!['messages'][0], {'role': 'system', 'content': 's'});
      expect(events.whereType<AiTextDelta>().map((e) => e.text).join(), 'Hello');
      final call = events.whereType<AiToolCall>().single.call;
      expect((call.id, call.name), ('call_9', 'grep'));
      expect(call.arguments, {'q': 'main'});
      expect(events.whereType<AiUsage>().single.outputTokens, 7);
      expect(events.whereType<AiStop>().single.reason, 'tool_use');
    });

    test('compatible provider: base URL with /v1, max_tokens, no auth when keyless', () async {
      final cap = Capture();
      final p = OpenAiProvider(
        const AiEndpoint.direct(apiKey: '', baseUrl: 'http://localhost:11434/v1'),
        compatible: true,
        client: cap.client('data: [DONE]\n\n'),
      );
      await collect(p.chat(model: 'llama3.2', messages: const [AiMessage.user('hi')]));
      expect(cap.request!.url.toString(), 'http://localhost:11434/v1/chat/completions');
      expect(cap.body!['max_tokens'], 16000);
      expect(cap.request!.headers.containsKey('authorization'), isFalse);
    });
  });

  test('Grok (xAI) uses Chat Completions at api.x.ai with max_tokens', () async {
    final cap = Capture();
    final p = createProvider(AiProviderId.xai, const AiEndpoint.direct(apiKey: 'xai-k')) as OpenAiProvider;
    final grok = OpenAiProvider.xai(const AiEndpoint.direct(apiKey: 'xai-k'), client: cap.client('data: [DONE]\n\n'));
    expect(p.id, AiProviderId.xai);
    await collect(grok.chat(model: 'grok-4', messages: const [AiMessage.user('hi')]));
    expect(cap.request!.url.toString(), 'https://api.x.ai/v1/chat/completions');
    expect(cap.request!.headers['authorization'], 'Bearer xai-k');
    expect(cap.body!['max_tokens'], 16000);
  });

  group('Gemini', () {
    test('streams text + function call, maps finish reason and usage', () async {
      final cap = Capture();
      var n = 0;
      final p = GeminiProvider(
        const AiEndpoint.direct(apiKey: 'AIza'),
        client: cap.client(sse([
          {'candidates': [{'content': {'role': 'model', 'parts': [{'text': 'Buon'}]}}]},
          {'candidates': [{'content': {'role': 'model', 'parts': [{'text': 'giorno'}, {'functionCall': {'name': 'list_dir', 'args': {'path': 'lib'}}}]}, 'finishReason': 'STOP'}], 'usageMetadata': {'promptTokenCount': 3, 'candidatesTokenCount': 4}},
        ])),
      );
      final events = await collect(p.chat(
        model: 'gemini-2.5-flash',
        system: 'sys',
        messages: const [
          AiMessage.user('hi'),
          AiMessage.toolResult(callId: 'c', name: 'list_dir', result: '[]'),
        ],
      ));
      expect(n, 0);
      expect(cap.request!.url.toString(),
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse');
      expect(cap.request!.headers['x-goog-api-key'], 'AIza');
      expect(cap.body!['systemInstruction'], {'parts': [{'text': 'sys'}]});
      expect(cap.body!['contents'][1]['parts'][0]['functionResponse']['name'], 'list_dir');
      expect(events.whereType<AiTextDelta>().map((e) => e.text).join(), 'Buongiorno');
      expect(events.whereType<AiToolCall>().single.call.arguments, {'path': 'lib'});
      expect(events.whereType<AiUsage>().single.inputTokens, 3);
      expect(events.whereType<AiStop>().single.reason, 'end');
    });
  });

  test('catalog costs and message JSON round-trip', () {
    final opus = builtInCatalog.firstWhere((m) => m.id == 'claude-opus-5');
    expect(opus.tags, contains('default'));
    expect(opus.inputPer1k, 0.005);
    expect(opus.estimateCost(1000000, 1000000), 30);
    final back = AiModel.fromJson(opus.toJson());
    expect(back.key, 'anthropic:claude-opus-5');

    const m = AiMessage.assistant('x', toolCalls: [AiToolCallPart(id: '1', name: 'n', arguments: {'a': 1})]);
    final r = AiMessage.fromJson(jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>);
    expect(r.toolCalls.single.arguments, {'a': 1});
  });

  test('complete() strips markdown fences', () async {
    final cap = Capture();
    final p = AnthropicProvider(
      const AiEndpoint.direct(apiKey: 'k'),
      client: cap.client(sse([
        {'type': 'content_block_delta', 'index': 0, 'delta': {'type': 'text_delta', 'text': '```dart\nprint(1);\n```'}},
      ])),
    );
    expect(await p.complete(model: 'claude-haiku-4-5', prefix: 'void main() {', suffix: '}'), 'print(1);');
    expect((cap.body!['messages'] as List).single['content'][0]['text'], 'void main() {<CURSOR>}');
  });
}
