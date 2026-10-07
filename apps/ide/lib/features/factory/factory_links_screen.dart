import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ide_core/ide_core.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'connect_cards.dart';
import 'factory_controller.dart';
import 'factory_models.dart';
import 'factory_widgets.dart';

/// "Qwen Code · Not installed": the name, and why it is not ready when it is not.
String _withDetail(AppLocalizations l, String name, List<LinkStatus> links, List<String> ids) {
  for (final link in links) {
    if (!ids.contains(link.id) || link.ready || link.detail.isEmpty) continue;
    final why = switch (link.detail) {
      'not_installed' => l.fxWhyNotInstalled,
      'not_signed_in' => l.fxWhyNotSignedIn,
      'missing' => l.fxWhyMissing,
      'windows' => l.fxWhyOnlyMac,
      _ => link.detail,
    };
    return '$name · $why';
  }
  return name;
}

/// Connections and capacity: what is ready to work with, what is missing and
/// how to connect it, what this computer can carry, and the two limits the
/// owner can set.
class FactoryLinksScreen extends ConsumerWidget {
  const FactoryLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final conn = ref.watch(factoryConnectionsProvider);
    final settings = ref.watch(factoryProvider).value?.settings;
    final ctl = ref.read(factoryProvider.notifier);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } on RunnerException catch (e) {
        if (context.mounted) showEmberSnack(context, l.error(e.message), error: true);
      }
    }

    Future<void> signIn(String engine) => run(() async {
      final api = await ref.read(runnerApiProvider.future);
      await api.startSubscriptionLogin(engine);
      if (context.mounted) showEmberSnack(context, l.fxSignInOpened);
    });

    return PageBody(
      children: [
        Row(
          children: [
            Expanded(child: Text(l.fxLinksTitle, style: context.text.headlineSmall)),
            IconButton(
              tooltip: l.retry,
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(factoryConnectionsProvider),
            ),
          ],
        ),
        // The store accounts come first: nothing reaches the stores without them.
        const StoreAccountsSection(),
        conn.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(Gap.xl),
            child: LoadingState(text: l.fxLoading),
          ),
          error: (e, _) => ErrorState(
            message: l.error(e is RunnerException ? e.message : '$e'),
            onRetry: () => ref.invalidate(factoryConnectionsProvider),
          ),
          data: (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                icon: Icons.memory_outlined,
                title: l.fxLinksEngines,
                children: [
                  Gap.vSm,
                  for (final (id, engine, name) in [
                    ('claude', 'claude-code', engineLabel('claude-code')),
                    ('codex', 'codex', engineLabel('codex')),
                    ('gemini', 'gemini-cli', engineLabel('gemini-cli')),
                    ('qwen', 'qwen-code', engineLabel('qwen-code')),
                  ])
                    StatusRow(
                      done: c.readyOf([id, engine]) ?? false,
                      text: _withDetail(l, name, c.links, [id, engine]),
                      trailing: (c.readyOf([id, engine]) ?? false)
                          ? null
                          : TextButton(onPressed: () => signIn(engine), child: Text(l.fxConnect)),
                    ),
                ],
              ),
              SectionCard(
                icon: Icons.build_outlined,
                title: l.fxLinksTools,
                children: [
                  Gap.vSm,
                  StatusRow(done: c.ready('flutter'), text: _withDetail(l, 'Flutter', c.links, ['flutter'])),
                  StatusRow(done: c.ready('android'), text: _withDetail(l, l.fxLinkAndroid, c.links, ['android'])),
                  StatusRow(done: c.ready('chrome'), text: _withDetail(l, l.fxLinkChrome, c.links, ['chrome'])),
                  StatusRow(done: c.ready('mac'), text: _withDetail(l, l.fxLinkMac, c.links, ['mac'])),
                ],
              ),
              if (c.cpus > 0)
                SectionCard(
                  icon: Icons.speed_outlined,
                  title: l.fxCapacityTitle,
                  hint: l.fxCapacityBody(c.cpus, (c.freeRamMb / 1024).toStringAsFixed(1), c.freeDiskGb),
                  children: [Gap.vSm, Text(l.fxCapacitySlots(c.agentSlots, c.buildSlots))],
                ),
            ],
          ),
        ),
        if (settings != null)
          SectionCard(
            icon: Icons.tune,
            title: l.fxLimitsTitle,
            children: [
              Gap.vSm,
              Row(
                children: [
                  Expanded(child: Text(l.fxLimitInFlight)),
                  Stepper2(
                    value: settings.maxInFlight,
                    min: 1,
                    max: 100,
                    onChanged: (v) => run(() => ctl.setMaxInFlight(v)),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text(l.fxDailyLabel)),
                  Stepper2(
                    value: settings.dailyStoreCap,
                    min: 1,
                    max: 100,
                    onChanged: (v) => run(() => ctl.setDailyCap(v)),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
