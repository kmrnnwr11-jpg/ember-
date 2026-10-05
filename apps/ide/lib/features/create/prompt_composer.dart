import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../ai/ai_settings.dart';
import '../review/reviewers.dart';
import 'access_links.dart';
import 'app_builder.dart';
import 'engines.dart';

const _kEngine = 'ember_engine';

/// What the user picked in "Options"; null means "whatever is available".
class _Choice extends ChangeNotifier {
  BuildEngine? engine;
  AiModel? model;

  /// Model picked for a subscription engine (Claude Code / Codex / Gemini CLI).
  String? cliModel;

  /// Picked by hand just now, as opposed to remembered from last time.
  bool explicit = false;

  void pickEngine(BuildEngine e) {
    engine = e;
    explicit = true;
    model = null;
    cliModel = null;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString(_kEngine, e.name), onError: (_) {});
  }

  void pickModel(AiModel m) {
    model = m;
    notifyListeners();
  }

  void pickCliModel(String? id) {
    cliModel = id;
    notifyListeners();
  }

  /// The engine used last time, so the choice is made once.
  Future<void> restore() async {
    try {
      final name = (await SharedPreferences.getInstance()).getString(_kEngine);
      final saved = BuildEngine.values.where((e) => e.name == name).firstOrNull;
      if (saved != null && engine == null) {
        engine = saved;
        notifyListeners();
      }
    } catch (_) {
      // keep the default
    }
  }
}

typedef _CliModel = ({String id, String label, String? description});
typedef _Drawer = ({String id, String label, IconData icon, bool available});

/// Everything the composer and its options sheet show, worked out from the
/// user's choice, the configured keys and what the Runner offers.
class _Resolved {
  _Resolved(WidgetRef ref, AppLocalizations l, _Choice choice) {
    final settings = ref.watch(aiSettingsProvider).value ?? const AiSettings();
    final health = ref.watch(runnerHealthProvider).value;
    final claudeCode = (health?['engines'] as Map?)?['claudeCode'] == true;
    final catalog = ref.watch(aiCatalogProvider).value ?? builtInCatalog;
    final panel = ref.watch(reviewerSettingsProvider).value;
    options = engineOptions(l, settings, claudeCode,
        serverGemini: serverGeminiAvailable(health),
        health: health,
        panelKeys: {
          for (final e in (panel?.keys.entries ?? const <MapEntry<String, String>>[]))
            if (e.value.trim().isNotEmpty) e.key,
        });

    // A remembered engine that is no longer usable gives way to one that is.
    final picked = options.where((o) => o.engine == choice.engine).firstOrNull;
    engine = (picked != null && (picked.available || choice.explicit))
        ? picked.engine
        : options.firstWhere((o) => o.available, orElse: () => options.first).engine;
    option = options.firstWhere((o) => o.engine == engine);
    models = engine.provider == null ? <AiModel>[] : catalog.where((m) => m.provider == engine.provider).toList();
    model = engine.provider == null
        ? null
        : (choice.model != null && choice.model!.provider == engine.provider
            ? choice.model
            : models.where((m) => m.id == engine.defaultModel).firstOrNull ?? models.firstOrNull);

    cliModels = [
      for (final m in ((health?['cliModels'] as Map?)?[engine.cli] as List? ?? const []).cast<Map<String, dynamic>>())
        (id: m['id'] as String, label: m['label'] as String, description: m['description'] as String?),
    ];
    cliModel = cliModels.any((m) => m.id == choice.cliModel) ? choice.cliModel : cliModels.firstOrNull?.id;

    // Drawing engines only: a subscription CLI has no one-shot drawing mode.
    final designOptions = options.where((o) => !o.engine.isCli).toList();
    design = designOptions
        .firstWhere((o) => o.engine == BuildEngine.gemini && o.available, orElse: () => designOptions.firstWhere((o) => o.available, orElse: () => designOptions.first))
        .engine;

    // Everyone who can draw, as the panel will call them. The user switches
    // each on or off; mockups come two per model and logos rotate among them.
    drawers = [
      (id: 'gemini_runner', label: 'Gemini', icon: Icons.auto_awesome_outlined, available: serverGeminiAvailable(health) || settings.isConfigured(AiProviderId.gemini)),
      (id: 'claude_code', label: 'Claude', icon: Icons.psychology_outlined, available: claudeCode),
      (id: 'codex', label: 'GPT', icon: Icons.chat_bubble_outline, available: (health?['engines'] as Map?)?['codex'] == true),
      for (final r in panel?.usable ?? const <Reviewer>[]) (id: r.id, label: r.label, icon: Icons.hub_outlined, available: true),
    ];
    availableDrawers = {for (final d in drawers) if (d.available) d.id};
    final chosen = ref.watch(chosenDesignersProvider);
    drawing = chosen == null ? availableDrawers : chosen.intersection(availableDrawers);
  }

  late final List<EngineOption> options;
  late final BuildEngine engine;
  late final EngineOption option;
  late final List<AiModel> models;
  late final AiModel? model;
  late final List<_CliModel> cliModels;
  late final String? cliModel;
  late final BuildEngine design;
  late final List<_Drawer> drawers;
  late final Set<String> availableDrawers;
  late final Set<String> drawing;
}

/// The prompt box and one button. Who builds the app is chosen once, under
/// "Options", and remembered.
class AppPromptComposer extends ConsumerStatefulWidget {
  const AppPromptComposer({super.key, required this.onSubmit, this.initialPrompt = '', this.busy = false, this.buttonLabel, this.onChanged});

  /// Called as the description is typed, so it can be kept as a draft.
  final ValueChanged<String>? onChanged;

  /// `engine` writes the code; `design` draws (mockups, logos, screenshots).
  final void Function(String prompt, BuildEngine engine, AiModel? model, String quality, BuildEngine design) onSubmit;
  final String initialPrompt;
  final bool busy;
  final String? buttonLabel;

  @override
  ConsumerState<AppPromptComposer> createState() => _AppPromptComposerState();
}

class _AppPromptComposerState extends ConsumerState<AppPromptComposer> {
  late final _text = TextEditingController(text: widget.initialPrompt);
  final _choice = _Choice();

  @override
  void initState() {
    super.initState();
    _choice
      ..addListener(_changed)
      ..restore();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _text.dispose();
    _choice
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _openOptions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _OptionsSheet(choice: _choice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = _Resolved(ref, l, _choice);
    final empty = _text.text.trim().isEmpty;

    void submit() {
      if (empty || !r.option.available || widget.busy) return;
      // For subscription engines the chosen CLI model travels in `quality`.
      widget.onSubmit(_text.text.trim(), r.engine, r.model, r.engine.isCli ? (r.cliModel ?? 'fast') : 'fast', r.design);
    }

    final create = FilledButton.icon(
      key: const Key('createAppButton'),
      onPressed: empty || !r.option.available || widget.busy ? null : submit,
      icon: widget.busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward),
      label: Text(widget.buttonLabel ?? l.createApp),
    );
    final options = TextButton.icon(
      key: const Key('engineOptions'),
      onPressed: _openOptions,
      icon: const Icon(Icons.tune, size: 18),
      label: Text(l.madeWith(r.option.label), overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(foregroundColor: context.scheme.onSurfaceVariant),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): submit},
          child: TextField(
            key: const Key('appPrompt'),
            controller: _text,
            minLines: 4,
            maxLines: 12,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(hintText: l.appPromptHint),
            onChanged: (text) {
              widget.onChanged?.call(text);
              setState(() {});
            },
          ),
        ),
        if (!r.option.available) ...[
          Gap.vSm,
          // The button goes under the reason when both do not fit on one line.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Gap.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: context.scheme.error),
                  Gap.hSm,
                  Flexible(child: Text(r.option.reason ?? '', style: TextStyle(color: context.scheme.error))),
                ],
              ),
              if (!r.engine.isCli)
                TextButton(onPressed: () => context.push('/settings'), child: Text(l.aiSettings))
              else
                TextButton(onPressed: () => showConnectSubscription(context, r.engine), child: Text(l.connectSubscription)),
            ],
          ),
        ],
        Gap.vMd,
        // Side by side when there is room, stacked on a phone.
        LayoutBuilder(
          builder: (context, box) => box.maxWidth < 420
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [create, Gap.vXs, Align(alignment: AlignmentDirectional.centerStart, child: options)],
                )
              : Row(children: [Flexible(child: options), const Spacer(), create]),
        ),
      ],
    );
  }
}

/// Who writes the code, who draws, which model: everything that used to sit
/// on the home screen, one tap away.
class _OptionsSheet extends ConsumerWidget {
  const _OptionsSheet({required this.choice});
  final _Choice choice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: choice,
      builder: (context, _) {
        final r = _Resolved(ref, l, choice);
        void toggleDrawer(String id) {
          final next = {...r.drawing};
          if (!next.remove(id)) next.add(id);
          // Never nobody: the last one stays on.
          if (next.isEmpty) return;
          ref.read(chosenDesignersProvider.notifier).set(next.length == r.availableDrawers.length ? null : next);
        }

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85, maxWidth: Widths.page),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg + MediaQuery.viewInsetsOf(context).bottom),
            children: [
              Text(l.buildOptionsTitle, style: context.text.titleLarge),
              Gap.vLg,
              Text(l.chooseAi, style: context.text.labelLarge),
              Gap.vSm,
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final o in r.options)
                    ChoiceChip(
                      key: Key('engine_${o.engine.name}'),
                      avatar: Icon(o.icon, size: 18),
                      label: Text('${o.label} · ${o.badge}'),
                      selected: r.engine == o.engine,
                      onSelected: (_) => choice.pickEngine(o.engine),
                    ),
                ],
              ),
              if (!r.option.available) ...[Gap.vSm, InlineMessage(r.option.reason ?? '', error: true)],
              if (r.engine.isCli && r.cliModels.isNotEmpty) ...[
                Gap.vMd,
                DropdownButtonFormField<String>(
                  key: ValueKey('cliModel_${r.engine.name}'),
                  initialValue: r.cliModel,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.selectModel),
                  items: [
                    for (final m in r.cliModels)
                      DropdownMenuItem(value: m.id, child: Text(m.description == null ? m.label : '${m.label} — ${m.description}', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: choice.pickCliModel,
                ),
              ],
              if (r.models.isNotEmpty) ...[
                Gap.vMd,
                DropdownButtonFormField<String>(
                  key: ValueKey('apiModel_${r.engine.name}'),
                  initialValue: r.model?.key,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.selectModel),
                  items: [for (final m in r.models) DropdownMenuItem(value: m.key, child: Text(m.label, overflow: TextOverflow.ellipsis))],
                  onChanged: (k) => choice.pickModel(r.models.firstWhere((m) => m.key == k)),
                ),
              ],
              Gap.vMd,
              AccessLinks(
                engine: r.engine,
                connected: r.option.available,
                subscriptionReady: (e) => r.options.any((o) => o.engine == e && o.available),
                onUseSubscription: choice.pickEngine,
              ),
              const Divider(height: Gap.xxl),
              Text(l.chooseDesignAi, style: context.text.labelLarge),
              Gap.vXs,
              Text(l.chooseDesignAiHint, style: context.text.bodySmall),
              Gap.vSm,
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final d in r.drawers)
                    FilterChip(
                      key: Key('design_${d.id}'),
                      avatar: Icon(d.icon, size: 16),
                      label: Text(d.label),
                      selected: r.drawing.contains(d.id),
                      onSelected: d.available ? (_) => toggleDrawer(d.id) : null,
                    ),
                ],
              ),
              Gap.vLg,
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(key: const Key('engineOptionsDone'), onPressed: () => Navigator.pop(context), child: Text(l.done)),
              ),
            ],
          ),
        );
      },
    );
  }
}
