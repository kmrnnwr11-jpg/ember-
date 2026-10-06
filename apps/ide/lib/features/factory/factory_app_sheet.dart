import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ide_core/ide_core.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'factory_controller.dart';
import 'factory_models.dart';
import 'factory_widgets.dart';

/// Opens one app's detail over the dashboard. It follows the app live: the
/// stages tick off while the sheet is open.
Future<void> showFactoryAppSheet(BuildContext context, String appId) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: Widths.page),
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.8,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    builder: (_, scroll) => FactoryAppSheet(appId: appId, scroll: scroll),
  ),
);

class FactoryAppSheet extends ConsumerWidget {
  const FactoryAppSheet({super.key, required this.appId, required this.scroll});
  final String appId;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final app = ref.watch(factoryProvider).value?.app(appId);
    if (app == null) return EmptyState(icon: Icons.search_off, text: l.fxAppGone);
    final ctl = ref.read(factoryProvider.notifier);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } on RunnerException catch (e) {
        if (context.mounted) showEmberSnack(context, l.error(e.message), error: true);
      }
    }

    final failedStage = app.failedStage;
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xxl),
      children: [
        Row(
          children: [
            Expanded(child: Text(app.name, style: context.text.titleLarge)),
            Pill(appStatusLabel(l, app.status), tone: appStatusTone(app.status)),
          ],
        ),
        Gap.vXs,
        Text(
          [engineLabel(app.engine), if (app.packageName != null) app.packageName!].join(' · '),
          style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant),
        ),
        if (app.summary.isNotEmpty) ...[Gap.vMd, Text(app.summary)],
        if (app.status == AppStatus.failed && app.error != null && app.error!.isNotEmpty) ...[
          Gap.vMd,
          Text(appHeadline(l, app), style: context.text.titleSmall),
          Gap.vXs,
          InlineMessage(app.error!, error: true),
        ],
        for (final n in app.needs)
          NeedsYouTile(
            need: n,
            showApp: false,
            onDone: () => run(() => ctl.appAction(app.id, 'resolve', body: {'needId': n.id})),
            onSkip: () => run(() => ctl.appAction(app.id, 'resolve', body: {'needId': n.id, 'skip': true})),
          ),
        Gap.vLg,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            if (app.projectId != null)
              FilledButton.icon(
                key: const Key('factoryOpenApp'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/projects/${app.projectId}/create');
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(l.openApp),
              ),
            if (app.status == AppStatus.failed || app.status == AppStatus.cancelled)
              OutlinedButton.icon(
                onPressed: () =>
                    run(() => ctl.appAction(app.id, 'retry', body: failedStage == null ? null : {'from': failedStage})),
                icon: const Icon(Icons.refresh),
                label: Text(failedStage == null ? l.retry : l.fxRetryFrom(stageLabel(l, failedStage))),
              ),
            if (app.status == AppStatus.running || app.status == AppStatus.queued)
              OutlinedButton.icon(
                onPressed: () => run(() => ctl.appAction(app.id, 'cancel')),
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l.cancel),
              ),
            TextButton.icon(
              onPressed: () async {
                final yes = await showConfirm(
                  context,
                  title: l.fxRemoveTitle(1),
                  message: l.fxRemoveBody,
                  destructive: true,
                  confirmLabel: l.delete,
                );
                if (!yes) return;
                await run(() => ctl.remove(app.id));
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(l.delete),
            ),
          ],
        ),
        Gap.vLg,
        Text(l.fxSteps, style: context.text.titleSmall),
        Gap.vSm,
        for (final id in factoryStages) _StageRow(app: app, stage: id),
        if (app.log.isNotEmpty) ...[
          Gap.vLg,
          Text(l.fxLog, style: context.text.titleSmall),
          Gap.vSm,
          LogSurface(child: SelectableText(app.log.join('\n'))),
        ],
        if (app.costUsd > 0) ...[
          Gap.vMd,
          Text(l.fxCost(app.costUsd.toStringAsFixed(2)), style: context.text.bodySmall),
        ],
      ],
    );
  }
}

/// The day and time in the user's language.
String _when(BuildContext context, DateTime t) {
  final local = t.toLocal();
  final loc = MaterialLocalizations.of(context);
  return '${loc.formatShortDate(local)} ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.app, required this.stage});
  final FactoryApp app;
  final String stage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final run = app.stage(stage);
    final (IconData icon, Color color) = switch (run.status) {
      StageStatus.done => (Icons.check_circle, context.ember.success),
      StageStatus.running => (Icons.autorenew, context.scheme.primary),
      StageStatus.queued => (Icons.schedule, context.scheme.primary),
      StageStatus.blocked => (Icons.front_hand, context.ember.warning),
      StageStatus.failed => (Icons.error, context.scheme.error),
      StageStatus.skipped => (Icons.remove_circle_outline, context.scheme.outlineVariant),
      StageStatus.pending => (Icons.radio_button_unchecked, context.scheme.outline),
    };
    final muted = run.status == StageStatus.skipped || run.status == StageStatus.pending;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color, semanticLabel: stageStatusLabel(l, run.status)),
          Gap.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stageLabel(l, stage), style: muted ? TextStyle(color: context.scheme.onSurfaceVariant) : null),
                if (run.status == StageStatus.failed && run.message.isNotEmpty)
                  Text(run.message, style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant)),
                if (run.until != null && run.status != StageStatus.done)
                  Text(
                    l.fxWaitsUntil(_when(context, run.until!)),
                    style: context.text.bodySmall?.copyWith(color: context.ember.warning),
                  ),
              ],
            ),
          ),
          if (run.attempts > 1) Text('×${run.attempts}', style: context.text.labelSmall),
        ],
      ),
    );
  }
}
