import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/domain/working_duration.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance_fakes.dart';

void main() {
  test('parses list payload from snake_case JSON', () {
    final AttendanceRecord record = AttendanceRecord.fromJson(
      sampleAttendanceJson(),
    );

    expect(record.id, 'att-1');
    expect(record.date, DateTime(2026, 8, 31));
    expect(record.status, AttendanceStatus.present);
    expect(record.employee?.fullName, 'Ada Lovelace');
    expect(record.checkIn, isNotNull);
    expect(record.checkOut, isNull);
    expect(record.totalMinutes, 537);
    expect(record.hasSensitiveLocation, isFalse);
    expect(record.punchState, PunchState.checkedIn);
  });

  test('parses authorized detail fields only when the API returns them', () {
    final AttendanceRecord record = AttendanceRecord.fromJson(
      sampleAttendanceJson(
        checkOut: '2026-08-31T18:02:00+05:00',
        sensitive: true,
      ),
    );

    expect(record.punchState, PunchState.checkedOut);
    expect(record.checkInIp, '203.0.113.10');
    expect(record.checkInLatitude, 24.8607);
    expect(record.hasSensitiveLocation, isTrue);
  });

  test('maps known statuses and keeps unknown values safe', () {
    expect(AttendanceStatus.fromApi('LATE'), AttendanceStatus.late);
    expect(AttendanceStatus.fromApi('HALF_DAY'), AttendanceStatus.halfDay);
    expect(AttendanceStatus.fromApi('WEEKEND'), AttendanceStatus.weekend);
    expect(AttendanceStatus.fromApi('FUTURE_STATUS'), AttendanceStatus.unknown);
    expect(AttendanceStatus.fromApi(null), AttendanceStatus.unknown);
  });

  test('formats total_minutes without recalculating from timestamps', () {
    expect(WorkingDuration.format(60), '1h 00m');
    expect(WorkingDuration.format(485), '8h 05m');
    expect(WorkingDuration.format(null), '—');
  });

  test('query parameters match the Django attendance filter contract', () {
    final AttendanceQuery query = AttendanceQuery(
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
      status: AttendanceStatus.late,
      employeeId: 'emp-9',
      page: 2,
    );

    expect(
      query.toQueryParameters(),
      <String, dynamic>{
        'start_date': '2026-08-01',
        'end_date': '2026-08-31',
        'status': 'LATE',
        'employee': 'emp-9',
        'ordering': '-date',
        'page': 2,
        'page_size': 20,
      },
    );
  });

  test('month helpers use DateTime instead of hardcoded lengths', () {
    expect(monthStart(DateTime(2024, 2, 15)), DateTime(2024, 2, 1));
    expect(monthEnd(DateTime(2024, 2, 15)), DateTime(2024, 2, 29));
    expect(monthEnd(DateTime(2025, 2, 1)), DateTime(2025, 2, 28));
    expect(formatDateParam(DateTime(2026, 8, 9)), '2026-08-09');
  });

  test('summary parses backend counts and overtime without recalculating', () {
    final AttendanceSummary summary = AttendanceSummary.fromJson(
      sampleSummaryJson(overtimeMinutes: 45),
    );
    expect(summary.presentDays, 18);
    expect(summary.absentDays, 2);
    expect(summary.lateDays, 1);
    expect(summary.halfDays, 1);
    expect(summary.leaveDays, 1);
    expect(summary.holidayDays, 1);
    expect(summary.weekendDays, 8);
    expect(summary.totalWorkingMinutes, 8640);
    expect(summary.overtimeMinutes, 45);
  });

  test('check-in body omits coordinates unless both are present', () {
    expect(const CheckInOutBody().toJson(), isEmpty);
    expect(const CheckInOutBody(latitude: 1.0).toJson(), isEmpty);
    expect(
      const CheckInOutBody(latitude: 24.86, longitude: 67.00).toJson(),
      <String, dynamic>{'latitude': 24.86, 'longitude': 67.00},
    );
  });
}
