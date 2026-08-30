from django.test import TestCase

from apps.companies.models import CompanyMembership
from apps.companies.services import MembershipService
from apps.employees.models import Employee
from apps.employees.tests.fixtures import (
    DEPARTMENTS,
    EMPLOYEES,
    EmployeeFixtureMixin,
    ids,
)


class RolePermissionTests(EmployeeFixtureMixin, TestCase):
    def test_manager_sees_self_and_direct_reports_only(self) -> None:
        client = self.authenticate(self.manager_a)
        listed = ids(client.get(f"{EMPLOYEES}/"))
        self.assertIn(str(self.emp_manager_a.id), listed)
        self.assertIn(str(self.emp_a1.id), listed)
        self.assertNotIn(str(self.emp_a2.id), listed)
        self.assertNotIn(str(self.emp_b1.id), listed)

        own = client.get(f"{EMPLOYEES}/{self.emp_manager_a.id}/")
        report = client.get(f"{EMPLOYEES}/{self.emp_a1.id}/")
        other = client.get(f"{EMPLOYEES}/{self.emp_a2.id}/")
        foreign = client.get(f"{EMPLOYEES}/{self.emp_b1.id}/")
        self.assertEqual(own.status_code, 200)
        self.assertEqual(report.status_code, 200)
        self.assertEqual(report.json()["data"]["phone"], "222-2222")
        self.assertEqual(other.status_code, 404)
        self.assertEqual(foreign.status_code, 404)

        list_row = client.get(f"{EMPLOYEES}/").json()["data"]["results"][0]
        self.assertNotIn("phone", list_row)
        self.assertNotIn("address", list_row)

    def test_manager_cannot_update_unauthorized_or_delete(self) -> None:
        client = self.authenticate(self.manager_a)
        self.assertEqual(
            client.patch(
                f"{EMPLOYEES}/{self.emp_a2.id}/",
                {"first_name": "Nope"},
                format="json",
            ).status_code,
            404,
        )
        ok = client.patch(
            f"{EMPLOYEES}/{self.emp_a1.id}/",
            {"first_name": "Ada-Updated"},
            format="json",
        )
        self.assertEqual(ok.status_code, 200)
        self.assertEqual(
            client.delete(f"{EMPLOYEES}/{self.emp_a1.id}/").status_code, 403
        )
        self.assertEqual(
            client.post(f"{EMPLOYEES}/", {}, format="json").status_code,
            403,
        )
        self.assertEqual(
            client.patch(
                f"{DEPARTMENTS}/{self.dept_a.id}/",
                {"name": "Hacked Org"},
                format="json",
            ).status_code,
            403,
        )

    def test_employee_self_access_only(self) -> None:
        client = self.authenticate(self.employee_a)
        listed = ids(client.get(f"{EMPLOYEES}/"))
        self.assertEqual(listed, {str(self.emp_a1.id)})
        self.assertEqual(
            client.get(f"{EMPLOYEES}/{self.emp_a1.id}/").status_code, 200
        )
        self.assertEqual(
            client.get(f"{EMPLOYEES}/{self.emp_a2.id}/").status_code, 404
        )
        self.assertEqual(
            client.get(f"{EMPLOYEES}/{self.emp_b1.id}/").status_code, 404
        )
        self.assertEqual(
            client.patch(
                f"{EMPLOYEES}/{self.emp_a2.id}/",
                {"first_name": "Nope"},
                format="json",
            ).status_code,
            403,
        )
        self.assertEqual(
            client.delete(f"{EMPLOYEES}/{self.emp_a1.id}/").status_code, 403
        )
        self.assertEqual(
            client.post(
                f"{EMPLOYEES}/",
                {
                    "employee_code": "EMP-SELF",
                    "first_name": "X",
                    "last_name": "Y",
                    "manager": str(self.emp_a1.id),
                },
                format="json",
            ).status_code,
            403,
        )

    def test_employee_cannot_mutate_org(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.post(
                f"{DEPARTMENTS}/", {"name": "Secret"}, format="json"
            ).status_code,
            403,
        )

    def test_create_update_delete_permissions(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(client.get(f"{EMPLOYEES}/").status_code, 200)
        self.assertEqual(
            client.post(
                f"{EMPLOYEES}/",
                {"employee_code": "X", "first_name": "A", "last_name": "B"},
                format="json",
            ).status_code,
            403,
        )
        admin = self.authenticate(self.admin_a)
        self.assertEqual(admin.get(f"{EMPLOYEES}/").status_code, 200)

    def test_inactive_membership_denied(self) -> None:
        membership = CompanyMembership.objects.get(
            user=self.employee_a, company=self.company_a
        )
        MembershipService().deactivate(membership)
        client = self.authenticate(self.employee_a)
        self.assertEqual(client.get(f"{EMPLOYEES}/").status_code, 403)
        self.assertEqual(client.get(f"{EMPLOYEES}/me/").status_code, 403)

    def test_company_admin_cannot_access_other_company(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assertEqual(
            client.get(f"{EMPLOYEES}/{self.emp_b1.id}/").status_code, 404
        )
        self.assertTrue(Employee.objects.filter(pk=self.emp_b1.pk).exists())
