import 'package:flutter/material.dart';
import 'package:flutter_base/views/login/login_screen.dart';
import 'package:flutter_base/views/splash/splash_screen.dart';
import 'routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final dynamic args = settings.arguments;

    switch (settings.name) {
      case Routes.LOGIN:
        return MaterialPageRoute<dynamic>(builder: (_) => const LoginScreen());

      case Routes.SPLASH:
        return MaterialPageRoute<dynamic>(builder: (_) => const SplashScreen());

      // case Routes.signUp:
      //   ScreenArguments arguments = args;
      //   if (arguments.authRepository is AuthRepository) {
      //     return PageRouteBuilder(
      //       pageBuilder: (BuildContext context, Animation<double> animation,
      //               Animation<double> secondaryAnimation) =>
      //           SignUpPage(
      //         authRepository: arguments.authRepository,
      //         phoneNumber: arguments.phoneNumber,
      //       ),
      //       transitionsBuilder: (
      //         BuildContext context,
      //         Animation<double> animation,
      //         Animation<double> secondaryAnimation,
      //         Widget child,
      //       ) =>
      //           FadeTransition(
      //         opacity: animation,
      //         child: child,
      //       ),
      //     );
      //   }
      //
      //   return _errorRoute();

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute<dynamic>(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('ERROR'),
        ),
      );
    });
  }
}
