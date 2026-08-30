import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';
import 'package:flutter_base/core/session/session_invalidator.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_error_mapper.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final SessionInvalidator invalidator = ref.read(sessionInvalidatorProvider);
    invalidator.register(_onSessionInvalidated);
    ref.onDispose(() => invalidator.unregister(_onSessionInvalidated));
    Future<void>.microtask(restoreSession);
    return const AuthState.loading();
  }

  Future<void> restoreSession() async {
    state = const AuthState.loading();
    try {
      final RestoreSessionUseCase restore =
          ref.read(restoreSessionUseCaseProvider);
      final User? user = await restore();
      if (user == null) {
        state = const AuthState.unauthenticated();
        return;
      }
      state = AuthState.authenticated(user);
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final LoginUseCase login = ref.read(loginUseCaseProvider);
    try {
      final User user = await login(email: email, password: password);
      state = AuthState.authenticated(user);
    } catch (error) {
      state = AuthState.error(AuthErrorMapper.message(error));
      rethrow;
    }
  }

  Future<void> logout() async {
    final LogoutUseCase logout = ref.read(logoutUseCaseProvider);
    try {
      await logout();
    } catch (_) {
      // Tokens are cleared in the repository even when the API call fails.
    } finally {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> loadCurrentUser() async {
    if (state is! AuthAuthenticated) {
      return;
    }
    try {
      final User user = await ref.read(authRepositoryProvider).getCurrentUser();
      state = AuthState.authenticated(user);
    } catch (error) {
      final AppException mapped = ErrorMapper.map(error);
      if (mapped is UnauthorizedException) {
        await logout();
      }
    }
  }

  void _onSessionInvalidated() {
    if (state is AuthUnauthenticated) {
      return;
    }
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
