from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.test import TestCase

from apps.employees.tests.fixtures import ids
from apps.leave.models import LeaveType, LeaveTypeStatus
from apps.leave.tests.fixtures import TYPES, LeaveFixtureMixin


class LeaveTypeAPITests(LeaveFixtureMixin, TestCase):
    def test_admin_creates_and_lists_types(self) -> None:
        client = self.authenticate(self.admin_a)
        created = client.post(
            f"{TYPES}/",
            {
                "name": "casual leave",
                "code": "casual",
                "days_allowed": 8,
                "is_paid": True,
                "carry_forward": False,
            },
            format="json",
        )
        self.assertEqual(created.status_code, 200)
        self.assertTrue(created.json()["success"])
        self.assertEqual(created.json()["data"]["code"], "CASUAL")
        self.assertEqual(created.json()["data"]["name"], "casual leave")
        listed = ids(client.get(f"{TYPES}/"))
        self.assertIn(str(self.type_a.id), listed)
        self.assertIn(created.json()["data"]["id"], listed)
        self.assertNotIn(str(self.type_b.id), listed)

    def test_duplicate_code_within_company_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{TYPES}/",
            {"name": "Annual copy", "code": "ANNUAL", "days_allowed": 5},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "VALIDATION_ERROR")

    def test_same_code_allowed_in_other_company(self) -> None:
        client = self.authenticate(self.admin_b)
        response = client.post(
            f"{TYPES}/",
            {"name": "Casual", "code": "CASUAL", "days_allowed": 3},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["code"], "CASUAL")
        self.assertTrue(
            LeaveType.objects.filter(company=self.company_a, code="ANNUAL").exists()
        )
        self.assertTrue(
            LeaveType.objects.filter(company=self.company_b, code="ANNUAL").exists()
        )

    def test_invalid_days_allowed_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{TYPES}/",
            {"name": "Bad", "code": "BAD", "days_allowed": -1},
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_inactive_type_is_listed_and_patchable(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = client.get(f"{TYPES}/?status=INACTIVE").json()["data"]["results"]
        self.assertEqual({row["id"] for row in listed}, {str(self.type_a_sick.id)})
        patched = client.patch(
            f"{TYPES}/{self.type_a_sick.id}/",
            {"status": LeaveTypeStatus.ACTIVE},
            format="json",
        )
        self.assertEqual(patched.status_code, 200)
        self.assertEqual(patched.json()["data"]["status"], LeaveTypeStatus.ACTIVE)

    def test_employee_cannot_create_leave_types(self) -> None:
        client = self.authenticate(self.employee_a)
        response = client.post(
            f"{TYPES}/",
            {"name": "Nope", "code": "NOPE", "days_allowed": 1},
            format="json",
        )
        self.assertEqual(response.status_code, 403)

    def test_unauthenticated_rejected(self) -> None:
        from rest_framework.test import APIClient

        response = APIClient().get(f"{TYPES}/")
        self.assertEqual(response.status_code, 401)

    def test_delete_not_allowed(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assertEqual(
            client.delete(f"{TYPES}/{self.type_a.id}/").status_code, 405
        )

    def test_company_id_in_payload_is_ignored(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{TYPES}/",
            {
                "name": "Ignored tenant",
                "code": "IGN",
                "days_allowed": 2,
                "company": str(self.company_b.id),
                "company_id": str(self.company_b.id),
            },
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        row = LeaveType.objects.get(pk=response.json()["data"]["id"])
        self.assertEqual(row.company_id, self.company_a.id)


class LeaveTypeConstraintTests(LeaveFixtureMixin, TestCase):
    def test_duplicate_code_db_constraint(self) -> None:
        with self.assertRaises((ValidationError, IntegrityError)):
            LeaveType.objects.create(
                company=self.company_a,
                name="Other",
                code="ANNUAL",
                days_allowed=1,
            )

    def test_invalid_code_rejected(self) -> None:
        with self.assertRaises(ValidationError):
            LeaveType.objects.create(
                company=self.company_a,
                name="Bad code",
                code="annual leave",
                days_allowed=1,
            )
