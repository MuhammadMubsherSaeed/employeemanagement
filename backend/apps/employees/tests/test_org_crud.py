from django.test import TestCase

from apps.employees.models import Department, OrgStatus, Position
from apps.employees.tests.fixtures import (
    DEPARTMENTS,
    POSITIONS,
    EmployeeFixtureMixin,
    ids,
)


class DepartmentCRUDTests(EmployeeFixtureMixin, TestCase):
    def test_department_crud(self) -> None:
        client = self.authenticate(self.admin_a)
        created = client.post(
            f"{DEPARTMENTS}/",
            {"name": "Finance", "description": "Money", "status": OrgStatus.ACTIVE},
            format="json",
        )
        self.assertEqual(created.status_code, 200)
        dept_id = created.json()["data"]["id"]

        listed = client.get(f"{DEPARTMENTS}/")
        self.assertIn(dept_id, ids(listed))

        detail = client.get(f"{DEPARTMENTS}/{dept_id}/")
        self.assertEqual(detail.status_code, 200)

        patched = client.patch(
            f"{DEPARTMENTS}/{dept_id}/",
            {"description": "Budgets"},
            format="json",
        )
        self.assertEqual(patched.status_code, 200)
        self.assertEqual(patched.json()["data"]["description"], "Budgets")

        updated = client.put(
            f"{DEPARTMENTS}/{dept_id}/",
            {"name": "Finance Ops", "status": OrgStatus.INACTIVE},
            format="json",
        )
        self.assertEqual(updated.status_code, 200)

        deleted = client.delete(f"{DEPARTMENTS}/{dept_id}/")
        self.assertEqual(deleted.status_code, 200)
        self.assertFalse(Department.objects.filter(pk=dept_id).exists())

    def test_duplicate_department_name_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{DEPARTMENTS}/",
            {"name": "Engineering"},
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_cross_company_manager_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{DEPARTMENTS}/",
            {
                "name": "Security",
                "manager": str(self.emp_b1.id),
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_delete_department_with_positions_is_protected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.delete(f"{DEPARTMENTS}/{self.dept_a.id}/")
        self.assertIn(response.status_code, {400, 409})
        self.assertTrue(Department.objects.filter(pk=self.dept_a.pk).exists())


class PositionCRUDTests(EmployeeFixtureMixin, TestCase):
    def test_position_crud(self) -> None:
        client = self.authenticate(self.admin_a)
        created = client.post(
            f"{POSITIONS}/",
            {
                "department": str(self.dept_a.id),
                "title": "Staff Engineer",
                "status": OrgStatus.ACTIVE,
            },
            format="json",
        )
        self.assertEqual(created.status_code, 200)
        pos_id = created.json()["data"]["id"]

        listed = client.get(f"{POSITIONS}/")
        self.assertIn(pos_id, ids(listed))

        detail = client.get(f"{POSITIONS}/{pos_id}/")
        self.assertEqual(detail.status_code, 200)

        patched = client.patch(
            f"{POSITIONS}/{pos_id}/",
            {"description": "IC"},
            format="json",
        )
        self.assertEqual(patched.status_code, 200)

        updated = client.put(
            f"{POSITIONS}/{pos_id}/",
            {
                "department": str(self.dept_a.id),
                "title": "Principal Engineer",
                "status": OrgStatus.ACTIVE,
            },
            format="json",
        )
        self.assertEqual(updated.status_code, 200)

        deleted = client.delete(f"{POSITIONS}/{pos_id}/")
        self.assertEqual(deleted.status_code, 200)
        self.assertFalse(Position.objects.filter(pk=pos_id).exists())

    def test_cross_company_department_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{POSITIONS}/",
            {
                "department": str(self.dept_b.id),
                "title": "Spy",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_duplicate_title_in_department_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{POSITIONS}/",
            {
                "department": str(self.dept_a.id),
                "title": "Engineer",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)
