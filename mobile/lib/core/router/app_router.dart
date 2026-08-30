import 'package:flutter/material.dart';
import 'package:flutter_base/core/presentation/app_error_screen.dart';
import 'package:flutter_base/core/presentation/temporary_home_screen.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      // Auth, role, and company guards will be added with those features.
      if (state.uri.path == AppRoutes.root) {
        return AppRoutes.home;
      }
      return null;
    },
    errorBuilder: (BuildContext context, GoRouterState state) {
      return const AppErrorScreen(
        message: 'This page could not be found.',
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return const TemporaryHomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.error,
        name: 'error',
        builder: (BuildContext context, GoRouterState state) {
          return const AppErrorScreen(
            message: 'Something went wrong.',
          );
        },
      ),
    ],
  );
}

final goRouterProvider = Provider<GoRouter>((Ref ref) {
  return createAppRouter();
});
