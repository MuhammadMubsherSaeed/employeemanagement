import 'package:flutter_base/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._remote);

  final AttendanceRemoteDataSource _remote;

  @override
  Future<AttendanceRecord?> getTodayAttendance({DateTime? now}) async {
    final DateTime day = now ?? DateTime.now();
    final DateTime date = DateTime(day.year, day.month, day.day);
    final AttendancePage<AttendanceRecord> page = await _remote.getMyAttendance(
      AttendanceQuery(
        startDate: date,
        endDate: date,
        page: 1,
        pageSize: 5,
        ordering: '-check_in',
      ),
    );
    if (page.results.isEmpty) {
      return null;
    }
    return page.results.first;
  }

  @override
  Future<AttendancePage<AttendanceRecord>> getMyAttendance(
    AttendanceQuery query,
  ) {
    return _remote.getMyAttendance(query);
  }

  @override
  Future<AttendancePage<AttendanceRecord>> getAttendanceHistory(
    AttendanceQuery query,
  ) {
    return _remote.getAttendanceHistory(query);
  }

  @override
  Future<AttendanceRecord> getAttendanceDetails(String id) {
    return _remote.getAttendanceById(id);
  }

  @override
  Future<AttendanceSummary> getAttendanceSummary(AttendanceSummaryQuery query) {
    return _remote.getAttendanceSummary(query);
  }

  @override
  Future<AttendanceRecord> checkIn({double? latitude, double? longitude}) {
    return _remote.checkIn(
      CheckInOutBody(latitude: latitude, longitude: longitude),
    );
  }

  @override
  Future<AttendanceRecord> checkOut({double? latitude, double? longitude}) {
    return _remote.checkOut(
      CheckInOutBody(latitude: latitude, longitude: longitude),
    );
  }
}
