from datetime import timedelta

from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from apps.accounts.models import UserRole
from apps.leave.models import LeaveRequestStatus
from apps.reports.tests import (
    LATER,
    LEAVE_REPORT,
    NEXT_DAY,
    ReportFixtureMixin,
    TODAY,
    codes,
    rows,
)


class LeaveReportTests(ReportFixtureMixin, TestCase):
    def setUp(self) -> None:
        self.req_a1 = self.pending_request(
            employee=self.emp_a1,
            start=TODAY,
            end=NEXT_DAY,
            total_days=2,
        )
        self.req_a2 = self.pending_request(
            employee=self.emp_a2,
            status=LeaveRequestStatus.APPROVED,
            start=LATER,
            end=LATER,
        )
        self.req_mgr = self.pending_request(
            employee=self.emp_manager_a,
            status=LeaveRequestStatus.REJECTED,
        )
        self.req_b1 = self.pending_request(
            employee=self.emp_b1,
            leave_type=self.type_b,
            company=self.company_b,
        )

    def test_admin_success_hides_reason(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(LEAVE_REPORT)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["message"], "Report generated successfully.")
        self.assertEqual(response.json()["data"]["count"], 3)
        first = rows(response)[0]
        self.assertIn("leave_type", first)
        self.assertIn("total_days", first)
        self.assertIn("approved_by", first)
        self.assertNotIn("reason", first)
        self.assertNotIn("attachment", first)
        self.assertNotIn("rejection_reason", first)
        self.assertEqual(codes(response), {"EMP-001", "EMP-002", "EMP-MGR"})

    def test_date_employee_department_and_status_filters(self) -> None:
        client = self.authenticate(self.admin_a)
        overlapping = client.get(
            LEAVE_REPORT,
            {"date_from": NEXT_DAY.isoformat(), "date_to": NEXT_DAY.isoformat()},
        )
        self.assertEqual(codes(overlapping), {"EMP-001"})

        by_employee = client.get(LEAVE_REPORT, {"employee": str(self.emp_a2.id)})
        self.assertEqual(codes(by_employee), {"EMP-002"})

        by_dept = client.get(LEAVE_REPORT, {"department": str(self.dept_a_hr.id)})
        self.assertEqual(codes(by_dept), {"EMP-002"})

        by_status = client.get(LEAVE_REPORT, {"status": LeaveRequestStatus.APPROVED})
        self.assertEqual(codes(by_status), {"EMP-002"})

        empty = client.get(
            LEAVE_REPORT,
            {
                "date_from": (LATER + timedelta(days=5)).isoformat(),
                "date_to": (LATER + timedelta(days=6)).isoformat(),
            },
        )
        self.assertEqual(empty.json()["data"]["count"], 0)

    def test_pagination(self) -> None:
        for index in range(8):
            self.pending_request(
                employee=self.emp_admin_a,
                start=LATER + timedelta(days=index + 1),
                end=LATER + timedelta(days=index + 1),
            )
        client = self.authenticate(self.admin_a)
        response = client.get(LEAVE_REPORT, {"page_size": 5, "page": 1})
        self.assertEqual(response.json()["data"]["count"], 11)
        self.assertEqual(len(rows(response)), 5)

    def test_manager_scope_and_employee_restriction(self) -> None:
        manager = self.authenticate(self.manager_a)
        response = manager.get(LEAVE_REPORT)
        self.assertEqual(codes(response), {"EMP-001", "EMP-MGR"})
        bypass = manager.get(LEAVE_REPORT, {"employee": str(self.emp_a2.id)})
        self.assertEqual(bypass.json()["data"]["count"], 0)
        employee = self.authenticate(self.employee_a)
        self.assertEqual(employee.get(LEAVE_REPORT).status_code, 403)

    def test_cross_company_isolation(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(LEAVE_REPORT, {"company_id": str(self.company_b.id)})
        self.assertEqual(codes(response), {"EMP-001", "EMP-002", "EMP-MGR"})
        other = self.authenticate(self.admin_b)
        body = other.get(LEAVE_REPORT)
        self.assertEqual(codes(body), {"EMP-001"})

    def test_unauthorized_and_invalid_dates(self) -> None:
        self.assertEqual(APIClient().get(LEAVE_REPORT).status_code, 401)
        client = self.authenticate(self.admin_a)
        inverted = client.get(
            LEAVE_REPORT,
            {"date_from": NEXT_DAY.isoformat(), "date_to": TODAY.isoformat()},
        )
        self.assertEqual(inverted.status_code, 400)
        self.assertEqual(
            inverted.json()["errors"]["date_from"],
            ["date_from cannot be after date_to."],
        )

    def test_query_count_does_not_grow_with_rows(self) -> None:
        client = self.authenticate(self.admin_a)
        with CaptureQueriesContext(connection) as first:
            first_response = client.get(LEAVE_REPORT)
        self.assertEqual(first_response.status_code, 200)
        for index in range(8):
            self.pending_request(
                employee=self.emp_admin_a,
                start=LATER + timedelta(days=index + 10),
                end=LATER + timedelta(days=index + 10),
            )
        with CaptureQueriesContext(connection) as second:
            second_response = client.get(LEAVE_REPORT)
        self.assertEqual(second_response.status_code, 200)
        self.assertEqual(len(first.captured_queries), len(second.captured_queries))
        self.assertLessEqual(len(second.captured_queries), 20)
