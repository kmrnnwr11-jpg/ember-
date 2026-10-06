import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'factory_models.dart';
import 'factory_widgets.dart';

/// Names the Runner may use for each engine's readiness.
const _linkIds = {
  'claude-code': ['claude', 'claude-code', 'claudeCode'],
  'qwen-code': ['qwen', 'qwen-code', 'qwenCode'],
  'gemini-cli': ['gemini', 'gemini-cli', 'geminiCli'],
  'codex': ['codex', 'chatgpt'],
};

/// Step two: how the batch is made. Who writes the apps and in what
/// proportion, who draws the logos, how far to go, and the daily upload limit.
class FactoryRecipeStep extends StatelessWidget {
  const FactoryRecipeStep({
    super.key,
    required this.recipe,
    required this.connections,
    required this.dailyLimit,
    required this.onRecipe,
    required this.onDailyLimit,
  });
  final BatchRecipe recipe;
  final FactoryConnections? connections;
  final int dailyLimit;
  final ValueChanged<BatchRecipe> onRecipe;
  final ValueChanged<int> onDailyLimit;

  void _setWeight(String engine, int w) {
    final next = {...recipe.engines};
    if (w <= 0) {
      next.remove(engine);
    } else {
      next[engine] = w;
    }
    // At least one engine writes the apps.
    if (next.isEmpty) return;
    onRecipe(recipe.copyWith(engines: next));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = recipe.engines.values.fold<int>(0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.fxRecipeTitle, style: context.text.headlineSmall),
        SectionCard(
          icon: Icons.memory_outlined,
          title: l.fxEnginesTitle,
          hint: l.fxEnginesHint,
          children: [
            Gap.vSm,
            for (final e in factoryEngines)
              Builder(
                builder: (_) {
                  final weight = recipe.engines[e] ?? 0;
                  final ready = connections?.readyOf(_linkIds[e]!);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(engineLabel(e), style: context.text.titleSmall),
                              if (ready == false)
                                Text(
                                  l.fxNotConnected,
                                  style: context.text.bodySmall?.copyWith(color: context.ember.warning),
                                ),
                              if (weight > 0 && total > 0)
                                Text(l.fxSharePercent((weight * 100 / total).round()), style: context.text.bodySmall),
                            ],
                          ),
                        ),
                        Stepper2(value: weight, max: 10, onChanged: (w) => _setWeight(e, w)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        SectionCard(
          icon: Icons.palette_outlined,
          title: l.fxLogoTitle,
          children: [
            Gap.vSm,
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final (id, label) in [
                  ('auto', l.fxLogoAuto),
                  ('codex', 'ChatGPT'),
                  ('claude_code', 'Claude'),
                  ('gemini_runner', 'Gemini'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: recipe.logoBy == id,
                    onSelected: (_) => onRecipe(recipe.copyWith(logoBy: id)),
                  ),
              ],
            ),
          ],
        ),
        SectionCard(
          icon: Icons.flag_outlined,
          title: l.fxGoalTitle,
          children: [
            RadioGroup<Goal>(
              groupValue: recipe.goal,
              onChanged: (g) => g == null ? null : onRecipe(recipe.copyWith(goal: g)),
              child: Column(
                children: [
                  for (final (g, label) in [
                    (Goal.app, l.fxGoalApp),
                    (Goal.assets, l.fxGoalAssets),
                    (Goal.android, l.fxGoalAndroid),
                    (Goal.ios, l.fxGoalIos),
                  ])
                    RadioListTile<Goal>(
                      key: Key('factoryGoal_${g.name}'),
                      value: g,
                      title: Text(label),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],
        ),
        SectionCard(
          icon: Icons.event_repeat_outlined,
          title: l.fxDailyTitle,
          hint: l.fxDailyHint,
          children: [
            Gap.vSm,
            Row(
              children: [
                Expanded(child: Text(l.fxDailyLabel)),
                Stepper2(value: dailyLimit, min: 1, max: 100, step: 1, onChanged: onDailyLimit),
              ],
            ),
          ],
        ),
        SectionCard(
          key: const Key('factorySafe'),
          icon: Icons.verified_user_outlined,
          tone: Tone.success,
          title: l.fxSafeTitle,
          hint: l.fxSafeBody,
        ),
      ],
    );
  }
}
