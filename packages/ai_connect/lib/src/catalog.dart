import 'transport.dart';
import 'types.dart';
import 'providers/anthropic.dart';
import 'providers/gemini.dart';
import 'providers/openai.dart';

/// One selectable model (§3 model picker).
class AiModel {
  const AiModel({
    required this.provider,
    required this.id,
    required this.label,
    this.inputPerMTok,
    this.outputPerMTok,
    this.contextTokens,
    this.tools = true,
    this.tags = const [],
  });

  final AiProviderId provider;
  final String id;
  final String label;

  /// USD per million tokens; null when unknown (e.g. local models).
  final double? inputPerMTok;
  final double? outputPerMTok;
  final int? contextTokens;
  final bool tools;

  /// e.g. `default`, `fast`, `autocomplete`, `embeddings`.
  final List<String> tags;

  String get key => '${provider.name}:$id';

  double? get inputPer1k => inputPerMTok == null ? null : inputPerMTok! / 1000;
  double? get outputPer1k => outputPerMTok == null ? null : outputPerMTok! / 1000;

  /// Estimated USD cost of a request.
  double? estimateCost(int inputTokens, int outputTokens) =>
      inputPerMTok == null || outputPerMTok == null
          ? null
          : (inputTokens * inputPerMTok! + outputTokens * outputPerMTok!) / 1e6;

  factory AiModel.fromJson(Map<String, dynamic> j) => AiModel(
    provider: AiProviderId.parse(j['provider'] as String),
    id: j['id'] as String,
    label: j['label'] as String? ?? j['id'] as String,
    inputPerMTok: (j['inputPerMTok'] as num?)?.toDouble(),
    outputPerMTok: (j['outputPerMTok'] as num?)?.toDouble(),
    contextTokens: (j['contextTokens'] as num?)?.toInt(),
    tools: j['tools'] as bool? ?? true,
    tags: [for (final t in (j['tags'] as List? ?? const [])) t as String],
  );

  Map<String, dynamic> toJson() => {
    'provider': provider.name,
    'id': id,
    'label': label,
    'inputPerMTok': inputPerMTok,
    'outputPerMTok': outputPerMTok,
    'contextTokens': contextTokens,
    'tools': tools,
    'tags': tags,
  };
}

/// Built-in catalog used when the Runner's remote catalog is unavailable.
/// Prices are list prices at the time of writing; the Runner catalog
/// (`GET /v1/ai/models`) is the source to update without an app release.
const builtInCatalog = <AiModel>[
  AiModel(provider: AiProviderId.anthropic, id: 'claude-opus-5', label: 'Claude Opus 5', inputPerMTok: 5, outputPerMTok: 25, contextTokens: 1000000, tags: ['default']),
  AiModel(provider: AiProviderId.anthropic, id: 'claude-fable-5-1', label: 'Claude Fable 5.1', inputPerMTok: 10, outputPerMTok: 50, contextTokens: 1000000),
  AiModel(provider: AiProviderId.anthropic, id: 'claude-sonnet-5', label: 'Claude Sonnet 5', inputPerMTok: 2, outputPerMTok: 10, contextTokens: 1000000),
  AiModel(provider: AiProviderId.anthropic, id: 'claude-haiku-4-5', label: 'Claude Haiku 4.5', inputPerMTok: 1, outputPerMTok: 5, contextTokens: 200000, tags: ['fast', 'autocomplete']),
  AiModel(provider: AiProviderId.openai, id: 'gpt-5', label: 'GPT-5', inputPerMTok: 1.25, outputPerMTok: 10, contextTokens: 400000),
  AiModel(provider: AiProviderId.openai, id: 'gpt-5-mini', label: 'GPT-5 mini', inputPerMTok: 0.25, outputPerMTok: 2, contextTokens: 400000, tags: ['fast', 'autocomplete']),
  AiModel(provider: AiProviderId.openai, id: 'text-embedding-3-small', label: 'text-embedding-3-small', inputPerMTok: 0.02, outputPerMTok: 0, tools: false, tags: ['embeddings']),
  AiModel(provider: AiProviderId.xai, id: 'grok-4', label: 'Grok 4', inputPerMTok: 3, outputPerMTok: 15, contextTokens: 256000),
  AiModel(provider: AiProviderId.xai, id: 'grok-3-mini', label: 'Grok 3 mini', inputPerMTok: 0.30, outputPerMTok: 0.50, contextTokens: 131072, tags: ['fast']),
  AiModel(provider: AiProviderId.gemini, id: 'gemini-2.5-pro', label: 'Gemini 2.5 Pro', inputPerMTok: 1.25, outputPerMTok: 10, contextTokens: 1000000),
  AiModel(provider: AiProviderId.gemini, id: 'gemini-2.5-flash', label: 'Gemini 2.5 Flash', inputPerMTok: 0.30, outputPerMTok: 2.50, contextTokens: 1000000, tags: ['fast', 'autocomplete']),
  AiModel(provider: AiProviderId.gemini, id: 'gemini-embedding-001', label: 'Gemini Embedding', inputPerMTok: 0.15, outputPerMTok: 0, tools: false, tags: ['embeddings']),
];

/// Creates the adapter for [provider].
AiProvider createProvider(AiProviderId provider, AiEndpoint endpoint) => switch (provider) {
  AiProviderId.anthropic => AnthropicProvider(endpoint),
  AiProviderId.openai => OpenAiProvider(endpoint),
  AiProviderId.openaiCompatible => OpenAiProvider(endpoint, compatible: true),
  AiProviderId.gemini => GeminiProvider(endpoint),
  AiProviderId.xai => OpenAiProvider.xai(endpoint),
};
