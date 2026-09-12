import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ide_core/ide_core.dart';
import 'package:re_editor/re_editor.dart';

/// Minimal request surface of the Runner socket, so the controller is testable.
typedef RunnerRequest = Future<Map<String, dynamic>> Function(String type, Map<String, dynamic> payload);

class OpenFile {
  OpenFile({required this.path, required String content, required this.mtimeMs})
    : savedText = content,
      controller = CodeLineEditingController.fromText(content);

  final String path;
  final CodeLineEditingController controller;
  String savedText;
  double mtimeMs;
  bool saving = false;

  bool get dirty => controller.text != savedText;
  String get name => ProjectPath.basename(path);
}

class SaveConflict implements Exception {
  const SaveConflict(this.path);
  final String path;
}

/// State of one open project: lazily-loaded file tree + open editor tabs.
class ProjectController extends ChangeNotifier {
  ProjectController({required this.projectId, required RunnerRequest request, Stream<WsFrame>? events})
    : _request = request {
    _eventsSub = events?.where((f) => f.type == MsgType.fsChanged).listen(_onFsChanged);
  }

  final String projectId;
  final RunnerRequest _request;
  StreamSubscription<WsFrame>? _eventsSub;

  /// Directory path ('' = root) → children. Missing key = not loaded.
  final Map<String, List<FsEntry>> children = {};
  final Set<String> expanded = {''};
  final List<OpenFile> tabs = [];
  int active = -1;
  Object? error;

  OpenFile? get activeFile => active >= 0 && active < tabs.length ? tabs[active] : null;

  Future<Map<String, dynamic>> _call(String type, Map<String, dynamic> payload) =>
      _request(type, {'projectId': projectId, ...payload});

  Future<void> loadDir(String dir) async {
    try {
      final res = await _call(MsgType.fsList, {'path': dir});
      children[dir] = [for (final e in res['entries'] as List) FsEntry.fromJson(e as Map<String, dynamic>)];
      error = null;
    } catch (e) {
      error = e;
    }
    notifyListeners();
  }

  Future<void> toggleDir(String dir) async {
    if (expanded.remove(dir)) {
      notifyListeners();
      return;
    }
    expanded.add(dir);
    notifyListeners();
    if (!children.containsKey(dir)) await loadDir(dir);
  }

  Future<void> open(String path) async {
    final existing = tabs.indexWhere((t) => t.path == path);
    if (existing >= 0) {
      active = existing;
      notifyListeners();
      return;
    }
    final res = await _call(MsgType.fsRead, {'path': path});
    final file = OpenFile(
      path: path,
      content: res['content'] as String,
      mtimeMs: (res['mtimeMs'] as num).toDouble(),
    );
    file.controller.addListener(notifyListeners);
    tabs.add(file);
    active = tabs.length - 1;
    notifyListeners();
  }

  void activate(int index) {
    active = index;
    notifyListeners();
  }

  void close(int index) {
    final f = tabs.removeAt(index);
    f.controller.removeListener(notifyListeners);
    f.controller.dispose();
    if (active >= tabs.length) active = tabs.length - 1;
    notifyListeners();
  }

  /// Saves [file]. Throws [SaveConflict] if it changed on disk, unless [force].
  Future<void> save(OpenFile file, {bool force = false}) async {
    if (file.saving) return;
    file.saving = true;
    notifyListeners();
    final text = file.controller.text;
    try {
      final res = await _call(MsgType.fsWrite, {
        'path': file.path,
        'content': text,
        if (!force) 'expectedMtimeMs': file.mtimeMs,
      });
      file
        ..savedText = text
        ..mtimeMs = (res['mtimeMs'] as num).toDouble();
    } on RunnerException catch (e) {
      if (e.code == 'conflict') throw SaveConflict(file.path);
      rethrow;
    } finally {
      file.saving = false;
      notifyListeners();
    }
  }

  Future<void> reload(OpenFile file) async {
    final res = await _call(MsgType.fsRead, {'path': file.path});
    final content = res['content'] as String;
    file
      ..savedText = content
      ..mtimeMs = (res['mtimeMs'] as num).toDouble()
      ..controller.text = content;
    notifyListeners();
  }

  Future<void> createFile(String dir, String name) async {
    final path = ProjectPath.join(dir, name);
    await _call(MsgType.fsWrite, {'path': path, 'content': ''});
    await loadDir(dir);
    await open(path);
  }

  Future<void> createFolder(String dir, String name) async {
    await _call(MsgType.fsMkdir, {'path': ProjectPath.join(dir, name)});
    await loadDir(dir);
  }

  Future<void> rename(FsEntry entry, String newName) async {
    final dir = ProjectPath.dirname(entry.path);
    final to = ProjectPath.join(dir, newName);
    await _call(MsgType.fsRename, {'from': entry.path, 'to': to});
    for (final t in tabs.where((t) => t.path == entry.path || t.path.startsWith('${entry.path}/')).toList()) {
      final i = tabs.indexOf(t);
      final moved = OpenFile(path: to + t.path.substring(entry.path.length), content: t.controller.text, mtimeMs: t.mtimeMs)
        ..savedText = t.savedText;
      moved.controller.addListener(notifyListeners);
      t.controller
        ..removeListener(notifyListeners)
        ..dispose();
      tabs[i] = moved;
    }
    children.removeWhere((k, _) => k == entry.path || k.startsWith('${entry.path}/'));
    await loadDir(dir);
  }

  Future<void> delete(FsEntry entry) async {
    await _call(MsgType.fsDelete, {'path': entry.path});
    for (var i = tabs.length - 1; i >= 0; i--) {
      if (tabs[i].path == entry.path || tabs[i].path.startsWith('${entry.path}/')) close(i);
    }
    children.removeWhere((k, _) => k == entry.path || k.startsWith('${entry.path}/'));
    await loadDir(ProjectPath.dirname(entry.path));
  }

  void _onFsChanged(WsFrame f) {
    if (f.payload['projectId'] != projectId) return;
    final path = f.payload['path'] as String;
    final event = f.payload['event'] as String;
    final dir = ProjectPath.dirname(path);
    if (event != 'change' && children.containsKey(dir)) unawaited(loadDir(dir));
    if (event == 'change') {
      final open = tabs.where((t) => t.path == path && !t.dirty && !t.saving);
      for (final t in open) {
        unawaited(_call(MsgType.fsRead, {'path': path}).then((res) {
          final mtime = (res['mtimeMs'] as num).toDouble();
          if (mtime == t.mtimeMs || t.dirty) return;
          final content = res['content'] as String;
          t
            ..savedText = content
            ..mtimeMs = mtime
            ..controller.text = content;
          notifyListeners();
        }, onError: (_) {}));
      }
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    for (final t in tabs) {
      t.controller.removeListener(notifyListeners);
      t.controller.dispose();
    }
    super.dispose();
  }
}
