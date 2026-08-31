import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';

abstract class AttendanceRepository {
  Future<AttendanceRecord?> getTodayAttendance({DateTime? now});

  Future<AttendancePage<AttendanceRecord>> getMyAttendance(AttendanceQuery query);

  Future<AttendancePage<AttendanceRecord>> getAttendanceHistory(
    AttendanceQuery query,
  );

  Future<AttendanceRecord> getAttendanceDetails(String id);

  Future<AttendanceSummary> getAttendanceSummary(AttendanceSummaryQuery query);

  Future<AttendanceRecord> checkIn({double? latitude, double? longitude});

  Future<AttendanceRecord> checkOut({double? latitude, double? longitude});
}
