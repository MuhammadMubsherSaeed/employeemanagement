import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/router/auth_redirect.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';

void main() {
  test('initial and loading stay on splash', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.initial(),
        location: AppRoutes.login,
      ),
      AppRoutes.splash,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.loading(),
        location: AppRoutes.splash,
      ),
      isNull,
    );
  });

  test('unauthenticated users are sent to login and cannot open home', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.home,
      ),
      AppRoutes.login,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.login,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.forgotPassword,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.resetPassword,
      ),
      isNull,
    );
  });

  test('authenticated users go home and cannot open login', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.login,
      ),
      AppRoutes.home,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.forgotPassword,
      ),
      AppRoutes.home,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.home,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.splash,
      ),
      AppRoutes.home,
    );
  });

  test('redirect never returns the current location', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.login,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.home,
      ),
      isNull,
    );
  });
}
