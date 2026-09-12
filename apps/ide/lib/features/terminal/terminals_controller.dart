import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ide_core/ide_core.dart';
import 'package:xterm/xterm.dart';

import '../editor/project_controller.dart' show RunnerRequest;

class TerminalSession {
  TerminalSession(this.title) : terminal = Terminal(maxLines: 10000);

  final String title;
  final Terminal terminal;
  String? ptyId;
  bool exited = false;

  /// Sticky Ctrl from the mobile key bar: applies to the next typed letter.
  bool ctrlArmed = false;
}

/// Terminal tabs of a project, each backed by a Runner PTY (§1.11).
class TerminalsController extends ChangeNotifier {
  TerminalsController({
    required this.projectId,
    required RunnerRequest request,
    required Stream<WsFrame> events,
    ValueListenable<bool>? connected,
  }) : _request = request {
    _sub = events.listen(_onEvent);
    _connected = connected;
    connected?.addListener(_onConnectionChange);
  }

  final String projectId;
  final RunnerRequest _request;
  late final StreamSubscription<WsFrame> _sub;
  ValueListenable<bool>? _connected;

  final List<TerminalSession> sessions = [];
  int active = -1;
  int _counter = 0;

  TerminalSession? get activeSession => active >= 0 && active < sessions.length ? sessions[active] : null;

  Future<TerminalSession> open() async {
    final s = TerminalSession('${++_counter}');
    sessions.add(s);
    active = sessions.length - 1;
    notifyListeners();
    await _attach(s);
    return s;
  }

  Future<void> _attach(TerminalSession s) async {
    final t = s.terminal;
    try {
      final res = await _request(MsgType.ptyOpen, {
        'projectId': projectId,
        'cols': t.viewWidth,
        'rows': t.viewHeight,
      });
      s
        ..ptyId = res['ptyId'] as String
        ..exited = false;
      t.onOutput = (data) => _input(s, data);
      t.onResize = (w, h, _, _) {
        final id = s.ptyId;
        if (id != null && !s.exited) {
          _request(MsgType.ptyResize, {'ptyId': id, 'cols': w, 'rows': h}).ignore();
        }
      };
    } on RunnerException catch (e) {
      s.exited = true;
      t.write('\r\n\x1b[31m[${e.message}]\x1b[0m\r\n');
    }
    notifyListeners();
  }

  void _input(TerminalSession s, String data) {
    final id = s.ptyId;
    if (id == null || s.exited) return;
    var out = data;
    if (s.ctrlArmed && data.length == 1) {
      final c = data.toLowerCase().codeUnitAt(0);
      if (c >= 0x61 && c <= 0x7a) out = String.fromCharCode(c - 0x60);
      s.ctrlArmed = false;
      notifyListeners();
    }
    _request(MsgType.ptyInput, {'ptyId': id, 'data': out}).ignore();
  }

  /// Sends raw bytes (mobile key bar).
  void send(String data) {
    final s = activeSession;
    if (s != null) _input(s, data);
  }

  void toggleCtrl() {
    final s = activeSession;
    if (s == null) return;
    s.ctrlArmed = !s.ctrlArmed;
    notifyListeners();
  }

  void activate(int i) {
    active = i;
    notifyListeners();
  }

  Future<void> close(int i) async {
    final s = sessions.removeAt(i);
    if (active >= sessions.length) active = sessions.length - 1;
    notifyListeners();
    final id = s.ptyId;
    if (id != null && !s.exited) await _request(MsgType.ptyClose, {'ptyId': id}).catchError((_) => <String, dynamic>{});
  }

  /// Restarts an exited session in place.
  Future<void> restart(TerminalSession s) async {
    s.terminal.write('\r\n');
    await _attach(s);
  }

  void _onEvent(WsFrame f) {
    if (f.type != MsgType.ptyOutput && f.type != MsgType.ptyExit) return;
    final id = f.payload['ptyId'];
    for (final s in sessions) {
      if (s.ptyId != id) continue;
      if (f.type == MsgType.ptyOutput) {
        s.terminal.write(f.payload['data'] as String);
      } else {
        s.exited = true;
        s.terminal.write('\r\n\x1b[90m[process exited with code ${f.payload['exitCode']}]\x1b[0m\r\n');
        notifyListeners();
      }
    }
  }

  void _onConnectionChange() {
    if (_connected?.value ?? true) return;
    // PTYs are tied to the socket: they are gone after a disconnect.
    for (final s in sessions.where((s) => !s.exited)) {
      s.exited = true;
      s.terminal.write('\r\n\x1b[33m[connection lost — tap restart]\x1b[0m\r\n');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    _connected?.removeListener(_onConnectionChange);
    for (final s in sessions) {
      final id = s.ptyId;
      if (id != null && !s.exited) _request(MsgType.ptyClose, {'ptyId': id}).ignore();
    }
    super.dispose();
  }
}
