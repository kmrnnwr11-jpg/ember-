import 'dart:convert';

import 'package:http/http.dart' as http;

import '../transport.dart';
import '../types.dart';
import 'anthropic.dart' show completionSystemPrompt, completionUserPrompt, stripFences;

/// Gemini via the Generative Language API (`streamGenerateContent?alt=sse`).
class GeminiProvider implements AiProvider {
  GeminiProvider(this.endpoint, {http.Client? client}) : _client = client ?? createStreamingClient();

  final AiEndpoint endpoint;
  final http.Client _client;
  int _callSeq = 0;

  @override
  AiProviderId get id => AiProviderId.gemini;

  Map<String, String> get _headers => endpoint.headers({'x-goog-api-key': endpoint.apiKey});

  static List<Map<String, dynamic>> encodeContents(List<AiMessage> messages) {
    final out = <Map<String, dynamic>>[];
    for (final m in messages) {
      switch (m.role) {
        case AiRole.user || AiRole.system:
          out.add({'role': 'user', 'parts': [{'text': m.content}]});
        case AiRole.assistant:
          out.add({
            'role': 'model',
            'parts': [
              if (m.content.isNotEmpty) {'text': m.content},
              for (final t in m.toolCalls) {'functionCall': {'name': t.name, 'args': t.arguments}},
            ],
          });
        case AiRole.tool:
          out.add({
            'role': 'user',
            'parts': [
              {
                'functionResponse': {
                  'name': m.toolName,
                  'response': {'result': m.content},
                },
              },
            ],
          });
      }
    }
    return out;
  }

  Map<String, dynamic> buildBody({
    required List<AiMessage> messages,
    String? system,
    List<AiTool> tools = const [],
    int maxTokens = 16000,
  }) => {
    if (system != null && system.isNotEmpty) 'systemInstruction': {'parts': [{'text': system}]},
    'contents': encodeContents(messages),
    if (tools.isNotEmpty)
      'tools': [
        {
          'functionDeclarations': [
            for (final t in tools) {'name': t.name, 'description': t.description, 'parameters': t.parameters},
          ],
        },
      ],
    'generationConfig': {'maxOutputTokens': maxTokens},
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
      Uri.parse('${endpoint.baseFor(id)}/v1beta/models/$model:streamGenerateContent${endpoint.proxyPath == null ? '?alt=sse' : ''}'),
      _headers,
      buildBody(messages: messages, system: system, tools: tools, maxTokens: maxTokens),
    );
    yield* decodeStream(res.stream, nextId: () => 'gemini_call_${++_callSeq}');
  });

  static Stream<AiEvent> decodeStream(Stream<List<int>> bytes, {required String Function() nextId}) async* {
    String? finish;
    AiUsage? usage;
    await for (final sse in parseSse(bytes)) {
      if (sse.data.isEmpty) continue;
      final j = jsonDecode(sse.data) as Map<String, dynamic>;
      if (j['error'] != null) {
        yield AiError(((j['error'] as Map)['message'] as String?) ?? 'Gemini stream error');
        continue;
      }
      final meta = j['usageMetadata'] as Map?;
      if (meta != null) {
        usage = AiUsage(
          inputTokens: meta['promptTokenCount'] as int? ?? 0,
          outputTokens: meta['candidatesTokenCount'] as int? ?? 0,
        );
      }
      final candidates = j['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        final block = (j['promptFeedback'] as Map?)?['blockReason'];
        if (block != null) finish = 'SAFETY';
        continue;
      }
      final cand = candidates.first as Map<String, dynamic>;
      for (final part in ((cand['content'] as Map?)?['parts'] as List? ?? const [])) {
        final p = part as Map<String, dynamic>;
        if (p['thought'] == true) continue;
        if (p['text'] is String && (p['text'] as String).isNotEmpty) yield AiTextDelta(p['text'] as String);
        final fc = p['functionCall'] as Map?;
        if (fc != null) {
          yield AiToolCall(AiToolCallPart(
            id: fc['id'] as String? ?? nextId(),
            name: fc['name'] as String,
            arguments: (fc['args'] as Map? ?? const {}).cast<String, dynamic>(),
          ));
        }
      }
      finish = cand['finishReason'] as String? ?? finish;
    }
    if (usage != null) yield usage;
    if (finish != null) {
      yield AiStop(switch (finish) {
        'STOP' => 'end',
        'MAX_TOKENS' => 'max_tokens',
        'SAFETY' || 'PROHIBITED_CONTENT' || 'BLOCKLIST' || 'RECITATION' => 'refusal',
        _ => finish.toLowerCase(),
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
    final j = await postJson(
      _client,
      Uri.parse('${endpoint.baseFor(id)}/v1beta/models/$model:batchEmbedContents'),
      _headers,
      {
        'requests': [
          for (final text in inputs)
            {
              'model': 'models/$model',
              'content': {'parts': [{'text': text}]},
            },
        ],
      },
    );
    return [
      for (final e in j['embeddings'] as List) ((e as Map)['values'] as List).map((v) => (v as num).toDouble()).toList(),
    ];
  }
}
