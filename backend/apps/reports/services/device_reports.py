from apps.common.tenancy import get_tenant_context
from apps.reports.services.scope import (
    active_assignment,
    can_see_device_cost,
    device_report_queryset,
)


class DeviceReportService:
    title = "Device report"
    filename_stem = "device-report"

    def queryset(self, request):
        return device_report_queryset(request)

    def columns(self, request):
        columns = [
            ("Asset code", lambda row: row.asset_code),
            ("Type", lambda row: row.type),
            ("Manufacturer", lambda row: row.manufacturer),
            ("Model", lambda row: row.model),
            ("Serial number", lambda row: row.serial_number or ""),
            ("Status", lambda row: row.status),
            (
                "Assigned employee",
                lambda row: _employee_label(active_assignment(row)),
            ),
            (
                "Assigned at",
                lambda row: _dt(_assignment_attr(row, "assigned_at")),
            ),
            (
                "Returned at",
                lambda row: _dt(_assignment_attr(row, "returned_at")),
            ),
        ]
        if can_see_device_cost(get_tenant_context(request)):
            columns.append(("Cost", lambda row: str(row.cost)))
        return tuple(columns)


def _assignment_attr(row, field: str):
    assignment = active_assignment(row)
    if assignment is None:
        return None
    return getattr(assignment, field)


def _employee_label(assignment) -> str:
    if assignment is None:
        return ""
    employee = assignment.employee
    return f"{employee.employee_code} {employee.first_name} {employee.last_name}".strip()


def _dt(value) -> str:
    return value.isoformat() if value is not None else ""
