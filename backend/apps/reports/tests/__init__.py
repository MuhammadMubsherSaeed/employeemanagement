from datetime import date, timedelta
import re

from apps.attendance.models import Attendance, AttendanceStatus
from apps.attendance.tests.fixtures import ON_TIME
from apps.dashboard.tests import DashboardFixtureMixin
from apps.employees.tests.fixtures import ids as result_ids
from apps.leave.tests.fixtures import TODAY

ATTENDANCE_REPORT = "/api/v1/reports/attendance/"
LEAVE_REPORT = "/api/v1/reports/leaves/"
EMPLOYEE_REPORT = "/api/v1/reports/employees/"
DEVICE_REPORT = "/api/v1/reports/devices/"
ATTENDANCE_EXPORT = "/api/v1/reports/attendance/export/"
LEAVE_EXPORT = "/api/v1/reports/leaves/export/"
EMPLOYEE_EXPORT = "/api/v1/reports/employees/export/"
DEVICE_EXPORT = "/api/v1/reports/devices/export/"
NEXT_DAY = TODAY + timedelta(days=1)
LATER = date(2026, 4, 1)


class ReportFixtureMixin(DashboardFixtureMixin):
    def punch(
        self,
        employee,
        on_date=TODAY,
        status=AttendanceStatus.PRESENT,
        check_in=ON_TIME,
        company=None,
        **kwargs,
    ) -> Attendance:
        return Attendance.objects.create(
            company=company or employee.company,
            employee=employee,
            date=on_date,
            check_in=check_in,
            status=status,
            **kwargs,
        )

    def grant(self, role, code: str) -> None:
        from apps.accounts.models import Permission

        role.permissions.add(Permission.objects.get(code=code))

    def revoke(self, role, code: str) -> None:
        from apps.accounts.models import Permission

        role.permissions.remove(Permission.objects.get(code=code))


def rows(response) -> list[dict]:
    payload = response.json()["data"]
    return payload["results"] if isinstance(payload, dict) else payload


def codes(response) -> set[str]:
    return {row["employee"]["employee_code"] for row in rows(response)}


def employee_codes(response) -> set[str]:
    return {row["employee_code"] for row in rows(response)}


def asset_codes(response) -> set[str]:
    return {row["asset_code"] for row in rows(response)}


def filename_of(response) -> str:
    header = response.get("Content-Disposition", "")
    match = re.search(r'filename="([^"]+)"', header)
    if match:
        return match.group(1)
    match = re.search(r"filename=([^;]+)", header)
    return match.group(1).strip().strip("'") if match else header


def body_bytes(response) -> bytes:
    if getattr(response, "streaming", False):
        return b"".join(response.streaming_content)
    return response.content


__all__ = [
    "ATTENDANCE_EXPORT",
    "ATTENDANCE_REPORT",
    "DEVICE_EXPORT",
    "DEVICE_REPORT",
    "EMPLOYEE_EXPORT",
    "EMPLOYEE_REPORT",
    "LEAVE_EXPORT",
    "LEAVE_REPORT",
    "LATER",
    "NEXT_DAY",
    "ReportFixtureMixin",
    "TODAY",
    "asset_codes",
    "body_bytes",
    "codes",
    "employee_codes",
    "filename_of",
    "result_ids",
    "rows",
]
