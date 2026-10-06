import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ide_core/ide_core.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'factory_controller.dart';
import 'factory_widgets.dart';

/// "Needs you": the things only the owner can do (create the app in Play
/// Console, sign in again, paste a key), each with the values to copy and a
/// button that lets the Fabbrica go on.
class FactoryNeedsScreen extends ConsumerWidget {
  const FactoryNeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(factoryProvider);
    final ctl = ref.read(factoryProvider.notifier);

    Future<void> resolve(String appId, String needId, {bool skip = false}) async {
      try {
        await ctl.appAction(appId, 'resolve', body: {'needId': needId, if (skip) 'skip': true});
      } on RunnerException catch (e) {
        if (context.mounted) showEmberSnack(context, l.error(e.message), error: true);
      }
    }

    return state.when(
      loading: () => LoadingState(text: l.fxLoading),
      error: (e, _) => ErrorState(
        message: l.error(e is RunnerException ? e.message : '$e'),
        onRetry: () => ref.invalidate(factoryProvider),
      ),
      data: (data) => data.needs.isEmpty
          ? EmptyState(key: const Key('factoryNeedsEmpty'), icon: Icons.check_circle_outline, text: l.fxNeedsEmpty)
          : PageBody(
              children: [
                Text(l.fxNeedsIntro, style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
                for (final n in data.needs)
                  NeedsYouTile(
                    key: Key('need_${n.appId}_${n.id}'),
                    need: n,
                    onDone: () => resolve(n.appId, n.id),
                    onSkip: () => resolve(n.appId, n.id, skip: true),
                  ),
              ],
            ),
    );
  }
}
