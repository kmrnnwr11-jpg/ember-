import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ide_core/ide_core.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'connect_cards.dart';
import 'factory_app_sheet.dart';
import 'factory_controller.dart';
import 'factory_models.dart';
import 'factory_widgets.dart';

enum _Filter { all, running, queued, needsYou, failed, done }

bool _matches(_Filter f, FactoryApp a) => switch (f) {
  _Filter.all => true,
  _Filter.running => a.status == AppStatus.running,
  _Filter.queued => a.status == AppStatus.queued,
  _Filter.needsYou => a.status == AppStatus.needsYou,
  _Filter.failed => a.status == AppStatus.failed,
  _Filter.done => a.status == AppStatus.done,
};

/// The Fabbrica at a glance: how many apps, how far along, what is stuck and
/// what needs the owner, then every app with its eleven-dot path.
class FactoryScreen extends ConsumerStatefulWidget {
  const FactoryScreen({super.key});

  @override
  ConsumerState<FactoryScreen> createState() => _FactoryScreenState();
}

class _FactoryScreenState extends ConsumerState<FactoryScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';
  final _selected = <String>{};

  Future<void> _run(Future<void> Function() action) async {
    final l = AppLocalizations.of(context);
    try {
      await action();
    } on RunnerException catch (e) {
      if (mounted) showEmberSnack(context, l.error(e.message), error: true);
    }
  }

  Future<void> _bulk(String action) async {
    final l = AppLocalizations.of(context);
    final ids = [..._selected];
    if (action == 'remove') {
      final yes = await showConfirm(
        context,
        title: l.fxRemoveTitle(ids.length),
        message: l.fxRemoveBody,
        destructive: true,
        confirmLabel: l.delete,
      );
      if (!yes) return;
    }
    await _run(() => ref.read(factoryProvider.notifier).bulk(ids, action == 'remove' ? 'delete' : action));
    if (mounted) setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(factoryProvider);
    final ctl = ref.read(factoryProvider.notifier);
    return state.when(
      loading: () => LoadingState(text: l.fxLoading),
      error: (e, _) => ErrorState(
        message: l.error(e is RunnerException ? e.message : '$e'),
        onRetry: () => ref.invalidate(factoryProvider),
      ),
      data: (data) {
        final apps = [
          for (final a in data.apps)
            if (_matches(_filter, a) && (_query.isEmpty || a.name.toLowerCase().contains(_query.toLowerCase()))) a,
        ];
        final s = data.summary;
        // The selection bar stays at the top while the list scrolls under it.
        return Column(
          children: [
            if (_selected.isNotEmpty)
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
                    child: _SelectionBar(
                      count: _selected.length,
                      onAction: _bulk,
                      onClear: () => setState(_selected.clear),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: PageBody(
                maxWidth: 1100,
                children: [
                  if (data.paused)
                    _PausedBanner(interrupted: data.interrupted, onResume: () => _run(() => ctl.setPaused(false))),
                  if (data.lowDisk)
                    SectionCard(
                      key: const Key('factoryLowDisk'),
                      icon: Icons.storage_outlined,
                      tone: Tone.error,
                      margin: const EdgeInsets.only(bottom: Gap.md),
                      title: l.fxLowDiskTitle,
                      hint: l.fxLowDiskHint,
                    ),
                  if (data.simulated)
                    SectionCard(
                      key: const Key('factorySimulated'),
                      icon: Icons.science_outlined,
                      margin: const EdgeInsets.only(bottom: Gap.md),
                      title: l.fxSimulatedTitle,
                      hint: l.fxSimulatedHint,
                    ),
                  const StoreAccountsBanner(),
                  _Summary(data: data, onFilter: (f) => setState(() => _filter = f)),
                  Gap.vMd,
                  _ProgressCard(data: data),
                  Gap.vLg,
                  if (data.apps.isEmpty)
                    EmptyState(
                      key: const Key('factoryEmpty'),
                      icon: Icons.factory_outlined,
                      text: l.fxEmpty,
                      action: FilledButton.icon(
                        onPressed: () => context.go('/factory/new'),
                        icon: const Icon(Icons.add),
                        label: Text(l.fxNavNew),
                      ),
                    )
                  else ...[
                    _Toolbar(
                      filter: _filter,
                      data: data,
                      onFilter: (f) => setState(() => _filter = f),
                      onQuery: (q) => setState(() => _query = q),
                      onRetryFailed: s.failed == 0 ? null : () => _run(() => ctl.retryFailed()),
                      onCancelBatch: (id) => _run(() => ctl.cancelBatch(id)),
                    ),
                    Gap.vMd,
                    if (apps.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(Gap.xl),
                        child: Center(child: Text(l.fxNoMatch)),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, box) {
                          final columns = (box.maxWidth / 340).floor().clamp(1, 4);
                          final width = (box.maxWidth - (columns - 1) * Gap.md) / columns;
                          return Wrap(
                            spacing: Gap.md,
                            runSpacing: Gap.md,
                            children: [
                              for (final a in apps)
                                SizedBox(
                                  width: width,
                                  child: FactoryAppTile(
                                    key: Key('factoryApp_${a.id}'),
                                    app: a,
                                    selected: _selected.contains(a.id),
                                    onTap: () => _selected.isNotEmpty
                                        ? setState(
                                            () =>
                                                _selected.contains(a.id) ? _selected.remove(a.id) : _selected.add(a.id),
                                          )
                                        : showFactoryAppSheet(context, a.id),
                                    onLongPress: () => setState(() => _selected.add(a.id)),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner({required this.interrupted, required this.onResume});
  final bool interrupted;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      key: const Key('factoryPaused'),
      icon: Icons.pause_circle_outline,
      tone: Tone.attention,
      margin: const EdgeInsets.only(bottom: Gap.md),
      title: l.fxPausedTitle,
      hint: interrupted ? l.fxPausedRestart : l.fxPausedHint,
      children: [
        Gap.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(onPressed: onResume, icon: const Icon(Icons.play_arrow), label: Text(l.fxResume)),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.data, required this.onFilter});
  final FactoryData data;
  final ValueChanged<_Filter> onFilter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = data.summary;
    return Wrap(
      spacing: Gap.md,
      runSpacing: Gap.md,
      children: [
        for (final (value, label, tone, filter) in [
          (s.total, l.fxStatTotal, Tone.neutral, _Filter.all),
          (s.running, l.fxStatusRunning, Tone.neutral, _Filter.running),
          (s.queued, l.fxStatusQueued, Tone.neutral, _Filter.queued),
          (s.needsYou, l.fxStatusNeedsYou, s.needsYou > 0 ? Tone.attention : Tone.neutral, _Filter.needsYou),
          (s.failed, l.fxStatusFailed, s.failed > 0 ? Tone.error : Tone.neutral, _Filter.failed),
          (s.done, l.fxStatusDone, Tone.success, _Filter.done),
        ])
          SizedBox(
            width: 132,
            child: StatTile(value: '$value', label: label, tone: tone, onTap: () => onFilter(filter)),
          ),
        SizedBox(
          width: 132,
          child: StatTile(value: '${s.onPlay}', label: l.fxOnPlay),
        ),
        SizedBox(
          width: 132,
          child: StatTile(value: '${s.onAppStore}', label: l.fxOnAppStore),
        ),
      ],
    );
  }
}

String _eta(AppLocalizations l, int seconds) {
  final minutes = (seconds / 60).ceil();
  if (minutes < 90) return l.fxMinutes(minutes);
  final hours = (minutes / 60).round();
  if (hours < 48) return l.fxHours(hours);
  return l.fxDays((hours / 24).round());
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.data});
  final FactoryData data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = data.summary;
    final percent = (s.progress * 100).floor();
    final eta = s.etaSeconds;
    final up = data.uploads;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              eta == null || s.progress >= 1 ? l.fxProgress(percent) : l.fxProgressEta(percent, _eta(l, eta)),
              style: context.text.titleSmall,
            ),
            Gap.vSm,
            ClipRRect(
              borderRadius: Radii.pillAll,
              child: LinearProgressIndicator(minHeight: 8, value: s.progress),
            ),
            Gap.vMd,
            Row(
              children: [
                Icon(Icons.event_repeat_outlined, size: 18, color: context.scheme.onSurfaceVariant),
                Gap.hSm,
                Expanded(
                  child: Text(
                    l.fxDailyLine(up.play, up.capPlay, up.appstore, up.capAppstore),
                    style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.filter,
    required this.data,
    required this.onFilter,
    required this.onQuery,
    required this.onRetryFailed,
    required this.onCancelBatch,
  });
  final _Filter filter;
  final FactoryData data;
  final ValueChanged<_Filter> onFilter;
  final ValueChanged<String> onQuery;
  final VoidCallback? onRetryFailed;
  final ValueChanged<String> onCancelBatch;

  String _label(AppLocalizations l, _Filter f) => switch (f) {
    _Filter.all => l.fxFilterAll,
    _Filter.running => l.fxStatusRunning,
    _Filter.queued => l.fxStatusQueued,
    _Filter.needsYou => l.fxStatusNeedsYou,
    _Filter.failed => l.fxStatusFailed,
    _Filter.done => l.fxStatusDone,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('factorySearch'),
                onChanged: onQuery,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.fxSearch, isDense: true),
              ),
            ),
            PopupMenuButton<String>(
              key: const Key('factoryMenu'),
              tooltip: l.homeMenu,
              onSelected: (v) => v == 'retry' ? onRetryFailed?.call() : onCancelBatch(v),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'retry', enabled: onRetryFailed != null, child: Text(l.fxRetryFailed)),
                for (final b in data.batches) PopupMenuItem(value: b.id, child: Text(l.fxCancelBatch(b.name))),
              ],
            ),
          ],
        ),
        Gap.vSm,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in _Filter.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                  child: ChoiceChip(label: Text(_label(l, f)), selected: filter == f, onSelected: (_) => onFilter(f)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.count, required this.onAction, required this.onClear});
  final int count;
  final ValueChanged<String> onAction;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: Gap.md),
      color: context.scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.xs),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Gap.sm,
          children: [
            Text(l.fxSelected(count), style: context.text.titleSmall),
            TextButton.icon(onPressed: () => onAction('retry'), icon: const Icon(Icons.refresh), label: Text(l.retry)),
            TextButton.icon(
              onPressed: () => onAction('cancel'),
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l.cancel),
            ),
            TextButton.icon(
              onPressed: () => onAction('remove'),
              icon: const Icon(Icons.delete_outline),
              label: Text(l.delete),
            ),
            IconButton(tooltip: l.close, icon: const Icon(Icons.close), onPressed: onClear),
          ],
        ),
      ),
    );
  }
}
