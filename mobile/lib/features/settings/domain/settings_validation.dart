import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';

const int kMaxCompanyNameLength = 255;
const int kMaxGracePeriodMinutes = 240;
const int kMaxMinimumWorkingMinutes = 1440;
const int kMaxLogoBytes = 2 * 1024 * 1024;
const List<String> kLogoExtensions = <String>['png', 'jpg', 'jpeg', 'webp'];

class SettingsValidation {
  SettingsValidation._();

  static Map<String, String> company({
    required String companyName,
    required String timezone,
    SettingsLogoFile? logo,
  }) {
    final Map<String, String> errors = <String, String>{};
    final String name = companyName.trim();
    if (name.isEmpty) {
      errors['company_name'] = 'Enter a company name.';
    } else if (name.length > kMaxCompanyNameLength) {
      errors['company_name'] = 'Company name is too long.';
    }
    if (timezone.trim().isEmpty) {
      errors['timezone'] = 'Select a timezone.';
    }
    final String? logoError = logoFile(logo);
    if (logoError != null) {
      errors['logo'] = logoError;
    }
    return errors;
  }

  static Map<String, String> attendance({
    required ClockTime workStartTime,
    required ClockTime workEndTime,
    required int gracePeriodMinutes,
    required int minimumWorkingMinutes,
    required List<String> workingDays,
  }) {
    final Map<String, String> errors = <String, String>{};
    if (workStartTime.totalMinutes == workEndTime.totalMinutes) {
      errors['work_end_time'] = 'Start and end times cannot be the same.';
    } else if (workEndTime.totalMinutes <= workStartTime.totalMinutes) {
      errors['work_end_time'] =
          'Overnight shifts are not supported. End time must be after start time.';
    }
    if (gracePeriodMinutes < 0 || gracePeriodMinutes > kMaxGracePeriodMinutes) {
      errors['grace_period_minutes'] =
          'Grace period must be between 0 and $kMaxGracePeriodMinutes minutes.';
    }
    if (minimumWorkingMinutes < 1 ||
        minimumWorkingMinutes > kMaxMinimumWorkingMinutes) {
      errors['minimum_working_minutes'] =
          'Minimum working minutes must be between 1 and $kMaxMinimumWorkingMinutes.';
    }
    final Set<String> unique = workingDays
        .map((String day) => day.trim().toLowerCase())
        .where((String day) => kWeekdayNames.contains(day))
        .toSet();
    if (unique.isEmpty) {
      errors['working_days'] = 'Select at least one working day.';
    }
    return errors;
  }

  static String? logoFile(SettingsLogoFile? file) {
    if (file == null) {
      return null;
    }
    final String ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : '';
    if (!kLogoExtensions.contains(ext)) {
      return 'Logo must be a PNG, JPEG, or WebP image.';
    }
    if (file.size > kMaxLogoBytes) {
      return 'Logo must be 2 MB or smaller.';
    }
    if (file.path.isEmpty) {
      return 'The selected image could not be read.';
    }
    return null;
  }

  static List<String> normalizeWorkingDays(Iterable<String> days) {
    final List<String> normalized = <String>[];
    for (final String day in days) {
      final String key = day.trim().toLowerCase();
      if (kWeekdayNames.contains(key) && !normalized.contains(key)) {
        normalized.add(key);
      }
    }
    return normalized;
  }
}
