import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../review/reviewer_key_row.dart';
import '../review/reviewers.dart';
import 'ai_settings.dart';

const _keyPages = {
  AiProviderId.anthropic: 'https://console.anthropic.com/settings/keys',
  AiProviderId.openai: 'https://platform.openai.com/api-keys',
  AiProviderId.gemini: 'https://aistudio.google.com/apikey',
  AiProviderId.xai: 'https://console.x.ai',
};

/// The keys of the engines that write apps and of the models that review
/// them: one section of the settings page.
class AiSettingsSection extends ConsumerWidget {
  const AiSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(aiSettingsProvider);
    return settings.when(
      loading: () => const Padding(padding: EdgeInsets.all(Gap.lg), child: LoadingState()),
      error: (e, _) => ErrorState(message: l.error(e.toString()), onRetry: () => ref.invalidate(aiSettingsProvider)),
      data: (s) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Only what is actually used: the two engines that write apps.
          for (final p in [AiProviderId.gemini, AiProviderId.anthropic]) _KeyTile(provider: p, settings: s),
          Gap.vMd,
          // Set once, used by every app: the models that check a finished app
          // on their own once it is built.
          const _ReviewerKeys(),
        ],
      ),
    );
  }
}

/// Whether AI requests go through the Runner instead of straight from this device.
class AiProxySwitch extends ConsumerWidget {
  const AiProxySwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(aiSettingsProvider).value;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l.useRunnerProxy),
      subtitle: Text(kIsWeb ? l.useRunnerProxyWeb : l.useRunnerProxyHint),
      value: s?.effectiveProxy ?? false,
      onChanged: kIsWeb || s == null ? null : (v) => ref.read(aiSettingsProvider.notifier).updateSettings(useProxy: v),
    );
  }
}

class _KeyTile extends ConsumerStatefulWidget {
  const _KeyTile({required this.provider, required this.settings});

  final AiProviderId provider;
  final AiSettings settings;

  @override
  ConsumerState<_KeyTile> createState() => _KeyTileState();
}

class _KeyTileState extends ConsumerState<_KeyTile> {
  late final _ctrl = TextEditingController();
  String? _testResult;
  bool _testFailed = false;
  bool _testing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final l = AppLocalizations.of(context);
    final model = (await ref.read(aiCatalogProvider.future)).firstWhere(
      (m) => m.provider == widget.provider && m.tags.contains('fast'),
      orElse: () => builtInCatalog.firstWhere((m) => m.provider == widget.provider),
    );
    setState(() {
      _testing = true;
      _testResult = null;
    });
    String result;
    var failed = true;
    try {
      final provider = await ref.read(aiProviderFactory)(model);
      final events = await provider
          .chat(model: model.id, maxTokens: 16, messages: const [AiMessage.user('Reply with OK')])
          .toList();
      final err = events.whereType<AiError>().firstOrNull;
      failed = err != null;
      result = err == null ? l.keyWorks(model.label) : l.error(err.message);
    } catch (e) {
      result = l.error(e is AiException ? e.message : e.toString());
    }
    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = result;
        _testFailed = failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = widget.provider;
    final saved = widget.settings.keys[p];
    return SectionCard(
      margin: const EdgeInsets.only(bottom: Gap.md),
      title: '${p.product} · ${p.vendor}',
      trailing: saved != null ? Pill('•••• ${saved.length > 4 ? saved.substring(saved.length - 4) : ''}', tone: Tone.success) : null,
      children: [
        Gap.vSm,
        SecretField(
          key: Key('key_${p.name}'),
          controller: _ctrl,
          label: saved == null ? l.apiKey : l.replaceApiKey,
          getUrl: _keyPages[p],
          getLabel: l.getKey,
        ),
        Gap.vSm,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(
              onPressed: () async {
                await ref.read(aiSettingsProvider.notifier).setKey(p, _ctrl.text);
                _ctrl.clear();
              },
              child: Text(l.save),
            ),
            if (saved != null) ...[
              OutlinedButton(onPressed: _testing ? null : _test, child: Text(_testing ? l.testing : l.testKey)),
              TextButton(
                onPressed: () => ref.read(aiSettingsProvider.notifier).setKey(p, ''),
                child: Text(l.delete),
              ),
            ],
          ],
        ),
        if (_testResult != null) ...[Gap.vSm, InlineMessage(_testResult!, error: _testFailed)],
      ],
    );
  }
}

/// The models that read a finished app on their own and report what is fake,
/// missing or broken. Set once here; every app uses them automatically.
class _ReviewerKeys extends ConsumerWidget {
  const _ReviewerKeys();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(reviewerSettingsProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(reviewerSettingsProvider)),
      data: (s) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.fact_check_outlined, size: 20),
            Gap.hSm,
            Expanded(child: Text(l.reviewersTitle, style: context.text.titleSmall)),
          ]),
          Gap.vXs,
          Text(l.reviewersHint, style: context.text.bodySmall),
          Gap.vMd,
          for (final r in s.reviewers) ReviewerKeyRow(reviewer: r, settings: s),
        ],
      ),
    );
  }
}
