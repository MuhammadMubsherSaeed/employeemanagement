import 'dart:async';

import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';
import 'package:flutter_base/core/session/logout_side_effects.dart';
import 'package:flutter_base/core/session/session_invalidator.dart';
import 'package:flutter_base/core/session/session_store.dart';
import 'package:flutter_base/core/session/user_session.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_error_mapper.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthController extends Notifier<AuthState> {
  int _epoch = 0;

  @override
  AuthState build() {
    final SessionInvalidator invalidator = ref.read(sessionInvalidatorProvider);
    invalidator.register(_onSessionInvalidated);
    ref.onDispose(() => invalidator.unregister(_onSessionInvalidated));
    Future<void>.microtask(restoreSession);
    return const AuthState.loading();
  }

  Future<void> restoreSession() async {
    if (state is AuthAuthenticated) {
      return;
    }
    final int epoch = _epoch;
    state = const AuthState.loading();
    try {
      final RestoreSessionUseCase restore =
          ref.read(restoreSessionUseCaseProvider);
      final User? user = await restore();
      if (epoch != _epoch) {
        return;
      }
      if (user == null) {
        await _clearAuthorization();
        state = const AuthState.unauthenticated();
        return;
      }
      await _persistAuthorization(user);
      if (epoch != _epoch) {
        return;
      }
      state = AuthState.authenticated(user);
    } catch (_) {
      if (epoch != _epoch) {
        return;
      }
      await _clearAuthorization();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final LoginUseCase login = ref.read(loginUseCaseProvider);
    try {
      final User user = await login(email: email, password: password);
      final int epoch = ++_epoch;
      await _persistAuthorization(user);
      if (epoch != _epoch) {
        return;
      }
      state = AuthState.authenticated(user);
    } catch (error) {
      state = AuthState.error(AuthErrorMapper.message(error));
      rethrow;
    }
  }

  Future<void> logout() async {
    _epoch++;
    try {
      await ref.read(logoutSideEffectsProvider).run();
    } catch (_) {
      // Device-token cleanup must not block sign-out.
    }
    final LogoutUseCase logout = ref.read(logoutUseCaseProvider);
    try {
      await logout();
    } catch (_) {
      // Tokens are cleared in the repository even when the API call fails.
    } finally {
      await _clearAuthorization();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> loadCurrentUser() async {
    if (state is! AuthAuthenticated) {
      return;
    }
    final int epoch = _epoch;
    try {
      final User user = await ref.read(authRepositoryProvider).getCurrentUser();
      if (epoch != _epoch) {
        return;
      }
      await _persistAuthorization(user);
      if (epoch != _epoch) {
        return;
      }
      state = AuthState.authenticated(user);
    } catch (error) {
      if (epoch != _epoch) {
        return;
      }
      final AppException mapped = ErrorMapper.map(error);
      if (mapped is UnauthorizedException) {
        await logout();
      }
    }
  }

  void _onSessionInvalidated() {
    _epoch++;
    unawaited(_clearAuthorization());
    if (state is AuthUnauthenticated) {
      return;
    }
    state = const AuthState.unauthenticated();
  }

  Future<void> _persistAuthorization(User user) async {
    try {
      final SessionStore store = ref.read(sessionStoreProvider);
      final String? companyId = user.companyId?.trim();
      if (companyId == null || companyId.isEmpty) {
        await store.clear();
      } else {
        await store.save(
          UserSession(
            userId: user.id.toString(),
            companyId: companyId,
            role: user.roleValue,
            permissions: user.permissions,
          ),
        );
      }
      ref.invalidate(currentSessionProvider);
    } catch (_) {
      // Tests without secure storage still authenticate.
    }
  }

  Future<void> _clearAuthorization() async {
    try {
      await ref.read(sessionStoreProvider).clear();
      ref.invalidate(currentSessionProvider);
    } catch (_) {
      // Missing storage must not block logout.
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
