import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../ai/ai_settings.dart';
import 'app_builder.dart';

/// Availability of each engine given keys and Runner capabilities.
class EngineOption {
  const EngineOption(this.engine, this.label, this.badge, this.icon, {required this.available, this.reason});
  final BuildEngine engine;
  final String label;
  final String badge;
  final IconData icon;
  final bool available;
  final String? reason;
}

List<EngineOption> engineOptions(AppLocalizations l, AiSettings s, bool claudeCodeAvailable,
        {bool serverGemini = false, Map<String, dynamic>? health, Set<String> panelKeys = const {}}) =>
    [
  EngineOption(BuildEngine.gemini, 'Gemini', l.badgeFreeTier, Icons.auto_awesome,
      available: serverGemini || s.isConfigured(AiProviderId.gemini), reason: l.needsKey('Gemini')),
  EngineOption(BuildEngine.claudeCode, 'Claude Code', l.badgeSubscription, Icons.terminal,
      available: claudeCodeAvailable, reason: l.claudeCodeUnavailable),
  EngineOption(BuildEngine.codex, 'Codex · ChatGPT', l.badgeSubscription, Icons.terminal,
      available: (health?['engines'] as Map?)?['codex'] == true, reason: l.subscriptionNotConnected('Codex (ChatGPT)')),
  EngineOption(BuildEngine.geminiCli, 'Gemini CLI · Google', l.badgeSubscription, Icons.terminal,
      available: (health?['engines'] as Map?)?['geminiCli'] == true, reason: l.subscriptionNotConnected('Gemini CLI')),
  EngineOption(BuildEngine.qwenCode, 'Qwen Code · Qwen', l.badgeSubscription, Icons.terminal,
      available: (health?['engines'] as Map?)?['qwenCode'] == true, reason: l.subscriptionNotConnected('Qwen Code')),
  EngineOption(BuildEngine.claude, 'Claude', l.badgePaid, Icons.psychology_outlined,
      available: s.isConfigured(AiProviderId.anthropic), reason: l.needsKey('Claude')),
  EngineOption(BuildEngine.openai, 'ChatGPT', l.badgePaid, Icons.chat_bubble_outline,
      available: s.isConfigured(AiProviderId.openai), reason: l.needsKey('ChatGPT')),
  EngineOption(BuildEngine.xai, 'Grok', l.badgePaid, Icons.bolt,
      available: s.isConfigured(AiProviderId.xai), reason: l.needsKey('Grok')),
  // These two take the key already pasted for the matching panel voice, so
  // they light up the moment that voice is configured.
  EngineOption(BuildEngine.deepseek, 'DeepSeek', l.badgePaid, Icons.travel_explore,
      available: panelKeys.contains('deepseek'), reason: l.needsKey('DeepSeek')),
  EngineOption(BuildEngine.qwen, 'Qwen Coder', l.badgePaid, Icons.hub_outlined,
      available: panelKeys.contains('qwen'), reason: l.needsKey('Qwen')),
];
