import 'package:flutter_base/core/storage/token_storage.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase({
    required AuthRepository repository,
    required TokenStorage tokenStorage,
  })  : _repository = repository,
        _tokenStorage = tokenStorage;

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  Future<User?> call() async {
    if (!await _tokenStorage.hasRefreshToken()) {
      return null;
    }
    final String? refreshAtStart = await _tokenStorage.getRefreshToken();
    try {
      return await _repository.getCurrentUser();
    } catch (_) {
      final String? refreshNow = await _tokenStorage.getRefreshToken();
      if (refreshNow == refreshAtStart) {
        await _tokenStorage.clearTokens();
      }
      return null;
    }
  }
}
