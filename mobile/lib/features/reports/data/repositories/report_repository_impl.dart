import 'package:flutter_base/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:flutter_base/features/reports/domain/entities/report_export.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/reports/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._remote);

  final ReportRemoteDataSource _remote;

  @override
  Future<ReportPage<AttendanceReportItem>> getAttendanceReport(
    ReportQuery query,
  ) {
    return _remote.getAttendanceReport(query);
  }

  @override
  Future<ReportPage<LeaveReportItem>> getLeaveReport(ReportQuery query) {
    return _remote.getLeaveReport(query);
  }

  @override
  Future<ReportPage<EmployeeReportItem>> getEmployeeReport(ReportQuery query) {
    return _remote.getEmployeeReport(query);
  }

  @override
  Future<ReportPage<DeviceReportItem>> getDeviceReport(ReportQuery query) {
    return _remote.getDeviceReport(query);
  }

  @override
  Future<ReportExportFile> exportAttendanceReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _remote.exportAttendanceReport(query, format);
  }

  @override
  Future<ReportExportFile> exportLeaveReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _remote.exportLeaveReport(query, format);
  }

  @override
  Future<ReportExportFile> exportEmployeeReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _remote.exportEmployeeReport(query, format);
  }

  @override
  Future<ReportExportFile> exportDeviceReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _remote.exportDeviceReport(query, format);
  }
}
