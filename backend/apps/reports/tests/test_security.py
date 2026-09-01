from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import UserRole
from apps.attendance.models import AttendanceStatus
from apps.reports.tests import (
    ATTENDANCE_EXPORT,
    ATTENDANCE_REPORT,
    DEVICE_EXPORT,
    DEVICE_REPORT,
    EMPLOYEE_EXPORT,
    EMPLOYEE_REPORT,
    LEAVE_EXPORT,
    LEAVE_REPORT,
    ReportFixtureMixin,
    TODAY,
    body_bytes,
    codes,
)


class ReportSecurityTests(ReportFixtureMixin, TestCase):
    def setUp(self) -> None:
        self.punch(self.emp_a1, TODAY, AttendanceStatus.PRESENT)
        self.punch(self.emp_a2, TODAY, AttendanceStatus.LATE)
        self.punch(self.emp_b1, TODAY, AttendanceStatus.PRESENT)
        self.pending_request(employee=self.emp_a1)
        self.pending_request(employee=self.emp_a2)
        self.bind(self.device_a, self.emp_a1)

    def test_company_a_cannot_read_company_b_reports(self) -> None:
        client = self.authenticate(self.admin_a)
        for path in (
            ATTENDANCE_REPORT,
            LEAVE_REPORT,
            EMPLOYEE_REPORT,
            DEVICE_REPORT,
        ):
            response = client.get(path, {"company_id": str(self.company_b.id)})
            self.assertEqual(response.status_code, 200, path)
            payload = str(response.json()["data"]["results"])
            self.assertNotIn("Bea", payload)
            self.assertNotIn("SN-B-001", payload)

    def test_company_a_manager_cannot_access_company_b_employee(self) -> None:
        client = self.authenticate(self.manager_a)
        response = client.get(
            ATTENDANCE_REPORT, {"employee": str(self.emp_b1.id)}
        )
        self.assertEqual(response.json()["data"]["count"], 0)
        directory = client.get(
            EMPLOYEE_REPORT, {"employee": str(self.emp_b1.id)}
        )
        self.assertEqual(directory.json()["data"]["count"], 0)

    def test_manager_cannot_bypass_team_scope_with_employee_param(self) -> None:
        client = self.authenticate(self.manager_a)
        response = client.get(
            ATTENDANCE_REPORT, {"employee": str(self.emp_a2.id)}
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["count"], 0)
        self.assertNotIn("EMP-002", codes(response))
        export_denied = client.get(
            ATTENDANCE_EXPORT, {"format": "csv", "employee": str(self.emp_a2.id)}
        )
        self.assertEqual(export_denied.status_code, 403)

    def test_employee_cannot_request_another_employee(self) -> None:
        self.grant(self.roles[UserRole.EMPLOYEE], "reports.view")
        client = self.authenticate(self.employee_a)
        response = client.get(
            ATTENDANCE_REPORT, {"employee": str(self.emp_a2.id)}
        )
        self.assertEqual(response.json()["data"]["count"], 0)
        directory = client.get(
            EMPLOYEE_REPORT, {"employee": str(self.emp_a2.id)}
        )
        self.assertEqual(directory.json()["data"]["count"], 0)

    def test_employee_cannot_export_company_wide_data(self) -> None:
        employee = self.authenticate(self.employee_a)
        for path in (
            ATTENDANCE_EXPORT,
            LEAVE_EXPORT,
            EMPLOYEE_EXPORT,
            DEVICE_EXPORT,
        ):
            self.assertEqual(employee.get(path).status_code, 403, path)
        self.grant(self.roles[UserRole.EMPLOYEE], "reports.export")
        client = self.authenticate(self.employee_a)
        csv_response = client.get(EMPLOYEE_EXPORT, {"format": "csv"})
        self.assertEqual(csv_response.status_code, 200)
        body = body_bytes(csv_response).decode()
        self.assertIn("EMP-001", body)
        self.assertNotIn("EMP-002", body)
        self.assertNotIn("EMP-ADMIN", body)

    def test_view_without_export_is_403(self) -> None:
        self.revoke(self.roles[UserRole.COMPANY_ADMIN], "reports.export")
        client = self.authenticate(self.admin_a)
        self.assertEqual(client.get(ATTENDANCE_REPORT).status_code, 200)
        self.assertEqual(client.get(ATTENDANCE_EXPORT, {"format": "csv"}).status_code, 403)

    def test_super_admin_and_unauthenticated(self) -> None:
        self.assertEqual(APIClient().get(ATTENDANCE_REPORT).status_code, 401)
        super_admin = self.authenticate(self.super_admin)
        self.assertEqual(super_admin.get(ATTENDANCE_REPORT).status_code, 403)
        self.assertEqual(super_admin.get(ATTENDANCE_EXPORT).status_code, 403)
        outsider = self.authenticate(self.no_company)
        self.assertEqual(outsider.get(EMPLOYEE_REPORT).status_code, 403)
