import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';

abstract class SettingsLogoPicker {
  Future<SettingsLogoFile?> pick();
}
