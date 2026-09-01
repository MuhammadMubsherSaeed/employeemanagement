import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:flutter_base/features/reports/data/repositories/report_repository_impl.dart';
import 'package:flutter_base/features/reports/domain/repositories/report_repository.dart';
import 'package:flutter_base/features/reports/domain/services/report_file_service.dart';
import 'package:flutter_base/features/reports/domain/usecases/report_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportRemoteDataSourceProvider =
    Provider<ReportRemoteDataSource>((Ref ref) {
  return ReportRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((Ref ref) {
  return ReportRepositoryImpl(ref.watch(reportRemoteDataSourceProvider));
});

final getAttendanceReportProvider = Provider<GetAttendanceReport>((Ref ref) {
  return GetAttendanceReport(ref.watch(reportRepositoryProvider));
});

final getLeaveReportProvider = Provider<GetLeaveReport>((Ref ref) {
  return GetLeaveReport(ref.watch(reportRepositoryProvider));
});

final getEmployeeReportProvider = Provider<GetEmployeeReport>((Ref ref) {
  return GetEmployeeReport(ref.watch(reportRepositoryProvider));
});

final getDeviceReportProvider = Provider<GetDeviceReport>((Ref ref) {
  return GetDeviceReport(ref.watch(reportRepositoryProvider));
});

final exportAttendanceReportProvider =
    Provider<ExportAttendanceReport>((Ref ref) {
  return ExportAttendanceReport(ref.watch(reportRepositoryProvider));
});

final exportLeaveReportProvider = Provider<ExportLeaveReport>((Ref ref) {
  return ExportLeaveReport(ref.watch(reportRepositoryProvider));
});

final exportEmployeeReportProvider = Provider<ExportEmployeeReport>((Ref ref) {
  return ExportEmployeeReport(ref.watch(reportRepositoryProvider));
});

final exportDeviceReportProvider = Provider<ExportDeviceReport>((Ref ref) {
  return ExportDeviceReport(ref.watch(reportRepositoryProvider));
});

final reportFileServiceProvider = Provider<ReportFileService>((Ref ref) {
  return const PathProviderReportFileService();
});
