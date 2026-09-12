import 'package:ide_core/ide_core.dart';
import 'package:test/test.dart';

void main() {
  group('WsFrame', () {
    test('round-trips', () {
      const f = WsFrame(id: 'r1', type: MsgType.fsRead, payload: {'path': 'a'});
      final back = WsFrame.decode(f.encode());
      expect(back.id, 'r1');
      expect(back.type, MsgType.fsRead);
      expect(back.payload['path'], 'a');
      expect(back.isResponse, isFalse);
    });

    test('events have no id', () {
      final f = WsFrame.decode('{"type":"fs.changed","payload":{"path":"x"}}');
      expect(f.id, isNull);
    });

    test('rejects missing type', () {
      expect(() => WsFrame.decode('{"id":"1"}'), throwsFormatException);
    });
  });

  group('ProjectPath', () {
    test('normalizes', () {
      expect(ProjectPath.normalize('/lib//./src/../main.dart'), 'lib/main.dart');
      expect(ProjectPath.normalize(r'lib\main.dart'), 'lib/main.dart');
      expect(ProjectPath.normalize(''), '');
    });

    test('blocks traversal', () {
      expect(() => ProjectPath.normalize('../etc/passwd'), throwsArgumentError);
      expect(() => ProjectPath.normalize('lib/../../x'), throwsArgumentError);
    });

    test('basename/dirname/join', () {
      expect(ProjectPath.basename('lib/src/a.dart'), 'a.dart');
      expect(ProjectPath.dirname('lib/src/a.dart'), 'lib/src');
      expect(ProjectPath.dirname('a.dart'), '');
      expect(ProjectPath.join('', 'a'), 'a');
      expect(ProjectPath.join('lib', 'a.dart'), 'lib/a.dart');
    });

    test('languageOf', () {
      expect(ProjectPath.languageOf('pubspec.yaml'), 'yaml');
      expect(ProjectPath.languageOf('lib/main.dart'), 'dart');
      expect(ProjectPath.languageOf('README.md'), 'markdown');
      expect(ProjectPath.languageOf('Makefile'), 'plaintext');
    });
  });

  test('models parse', () {
    final p = Project.fromJson({
      'id': 'p1',
      'workspaceId': 'w1',
      'name': 'counter',
      'template': 'empty',
      'status': 'ready',
      'createdAt': '2026-09-13T10:00:00.000Z',
    });
    expect(p.isReady, isTrue);
    final j = JobStatus.fromJson({'jobId': 'j', 'kind': 'create', 'status': 'failed', 'exitCode': 1});
    expect(j.isDone, isTrue);
  });
}
