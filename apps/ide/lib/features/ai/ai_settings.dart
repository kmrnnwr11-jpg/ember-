import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/session.dart';

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

  KeyValueStore get _secure => ref.read(keyValueStoreProvider);

  @override
  Future<AiSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = <AiProviderId, String>{};
    for (final p in AiProviderId.values) {
      final k = await _secure.read(_keyName(p));
      if (k != null && k.isNotEmpty) keys[p] = k;
    }
    return AiSettings(
      keys: keys,
      compatibleBaseUrl: prefs.getString('ai_compat_base') ?? '',
      useProxy: prefs.getBool('ai_use_proxy') ?? true,
      defaultModel: prefs.getString('ai_default_model') ?? 'anthropic:claude-opus-5',
      customModels: prefs.getStringList('ai_custom_models') ?? const [],
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
    final prefs = await SharedPreferences.getInstance();
    if (compatibleBaseUrl != null) await prefs.setString('ai_compat_base', compatibleBaseUrl.trim());
    if (useProxy != null) await prefs.setBool('ai_use_proxy', useProxy);
    if (defaultModel != null) await prefs.setString('ai_default_model', defaultModel);
    if (customModels != null) await prefs.setStringList('ai_custom_models', customModels);
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
final aiProviderFactory = Provider<Future<AiProvider> Function(AiModel model)>((ref) {
  return (model) async {
    final settings = await ref.read(aiSettingsProvider.future);
    final session = ref.read(sessionProvider).value;
    final key = settings.keys[model.provider] ?? '';
    if (!settings.isConfigured(model.provider)) {
      throw AiException('No API key configured for ${model.provider.vendor}');
    }
    final baseUrl = model.provider == AiProviderId.openaiCompatible ? settings.compatibleBaseUrl : null;
    final endpoint = settings.effectiveProxy && session != null
        ? AiEndpoint.proxy(apiKey: key, runnerUrl: session.runnerUrl, runnerToken: await session.token(), baseUrl: baseUrl)
        : AiEndpoint.direct(apiKey: key, baseUrl: baseUrl);
    return createProvider(model.provider, endpoint);
  };
});

/// Last model used per project (§1.2), persisted locally.
class ProjectModelStore {
  static Future<String?> get(String projectId) async =>
      (await SharedPreferences.getInstance()).getString('ai_model_$projectId');
  static Future<void> set(String projectId, String modelKey) async =>
      (await SharedPreferences.getInstance()).setString('ai_model_$projectId', modelKey);
}

/// Chat history per project, persisted locally (last 200 messages).
class ChatHistoryStore {
  static Future<List<Map<String, dynamic>>> load(String projectId) async {
    final raw = (await SharedPreferences.getInstance()).getString('ai_chat_$projectId');
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(String projectId, List<Map<String, dynamic>> entries) async {
    final trimmed = entries.length > 200 ? entries.sublist(entries.length - 200) : entries;
    await (await SharedPreferences.getInstance()).setString('ai_chat_$projectId', jsonEncode(trimmed));
  }
}
