import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/session.dart';
import 'features/auth/login_screen.dart';
import 'features/editor/workspace_screen.dart';
import 'features/projects/projects_screen.dart';

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
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/projects',
        builder: (_, _) => const ProjectsScreen(),
        routes: [
          GoRoute(
            path: ':projectId',
            builder: (_, state) => WorkspaceScreen(projectId: state.pathParameters['projectId']!),
          ),
        ],
      ),
    ],
  );
});
