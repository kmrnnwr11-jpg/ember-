import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'app_builder.dart';

/// Where to get access for an engine. Payments always happen on the provider's own site.
class EngineAccess {
  const EngineAccess({this.apiKeys, this.credits, this.plan, this.planName, this.connectCommand});
  final String? apiKeys;
  final String? credits;
  final String? plan;
  final String? planName;

  /// Terminal command that logs the subscription CLI in on the Runner machine.
  final String? connectCommand;
}

const engineAccess = <BuildEngine, EngineAccess>{
  BuildEngine.gemini: EngineAccess(
    apiKeys: 'https://aistudio.google.com/apikey',
    credits: 'https://console.cloud.google.com/billing',
    plan: 'https://one.google.com/about/google-ai-plans/',
    planName: 'Google AI',
  ),
  BuildEngine.openai: EngineAccess(
    apiKeys: 'https://platform.openai.com/api-keys',
    credits: 'https://platform.openai.com/settings/organization/billing/overview',
    plan: 'https://chatgpt.com/pricing',
    planName: 'ChatGPT',
  ),
  BuildEngine.claude: EngineAccess(
    apiKeys: 'https://console.anthropic.com/settings/keys',
    credits: 'https://console.anthropic.com/settings/billing',
    plan: 'https://claude.ai/upgrade',
    planName: 'Claude Pro / Max',
  ),
  BuildEngine.xai: EngineAccess(
    apiKeys: 'https://console.x.ai/',
    credits: 'https://console.x.ai/',
    plan: 'https://x.ai/grok',
    planName: 'SuperGrok',
  ),
  BuildEngine.claudeCode: EngineAccess(plan: 'https://claude.ai/upgrade', planName: 'Claude Pro / Max', connectCommand: 'claude   (then type /login)'),
  BuildEngine.codex: EngineAccess(plan: 'https://chatgpt.com/pricing', planName: 'ChatGPT Plus / Pro', connectCommand: 'codex login'),
  BuildEngine.geminiCli: EngineAccess(plan: 'https://one.google.com/about/google-ai-plans/', planName: 'Google account / Google AI', connectCommand: 'gemini   (choose "Login with Google")'),
};

void _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// "Get API key · Buy credits · Subscribe" (API engines) or "Subscribe · Connect" (subscription engines).
class AccessLinks extends StatelessWidget {
  const AccessLinks({super.key, required this.engine});
  final BuildEngine engine;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = engineAccess[engine];
    if (a == null) return const SizedBox.shrink();
    final muted = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l.accessTitle} — ${l.accessPaidOutside}', style: muted),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (a.apiKeys != null) OutlinedButton.icon(onPressed: () => _open(a.apiKeys!), icon: const Icon(Icons.key, size: 16), label: Text(l.getKey)),
            if (a.credits != null) OutlinedButton.icon(onPressed: () => _open(a.credits!), icon: const Icon(Icons.shopping_cart_outlined, size: 16), label: Text(l.buyCredits)),
            if (a.plan != null)
              OutlinedButton.icon(onPressed: () => _open(a.plan!), icon: const Icon(Icons.workspace_premium_outlined, size: 16), label: Text('${l.getSubscription} · ${a.planName}')),
            if (a.connectCommand != null)
              FilledButton.tonalIcon(onPressed: () => showConnectSubscription(context, engine), icon: const Icon(Icons.link, size: 16), label: Text(l.connectSubscription)),
          ],
        ),
        if (engine == BuildEngine.xai) Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.grokNoCli, style: muted)),
      ],
    );
  }
}

/// Explains how to log a subscription CLI in on the Runner machine.
Future<void> showConnectSubscription(BuildContext context, BuildEngine engine) {
  final l = AppLocalizations.of(context);
  final a = engineAccess[engine]!;
  final command = a.connectCommand!.split('   ').first;
  return showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text('${l.connectSubscription} · ${engine.cliLabel}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(l.connectHowTo(a.planName!, a.connectCommand!)),
            const SizedBox(height: 12),
            Text(l.connectPersonalNote, style: Theme.of(d).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Clipboard.setData(ClipboardData(text: command)),
          icon: const Icon(Icons.copy, size: 16),
          label: Text(l.copy),
        ),
        TextButton(onPressed: () => _open(a.plan!), child: Text(l.getSubscription)),
        FilledButton(onPressed: () => Navigator.pop(d), child: Text(l.close)),
      ],
    ),
  );
}
