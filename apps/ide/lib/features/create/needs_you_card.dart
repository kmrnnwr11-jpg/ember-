import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'app_builder.dart';

/// What the engine cannot do by itself — a sign-in, a key, an account — shown
/// as notifications next to the chat. The owner settles one in a minute and the
/// engine goes straight back to work, instead of building around the gap.
class NeedsYouCard extends StatelessWidget {
  const NeedsYouCard({super.key, required this.builder});

  final AppBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (builder.needsYou.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return SectionCard(
      icon: Icons.notifications_active_outlined,
      title: l.needsYouTitle(builder.needsYou.length),
      hint: l.needsYouHint,
      tone: Tone.attention,
      children: [
        Gap.vMd,
        for (final need in List<String>.from(builder.needsYou))
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(Gap.md, Gap.md, Gap.sm, Gap.md),
              decoration: BoxDecoration(color: context.scheme.surface, borderRadius: Radii.mdAll),
              child: Row(
                children: [
                  Expanded(child: SelectableText(need)),
                  Gap.hSm,
                  FilledButton.icon(
                    onPressed: builder.running ? null : () => builder.resolveNeed(need),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l.done),
                  ),
                  IconButton(
                    tooltip: l.needsYouIgnore,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => builder.dismissNeed(need),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
