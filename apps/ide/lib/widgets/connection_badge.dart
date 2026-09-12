import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/runner_socket.dart';
import '../core/session.dart';
import '../l10n/app_localizations.dart';

class ConnectionBadge extends ConsumerWidget {
  const ConnectionBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final socket = ref.watch(runnerSocketProvider);
    return ValueListenableBuilder(
      valueListenable: socket.state,
      builder: (context, state, _) {
        final (color, label) = switch (state) {
          SocketState.connected => (Colors.green, l.connected),
          SocketState.connecting => (Colors.amber, l.connecting),
          SocketState.disconnected => (Colors.red, l.disconnected),
        };
        return Tooltip(
          message: label,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.circle, size: 10, color: color),
          ),
        );
      },
    );
  }
}
