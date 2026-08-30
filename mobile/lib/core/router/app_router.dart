import 'package:flutter/material.dart';
import 'package:flutter_base/core/presentation/app_error_screen.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/router/auth_redirect.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter_base/features/auth/presentation/screens/home_screen.dart';
import 'package:flutter_base/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_base/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:flutter_base/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createAppRouter({
  required AuthState Function() readAuth,
  Listenable? refreshListenable,
  String initialLocation = AppRoutes.splash,
}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: false,
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      return AuthRedirect.resolve(
        auth: readAuth(),
        location: state.matchedLocation,
      );
    },
    errorBuilder: (BuildContext context, GoRouterState state) {
      return const AppErrorScreen(
        message: 'This page could not be found.',
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (BuildContext context, GoRouterState state) {
          return const ForgotPasswordScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        builder: (BuildContext context, GoRouterState state) {
          return ResetPasswordScreen(
            uid: state.uri.queryParameters['uid'],
            token: state.uri.queryParameters['token'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
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
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (
    AuthState? previous,
    AuthState next,
  ) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);
  return createAppRouter(
    readAuth: () => ref.read(authControllerProvider),
    refreshListenable: refresh,
  );
});
