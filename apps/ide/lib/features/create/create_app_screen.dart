import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/locale.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../ai/ai_settings.dart';
import '../../widgets/ember_logo.dart';
import 'access_links.dart';
import 'logo_card.dart';
import '../assistant/home_assistant.dart';
import 'checkup_card.dart';
import 'ios_card.dart';
import 'phone_card.dart';
import 'github_card.dart';
import 'play_update_card.dart';
import 'products_card.dart';
import 'screenshots_card.dart';
import 'ads_card.dart';
import 'app_builder.dart';
import 'forge_view.dart';

/// The chat and settings of each built app, saved on this device.
class AppSessionStore {
  static String _key(String projectId) => 'ember_session_$projectId';

  static Future<void> save(String projectId, Map<String, dynamic> session) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key(projectId), jsonEncode(session));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> load(String projectId) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key(projectId));
      return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

/// Arguments passed when arriving from the home prompt.
class CreateAppArgs {
  const CreateAppArgs({required this.prompt, required this.engine, this.modelKey, this.quality = 'fast', this.design, this.designName, this.reference});
  final String prompt;
  final BuildEngine engine;
  final String? modelKey;
  final String quality;

  /// Design brief from the chosen mockup, appended to the build instructions.
  final String? design;
  final String? designName;

  /// Brief of a Play Store app to take as a model (see [ReferenceApp.brief]).
  final String? reference;
}

/// One builder per project, kept alive so a build continues if the user navigates away.
final appBuilderProvider = ChangeNotifierProvider.family<AppBuilder, (String, String)>((ref, key) {
  final (projectId, projectName) = key;
  final socket = ref.watch(runnerSocketProvider);
  final builder = AppBuilder(
    projectId: projectId,
    projectName: projectName,
    strings: ref.read(stringsProvider),
    onSession: (s) => AppSessionStore.save(projectId, s),
    request: socket.request,
    events: socket.events,
    fetchJobLog: (jobId) async => (await ref.read(runnerApiProvider.future)).jobLog(jobId),
    resolveProvider: ref.read(aiProviderFactory),
    androidInfo: () async {
      final info = await (await ref.read(runnerApiProvider.future)).androidInfo(projectId);
      return 'ANDROID APP INFO (use for Firebase Android app and Google Sign-In):\n'
          '- package name: ${info['applicationId']}\n'
          '- SHA-1 release (Play/upload key): ${info['sha1Release']}\n'
          '- SHA-1 debug: ${info['sha1Debug']}';
    },
  );
  // Follow language changes without recreating the builder (a build may be running).
  ref.listen(stringsProvider, (_, s) => builder.strings = s);
  return builder;
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

List<EngineOption> engineOptions(AppLocalizations l, AiSettings s, bool claudeCodeAvailable, {bool serverGemini = false, Map<String, dynamic>? health}) => [
  EngineOption(BuildEngine.gemini, 'Gemini', l.badgeFreeTier, Icons.auto_awesome,
      available: serverGemini || s.isConfigured(AiProviderId.gemini), reason: l.needsKey('Gemini')),
  EngineOption(BuildEngine.claudeCode, 'Claude Code', l.badgeSubscription, Icons.terminal,
      available: claudeCodeAvailable, reason: l.claudeCodeUnavailable),
  EngineOption(BuildEngine.codex, 'Codex · ChatGPT', l.badgeSubscription, Icons.terminal,
      available: (health?['engines'] as Map?)?['codex'] == true, reason: l.subscriptionNotConnected('Codex (ChatGPT)')),
  EngineOption(BuildEngine.geminiCli, 'Gemini CLI · Google', l.badgeSubscription, Icons.terminal,
      available: (health?['engines'] as Map?)?['geminiCli'] == true, reason: l.subscriptionNotConnected('Gemini CLI')),
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

  /// Model picked for a subscription engine (Claude Code / Codex / Gemini CLI).
  String? _cliModel;

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
    final options = engineOptions(l, settings, claudeCode, serverGemini: serverGeminiAvailable(health), health: health);

    final engine = _engine ?? options.firstWhere((o) => o.available, orElse: () => options.first).engine;
    final option = options.firstWhere((o) => o.engine == engine);
    final models = engine.provider == null ? <AiModel>[] : catalog.where((m) => m.provider == engine.provider).toList();
    final model = engine.provider == null
        ? null
        : (_model != null && _model!.provider == engine.provider
            ? _model
            : models.where((m) => m.id == engine.defaultModel).firstOrNull ?? models.firstOrNull);

    final cliModels = [
      for (final m in ((health?['cliModels'] as Map?)?[engine.cli] as List? ?? const []).cast<Map<String, dynamic>>())
        (id: m['id'] as String, label: m['label'] as String, description: m['description'] as String?),
    ];
    final cliModel = cliModels.any((m) => m.id == _cliModel) ? _cliModel : cliModels.firstOrNull?.id;

    void submit() {
      if (_text.text.trim().isEmpty || !option.available || widget.busy) return;
      // For subscription engines the chosen CLI model travels in `quality`.
      widget.onSubmit(_text.text.trim(), engine, model, engine.isCli ? (cliModel ?? 'fast') : 'fast');
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
                  _cliModel = null;
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
              if (!engine.isCli)
                TextButton(onPressed: () => context.push('/settings'), child: Text(l.aiSettings))
              else if (engine != BuildEngine.claudeCode || !option.available)
                TextButton(onPressed: () => showConnectSubscription(context, engine), child: Text(l.connectSubscription)),
            ],
          ),
        ],
        const SizedBox(height: 8),
        AccessLinks(
          engine: engine,
          connected: option.available,
          subscriptionReady: (e) => options.any((o) => o.engine == e && o.available),
          onUseSubscription: (e) => setState(() {
            _engine = e;
            _model = null;
          }),
        ),
        if (engine.isCli && cliModels.isNotEmpty) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('cliModel_${engine.name}'),
            initialValue: cliModel,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.selectModel, border: const OutlineInputBorder(), isDense: true),
            items: [
              for (final m in cliModels)
                DropdownMenuItem(value: m.id, child: Text(m.description == null ? m.label : '${m.label} — ${m.description}', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _cliModel = v),
          ),
        ],
        if (models.isNotEmpty) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('apiModel_${engine.name}'),
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
              : const Icon(Icons.local_fire_department),
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
  bool _showAssistant = false;

  /// Which store this page is working on: Android (false) or iPhone (true).
  bool _ios = false;

  @override
  void dispose() {
    _change.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  Future<void> _autoStart(AppBuilder b) async {
    final args = widget.args;
    if (_autoStarted || b.phase != BuildPhase.idle) return;
    _autoStarted = true;
    final catalog = await ref.read(aiCatalogProvider.future);
    if (args == null) {
      // Opening an existing app: continue the chat, rebuild the preview, allow new changes and new APK/AAB versions.
      final session = await AppSessionStore.load(widget.projectId) ?? <String, dynamic>{};
      final health = await ref.read(runnerHealthProvider.future).catchError((_) => <String, dynamic>{});
      final saved = BuildEngine.values.where((e) => e.name == session['engine']).firstOrNull;
      final claudeCode = (health['engines'] as Map?)?['claudeCode'] == true;
      final engine = saved ?? (claudeCode ? BuildEngine.claudeCode : BuildEngine.gemini);
      final model = engine.provider == null
          ? null
          : catalog.where((m) => m.key == session['modelKey']).firstOrNull ??
              catalog.where((m) => m.provider == engine.provider && m.id == engine.defaultModel).firstOrNull ??
              catalog.where((m) => m.provider == engine.provider).firstOrNull;
      if (!mounted) return;
      await b.reopen(session: session, engine: engine, model: model);
      return;
    }
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
            title: Text(project.displayName),
            actions: [
              IconButton(
                tooltip: l.acAssistant,
                icon: Icon(_showAssistant ? Icons.forum : Icons.forum_outlined),
                onPressed: () => setState(() => _showAssistant = !_showAssistant),
              ),
              TextButton.icon(
                onPressed: () => context.go('/projects/${project.id}'),
                icon: const Icon(Icons.code),
                label: Text(l.openEditor),
              ),
            ],
          ),
          body: Row(
            children: [
              Expanded(child: _buildBody(context, l, b, project)),
              if (_showAssistant && MediaQuery.sizeOf(context).width >= 900) ...[
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 380,
                  child: HomeAssistantPanel(
                    app: (id: project.id, name: project.displayName),
                    onClose: () => setState(() => _showAssistant = false),
                  ),
                ),
              ],
            ],
          ),
          // On a narrow window the assistant takes the whole screen instead of squeezing the app.
          endDrawer: MediaQuery.sizeOf(context).width < 900
              ? Drawer(
                  width: 380,
                  child: HomeAssistantPanel(app: (id: project.id, name: project.displayName), onClose: () => Navigator.pop(context)),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l, AppBuilder b, Project project) {
    return ListenableBuilder(
            listenable: b,
            builder: (context, _) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (b.phase == BuildPhase.idle) ...[
                      const SizedBox(height: 120),
                      const Center(child: EmberMark(size: 96)),
                    ] else ...[
                      _PromptCard(prompt: b.prompt, engine: b.engine, model: b.model, designName: b.designName, quality: b.quality),
                      const SizedBox(height: 12),
                      _Steps(builder: b),
                      const SizedBox(height: 12),
                      if (b.phase == BuildPhase.ready) PlatformTabs(ios: _ios, onChanged: (v) => setState(() => _ios = v)),
                      if (b.phase == BuildPhase.ready && _ios) IosCard(builder: b),
                      if (b.phase == BuildPhase.ready && !_ios)
                        CheckupCard(
                          projectId: project.id,
                          builder: b,
                          previewUrl: b.preview?.resolve(ref.read(sessionProvider).value?.runnerUrl ?? ''),
                        ),
                      if (b.phase == BuildPhase.ready && !_ios) _ReadyCard(builder: b, projectId: project.id),
                      if (b.phase == BuildPhase.ready && !_ios) PhoneCard(projectId: project.id, builder: b),
                      if (b.phase == BuildPhase.ready && !_ios) PlayUpdateCard(builder: b, projectId: project.id),
                      if (b.phase == BuildPhase.ready) GitHubCard(projectId: project.id),
                      if (b.phase == BuildPhase.ready) LogoCard(builder: b, projectId: project.id),
                      if (b.phase == BuildPhase.ready || b.phase == BuildPhase.generating) ScreenshotsCard(builder: b, projectId: project.id),
                      if (b.phase == BuildPhase.ready && b.products.isNotEmpty) ProductsCard(builder: b, projectId: project.id),
                      if (b.phase == BuildPhase.ready) AdsCard(builder: b),
                      if (b.phase == BuildPhase.failed || b.phase == BuildPhase.cancelled) _FailedCard(builder: b, projectId: project.id),
                      if (b.conversation.length > 1) ...[
                        const SizedBox(height: 12),
                        for (final msg in b.conversation.skip(1)) _ChatBubble(role: msg.role, text: msg.text),
                      ],
                      if (b.running && b.conversation.length > 1 && b.conversation.last.role == 'user')
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Align(alignment: Alignment.centerLeft, child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        ),
                      if (b.phase == BuildPhase.ready || b.phase == BuildPhase.failed) ...[
                        const SizedBox(height: 12),
                        Text(l.improveApp, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        TextField(
                          key: const Key('nextRequest'),
                          controller: _change,
                          minLines: 2,
                          maxLines: 8,
                          decoration: InputDecoration(hintText: l.improveAppHint, border: const OutlineInputBorder()),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            key: const Key('sendRequest'),
                            onPressed: () {
                              final text = _change.text.trim();
                              if (text.isEmpty) return;
                              _change.clear();
                              b.improve(text);
                            },
                            icon: const Icon(Icons.send),
                            label: Text(l.send),
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
    );
  }
}

final _projectByIdProvider = FutureProvider.autoDispose.family<Project, String>((ref, id) async {
  final api = await ref.watch(runnerApiProvider.future);
  return api.project(id);
});

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.role, required this.text});
  final String role;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = role == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 680),
        decoration: BoxDecoration(
          color: user ? scheme.surfaceContainerHighest : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: user
            ? SelectableText(text, style: const TextStyle(color: Colors.white))
            : MarkdownBody(
                data: text,
                selectable: true,
                onTapLink: (_, href, _) {
                  if (href != null) launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
                },
              ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.engine, required this.model, this.designName, this.quality = 'fast'});
  final String prompt;
  final String quality;
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
            [engine != null && engine!.isCli ? engine!.cliLabel : (model?.label ?? ''), if (engine != null && engine!.isCli && quality != 'fast' && quality != 'best') quality, if (designName != null) '🎨 $designName'].join(' · '),
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
      BuildPhase.generating: b.engine?.isCli == true
          ? [
              '${b.engine == BuildEngine.claudeCode ? l.stepClaudeCode : b.engine!.cliLabel} (${b.writtenFiles.length} file)',
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
    if (b.running) return ForgeView(builder: b, status: labels[current] ?? '');

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
                  if (builder.androidKind == 'aab' && !builder.playPromptDismissed) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.playAskUpload, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(l.playFeeNotice, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                FilledButton.icon(
                                  key: const Key('goPublishPlay'),
                                  onPressed: () => context.push(
                                    '/projects/$projectId/play',
                                    extra: [builder.prompt, ...builder.conversation.where((m) => m.role == 'user').skip(1).map((m) => m.text)].join('\n'),
                                  ),
                                  icon: const Icon(Icons.shop),
                                  label: Text(l.playYesUpload),
                                ),
                                TextButton(onPressed: builder.dismissPlayPrompt, child: Text(l.playNotNow)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    String? driveMessage;
    String? driveFolder;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setState) => AlertDialog(
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
              const SizedBox(height: 12),
              if (saving) Row(children: [const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Expanded(child: Text(l.driveSaving))]),
              if (driveMessage != null) SelectableText(driveMessage!),
              if (driveFolder != null)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(driveFolder!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: Text(l.driveOpenFolder),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: Text(l.close)),
            OutlinedButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() {
                        saving = true;
                        driveMessage = null;
                      });
                      try {
                        final res = await (await ref.read(runnerApiProvider.future)).backupSigningKey(projectId);
                        setState(() {
                          driveMessage = l.driveSaved;
                          driveFolder = res['folderUrl'] as String?;
                        });
                      } on RunnerException catch (e) {
                        setState(() => driveMessage = e.message);
                      } finally {
                        setState(() => saving = false);
                      }
                    },
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(l.driveBackup),
            ),
            FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse('$runnerUrl${info['path']}'), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.download),
              label: Text(l.downloadKeystore),
            ),
          ],
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.error.withValues(alpha: 0.6))),
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
          if (generating && tail.isNotEmpty && b.engine?.isCli != true)
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
