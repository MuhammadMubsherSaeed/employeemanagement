import 'dart:async';

import 'package:flutter_base/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/domain/repositories/attendance_repository.dart';

AttendanceRecord sampleAttendance({
  String id = 'att-1',
  DateTime? date,
  AttendanceStatus status = AttendanceStatus.present,
  DateTime? checkIn,
  DateTime? checkOut,
  int? totalMinutes = 537,
  String? checkInIp,
  String? checkOutIp,
  double? checkInLatitude,
  double? checkInLongitude,
  double? checkOutLatitude,
  double? checkOutLongitude,
  String employeeId = 'emp-1',
}) {
  return AttendanceRecord(
    id: id,
    date: date ?? DateTime(2026, 8, 31),
    status: status,
    employee: AttendanceEmployeeRef(
      id: employeeId,
      employeeCode: 'EMP-001',
      firstName: 'Ada',
      lastName: 'Lovelace',
    ),
    checkIn: checkIn ?? DateTime.parse('2026-08-31T09:05:00+05:00'),
    checkOut: checkOut,
    totalMinutes: totalMinutes,
    checkInIp: checkInIp,
    checkOutIp: checkOutIp,
    checkInLatitude: checkInLatitude,
    checkInLongitude: checkInLongitude,
    checkOutLatitude: checkOutLatitude,
    checkOutLongitude: checkOutLongitude,
    createdAt: DateTime.parse('2026-08-31T09:05:00+05:00'),
  );
}

Map<String, dynamic> sampleAttendanceJson({
  String id = 'att-1',
  String date = '2026-08-31',
  String status = 'PRESENT',
  String? checkIn = '2026-08-31T09:05:00+05:00',
  String? checkOut,
  int totalMinutes = 537,
  bool sensitive = false,
}) {
  final Map<String, dynamic> json = <String, dynamic>{
    'id': id,
    'employee': <String, dynamic>{
      'id': 'emp-1',
      'employee_code': 'EMP-001',
      'first_name': 'Ada',
      'last_name': 'Lovelace',
    },
    'date': date,
    'check_in': checkIn,
    'check_out': checkOut,
    'total_minutes': totalMinutes,
    'status': status,
    'created_at': '2026-08-31T09:05:00+05:00',
  };
  if (sensitive) {
    json.addAll(<String, dynamic>{
      'updated_at': '2026-08-31T18:02:00+05:00',
      'check_in_ip': '203.0.113.10',
      'check_out_ip': '203.0.113.11',
      'check_in_latitude': 24.8607,
      'check_in_longitude': 67.0011,
      'check_out_latitude': 24.8608,
      'check_out_longitude': 67.0012,
    });
  }
  return json;
}

AttendanceSummary sampleSummary({
  DateTime? start,
  DateTime? end,
  int presentDays = 18,
  int absentDays = 2,
  int lateDays = 1,
  int halfDays = 1,
  int leaveDays = 1,
  int holidayDays = 1,
  int weekendDays = 8,
  int totalWorkingMinutes = 8640,
  int overtimeMinutes = 0,
}) {
  final DateTime startDate = start ?? DateTime(2026, 8, 1);
  final DateTime endDate = end ?? DateTime(2026, 8, 31);
  return AttendanceSummary(
    startDate: startDate,
    endDate: endDate,
    totalDays: presentDays +
        absentDays +
        lateDays +
        halfDays +
        leaveDays +
        holidayDays +
        weekendDays,
    presentDays: presentDays,
    absentDays: absentDays,
    lateDays: lateDays,
    halfDays: halfDays,
    leaveDays: leaveDays,
    holidayDays: holidayDays,
    weekendDays: weekendDays,
    totalWorkingMinutes: totalWorkingMinutes,
    overtimeMinutes: overtimeMinutes,
  );
}

Map<String, dynamic> sampleSummaryJson({
  String startDate = '2026-08-01',
  String endDate = '2026-08-31',
  int overtimeMinutes = 0,
}) {
  return <String, dynamic>{
    'start_date': startDate,
    'end_date': endDate,
    'employee_id': null,
    'total_days': 31,
    'present_days': 18,
    'absent_days': 2,
    'late_days': 1,
    'half_days': 1,
    'leave_days': 1,
    'holiday_days': 1,
    'weekend_days': 8,
    'total_working_minutes': 8640,
    'overtime_minutes': overtimeMinutes,
  };
}

class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository({
    AttendanceRecord? today,
    List<AttendanceRecord>? records,
    AttendanceSummary? summary,
  })  : todayRecord = today,
        records = records ?? <AttendanceRecord>[sampleAttendance()],
        summary = summary ?? sampleSummary();

  AttendanceRecord? todayRecord;
  List<AttendanceRecord> records;
  AttendanceSummary summary;
  Duration delay = Duration.zero;
  Object? todayError;
  Object? myError;
  Object? historyError;
  Object? detailError;
  Object? summaryError;
  Object? checkInError;
  Object? checkOutError;
  int todayCalls = 0;
  int myCalls = 0;
  int historyCalls = 0;
  int detailCalls = 0;
  int summaryCalls = 0;
  int checkInCalls = 0;
  int checkOutCalls = 0;
  final List<AttendanceQuery> myQueries = <AttendanceQuery>[];
  final List<AttendanceQuery> historyQueries = <AttendanceQuery>[];
  final List<AttendanceSummaryQuery> summaryQueries = <AttendanceSummaryQuery>[];
  String? lastDetailId;
  Completer<AttendanceRecord?>? todayHold;
  AttendancePage<AttendanceRecord> Function(AttendanceQuery query)? pageBuilder;

  @override
  Future<AttendanceRecord?> getTodayAttendance({DateTime? now}) async {
    todayCalls += 1;
    if (todayHold != null) {
      return todayHold!.future;
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (todayError != null) {
      throw todayError!;
    }
    return todayRecord;
  }

  @override
  Future<AttendancePage<AttendanceRecord>> getMyAttendance(
    AttendanceQuery query,
  ) async {
    myCalls += 1;
    myQueries.add(query);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (myError != null) {
      throw myError!;
    }
    if (pageBuilder != null) {
      return pageBuilder!(query);
    }
    return AttendancePage<AttendanceRecord>(
      results: records,
      count: records.length,
    );
  }

  @override
  Future<AttendancePage<AttendanceRecord>> getAttendanceHistory(
    AttendanceQuery query,
  ) async {
    historyCalls += 1;
    historyQueries.add(query);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (historyError != null) {
      throw historyError!;
    }
    if (pageBuilder != null) {
      return pageBuilder!(query);
    }
    return AttendancePage<AttendanceRecord>(
      results: records,
      count: records.length,
    );
  }

  @override
  Future<AttendanceRecord> getAttendanceDetails(String id) async {
    detailCalls += 1;
    lastDetailId = id;
    if (detailError != null) {
      throw detailError!;
    }
    return records.firstWhere(
      (AttendanceRecord item) => item.id == id,
      orElse: () => records.first,
    );
  }

  @override
  Future<AttendanceSummary> getAttendanceSummary(
    AttendanceSummaryQuery query,
  ) async {
    summaryCalls += 1;
    summaryQueries.add(query);
    if (summaryError != null) {
      throw summaryError!;
    }
    return summary;
  }

  @override
  Future<AttendanceRecord> checkIn({
    double? latitude,
    double? longitude,
  }) async {
    checkInCalls += 1;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (checkInError != null) {
      throw checkInError!;
    }
    todayRecord = sampleAttendance(
      checkOut: null,
      totalMinutes: null,
    );
    return todayRecord!;
  }

  @override
  Future<AttendanceRecord> checkOut({
    double? latitude,
    double? longitude,
  }) async {
    checkOutCalls += 1;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (checkOutError != null) {
      throw checkOutError!;
    }
    todayRecord = sampleAttendance(
      checkOut: DateTime.parse('2026-08-31T18:02:00+05:00'),
      totalMinutes: 537,
    );
    return todayRecord!;
  }
}

class FakeAttendanceRemote implements AttendanceRemoteDataSource {
  FakeAttendanceRemote({
    AttendancePage<AttendanceRecord>? page,
    this.record,
    this.summary,
  }) : page = page ??
            AttendancePage<AttendanceRecord>(
              results: <AttendanceRecord>[sampleAttendance()],
              count: 1,
            );

  AttendancePage<AttendanceRecord> page;
  AttendanceRecord? record;
  AttendanceSummary? summary;
  AttendanceQuery? lastQuery;
  CheckInOutBody? lastBody;
  String? lastId;
  int myCalls = 0;
  int historyCalls = 0;
  int checkInCalls = 0;
  int checkOutCalls = 0;
  Object? error;

  @override
  Future<AttendancePage<AttendanceRecord>> getMyAttendance(
    AttendanceQuery query,
  ) async {
    myCalls += 1;
    lastQuery = query;
    if (error != null) {
      throw error!;
    }
    return page;
  }

  @override
  Future<AttendancePage<AttendanceRecord>> getAttendanceHistory(
    AttendanceQuery query,
  ) async {
    historyCalls += 1;
    lastQuery = query;
    if (error != null) {
      throw error!;
    }
    return page;
  }

  @override
  Future<AttendanceRecord> getAttendanceById(String id) async {
    lastId = id;
    if (error != null) {
      throw error!;
    }
    return record ?? sampleAttendance(id: id);
  }

  @override
  Future<AttendanceSummary> getAttendanceSummary(
    AttendanceSummaryQuery query,
  ) async {
    if (error != null) {
      throw error!;
    }
    return summary ?? sampleSummary();
  }

  @override
  Future<AttendanceRecord> checkIn(CheckInOutBody body) async {
    checkInCalls += 1;
    lastBody = body;
    if (error != null) {
      throw error!;
    }
    return record ?? sampleAttendance(checkOut: null, totalMinutes: null);
  }

  @override
  Future<AttendanceRecord> checkOut(CheckInOutBody body) async {
    checkOutCalls += 1;
    lastBody = body;
    if (error != null) {
      throw error!;
    }
    return record ??
        sampleAttendance(
          checkOut: DateTime.parse('2026-08-31T18:02:00+05:00'),
        );
  }
}

