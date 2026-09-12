import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ide_core/ide_core.dart';

import '../editor/project_controller.dart' show RunnerRequest;

enum PreviewPhase { idle, building, ready, failed }

class ConsoleLine {
  const ConsoleLine(this.level, this.message, this.at);
  final String level;
  final String message;
  final DateTime at;
}

/// Web build + preview state of a project (§2).
class PreviewController extends ChangeNotifier {
  PreviewController({
    required this.projectId,
    required this.runnerUrl,
    required RunnerRequest request,
    required Stream<WsFrame> events,
  }) : _request = request {
    _sub = events.listen(_onEvent);
  }

  final String projectId;
  final String runnerUrl;
  final RunnerRequest _request;
  late final StreamSubscription<WsFrame> _sub;

  PreviewInfo? info;
  PreviewPhase phase = PreviewPhase.idle;
  String? jobId;
  final StringBuffer buildLog = StringBuffer();
  final List<ConsoleLine> console = [];
  Object? error;

  /// Incremented on every successful build so the WebView reloads.
  int revision = 0;

  String? get url => info?.built == true ? info!.resolve(runnerUrl) : null;

  Future<void> refreshStatus() async {
    try {
      info = PreviewInfo.fromJson(await _request(MsgType.previewStatus, {'projectId': projectId}));
      if (info!.building) {
        phase = PreviewPhase.building;
      } else if (info!.built && phase == PreviewPhase.idle) {
        phase = PreviewPhase.ready;
      }
    } catch (e) {
      error = e;
    }
    notifyListeners();
  }

  /// Builds the web app; with [autoRebuild] the Runner rebuilds on every save.
  Future<void> run({bool autoRebuild = true}) async {
    error = null;
    phase = PreviewPhase.building;
    buildLog.clear();
    notifyListeners();
    try {
      final res = await _request(MsgType.previewStart, {'projectId': projectId, 'autoRebuild': autoRebuild});
      jobId = (res['job'] as Map<String, dynamic>)['jobId'] as String;
      info = PreviewInfo.fromJson(res['preview'] as Map<String, dynamic>);
    } catch (e) {
      error = e;
      phase = PreviewPhase.failed;
    }
    notifyListeners();
  }

  Future<void> stopAutoRebuild() async {
    await _request(MsgType.previewStop, {'projectId': projectId});
    await refreshStatus();
  }

  void addConsole(String level, String message) {
    console.add(ConsoleLine(level, message, DateTime.now()));
    if (console.length > 500) console.removeRange(0, console.length - 500);
    notifyListeners();
  }

  void clearConsole() {
    console.clear();
    notifyListeners();
  }

  void _onEvent(WsFrame f) {
    final p = f.payload;
    switch (f.type) {
      case MsgType.previewBuilding when p['projectId'] == projectId:
        jobId = p['jobId'] as String;
        buildLog.clear();
        phase = PreviewPhase.building;
        notifyListeners();
      case MsgType.previewReady when p['projectId'] == projectId:
        info = PreviewInfo.fromJson(p);
        phase = PreviewPhase.ready;
        revision++;
        console.clear();
        notifyListeners();
      case MsgType.previewFailed when p['projectId'] == projectId:
        phase = PreviewPhase.failed;
        notifyListeners();
      case MsgType.jobLog when p['jobId'] == jobId:
        buildLog.write(p['chunk'] as String? ?? '');
        notifyListeners();
      default:
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
