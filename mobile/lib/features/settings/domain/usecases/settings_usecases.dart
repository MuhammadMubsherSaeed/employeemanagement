import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_base/features/settings/domain/repositories/settings_repository.dart';

class GetCompanySettings {
  const GetCompanySettings(this._repository);

  final SettingsRepository _repository;

  Future<CompanySettings> call() => _repository.getSettings();
}

class UpdateCompanySettings {
  const UpdateCompanySettings(this._repository);

  final SettingsRepository _repository;

  Future<CompanySettings> call(CompanySettingsPatch patch) {
    return _repository.updateSettings(patch);
  }
}
