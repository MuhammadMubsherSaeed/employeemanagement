import 'package:flutter_base/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String uid,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _repository.resetPassword(
      uid: uid,
      token: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
