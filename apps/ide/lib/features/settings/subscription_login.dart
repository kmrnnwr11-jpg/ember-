import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../create/access_links.dart';
import '../create/app_builder.dart';
import '../create/subscription_login.dart';

String _planName(BuildEngine e) => engineAccess[e]?.planName ?? e.cliLabel;

/// Claude, ChatGPT and Gemini: connected or not, and a button to connect.
/// The sign-in is kept on this computer, so it is done once.
class SubscriptionsSection extends ConsumerWidget {
  const SubscriptionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final health = ref.watch(runnerHealthProvider).value;
    return SectionCard(
      icon: Icons.workspace_premium_outlined,
      title: l.subsTitle,
      hint: l.subsHint,
      children: [
        Gap.vSm,
        for (final e in subscriptionEngines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: StatusRow(
              done: subscriptionConnected(health, e),
              text: subscriptionConnected(health, e) ? l.accountConnected(_planName(e)) : l.accountNotConnected(_planName(e)),
              trailing: subscriptionConnected(health, e)
                  ? null
                  : TextButton(
                      key: Key('connect_${e.name}'),
                      onPressed: () async {
                        if (!await startSubscriptionLogin(context, ref, e) && context.mounted) showConnectSubscription(context, e);
                      },
                      child: Text(l.subsConnect),
                    ),
            ),
          ),
      ],
    );
  }
}
