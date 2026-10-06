import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'factory_models.dart';

/// Brand names: the same in every language.
const engineLabels = {
  'claude-code': 'Claude Code',
  'qwen-code': 'Qwen Code',
  'gemini-cli': 'Gemini CLI',
  'codex': 'ChatGPT (Codex)',
};

String engineLabel(String engine) => engineLabels[engine] ?? engine;

String stageLabel(AppLocalizations l, String stage) => switch (stage) {
  'create' => l.fxStageCreate,
  'code' => l.fxStageCode,
  'verify' => l.fxStageVerify,
  'preview' => l.fxStagePreview,
  'logo' => l.fxStageLogo,
  'shots' => l.fxStageShots,
  'listing' => l.fxStageListing,
  'android' => l.fxStageAndroid,
  'play' => l.fxStagePlay,
  'ios' => l.fxStageIos,
  'appstore' => l.fxStageAppStore,
  _ => stage,
};

String stageStatusLabel(AppLocalizations l, StageStatus s) => switch (s) {
  StageStatus.pending => l.fxStagePending,
  StageStatus.queued => l.fxStatusQueued,
  StageStatus.running => l.fxStatusRunning,
  StageStatus.done => l.fxStatusDone,
  StageStatus.skipped => l.fxStageSkipped,
  StageStatus.blocked => l.fxStatusNeedsYou,
  StageStatus.failed => l.fxStatusFailed,
};

String appStatusLabel(AppLocalizations l, AppStatus s) => switch (s) {
  AppStatus.queued => l.fxStatusQueued,
  AppStatus.running => l.fxStatusRunning,
  AppStatus.needsYou => l.fxStatusNeedsYou,
  AppStatus.done => l.fxStatusDone,
  AppStatus.failed => l.fxStatusFailed,
  AppStatus.cancelled => l.fxStatusCancelled,
};

Tone appStatusTone(AppStatus s) => switch (s) {
  AppStatus.done => Tone.success,
  AppStatus.failed => Tone.error,
  AppStatus.needsYou => Tone.attention,
  _ => Tone.neutral,
};

/// One line that says where the app is, in our words (the Runner's English is only the fallback).
String appHeadline(AppLocalizations l, FactoryApp app) {
  final stage = app.currentStage;
  final name = stage == null ? '' : stageLabel(l, stage);
  switch (app.status) {
    case AppStatus.done:
      return l.fxHeadDone;
    case AppStatus.cancelled:
      return l.fxStatusCancelled;
    case AppStatus.needsYou:
      return app.needs.isNotEmpty ? needTitle(l, app.needs.first) : l.fxHeadNeedsYou;
    case AppStatus.failed:
      return l.fxHeadFailed(app.failedStage == null ? name : stageLabel(l, app.failedStage!));
    case AppStatus.running:
      return l.fxHeadRunning(name);
    case AppStatus.queued:
      return app.waitingUntil != null ? l.fxHeadWaitingTomorrow(name) : l.fxHeadQueued(name);
  }
}

String needTitle(AppLocalizations l, NeedsYou n) => switch (n.kind) {
  'play_console_app' => l.fxNeedPlayAppTitle,
  'apple_app_record' => l.fxNeedAppleAppTitle,
  'mac' => l.fxNeedMacTitle,
  'play_key' => l.fxNeedPlayKeyTitle,
  'apple_key' => l.fxNeedAppleKeyTitle,
  'login' => l.fxNeedLoginTitle(engineLabel(n.data['engine'] ?? '')),
  _ => n.title,
};

String needDetail(AppLocalizations l, NeedsYou n) => switch (n.kind) {
  'play_console_app' => l.fxNeedPlayAppDetail,
  'apple_app_record' => l.fxNeedAppleAppDetail,
  'mac' => l.fxNeedMacDetail,
  'play_key' => l.fxNeedPlayKeyDetail,
  'apple_key' => l.fxNeedAppleKeyDetail,
  'login' => l.fxNeedLoginDetail,
  _ => n.detail,
};

String needDataLabel(AppLocalizations l, String key) => switch (key) {
  'name' => l.fxDataName,
  'package' => l.fxDataPackage,
  'shortDescription' => l.fxDataShort,
  'category' => l.fxDataCategory,
  'bundleId' => l.fxDataBundleId,
  'sku' => l.fxDataSku,
  'engine' => l.fxDataEngine,
  _ => key,
};

Color _stageColor(BuildContext context, StageStatus s) {
  final scheme = context.scheme;
  return switch (s) {
    StageStatus.done => context.ember.success,
    StageStatus.running => scheme.primary,
    StageStatus.queued => scheme.primary.withValues(alpha: 0.6),
    StageStatus.blocked => context.ember.warning,
    StageStatus.failed => scheme.error,
    StageStatus.pending => scheme.outline,
    StageStatus.skipped => scheme.outlineVariant,
  };
}

/// The eleven stages of an app as eleven small dots: filled when done,
/// ringed while working, amber when it waits for the owner, red when it failed.
class StagePath extends StatelessWidget {
  const StagePath(this.app, {super.key});
  final FactoryApp app;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final summary = '${app.doneStages}/${app.plannedStages}';
    return Semantics(
      label: l.fxStagesDone(app.doneStages, app.plannedStages),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final id in factoryStages)
            Tooltip(
              message: '${stageLabel(l, id)} · ${stageStatusLabel(l, app.stage(id).status)}',
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 3),
                child: _Dot(status: app.stage(id).status, color: _stageColor(context, app.stage(id).status)),
              ),
            ),
          Gap.hXs,
          Text(summary, style: context.text.labelSmall?.copyWith(color: context.scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.status, required this.color});
  final StageStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final filled = status == StageStatus.done || status == StageStatus.failed || status == StageStatus.blocked;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : null,
        border: filled ? null : Border.all(color: color, width: status == StageStatus.running ? 2.5 : 1.5),
      ),
    );
  }
}

/// One app in the list: its name, who writes it, where it is and what it says.
class FactoryAppTile extends StatelessWidget {
  const FactoryAppTile({super.key, required this.app, required this.onTap, this.onLongPress, this.selected = false});
  final FactoryApp app;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final headline = appHeadline(l, app);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: Radii.mdAll,
              side: BorderSide(color: context.scheme.primary, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(app.name, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Gap.hSm,
                  Pill(appStatusLabel(l, app.status), tone: appStatusTone(app.status)),
                ],
              ),
              Gap.vXs,
              Text(
                engineLabel(app.engine),
                style: context.text.labelSmall?.copyWith(color: context.scheme.onSurfaceVariant),
              ),
              Gap.vSm,
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: StagePath(app)),
              if (headline.isNotEmpty) ...[
                Gap.vSm,
                Text(
                  headline,
                  style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A big number with its caption.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.tone = Tone.neutral, this.onTap});
  final String value;
  final String label;
  final Tone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      Tone.attention => context.ember.warning,
      Tone.error => context.scheme.error,
      Tone.success => context.ember.success,
      Tone.neutral => context.scheme.onSurface,
    };
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: context.text.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
              Text(label, style: context.text.labelMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Something only the owner can do: what, the values to copy, and the buttons
/// "I did it, go on" and "skip this".
class NeedsYouTile extends StatelessWidget {
  const NeedsYouTile({super.key, required this.need, required this.onDone, required this.onSkip, this.showApp = true});
  final NeedsYou need;
  final VoidCallback onDone;
  final VoidCallback onSkip;
  final bool showApp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      icon: Icons.front_hand_outlined,
      tone: Tone.attention,
      title: needTitle(l, need),
      hint: showApp && need.appName.isNotEmpty ? need.appName : null,
      children: [
        if (needDetail(l, need).isNotEmpty) ...[Gap.vMd, StepsList.parse(needDetail(l, need))],
        for (final e in need.data.entries) ...[Gap.vSm, _CopyRow(label: needDataLabel(l, e.key), value: e.value)],
        Gap.vMd,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            FilledButton.icon(onPressed: onDone, icon: const Icon(Icons.check), label: Text(l.fxNeedsDone)),
            TextButton(onPressed: onSkip, child: Text(l.fxNeedsSkip)),
          ],
        ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.labelSmall),
              SelectableText(value, style: kMono),
            ],
          ),
        ),
        IconButton(
          tooltip: l.copy,
          icon: const Icon(Icons.copy_outlined, size: 18),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) showEmberSnack(context, l.copied);
          },
        ),
      ],
    );
  }
}

/// "-  5  +": a whole number the owner can raise or lower.
class Stepper2 extends StatelessWidget {
  const Stepper2({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 99, this.step = 1});
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l.fxLess,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
        ),
        SizedBox(
          width: 36,
          child: Text('$value', textAlign: TextAlign.center, style: context.text.titleMedium),
        ),
        IconButton(
          tooltip: l.fxMore,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
        ),
      ],
    );
  }
}
