import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:flutter_base/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_base/features/attendance/domain/usecases/attendance_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final attendanceRemoteDataSourceProvider =
    Provider<AttendanceRemoteDataSource>((Ref ref) {
  return AttendanceRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((Ref ref) {
  return AttendanceRepositoryImpl(ref.watch(attendanceRemoteDataSourceProvider));
});

final getTodayAttendanceProvider = Provider<GetTodayAttendance>((Ref ref) {
  return GetTodayAttendance(ref.watch(attendanceRepositoryProvider));
});

final getAttendanceHistoryUseCaseProvider =
    Provider<GetAttendanceHistory>((Ref ref) {
  return GetAttendanceHistory(ref.watch(attendanceRepositoryProvider));
});

final getAttendanceDetailsProvider = Provider<GetAttendanceDetails>((Ref ref) {
  return GetAttendanceDetails(ref.watch(attendanceRepositoryProvider));
});

final getAttendanceSummaryUseCaseProvider =
    Provider<GetAttendanceSummary>((Ref ref) {
  return GetAttendanceSummary(ref.watch(attendanceRepositoryProvider));
});

final checkInUseCaseProvider = Provider<CheckIn>((Ref ref) {
  return CheckIn(ref.watch(attendanceRepositoryProvider));
});

final checkOutUseCaseProvider = Provider<CheckOut>((Ref ref) {
  return CheckOut(ref.watch(attendanceRepositoryProvider));
});

final attendanceDetailProvider =
    FutureProvider.autoDispose.family<AttendanceRecord, String>(
  (Ref ref, String id) {
    return ref.watch(getAttendanceDetailsProvider)(id);
  },
);

final attendanceSummaryProvider =
    FutureProvider.autoDispose.family<AttendanceSummary, AttendanceSummaryQuery>(
  (Ref ref, AttendanceSummaryQuery query) {
    return ref.watch(getAttendanceSummaryUseCaseProvider)(query);
  },
);
