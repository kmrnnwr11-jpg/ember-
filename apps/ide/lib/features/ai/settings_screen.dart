import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'ai_settings.dart';

const _keyPages = {
  AiProviderId.anthropic: 'https://console.anthropic.com/settings/keys',
  AiProviderId.openai: 'https://platform.openai.com/api-keys',
  AiProviderId.gemini: 'https://aistudio.google.com/apikey',
  AiProviderId.xai: 'https://console.x.ai',
};

class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(aiSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.aiSettings)),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.error(e.toString()))),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.apiKeysHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            for (final p in [AiProviderId.gemini, AiProviderId.anthropic, AiProviderId.openai, AiProviderId.xai])
              _KeyTile(provider: p, settings: s),
            _CompatibleTile(settings: s),
            const Divider(height: 32),
            SwitchListTile(
              title: Text(l.useRunnerProxy),
              subtitle: Text(kIsWeb ? l.useRunnerProxyWeb : l.useRunnerProxyHint),
              value: s.effectiveProxy,
              onChanged: kIsWeb ? null : (v) => ref.read(aiSettingsProvider.notifier).updateSettings(useProxy: v),
            ),
          ],
        ),
      ),
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
  bool _obscure = true;
  String? _testResult;
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
    try {
      final provider = await ref.read(aiProviderFactory)(model);
      final events = await provider
          .chat(model: model.id, maxTokens: 16, messages: const [AiMessage.user('Reply with OK')])
          .toList();
      final err = events.whereType<AiError>().firstOrNull;
      result = err == null ? l.keyWorks(model.label) : l.error(err.message);
    } catch (e) {
      result = l.error(e is AiException ? e.message : e.toString());
    }
    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = widget.provider;
    final saved = widget.settings.keys[p];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${p.product} · ${p.vendor}', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (saved != null) Chip(label: Text('•••• ${saved.length > 4 ? saved.substring(saved.length - 4) : ''}')),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: Key('key_${p.name}'),
              controller: _ctrl,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: saved == null ? l.apiKey : l.replaceApiKey,
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
                if (_keyPages[p] != null)
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(l.getKey),
                    onPressed: () => launchUrl(Uri.parse(_keyPages[p]!), mode: LaunchMode.externalApplication),
                  ),
              ],
            ),
            if (_testResult != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_testResult!)),
          ],
        ),
      ),
    );
  }
}

class _CompatibleTile extends ConsumerStatefulWidget {
  const _CompatibleTile({required this.settings});
  final AiSettings settings;

  @override
  ConsumerState<_CompatibleTile> createState() => _CompatibleTileState();
}

class _CompatibleTileState extends ConsumerState<_CompatibleTile> {
  late final _base = TextEditingController(text: widget.settings.compatibleBaseUrl);
  final _key = TextEditingController();
  final _model = TextEditingController();

  @override
  void dispose() {
    _base.dispose();
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = widget.settings;
    final notifier = ref.read(aiSettingsProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AiProviderId.openaiCompatible.product, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _base,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).baseUrl, hintText: 'https://openrouter.ai/api/v1', isDense: true),
            ),
            TextField(
              controller: _key,
              obscureText: true,
              decoration: InputDecoration(labelText: l.apiKeyOptional, isDense: true),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _model,
                    decoration: InputDecoration(labelText: l.addModelId, hintText: 'llama3.2 / meta-llama/llama-3.3-70b', isDense: true),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final id = _model.text.trim();
                    if (id.isEmpty) return;
                    notifier.updateSettings(customModels: {...s.customModels, 'openaiCompatible:$id'}.toList());
                    _model.clear();
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final m in s.customModels)
                  InputChip(
                    label: Text(m.split(':').skip(1).join(':')),
                    onDeleted: () => notifier.updateSettings(customModels: s.customModels.where((x) => x != m).toList()),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await notifier.updateSettings(compatibleBaseUrl: _base.text);
                if (_key.text.isNotEmpty) await notifier.setKey(AiProviderId.openaiCompatible, _key.text);
                _key.clear();
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
