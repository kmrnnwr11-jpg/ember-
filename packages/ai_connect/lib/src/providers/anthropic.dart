import 'dart:convert';

import 'package:http/http.dart' as http;

import '../transport.dart';
import '../types.dart';

/// Claude via the Messages API (`POST /v1/messages`, SSE streaming).
class AnthropicProvider implements AiProvider {
  AnthropicProvider(this.endpoint, {http.Client? client}) : _client = client ?? createStreamingClient();

  final AiEndpoint endpoint;
  final http.Client _client;

  static const apiVersion = '2023-06-01';

  /// Models that support server-side refusal fallbacks (`fallbacks: "default"`).
  static bool supportsFallbacks(String model) => model == 'claude-opus-5' || model.startsWith('claude-fable-5-1');

  @override
  AiProviderId get id => AiProviderId.anthropic;

  Map<String, String> _headers(String model) => {
    ...endpoint.headers({'x-api-key': endpoint.apiKey}),
    'anthropic-version': apiVersion,
    if (supportsFallbacks(model)) 'anthropic-beta': 'server-side-fallback-2026-07-01',
  };

  static List<Map<String, dynamic>> encodeMessages(List<AiMessage> messages) {
    final out = <Map<String, dynamic>>[];
    for (final m in messages) {
      switch (m.role) {
        case AiRole.system:
          // Top-level `system` carries the system prompt; inline system turns become user text.
          out.add({'role': 'user', 'content': [{'type': 'text', 'text': m.content}]});
        case AiRole.user:
          out.add({'role': 'user', 'content': [{'type': 'text', 'text': m.content}]});
        case AiRole.assistant:
          out.add({
            'role': 'assistant',
            'content': [
              if (m.content.isNotEmpty) {'type': 'text', 'text': m.content},
              for (final t in m.toolCalls) {'type': 'tool_use', 'id': t.id, 'name': t.name, 'input': t.arguments},
            ],
          });
        case AiRole.tool:
          out.add({
            'role': 'user',
            'content': [
              {'type': 'tool_result', 'tool_use_id': m.toolCallId, 'content': m.content},
            ],
          });
      }
    }
    return out;
  }

  Map<String, dynamic> buildBody({
    required String model,
    required List<AiMessage> messages,
    String? system,
    List<AiTool> tools = const [],
    int maxTokens = 16000,
    bool stream = true,
  }) => {
    'model': model,
    'max_tokens': maxTokens,
    'stream': stream,
    if (system != null && system.isNotEmpty) 'system': system,
    'messages': encodeMessages(messages),
    if (tools.isNotEmpty)
      'tools': [
        for (final t in tools) {'name': t.name, 'description': t.description, 'input_schema': t.parameters},
      ],
    // On a policy decline the API transparently re-runs on a fallback model.
    if (supportsFallbacks(model)) 'fallbacks': 'default',
  };

  @override
  Stream<AiEvent> chat({
    required String model,
    required List<AiMessage> messages,
    String? system,
    List<AiTool> tools = const [],
    int maxTokens = 16000,
  }) => guardStream(() async* {
    final res = await postStream(
      _client,
      Uri.parse('${endpoint.baseFor(id)}/v1/messages'),
      _headers(model),
      buildBody(model: model, messages: messages, system: system, tools: tools, maxTokens: maxTokens),
    );
    yield* decodeStream(res.stream);
  });

  /// Decodes Messages API SSE into normalized events.
  static Stream<AiEvent> decodeStream(Stream<List<int>> bytes) async* {
    final toolBlocks = <int, ({String id, String name, StringBuffer json})>{};
    var input = 0;
    await for (final sse in parseSse(bytes)) {
      if (sse.data.isEmpty) continue;
      final j = jsonDecode(sse.data) as Map<String, dynamic>;
      switch (j['type']) {
        case 'message_start':
          input = ((j['message'] as Map)['usage'] as Map?)?['input_tokens'] as int? ?? 0;
        case 'content_block_start':
          final block = j['content_block'] as Map<String, dynamic>;
          if (block['type'] == 'tool_use') {
            toolBlocks[j['index'] as int] = (id: block['id'] as String, name: block['name'] as String, json: StringBuffer());
          }
        case 'content_block_delta':
          final delta = j['delta'] as Map<String, dynamic>;
          switch (delta['type']) {
            case 'text_delta':
              yield AiTextDelta(delta['text'] as String);
            case 'input_json_delta':
              toolBlocks[j['index'] as int]?.json.write(delta['partial_json'] as String);
          }
        case 'content_block_stop':
          final tb = toolBlocks.remove(j['index'] as int);
          if (tb != null) {
            final raw = tb.json.toString();
            final args = raw.isEmpty ? <String, dynamic>{} : (jsonDecode(raw) as Map).cast<String, dynamic>();
            yield AiToolCall(AiToolCallPart(id: tb.id, name: tb.name, arguments: args));
          }
        case 'message_delta':
          final usage = j['usage'] as Map?;
          yield AiUsage(inputTokens: input, outputTokens: usage?['output_tokens'] as int? ?? 0);
          final reason = (j['delta'] as Map?)?['stop_reason'] as String?;
          if (reason != null) {
            yield AiStop(switch (reason) {
              'end_turn' || 'stop_sequence' => 'end',
              _ => reason,
            });
          }
        case 'error':
          yield AiError(((j['error'] as Map?)?['message'] as String?) ?? 'Anthropic stream error');
      }
    }
  }

  @override
  Future<String> complete({required String model, required String prefix, String suffix = '', int maxTokens = 256}) async {
    final buf = StringBuffer();
    await for (final e in chat(
      model: model,
      maxTokens: maxTokens,
      system: completionSystemPrompt,
      messages: [AiMessage.user(completionUserPrompt(prefix, suffix))],
    )) {
      if (e is AiTextDelta) buf.write(e.text);
      if (e is AiError) throw AiException(e.message, statusCode: e.statusCode);
    }
    return stripFences(buf.toString());
  }

  @override
  Future<List<List<double>>> embed({required String model, required List<String> inputs}) =>
      Future.error(const AiException('Anthropic does not offer an embeddings API; use OpenAI or Gemini embeddings.'));
}

const completionSystemPrompt =
    'You are a code completion engine. Output ONLY the code that belongs at <CURSOR>, '
    'with no explanation and no markdown fences. Output nothing if no completion fits.';

String completionUserPrompt(String prefix, String suffix) => '$prefix<CURSOR>$suffix';

String stripFences(String s) {
  final m = RegExp(r'^```[\w-]*\n([\s\S]*?)\n?```\s*$').firstMatch(s.trim());
  return m != null ? m.group(1)! : s;
}
