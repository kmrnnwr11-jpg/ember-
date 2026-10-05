import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'build_watch.dart';
import 'projects_screen.dart';

/// Width of the history column, and the window width from which it sits
/// beside the page instead of in a drawer.
const historyPanelWidth = Widths.rail;
const historyBesideWidth = Breakpoints.expanded;

/// A description typed on the home screen that has not become an app yet.
class Draft {
  const Draft({required this.id, required this.prompt, required this.updatedAt});

  /// An empty draft with a fresh id: what "New app" starts from.
  factory Draft.blank() => Draft(id: '${DateTime.now().microsecondsSinceEpoch}', prompt: '', updatedAt: DateTime.now());

  factory Draft.fromJson(Map<String, dynamic> j) => Draft(
    id: '${j['id']}',
    prompt: '${j['prompt'] ?? ''}',
    updatedAt: DateTime.tryParse('${j['updatedAt']}') ?? DateTime.now(),
  );

  final String id;
  final String prompt;
  final DateTime updatedAt;

  /// First line of the description, as the row in the history shows it.
  String get title => prompt.trim().split('\n').first.trim();

  Map<String, dynamic> toJson() => {'id': id, 'prompt': prompt, 'updatedAt': updatedAt.toIso8601String()};
}

/// Drafts, newest first, kept on the Runner with the rest of the settings.
///
/// A description sent to the mockups and then abandoned was simply gone: the
/// project is only created once a design is chosen, so nothing remembered what
/// had been asked for.
class Drafts extends AsyncNotifier<List<Draft>> {
  static const _key = 'ember_drafts';
  static const _max = 30;

  @override
  Future<List<Draft>> build() async {
    // Settings live on the Runner of the signed-in user.
    await ref.watch(runnerApiProvider.future);
    try {
      final raw = await Settings.instance.read(_key);
      if (raw == null) return [];
      return [for (final d in jsonDecode(raw) as List) Draft.fromJson((d as Map).cast<String, dynamic>())]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  Future<List<Draft>> _current() async {
    try {
      return await future;
    } catch (_) {
      return [];
    }
  }

  Future<void> _set(List<Draft> list) async {
    state = AsyncData(list);
    try {
      await Settings.instance.write(_key, jsonEncode([for (final d in list) d.toJson()]));
    } catch (_) {}
  }

  /// Saves the text under this id; an emptied draft is removed.
  Future<void> put(String id, String prompt) async {
    final rest = (await _current()).where((d) => d.id != id);
    if (prompt.trim().isEmpty) return _set(rest.toList());
    await _set([Draft(id: id, prompt: prompt, updatedAt: DateTime.now()), ...rest].take(_max).toList());
  }

  Future<void> remove(String id) async => _set((await _current()).where((d) => d.id != id).toList());

  /// The draft has become an app: it is in the history as a project now.
  Future<void> removeByPrompt(String prompt) async {
    final list = await _current();
    final rest = list.where((d) => d.prompt.trim() != prompt.trim()).toList();
    if (rest.length != list.length) await _set(rest);
  }
}

final draftsProvider = AsyncNotifierProvider<Drafts, List<Draft>>(Drafts.new);

/// The draft the home screen should load into its prompt box, set by the
/// history from whichever screen it is shown on.
class OpenDraft extends Notifier<Draft?> {
  @override
  Draft? build() => null;

  void set(Draft? draft) => state = draft;
}

final openDraftProvider = NotifierProvider<OpenDraft, Draft?>(OpenDraft.new);

/// Drafts and started apps, newest first and grouped by day. The one list of
/// the user's apps: in the side column when there is room, under the prompt
/// box on the home screen when there is not.
class HistoryList extends ConsumerWidget {
  const HistoryList({super.key, this.currentProjectId, this.currentDraftId, this.onNavigate});

  final String? currentProjectId;
  final String? currentDraftId;

  /// Called before going anywhere (a drawer closes itself here).
  final VoidCallback? onNavigate;

  void _openDraft(BuildContext context, WidgetRef ref, Draft draft) {
    onNavigate?.call();
    ref.read(openDraftProvider.notifier).set(draft);
    context.go('/projects');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Project p) async {
    final l = AppLocalizations.of(context);
    if (!await showConfirm(context, title: l.deleteConfirm(p.displayName), confirmLabel: l.delete, destructive: true)) return;
    try {
      await (await ref.read(runnerApiProvider.future)).deleteProject(p.id);
    } on RunnerException catch (e) {
      if (context.mounted) showEmberSnack(context, l.error(e.message), error: true);
    }
    ref.invalidate(projectsProvider);
    // The app on screen is gone: back to the list.
    if (p.id == currentProjectId && context.mounted) context.go('/projects');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final drafts = ref.watch(draftsProvider).value ?? const <Draft>[];
    final projects = ref.watch(projectsProvider);
    final watch = ref.watch(buildWatchProvider);
    final live = watch is AsyncData<Map<String, BuildState>> ? watch.value : const <String, BuildState>{};

    final today = DateUtils.dateOnly(DateTime.now());
    String group(DateTime at) {
      final days = today.difference(DateUtils.dateOnly(at.toLocal())).inDays;
      if (days <= 0) return l.historyToday;
      if (days == 1) return l.historyYesterday;
      return days <= 7 ? l.historyLast7Days : l.historyOlder;
    }

    Widget header(String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Gap.lg, Gap.lg, Gap.lg, Gap.xs),
      child: Text(text, style: context.text.labelMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
    );

    final list = projects.value ?? const <Project>[];
    final rows = <Widget>[
      if (drafts.isNotEmpty) header(l.historyDrafts),
      for (final d in drafts)
        ListTile(
          key: Key('draft_${d.id}'),
          dense: true,
          leading: const Icon(Icons.edit_note_outlined, size: 20),
          title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          selected: currentProjectId == null && d.id == currentDraftId,
          onTap: () => _openDraft(context, ref, d),
          trailing: IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => ref.read(draftsProvider.notifier).remove(d.id),
          ),
        ),
    ];
    String? section;
    for (final p in list) {
      final g = group(p.createdAt);
      if (g != section) rows.add(header(section = g));
      // What the Runner says this project is doing right now: a build carries
      // on there while the user is elsewhere, so the list is where it shows.
      final state = live[p.id];
      final building = state?.building ?? false;
      final waiting = state?.waiting ?? false;
      rows.add(ListTile(
        key: Key('history_${p.id}'),
        dense: true,
        leading: building
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(
                switch (p.status) { 'ready' => Icons.apps_outlined, 'creating' => Icons.hourglass_top_outlined, _ => Icons.error_outline },
                size: 18,
              ),
        title: Text(p.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: building
            ? Text(l.statusBuilding(state!.progress), maxLines: 1, overflow: TextOverflow.ellipsis)
            : p.status == 'ready'
                ? null
                : Text(p.status == 'creating' ? l.statusCreating : l.statusError),
        selected: p.id == currentProjectId,
        // A project being written opens like any other: the app screen shows
        // how far it has got.
        enabled: p.isReady || building,
        onTap: () {
          onNavigate?.call();
          if (p.id != currentProjectId) context.go('/projects/${p.id}/create');
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A build waiting on a login or a key cannot move until the user
            // comes back, and would otherwise look exactly like one that is working.
            if (waiting)
              Tooltip(
                message: state!.needsYou.join(', '),
                child: Icon(Icons.warning_amber_outlined, color: context.ember.warning, size: 18),
              ),
            IconButton(
              key: Key('delete_${p.id}'),
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline, size: 18),
              // Deleting a project mid-build would pull the files out from
              // under the engine writing them.
              onPressed: (p.status == 'creating' || building) ? null : () => _delete(context, ref, p),
            ),
          ],
        ),
      ));
    }

    if (rows.isEmpty) {
      if (projects.isLoading) return const Padding(padding: EdgeInsets.all(Gap.xl), child: LoadingState());
      if (projects.hasError) {
        final e = projects.error;
        return ErrorState(message: l.error(e is RunnerException ? e.message : '$e'), onRetry: () => ref.invalidate(workspaceProvider));
      }
      return EmptyState(text: l.historyEmpty, compact: true);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

/// The history as a column of its own: "New app" on top, the list under it.
class HistoryPanel extends ConsumerWidget {
  const HistoryPanel({super.key, this.currentProjectId, this.currentDraftId, this.inDrawer = false});

  final String? currentProjectId;
  final String? currentDraftId;

  /// Shown in a drawer (narrow window): close it before going anywhere.
  final bool inDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    void leave() {
      if (inDrawer) Navigator.of(context).pop();
    }

    return Material(
      color: context.scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.xs),
            child: FilledButton.tonalIcon(
              key: const Key('historyNewApp'),
              onPressed: () {
                leave();
                ref.read(openDraftProvider.notifier).set(Draft.blank());
                context.go('/projects');
              },
              icon: const Icon(Icons.add),
              label: Text(l.historyNewApp),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: HistoryList(currentProjectId: currentProjectId, currentDraftId: currentDraftId, onNavigate: leave),
            ),
          ),
        ],
      ),
    );
  }
}
