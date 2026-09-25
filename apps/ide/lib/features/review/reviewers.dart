import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../mockups/mockup_controller.dart' show PanelMember;

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

/// One model that answered, or the reason it did not.
typedef PanelPing = ({String id, String label, bool ok, String error});

/// Asks every configured model for one word before any real work starts. A
/// model that is down, out of quota or misconfigured answers nothing for
/// minutes and then silently drops out of the set; asked this way it costs a
/// couple of seconds and the user learns its name while there is still a
/// choice to make.
Future<List<PanelPing>> pingPanel(ReviewerSettings s) async {
  Future<PanelPing> ping(Reviewer r) async {
    try {
      final provider = providerFor(r, s.keys[r.id]!);
      final buf = StringBuffer();
      await for (final e in provider.chat(
        model: r.model,
        maxTokens: 16,
        messages: const [AiMessage.user('Reply with OK')],
      )) {
        switch (e) {
          case AiTextDelta(:final text):
            buf.write(text);
          case AiError(:final message, :final statusCode):
            throw AiException(message, statusCode: statusCode);
          default:
        }
      }
      // A model that answers with nothing at all is down, whatever it says.
      return buf.toString().trim().isEmpty
          ? (id: r.id, label: r.label, ok: false, error: 'nessuna risposta')
          : (id: r.id, label: r.label, ok: true, error: '');
    } on AiException catch (e) {
      return (id: r.id, label: r.label, ok: false, error: e.message);
    } catch (e) {
      return (id: r.id, label: r.label, ok: false, error: '$e');
    }
  }

  return Future.wait([
    for (final r in s.usable)
      ping(r).timeout(
        const Duration(seconds: 25),
        onTimeout: () => (id: r.id, label: r.label, ok: false, error: 'non risponde (25s)'),
      ),
  ]);
}

/// The same models, used the other way round: not judging a finished app but
/// drawing part of the design themselves and then reviewing each other.
/// [only] keeps just the models that answered the ping, so a model known to be
/// down is never handed a share of the drawing.
List<PanelMember> designPanel(ReviewerSettings s, {Set<String>? only}) => [
      for (final r in s.usable.where((r) => only == null || only.contains(r.id)))
        (
          id: r.id,
          label: r.label,
          complete: (String system, String prompt) async {
            final provider = providerFor(r, s.keys[r.id]!);
            final buf = StringBuffer();
            await for (final e in provider.chat(
              model: r.model,
              system: system,
              maxTokens: 32000,
              messages: [AiMessage.user(prompt)],
            )) {
              switch (e) {
                case AiTextDelta(:final text):
                  buf.write(text);
                case AiError(:final message, :final statusCode):
                  throw AiException(message, statusCode: statusCode);
                default:
              }
            }
            // These are free or near-free tiers, so no cost is attributed.
            return (text: buf.toString(), costUsd: null);
          },
        ),
    ];
