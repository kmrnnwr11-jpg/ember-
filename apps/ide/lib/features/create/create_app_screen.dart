import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../ai/ai_settings.dart';
import '../assistant/home_assistant.dart';
import '../projects/history_panel.dart';
import '../review/design_council.dart';
import '../review/panel_health.dart';
import '../review/review_state.dart';
import 'app_builder.dart';
import 'app_section_screen.dart';
import 'app_session.dart';
import 'checkup_card.dart';
import 'hub/hub_widgets.dart';
import 'needs_you_card.dart';

export 'app_session.dart';
export 'engines.dart';
export 'prompt_composer.dart';

/// The home of one app: how the build is going, the app once it is ready,
/// where to go next, and the conversation with Ember. Everything else
/// (phone, pictures, stores, checks) is one row away.
class CreateAppScreen extends ConsumerStatefulWidget {
  const CreateAppScreen({super.key, required this.projectId, this.args});

  final String projectId;
  final CreateAppArgs? args;

  @override
  ConsumerState<CreateAppScreen> createState() => _CreateAppScreenState();
}

class _CreateAppScreenState extends ConsumerState<CreateAppScreen> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _change = TextEditingController();
  final _logScroll = ScrollController();
  bool _autoStarted = false;
  bool _showLog = false;
  bool _showAssistant = false;

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
    // Nothing is written until every model has answered, or the user has said
    // in so many words to go on without one.
    if (!mounted) return;
    final health = await checkPanel(context, ref);
    if (!health.proceed) {
      // Stopping here goes back to the list; the app is not closed.
      if (mounted) context.go('/projects');
      return;
    }
    // The panel says how the app should be designed before a line of it is
    // written. Reviewing at the end only ever caught what a rebuild could
    // fix; agreeing first is what stops it being built wrong.
    final agreed = await designCouncil(
      health.members,
      request: args.prompt,
      reference: args.reference ?? '',
      onProgress: (s) => b.note(s),
    );
    // The draft is an app now: the history lists it as one.
    if (mounted) ref.read(draftsProvider.notifier).removeByPrompt(args.prompt);
    b.build(
      prompt: args.prompt,
      engine: args.engine,
      model: model,
      quality: args.quality,
      design: '${args.design ?? ''}$agreed',
      designName: args.designName,
      referenceId: args.referenceId,
      referenceTopics: args.referenceTopics,
      appName: args.appName,
      referenceSiteUrl: args.referenceSiteUrl,
      designEngine: args.designEngine,
    );
  }

  void _send(AppBuilder b) {
    final text = _change.text.trim();
    if (text.isEmpty) return;
    _change.clear();
    b.improve(text);
  }

  void _toggleAssistant() {
    // Beside the app when there is room, over it on a narrow window.
    if (Breakpoints.isMedium(context)) {
      setState(() => _showAssistant = !_showAssistant);
    } else {
      _scaffold.currentState?.openEndDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final projectAsync = ref.watch(projectByIdProvider(widget.projectId));
    return projectAsync.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (e, _) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/projects'))),
        body: ErrorState(message: l.error(e is RunnerException ? e.message : e.toString()), onRetry: () => ref.invalidate(projectByIdProvider(widget.projectId))),
      ),
      data: (project) {
        final b = ref.watch(appBuilderProvider((project.id, project.name)));
        WidgetsBinding.instance.addPostFrameCallback((_) => _autoStart(b));
        final historyBeside = Breakpoints.isExpanded(context);
        final assistantBeside = Breakpoints.isMedium(context);
        HomeAssistantPanel assistant(VoidCallback onClose) => HomeAssistantPanel(
          app: (id: project.id, name: project.displayName),
          onClose: onClose,
          fixing: b.running,
          onFixApp: (request) => b.improve(request),
        );
        return Scaffold(
          key: _scaffold,
          drawer: historyBeside ? null : Drawer(width: 300, child: SafeArea(child: HistoryPanel(currentProjectId: project.id, inDrawer: true))),
          // On a narrow window the assistant takes the whole screen instead of squeezing the app.
          endDrawer: assistantBeside ? null : Drawer(width: Widths.panel, child: SafeArea(child: assistant(() => Navigator.pop(context)))),
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.go('/projects')),
            title: Text(project.displayName),
            actions: [
              if (!historyBeside)
                IconButton(
                  key: const Key('openHistory'),
                  tooltip: l.historyTitle,
                  icon: const Icon(Icons.history),
                  onPressed: () => _scaffold.currentState?.openDrawer(),
                ),
              IconButton(
                key: const Key('toggleAssistant'),
                tooltip: l.acAssistant,
                isSelected: _showAssistant && assistantBeside,
                icon: const Icon(Icons.forum_outlined),
                selectedIcon: const Icon(Icons.forum),
                onPressed: _toggleAssistant,
              ),
              Gap.hSm,
            ],
          ),
          body: Row(
            children: [
              if (historyBeside) ...[
                SizedBox(width: historyPanelWidth, child: HistoryPanel(currentProjectId: project.id)),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: ListenableBuilder(listenable: b, builder: (context, _) => _body(context, l, b, project))),
              if (_showAssistant && assistantBeside) ...[
                const VerticalDivider(width: 1),
                SizedBox(width: Widths.panel, child: assistant(() => setState(() => _showAssistant = false))),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, AppBuilder b, Project project) {
    if (b.phase == BuildPhase.idle) return const LoadingState();
    final ready = b.phase == BuildPhase.ready;
    final failed = b.phase == BuildPhase.failed || b.phase == BuildPhase.cancelled;
    final findings = ref.watch(reviewStatesProvider.notifier).of(project.id).findings.length;
    void open(AppSection s) => context.push('/projects/${project.id}/${s.path}');

    return Column(
      children: [
        Expanded(
          child: PageBody(
            children: [
              // Right at the top: what only the owner can do blocks the
              // rest, so it must not be scrolled to.
              NeedsYouCard(builder: b),
              Gap.vMd,
              PromptCard(prompt: b.prompt, engine: b.engine, model: b.model, designName: b.designName, quality: b.quality),
              Gap.vMd,
              AnimatedSwitcher(
                duration: Motion.of(context),
                switchInCurve: Motion.curve,
                child: KeyedSubtree(
                  key: ValueKey(b.running ? 'running' : b.phase.name),
                  child: b.running
                      ? BuildProgress(builder: b)
                      : ready
                          ? ReadyHero(builder: b, projectId: project.id)
                          : failed
                              ? FailedCard(builder: b, projectId: project.id)
                              : const SizedBox.shrink(),
                ),
              ),
              // Shows itself only when the automatic check found something.
              if (ready)
                CheckupCard(
                  projectId: project.id,
                  builder: b,
                  previewUrl: b.preview?.resolve(ref.read(sessionProvider).value?.runnerUrl ?? ''),
                  onlyProblems: true,
                ),
              if (ready) ...[
                Gap.vXl,
                NextSteps(
                  steps: [
                    NextStep(key: 'test', icon: Icons.phone_android_outlined, title: l.hubTest, hint: l.hubTestHint, onTap: () => open(AppSection.test)),
                    NextStep(key: 'images', icon: Icons.image_outlined, title: l.hubImages, hint: l.hubImagesHint, onTap: () => open(AppSection.images)),
                    NextStep(
                      key: 'checks',
                      icon: Icons.fact_check_outlined,
                      title: l.hubChecks,
                      hint: l.hubChecksHint,
                      status: findings == 0 ? null : Pill(l.hubChecksCount(findings), tone: Tone.attention),
                      onTap: () => open(AppSection.checks),
                    ),
                    NextStep(key: 'play', icon: Icons.shop_outlined, title: l.hubPlay, hint: l.hubPlayHint, onTap: () => open(AppSection.googlePlay)),
                    NextStep(key: 'appStore', icon: Icons.phone_iphone_outlined, title: l.hubAppStore, hint: l.hubAppStoreHint, onTap: () => open(AppSection.appStore)),
                    NextStep(key: 'more', icon: Icons.more_horiz, title: l.hubMore, hint: l.hubMoreHint, onTap: () => open(AppSection.more)),
                  ],
                ),
              ] else if (findings > 0) ...[
                // A fix is running: the list being worked through stays one tap away.
                Gap.vMd,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(onPressed: () => open(AppSection.checks), icon: const Icon(Icons.fact_check_outlined), label: Text('${l.hubChecks} · ${l.hubChecksCount(findings)}')),
                ),
              ],
              if (b.conversation.length > 1) ...[
                Gap.vXl,
                for (final msg in b.conversation.skip(1)) AppChatBubble(role: msg.role, text: msg.text),
              ],
              if (b.running && b.conversation.length > 1 && b.conversation.last.role == 'user')
                const Padding(
                  padding: EdgeInsets.all(Gap.sm),
                  child: Align(alignment: AlignmentDirectional.centerStart, child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
              Gap.vLg,
              InkWell(
                key: const Key('toggleLog'),
                borderRadius: Radii.smAll,
                onTap: () => setState(() => _showLog = !_showLog),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: kTapTarget),
                  child: Row(
                    children: [
                      Gap.hXs,
                      Icon(_showLog ? Icons.expand_less : Icons.expand_more, size: 20, color: context.scheme.onSurfaceVariant),
                      Gap.hSm,
                      Expanded(child: Text(l.techDetails, style: context.text.labelLarge?.copyWith(color: context.scheme.onSurfaceVariant))),
                      if (b.costUsd > 0) Text('≈\$${b.costUsd.toStringAsFixed(3)}', style: context.text.bodySmall),
                      Gap.hXs,
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: Motion.of(context),
                curve: Motion.curve,
                alignment: Alignment.topCenter,
                child: _showLog ? BuildLogView(builder: b, scroll: _logScroll) : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
        // Always in reach: the next change is typed here, not at the end of the page.
        if (ready || failed)
          Material(
            color: context.scheme.surfaceContainerLow,
            child: SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Widths.page),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
                    child: ChatComposer(
                      controller: _change,
                      hint: l.changeHint,
                      sendTooltip: l.send,
                      fieldKey: const Key('nextRequest'),
                      sendKey: const Key('sendRequest'),
                      onSend: () => _send(b),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
