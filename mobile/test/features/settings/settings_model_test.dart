import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/settings_fakes.dart';

void main() {
  test('parses snake_case settings including nullable logo and weekday names', () {
    final CompanySettings settings = CompanySettings.fromJson(
      sampleSettingsJson(
        logo: 'https://example.com/media/logo.png',
        timezone: 'Asia/Karachi',
        overtime: true,
      ),
    );

    expect(settings.id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
    expect(settings.companyId, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
    expect(settings.companyName, 'Acme');
    expect(settings.logo, 'https://example.com/media/logo.png');
    expect(settings.timezone, 'Asia/Karachi');
    expect(settings.workStartTime, const ClockTime(hour: 9, minute: 0));
    expect(settings.workEndTime, const ClockTime(hour: 17, minute: 0));
    expect(settings.gracePeriodMinutes, 15);
    expect(settings.minimumWorkingMinutes, 480);
    expect(settings.overtimeEnabled, isTrue);
    expect(
      settings.workingDays,
      <String>['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    );
  });

  test('treats missing logo as null and ignores unknown weekday names', () {
    final CompanySettings settings = CompanySettings.fromJson(
      sampleSettingsJson(
        logo: null,
        workingDays: <dynamic>['monday', 'funday', 2],
      ),
    );

    expect(settings.logo, isNull);
    expect(settings.workingDays, <String>['monday', 'wednesday']);
  });

  test('CompanySettingsPatch omits unset fields and serializes times', () {
    const CompanySettingsPatch patch = CompanySettingsPatch(
      timezone: 'Europe/London',
      gracePeriodMinutes: 20,
      workStartTime: ClockTime(hour: 8, minute: 30),
    );

    expect(
      patch.toJson(),
      <String, dynamic>{
        'timezone': 'Europe/London',
        'work_start_time': '08:30:00',
        'grace_period_minutes': 20,
      },
    );
  });
}
