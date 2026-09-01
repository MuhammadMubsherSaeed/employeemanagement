import 'package:flutter_base/features/reports/domain/entities/report_export.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/reports/domain/repositories/report_repository.dart';

class GetAttendanceReport {
  const GetAttendanceReport(this._repository);

  final ReportRepository _repository;

  Future<ReportPage<AttendanceReportItem>> call(ReportQuery query) {
    return _repository.getAttendanceReport(query);
  }
}

class GetLeaveReport {
  const GetLeaveReport(this._repository);

  final ReportRepository _repository;

  Future<ReportPage<LeaveReportItem>> call(ReportQuery query) {
    return _repository.getLeaveReport(query);
  }
}

class GetEmployeeReport {
  const GetEmployeeReport(this._repository);

  final ReportRepository _repository;

  Future<ReportPage<EmployeeReportItem>> call(ReportQuery query) {
    return _repository.getEmployeeReport(query);
  }
}

class GetDeviceReport {
  const GetDeviceReport(this._repository);

  final ReportRepository _repository;

  Future<ReportPage<DeviceReportItem>> call(ReportQuery query) {
    return _repository.getDeviceReport(query);
  }
}

class ExportAttendanceReport {
  const ExportAttendanceReport(this._repository);

  final ReportRepository _repository;

  Future<ReportExportFile> call(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _repository.exportAttendanceReport(query, format);
  }
}

class ExportLeaveReport {
  const ExportLeaveReport(this._repository);

  final ReportRepository _repository;

  Future<ReportExportFile> call(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _repository.exportLeaveReport(query, format);
  }
}

class ExportEmployeeReport {
  const ExportEmployeeReport(this._repository);

  final ReportRepository _repository;

  Future<ReportExportFile> call(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _repository.exportEmployeeReport(query, format);
  }
}

class ExportDeviceReport {
  const ExportDeviceReport(this._repository);

  final ReportRepository _repository;

  Future<ReportExportFile> call(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _repository.exportDeviceReport(query, format);
  }
}
