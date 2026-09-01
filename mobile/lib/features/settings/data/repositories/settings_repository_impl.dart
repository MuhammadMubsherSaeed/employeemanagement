import 'package:flutter_base/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_base/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._remote);

  final SettingsRemoteDataSource _remote;

  @override
  Future<CompanySettings> getSettings() => _remote.getSettings();

  @override
  Future<CompanySettings> updateSettings(CompanySettingsPatch patch) {
    return _remote.updateSettings(patch);
  }
}
