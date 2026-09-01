import 'package:equatable/equatable.dart';

const List<String> kWeekdayNames = <String>[
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

class ClockTime extends Equatable {
  const ClockTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  int get totalMinutes => hour * 60 + minute;

  String get label {
    final String hh = hour.toString().padLeft(2, '0');
    final String mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String toApi() => '$label:00';

  factory ClockTime.parse(dynamic raw) {
    if (raw is ClockTime) {
      return raw;
    }
    final String text = (raw ?? '').toString().trim();
    final List<String> parts = text.split(':');
    if (parts.length < 2) {
      throw const FormatException('Invalid time.');
    }
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const FormatException('Invalid time.');
    }
    return ClockTime(hour: hour, minute: minute);
  }

  @override
  List<Object?> get props => <Object?>[hour, minute];
}

class SettingsLogoFile extends Equatable {
  const SettingsLogoFile({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;

  @override
  List<Object?> get props => <Object?>[path, name, size];
}

class CompanySettings extends Equatable {
  const CompanySettings({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.timezone,
    required this.workStartTime,
    required this.workEndTime,
    required this.gracePeriodMinutes,
    required this.minimumWorkingMinutes,
    required this.overtimeEnabled,
    required this.workingDays,
    this.logo,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String? logo;
  final String timezone;
  final ClockTime workStartTime;
  final ClockTime workEndTime;
  final int gracePeriodMinutes;
  final int minimumWorkingMinutes;
  final bool overtimeEnabled;
  final List<String> workingDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      id: _readString(json['id']),
      companyId: _readString(json['company_id']),
      companyName: _readString(json['company_name']),
      logo: _readOptionalString(json['logo']),
      timezone: _readString(json['timezone']),
      workStartTime: ClockTime.parse(json['work_start_time']),
      workEndTime: ClockTime.parse(json['work_end_time']),
      gracePeriodMinutes: _readInt(json['grace_period_minutes']),
      minimumWorkingMinutes: _readInt(json['minimum_working_minutes']),
      overtimeEnabled: json['overtime_enabled'] == true,
      workingDays: _readWorkingDays(json['working_days']),
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
    );
  }

  CompanySettings copyWith({
    String? id,
    String? companyId,
    String? companyName,
    String? logo,
    String? timezone,
    ClockTime? workStartTime,
    ClockTime? workEndTime,
    int? gracePeriodMinutes,
    int? minimumWorkingMinutes,
    bool? overtimeEnabled,
    List<String>? workingDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearLogo = false,
  }) {
    return CompanySettings(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      logo: clearLogo ? null : (logo ?? this.logo),
      timezone: timezone ?? this.timezone,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      minimumWorkingMinutes:
          minimumWorkingMinutes ?? this.minimumWorkingMinutes,
      overtimeEnabled: overtimeEnabled ?? this.overtimeEnabled,
      workingDays: workingDays ?? this.workingDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        companyName,
        logo,
        timezone,
        workStartTime,
        workEndTime,
        gracePeriodMinutes,
        minimumWorkingMinutes,
        overtimeEnabled,
        workingDays,
        createdAt,
        updatedAt,
      ];
}

class CompanySettingsPatch extends Equatable {
  const CompanySettingsPatch({
    this.companyName,
    this.timezone,
    this.workStartTime,
    this.workEndTime,
    this.gracePeriodMinutes,
    this.minimumWorkingMinutes,
    this.overtimeEnabled,
    this.workingDays,
    this.logo,
  });

  final String? companyName;
  final String? timezone;
  final ClockTime? workStartTime;
  final ClockTime? workEndTime;
  final int? gracePeriodMinutes;
  final int? minimumWorkingMinutes;
  final bool? overtimeEnabled;
  final List<String>? workingDays;
  final SettingsLogoFile? logo;

  bool get hasLogo => logo != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (companyName != null) 'company_name': companyName,
      if (timezone != null) 'timezone': timezone,
      if (workStartTime != null) 'work_start_time': workStartTime!.toApi(),
      if (workEndTime != null) 'work_end_time': workEndTime!.toApi(),
      if (gracePeriodMinutes != null)
        'grace_period_minutes': gracePeriodMinutes,
      if (minimumWorkingMinutes != null)
        'minimum_working_minutes': minimumWorkingMinutes,
      if (overtimeEnabled != null) 'overtime_enabled': overtimeEnabled,
      if (workingDays != null) 'working_days': workingDays,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        companyName,
        timezone,
        workStartTime,
        workEndTime,
        gracePeriodMinutes,
        minimumWorkingMinutes,
        overtimeEnabled,
        workingDays,
        logo,
      ];
}

String _readString(dynamic value) => (value ?? '').toString();

String? _readOptionalString(dynamic value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

List<String> _readWorkingDays(dynamic raw) {
  if (raw is! List) {
    return const <String>[];
  }
  final List<String> days = <String>[];
  for (final Object? item in raw) {
    if (item is int && item >= 0 && item < kWeekdayNames.length) {
      days.add(kWeekdayNames[item]);
      continue;
    }
    if (item is String) {
      final String key = item.trim().toLowerCase();
      if (kWeekdayNames.contains(key) && !days.contains(key)) {
        days.add(key);
      }
    }
  }
  return days;
}
