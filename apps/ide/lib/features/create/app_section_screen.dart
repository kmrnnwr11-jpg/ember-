import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../review/review_card.dart';
import 'ads_card.dart';
import 'app_builder.dart';
import 'app_session.dart';
import 'appstore_card.dart';
import 'checkup_card.dart';
import 'github_card.dart';
import 'hub/android_file_card.dart';
import 'hub/hub_widgets.dart';
import 'ios_card.dart';
import 'logo_card.dart';
import 'phone_card.dart';
import 'play_update_card.dart';
import 'products_card.dart';
import 'screenshots_card.dart';

/// The pages one row away from an app's home.
enum AppSection {
  test('test'),
  images('images'),
  checks('checks'),
  googlePlay('google-play'),
  appStore('app-store'),
  more('more');

  const AppSection(this.path);

  /// Last segment of the route: `/projects/:id/<path>`.
  final String path;

  String title(AppLocalizations l) => switch (this) {
    test => l.hubTest,
    images => l.hubImages,
    checks => l.hubChecks,
    googlePlay => l.hubPlay,
    appStore => l.hubAppStore,
    more => l.hubMore,
  };
}

/// One section of a finished app, on a page of its own.
class AppSectionScreen extends ConsumerWidget {
  const AppSectionScreen({super.key, required this.projectId, required this.section});

  final String projectId;
  final AppSection section;

  String get _home => '/projects/$projectId/create';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final projectAsync = ref.watch(projectByIdProvider(projectId));
    void back() => context.canPop() ? context.pop() : context.go(_home);
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: back), title: Text(section.title(l))),
      body: projectAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: l.error(e is RunnerException ? e.message : e.toString()), onRetry: () => ref.invalidate(projectByIdProvider(projectId))),
        data: (project) {
          final b = ref.watch(appBuilderProvider((project.id, project.name)));
          // Opened straight from a link: the app's home loads the app first.
          if (b.phase == BuildPhase.idle) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(_home);
            });
            return const LoadingState();
          }
          return ListenableBuilder(
            listenable: b,
            builder: (context, _) => PageBody(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.xl),
              children: [
                if (b.running)
                  SectionCard(
                    icon: Icons.auto_awesome_outlined,
                    title: l.forgeTitle,
                    children: [
                      Gap.vSm,
                      BusyRow(b.currentAction ?? l.stepWriting(b.writtenFiles.length)),
                      Gap.vSm,
                      Align(alignment: AlignmentDirectional.centerStart, child: TextButton(onPressed: back, child: Text(l.backToApp))),
                    ],
                  ),
                ..._cards(context, ref, l, b, project),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _cards(BuildContext context, WidgetRef ref, AppLocalizations l, AppBuilder b, Project project) {
    final id = project.id;
    return switch (section) {
      AppSection.test => [
        PhoneCard(projectId: id, builder: b),
        AndroidFileCard(builder: b, projectId: id, kind: 'apk'),
        OpenInBrowserCard(builder: b),
      ],
      AppSection.images => [
        LogoCard(builder: b, projectId: id),
        ScreenshotsCard(builder: b, projectId: id),
      ],
      AppSection.checks => [
        CheckupCard(projectId: id, builder: b, previewUrl: b.preview?.resolve(ref.read(sessionProvider).value?.runnerUrl ?? '')),
        // Several models read the finished app and say what is fake, missing
        // or broken; one tap sends a fix back. It stays here while a fix is
        // running too: it is the list the user is working through.
        ReviewCard(projectId: id, onFix: (ask) => b.improve(ask, display: l.reviewFixLabel)),
      ],
      AppSection.googlePlay => [
        PlayUpdateCard(builder: b, projectId: id),
        AndroidFileCard(builder: b, projectId: id, kind: 'aab'),
        SigningKeyCard(projectId: id),
      ],
      AppSection.appStore => [
        IosCard(builder: b),
        AppStoreCard(projectId: id, builder: b),
      ],
      AppSection.more => [
        GitHubCard(projectId: id),
        if (b.products.isNotEmpty) ProductsCard(builder: b, projectId: id),
        AdsCard(builder: b),
        SigningKeyCard(projectId: id),
        SectionCard(
          icon: Icons.code,
          title: l.openCodeTitle,
          hint: l.openCodeHint,
          children: [
            Gap.vMd,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(key: const Key('openEditor'), onPressed: () => context.go('/projects/$id'), icon: const Icon(Icons.code), label: Text(l.openEditor)),
            ),
          ],
        ),
      ],
    };
  }
}
