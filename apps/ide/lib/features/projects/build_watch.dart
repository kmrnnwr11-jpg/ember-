import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';

/// What a project in the list is doing right now.
///
/// A build lives on the Runner, not in the screen that started it, so it keeps
/// going while the user is somewhere else in Ember — or while Ember is shut.
/// The list is where that becomes visible: without it, an app being written
/// looks exactly like one finished an hour ago, and the only way to find out
/// was to open it and hope.
class BuildState {
  const BuildState({required this.building, this.files = 0, this.plannedFiles, this.needsYou = const []});

  /// A build is running for this project on the Runner right now.
  final bool building;

  /// Files written so far, and how many were planned when that is known.
  final int files;
  final int? plannedFiles;

  /// What the build is waiting on the user for: a login, a key, a paste.
  final List<String> needsYou;

  bool get waiting => needsYou.isNotEmpty;

  /// "3 di 32" while it is known, otherwise just the count.
  String get progress => plannedFiles != null && plannedFiles! > 0 ? '$files/$plannedFiles' : '$files';
}

/// The live state of every project, refreshed on its own.
///
/// One question for the whole list rather than one per project: with thirty
/// projects on screen the per-project version would be thirty round trips to
/// answer one.
class BuildWatch extends AsyncNotifier<Map<String, BuildState>> {
  Timer? _timer;

  @override
  Future<Map<String, BuildState>> build() async {
    _timer?.cancel();
    // Four seconds: fast enough that "finished" does not linger on screen,
    // slow enough to be free.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => refresh());
    ref.onDispose(() => _timer?.cancel());
    return _read();
  }

  Future<void> refresh() async {
    final next = await _read();
    if (!ref.mounted) return;
    state = AsyncData(next);
  }

  /// What we last knew, when the Runner cannot be reached.
  Map<String, BuildState> get stateOrEmpty =>
      state is AsyncData<Map<String, BuildState>> ? (state as AsyncData<Map<String, BuildState>>).value : const {};

  Future<Map<String, BuildState>> _read() async {
    final out = <String, BuildState>{};
    try {
      final socket = ref.read(runnerSocketProvider);
      final res = await socket.request(MsgType.agentRunning, const {});
      for (final r in (res['runs'] as List? ?? const [])) {
        final m = (r as Map).cast<String, dynamic>();
        final id = '${m['projectId'] ?? ''}';
        if (id.isEmpty) continue;
        out[id] = BuildState(
          building: true,
          files: (m['files'] as num?)?.toInt() ?? 0,
          plannedFiles: (m['plannedFiles'] as num?)?.toInt(),
        );
      }
    } catch (_) {
      // The Runner is unreachable for a moment: say nothing rather than
      // wrongly reporting every build as finished.
      return stateOrEmpty;
    }
    // What each project is waiting on the user for, saved with its session so
    // it survives Ember being closed.
    for (final id in out.keys.toList()) {
      out[id] = out[id]!.copyWithNeeds(await _needsYou(id));
    }
    return out;
  }

  Future<List<String>> _needsYou(String projectId) async {
    try {
      final raw = await Settings.instance.read('ember_session_$projectId');
      if (raw == null) return const [];
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return [for (final n in (m['needsYou'] as List? ?? const [])) '$n'];
    } catch (_) {
      return const [];
    }
  }
}

extension on BuildState {
  BuildState copyWithNeeds(List<String> needs) =>
      BuildState(building: building, files: files, plannedFiles: plannedFiles, needsYou: needs);
}

final buildWatchProvider =
    AsyncNotifierProvider<BuildWatch, Map<String, BuildState>>(BuildWatch.new);
