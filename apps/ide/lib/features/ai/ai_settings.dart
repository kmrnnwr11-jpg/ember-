import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings_store.dart';

import '../../core/session.dart';
import '../review/reviewers.dart';

/// User AI configuration. Keys live in secure storage; the rest in prefs.
@immutable
class AiSettings {
  const AiSettings({
    this.keys = const {},
    this.compatibleBaseUrl = '',
    this.useProxy = true,
    this.defaultModel = 'anthropic:claude-opus-5',
    this.customModels = const [],
  });

  final Map<AiProviderId, String> keys;
  final String compatibleBaseUrl;

  /// Route calls through the Runner. Always true on web (CORS, key exposure).
  final bool useProxy;
  final String defaultModel;

  /// Extra model ids the user typed (e.g. `openaiCompatible:llama3.2`).
  final List<String> customModels;

  bool get effectiveProxy => kIsWeb || useProxy;

  bool isConfigured(AiProviderId p) =>
      p == AiProviderId.openaiCompatible ? compatibleBaseUrl.isNotEmpty : (keys[p]?.isNotEmpty ?? false);

  AiSettings copyWith({
    Map<AiProviderId, String>? keys,
    String? compatibleBaseUrl,
    bool? useProxy,
    String? defaultModel,
    List<String>? customModels,
  }) => AiSettings(
    keys: keys ?? this.keys,
    compatibleBaseUrl: compatibleBaseUrl ?? this.compatibleBaseUrl,
    useProxy: useProxy ?? this.useProxy,
    defaultModel: defaultModel ?? this.defaultModel,
    customModels: customModels ?? this.customModels,
  );
}

class AiSettingsController extends AsyncNotifier<AiSettings> {
  static String _keyName(AiProviderId p) => 'ai_key_${p.name}';

  // Saved on the Runner: a restarted or different browser keeps the keys.
  KeyValueStore get _secure => ref.read(settingsStoreProvider);

  @override
  Future<AiSettings> build() async {
    final prefs = Settings.instance;
    final keys = <AiProviderId, String>{};
    for (final p in AiProviderId.values) {
      final k = await _secure.read(_keyName(p));
      if (k != null && k.isNotEmpty) keys[p] = k;
    }
    return AiSettings(
      keys: keys,
      compatibleBaseUrl: await prefs.read('ai_compat_base') ?? '',
      useProxy: (await prefs.read('ai_use_proxy')) != 'false',
      defaultModel: await prefs.read('ai_default_model') ?? 'anthropic:claude-opus-5',
      customModels: ((await prefs.read('ai_custom_models')) ?? '').split('\n').where((m) => m.isNotEmpty).toList(),
    );
  }

  Future<void> setKey(AiProviderId p, String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _secure.delete(_keyName(p));
    } else {
      await _secure.write(_keyName(p), trimmed);
    }
    final s = await future;
    final keys = {...s.keys}..remove(p);
    if (trimmed.isNotEmpty) keys[p] = trimmed;
    state = AsyncData(s.copyWith(keys: keys));
  }

  Future<void> updateSettings({String? compatibleBaseUrl, bool? useProxy, String? defaultModel, List<String>? customModels}) async {
    final prefs = Settings.instance;
    if (compatibleBaseUrl != null) await prefs.write('ai_compat_base', compatibleBaseUrl.trim());
    if (useProxy != null) await prefs.write('ai_use_proxy', '$useProxy');
    if (defaultModel != null) await prefs.write('ai_default_model', defaultModel);
    if (customModels != null) await prefs.write('ai_custom_models', customModels.join('\n'));
    final s = await future;
    state = AsyncData(s.copyWith(
      compatibleBaseUrl: compatibleBaseUrl?.trim(),
      useProxy: useProxy,
      defaultModel: defaultModel,
      customModels: customModels,
    ));
  }
}

final aiSettingsProvider = AsyncNotifierProvider<AiSettingsController, AiSettings>(AiSettingsController.new);

/// Model catalog: Runner's remote catalog, falling back to the built-in one,
/// plus any custom model ids the user added.
final aiCatalogProvider = FutureProvider<List<AiModel>>((ref) async {
  final settings = await ref.watch(aiSettingsProvider.future);
  var models = builtInCatalog;
  final session = ref.watch(sessionProvider).value;
  if (session != null) {
    try {
      final token = await session.token();
      final res = await Dio().get<Map<String, dynamic>>(
        '${session.runnerUrl}/v1/ai/models',
        options: Options(headers: {'authorization': 'Bearer $token'}, receiveTimeout: const Duration(seconds: 5)),
      );
      final list = res.data?['models'] as List?;
      if (list != null && list.isNotEmpty) {
        models = [
          for (final m in list)
            if (AiProviderId.values.any((p) => p.name == (m as Map)['provider'])) AiModel.fromJson(m as Map<String, dynamic>),
        ];
      }
    } catch (_) {
      // offline or old Runner: keep the built-in catalog
    }
  }
  final custom = [
    for (final key in settings.customModels)
      if (key.contains(':'))
        AiModel(
          provider: AiProviderId.parse(key.substring(0, key.indexOf(':'))),
          id: key.substring(key.indexOf(':') + 1),
          label: key.substring(key.indexOf(':') + 1),
        ),
  ];
  return [...models.where((m) => !m.tags.contains('embeddings')), ...custom];
});

/// Builds a provider for [model] from the current settings and session.
/// Whether the Runner offers Gemini on its own key (no user key needed).
bool serverGeminiAvailable(Map<String, dynamic>? health) => (health?['engines'] as Map?)?['serverGemini'] == true;

Future<Map<String, dynamic>?> _health(Ref ref) async {
  try {
    return await ref.read(runnerHealthProvider.future);
  } catch (_) {
    return null;
  }
}

/// A provider is usable with the user's key, or Gemini through the Runner.
bool canUseProvider(AiSettings s, AiProviderId p, Map<String, dynamic>? health) =>
    s.isConfigured(p) || (p == AiProviderId.gemini && serverGeminiAvailable(health));

final aiProviderFactory = Provider<Future<AiProvider> Function(AiModel model)>((ref) {
  return (model) async {
    final settings = await ref.read(aiSettingsProvider.future);
    final session = ref.read(sessionProvider).value;
    var key = settings.keys[model.provider] ?? '';
    // A model with its own address takes the key pasted for the matching panel
    // voice, so the same key serves both and there is only one place to put it.
    if (key.isEmpty && model.baseUrl?.isNotEmpty == true) {
      final panel = await ref.read(reviewerSettingsProvider.future);
      key = panel.keys.entries
              .firstWhere((e) => panel.reviewers.any((r) => r.id == e.key && r.baseUrl == model.baseUrl),
                  orElse: () => const MapEntry('', ''))
              .value;
      if (key.isNotEmpty) {
        final session2 = ref.read(sessionProvider).value;
        return createProvider(
          model.provider,
          settings.effectiveProxy && session2 != null
              ? AiEndpoint.proxy(apiKey: key, runnerUrl: session2.runnerUrl, runnerToken: await session2.token(), baseUrl: model.baseUrl)
              : AiEndpoint.direct(apiKey: key, baseUrl: model.baseUrl),
        );
      }
    }
    if (key.isEmpty && !settings.isConfigured(model.provider)) {
      // No personal key: Gemini runs on the Runner's key, so users never need one.
      if (model.provider == AiProviderId.gemini && session != null && serverGeminiAvailable(await _health(ref))) {
        return createProvider(
          model.provider,
          AiEndpoint.proxy(apiKey: '', runnerUrl: session.runnerUrl, runnerToken: await session.token(), proxyPath: 'builder'),
        );
      }
      throw AiException('No API key configured for ${model.provider.vendor}');
    }
    // The model's own address wins: DeepSeek and Qwen are both
    // OpenAI-compatible but live at different servers, and the single shared
    // setting can only point at one of them.
    final baseUrl = model.baseUrl?.isNotEmpty == true
        ? model.baseUrl
        : (model.provider == AiProviderId.openaiCompatible ? settings.compatibleBaseUrl : null);
    final endpoint = settings.effectiveProxy && session != null
        ? AiEndpoint.proxy(apiKey: key, runnerUrl: session.runnerUrl, runnerToken: await session.token(), baseUrl: baseUrl)
        : AiEndpoint.direct(apiKey: key, baseUrl: baseUrl);
    return createProvider(model.provider, endpoint);
  };
});

/// Last model used per project (§1.2), kept on the Runner.
class ProjectModelStore {
  static Future<String?> get(String projectId) => Settings.instance.read('ai_model_$projectId');
  static Future<void> set(String projectId, String modelKey) => Settings.instance.write('ai_model_$projectId', modelKey);
}

/// Chat history per project, kept on the Runner (last 200 messages).
class ChatHistoryStore {
  static Future<List<Map<String, dynamic>>> load(String projectId) async {
    final raw = await Settings.instance.read('ai_chat_$projectId');
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(String projectId, List<Map<String, dynamic>> entries) async {
    final trimmed = entries.length > 200 ? entries.sublist(entries.length - 200) : entries;
    await Settings.instance.write('ai_chat_$projectId', jsonEncode(trimmed));
  }
}
