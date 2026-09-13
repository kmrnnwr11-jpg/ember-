import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
            height: 32,
            child: Row(
              children: [
                Text(provider.product, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(width: 6),
                _Badge(label: 'BYOK', color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Icon(ok ? Icons.check_circle : Icons.key_off, size: 14, color: ok ? Colors.green : Colors.orange),
                const SizedBox(width: 4),
                Text(ok ? l.keyPresent : l.notConfigured, style: Theme.of(context).textTheme.labelSmall),
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
                  const SizedBox(width: 12),
                  Text(
                    '${formatPer1k(m.inputPer1k)} / ${formatPer1k(m.outputPer1k)} ${l.per1k}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ));
          }
        }
        items
          ..add(const PopupMenuDivider())
          ..add(PopupMenuItem<Object>(value: 'settings', child: ListTile(dense: true, leading: const Icon(Icons.key), title: Text(l.aiSettings))));
        return items;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 16),
            const SizedBox(width: 6),
            Flexible(child: Text(sel?.label ?? l.selectModel, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
  );
}
