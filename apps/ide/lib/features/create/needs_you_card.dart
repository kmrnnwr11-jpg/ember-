import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.notifications_active_outlined, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  builder.needsYou.length == 1 ? 'Serve una cosa da te' : 'Servono ${builder.needsYou.length} cose da te',
                  style: theme.textTheme.titleMedium?.copyWith(color: scheme.onTertiaryContainer),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              'Ember non puo\' farle da solo (un accesso, una chiave, un account). '
              'Falle e tocca "Fatto": riprende da dove si era fermato.',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onTertiaryContainer),
            ),
            const SizedBox(height: 12),
            for (final need in List<String>.from(builder.needsYou))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: SelectableText(need)),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: builder.running ? null : () => builder.resolveNeed(need),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Fatto'),
                      ),
                      IconButton(
                        tooltip: 'Ignora',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => builder.dismissNeed(need),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
