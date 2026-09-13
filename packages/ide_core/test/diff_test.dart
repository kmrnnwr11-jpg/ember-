import 'package:ide_core/ide_core.dart';
import 'package:test/test.dart';

String render(List<DiffLine> d) => d.map((l) => l.toString()).join('\n');

void main() {
  group('LineDiff', () {
    test('identical, insert, delete, replace', () {
      expect(LineDiff.compute('a\nb', 'a\nb').every((l) => l.kind == DiffKind.same), isTrue);
      expect(render(LineDiff.compute('a\nc', 'a\nb\nc')), ' a\n+b\n c');
      expect(render(LineDiff.compute('a\nb\nc', 'a\nc')), ' a\n-b\n c');
      expect(render(LineDiff.compute('x\ny', 'x\nz')), ' x\n-y\n+z');
      expect(render(LineDiff.compute('', 'new')), '+new');
    });

    test('line numbers and CRLF normalization', () {
      final d = LineDiff.compute('a\r\nb\r\nc', 'a\nB\nc');
      final added = d.firstWhere((l) => l.kind == DiffKind.added);
      final removed = d.firstWhere((l) => l.kind == DiffKind.removed);
      expect((added.newLine, removed.oldLine), (2, 2));
      expect(d.last.oldLine, 3);
    });

    test('hunks merge nearby changes and split distant ones', () {
      final old = List.generate(30, (i) => 'l$i').join('\n');
      final edited = old.replaceFirst('l2\n', 'X\n').replaceFirst('l4\n', 'Y\n').replaceFirst('l25', 'Z');
      final hunks = LineDiff.hunks(LineDiff.compute(old, edited), context: 2);
      expect(hunks.length, 2);
      expect((hunks[0].added, hunks[0].removed), (2, 2));
      expect(hunks[1].added, 1);
    });
  });

  group('CodeBlocks', () {
    test('splits prose and code, keeps path from info string', () {
      final segs = CodeBlocks.parse('Ecco:\n```dart lib/main.dart\nvoid main() {}\n```\nFatto.');
      expect(segs.length, 3);
      final code = segs[1] as CodeSegment;
      expect((code.language, code.path, code.code, code.complete), ('dart', 'lib/main.dart', 'void main() {}', true));
      expect((segs[2] as TextSegment).markdown, 'Fatto.');
    });

    test('info string variants and unsafe paths', () {
      expect(CodeBlocks.parseInfo('dart:lib/a.dart'), ('dart', 'lib/a.dart'));
      expect(CodeBlocks.parseInfo('pubspec.yaml'), ('yaml', 'pubspec.yaml'));
      expect(CodeBlocks.parseInfo('dart title="lib/x.dart"'), ('dart', 'lib/x.dart'));
      expect(CodeBlocks.parseInfo('bash'), ('bash', null));
      expect(CodeBlocks.parseInfo('dart ../../etc/passwd'), ('dart', null));
    });

    test('unterminated block while streaming', () {
      final code = CodeBlocks.parse('```dart\nprint(1);').single as CodeSegment;
      expect(code.complete, isFalse);
      expect(code.code, 'print(1);');
    });
  });
}
