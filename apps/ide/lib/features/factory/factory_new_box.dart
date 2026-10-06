import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';

/// A text file the owner added to the big box.
typedef AttachedFile = ({String name, String content});

/// The three steps as a row of numbered labels; the current one is lit.
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.current, required this.labels});
  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // Room for every label, or only the current one keeps its words.
      final showAll = box.maxWidth >= 480;
      return Row(
        children: [
          for (final (i, label) in labels.indexed) ...[
            if (i > 0) Expanded(child: Divider(color: context.scheme.outlineVariant)),
            Semantics(
              selected: i == current,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: i <= current ? context.scheme.primary : context.scheme.surfaceContainerHighest,
                    foregroundColor: i <= current ? context.scheme.onPrimary : context.scheme.onSurfaceVariant,
                    child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  if (showAll || i == current) ...[
                    Gap.hSm,
                    Text(
                      label,
                      style: context.text.labelLarge?.copyWith(
                        color: i == current ? null : context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// Step one: say it all. Paste or drop in ideas, lists, plans, prompts, files;
/// or ask for ideas on a theme. The supervisor makes apps out of it.
class FactoryBoxStep extends StatelessWidget {
  const FactoryBoxStep({
    super.key,
    required this.text,
    required this.theme,
    required this.invent,
    required this.count,
    required this.files,
    required this.onInvent,
    required this.onCount,
    required this.onChanged,
    required this.onAttach,
    required this.onRemoveFile,
  });

  final TextEditingController text;
  final TextEditingController theme;
  final bool invent;
  final int count;
  final List<AttachedFile> files;
  final ValueChanged<bool> onInvent;
  final ValueChanged<int> onCount;
  final VoidCallback onChanged;
  final VoidCallback onAttach;
  final ValueChanged<AttachedFile> onRemoveFile;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.fxBoxTitle, style: context.text.headlineSmall),
        Gap.vSm,
        Text(l.fxBoxHint, style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
        Gap.vLg,
        SegmentedButton<bool>(
          key: const Key('factoryMode'),
          segments: [
            ButtonSegment(value: false, icon: const Icon(Icons.edit_note), label: Text(l.fxModeMine)),
            ButtonSegment(value: true, icon: const Icon(Icons.auto_awesome_outlined), label: Text(l.fxModeInvent)),
          ],
          selected: {invent},
          onSelectionChanged: (s) => onInvent(s.first),
        ),
        Gap.vLg,
        if (!invent) ...[
          TextField(
            key: const Key('factoryBox'),
            controller: text,
            minLines: 10,
            maxLines: 24,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(hintText: l.fxBoxPlaceholder, alignLabelWithHint: true),
          ),
          Gap.vSm,
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                key: const Key('factoryAttach'),
                onPressed: onAttach,
                icon: const Icon(Icons.attach_file),
                label: Text(l.fxAttach),
              ),
              for (final f in files)
                InputChip(
                  label: Text(f.name, overflow: TextOverflow.ellipsis),
                  onDeleted: () => onRemoveFile(f),
                  deleteButtonTooltipMessage: l.delete,
                ),
            ],
          ),
        ] else ...[
          TextField(
            key: const Key('factoryTheme'),
            controller: theme,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(labelText: l.fxThemeLabel, hintText: l.fxThemeHint, alignLabelWithHint: true),
          ),
          Gap.vLg,
          Row(
            children: [
              Expanded(child: Text(l.fxHowMany, style: context.text.titleSmall)),
              Text('$count', style: context.text.titleMedium),
            ],
          ),
          Slider(
            key: const Key('factoryCount'),
            value: count.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            label: '$count',
            onChanged: (v) => onCount(v.round()),
          ),
        ],
        Gap.vMd,
        Text(l.fxBoxFootnote, style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant)),
      ],
    );
  }
}
