from apps.reports.services.scope import employee_report_queryset


class EmployeeReportService:
    title = "Employee report"
    filename_stem = "employee-report"

    def queryset(self, request):
        return employee_report_queryset(request)

    def columns(self):
        return (
            ("Employee code", lambda row: row.employee_code),
            ("First name", lambda row: row.first_name),
            ("Last name", lambda row: row.last_name),
            (
                "Department",
                lambda row: row.department.name if row.department_id else "",
            ),
            ("Position", lambda row: row.position.title if row.position_id else ""),
            ("Employment type", lambda row: row.employment_type),
            (
                "Joining date",
                lambda row: row.joining_date.isoformat() if row.joining_date else "",
            ),
            ("Status", lambda row: row.status),
            (
                "Manager",
                lambda row: (
                    f"{row.manager.first_name} {row.manager.last_name}".strip()
                    if row.manager_id
                    else ""
                ),
            ),
        )
