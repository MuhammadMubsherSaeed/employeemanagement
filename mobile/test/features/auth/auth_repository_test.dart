import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/data/models/token_model.dart';
import 'package:flutter_base/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';

void main() {
  test('successful login persists tokens and maps the user', () async {
    final InMemoryTokenStorage tokens = InMemoryTokenStorage();
    final FakeAuthRemote remote = FakeAuthRemote();
    final AuthRepositoryImpl repository = AuthRepositoryImpl(
      remote: remote,
      tokenStorage: tokens,
    );

    final user = await repository.login(
      email: 'user@example.com',
      password: 'secret',
    );

    expect(user.email, 'user@example.com');
    expect(user.role, isNotNull);
    expect(tokens.access, 'access-1');
    expect(tokens.refresh, 'refresh-1');
  });

  test('invalid credentials bubble up without storing tokens', () async {
    final InMemoryTokenStorage tokens = InMemoryTokenStorage();
    final FakeAuthRemote remote = FakeAuthRemote()
      ..loginError = const UnauthorizedException(
        'Invalid email or password.',
        'INVALID_CREDENTIALS',
      );
    final AuthRepositoryImpl repository = AuthRepositoryImpl(
      remote: remote,
      tokenStorage: tokens,
    );

    await expectLater(
      () => repository.login(email: 'user@example.com', password: 'bad'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(tokens.access, isNull);
  });

  test('logout clears tokens even when the backend call fails', () async {
    final InMemoryTokenStorage tokens = InMemoryTokenStorage(
      access: 'a',
      refresh: 'r',
    );
    final FakeAuthRemote remote = FakeAuthRemote()
      ..logoutError = const NetworkException();
    final AuthRepositoryImpl repository = AuthRepositoryImpl(
      remote: remote,
      tokenStorage: tokens,
    );

    await repository.logout();

    expect(remote.logoutCalls, 1);
    expect(tokens.access, isNull);
    expect(tokens.refresh, isNull);
  });

  test('refresh stores a rotated refresh token', () async {
    final InMemoryTokenStorage tokens = InMemoryTokenStorage(refresh: 'old');
    final FakeAuthRemote remote = FakeAuthRemote()
      ..refreshResponse = const TokenModel(
        access: 'new-access',
        refresh: 'new-refresh',
      );
    final AuthRepositoryImpl repository = AuthRepositoryImpl(
      remote: remote,
      tokenStorage: tokens,
    );

    await repository.refreshToken();

    expect(tokens.access, 'new-access');
    expect(tokens.refresh, 'new-refresh');
  });

  test('refresh does not overwrite a valid refresh token with null', () async {
    final InMemoryTokenStorage tokens = InMemoryTokenStorage(
      access: 'a',
      refresh: 'keep-me',
    );
    final FakeAuthRemote remote = FakeAuthRemote()
      ..refreshResponse = const TokenModel(access: 'new-access');
    final AuthRepositoryImpl repository = AuthRepositoryImpl(
      remote: remote,
      tokenStorage: tokens,
    );

    await repository.refreshToken();

    expect(tokens.access, 'new-access');
    expect(tokens.refresh, 'keep-me');
  });

  test('forgot password success and validation errors', () async {
    final AuthRepositoryImpl ok = AuthRepositoryImpl(
      remote: FakeAuthRemote(),
      tokenStorage: InMemoryTokenStorage(),
    );
    await ok.forgotPassword(email: 'user@example.com');

    final AuthRepositoryImpl failing = AuthRepositoryImpl(
      remote: FakeAuthRemote()
        ..forgotError = const ValidationException('Enter a valid email.'),
      tokenStorage: InMemoryTokenStorage(),
    );
    await expectLater(
      () => failing.forgotPassword(email: 'bad'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('reset password success, mismatch, and invalid token', () async {
    final FakeAuthRemote remote = FakeAuthRemote();
    final AuthRepositoryImpl repository = AuthRepositoryImpl(
      remote: remote,
      tokenStorage: InMemoryTokenStorage(),
    );

    await repository.resetPassword(
      uid: 'uid',
      token: 'token',
      newPassword: 'another-strong-pass-123',
      confirmPassword: 'another-strong-pass-123',
    );
    expect(remote.lastResetUid, 'uid');

    remote.resetError = const ValidationException('Passwords do not match.');
    await expectLater(
      () => repository.resetPassword(
        uid: 'uid',
        token: 'token',
        newPassword: 'a',
        confirmPassword: 'b',
      ),
      throwsA(isA<ValidationException>()),
    );

    remote.resetError = const UnknownException('Password reset failed.');
    await expectLater(
      () => repository.resetPassword(
        uid: 'bad',
        token: 'bad',
        newPassword: 'another-strong-pass-123',
        confirmPassword: 'another-strong-pass-123',
      ),
      throwsA(isA<UnknownException>()),
    );
  });
}
