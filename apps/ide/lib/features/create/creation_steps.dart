import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';

/// The four steps from an idea to an app, with the one in progress lit up.
/// Shown on every screen of the way, so the user always knows where they are.
class CreationSteps extends StatelessWidget {
  const CreationSteps({super.key, required this.current, this.onDark = false});

  /// 0 describe, 1 choose the style, 2 name it, 3 Ember builds it.
  final int current;

  /// Drawn over a mockup or another always-dark surface.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = context.scheme;
    final ember = context.ember;
    final labels = [l.flowDescribe, l.flowStyle, l.flowName, l.flowBuild];
    final muted = onDark ? ember.codeMuted : scheme.onSurfaceVariant;
    final strong = onDark ? ember.onCodeSurface : scheme.onSurface;

    Widget dot(int i) {
      final done = i < current;
      final now = i == current;
      return AnimatedContainer(
        duration: Motion.of(context),
        curve: Motion.curve,
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: now ? scheme.primary : (done ? ember.success.withValues(alpha: 0.16) : Colors.transparent),
          border: Border.all(color: now ? scheme.primary : (done ? ember.success : muted.withValues(alpha: 0.5)), width: 1.5),
        ),
        child: done
            ? Icon(Icons.check, size: 15, color: ember.success)
            : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: now ? scheme.onPrimary : muted)),
      );
    }

    return Semantics(
      label: '${current + 1} / ${labels.length}: ${labels[current]}',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            // On a phone only the step in progress keeps its name.
            final compact = box.maxWidth < 520;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0)
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 48, minWidth: 12),
                        margin: const EdgeInsets.symmetric(horizontal: Gap.sm),
                        height: 1.5,
                        color: i <= current ? ember.success.withValues(alpha: 0.6) : muted.withValues(alpha: 0.3),
                      ),
                    ),
                  dot(i),
                  if (!compact || i == current) ...[
                    Gap.hSm,
                    Flexible(
                      flex: 3,
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: i == current ? FontWeight.w700 : FontWeight.w500, color: i == current ? strong : muted),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
