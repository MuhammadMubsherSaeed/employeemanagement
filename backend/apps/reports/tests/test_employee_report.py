from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from apps.accounts.models import UserRole
from apps.employees.models import Employee, EmployeeStatus, EmploymentType
from apps.reports.tests import (
    EMPLOYEE_REPORT,
    ReportFixtureMixin,
    employee_codes,
    rows,
)


class EmployeeReportTests(ReportFixtureMixin, TestCase):
    def test_admin_success_hides_profile_fields(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(EMPLOYEE_REPORT)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["message"], "Report generated successfully.")
        self.assertEqual(response.json()["data"]["count"], 4)
        first = rows(response)[0]
        self.assertIn("employee_code", first)
        self.assertIn("department", first)
        self.assertIn("position", first)
        self.assertIn("manager", first)
        self.assertIn("employment_type", first)
        self.assertIn("joining_date", first)
        self.assertNotIn("phone", first)
        self.assertNotIn("address", first)
        self.assertNotIn("date_of_birth", first)
        self.assertNotIn("emergency_contact_name", first)
        self.assertEqual(
            employee_codes(response),
            {"EMP-ADMIN", "EMP-MGR", "EMP-001", "EMP-002"},
        )

    def test_department_status_and_employment_type_filters(self) -> None:
        Employee.objects.create(
            company=self.company_a,
            employee_code="EMP-CONT",
            first_name="Cora",
            last_name="Contract",
            department=self.dept_a,
            position=self.pos_a,
            employment_type=EmploymentType.CONTRACT,
            status=EmployeeStatus.INACTIVE,
        )
        client = self.authenticate(self.admin_a)
        by_dept = client.get(EMPLOYEE_REPORT, {"department": str(self.dept_a_hr.id)})
        self.assertEqual(employee_codes(by_dept), {"EMP-002"})

        by_status = client.get(EMPLOYEE_REPORT, {"status": EmployeeStatus.INACTIVE})
        self.assertEqual(employee_codes(by_status), {"EMP-CONT"})

        by_type = client.get(
            EMPLOYEE_REPORT, {"employment_type": EmploymentType.CONTRACT}
        )
        self.assertEqual(employee_codes(by_type), {"EMP-CONT"})

        by_employee = client.get(EMPLOYEE_REPORT, {"employee": str(self.emp_a1.id)})
        self.assertEqual(employee_codes(by_employee), {"EMP-001"})

    def test_pagination_and_empty(self) -> None:
        client = self.authenticate(self.admin_a)
        paged = client.get(EMPLOYEE_REPORT, {"page_size": 2, "page": 1})
        self.assertEqual(paged.json()["data"]["count"], 4)
        self.assertEqual(len(rows(paged)), 2)
        empty = client.get(EMPLOYEE_REPORT, {"status": EmployeeStatus.TERMINATED})
        self.assertEqual(empty.json()["data"]["count"], 0)

    def test_manager_and_employee_restrictions(self) -> None:
        manager = self.authenticate(self.manager_a)
        response = manager.get(EMPLOYEE_REPORT)
        self.assertEqual(employee_codes(response), {"EMP-MGR", "EMP-001"})
        bypass = manager.get(EMPLOYEE_REPORT, {"employee": str(self.emp_a2.id)})
        self.assertEqual(bypass.json()["data"]["count"], 0)
        employee = self.authenticate(self.employee_a)
        self.assertEqual(employee.get(EMPLOYEE_REPORT).status_code, 403)

    def test_employee_self_scope_when_permission_granted(self) -> None:
        self.grant(self.roles[UserRole.EMPLOYEE], "reports.view")
        client = self.authenticate(self.employee_a)
        response = client.get(EMPLOYEE_REPORT)
        self.assertEqual(employee_codes(response), {"EMP-001"})
        other = client.get(EMPLOYEE_REPORT, {"employee": str(self.emp_a2.id)})
        self.assertEqual(other.json()["data"]["count"], 0)

    def test_cross_company_isolation(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(
            EMPLOYEE_REPORT, {"company_id": str(self.company_b.id)}
        )
        self.assertNotIn("Bea", {row["first_name"] for row in rows(response)})
        other = self.authenticate(self.admin_b)
        names = {row["first_name"] for row in rows(other.get(EMPLOYEE_REPORT))}
        self.assertIn("Bea", names)
        self.assertNotIn("Ada", names)

    def test_unauthenticated(self) -> None:
        self.assertEqual(APIClient().get(EMPLOYEE_REPORT).status_code, 401)

    def test_query_count_does_not_grow_with_rows(self) -> None:
        client = self.authenticate(self.admin_a)
        with CaptureQueriesContext(connection) as first:
            first_response = client.get(EMPLOYEE_REPORT)
        self.assertEqual(first_response.status_code, 200)
        for index in range(8):
            Employee.objects.create(
                company=self.company_a,
                employee_code=f"EMP-Q{index:02d}",
                first_name="Query",
                last_name=str(index),
                department=self.dept_a,
                position=self.pos_a,
            )
        with CaptureQueriesContext(connection) as second:
            second_response = client.get(EMPLOYEE_REPORT)
        self.assertEqual(second_response.status_code, 200)
        self.assertEqual(len(first.captured_queries), len(second.captured_queries))
        self.assertLessEqual(len(second.captured_queries), 20)
