from apps.reports.services.scope import leave_report_queryset


class LeaveReportService:
    title = "Leave report"
    filename_stem = "leave-report"

    def queryset(self, request):
        return leave_report_queryset(request)

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
            ("Leave type", lambda row: row.leave_type.name),
            ("Start date", lambda row: row.start_date.isoformat()),
            ("End date", lambda row: row.end_date.isoformat()),
            ("Total days", lambda row: row.total_days),
            ("Status", lambda row: row.status),
            (
                "Approved by",
                lambda row: row.approved_by.email if row.approved_by_id else "",
            ),
            ("Approved at", lambda row: _dt(row.approved_at)),
        )


def _dt(value) -> str:
    return value.isoformat() if value is not None else ""
