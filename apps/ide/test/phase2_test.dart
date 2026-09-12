import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/preview/preview_controller.dart';
import 'package:ide/features/terminal/terminals_controller.dart';
import 'package:ide_core/ide_core.dart';

void main() {
  group('TerminalsController', () {
    late StreamController<WsFrame> events;
    late List<(String, Map<String, dynamic>)> sent;
    late ValueNotifier<bool> connected;
    late TerminalsController c;

    setUp(() {
      events = StreamController<WsFrame>.broadcast();
      sent = [];
      connected = ValueNotifier(true);
      c = TerminalsController(
        projectId: 'p1',
        request: (type, payload) async {
          sent.add((type, payload));
          return type == MsgType.ptyOpen ? {'ptyId': 'pty${sent.length}'} : {};
        },
        events: events.stream,
        connected: connected,
      );
    });

    tearDown(() async {
      c.dispose();
      await events.close();
    });

    test('opens a PTY, forwards input, renders output, handles exit', () async {
      final s = await c.open();
      expect(sent.first.$1, MsgType.ptyOpen);
      expect(sent.first.$2['projectId'], 'p1');
      expect(s.ptyId, 'pty1');

      s.terminal.textInput('ls');
      await Future<void>.delayed(Duration.zero);
      expect(sent.where((e) => e.$1 == MsgType.ptyInput).map((e) => e.$2['data']).join(), 'ls');

      events.add(const WsFrame(type: MsgType.ptyOutput, payload: {'ptyId': 'pty1', 'data': 'hello-world'}));
      await Future<void>.delayed(Duration.zero);
      expect(s.terminal.buffer.lines[0].toString(), contains('hello-world'));

      events.add(const WsFrame(type: MsgType.ptyExit, payload: {'ptyId': 'pty1', 'exitCode': 0}));
      await Future<void>.delayed(Duration.zero);
      expect(s.exited, isTrue);
    });

    test('sticky Ctrl turns the next letter into a control code', () async {
      await c.open();
      c.toggleCtrl();
      c.activeSession!.terminal.textInput('c');
      await Future<void>.delayed(Duration.zero);
      expect(sent.last.$2['data'], '\x03');
      expect(c.activeSession!.ctrlArmed, isFalse);
      c.send('\x1b[A');
      expect(sent.last.$2['data'], '\x1b[A');
    });

    test('marks sessions exited when the socket drops', () async {
      final s = await c.open();
      connected.value = false;
      expect(s.exited, isTrue);
    });
  });

  test('PreviewController tracks build lifecycle', () async {
    final events = StreamController<WsFrame>.broadcast();
    final c = PreviewController(
      projectId: 'p1',
      runnerUrl: 'http://10.0.2.2:8787',
      request: (type, payload) async => {
        'job': {'jobId': 'j1', 'kind': 'build_web', 'status': 'queued'},
        'preview': {'projectId': 'p1', 'path': '/preview/w/p1/', 'built': false, 'autoRebuild': true},
      },
      events: events.stream,
    );
    await c.run();
    expect(c.phase, PreviewPhase.building);
    expect(c.url, isNull);

    events.add(const WsFrame(type: MsgType.jobLog, payload: {'jobId': 'j1', 'chunk': 'Compiling…'}));
    events.add(const WsFrame(type: MsgType.jobLog, payload: {'jobId': 'other', 'chunk': 'nope'}));
    events.add(const WsFrame(
      type: MsgType.previewReady,
      payload: {'projectId': 'p1', 'path': '/preview/w/p1/', 'built': true, 'autoRebuild': true},
    ));
    await Future<void>.delayed(Duration.zero);
    expect(c.buildLog.toString(), 'Compiling…');
    expect(c.phase, PreviewPhase.ready);
    expect(c.revision, 1);
    expect(c.url, 'http://10.0.2.2:8787/preview/w/p1/');

    events.add(const WsFrame(type: MsgType.previewFailed, payload: {'projectId': 'p1', 'jobId': 'j2'}));
    await Future<void>.delayed(Duration.zero);
    expect(c.phase, PreviewPhase.failed);
    c.dispose();
    await events.close();
  });
}
