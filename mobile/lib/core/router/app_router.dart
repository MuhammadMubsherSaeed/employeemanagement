import 'package:flutter_base/views/login/login_screen.dart';
import 'package:flutter_base/views/splash/splash_screen.dart';
import 'package:go_router/go_router.dart';

/// Target GoRouter configuration.
///
/// [MyApp] still uses Navigator 1.0 via [RouteGenerator]. Do not wire this
/// into [MaterialApp.router] until auth is rebuilt on the new stack.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/signIn',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
}
