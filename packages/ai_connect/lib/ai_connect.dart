/// AI provider layer for Ember and the apps it generates:
/// Claude (Anthropic), ChatGPT (OpenAI), Gemini (Google) and any
/// OpenAI-compatible server, with one streaming/tool-calling interface.
library;

export 'src/catalog.dart';
export 'src/providers/anthropic.dart' show AnthropicProvider;
export 'src/providers/gemini.dart' show GeminiProvider;
export 'src/providers/openai.dart' show OpenAiProvider;
export 'src/transport.dart' show AiEndpoint, SseEvent, parseSse, createStreamingClient;
export 'src/types.dart';
