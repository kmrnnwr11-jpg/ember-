import 'dart:async';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../../widgets/connection_badge.dart';
import '../../widgets/ember_logo.dart';
import '../assistant/home_assistant.dart';
import '../create/app_builder.dart';
import '../create/create_app_screen.dart';
import '../create/creation_steps.dart';
import '../create/reference_app.dart';
import 'history_panel.dart';
import 'job_log_dialog.dart';
import 'restore_from_github.dart';

export 'job_log_dialog.dart';

/// The user's default workspace (created on first use).
final workspaceProvider = FutureProvider<Workspace>((ref) async {
  final api = await ref.watch(runnerApiProvider.future);
  final list = await api.workspaces();
  return list.isNotEmpty ? list.first : api.createWorkspace('default');
});

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final api = await ref.watch(runnerApiProvider.future);
  final ws = await ref.watch(workspaceProvider.future);
  final list = await api.projects(ws.id);
  return list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

enum _Menu { factory, emptyProject, restore }

/// Home: say what app you want. The apps already started are listed beside
/// the prompt box when there is room, under it when there is not.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  StreamSubscription<WsFrame>? _jobSub;

  @override
  void initState() {
    super.initState();
    // Refresh the list whenever a create job finishes.
    _jobSub = ref.read(runnerSocketProvider).eventsOf(MsgType.jobStatus).listen((f) {
      final s = JobStatus.fromJson(f.payload);
      if (s.kind == 'create' && s.isDone) ref.invalidate(projectsProvider);
    });
    _drafts = ref.read(draftsProvider.notifier);
    // A draft picked in the history of another screen, waiting to be opened here.
    final pending = ref.read(openDraftProvider);
    if (pending != null) {
      _draft = pending;
      Future.microtask(() => ref.read(openDraftProvider.notifier).set(null));
    }
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    if (_draftTimer?.isActive ?? false) _saveDraft();
    _draftTimer?.cancel();
    super.dispose();
  }

  /// What is being typed in the prompt box, saved as a draft until it is built.
  Draft _draft = Draft.blank();
  String? _draftText;
  Timer? _draftTimer;
  late final Drafts _drafts;

  void _saveDraft() {
    final text = _draftText;
    if (text != null) _drafts.put(_draft.id, text);
  }

  void _draftChanged(String text) {
    _draftText = text;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 700), _saveDraft);
  }

  void _openDraft(Draft draft) {
    if (_draftTimer?.isActive ?? false) _saveDraft();
    _draftTimer?.cancel();
    setState(() {
      _draft = draft;
      _draftText = null;
    });
  }

  bool _creating = false;
  bool _assistantOpen = false;

  void _toggleAssistant() {
    // Beside the page when there is room, full screen on a narrow window.
    if (Breakpoints.isMedium(context)) {
      setState(() => _assistantOpen = !_assistantOpen);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => Scaffold(body: SafeArea(child: HomeAssistantPanel(onClose: () => Navigator.of(ctx).pop()))),
    ));
  }

  /// Creates the Flutter project, then opens the app screen.
  Future<void> _createProject(String name, {CreateAppArgs? args}) async {
    final l = AppLocalizations.of(context);
    setState(() => _creating = true);
    try {
      final api = await ref.read(runnerApiProvider.future);
      final ws = await ref.read(workspaceProvider.future);
      final (project, job) = await api.createProject(ws.id, name);
      ref.invalidate(projectsProvider);
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => JobLogDialog(title: l.creatingProject(project.name), jobId: job.jobId),
      );
      ref.invalidate(projectsProvider);
      if (ok == true && mounted) context.go('/projects/${project.id}/create', extra: args);
    } on RunnerException catch (e) {
      if (mounted) showEmberSnack(context, l.error(e.message), error: true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _create() async {
    final name = await showDialog<String>(context: context, builder: (_) => const _NewProjectDialog());
    if (name == null || !mounted) return;
    await _createProject(name);
  }

  /// Describe → see 5 style mockups full screen → choose → build (§1B).
  Future<void> _createFromPrompt(String prompt, BuildEngine engine, AiModel? model, String quality, BuildEngine design) async {
    // Kept as a draft until the app is actually built: leaving the mockups
    // must not lose what was asked for.
    _draftTimer?.cancel();
    _drafts.put(_draft.id, prompt);
    // "Make an app like X": study X first — on the Play Store, or the website
    // itself when the link is a site — then design and build the same features.
    ReferenceApp? reference;
    ReferenceSite? site;
    final siteUrl = referenceSiteUrl(prompt);
    try {
      final api = await ref.read(runnerApiProvider.future);
      if (!mounted) return;
      if (siteUrl != null) {
        showEmberSnack(context, AppLocalizations.of(context).researchingApp(Uri.parse(siteUrl).host));
        site = ReferenceSite.fromJson(await api.readSite(siteUrl));
      } else {
        reference = await pickReferenceApp(context, api, prompt);
      }
    } catch (e) {
      if (mounted && siteUrl != null) showEmberSnack(context, AppLocalizations.of(context).error(e is RunnerException ? e.message : e.toString()), error: true);
    }
    if (!mounted) return;
    context.push(
      '/mockups',
      extra: CreateAppArgs(
        prompt: prompt,
        engine: engine,
        modelKey: model?.key,
        quality: quality,
        reference: reference?.brief() ?? site?.brief(),
        referenceId: reference?.id,
        referenceTopics: reference?.topics() ?? [for (final f in site?.features.take(20) ?? const <String>[]) f],
        styleBrief: reference?.visualDirection() ?? '',
        referenceSiteUrl: site?.url,
        designEngine: design,
      ),
    );
  }

  /// Opens an app saved on GitHub: the same apps from Windows and from a Mac.
  Future<void> _restoreFromGitHub() async {
    final ws = await ref.read(workspaceProvider.future);
    final here = {for (final p in ref.read(projectsProvider).value ?? const <Project>[]) p.name};
    if (!mounted) return;
    final project = await showDialog<Project>(
      context: context,
      builder: (_) => RestoreFromGitHubDialog(workspaceId: ws.id, alreadyHere: here),
    );
    ref.invalidate(projectsProvider);
    if (project != null && mounted) context.go('/projects/${project.id}/create');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    ref.listen(openDraftProvider, (_, draft) {
      if (draft == null) return;
      _openDraft(draft);
      Future.microtask(() => ref.read(openDraftProvider.notifier).set(null));
    });
    final historyBeside = Breakpoints.isExpanded(context);
    final assistantBeside = Breakpoints.isMedium(context) && _assistantOpen;

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const EmberLockup(size: 18, subtitle: false),
        actions: [
          const ConnectionBadge(hideWhenConnected: true),
          IconButton(
            key: const Key('toggleAssistant'),
            tooltip: l.assistantTitle,
            isSelected: assistantBeside,
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: const Icon(Icons.forum),
            onPressed: _toggleAssistant,
          ),
          IconButton(
            key: const Key('openSettings'),
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          PopupMenuButton<_Menu>(
            key: const Key('homeMenu'),
            tooltip: l.homeMenu,
            icon: const Icon(Icons.more_vert),
            onSelected: (m) => switch (m) {
              _Menu.factory => context.push('/factory'),
              _Menu.emptyProject => _create(),
              _Menu.restore => _restoreFromGitHub(),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                key: const Key('openFactory'),
                value: _Menu.factory,
                child: ListTile(leading: const Icon(Icons.factory_outlined), title: Text(l.fxTitle), contentPadding: EdgeInsets.zero),
              ),
              PopupMenuItem(
                key: const Key('newProject'),
                value: _Menu.emptyProject,
                child: ListTile(leading: const Icon(Icons.add_box_outlined), title: Text(l.emptyProject), contentPadding: EdgeInsets.zero),
              ),
              PopupMenuItem(
                key: const Key('restoreFromGitHub'),
                value: _Menu.restore,
                child: ListTile(leading: const Icon(Icons.cloud_download_outlined), title: Text(l.ghRestoreTitle), contentPadding: EdgeInsets.zero),
              ),
            ],
          ),
          Gap.hXs,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(projectsProvider.future),
        // A faint warm light behind the prompt box, so the page is not a flat sheet.
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.9),
              radius: 1.1,
              colors: [context.scheme.primary.withValues(alpha: 0.07), context.scheme.primary.withValues(alpha: 0)],
            ),
          ),
          child: PageBody(
          padding: EdgeInsets.fromLTRB(Gap.lg, historyBeside ? Gap.xxl * 2 : Gap.xl, Gap.lg, Gap.xxl),
          children: [
            Text(
              l.homeEyebrow.toUpperCase(),
              textAlign: TextAlign.center,
              style: context.text.labelMedium?.copyWith(color: context.scheme.primary, letterSpacing: 2, fontWeight: FontWeight.w700),
            ),
            Gap.vSm,
            Text(l.describeYourApp, style: (historyBeside ? context.text.headlineMedium : context.text.headlineSmall), textAlign: TextAlign.center),
            Gap.vSm,
            Text(l.describeYourAppHint, style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant), textAlign: TextAlign.center),
            Gap.vXl,
            // The whole way, in four steps: this screen is the first.
            const CreationSteps(current: 0),
            Gap.vXl,
            AppPromptComposer(
              key: ValueKey('composer_${_draft.id}'),
              initialPrompt: _draft.prompt,
              busy: _creating,
              onChanged: _draftChanged,
              onSubmit: _createFromPrompt,
            ),
            // No room for the side column: the same list, under the prompt box.
            if (!historyBeside) ...[
              Gap.vXl,
              Padding(
                padding: const EdgeInsetsDirectional.only(start: Gap.xs),
                child: Text(l.projects, style: context.text.titleMedium),
              ),
              Card(
                margin: const EdgeInsets.only(top: Gap.sm),
                clipBehavior: Clip.antiAlias,
                child: HistoryList(currentDraftId: _draft.id),
              ),
            ],
          ],
          ),
        ),
      ),
    );
    if (!assistantBeside && !historyBeside) return scaffold;
    return Row(
      children: [
        if (historyBeside) ...[
          SizedBox(width: historyPanelWidth, child: SafeArea(child: HistoryPanel(currentDraftId: _draft.id))),
          const VerticalDivider(width: 1),
        ],
        Expanded(child: scaffold),
        if (assistantBeside) ...[
          const VerticalDivider(width: 1),
          SizedBox(width: Widths.panel, child: SafeArea(child: HomeAssistantPanel(onClose: () => setState(() => _assistantOpen = false)))),
        ],
      ],
    );
  }
}

class _NewProjectDialog extends StatefulWidget {
  const _NewProjectDialog();

  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  static final _valid = RegExp(r'^[a-z][a-z0-9_]{0,63}$');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _ok() {
    if (_form.currentState!.validate()) Navigator.pop(context, _name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.newProject),
      content: Form(
        key: _form,
        child: TextFormField(
          key: const Key('projectName'),
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: l.projectName, helperText: l.projectNameHelp),
          validator: (v) => _valid.hasMatch(v?.trim() ?? '') ? null : l.projectNameHelp,
          onFieldSubmitted: (_) => _ok(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _ok, child: Text(l.create)),
      ],
    );
  }
}
