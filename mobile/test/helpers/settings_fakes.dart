import 'package:flutter_base/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_base/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_base/features/settings/domain/services/settings_logo_picker.dart';

Map<String, dynamic> sampleSettingsJson({
  String id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  String companyId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  String companyName = 'Acme',
  String? logo,
  String timezone = 'UTC',
  String workStart = '09:00:00',
  String workEnd = '17:00:00',
  int grace = 15,
  int minimum = 480,
  bool overtime = false,
  List<dynamic> workingDays = const <dynamic>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ],
}) {
  return <String, dynamic>{
    'id': id,
    'company_id': companyId,
    'company_name': companyName,
    'logo': logo,
    'timezone': timezone,
    'work_start_time': workStart,
    'work_end_time': workEnd,
    'grace_period_minutes': grace,
    'minimum_working_minutes': minimum,
    'overtime_enabled': overtime,
    'working_days': workingDays,
    'created_at': '2026-03-16T09:00:00Z',
    'updated_at': '2026-03-16T09:00:00Z',
  };
}

CompanySettings sampleSettings({
  String timezone = 'UTC',
  bool overtime = false,
  List<String>? workingDays,
}) {
  return CompanySettings.fromJson(
    sampleSettingsJson(
      timezone: timezone,
      overtime: overtime,
      workingDays: workingDays ??
          const <dynamic>[
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
          ],
    ),
  );
}

class FakeSettingsRemote implements SettingsRemoteDataSource {
  FakeSettingsRemote({CompanySettings? settings})
      : settings = settings ?? sampleSettings();

  CompanySettings settings;
  CompanySettingsPatch? lastPatch;
  Object? getError;
  Object? patchError;
  int getCalls = 0;
  int patchCalls = 0;

  @override
  Future<CompanySettings> getSettings() async {
    getCalls += 1;
    if (getError != null) {
      throw getError!;
    }
    return settings;
  }

  @override
  Future<CompanySettings> updateSettings(CompanySettingsPatch patch) async {
    patchCalls += 1;
    lastPatch = patch;
    if (patchError != null) {
      throw patchError!;
    }
    settings = settings.copyWith(
      companyName: patch.companyName ?? settings.companyName,
      timezone: patch.timezone ?? settings.timezone,
      workStartTime: patch.workStartTime ?? settings.workStartTime,
      workEndTime: patch.workEndTime ?? settings.workEndTime,
      gracePeriodMinutes: patch.gracePeriodMinutes ?? settings.gracePeriodMinutes,
      minimumWorkingMinutes:
          patch.minimumWorkingMinutes ?? settings.minimumWorkingMinutes,
      overtimeEnabled: patch.overtimeEnabled ?? settings.overtimeEnabled,
      workingDays: patch.workingDays ?? settings.workingDays,
    );
    return settings;
  }
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({CompanySettings? settings})
      : settings = settings ?? sampleSettings();

  CompanySettings settings;
  CompanySettingsPatch? lastPatch;
  Object? getError;
  Object? patchError;
  int getCalls = 0;
  int patchCalls = 0;
  Duration? delay;

  @override
  Future<CompanySettings> getSettings() async {
    getCalls += 1;
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (getError != null) {
      throw getError!;
    }
    return settings;
  }

  @override
  Future<CompanySettings> updateSettings(CompanySettingsPatch patch) async {
    patchCalls += 1;
    lastPatch = patch;
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (patchError != null) {
      throw patchError!;
    }
    settings = settings.copyWith(
      companyName: patch.companyName ?? settings.companyName,
      timezone: patch.timezone ?? settings.timezone,
      workStartTime: patch.workStartTime ?? settings.workStartTime,
      workEndTime: patch.workEndTime ?? settings.workEndTime,
      gracePeriodMinutes: patch.gracePeriodMinutes ?? settings.gracePeriodMinutes,
      minimumWorkingMinutes:
          patch.minimumWorkingMinutes ?? settings.minimumWorkingMinutes,
      overtimeEnabled: patch.overtimeEnabled ?? settings.overtimeEnabled,
      workingDays: patch.workingDays ?? settings.workingDays,
      updatedAt: DateTime.parse('2026-03-16T10:00:00Z'),
    );
    return settings;
  }
}

class FakeSettingsLogoPicker implements SettingsLogoPicker {
  FakeSettingsLogoPicker({this.file});

  SettingsLogoFile? file;
  int pickCalls = 0;

  @override
  Future<SettingsLogoFile?> pick() async {
    pickCalls += 1;
    return file;
  }
}
