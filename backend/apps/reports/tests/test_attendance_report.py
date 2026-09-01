from datetime import timedelta

from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from apps.accounts.models import UserRole
from apps.attendance.models import AttendanceStatus
from apps.employees.tests.fixtures import ids
from apps.reports.tests import (
    ATTENDANCE_REPORT,
    LATER,
    NEXT_DAY,
    ReportFixtureMixin,
    TODAY,
    codes,
    rows,
)


class AttendanceReportTests(ReportFixtureMixin, TestCase):
    def setUp(self) -> None:
        self.punch(self.emp_a1, TODAY, AttendanceStatus.PRESENT)
        self.punch(self.emp_a2, TODAY, AttendanceStatus.LATE)
        self.punch(self.emp_manager_a, TODAY, AttendanceStatus.PRESENT)
        self.punch(self.emp_a1, NEXT_DAY, AttendanceStatus.HALF_DAY)
        self.punch(self.emp_b1, TODAY, AttendanceStatus.PRESENT)

    def test_admin_success_and_empty_sensitive_fields(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(ATTENDANCE_REPORT)
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["message"], "Report generated successfully.")
        self.assertEqual(body["data"]["count"], 4)
        first = rows(response)[0]
        self.assertIn("working_minutes", first)
        self.assertIn("employee", first)
        self.assertIn("department", first["employee"])
        self.assertNotIn("check_in_ip", first)
        self.assertNotIn("check_in_latitude", first)
        self.assertEqual(codes(response), {"EMP-001", "EMP-002", "EMP-MGR"})

    def test_date_employee_department_and_status_filters(self) -> None:
        client = self.authenticate(self.admin_a)
        by_date = client.get(
            ATTENDANCE_REPORT,
            {"date_from": NEXT_DAY.isoformat(), "date_to": NEXT_DAY.isoformat()},
        )
        self.assertEqual(by_date.status_code, 200)
        self.assertEqual(by_date.json()["data"]["count"], 1)
        self.assertEqual(codes(by_date), {"EMP-001"})

        by_employee = client.get(
            ATTENDANCE_REPORT, {"employee": str(self.emp_a2.id)}
        )
        self.assertEqual(codes(by_employee), {"EMP-002"})

        by_dept = client.get(
            ATTENDANCE_REPORT, {"department": str(self.dept_a_hr.id)}
        )
        self.assertEqual(codes(by_dept), {"EMP-002"})

        by_status = client.get(ATTENDANCE_REPORT, {"status": AttendanceStatus.LATE})
        self.assertEqual(codes(by_status), {"EMP-002"})

        empty = client.get(
            ATTENDANCE_REPORT,
            {"date_from": LATER.isoformat(), "date_to": LATER.isoformat()},
        )
        self.assertEqual(empty.json()["data"]["count"], 0)
        self.assertEqual(rows(empty), [])

    def test_pagination_and_large_queryset(self) -> None:
        for index in range(12):
            self.punch(
                self.emp_admin_a,
                TODAY + timedelta(days=index + 2),
                AttendanceStatus.PRESENT,
            )
        client = self.authenticate(self.admin_a)
        response = client.get(ATTENDANCE_REPORT, {"page_size": 5, "page": 2})
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["count"], 16)
        self.assertEqual(len(data["results"]), 5)
        self.assertIsNotNone(data["next"])
        self.assertIsNotNone(data["previous"])

    def test_manager_scope_and_employee_restriction(self) -> None:
        manager = self.authenticate(self.manager_a)
        response = manager.get(ATTENDANCE_REPORT)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(codes(response), {"EMP-001", "EMP-MGR"})
        bypass = manager.get(ATTENDANCE_REPORT, {"employee": str(self.emp_a2.id)})
        self.assertEqual(bypass.json()["data"]["count"], 0)

        employee = self.authenticate(self.employee_a)
        self.assertEqual(employee.get(ATTENDANCE_REPORT).status_code, 403)

    def test_employee_self_scope_when_permission_granted(self) -> None:
        self.grant(self.roles[UserRole.EMPLOYEE], "reports.view")
        client = self.authenticate(self.employee_a)
        response = client.get(ATTENDANCE_REPORT)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(codes(response), {"EMP-001"})
        other = client.get(ATTENDANCE_REPORT, {"employee": str(self.emp_a2.id)})
        self.assertEqual(other.json()["data"]["count"], 0)

    def test_cross_company_isolation_and_company_id_ignored(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(
            ATTENDANCE_REPORT, {"company_id": str(self.company_b.id)}
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(codes(response), {"EMP-001", "EMP-002", "EMP-MGR"})
        other_employee = client.get(
            ATTENDANCE_REPORT, {"employee": str(self.emp_b1.id)}
        )
        self.assertEqual(other_employee.json()["data"]["count"], 0)

        other = self.authenticate(self.admin_b)
        body = other.get(ATTENDANCE_REPORT)
        self.assertEqual(codes(body), {"EMP-001"})
        self.assertEqual(rows(body)[0]["employee"]["first_name"], "Bea")

    def test_unauthenticated_and_invalid_dates(self) -> None:
        self.assertEqual(APIClient().get(ATTENDANCE_REPORT).status_code, 401)
        client = self.authenticate(self.admin_a)
        inverted = client.get(
            ATTENDANCE_REPORT,
            {"date_from": NEXT_DAY.isoformat(), "date_to": TODAY.isoformat()},
        )
        self.assertEqual(inverted.status_code, 400)
        body = inverted.json()
        self.assertFalse(body["success"])
        self.assertEqual(body["message"], "Validation failed.")
        self.assertEqual(
            body["errors"]["date_from"],
            ["date_from cannot be after date_to."],
        )
        invalid = client.get(ATTENDANCE_REPORT, {"date_from": "not-a-date"})
        self.assertEqual(invalid.status_code, 400)
        self.assertIn("date_from", invalid.json()["errors"])

    def test_query_count_does_not_grow_with_rows(self) -> None:
        client = self.authenticate(self.admin_a)
        with CaptureQueriesContext(connection) as first:
            first_response = client.get(ATTENDANCE_REPORT)
        self.assertEqual(first_response.status_code, 200)
        for index in range(8):
            self.punch(
                self.emp_admin_a,
                LATER + timedelta(days=index),
                AttendanceStatus.PRESENT,
            )
        with CaptureQueriesContext(connection) as second:
            second_response = client.get(ATTENDANCE_REPORT)
        self.assertEqual(second_response.status_code, 200)
        self.assertEqual(len(first.captured_queries), len(second.captured_queries))
        self.assertLessEqual(len(second.captured_queries), 20)
        self.assertEqual(
            {row["id"] for row in rows(first_response)}.issubset(
                ids(second_response)
            ),
            True,
        )
