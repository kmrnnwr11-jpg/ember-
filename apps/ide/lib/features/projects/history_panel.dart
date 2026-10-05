import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../l10n/app_localizations.dart';
import 'build_watch.dart';
import 'projects_screen.dart';

/// Width of the history column, and the window width from which it sits
/// beside the page instead of in a drawer.
const historyPanelWidth = 260.0;
const historyBesideWidth = 1100.0;

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

/// Drafts and started apps, newest first and grouped by day, to move between
/// them without going back to the list.
class HistoryPanel extends ConsumerWidget {
  const HistoryPanel({super.key, this.currentProjectId, this.currentDraftId, this.inDrawer = false});

  final String? currentProjectId;
  final String? currentDraftId;

  /// Shown in a drawer (narrow window): close it before going anywhere.
  final bool inDrawer;

  void _openDraft(BuildContext context, WidgetRef ref, Draft draft) {
    if (inDrawer) Navigator.of(context).pop();
    ref.read(openDraftProvider.notifier).set(draft);
    context.go('/projects');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(text, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );

    final list = projects.value ?? const <Project>[];
    final rows = <Widget>[
      if (drafts.isNotEmpty) header(l.historyDrafts),
      for (final d in drafts)
        ListTile(
          key: Key('draft_${d.id}'),
          dense: true,
          leading: const Icon(Icons.edit_note, size: 20),
          title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          selected: currentProjectId == null && d.id == currentDraftId,
          onTap: () => _openDraft(context, ref, d),
          trailing: IconButton(
            tooltip: l.delete,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => ref.read(draftsProvider.notifier).remove(d.id),
          ),
        ),
    ];
    String? section;
    for (final p in list) {
      final g = group(p.createdAt);
      if (g != section) rows.add(header(section = g));
      final building = live[p.id]?.building ?? false;
      rows.add(ListTile(
        key: Key('history_${p.id}'),
        dense: true,
        leading: building
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(p.status == 'error' ? Icons.error_outline : Icons.chat_bubble_outline, size: 18),
        title: Text(p.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: p.id == currentProjectId,
        enabled: p.isReady || building,
        onTap: () {
          if (inDrawer) Navigator.of(context).pop();
          if (p.id != currentProjectId) context.go('/projects/${p.id}/create');
        },
      ));
    }

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: FilledButton.tonalIcon(
              key: const Key('historyNewApp'),
              onPressed: () => _openDraft(context, ref, Draft.blank()),
              icon: const Icon(Icons.add),
              label: Text(l.historyNewApp),
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: projects.isLoading
                        ? const Align(alignment: Alignment.topCenter, child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : Text(l.historyEmpty, style: theme.textTheme.bodySmall),
                  )
                : ListView(padding: const EdgeInsets.only(bottom: 12), children: rows),
          ),
        ],
      ),
    );
  }
}
