import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:flutter_base/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_base/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_base/features/settings/domain/services/image_picker_settings_logo_picker.dart';
import 'package:flutter_base/features/settings/domain/services/settings_logo_picker.dart';
import 'package:flutter_base/features/settings/domain/usecases/settings_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsRemoteDataSourceProvider =
    Provider<SettingsRemoteDataSource>((Ref ref) {
  return SettingsRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((Ref ref) {
  return SettingsRepositoryImpl(ref.watch(settingsRemoteDataSourceProvider));
});

final getCompanySettingsUseCaseProvider = Provider<GetCompanySettings>((Ref ref) {
  return GetCompanySettings(ref.watch(settingsRepositoryProvider));
});

final updateCompanySettingsUseCaseProvider =
    Provider<UpdateCompanySettings>((Ref ref) {
  return UpdateCompanySettings(ref.watch(settingsRepositoryProvider));
});

final settingsLogoPickerProvider = Provider<SettingsLogoPicker>((Ref ref) {
  return ImagePickerSettingsLogoPicker();
});

/// Company settings for the authenticated tenant. Watches auth so a company
/// switch cannot keep another tenant's row in memory.
final companySettingsProvider =
    FutureProvider.autoDispose<CompanySettings>((Ref ref) {
  ref.watch(
    authControllerProvider.select((AuthState state) {
      if (state is AuthAuthenticated) {
        return state.user.id;
      }
      return null;
    }),
  );
  return ref.watch(getCompanySettingsUseCaseProvider)();
});
