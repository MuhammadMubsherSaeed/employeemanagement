enum ReportKind {
  attendance,
  leaves,
  employees,
  devices;

  String get title => switch (this) {
        ReportKind.attendance => 'Attendance report',
        ReportKind.leaves => 'Leave report',
        ReportKind.employees => 'Employee report',
        ReportKind.devices => 'Device report',
      };

  String get emptyMessage => switch (this) {
        ReportKind.attendance => 'No attendance records found.',
        ReportKind.leaves => 'No leave records found.',
        ReportKind.employees => 'No employees found.',
        ReportKind.devices => 'No devices found.',
      };

  String get filenameStem => switch (this) {
        ReportKind.attendance => 'attendance-report',
        ReportKind.leaves => 'leave-report',
        ReportKind.employees => 'employee-report',
        ReportKind.devices => 'device-report',
      };

  bool get supportsDates =>
      this == ReportKind.attendance || this == ReportKind.leaves;

  bool get supportsLeaveType => this == ReportKind.leaves;

  bool get supportsEmploymentType => this == ReportKind.employees;

  bool get supportsSearch => true;
}

enum ReportExportFormat {
  csv('csv', 'CSV', 'text/csv'),
  xlsx(
    'xlsx',
    'Excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ),
  pdf('pdf', 'PDF', 'application/pdf');

  const ReportExportFormat(this.apiValue, this.label, this.mimeType);

  final String apiValue;
  final String label;
  final String mimeType;

  static ReportExportFormat fromApi(String? raw) {
    final String value = (raw ?? '').trim().toLowerCase();
    for (final ReportExportFormat item in ReportExportFormat.values) {
      if (item.apiValue == value) {
        return item;
      }
    }
    return ReportExportFormat.csv;
  }
}
