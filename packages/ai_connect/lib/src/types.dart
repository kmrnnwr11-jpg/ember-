/// Provider families supported by ai_connect.
enum AiProviderId {
  anthropic('Anthropic', 'Claude'),
  openai('OpenAI', 'ChatGPT'),
  gemini('Google', 'Gemini'),
  openaiCompatible('OpenAI-compatible', 'Ollama / OpenRouter / Groq');

  const AiProviderId(this.vendor, this.product);
  final String vendor;
  final String product;

  static AiProviderId parse(String s) => values.firstWhere((v) => v.name == s);
}

/// How a provider is reached: user API key, or a logged-in CLI in the
/// workspace container (Phase 7).
enum AiConnectionMode { byok, cli }

enum AiRole { system, user, assistant, tool }

/// A tool the model may call. [parameters] is a JSON Schema object.
class AiTool {
  const AiTool({required this.name, required this.description, required this.parameters});

  final String name;
  final String description;
  final Map<String, dynamic> parameters;
}

/// A completed tool call requested by the model.
class AiToolCallPart {
  const AiToolCallPart({required this.id, required this.name, required this.arguments});

  final String id;
  final String name;
  final Map<String, dynamic> arguments;
}

class AiMessage {
  const AiMessage(this.role, this.content, {this.toolCalls = const [], this.toolCallId, this.toolName});

  const AiMessage.user(String content) : this(AiRole.user, content);
  const AiMessage.assistant(String content, {List<AiToolCallPart> toolCalls = const []})
    : this(AiRole.assistant, content, toolCalls: toolCalls);

  /// Result of a tool call, sent back to the model.
  const AiMessage.toolResult({required String callId, required String name, required String result})
    : this(AiRole.tool, result, toolCallId: callId, toolName: name);

  final AiRole role;
  final String content;
  final List<AiToolCallPart> toolCalls;
  final String? toolCallId;
  final String? toolName;

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content,
    if (toolCalls.isNotEmpty)
      'toolCalls': [for (final t in toolCalls) {'id': t.id, 'name': t.name, 'arguments': t.arguments}],
    if (toolCallId != null) 'toolCallId': toolCallId,
    if (toolName != null) 'toolName': toolName,
  };

  factory AiMessage.fromJson(Map<String, dynamic> j) => AiMessage(
    AiRole.values.byName(j['role'] as String),
    j['content'] as String? ?? '',
    toolCalls: [
      for (final t in (j['toolCalls'] as List? ?? const []))
        AiToolCallPart(
          id: t['id'] as String,
          name: t['name'] as String,
          arguments: (t['arguments'] as Map).cast<String, dynamic>(),
        ),
    ],
    toolCallId: j['toolCallId'] as String?,
    toolName: j['toolName'] as String?,
  );
}

/// Normalized streaming events: text_delta, tool_call, usage, stop, error.
sealed class AiEvent {
  const AiEvent();
}

class AiTextDelta extends AiEvent {
  const AiTextDelta(this.text);
  final String text;
}

class AiToolCall extends AiEvent {
  const AiToolCall(this.call);
  final AiToolCallPart call;
}

class AiUsage extends AiEvent {
  const AiUsage({this.inputTokens = 0, this.outputTokens = 0});
  final int inputTokens;
  final int outputTokens;
}

/// Why generation ended: `end`, `max_tokens`, `tool_use`, `refusal`, or the raw provider reason.
class AiStop extends AiEvent {
  const AiStop(this.reason);
  final String reason;
}

class AiError extends AiEvent {
  const AiError(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

class AiException implements Exception {
  const AiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null ? 'AiException: $message' : 'AiException($statusCode): $message';
}

/// Unified provider contract (§3).
abstract interface class AiProvider {
  AiProviderId get id;

  /// Streams a chat completion. Errors are delivered as [AiError] events,
  /// never thrown, so UIs can render partial output.
  Stream<AiEvent> chat({
    required String model,
    required List<AiMessage> messages,
    String? system,
    List<AiTool> tools = const [],
    int maxTokens = 16000,
  });

  /// Short, low-latency completion for inline autocomplete.
  Future<String> complete({required String model, required String prefix, String suffix = '', int maxTokens = 256});

  /// Text embeddings. Throws [AiException] if the provider has none.
  Future<List<List<double>>> embed({required String model, required List<String> inputs});
}
