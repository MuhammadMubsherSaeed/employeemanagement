import 'package:flutter_base/features/reports/domain/entities/report_export.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';

abstract class ReportRepository {
  Future<ReportPage<AttendanceReportItem>> getAttendanceReport(ReportQuery query);

  Future<ReportPage<LeaveReportItem>> getLeaveReport(ReportQuery query);

  Future<ReportPage<EmployeeReportItem>> getEmployeeReport(ReportQuery query);

  Future<ReportPage<DeviceReportItem>> getDeviceReport(ReportQuery query);

  Future<ReportExportFile> exportAttendanceReport(
    ReportQuery query,
    ReportExportFormat format,
  );

  Future<ReportExportFile> exportLeaveReport(
    ReportQuery query,
    ReportExportFormat format,
  );

  Future<ReportExportFile> exportEmployeeReport(
    ReportQuery query,
    ReportExportFormat format,
  );

  Future<ReportExportFile> exportDeviceReport(
    ReportQuery query,
    ReportExportFormat format,
  );
}
