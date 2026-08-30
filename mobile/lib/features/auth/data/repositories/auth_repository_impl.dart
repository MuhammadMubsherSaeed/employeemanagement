import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/storage/token_storage.dart';
import 'package:flutter_base/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_base/features/auth/data/models/login_request.dart';
import 'package:flutter_base/features/auth/data/models/token_model.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _remote = remote,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<User> login({required String email, required String password}) async {
    final result = await _remote.login(
      LoginRequest(email: email.trim(), password: password),
    );
    await _persistTokens(result.tokens);
    return result.user.toEntity();
  }

  @override
  Future<void> logout() async {
    final String? refresh = await _tokenStorage.getRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _remote.logout(refresh);
      }
    } on AppException {
      // Local logout must always succeed.
    } catch (_) {
      // Network/timeout/server failures still clear the device session.
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  @override
  Future<void> refreshToken() async {
    final String? refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw const UnauthorizedException(
        'Your session has expired. Please log in again.',
      );
    }
    final TokenModel tokens = await _remote.refresh(refresh);
    await _persistTokens(tokens);
  }

  @override
  Future<User> getCurrentUser() async {
    return (await _remote.getCurrentUser()).toEntity();
  }

  @override
  Future<void> forgotPassword({required String email}) {
    return _remote.forgotPassword(email.trim());
  }

  @override
  Future<void> resetPassword({
    required String uid,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _remote.resetPassword(
      uid: uid,
      token: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  Future<void> _persistTokens(TokenModel tokens) {
    return _tokenStorage.saveTokens(
      accessToken: tokens.access,
      refreshToken: tokens.refresh,
    );
  }
}
