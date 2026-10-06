import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'factory_models.dart';
import 'factory_widgets.dart';

/// Step three: the apps the supervisor made out of the big box. The owner
/// removes the ones not wanted, renames, marks big or small, then starts.
class FactoryReviewStep extends StatelessWidget {
  const FactoryReviewStep({
    super.key,
    required this.planning,
    required this.error,
    required this.plan,
    required this.proposals,
    required this.name,
    required this.goal,
    required this.dailyLimit,
    required this.onRetry,
    required this.onChanged,
    required this.onNameChanged,
  });

  final bool planning;
  final String? error;
  final PlanResult? plan;
  final List<AppProposal> proposals;
  final TextEditingController name;
  final Goal goal;
  final int dailyLimit;
  final VoidCallback onRetry;
  final ValueChanged<List<AppProposal>> onChanged;
  final VoidCallback onNameChanged;

  void _replace(int i, AppProposal p) => onChanged([...proposals]..[i] = p);

  Future<void> _rename(BuildContext context, int i) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: proposals[i].name);
    final value = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.rename),
        content: TextField(controller: controller, autofocus: true, onSubmitted: (v) => Navigator.pop(c, v)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, controller.text), child: Text(l.ok)),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.trim().isNotEmpty) _replace(i, proposals[i].copyWith(name: value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (planning) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.xxl),
        child: LoadingState(text: l.fxSupervisorReading),
      );
    }
    if (error != null) return ErrorState(message: l.error(error!), onRetry: onRetry);
    final p = plan;
    if (p == null) return const SizedBox.shrink();
    if (proposals.isEmpty) {
      return EmptyState(
        icon: Icons.lightbulb_outline,
        text: l.fxNoIdeas,
        action: OutlinedButton(onPressed: onRetry, child: Text(l.retry)),
      );
    }

    final chosen = proposals.where((a) => a.include).length;
    final stores = goal == Goal.android || goal == Goal.ios;
    final days = (chosen / (dailyLimit < 1 ? 1 : dailyLimit)).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.fxReviewTitle(proposals.length), style: context.text.headlineSmall),
        Gap.vSm,
        Text(l.fxReviewHint, style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
        Gap.vMd,
        TextField(
          key: const Key('factoryBatchName'),
          controller: name,
          onChanged: (_) => onNameChanged(),
          decoration: InputDecoration(labelText: l.fxBatchName),
        ),
        for (final w in p.warnings)
          SectionCard(icon: Icons.warning_amber_outlined, tone: Tone.attention, title: w == 'no_ai' ? l.fxWarnNoAi : w),
        if (p.dropped.isNotEmpty)
          SectionCard(
            icon: Icons.filter_alt_outlined,
            title: l.fxDroppedTitle(p.dropped.length),
            children: [
              Gap.vSm,
              for (final d in p.dropped)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(_droppedText(l, d), style: context.text.bodySmall),
                ),
            ],
          ),
        Gap.vMd,
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, a) in proposals.indexed) ...[
                if (i > 0) const Divider(height: 1),
                _ProposalRow(
                  key: Key('factoryProposal_$i'),
                  app: a,
                  onToggle: (v) => _replace(i, a.copyWith(include: v)),
                  onRename: () => _rename(context, i),
                  onSize: () => _replace(i, a.copyWith(size: a.size == 'big' ? 'small' : 'big')),
                ),
              ],
            ],
          ),
        ),
        Gap.vMd,
        if (stores) Text(l.fxEstimateStores(dailyLimit, days), style: context.text.bodyMedium),
      ],
    );
  }
}

String _droppedText(AppLocalizations l, DroppedIdea d) => switch (d.reason) {
  'duplicate_name' => l.fxDropDuplicate(d.name),
  'similar_idea' => l.fxDropSimilar(d.name, d.keptInstead),
  'too_many' => l.fxDropTooMany(d.name),
  _ => d.name,
};

class _ProposalRow extends StatelessWidget {
  const _ProposalRow({
    super.key,
    required this.app,
    required this.onToggle,
    required this.onRename,
    required this.onSize,
  });
  final AppProposal app;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRename;
  final VoidCallback onSize;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dim = app.include ? null : context.scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: app.include, onChanged: (v) => onToggle(v ?? false)),
          Expanded(
            child: InkWell(
              onTap: onRename,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: context.text.titleSmall?.copyWith(color: dim)),
                    if (app.summary.isNotEmpty)
                      Text(
                        app.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant),
                      ),
                    if (app.engine != null)
                      Text(
                        engineLabel(app.engine!),
                        style: context.text.labelSmall?.copyWith(color: context.scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Gap.hSm,
          Padding(
            padding: const EdgeInsets.only(top: Gap.sm),
            child: ActionChip(
              tooltip: l.fxSizeTooltip,
              label: Text(app.size == 'big' ? l.fxSizeBig : l.fxSizeSmall),
              onPressed: onSize,
            ),
          ),
        ],
      ),
    );
  }
}
