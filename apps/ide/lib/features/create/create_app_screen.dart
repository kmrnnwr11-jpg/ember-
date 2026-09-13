import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../ai/ai_settings.dart';
import 'app_builder.dart';

/// Arguments passed when arriving from the home prompt.
class CreateAppArgs {
  const CreateAppArgs({required this.prompt, required this.engine, this.modelKey, this.quality = 'fast', this.design, this.designName});
  final String prompt;
  final BuildEngine engine;
  final String? modelKey;
  final String quality;

  /// Design brief from the chosen mockup, appended to the build instructions.
  final String? design;
  final String? designName;
}

/// One builder per project, kept alive so a build continues if the user navigates away.
final appBuilderProvider = ChangeNotifierProvider.family<AppBuilder, (String, String)>((ref, key) {
  final (projectId, projectName) = key;
  final socket = ref.watch(runnerSocketProvider);
  return AppBuilder(
    projectId: projectId,
    projectName: projectName,
    request: socket.request,
    events: socket.events,
    fetchJobLog: (jobId) async => (await ref.read(runnerApiProvider.future)).jobLog(jobId),
    resolveProvider: ref.read(aiProviderFactory),
  );
});

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

List<EngineOption> engineOptions(AppLocalizations l, AiSettings s, bool claudeCodeAvailable) => [
  EngineOption(BuildEngine.gemini, 'Gemini', l.badgeFreeTier, Icons.auto_awesome,
      available: s.isConfigured(AiProviderId.gemini), reason: l.needsKey('Gemini')),
  EngineOption(BuildEngine.claudeCode, 'Claude Code', l.badgeSubscription, Icons.terminal,
      available: claudeCodeAvailable, reason: l.claudeCodeUnavailable),
  EngineOption(BuildEngine.claude, 'Claude', l.badgePaid, Icons.psychology_outlined,
      available: s.isConfigured(AiProviderId.anthropic), reason: l.needsKey('Claude')),
  EngineOption(BuildEngine.openai, 'ChatGPT', l.badgePaid, Icons.chat_bubble_outline,
      available: s.isConfigured(AiProviderId.openai), reason: l.needsKey('ChatGPT')),
  EngineOption(BuildEngine.xai, 'Grok', l.badgePaid, Icons.bolt,
      available: s.isConfigured(AiProviderId.xai), reason: l.needsKey('Grok')),
];

/// Prompt box + engine chips + model menu, shared by home and project screens.
class AppPromptComposer extends ConsumerStatefulWidget {
  const AppPromptComposer({super.key, required this.onSubmit, this.initialPrompt = '', this.busy = false, this.buttonLabel});

  final void Function(String prompt, BuildEngine engine, AiModel? model, String quality) onSubmit;
  final String initialPrompt;
  final bool busy;
  final String? buttonLabel;

  @override
  ConsumerState<AppPromptComposer> createState() => _AppPromptComposerState();
}

class _AppPromptComposerState extends ConsumerState<AppPromptComposer> {
  late final _text = TextEditingController(text: widget.initialPrompt);
  BuildEngine? _engine;
  AiModel? _model;
  bool _best = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(aiSettingsProvider).value ?? const AiSettings();
    final health = ref.watch(runnerHealthProvider).value;
    final claudeCode = (health?['engines'] as Map?)?['claudeCode'] == true;
    final catalog = ref.watch(aiCatalogProvider).value ?? builtInCatalog;
    final options = engineOptions(l, settings, claudeCode);

    final engine = _engine ?? options.firstWhere((o) => o.available, orElse: () => options.first).engine;
    final option = options.firstWhere((o) => o.engine == engine);
    final models = engine.provider == null ? <AiModel>[] : catalog.where((m) => m.provider == engine.provider).toList();
    final model = engine.provider == null
        ? null
        : (_model != null && _model!.provider == engine.provider
            ? _model
            : models.where((m) => m.id == engine.defaultModel).firstOrNull ?? models.firstOrNull);

    void submit() {
      if (_text.text.trim().isEmpty || !option.available || widget.busy) return;
      widget.onSubmit(_text.text.trim(), engine, model, _best ? 'best' : 'fast');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): submit},
          child: TextField(
            key: const Key('appPrompt'),
            controller: _text,
            minLines: 4,
            maxLines: 12,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: l.appPromptHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        Text(l.chooseAi, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              ChoiceChip(
                key: Key('engine_${o.engine.name}'),
                avatar: Icon(o.icon, size: 18),
                label: Text('${o.label} · ${o.badge}'),
                selected: engine == o.engine,
                onSelected: (_) => setState(() {
                  _engine = o.engine;
                  _model = null;
                }),
              ),
          ],
        ),
        if (!option.available) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 6),
              Expanded(child: Text(option.reason ?? '', style: TextStyle(color: Theme.of(context).colorScheme.error))),
              if (engine != BuildEngine.claudeCode)
                TextButton(onPressed: () => context.push('/settings'), child: Text(l.aiSettings)),
            ],
          ),
        ],
        if (engine == BuildEngine.claudeCode && option.available)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.bestQuality),
            subtitle: Text(_best ? l.bestQualityOn : l.bestQualityOff),
            value: _best,
            onChanged: (v) => setState(() => _best = v),
          ),
        if (models.length > 1 && option.available) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: model?.key,
            isDense: true,
            decoration: InputDecoration(labelText: l.selectModel, border: const OutlineInputBorder(), isDense: true),
            items: [for (final m in models) DropdownMenuItem(value: m.key, child: Text(m.label))],
            onChanged: (k) => setState(() => _model = models.firstWhere((m) => m.key == k)),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('createAppButton'),
          onPressed: _text.text.trim().isEmpty || !option.available || widget.busy ? null : submit,
          icon: widget.busy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.rocket_launch_outlined),
          label: Padding(padding: const EdgeInsets.all(12), child: Text(widget.buttonLabel ?? l.createApp)),
        ),
      ],
    );
  }
}

class CreateAppScreen extends ConsumerStatefulWidget {
  const CreateAppScreen({super.key, required this.projectId, this.args});

  final String projectId;
  final CreateAppArgs? args;

  @override
  ConsumerState<CreateAppScreen> createState() => _CreateAppScreenState();
}

class _CreateAppScreenState extends ConsumerState<CreateAppScreen> {
  final _change = TextEditingController();
  final _logScroll = ScrollController();
  bool _autoStarted = false;
  bool _showLog = true;

  @override
  void dispose() {
    _change.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  Future<void> _autoStart(AppBuilder b) async {
    final args = widget.args;
    if (_autoStarted || args == null || b.phase != BuildPhase.idle) return;
    _autoStarted = true;
    final catalog = await ref.read(aiCatalogProvider.future);
    final model = args.engine.provider == null
        ? null
        : catalog.where((m) => m.key == args.modelKey).firstOrNull ??
            catalog.where((m) => m.provider == args.engine.provider && m.id == args.engine.defaultModel).firstOrNull ??
            catalog.where((m) => m.provider == args.engine.provider).firstOrNull;
    b.build(prompt: args.prompt, engine: args.engine, model: model, quality: args.quality, design: args.design, designName: args.designName);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final projectAsync = ref.watch(_projectByIdProvider(widget.projectId));
    return projectAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text(l.error(e.toString())))),
      data: (project) {
        final b = ref.watch(appBuilderProvider((project.id, project.name)));
        WidgetsBinding.instance.addPostFrameCallback((_) => _autoStart(b));
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/projects')),
            title: Text(project.name),
            actions: [
              TextButton.icon(
                onPressed: () => context.go('/projects/${project.id}'),
                icon: const Icon(Icons.code),
                label: Text(l.openEditor),
              ),
            ],
          ),
          body: ListenableBuilder(
            listenable: b,
            builder: (context, _) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (b.phase == BuildPhase.idle && widget.args == null) ...[
                      Text(l.describeYourApp, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(l.describeYourAppHint),
                      const SizedBox(height: 16),
                      AppPromptComposer(onSubmit: (prompt, engine, model, quality) => b.build(prompt: prompt, engine: engine, model: model, quality: quality)),
                    ] else ...[
                      _PromptCard(prompt: b.prompt, engine: b.engine, model: b.model, designName: b.designName),
                      const SizedBox(height: 12),
                      _Steps(builder: b),
                      const SizedBox(height: 12),
                      if (b.phase == BuildPhase.ready) _ReadyCard(builder: b, projectId: project.id),
                      if (b.phase == BuildPhase.failed || b.phase == BuildPhase.cancelled) _FailedCard(builder: b, projectId: project.id),
                      if (b.phase == BuildPhase.ready || b.phase == BuildPhase.failed) ...[
                        const SizedBox(height: 12),
                        Text(l.improveApp, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _change,
                          minLines: 2,
                          maxLines: 6,
                          decoration: InputDecoration(hintText: l.improveAppHint, border: const OutlineInputBorder()),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () {
                              final text = _change.text.trim();
                              if (text.isEmpty) return;
                              _change.clear();
                              b.improve(text);
                            },
                            icon: const Icon(Icons.auto_fix_high),
                            label: Text(l.applyChange),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(l.buildLog, style: Theme.of(context).textTheme.titleSmall),
                          const Spacer(),
                          if (b.costUsd > 0) Text('≈\$${b.costUsd.toStringAsFixed(3)}  '),
                          IconButton(
                            icon: Icon(_showLog ? Icons.expand_less : Icons.expand_more),
                            onPressed: () => setState(() => _showLog = !_showLog),
                          ),
                        ],
                      ),
                      if (_showLog) _LogView(builder: b, scroll: _logScroll),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final _projectByIdProvider = FutureProvider.autoDispose.family<Project, String>((ref, id) async {
  final api = await ref.watch(runnerApiProvider.future);
  return api.project(id);
});

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.engine, required this.model, this.designName});
  final String prompt;
  final BuildEngine? engine;
  final AiModel? model;
  final String? designName;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt, maxLines: 6, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(
            [engine == BuildEngine.claudeCode ? 'Claude Code' : (model?.label ?? ''), if (designName != null) '🎨 $designName'].join(' · '),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _Steps extends StatelessWidget {
  const _Steps({required this.builder});
  final AppBuilder builder;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final b = builder;
    final order = [BuildPhase.generating, BuildPhase.dependencies, BuildPhase.checking, BuildPhase.building, BuildPhase.ready];
    final labels = {
      BuildPhase.generating: b.engine == BuildEngine.claudeCode
          ? [
              '${l.stepClaudeCode} (${b.writtenFiles.length} file)',
              if (b.currentAction != null) b.currentAction!,
            ].join('\n')
          : l.stepWriting(b.writtenFiles.length),
      BuildPhase.dependencies: l.stepDependencies,
      BuildPhase.checking: b.fixRound > 0 ? l.stepFixing(b.fixRound) : l.stepChecking,
      BuildPhase.building: l.stepBuilding,
      BuildPhase.ready: l.stepReady,
    };
    final current = b.phase == BuildPhase.fixing ? BuildPhase.checking : b.phase;
    final currentIndex = order.indexOf(current);
    final terminalFail = b.phase == BuildPhase.failed || b.phase == BuildPhase.cancelled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < order.length; i++)
              ListTile(
                dense: true,
                leading: switch ((i < currentIndex || b.phase == BuildPhase.ready, i == currentIndex)) {
                  (true, _) => const Icon(Icons.check_circle, color: Colors.green),
                  (false, true) when !terminalFail => const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  _ => Icon(Icons.radio_button_unchecked, color: Theme.of(context).disabledColor),
                },
                title: Text(labels[order[i]]!),
              ),
            if (b.running)
              Padding(
                padding: const EdgeInsets.all(8),
                child: OutlinedButton.icon(onPressed: b.cancel, icon: const Icon(Icons.stop), label: Text(l.stop)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.builder, required this.projectId});
  final AppBuilder builder;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final session = ref.watch(sessionProvider).value;
        final url = session == null ? null : builder.preview?.resolve(session.runnerUrl);
        return Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.appReadyTitle, style: Theme.of(context).textTheme.titleLarge),
                if (builder.summary != null) ...[const SizedBox(height: 8), Text(builder.summary!, maxLines: 8, overflow: TextOverflow.ellipsis)],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const Key('openPreview'),
                      onPressed: () => url == null
                          ? context.go('/projects/$projectId?panel=preview')
                          : context.push(Uri(path: '/run', queryParameters: {'url': url}).toString()),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l.openApp),
                    ),
                    if (url != null)
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(l.openInBrowser),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/projects/$projectId'),
                      icon: const Icon(Icons.code),
                      label: Text(l.viewCode),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(l.androidFileQuestion, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(l.androidFileHint, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      key: const Key('buildApk'),
                      onPressed: builder.androidBuilding ? null : () => builder.buildAndroid('apk'),
                      icon: const Icon(Icons.android),
                      label: Text(l.generateApk),
                    ),
                    FilledButton.tonalIcon(
                      key: const Key('buildAab'),
                      onPressed: builder.androidBuilding ? null : () => builder.buildAndroid('aab'),
                      icon: const Icon(Icons.shop),
                      label: Text(l.generateAab),
                    ),
                  ],
                ),
                if (builder.androidBuilding) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 6),
                  Text(l.androidBuilding(builder.androidKind!.toUpperCase())),
                ],
                if (builder.androidStatus == 'ready' && session != null && builder.androidPath != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('downloadAndroid'),
                    onPressed: () => launchUrl(
                      Uri.parse('${session.runnerUrl}${builder.androidPath}'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.download),
                    label: Text(builder.androidKind == 'apk' ? l.downloadApk : l.downloadAab),
                  ),
                  const SizedBox(height: 6),
                  Text(builder.androidKind == 'apk' ? l.apkInstallHint : l.aabHint, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('backupKey'),
                    onPressed: () => _showKeyBackup(context, ref, projectId, session.runnerUrl),
                    icon: const Icon(Icons.key),
                    label: Text(l.backupSigningKey),
                  ),
                ],
                if (builder.androidStatus == 'failed') ...[
                  const SizedBox(height: 12),
                  Text(l.androidFailed, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  if (builder.androidError != null)
                    SelectableText(builder.androidError!, maxLines: 10, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showKeyBackup(BuildContext context, WidgetRef ref, String projectId, String runnerUrl) async {
  final l = AppLocalizations.of(context);
  try {
    final info = await (await ref.read(runnerApiProvider.future)).signingLink(projectId);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.backupSigningKey),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.backupSigningKeyHint),
            const SizedBox(height: 12),
            SelectableText('Alias: ${info['alias']}'),
            Row(
              children: [
                Expanded(child: SelectableText('Password: ${info['password']}')),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => Clipboard.setData(ClipboardData(text: info['password'] as String)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l.close)),
          FilledButton.icon(
            onPressed: () => launchUrl(Uri.parse('$runnerUrl${info['path']}'), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.download),
            label: Text(l.downloadKeystore),
          ),
        ],
      ),
    );
  } on RunnerException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.error(e.message))));
  }
}

class _FailedCard extends StatelessWidget {
  const _FailedCard({required this.builder, required this.projectId});
  final AppBuilder builder;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(builder.phase == BuildPhase.cancelled ? l.buildCancelled : l.buildFailedTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onErrorContainer)),
            if (builder.error != null) ...[
              const SizedBox(height: 8),
              SelectableText(builder.error!, maxLines: 12, style: TextStyle(color: scheme.onErrorContainer)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => builder.build(prompt: builder.prompt, engine: builder.engine!, model: builder.model, quality: builder.quality, design: builder.design, designName: builder.designName),
                  icon: const Icon(Icons.refresh),
                  label: Text(l.retry),
                ),
                OutlinedButton(onPressed: () => context.go('/projects/$projectId'), child: Text(l.openEditor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogView extends StatelessWidget {
  const _LogView({required this.builder, required this.scroll});
  final AppBuilder builder;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final b = builder;
    final generating = b.phase == BuildPhase.generating || b.phase == BuildPhase.fixing;
    final live = b.liveText.toString();
    final tail = live.length > 1500 ? live.substring(live.length - 1500) : live;
    return Container(
      height: 280,
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(10),
      child: ListView(
        controller: scroll,
        reverse: true,
        children: [
          if (generating && tail.isNotEmpty && b.engine != BuildEngine.claudeCode)
            Text(tail, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white38)),
          for (final line in b.log.reversed.take(300))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                '${switch (line.kind) { 'file' => '📄 ', 'tool' => '⚙️ ', 'error' => '⚠️ ', 'ai' => '💬 ', _ => '• ' }}${line.text}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: line.kind == 'error' ? Colors.orangeAccent : Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
