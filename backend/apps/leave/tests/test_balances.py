from django.core.exceptions import ValidationError
from django.core.management import call_command
from django.db import IntegrityError
from django.test import TestCase

from apps.employees.tests.fixtures import ids
from apps.leave.models import LeaveBalance
from apps.leave.services import LeaveService
from apps.leave.tests.fixtures import BALANCES, LeaveFixtureMixin


class LeaveBalanceAPITests(LeaveFixtureMixin, TestCase):
    def test_employee_sees_only_own_balances(self) -> None:
        client = self.authenticate(self.employee_a)
        listed = ids(client.get(f"{BALANCES}/"))
        self.assertEqual(listed, {str(self.balance_a1.id)})
        self.assertEqual(
            client.get(f"{BALANCES}/{self.balance_a1.id}/").status_code, 200
        )
        self.assertEqual(
            client.get(f"{BALANCES}/{self.balance_a2.id}/").status_code, 404
        )
        data = client.get(f"{BALANCES}/{self.balance_a1.id}/").json()["data"]
        self.assertEqual(data["remaining_days"], 10)
        self.assertEqual(data["used_days"], 0)

    def test_employee_cannot_allocate(self) -> None:
        client = self.authenticate(self.employee_a)
        response = client.patch(
            f"{BALANCES}/{self.balance_a1.id}/",
            {"allocated_days": 20},
            format="json",
        )
        self.assertEqual(response.status_code, 403)
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.allocated_days, 10)

    def test_admin_allocates_without_changing_used_days(self) -> None:
        self.balance_a1.used_days = 3
        self.balance_a1.save()
        client = self.authenticate(self.admin_a)
        response = client.patch(
            f"{BALANCES}/{self.balance_a1.id}/",
            {"allocated_days": 15, "used_days": 0, "remaining_days": 99},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["allocated_days"], 15)
        self.assertEqual(data["used_days"], 3)
        self.assertEqual(data["remaining_days"], 12)

    def test_allocate_below_used_days_rejected(self) -> None:
        self.balance_a1.used_days = 4
        self.balance_a1.save()
        client = self.authenticate(self.admin_a)
        response = client.patch(
            f"{BALANCES}/{self.balance_a1.id}/",
            {"allocated_days": 2},
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_manager_sees_self_and_direct_reports_only(self) -> None:
        client = self.authenticate(self.manager_a)
        listed = ids(client.get(f"{BALANCES}/"))
        self.assertIn(str(self.balance_a1.id), listed)
        self.assertIn(str(self.balance_manager.id), listed)
        self.assertNotIn(str(self.balance_a2.id), listed)
        self.assertNotIn(str(self.balance_b1.id), listed)

    def test_year_filter(self) -> None:
        extra = self._balance(self.emp_a1, self.type_a, 4, year=2025)
        client = self.authenticate(self.employee_a)
        listed = ids(client.get(f"{BALANCES}/?year=2026"))
        self.assertEqual(listed, {str(self.balance_a1.id)})
        listed_old = ids(client.get(f"{BALANCES}/?year=2025"))
        self.assertEqual(listed_old, {str(extra.id)})


class LeaveBalanceConstraintTests(LeaveFixtureMixin, TestCase):
    def test_unique_employee_type_year(self) -> None:
        with self.assertRaises((ValidationError, IntegrityError)):
            LeaveBalance.objects.create(
                company=self.company_a,
                employee=self.emp_a1,
                leave_type=self.type_a,
                year=2026,
                allocated_days=1,
            )

    def test_remaining_days_are_calculated(self) -> None:
        self.balance_a1.used_days = 4
        self.balance_a1.save()
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.remaining_days, 6)

    def test_used_days_cannot_exceed_allocated(self) -> None:
        self.balance_a1.used_days = 11
        with self.assertRaises(ValidationError):
            self.balance_a1.save()

    def test_cross_company_employee_type_rejected(self) -> None:
        with self.assertRaises(ValidationError):
            LeaveBalance.objects.create(
                company=self.company_a,
                employee=self.emp_a1,
                leave_type=self.type_b,
                year=2027,
                allocated_days=1,
            )

    def test_initialize_creates_missing_and_skips_existing(self) -> None:
        before = LeaveBalance.objects.filter(
            employee=self.emp_a1, leave_type=self.type_a, year=2026
        ).get()
        created = LeaveService().ensure_balances_for_year(
            company=self.company_a, year=2026
        )
        self.assertEqual(created, 0)
        before.refresh_from_db()
        self.assertEqual(before.allocated_days, 10)
        call_command("initialize_leave_balances", year=2027, company="acme")
        self.assertTrue(
            LeaveBalance.objects.filter(
                employee=self.emp_a1, leave_type=self.type_a, year=2027
            ).exists()
        )
        self.assertFalse(
            LeaveBalance.objects.filter(
                employee=self.emp_a1, leave_type=self.type_a_sick, year=2027
            ).exists()
        )
