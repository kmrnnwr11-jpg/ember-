import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/core/session.dart';
import 'package:ide/features/auth/login_screen.dart';
import 'package:ide/features/editor/project_controller.dart';
import 'package:ide/l10n/app_localizations.dart';
import 'package:ide_core/ide_core.dart';

class MemoryStore implements KeyValueStore {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// In-memory Runner implementing the fs.* protocol with mtime conflicts.
class FakeRunner {
  final files = <String, String>{'lib/main.dart': 'void main() {}', 'pubspec.yaml': 'name: demo'};
  final mtimes = <String, double>{};
  double clock = 1;

  Future<Map<String, dynamic>> call(String type, Map<String, dynamic> p) async {
    final path = p['path'] as String? ?? '';
    switch (type) {
      case MsgType.fsList:
        final prefix = path.isEmpty ? '' : '$path/';
        final names = <String, bool>{};
        for (final f in files.keys.where((f) => f.startsWith(prefix))) {
          final rest = f.substring(prefix.length);
          final slash = rest.indexOf('/');
          names[slash < 0 ? rest : rest.substring(0, slash)] = slash >= 0;
        }
        return {
          'entries': [
            for (final e in names.entries) {'path': '$prefix${e.key}', 'name': e.key, 'isDir': e.value, 'size': 0},
          ],
        };
      case MsgType.fsRead:
        return {'path': path, 'content': files[path]!, 'mtimeMs': mtimes[path] ??= clock};
      case MsgType.fsWrite:
        final expected = p['expectedMtimeMs'];
        if (expected != null && mtimes[path] != null && mtimes[path] != expected) {
          throw const RunnerException('conflict', 'changed');
        }
        files[path] = p['content'] as String;
        return {'path': path, 'mtimeMs': mtimes[path] = ++clock};
      case MsgType.fsDelete:
        files.removeWhere((k, _) => k == path || k.startsWith('$path/'));
        return {};
      default:
        throw RunnerException('unsupported', type);
    }
  }
}

void main() {
  group('ProjectController', () {
    test('loads tree, opens, edits, saves, detects conflicts', () async {
      final runner = FakeRunner();
      final c = ProjectController(projectId: 'p1', request: runner.call);

      await c.loadDir('');
      expect(c.children['']!.map((e) => e.name), containsAll(['lib', 'pubspec.yaml']));
      await c.toggleDir('lib');
      expect(c.children['lib']!.single.path, 'lib/main.dart');

      await c.open('lib/main.dart');
      final f = c.activeFile!;
      expect(f.dirty, isFalse);
      f.controller.text = 'void main() { print(1); }';
      expect(f.dirty, isTrue);
      await c.save(f);
      expect(f.dirty, isFalse);
      expect(runner.files['lib/main.dart'], 'void main() { print(1); }');

      // Someone else writes the file → our save conflicts.
      runner.mtimes['lib/main.dart'] = 999;
      f.controller.text = 'mine';
      await expectLater(c.save(f), throwsA(isA<SaveConflict>()));
      await c.save(f, force: true);
      expect(runner.files['lib/main.dart'], 'mine');

      await c.delete(const FsEntry(path: 'lib', name: 'lib', isDir: true));
      expect(c.tabs, isEmpty);
      c.dispose();
    });
  });

  testWidgets('login screen renders in Italian and validates email', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreProvider.overrideWithValue(MemoryStore())],
        child: const MaterialApp(
          locale: Locale('it'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FlutterCursor'), findsOneWidget);
    expect(find.text('Accedi'), findsWidgets);
    await tester.tap(find.byKey(const Key('signIn')));
    await tester.pump();
    expect(find.text('Email non valida'), findsOneWidget);
  });
}
