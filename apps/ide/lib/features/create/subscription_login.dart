import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'app_builder.dart';

/// The subscription engines: Claude, ChatGPT, Gemini and Qwen, on the user's own plan.
const subscriptionEngines = [BuildEngine.claudeCode, BuildEngine.codex, BuildEngine.geminiCli, BuildEngine.qwenCode];

/// Whether this computer is signed in to that subscription right now.
bool subscriptionConnected(Map<String, dynamic>? health, BuildEngine e) {
  final engines = health?['engines'] as Map?;
  return switch (e) {
    // Installed and signed in: older Runners only say "installed".
    BuildEngine.claudeCode => (engines?['claudeLogin'] ?? engines?['claudeCode']) == true,
    BuildEngine.codex => engines?['codex'] == true,
    BuildEngine.geminiCli => engines?['geminiCli'] == true,
    BuildEngine.qwenCode => engines?['qwenCode'] == true,
    _ => false,
  };
}

/// Opens the sign-in window on this computer, then watches until the
/// subscription shows as connected. Returns false when that is not possible
/// (a Runner on another machine): the caller then explains the steps instead.
Future<bool> startSubscriptionLogin(BuildContext context, WidgetRef ref, BuildEngine engine) async {
  final l = AppLocalizations.of(context);
  try {
    await (await ref.read(runnerApiProvider.future)).startSubscriptionLogin(engine.cli!);
  } catch (_) {
    return false;
  }
  if (context.mounted) showEmberSnack(context, l.subsLoginOpened(engine.cliLabel));
  // The sign-in happens in another window: look again every few seconds for up to three minutes.
  unawaited(() async {
    for (var i = 0; i < 45; i++) {
      await Future<void>.delayed(const Duration(seconds: 4));
      try {
        final health = await (await ref.read(runnerApiProvider.future)).health();
        if (subscriptionConnected(health, engine)) {
          ref.invalidate(runnerHealthProvider);
          return;
        }
      } catch (_) {
        return;
      }
    }
  }());
  return true;
}
