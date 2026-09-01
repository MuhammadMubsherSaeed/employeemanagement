from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from apps.accounts.models import UserRole
from apps.devices.models import DeviceStatus
from apps.reports.tests import (
    DEVICE_REPORT,
    ReportFixtureMixin,
    asset_codes,
    rows,
)


class DeviceReportTests(ReportFixtureMixin, TestCase):
    def setUp(self) -> None:
        self.bind(self.device_a, self.emp_a1)
        self.available = self.make_device(self.company_a, "LAPTOP-AVAIL")
        self.hr_device = self.make_device(self.company_a, "LAPTOP-HR")
        self.bind(self.hr_device, self.emp_a2)

    def test_admin_success_includes_cost(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(DEVICE_REPORT)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["message"], "Report generated successfully.")
        self.assertEqual(
            asset_codes(response),
            {"LAPTOP-001", "LAPTOP-AVAIL", "LAPTOP-HR"},
        )
        assigned = next(
            row for row in rows(response) if row["asset_code"] == "LAPTOP-001"
        )
        self.assertEqual(assigned["assigned_employee"]["employee_code"], "EMP-001")
        self.assertIn("cost", assigned)
        self.assertNotIn("notes", assigned)

    def test_status_employee_and_department_filters(self) -> None:
        client = self.authenticate(self.admin_a)
        available = client.get(DEVICE_REPORT, {"status": DeviceStatus.AVAILABLE})
        self.assertEqual(asset_codes(available), {"LAPTOP-AVAIL"})

        by_employee = client.get(DEVICE_REPORT, {"employee": str(self.emp_a1.id)})
        self.assertEqual(asset_codes(by_employee), {"LAPTOP-001"})

        by_dept = client.get(DEVICE_REPORT, {"department": str(self.dept_a_hr.id)})
        self.assertEqual(asset_codes(by_dept), {"LAPTOP-HR"})

        empty = client.get(DEVICE_REPORT, {"status": DeviceStatus.RETIRED})
        self.assertEqual(empty.json()["data"]["count"], 0)

    def test_pagination(self) -> None:
        for index in range(6):
            self.make_device(self.company_a, f"LAPTOP-P{index}")
        client = self.authenticate(self.admin_a)
        response = client.get(DEVICE_REPORT, {"page_size": 3, "page": 1})
        self.assertEqual(response.json()["data"]["count"], 9)
        self.assertEqual(len(rows(response)), 3)

    def test_manager_scope_hides_cost_and_other_team_devices(self) -> None:
        manager = self.authenticate(self.manager_a)
        response = manager.get(DEVICE_REPORT)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(asset_codes(response), {"LAPTOP-001", "LAPTOP-AVAIL"})
        for row in rows(response):
            self.assertNotIn("cost", row)
        bypass = manager.get(DEVICE_REPORT, {"employee": str(self.emp_a2.id)})
        self.assertEqual(bypass.json()["data"]["count"], 0)

    def test_employee_restriction(self) -> None:
        employee = self.authenticate(self.employee_a)
        self.assertEqual(employee.get(DEVICE_REPORT).status_code, 403)
        self.grant(self.roles[UserRole.EMPLOYEE], "reports.view")
        client = self.authenticate(self.employee_a)
        response = client.get(DEVICE_REPORT)
        self.assertEqual(asset_codes(response), {"LAPTOP-001"})
        self.assertNotIn("cost", rows(response)[0])
        other = client.get(DEVICE_REPORT, {"employee": str(self.emp_a2.id)})
        self.assertEqual(other.json()["data"]["count"], 0)

    def test_cross_company_isolation(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(DEVICE_REPORT, {"company_id": str(self.company_b.id)})
        self.assertNotIn("SN-B-001", {row["serial_number"] for row in rows(response)})
        other = self.authenticate(self.admin_b)
        body = other.get(DEVICE_REPORT)
        self.assertEqual(asset_codes(body), {"LAPTOP-001"})
        self.assertEqual(rows(body)[0]["serial_number"], "SN-B-001")

    def test_unauthenticated(self) -> None:
        self.assertEqual(APIClient().get(DEVICE_REPORT).status_code, 401)

    def test_query_count_does_not_grow_with_rows(self) -> None:
        client = self.authenticate(self.admin_a)
        with CaptureQueriesContext(connection) as first:
            first_response = client.get(DEVICE_REPORT)
        self.assertEqual(first_response.status_code, 200)
        for index in range(8):
            self.make_device(self.company_a, f"LAPTOP-Q{index}")
        with CaptureQueriesContext(connection) as second:
            second_response = client.get(DEVICE_REPORT)
        self.assertEqual(second_response.status_code, 200)
        self.assertEqual(len(first.captured_queries), len(second.captured_queries))
        self.assertLessEqual(len(second.captured_queries), 20)
