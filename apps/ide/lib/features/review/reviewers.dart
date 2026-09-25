import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';

/// One extra model that reviews a finished app. They are all OpenAI-compatible
/// services (DeepSeek, Groq, GitHub Models, OpenRouter, a local Ollama...), so
/// one adapter serves them all: what changes is the address, the key and the
/// model name.
@immutable
class Reviewer {
  const Reviewer({required this.id, required this.label, required this.baseUrl, required this.model});

  /// Stable slug: names the key in secure storage, so renaming keeps the key.
  final String id;
  final String label;
  final String baseUrl;
  final String model;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'baseUrl': baseUrl, 'model': model};

  static Reviewer fromJson(Map<String, dynamic> j) => Reviewer(
        id: '${j['id'] ?? ''}',
        label: '${j['label'] ?? ''}',
        baseUrl: '${j['baseUrl'] ?? ''}',
        model: '${j['model'] ?? ''}',
      );

  Reviewer copyWith({String? label, String? baseUrl, String? model}) =>
      Reviewer(id: id, label: label ?? this.label, baseUrl: baseUrl ?? this.baseUrl, model: model ?? this.model);
}

/// The services worth offering with one tap: the address and a sensible model
/// are already right, the user only pastes the key.
const reviewerPresets = <Reviewer>[
  Reviewer(id: 'deepseek', label: 'DeepSeek', baseUrl: 'https://api.deepseek.com', model: 'deepseek-chat'),
  Reviewer(id: 'groq', label: 'Groq', baseUrl: 'https://api.groq.com/openai/v1', model: 'openai/gpt-oss-120b'),
  // Google speaks the OpenAI format too, so the key already in Ember for
  // writing apps also serves to review them — pasted again here, because a
  // reviewer must stay a choice of its own.
  Reviewer(
    id: 'gemini',
    label: 'Gemini (Google)',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    model: 'gemini-2.5-flash',
  ),
  // One key, many models: the ones ending in :free cost nothing.
  Reviewer(
    id: 'openrouter',
    label: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    model: 'deepseek/deepseek-chat-v3.1:free',
  ),
];

/// The reviewers the user configured, with their keys.
@immutable
class ReviewerSettings {
  const ReviewerSettings({this.reviewers = const [], this.keys = const {}});

  final List<Reviewer> reviewers;
  final Map<String, String> keys;

  /// Only the ones that can actually be called.
  List<Reviewer> get usable =>
      [for (final r in reviewers) if ((keys[r.id] ?? '').isNotEmpty && r.baseUrl.isNotEmpty && r.model.isNotEmpty) r];

  bool hasKey(String id) => (keys[id] ?? '').isNotEmpty;
}

class ReviewerSettingsController extends AsyncNotifier<ReviewerSettings> {
  static const _listKey = 'ai_reviewers';
  static String _keyName(String id) => 'ai_reviewer_key_$id';

  KeyValueStore get _secure => ref.read(settingsStoreProvider);

  @override
  Future<ReviewerSettings> build() async {
    final raw = await Settings.instance.read(_listKey) ?? '';
    final saved = <String, Reviewer>{};
    if (raw.trim().isNotEmpty) {
      try {
        for (final e in jsonDecode(raw) as List) {
          final r = Reviewer.fromJson((e as Map).cast<String, dynamic>());
          if (r.id.isNotEmpty) saved[r.id] = r;
        }
      } catch (_) {
        // A corrupted list just means starting from the presets again.
      }
    }
    // The presets decide who is on the list; a saved entry only carries the
    // user's own edits for one of them. A service dropped from the presets
    // disappears instead of lingering from an older version.
    final list = [for (final p in reviewerPresets) saved[p.id] ?? p];
    final keys = <String, String>{};
    for (final r in list) {
      final k = await _secure.read(_keyName(r.id));
      if (k != null && k.isNotEmpty) keys[r.id] = k;
    }
    return ReviewerSettings(reviewers: list, keys: keys);
  }

  Future<void> _saveList(List<Reviewer> list) async {
    await Settings.instance.write(_listKey, jsonEncode([for (final r in list) r.toJson()]));
  }

  Future<void> setKey(String id, String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _secure.delete(_keyName(id));
    } else {
      await _secure.write(_keyName(id), trimmed);
    }
    final s = await future;
    final keys = {...s.keys}..remove(id);
    if (trimmed.isNotEmpty) keys[id] = trimmed;
    state = AsyncData(ReviewerSettings(reviewers: s.reviewers, keys: keys));
  }

  Future<void> edit(String id, {String? label, String? baseUrl, String? model}) async {
    final s = await future;
    final list = [
      for (final r in s.reviewers) r.id == id ? r.copyWith(label: label, baseUrl: baseUrl, model: model) : r,
    ];
    await _saveList(list);
    state = AsyncData(ReviewerSettings(reviewers: list, keys: s.keys));
  }
}

final reviewerSettingsProvider =
    AsyncNotifierProvider<ReviewerSettingsController, ReviewerSettings>(ReviewerSettingsController.new);

/// Builds the adapter that talks to one reviewer.
AiProvider providerFor(Reviewer r, String key) =>
    createProvider(AiProviderId.openaiCompatible, AiEndpoint.direct(apiKey: key, baseUrl: r.baseUrl));
