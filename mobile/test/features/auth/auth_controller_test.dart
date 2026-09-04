import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/session/session_invalidator.dart';
import 'package:flutter_base/core/session/session_store.dart';
import 'package:flutter_base/core/storage/token_storage.dart';
import 'package:flutter_base/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';

ProviderContainer _container({
  required FakeAuthRepository repository,
  InMemoryTokenStorage? tokens,
}) {
  final InMemoryTokenStorage storage = tokens ?? InMemoryTokenStorage();
  return ProviderContainer(
    overrides: <Override>[
      authRepositoryProvider.overrideWithValue(repository),
      tokenStorageProvider.overrideWithValue(storage),
      loginUseCaseProvider.overrideWithValue(LoginUseCase(repository)),
      logoutUseCaseProvider.overrideWithValue(LogoutUseCase(repository)),
      restoreSessionUseCaseProvider.overrideWithValue(
        RestoreSessionUseCase(repository: repository, tokenStorage: storage),
      ),
      forgotPasswordUseCaseProvider.overrideWithValue(
        ForgotPasswordUseCase(repository),
      ),
      resetPasswordUseCaseProvider.overrideWithValue(
        ResetPasswordUseCase(repository),
      ),
      sessionInvalidatorProvider.overrideWithValue(SessionInvalidator()),
      sessionStoreProvider.overrideWithValue(SessionStore.memory()),
    ],
  );
}

void main() {
  test('restore with no tokens becomes unauthenticated', () async {
    final ProviderContainer container = _container(
      repository: FakeAuthRepository(),
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(authControllerProvider),
      const AuthState.unauthenticated(),
    );
  });

  test('restore with a valid refresh token loads /me/', () async {
    final FakeAuthRepository repository = FakeAuthRepository();
    final ProviderContainer container = _container(
      repository: repository,
      tokens: InMemoryTokenStorage(refresh: 'refresh-1'),
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(repository.meCalls, 1);
    expect(
      container.read(authControllerProvider),
      const AuthState.authenticated(sampleUser),
    );
  });

  test('restore treats /me/ failure as unauthenticated', () async {
    final FakeAuthRepository repository = FakeAuthRepository()
      ..meError = const UnauthorizedException();
    final InMemoryTokenStorage tokens =
        InMemoryTokenStorage(refresh: 'refresh-1');
    final ProviderContainer container = _container(
      repository: repository,
      tokens: tokens,
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authControllerProvider), const AuthState.unauthenticated());
    expect(tokens.refresh, isNull);
  });

  test('successful login authenticates', () async {
    final ProviderContainer container = _container(
      repository: FakeAuthRepository(),
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await container.read(authControllerProvider.notifier).login(
          email: 'user@example.com',
          password: 'secret',
        );
    expect(
      container.read(authControllerProvider),
      const AuthState.authenticated(sampleUser),
    );
  });

  test('invalid credentials become an error state', () async {
    final FakeAuthRepository repository = FakeAuthRepository()
      ..loginError = const UnauthorizedException(
        'Invalid email or password.',
        'INVALID_CREDENTIALS',
      );
    final ProviderContainer container = _container(repository: repository);
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);

    await expectLater(
      () => container.read(authControllerProvider.notifier).login(
            email: 'user@example.com',
            password: 'wrong',
          ),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(container.read(authControllerProvider), isA<AuthError>());
  });

  test('network errors map to a user-safe login error', () async {
    final FakeAuthRepository repository = FakeAuthRepository()
      ..loginError = const NetworkException();
    final ProviderContainer container = _container(repository: repository);
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);

    await expectLater(
      () => container.read(authControllerProvider.notifier).login(
            email: 'user@example.com',
            password: 'secret',
          ),
      throwsA(isA<NetworkException>()),
    );
    final AuthState state = container.read(authControllerProvider);
    expect(state, isA<AuthError>());
    expect(
      (state as AuthError).message,
      contains('internet connection'),
    );
  });

  test('logout always ends unauthenticated', () async {
    final FakeAuthRepository repository = FakeAuthRepository()
      ..logoutThrows = true;
    final ProviderContainer container = _container(
      repository: repository,
      tokens: InMemoryTokenStorage(access: 'a', refresh: 'r'),
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await container.read(authControllerProvider.notifier).login(
          email: 'user@example.com',
          password: 'secret',
        );
    await container.read(authControllerProvider.notifier).logout();
    expect(repository.logoutCalls, 1);
    expect(
      container.read(authControllerProvider),
      const AuthState.unauthenticated(),
    );
  });
}
