from django.contrib.auth import get_user_model
from django.test import TestCase

from apps.accounts.models import UserRole
from apps.companies.services import MembershipService
from apps.companies.tests.fixtures import PASSWORD
from apps.employees.models import Employee, EmployeeStatus, EmploymentType
from apps.employees.tests.fixtures import (
    EMPLOYEES,
    EmployeeFixtureMixin,
    ids,
)

User = get_user_model()


class EmployeeCRUDTests(EmployeeFixtureMixin, TestCase):
    def test_company_admin_creates_lists_retrieves_updates_and_deletes(self) -> None:
        client = self.authenticate(self.admin_a)
        hire = User.objects.create_user(
            email="hire-a@example.com",
            password=PASSWORD,
            role=UserRole.EMPLOYEE,
        )
        MembershipService().assign(
            user=hire,
            company=self.company_a,
            role=self.roles[UserRole.EMPLOYEE],
        )
        created = client.post(
            f"{EMPLOYEES}/",
            {
                "employee_code": "EMP-NEW",
                "first_name": "New",
                "last_name": "Hire",
                "user": hire.id,
                "department": str(self.dept_a.id),
                "position": str(self.pos_a.id),
                "employment_type": EmploymentType.CONTRACT,
                "status": EmployeeStatus.ACTIVE,
                "phone": "555-0100",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 200)
        emp_id = created.json()["data"]["id"]
        self.assertEqual(
            Employee.objects.get(pk=emp_id).company_id, self.company_a.id
        )

        listed = client.get(f"{EMPLOYEES}/")
        self.assertEqual(listed.status_code, 200)
        self.assertIn(emp_id, ids(listed))
        self.assertNotIn("phone", listed.json()["data"]["results"][0])

        detail = client.get(f"{EMPLOYEES}/{emp_id}/")
        self.assertEqual(detail.status_code, 200)
        self.assertEqual(detail.json()["data"]["phone"], "555-0100")

        patched = client.patch(
            f"{EMPLOYEES}/{emp_id}/",
            {"status": EmployeeStatus.ON_LEAVE},
            format="json",
        )
        self.assertEqual(patched.status_code, 200)
        self.assertEqual(patched.json()["data"]["status"], EmployeeStatus.ON_LEAVE)

        updated = client.put(
            f"{EMPLOYEES}/{emp_id}/",
            {
                "employee_code": "EMP-NEW",
                "first_name": "Newer",
                "last_name": "Hire",
                "employment_type": EmploymentType.FULL_TIME,
                "status": EmployeeStatus.ACTIVE,
            },
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.json()["data"]["first_name"], "Newer")

        deleted = client.delete(f"{EMPLOYEES}/{emp_id}/")
        self.assertEqual(deleted.status_code, 200)
        self.assertFalse(Employee.objects.filter(pk=emp_id).exists())
        self.assertTrue(User.objects.filter(pk=hire.pk).exists())

    def test_create_requires_name_and_code(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{EMPLOYEES}/",
            {"first_name": "NoCode"},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "VALIDATION_ERROR")

    def test_duplicate_employee_code_in_company_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{EMPLOYEES}/",
            {
                "employee_code": "EMP-001",
                "first_name": "Dup",
                "last_name": "Code",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_same_employee_code_in_other_company_allowed(self) -> None:
        client = self.authenticate(self.admin_b)
        response = client.post(
            f"{EMPLOYEES}/",
            {
                "employee_code": "EMP-009",
                "first_name": "Extra",
                "last_name": "Beta",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["employee_code"], "EMP-009")

    def test_payload_cannot_override_company(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{EMPLOYEES}/",
            {
                "employee_code": "EMP-OWN",
                "first_name": "Stay",
                "last_name": "Acme",
                "company": str(self.company_b.id),
                "company_id": str(self.company_b.id),
            },
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        created = Employee.objects.get(employee_code="EMP-OWN")
        self.assertEqual(created.company_id, self.company_a.id)

    def test_me_returns_own_profile_with_private_fields(self) -> None:
        client = self.authenticate(self.employee_a)
        response = client.get(f"{EMPLOYEES}/me/")
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["id"], str(self.emp_a1.id))
        self.assertEqual(data["phone"], "222-2222")
        self.assertEqual(data["address"], "2 Worker Lane")

    def test_me_404_without_employee_row(self) -> None:
        client = self.authenticate(self.no_company)
        response = client.get(f"{EMPLOYEES}/me/")
        self.assertIn(response.status_code, {403, 404})
