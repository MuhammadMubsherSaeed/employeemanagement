import 'package:flutter_base/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});

  Future<void> logout();

  Future<void> refreshToken();

  Future<User> getCurrentUser();

  Future<void> forgotPassword({required String email});

  Future<void> resetPassword({
    required String uid,
    required String token,
    required String newPassword,
    required String confirmPassword,
  });
}
