import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/session.dart';
import 'features/auth/login_screen.dart';
import 'features/create/app_section_screen.dart';
import 'features/create/create_app_screen.dart';
import 'features/preview/fullscreen_app_screen.dart';
import 'features/store/play_publish_screen.dart';
import 'features/store/publish_chat_screen.dart';
import 'features/mockups/mockup_gallery_screen.dart';
import 'features/editor/workspace_screen.dart';
import 'features/projects/projects_screen.dart';
import 'features/settings/settings_screen.dart';
import 'ui/ui.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/projects',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      if (session.isLoading && !session.hasValue) return '/splash';
      final signedIn = session.value != null;
      final atLogin = state.matchedLocation == '/login';
      if (!signedIn) return atLogin ? null : '/login';
      if (atLogin || state.matchedLocation == '/splash') return '/projects';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const Scaffold(body: LoadingState()),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/mockups',
        redirect: (_, state) => state.extra is CreateAppArgs ? null : '/projects',
        builder: (_, state) => MockupGalleryScreen(args: state.extra! as CreateAppArgs),
      ),
      GoRoute(path: '/run', builder: (_, state) => FullscreenAppScreen(url: state.uri.queryParameters['url'] ?? '')),
      GoRoute(
        path: '/projects',
        builder: (_, _) => const ProjectsScreen(),
        routes: [
          GoRoute(
            path: ':projectId',
            builder: (_, state) => WorkspaceScreen(
              projectId: state.pathParameters['projectId']!,
              initialPanel: state.uri.queryParameters['panel'],
            ),
            routes: [
              GoRoute(
                path: 'play',
                builder: (_, state) => PublishChatScreen(
                  projectId: state.pathParameters['projectId']!,
                  appDescription: state.extra is String ? state.extra! as String : '',
                ),
                routes: [
                  GoRoute(
                    path: 'details',
                    builder: (_, state) => PlayPublishScreen(
                      projectId: state.pathParameters['projectId']!,
                      appDescription: state.extra is String ? state.extra! as String : '',
                      initialStep: 3,
                    ),
                  ),
                ],
              ),
              // The pages one row away from the app's home.
              for (final section in AppSection.values)
                GoRoute(
                  path: section.path,
                  builder: (_, state) => AppSectionScreen(projectId: state.pathParameters['projectId']!, section: section),
                ),
              GoRoute(
                path: 'create',
                builder: (_, state) => CreateAppScreen(
                  projectId: state.pathParameters['projectId']!,
                  args: state.extra is CreateAppArgs ? state.extra as CreateAppArgs : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
