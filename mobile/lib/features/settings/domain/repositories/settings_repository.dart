import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';

abstract class SettingsRepository {
  Future<CompanySettings> getSettings();

  Future<CompanySettings> updateSettings(CompanySettingsPatch patch);
}
