/// Provider families supported by ai_connect.
enum AiProviderId { anthropic, openai, gemini, openaiCompatible }

/// How a provider is reached: user API key, or a logged-in CLI in the
/// workspace container (Phase 7).
enum AiConnectionMode { byok, cli }

enum AiRole { system, user, assistant, tool }

class AiMessage {
  const AiMessage(this.role, this.content);

  final AiRole role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role.name, 'content': content};
}

/// Normalized streaming events (§5B): text_delta, tool_call, usage, error, done.
sealed class AiEvent {
  const AiEvent();
}

class AiTextDelta extends AiEvent {
  const AiTextDelta(this.text);
  final String text;
}

class AiToolCall extends AiEvent {
  const AiToolCall(this.id, this.name, this.arguments);
  final String id;
  final String name;
  final Map<String, dynamic> arguments;
}

class AiUsage extends AiEvent {
  const AiUsage(this.inputTokens, this.outputTokens);
  final int inputTokens;
  final int outputTokens;
}

class AiError extends AiEvent {
  const AiError(this.message);
  final String message;
}

class AiDone extends AiEvent {
  const AiDone();
}

/// Unified provider contract.
abstract interface class AiProvider {
  AiProviderId get id;

  Stream<AiEvent> chat({
    required String model,
    required List<AiMessage> messages,
    String? system,
    int maxTokens = 4096,
  });

  Future<String> complete({
    required String model,
    required String prefix,
    String suffix = '',
  });

  Future<List<List<double>>> embed({
    required String model,
    required List<String> inputs,
  });
}
