import 'dart:convert';

import 'package:http/http.dart' as http;

import '../transport.dart';
import '../types.dart';
import 'anthropic.dart' show completionSystemPrompt, completionUserPrompt, stripFences;

/// ChatGPT and OpenAI-compatible servers (Ollama, OpenRouter, Groq, …) via
/// Chat Completions — the most widely implemented streaming dialect.
class OpenAiProvider implements AiProvider {
  OpenAiProvider(this.endpoint, {this.compatible = false, AiProviderId? providerId, http.Client? client})
    : _id = providerId ?? (compatible ? AiProviderId.openaiCompatible : AiProviderId.openai),
      _client = client ?? createStreamingClient();

  /// Grok (xAI) speaks the same Chat Completions dialect.
  OpenAiProvider.xai(AiEndpoint endpoint, {http.Client? client})
    : this(endpoint, compatible: true, providerId: AiProviderId.xai, client: client);

  final AiEndpoint endpoint;
  final bool compatible;
  final AiProviderId _id;
  final http.Client _client;

  @override
  AiProviderId get id => _id;

  Map<String, String> get _headers =>
      endpoint.headers({if (endpoint.apiKey.isNotEmpty) 'authorization': 'Bearer ${endpoint.apiKey}'});

  String get _v1 {
    final base = endpoint.baseFor(id);
    // Compatible base URLs are often given with /v1 already (e.g. http://localhost:11434/v1).
    return !endpoint.proxied && _id == AiProviderId.openaiCompatible && base.endsWith('/v1') ? base : '$base/v1';
  }

  static List<Map<String, dynamic>> encodeMessages(List<AiMessage> messages, String? system) => [
    if (system != null && system.isNotEmpty) {'role': 'system', 'content': system},
    for (final m in messages)
      switch (m.role) {
        AiRole.tool => {'role': 'tool', 'tool_call_id': m.toolCallId, 'content': m.content},
        AiRole.assistant => {
          'role': 'assistant',
          'content': m.content.isEmpty && m.toolCalls.isNotEmpty ? null : m.content,
          if (m.toolCalls.isNotEmpty)
            'tool_calls': [
              for (final t in m.toolCalls)
                {
                  'id': t.id,
                  'type': 'function',
                  'function': {'name': t.name, 'arguments': jsonEncode(t.arguments)},
                },
            ],
        },
        _ => {'role': m.role.name, 'content': m.content},
      },
  ];

  Map<String, dynamic> buildBody({
    required String model,
    required List<AiMessage> messages,
    String? system,
    List<AiTool> tools = const [],
    int maxTokens = 16000,
  }) => {
    'model': model,
    'stream': true,
    'stream_options': {'include_usage': true},
    // OpenAI renamed the limit; many compatible servers still only accept max_tokens.
    compatible ? 'max_tokens' : 'max_completion_tokens': maxTokens,
    'messages': encodeMessages(messages, system),
    if (tools.isNotEmpty)
      'tools': [
        for (final t in tools)
          {
            'type': 'function',
            'function': {'name': t.name, 'description': t.description, 'parameters': t.parameters},
          },
      ],
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
      Uri.parse('$_v1/chat/completions'),
      _headers,
      buildBody(model: model, messages: messages, system: system, tools: tools, maxTokens: maxTokens),
    );
    yield* decodeStream(res.stream);
  });

  static Stream<AiEvent> decodeStream(Stream<List<int>> bytes) async* {
    final calls = <int, ({StringBuffer id, StringBuffer name, StringBuffer args})>{};
    String? finish;
    await for (final sse in parseSse(bytes)) {
      if (sse.data == '[DONE]') break;
      if (sse.data.isEmpty) continue;
      final j = jsonDecode(sse.data) as Map<String, dynamic>;
      if (j['error'] != null) {
        yield AiError(((j['error'] as Map)['message'] as String?) ?? 'stream error');
        continue;
      }
      final usage = j['usage'] as Map?;
      if (usage != null) {
        yield AiUsage(
          inputTokens: usage['prompt_tokens'] as int? ?? 0,
          outputTokens: usage['completion_tokens'] as int? ?? 0,
        );
      }
      final choices = j['choices'] as List?;
      if (choices == null || choices.isEmpty) continue;
      final choice = choices.first as Map<String, dynamic>;
      final delta = choice['delta'] as Map<String, dynamic>? ?? const {};
      final text = delta['content'];
      if (text is String && text.isNotEmpty) yield AiTextDelta(text);
      for (final tc in (delta['tool_calls'] as List? ?? const [])) {
        final t = tc as Map<String, dynamic>;
        final slot = calls.putIfAbsent(
          t['index'] as int? ?? 0,
          () => (id: StringBuffer(), name: StringBuffer(), args: StringBuffer()),
        );
        if (t['id'] is String) slot.id.write(t['id']);
        final fn = t['function'] as Map?;
        if (fn?['name'] is String) slot.name.write(fn!['name']);
        if (fn?['arguments'] is String) slot.args.write(fn!['arguments']);
      }
      finish = choice['finish_reason'] as String? ?? finish;
    }
    for (final entry in calls.entries) {
      final raw = entry.value.args.toString();
      yield AiToolCall(AiToolCallPart(
        id: entry.value.id.isEmpty ? 'call_${entry.key}' : entry.value.id.toString(),
        name: entry.value.name.toString(),
        arguments: raw.isEmpty ? {} : (jsonDecode(raw) as Map).cast<String, dynamic>(),
      ));
    }
    if (finish != null) {
      yield AiStop(switch (finish) {
        'stop' => 'end',
        'length' => 'max_tokens',
        'tool_calls' => 'tool_use',
        'content_filter' => 'refusal',
        _ => finish,
      });
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
  Future<List<List<double>>> embed({required String model, required List<String> inputs}) async {
    final j = await postJson(_client, Uri.parse('$_v1/embeddings'), _headers, {'model': model, 'input': inputs});
    final data = (j['data'] as List).cast<Map<String, dynamic>>()..sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
    return [for (final d in data) (d['embedding'] as List).map((v) => (v as num).toDouble()).toList()];
  }
}
