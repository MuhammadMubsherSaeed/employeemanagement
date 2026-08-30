from io import StringIO

from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.test import TestCase

from apps.accounts.models import Permission, Role
from apps.accounts.rbac_catalog import PERMISSION_CODES, ROLE_DEFINITIONS
from apps.companies.models import Company, CompanyMembership, TenantOwnedRecord
from apps.employees.models import Department, Employee, Position

User = get_user_model()


class SeedDemoTests(TestCase):
    def test_seed_demo_creates_five_rows_per_domain_table(self) -> None:
        call_command("seed_demo", stdout=StringIO())
        call_command("seed_demo", stdout=StringIO())

        self.assertEqual(Permission.objects.count(), len(PERMISSION_CODES))
        self.assertEqual(Role.objects.count(), len(ROLE_DEFINITIONS))
        self.assertEqual(Company.objects.count(), 5)
        self.assertEqual(CompanyMembership.objects.count(), 5)
        self.assertEqual(Department.objects.count(), 5)
        self.assertEqual(Position.objects.count(), 5)
        self.assertEqual(Employee.objects.count(), 5)
        self.assertEqual(TenantOwnedRecord.objects.count(), 5)
        self.assertEqual(User.objects.count(), 6)

        acme = Company.objects.get(slug="acme")
        self.assertEqual(acme.employees.count(), 5)
        self.assertEqual(acme.departments.count(), 5)
        self.assertEqual(acme.positions.count(), 5)
        self.assertFalse(Company.objects.get(slug="epsilon").is_active)

        admin = User.objects.get(email="james.carter@acme.example.com")
        membership = admin.get_active_membership()
        self.assertEqual(membership.company, acme)
        self.assertEqual(membership.role.code, "COMPANY_ADMIN")

        priya = Employee.objects.get(employee_code="EMP-002", company=acme)
        ada = Employee.objects.get(employee_code="EMP-003", company=acme)
        self.assertEqual(ada.manager_id, priya.id)
        self.assertEqual(
            Department.objects.get(company=acme, name="Engineering").manager_id,
            priya.id,
        )
        self.assertTrue(
            User.objects.get(email="ops@bestech.example.com").is_platform_admin
        )
