from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import UserRole
from apps.attendance.models import AttendanceStatus
from apps.common.models import AuditEvent
from apps.leave.models import LeaveRequestStatus
from apps.reports.tests import (
    ATTENDANCE_EXPORT,
    ATTENDANCE_REPORT,
    DEVICE_EXPORT,
    EMPLOYEE_EXPORT,
    LEAVE_EXPORT,
    NEXT_DAY,
    ReportFixtureMixin,
    TODAY,
    body_bytes,
    filename_of,
)


class ReportExportTests(ReportFixtureMixin, TestCase):
    def setUp(self) -> None:
        self.punch(self.emp_a1, TODAY, AttendanceStatus.PRESENT)
        self.punch(self.emp_a2, TODAY, AttendanceStatus.LATE)
        self.punch(self.emp_b1, TODAY, AttendanceStatus.PRESENT)
        self.pending_request(employee=self.emp_a1)
        self.pending_request(
            employee=self.emp_a2,
            status=LeaveRequestStatus.APPROVED,
            start=NEXT_DAY,
            end=NEXT_DAY,
        )
        self.pending_request(
            employee=self.emp_b1,
            leave_type=self.type_b,
            company=self.company_b,
        )
        self.bind(self.device_a, self.emp_a1)
        self.make_device(self.company_a, "LAPTOP-AVAIL")

    def test_csv_xlsx_pdf_for_each_report(self) -> None:
        client = self.authenticate(self.admin_a)
        cases = (
            (ATTENDANCE_EXPORT, "attendance-report", b"Employee code"),
            (LEAVE_EXPORT, "leave-report", b"Leave type"),
            (EMPLOYEE_EXPORT, "employee-report", b"Employee code"),
            (DEVICE_EXPORT, "device-report", b"Asset code"),
        )
        for path, stem, csv_marker in cases:
            csv_response = client.get(path, {"format": "csv"})
            self.assertEqual(csv_response.status_code, 200, path)
            self.assertIn("text/csv", csv_response["Content-Type"])
            self.assertRegex(filename_of(csv_response), rf"^{stem}-\d{{4}}-\d{{2}}-\d{{2}}\.csv$")
            self.assertIn(csv_marker, body_bytes(csv_response))

            xlsx = client.get(path, {"format": "xlsx"})
            self.assertEqual(xlsx.status_code, 200, path)
            self.assertIn(
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                xlsx["Content-Type"],
            )
            self.assertRegex(filename_of(xlsx), rf"^{stem}-\d{{4}}-\d{{2}}-\d{{2}}\.xlsx$")
            self.assertTrue(body_bytes(xlsx).startswith(b"PK"))

            pdf = client.get(path, {"format": "pdf"})
            self.assertEqual(pdf.status_code, 200, path)
            self.assertIn("application/pdf", pdf["Content-Type"])
            self.assertRegex(filename_of(pdf), rf"^{stem}-\d{{4}}-\d{{2}}-\d{{2}}\.pdf$")
            pdf_body = body_bytes(pdf)
            self.assertTrue(pdf_body.startswith(b"%PDF"))
            self.assertGreater(len(pdf_body), 100)

    def test_export_applies_same_filters(self) -> None:
        client = self.authenticate(self.admin_a)
        csv_response = client.get(
            ATTENDANCE_EXPORT,
            {
                "format": "csv",
                "status": AttendanceStatus.LATE,
                "date_from": TODAY.isoformat(),
                "date_to": TODAY.isoformat(),
            },
        )
        body = body_bytes(csv_response).decode()
        self.assertIn("EMP-002", body)
        self.assertNotIn("EMP-001", body)

    def test_export_requires_reports_export(self) -> None:
        self.revoke(self.roles[UserRole.COMPANY_ADMIN], "reports.export")
        client = self.authenticate(self.admin_a)
        self.assertEqual(client.get(ATTENDANCE_REPORT).status_code, 200)
        self.assertEqual(client.get(ATTENDANCE_EXPORT).status_code, 403)
        manager = self.authenticate(self.manager_a)
        self.assertEqual(manager.get(ATTENDANCE_EXPORT).status_code, 403)
        employee = self.authenticate(self.employee_a)
        self.assertEqual(employee.get(ATTENDANCE_EXPORT).status_code, 403)
        self.assertEqual(APIClient().get(ATTENDANCE_EXPORT).status_code, 401)

    def test_manager_export_stays_team_scoped_when_granted(self) -> None:
        self.punch(self.emp_manager_a, TODAY, AttendanceStatus.PRESENT)
        self.grant(self.roles[UserRole.MANAGER], "reports.export")
        client = self.authenticate(self.manager_a)
        csv_response = client.get(ATTENDANCE_EXPORT, {"format": "csv"})
        self.assertEqual(csv_response.status_code, 200)
        body = body_bytes(csv_response).decode()
        self.assertIn("EMP-001", body)
        self.assertIn("EMP-MGR", body)
        self.assertNotIn("EMP-002", body)

    def test_employee_cannot_export_company_wide_data(self) -> None:
        self.grant(self.roles[UserRole.EMPLOYEE], "reports.export")
        client = self.authenticate(self.employee_a)
        csv_response = client.get(EMPLOYEE_EXPORT, {"format": "csv"})
        self.assertEqual(csv_response.status_code, 200)
        body = body_bytes(csv_response).decode()
        self.assertIn("EMP-001", body)
        self.assertNotIn("EMP-002", body)
        self.assertNotIn("EMP-ADMIN", body)

    def test_tenant_isolation_on_export(self) -> None:
        client = self.authenticate(self.admin_a)
        csv_response = client.get(
            ATTENDANCE_EXPORT,
            {"format": "csv", "company_id": str(self.company_b.id)},
        )
        body = body_bytes(csv_response).decode()
        self.assertNotIn("Bea", body)
        other = self.authenticate(self.admin_b)
        other_csv = other.get(ATTENDANCE_EXPORT, {"format": "csv"})
        other_body = body_bytes(other_csv).decode()
        self.assertIn("EMP-001", other_body)
        self.assertIn("Bea", other_body)

    def test_device_cost_not_exported_without_sensitive_permission(self) -> None:
        self.grant(self.roles[UserRole.MANAGER], "reports.export")
        manager = self.authenticate(self.manager_a)
        csv_response = manager.get(DEVICE_EXPORT, {"format": "csv"})
        self.assertEqual(csv_response.status_code, 200)
        self.assertNotIn(b"Cost", body_bytes(csv_response))
        admin = self.authenticate(self.admin_a)
        admin_csv = admin.get(DEVICE_EXPORT, {"format": "csv"})
        admin_body = body_bytes(admin_csv)
        self.assertIn(b"Cost", admin_body)
        self.assertIn(b"1299", admin_body)

    def test_attendance_export_omits_ip_fields(self) -> None:
        client = self.authenticate(self.admin_a)
        csv_response = client.get(ATTENDANCE_EXPORT, {"format": "csv"})
        header = body_bytes(csv_response).decode().splitlines()[0]
        self.assertNotIn("ip", header.lower())
        self.assertNotIn("latitude", header.lower())

    def test_export_is_audited(self) -> None:
        client = self.authenticate(self.admin_a)
        client.get(
            ATTENDANCE_EXPORT,
            {"format": "csv", "status": AttendanceStatus.LATE},
        )
        event = AuditEvent.objects.filter(action="report.exported").first()
        self.assertIsNotNone(event)
        self.assertEqual(event.actor_id, self.admin_a.id)
        self.assertEqual(event.company_id, self.company_a.id)
        self.assertEqual(event.resource_id, "attendance")
        self.assertEqual(event.metadata["format"], "csv")
        self.assertEqual(event.metadata["filters"]["status"], AttendanceStatus.LATE)

    def test_unsupported_format_and_pdf_row_cap(self) -> None:
        client = self.authenticate(self.admin_a)
        bad = client.get(ATTENDANCE_EXPORT, {"format": "exe"})
        self.assertEqual(bad.status_code, 400)
        with patch("apps.reports.services.export_service.PDF_MAX_ROWS", 1):
            self.punch(self.emp_manager_a, TODAY, AttendanceStatus.PRESENT)
            capped = client.get(ATTENDANCE_EXPORT, {"format": "pdf"})
        self.assertEqual(capped.status_code, 400)
        self.assertIn("format", capped.json()["errors"])

    def test_invalid_date_on_export(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(
            ATTENDANCE_EXPORT,
            {
                "format": "csv",
                "date_from": NEXT_DAY.isoformat(),
                "date_to": TODAY.isoformat(),
            },
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            response.json()["errors"]["date_from"],
            ["date_from cannot be after date_to."],
        )
