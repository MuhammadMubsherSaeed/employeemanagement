import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/domain/repositories/attendance_repository.dart';

class GetTodayAttendance {
  const GetTodayAttendance(this._repository);

  final AttendanceRepository _repository;

  Future<AttendanceRecord?> call({DateTime? now}) {
    return _repository.getTodayAttendance(now: now);
  }
}

class GetAttendanceHistory {
  const GetAttendanceHistory(this._repository);

  final AttendanceRepository _repository;

  Future<AttendancePage<AttendanceRecord>> call(
    AttendanceQuery query, {
    required bool selfOnly,
  }) {
    if (selfOnly) {
      return _repository.getMyAttendance(
        query.copyWith(clearEmployee: true, clearDepartment: true),
      );
    }
    return _repository.getAttendanceHistory(query);
  }
}

class GetAttendanceDetails {
  const GetAttendanceDetails(this._repository);

  final AttendanceRepository _repository;

  Future<AttendanceRecord> call(String id) {
    return _repository.getAttendanceDetails(id);
  }
}

class GetAttendanceSummary {
  const GetAttendanceSummary(this._repository);

  final AttendanceRepository _repository;

  Future<AttendanceSummary> call(AttendanceSummaryQuery query) {
    return _repository.getAttendanceSummary(query);
  }
}

class CheckIn {
  const CheckIn(this._repository);

  final AttendanceRepository _repository;

  Future<AttendanceRecord> call({double? latitude, double? longitude}) {
    return _repository.checkIn(latitude: latitude, longitude: longitude);
  }
}

class CheckOut {
  const CheckOut(this._repository);

  final AttendanceRepository _repository;

  Future<AttendanceRecord> call({double? latitude, double? longitude}) {
    return _repository.checkOut(latitude: latitude, longitude: longitude);
  }
}
