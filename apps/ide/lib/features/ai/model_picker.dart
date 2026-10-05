import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'ai_settings.dart';

String formatPer1k(double? usd) {
  if (usd == null) return '—';
  if (usd == 0) return '\$0';
  return usd < 0.01 ? '\$${usd.toStringAsFixed(4)}' : '\$${usd.toStringAsFixed(3)}';
}

/// Compact model selector with provider, BYOK badge, key status and cost (§3).
class ModelPicker extends StatelessWidget {
  const ModelPicker({
    super.key,
    required this.models,
    required this.settings,
    required this.selected,
    required this.onSelected,
    required this.onOpenSettings,
  });

  final List<AiModel> models;
  final AiSettings settings;
  final AiModel? selected;
  final ValueChanged<AiModel> onSelected;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sel = selected;
    return PopupMenuButton<Object>(
      key: const Key('modelPicker'),
      tooltip: l.selectModel,
      onSelected: (v) => v is AiModel ? onSelected(v) : onOpenSettings(),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<Object>>[];
        for (final provider in AiProviderId.values) {
          final group = models.where((m) => m.provider == provider).toList();
          if (group.isEmpty) continue;
          final ok = settings.isConfigured(provider);
          items.add(PopupMenuItem<Object>(
            enabled: false,
            height: Gap.xxl,
            child: Row(
              children: [
                Text(provider.product, style: context.text.labelMedium),
                Gap.hSm,
                const Pill('BYOK'),
                Gap.hSm,
                Icon(ok ? Icons.check_circle_outline : Icons.key_off_outlined, size: 14, color: ok ? context.ember.success : context.ember.warning),
                Gap.hXs,
                Flexible(child: Text(ok ? l.keyPresent : l.notConfigured, style: context.text.labelSmall, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ));
          for (final m in group) {
            items.add(PopupMenuItem<Object>(
              value: m,
              enabled: ok,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: sel?.key == m.key ? const Icon(Icons.check, size: 16) : null,
                  ),
                  Expanded(child: Text(m.label, overflow: TextOverflow.ellipsis)),
                  Gap.hMd,
                  Text(
                    '${formatPer1k(m.inputPer1k)} / ${formatPer1k(m.outputPer1k)} ${l.per1k}',
                    style: context.text.labelSmall,
                  ),
                ],
              ),
            ));
          }
        }
        items
          ..add(const PopupMenuDivider())
          ..add(PopupMenuItem<Object>(value: 'settings', child: ListTile(dense: true, leading: const Icon(Icons.key_outlined), title: Text(l.aiSettings))));
        return items;
      },
      child: Padding(
        padding: const EdgeInsets.all(Gap.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 16),
            Gap.hSm,
            Flexible(child: Text(sel?.label ?? l.selectModel, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
