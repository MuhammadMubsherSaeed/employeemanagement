from apps.reports.services.scope import attendance_report_queryset


class AttendanceReportService:
    title = "Attendance report"
    filename_stem = "attendance-report"

    def queryset(self, request):
        return attendance_report_queryset(request)

    def columns(self):
        return (
            ("Employee code", lambda row: row.employee.employee_code),
            ("First name", lambda row: row.employee.first_name),
            ("Last name", lambda row: row.employee.last_name),
            (
                "Department",
                lambda row: (
                    row.employee.department.name if row.employee.department_id else ""
                ),
            ),
            ("Date", lambda row: row.date.isoformat() if row.date else ""),
            ("Check in", lambda row: _dt(row.check_in)),
            ("Check out", lambda row: _dt(row.check_out)),
            ("Working minutes", lambda row: row.total_minutes or 0),
            ("Status", lambda row: row.status),
        )


def _dt(value) -> str:
    return value.isoformat() if value is not None else ""
