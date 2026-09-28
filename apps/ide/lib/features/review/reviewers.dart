import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show MsgType;

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../ai/ai_settings.dart';
import '../mockups/mockup_controller.dart' show PanelMember, claudeCodeCompleter;

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
  // Gemini is deliberately absent: it joins the panel by itself on the
  // Runner's own key (see runnerGeminiMember), so there is nothing here for
  // the user to fetch and paste. A row asking for a key it does not need would
  // only read as a second, broken Gemini.
  //
  // One key, many models: the ones ending in :free cost nothing.
  Reviewer(
    id: 'openrouter',
    label: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    model: 'nvidia/nemotron-3-ultra-550b-a55b:free',
  ),
  // Alibaba's Qwen, whose coder model is the strongest of the open-weight ones
  // on code. Reached through OpenRouter so it takes the key that is already
  // pasted there; point baseUrl at https://dashscope-intl.aliyuncs.com/compatible-mode/v1
  // and paste a DashScope key instead to talk to Alibaba directly.
  Reviewer(
    id: 'qwen',
    label: 'Qwen',
    baseUrl: 'https://openrouter.ai/api/v1',
    model: 'qwen/qwen3-coder-next',
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

/// Models the services no longer offer (e.g. free variants withdrawn).
const _withdrawnModels = {'qwen/qwen3-coder:free', 'deepseek/deepseek-chat-v3.1:free'};

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
    final list = [
      for (final p in reviewerPresets)
        // A model OpenRouter has withdrawn answers 404 and stops every build:
        // a saved entry still naming one falls back on the preset's model.
        if (saved[p.id] != null && _withdrawnModels.contains(saved[p.id]!.model)) saved[p.id]!.copyWith(model: p.model) else saved[p.id] ?? p,
    ];
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

/// Reads one answer out of a provider's stream, as plain text.
Future<String> _readAll(AiProvider provider, String model, String system, String prompt, int maxTokens) async {
  final buf = StringBuffer();
  await for (final e in provider.chat(
    model: model,
    system: system.isEmpty ? null : system,
    maxTokens: maxTokens,
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
  return buf.toString();
}

/// Asks every model at the table for one word before any real work starts. A
/// model that is down, out of quota or misconfigured answers nothing for
/// minutes and then silently drops out of the set; asked this way it costs a
/// couple of seconds and the user learns its name while there is still a
/// choice to make.
Future<List<PanelPing>> pingMembers(List<PanelMember> members) async {
  Future<PanelPing> ping(PanelMember m) async {
    try {
      final answer = await m.complete('', 'Reply with OK');
      // A model that answers with nothing at all is down, whatever it says.
      return answer.text.trim().isEmpty
          ? (id: m.id, label: m.label, ok: false, error: 'nessuna risposta')
          : (id: m.id, label: m.label, ok: true, error: '');
    } on AiException catch (e) {
      return (id: m.id, label: m.label, ok: false, error: e.message);
    } catch (e) {
      return (id: m.id, label: m.label, ok: false, error: '$e');
    }
  }

  return Future.wait([
    for (final m in members)
      ping(m).timeout(
        const Duration(seconds: 25),
        onTimeout: () => (id: m.id, label: m.label, ok: false, error: 'non risponde (25s)'),
      ),
  ]);
}

/// Claude drawing and reviewing through the machine's own Claude login.
///
/// It is the engine that writes the apps, so it is at the table on the
/// subscription that is already paid for, with no key and no extra cost. Its
/// verdict on its own drawing is discarded like everyone else's, so being both
/// author and critic changes nothing.
///
/// Returns null when this machine has no Claude login; the panel then simply
/// has one member fewer.
Future<PanelMember?> runnerClaudeMember(WidgetRef ref) async {
  try {
    final health = await ref.read(runnerHealthProvider.future);
    if ((health['engines'] as Map?)?['claudeCode'] != true) return null;
    final socket = ref.read(runnerSocketProvider);
    final complete = claudeCodeCompleter((t, p) => socket.request(t, p, timeout: const Duration(minutes: 6)));
    return (id: 'claude_code', label: 'Claude', complete: complete);
  } catch (_) {
    return null;
  }
}

/// GPT drawing and reviewing through the machine's ChatGPT login (Codex).
///
/// A ChatGPT subscription used to buy only code: Codex built apps and sat out
/// the mockups, the logos and the review. The Runner now answers one-shot
/// prompts through it too, so it takes a seat like Claude does — no key, no
/// extra cost. Null when this machine is not logged in to Codex.
Future<PanelMember?> runnerCodexMember(WidgetRef ref) async {
  try {
    final health = await ref.read(runnerHealthProvider.future);
    if ((health['engines'] as Map?)?['codex'] != true) return null;
    final socket = ref.read(runnerSocketProvider);
    return (
      id: 'codex',
      label: 'GPT',
      complete: (String system, String prompt) async {
        final res = await socket.request(
          MsgType.agentComplete,
          {'engine': 'codex', 'system': system, 'prompt': prompt},
          timeout: const Duration(minutes: 6),
        );
        return (text: res['text'] as String, costUsd: null);
      },
    );
  } catch (_) {
    return null;
  }
}

/// Which models draw the mockups and logos, as the user picked them.
///
/// Null means "everyone who is available" — the default, so a new install
/// draws with the whole table without anyone having to tick boxes. Kept for
/// the whole session: the choice is made on the home screen and read by the
/// mockup gallery and the logo card later.
class ChosenDesigners extends Notifier<Set<String>?> {
  @override
  Set<String>? build() {
    ref.keepAlive();
    return null;
  }

  void set(Set<String>? ids) => state = ids;
}

final chosenDesignersProvider = NotifierProvider<ChosenDesigners, Set<String>?>(ChosenDesigners.new);

/// Gemini drawing and reviewing on the Runner's own key.
///
/// Every other model at the table needs a key the user went and fetched.
/// Gemini does not: the Runner already holds one for building apps, and
/// [aiProviderFactory] hands out a proxied provider that uses it. So Gemini
/// joins the panel with nothing for the user to do — at the cost of sharing
/// that free quota with app building.
///
/// Returns null when the Runner has no Gemini to offer; the panel then simply
/// has one member fewer.
Future<PanelMember?> runnerGeminiMember(WidgetRef ref) async {
  try {
    final catalog = await ref.read(aiCatalogProvider.future);
    final gemini = catalog.where((m) => m.provider == AiProviderId.gemini);
    final model = gemini.where((m) => m.tags.contains('fast')).firstOrNull ?? gemini.firstOrNull;
    if (model == null) return null;
    final provider = await ref.read(aiProviderFactory)(model);
    return (
      id: 'gemini_runner',
      label: 'Gemini',
      complete: (String system, String prompt) async =>
          (text: await _readAll(provider, model.id, system, prompt, 32000), costUsd: null),
    );
  } catch (_) {
    // No key on the Runner, or it is unreachable: not an error, just one
    // designer fewer at the table.
    return null;
  }
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
          // These are free or near-free tiers, so no cost is attributed.
          complete: (String system, String prompt) async =>
              (text: await _readAll(providerFor(r, s.keys[r.id]!), r.model, system, prompt, 32000), costUsd: null),
        ),
    ];
