import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/locale.dart';
import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../ai/ai_settings.dart';
import '../review/reviewers.dart';
import 'app_builder.dart';

/// The chat and settings of each built app, kept on the Runner.
class AppSessionStore {
  static String _key(String projectId) => 'ember_session_$projectId';

  static Future<void> save(String projectId, Map<String, dynamic> session) async {
    try {
      await Settings.instance.write(_key(projectId), jsonEncode(session));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> load(String projectId) async {
    try {
      final raw = await Settings.instance.read(_key(projectId));
      return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

/// Arguments passed when arriving from the home prompt.
class CreateAppArgs {
  const CreateAppArgs({
    required this.prompt,
    required this.engine,
    this.modelKey,
    this.quality = 'fast',
    this.design,
    this.designName,
    this.reference,
    this.referenceId,
    this.referenceTopics = const [],
    this.styleBrief = '',
    this.appName,
    this.referenceSiteUrl,
    this.designEngine = BuildEngine.gemini,
  });
  final String prompt;
  final BuildEngine engine;
  final String? modelKey;
  final String quality;

  /// Design brief from the chosen mockup, appended to the build instructions.
  final String? design;
  final String? designName;

  /// Brief of a Play Store app to take as a model (see [ReferenceApp.brief]).
  final String? reference;

  /// That app's Play Store id, to fetch its screens, and the subjects its
  /// listing promises, checked off once the app is built.
  final String? referenceId;
  final List<String> referenceTopics;

  /// Who the app is for, from the reference listing: decides how the mockups look.
  final String styleBrief;

  /// The name the user chose before the build: store listing, privacy policy
  /// and package name all come from it.
  final String? appName;

  /// A website being turned into an app: its pages are photographed into the
  /// project before the build, the way a Play listing's screenshots are.
  final String? referenceSiteUrl;

  /// Who draws the mockups, the logo and the screenshots: kept apart from the
  /// engine that writes the code.
  final BuildEngine designEngine;
}

/// One builder per project, kept alive so a build continues if the user
/// navigates away.
///
/// The keepAlive is the whole of that promise. Riverpod disposes a provider as
/// soon as nothing watches it, so leaving the build screen threw the builder
/// away mid-build: the engine carried on writing files on the Runner, but
/// nothing in Ember was listening any more, and to the user the app had simply
/// stopped. Going back to the list — the one thing this screen is meant to let
/// you do — was what broke it.
final appBuilderProvider = ChangeNotifierProvider.family<AppBuilder, (String, String)>((ref, key) {
  ref.keepAlive();
  final (projectId, projectName) = key;
  final socket = ref.watch(runnerSocketProvider);
  final builder = AppBuilder(
    projectId: projectId,
    projectName: projectName,
    strings: ref.read(stringsProvider),
    onSession: (s) => AppSessionStore.save(projectId, s),
    request: socket.request,
    events: socket.events,
    fetchJobLog: (jobId) async => (await ref.read(runnerApiProvider.future)).jobLog(jobId),
    resolveProvider: ref.read(aiProviderFactory),
    saveReferenceShots: (playAppId) async {
      final res = await (await ref.read(runnerApiProvider.future)).saveReferenceShots(projectId, playAppId);
      return (res['saved'] as num?)?.toInt() ?? 0;
    },
    saveSiteShots: (url) async {
      final res = await (await ref.read(runnerApiProvider.future)).saveSiteShots(projectId, url);
      return (res['shotsSaved'] as num?)?.toInt() ?? 0;
    },
    // The reviewers the user configured, asked automatically once the app is
    // built. None configured: an empty list, and the build just carries on.
    runReview: () async {
      final s = await ref.read(reviewerSettingsProvider.future);
      // Not a shortcut when the list is empty: Claude and Gemini review on the
      // Runner's own login and key, and the Runner adds them itself.
      // The owner's pick: GPT (ChatGPT subscription), Gemini and DeepSeek read
      // the app — three different eyes from Claude, who fixes what they find.
      // More reviewers only meant more "one more thing" rounds.
      final res = await (await ref.read(runnerApiProvider.future)).reviewApp(
        projectId,
        [
          for (final r in s.usable)
            if (r.id == 'deepseek')
              {'id': r.id, 'label': r.label, 'baseUrl': r.baseUrl, 'apiKey': s.keys[r.id]!, 'model': r.model},
        ],
        own: const ['gemini_runner', 'codex'],
      );
      return [for (final f in (res['findings'] as List? ?? const [])) (f as Map).cast<String, dynamic>()];
    },
    androidInfo: () async {
      final info = await (await ref.read(runnerApiProvider.future)).androidInfo(projectId);
      return 'ANDROID APP INFO (use for Firebase Android app and Google Sign-In):\n'
          '- package name: ${info['applicationId']}\n'
          '- SHA-1 release (Play/upload key): ${info['sha1Release']}\n'
          '- SHA-1 debug: ${info['sha1Debug']}';
    },
  );
  // Follow language changes without recreating the builder (a build may be running).
  ref.listen(stringsProvider, (_, s) => builder.strings = s);
  return builder;
});

/// The project behind an app screen.
final projectByIdProvider = FutureProvider.autoDispose.family<Project, String>((ref, id) async {
  final api = await ref.watch(runnerApiProvider.future);
  return api.project(id);
});
