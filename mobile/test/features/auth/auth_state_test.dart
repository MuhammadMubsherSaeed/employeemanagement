import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';

void main() {
  test('initial, loading, authenticated, unauthenticated, and error states', () {
    const AuthState initial = AuthState.initial();
    const AuthState loading = AuthState.loading();
    const AuthState authenticated = AuthState.authenticated(sampleUser);
    const AuthState unauthenticated = AuthState.unauthenticated();
    const AuthState error = AuthState.error('Invalid email or password.');

    expect(initial, isA<AuthInitial>());
    expect(loading, isA<AuthLoading>());
    expect(authenticated, isA<AuthAuthenticated>());
    expect((authenticated as AuthAuthenticated).user, sampleUser);
    expect(unauthenticated, isA<AuthUnauthenticated>());
    expect(error, isA<AuthError>());
    expect((error as AuthError).message, 'Invalid email or password.');
    expect(initial.isResolving, isTrue);
    expect(loading.isResolving, isTrue);
    expect(authenticated.isAuthenticated, isTrue);
    expect(unauthenticated.isAuthenticated, isFalse);
  });

  test('unknown backend roles do not throw', () {
    expect(UserRole.fromApi('AUDITOR'), UserRole.unknown);
    expect(UserRole.fromApi('EMPLOYEE'), UserRole.employee);
    expect(UserRole.fromApi(null), UserRole.unknown);
  });
}
