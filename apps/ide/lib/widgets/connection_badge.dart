import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/runner_socket.dart';
import '../core/session.dart';
import '../l10n/app_localizations.dart';
import '../ui/ui.dart';

class ConnectionBadge extends ConsumerWidget {
  const ConnectionBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final socket = ref.watch(runnerSocketProvider);
    return ValueListenableBuilder(
      valueListenable: socket.state,
      builder: (context, state, _) {
        // The state is told by the icon and the label too, not by colour alone.
        final (color, icon, label) = switch (state) {
          SocketState.connected => (context.ember.success, Icons.check, l.connected),
          SocketState.connecting => (context.ember.warning, Icons.sync, l.connecting),
          SocketState.disconnected => (context.scheme.error, Icons.cloud_off_outlined, l.disconnected),
        };
        return Semantics(
          label: label,
          child: Tooltip(
            message: label,
            excludeFromSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.md),
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle, border: Border.all(color: color)),
                child: Icon(icon, size: 12, color: color),
              ),
            ),
          ),
        );
      },
    );
  }
}
