import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/locale.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/connection_badge.dart';
import '../../widgets/ember_logo.dart';
import '../assistant/home_assistant.dart';
import '../create/app_builder.dart';
import '../create/create_app_screen.dart';
import '../create/reference_app.dart';
import 'restore_from_github.dart';
import 'package:ai_connect/ai_connect.dart';

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
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    super.dispose();
  }

  bool _creating = false;
  bool _assistantOpen = true;

  void _openAssistantFullScreen() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => Scaffold(body: SafeArea(child: HomeAssistantPanel(onClose: () => Navigator.of(ctx).pop()))),
    ));
  }

  /// Creates the Flutter project, then opens the "describe your app" flow.
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
      if (mounted) _snack(l.error(e.message));
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
  Future<void> _createFromPrompt(String prompt, BuildEngine engine, AiModel? model, String quality) async {
    // "Make an app like X": study X first — on the Play Store, or the website
    // itself when the link is a site — then design and build the same features.
    ReferenceApp? reference;
    ReferenceSite? site;
    final siteUrl = referenceSiteUrl(prompt);
    try {
      final api = await ref.read(runnerApiProvider.future);
      if (!mounted) return;
      if (siteUrl != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).researchingApp(Uri.parse(siteUrl).host))));
        site = ReferenceSite.fromJson(await api.readSite(siteUrl));
      } else {
        reference = await pickReferenceApp(context, api, prompt);
      }
    } catch (e) {
      if (mounted && siteUrl != null) _snack(AppLocalizations.of(context).error(e is RunnerException ? e.message : e.toString()));
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

  Future<void> _delete(Project p) async {
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l.deleteConfirm(p.displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await (await ref.read(runnerApiProvider.future)).deleteProject(p.id);
    } on RunnerException catch (e) {
      if (mounted) _snack(l.error(e.message));
    }
    ref.invalidate(projectsProvider);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final projects = ref.watch(projectsProvider);

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const EmberLockup(size: 18, subtitle: false),
        actions: [
          const ConnectionBadge(),
          const LanguageButton(),
          Builder(
            builder: (context) => IconButton(
              key: const Key('toggleAssistant'),
              tooltip: l.assistantTitle,
              isSelected: _assistantOpen,
              icon: const EmberMark(size: 28, animate: false),
              onPressed: () => MediaQuery.of(context).size.width >= 1000
                  ? setState(() => _assistantOpen = !_assistantOpen)
                  : _openAssistantFullScreen(),
            ),
          ),
          IconButton(
            key: const Key('restoreFromGitHub'),
            tooltip: l.ghRestoreTitle,
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: _restoreFromGitHub,
          ),
          IconButton(
            tooltip: l.aiSettings,
            icon: const Icon(Icons.key),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            tooltip: l.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newProject'),
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(l.newProject),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(projectsProvider.future),
        child: projects.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(child: Text(l.error(e is RunnerException ? e.message : e.toString()), textAlign: TextAlign.center)),
              Center(child: TextButton(onPressed: () => ref.invalidate(workspaceProvider), child: Text(l.retry))),
            ],
          ),
          data: (list) => ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, i) => i == 0 ? const SizedBox.shrink() : const Divider(height: 1),
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Card(
                            margin: const EdgeInsets.all(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(l.describeYourApp, style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text(l.describeYourAppHint, style: Theme.of(context).textTheme.bodySmall),
                                  const SizedBox(height: 12),
                                  AppPromptComposer(busy: _creating, onSubmit: _createFromPrompt),
                                  const SizedBox(height: 16),
                                  if (list.isNotEmpty)
                                    Text(l.projects, style: Theme.of(context).textTheme.titleMedium)
                                  else
                                    Column(
                                      children: [
                                        const EmberMark(size: 72),
                                        const SizedBox(height: 6),
                                        Text(l.noProjects, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final p = list[index - 1];
                    final (label, icon) = switch (p.status) {
                      'ready' => (l.statusReady, Icons.folder_outlined),
                      'creating' => (l.statusCreating, Icons.hourglass_top),
                      _ => (l.statusError, Icons.error_outline),
                    };
                    return ListTile(
                      leading: Icon(icon),
                      title: Text(p.displayName),
                      subtitle: Text(label),
                      enabled: p.isReady,
                      onTap: p.isReady ? () => context.go('/projects/${p.id}/create') : null,
                      trailing: IconButton(
                        tooltip: l.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: p.status == 'creating' ? null : () => _delete(p),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 1000;
        if (!wide || !_assistantOpen) return scaffold;
        return Row(
          children: [
            Expanded(child: scaffold),
            const VerticalDivider(width: 1),
            SizedBox(width: (box.maxWidth * 0.3).clamp(340.0, 460.0), child: const HomeAssistantPanel()),
          ],
        );
      },
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

/// Streams a job's log; pops `true` on success, `false` on failure.
class JobLogDialog extends ConsumerStatefulWidget {
  const JobLogDialog({super.key, required this.title, required this.jobId});

  final String title;
  final String jobId;

  @override
  ConsumerState<JobLogDialog> createState() => _JobLogDialogState();
}

class _JobLogDialogState extends ConsumerState<JobLogDialog> {
  final _log = StringBuffer();
  final _scroll = ScrollController();
  final _subs = <StreamSubscription<WsFrame>>[];
  JobStatus? _status;

  @override
  void initState() {
    super.initState();
    final socket = ref.read(runnerSocketProvider);
    _subs
      ..add(socket.eventsOf(MsgType.jobLog).where((f) => f.payload['jobId'] == widget.jobId).listen((f) {
        setState(() => _log.write(f.payload['chunk'] as String? ?? ''));
        _scrollToEnd();
      }))
      ..add(socket.eventsOf(MsgType.jobStatus).where((f) => f.payload['jobId'] == widget.jobId).listen((f) {
        setState(() => _status = JobStatus.fromJson(f.payload));
      }));
    // Replay what was logged before we subscribed.
    ref.read(runnerApiProvider.future).then((api) => api.jobLog(widget.jobId)).then((prior) {
      if (!mounted || _log.isNotEmpty) return;
      setState(() => _log.write(prior));
      _scrollToEnd();
    }, onError: (_) {});
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  });

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final done = _status?.isDone ?? false;
    final ok = _status?.status == 'succeeded';
    return AlertDialog(
      title: Row(
        children: [
          if (!done) const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          if (done) Icon(ok ? Icons.check_circle : Icons.error, color: ok ? Colors.green : Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: SizedBox(
        width: 640,
        height: 320,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            controller: _scroll,
            child: SelectableText(
              _log.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70),
            ),
          ),
        ),
      ),
      actions: [
        if (done) FilledButton(onPressed: () => Navigator.pop(context, ok), child: Text(ok ? l.statusReady : l.cancel)),
      ],
    );
  }
}
