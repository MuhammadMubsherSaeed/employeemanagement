import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_base/features/settings/domain/settings_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('company name is required and trimmed length is bounded', () {
    expect(
      SettingsValidation.company(companyName: '  ', timezone: 'UTC'),
      containsPair('company_name', 'Enter a company name.'),
    );
    expect(
      SettingsValidation.company(
        companyName: 'A' * (kMaxCompanyNameLength + 1),
        timezone: 'UTC',
      ).containsKey('company_name'),
      isTrue,
    );
    expect(
      SettingsValidation.company(companyName: 'Acme', timezone: 'UTC'),
      isEmpty,
    );
  });

  test('work times reject identical and overnight configurations', () {
    expect(
      SettingsValidation.attendance(
        workStartTime: const ClockTime(hour: 9, minute: 0),
        workEndTime: const ClockTime(hour: 9, minute: 0),
        gracePeriodMinutes: 15,
        minimumWorkingMinutes: 480,
        workingDays: const <String>['monday'],
      )['work_end_time'],
      'Start and end times cannot be the same.',
    );
    expect(
      SettingsValidation.attendance(
        workStartTime: const ClockTime(hour: 22, minute: 0),
        workEndTime: const ClockTime(hour: 6, minute: 0),
        gracePeriodMinutes: 15,
        minimumWorkingMinutes: 480,
        workingDays: const <String>['monday'],
      )['work_end_time'],
      contains('Overnight'),
    );
  });

  test('grace, minimum minutes, and working days bounds', () {
    expect(
      SettingsValidation.attendance(
        workStartTime: const ClockTime(hour: 9, minute: 0),
        workEndTime: const ClockTime(hour: 17, minute: 0),
        gracePeriodMinutes: -1,
        minimumWorkingMinutes: 480,
        workingDays: const <String>['monday'],
      ).containsKey('grace_period_minutes'),
      isTrue,
    );
    expect(
      SettingsValidation.attendance(
        workStartTime: const ClockTime(hour: 9, minute: 0),
        workEndTime: const ClockTime(hour: 17, minute: 0),
        gracePeriodMinutes: 15,
        minimumWorkingMinutes: 0,
        workingDays: const <String>['monday'],
      ).containsKey('minimum_working_minutes'),
      isTrue,
    );
    expect(
      SettingsValidation.attendance(
        workStartTime: const ClockTime(hour: 9, minute: 0),
        workEndTime: const ClockTime(hour: 17, minute: 0),
        gracePeriodMinutes: 15,
        minimumWorkingMinutes: 480,
        workingDays: const <String>[],
      ).containsKey('working_days'),
      isTrue,
    );
    expect(
      SettingsValidation.normalizeWorkingDays(
        const <String>['Friday', 'monday', 'monday'],
      ),
      <String>['friday', 'monday'],
    );
  });
}
