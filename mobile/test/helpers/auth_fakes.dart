import 'dart:async';

import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/storage/token_storage.dart';
import 'package:flutter_base/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_base/features/auth/data/models/auth_response.dart';
import 'package:flutter_base/features/auth/data/models/login_request.dart';
import 'package:flutter_base/features/auth/data/models/token_model.dart';
import 'package:flutter_base/features/auth/data/models/user_model.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/repositories/auth_repository.dart';

import 'rbac_fixtures.dart';

const User sampleUser = User(
  id: 1,
  email: 'user@example.com',
  firstName: 'User',
  lastName: 'Name',
  fullName: 'User Name',
  role: UserRole.employee,
  roleValue: 'EMPLOYEE',
  isActive: true,
  companyId: kSampleCompanyId,
  permissions: kEmployeePermissions,
);

const UserModel sampleUserModel = UserModel(
  id: 1,
  email: 'user@example.com',
  firstName: 'User',
  lastName: 'Name',
  fullName: 'User Name',
  role: 'EMPLOYEE',
  isActive: true,
  companyId: kSampleCompanyId,
  permissions: kEmployeePermissions,
);

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({this.access, this.refresh});

  String? access;
  String? refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    access = accessToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      refresh = refreshToken;
    }
  }

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }

  @override
  Future<bool> hasTokens() async {
    return (access != null && access!.isNotEmpty) ||
        (refresh != null && refresh!.isNotEmpty);
  }

  @override
  Future<bool> hasRefreshToken() async {
    return refresh != null && refresh!.isNotEmpty;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user = sampleUser});

  User user;
  Object? loginError;
  Object? meError;
  Object? refreshError;
  Object? forgotError;
  Object? resetError;
  bool logoutThrows = false;
  int logoutCalls = 0;
  int loginCalls = 0;
  int meCalls = 0;
  int refreshCalls = 0;
  Completer<User>? meHold;

  @override
  Future<User> login({required String email, required String password}) async {
    loginCalls += 1;
    if (loginError != null) {
      throw loginError!;
    }
    return user;
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
    if (logoutThrows) {
      throw const NetworkException();
    }
  }

  @override
  Future<void> refreshToken() async {
    refreshCalls += 1;
    if (refreshError != null) {
      throw refreshError!;
    }
  }

  @override
  Future<User> getCurrentUser() async {
    meCalls += 1;
    if (meHold != null) {
      return meHold!.future;
    }
    if (meError != null) {
      throw meError!;
    }
    return user;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    if (forgotError != null) {
      throw forgotError!;
    }
  }

  @override
  Future<void> resetPassword({
    required String uid,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (resetError != null) {
      throw resetError!;
    }
  }
}

class FakeAuthRemote implements AuthRemoteDataSource {
  AuthResponse loginResponse = const AuthResponse(
    tokens: TokenModel(access: 'access-1', refresh: 'refresh-1'),
    user: sampleUserModel,
  );
  TokenModel refreshResponse = const TokenModel(
    access: 'access-2',
    refresh: 'refresh-2',
  );
  UserModel meResponse = sampleUserModel;
  Object? loginError;
  Object? refreshError;
  Object? logoutError;
  Object? meError;
  Object? forgotError;
  Object? resetError;
  int logoutCalls = 0;
  String? lastResetUid;
  String? lastResetToken;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    if (loginError != null) {
      throw loginError!;
    }
    return loginResponse;
  }

  @override
  Future<TokenModel> refresh(String refreshToken) async {
    if (refreshError != null) {
      throw refreshError!;
    }
    return refreshResponse;
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls += 1;
    if (logoutError != null) {
      throw logoutError!;
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    if (meError != null) {
      throw meError!;
    }
    return meResponse;
  }

  @override
  Future<void> forgotPassword(String email) async {
    if (forgotError != null) {
      throw forgotError!;
    }
  }

  @override
  Future<void> resetPassword({
    required String uid,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    lastResetUid = uid;
    lastResetToken = token;
    if (resetError != null) {
      throw resetError!;
    }
  }
}
