import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_base/features/settings/domain/settings_access.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_error_mapper.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_base/features/settings/presentation/states/settings_update_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsUpdateController extends Notifier<SettingsUpdateState> {
  @override
  SettingsUpdateState build() {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      state = const SettingsUpdateState();
    });
    return const SettingsUpdateState();
  }

  void setFieldErrors(Map<String, String> errors) {
    state = SettingsUpdateState(fieldErrors: errors);
  }

  Future<CompanySettings?> save(CompanySettingsPatch patch) async {
    if (!SettingsAccess(ref.read(authorizationProvider)).canEdit) {
      state = const SettingsUpdateState(error: SettingsErrorMapper.forbidden);
      return null;
    }
    if (state.isSubmitting) {
      return null;
    }
    state = const SettingsUpdateState(isSubmitting: true);
    try {
      final CompanySettings updated =
          await ref.read(updateCompanySettingsUseCaseProvider)(patch);
      ref.invalidate(companySettingsProvider);
      await ref.read(companySettingsProvider.future);
      state = const SettingsUpdateState();
      return updated;
    } catch (error) {
      state = SettingsUpdateState(
        fieldErrors: SettingsErrorMapper.fieldErrors(error),
        error: SettingsErrorMapper.message(error),
      );
      return null;
    }
  }
}

final settingsUpdateControllerProvider =
    NotifierProvider<SettingsUpdateController, SettingsUpdateState>(
  SettingsUpdateController.new,
);
