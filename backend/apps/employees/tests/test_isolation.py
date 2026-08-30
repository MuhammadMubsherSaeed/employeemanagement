from django.test import TestCase

from apps.employees.models import Employee
from apps.employees.tests.fixtures import (
    DEPARTMENTS,
    EMPLOYEES,
    POSITIONS,
    EmployeeFixtureMixin,
    ids,
)


class TenantIsolationTests(EmployeeFixtureMixin, TestCase):
    def test_list_is_company_scoped(self) -> None:
        client_a = self.authenticate(self.admin_a)
        client_b = self.authenticate(self.admin_b)
        a_ids = ids(client_a.get(f"{EMPLOYEES}/"))
        b_ids = ids(client_b.get(f"{EMPLOYEES}/"))
        self.assertIn(str(self.emp_a1.id), a_ids)
        self.assertIn(str(self.emp_a2.id), a_ids)
        self.assertNotIn(str(self.emp_b1.id), a_ids)
        self.assertNotIn(str(self.emp_b2.id), a_ids)
        self.assertIn(str(self.emp_b1.id), b_ids)
        self.assertNotIn(str(self.emp_a1.id), b_ids)

    def test_idor_employee(self) -> None:
        client = self.authenticate(self.admin_a)
        url = f"{EMPLOYEES}/{self.emp_b1.id}/"
        self.assertEqual(client.get(url).status_code, 404)
        self.assertEqual(
            client.patch(url, {"first_name": "Hacked"}, format="json").status_code,
            404,
        )
        self.assertEqual(client.delete(url).status_code, 404)
        self.assertTrue(Employee.objects.filter(pk=self.emp_b1.pk).exists())
        self.emp_b1.refresh_from_db()
        self.assertEqual(self.emp_b1.first_name, "Bea")

    def test_idor_department_and_position(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assertEqual(
            client.get(f"{DEPARTMENTS}/{self.dept_b.id}/").status_code, 404
        )
        self.assertEqual(
            client.patch(
                f"{DEPARTMENTS}/{self.dept_b.id}/",
                {"name": "Stolen"},
                format="json",
            ).status_code,
            404,
        )
        self.assertEqual(
            client.delete(f"{DEPARTMENTS}/{self.dept_b.id}/").status_code, 404
        )
        self.assertEqual(
            client.get(f"{POSITIONS}/{self.pos_b.id}/").status_code, 404
        )
        self.assertEqual(
            client.patch(
                f"{POSITIONS}/{self.pos_b.id}/",
                {"title": "Stolen"},
                format="json",
            ).status_code,
            404,
        )
        self.assertEqual(
            client.delete(f"{POSITIONS}/{self.pos_b.id}/").status_code, 404
        )

    def test_filter_cannot_reach_other_company(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(f"{EMPLOYEES}/?department={self.dept_b.id}")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(ids(response), set())

    def test_search_stays_in_tenant(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(f"{EMPLOYEES}/?search=EMP-001")
        found = ids(response)
        self.assertIn(str(self.emp_a1.id), found)
        self.assertNotIn(str(self.emp_b1.id), found)

    def test_search_by_email_and_name(self) -> None:
        client = self.authenticate(self.admin_a)
        by_email = client.get(f"{EMPLOYEES}/?search=employee-a@example.com")
        self.assertIn(str(self.emp_a1.id), ids(by_email))
        by_name = client.get(f"{EMPLOYEES}/?search=Nia")
        self.assertIn(str(self.emp_a2.id), ids(by_name))

    def test_ordering(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(f"{EMPLOYEES}/?ordering=employee_code")
        codes = [
            row["employee_code"] for row in response.json()["data"]["results"]
        ]
        self.assertEqual(codes, sorted(codes))

    def test_pagination(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(f"{EMPLOYEES}/?page_size=1")
        self.assertEqual(response.status_code, 200)
        payload = response.json()["data"]
        self.assertEqual(len(payload["results"]), 1)
        self.assertGreaterEqual(payload["count"], 4)

    def test_cross_company_relationships_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assertEqual(
            client.post(
                f"{EMPLOYEES}/",
                {
                    "employee_code": "EMP-XUSER",
                    "first_name": "Bad",
                    "last_name": "User",
                    "user": self.employee_b.id,
                },
                format="json",
            ).status_code,
            400,
        )
        self.assertEqual(
            client.patch(
                f"{EMPLOYEES}/{self.emp_a1.id}/",
                {"department": str(self.dept_b.id)},
                format="json",
            ).status_code,
            400,
        )
        self.assertEqual(
            client.patch(
                f"{EMPLOYEES}/{self.emp_a1.id}/",
                {"position": str(self.pos_b.id)},
                format="json",
            ).status_code,
            400,
        )
        self.assertEqual(
            client.patch(
                f"{EMPLOYEES}/{self.emp_a1.id}/",
                {"manager": str(self.emp_b1.id)},
                format="json",
            ).status_code,
            400,
        )
