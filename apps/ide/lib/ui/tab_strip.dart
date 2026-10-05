import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// One tab of a [TabStrip].
@immutable
class TabStripItem {
  const TabStripItem({required this.label, this.icon, this.muted = false, this.status});

  final String label;
  final IconData? icon;

  /// Something that is over (an exited terminal): drawn dimmer.
  final bool muted;

  /// Small mark after the label (saving, unsaved).
  final Widget? status;
}

/// A row of closable tabs that scrolls sideways: open files, terminals.
class TabStrip extends StatelessWidget {
  const TabStrip({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.onClose,
    required this.closeTooltip,
    this.trailing = const [],
    this.onDark = false,
  });

  final List<TabStripItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;
  final String closeTooltip;

  /// Fixed controls at the end of the strip (new tab).
  final List<Widget> trailing;

  /// Drawn on a terminal or another always-dark surface.
  final bool onDark;

  static const double _minHeight = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final ember = context.ember;
    final foreground = onDark ? ember.onCodeSurface : scheme.onSurface;
    final mutedColor = onDark ? ember.codeMuted : scheme.onSurfaceVariant;
    final selectedFill = onDark ? ember.onCodeSurface.withValues(alpha: 0.08) : scheme.surface;

    Widget tab(int i) {
      final item = items[i];
      final isSelected = i == selected;
      final color = item.muted ? mutedColor : foreground;
      return Semantics(
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: () => onSelect(i),
          child: Container(
            constraints: const BoxConstraints(minHeight: _minHeight),
            padding: const EdgeInsetsDirectional.only(start: Gap.md),
            decoration: BoxDecoration(
              color: isSelected ? selectedFill : null,
              border: Border(bottom: BorderSide(color: isSelected ? scheme.primary : Colors.transparent, width: 2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[Icon(item.icon, size: 16, color: color), Gap.hXs],
                Text(item.label, style: context.text.labelLarge?.copyWith(color: color)),
                if (item.status != null) ...[Gap.hXs, item.status!],
                IconButton(
                  tooltip: closeTooltip,
                  iconSize: 16,
                  color: mutedColor,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: _minHeight),
                  icon: const Icon(Icons.close),
                  onPressed: () => onClose(i),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: onDark ? ember.codeSurface : scheme.surfaceContainer,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [for (var i = 0; i < items.length; i++) tab(i)]),
              ),
            ),
            ...trailing,
          ],
        ),
      ),
    );
  }
}
