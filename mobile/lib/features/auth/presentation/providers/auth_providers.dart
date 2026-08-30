import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/core/storage/token_storage.dart';
import 'package:flutter_base/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_base/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_base/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_base/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:flutter_base/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((Ref ref) {
  return AuthRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((Ref ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((Ref ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((Ref ref) {
  return RestoreSessionUseCase(
    repository: ref.watch(authRepositoryProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((Ref ref) {
  return ForgotPasswordUseCase(ref.watch(authRepositoryProvider));
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((Ref ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
});
