from io import StringIO

from django.core.management import call_command
from django.db.models.deletion import ProtectedError
from django.test import TestCase

from apps.accounts.models import Permission, Role, RoleScope, UserRole
from apps.accounts.rbac_catalog import PERMISSION_CODES, ROLE_DEFINITIONS


class SeedRbacTests(TestCase):
    def test_seed_rbac_is_idempotent(self) -> None:
        call_command("seed_rbac", stdout=StringIO())
        call_command("seed_rbac", stdout=StringIO())

        self.assertEqual(Permission.objects.count(), len(PERMISSION_CODES))
        self.assertEqual(Role.objects.count(), len(ROLE_DEFINITIONS))
        self.assertEqual(
            Permission.objects.filter(code__in=PERMISSION_CODES).count(),
            len(PERMISSION_CODES),
        )

        admin = Role.objects.get(
            code=UserRole.COMPANY_ADMIN, scope=RoleScope.COMPANY
        )
        manager = Role.objects.get(code=UserRole.MANAGER, scope=RoleScope.COMPANY)
        employee = Role.objects.get(
            code=UserRole.EMPLOYEE, scope=RoleScope.COMPANY
        )
        super_admin = Role.objects.get(
            code=UserRole.SUPER_ADMIN, scope=RoleScope.PLATFORM
        )

        self.assertEqual(admin.permissions.count(), len(PERMISSION_CODES))
        self.assertFalse(manager.permissions.filter(code="settings.manage").exists())
        self.assertTrue(manager.permissions.filter(code="employees.view").exists())
        self.assertTrue(employee.permissions.filter(code="leave.create").exists())
        self.assertTrue(employee.permissions.filter(code="documents.create").exists())
        self.assertFalse(employee.permissions.filter(code="documents.delete").exists())
        self.assertFalse(manager.permissions.filter(code="documents.delete").exists())
        self.assertTrue(manager.permissions.filter(code="documents.update").exists())
        self.assertFalse(employee.permissions.filter(code="employees.delete").exists())
        self.assertEqual(super_admin.permissions.count(), 0)
        self.assertTrue(admin.is_system_role)

    def test_system_roles_cannot_be_deleted(self) -> None:
        call_command("seed_rbac", stdout=StringIO())
        role = Role.objects.get(code=UserRole.MANAGER, scope=RoleScope.COMPANY)
        with self.assertRaises(ProtectedError):
            role.delete()

    def test_seed_does_not_delete_custom_roles_or_permissions(self) -> None:
        call_command("seed_rbac", stdout=StringIO())
        Role.objects.create(
            code="CUSTOM_AUDITOR",
            name="Custom Auditor",
            scope=RoleScope.COMPANY,
            is_system_role=False,
        )
        Permission.objects.create(
            code="custom.audit",
            name="Custom audit",
            module="custom",
        )
        call_command("seed_rbac", stdout=StringIO())
        self.assertTrue(Role.objects.filter(code="CUSTOM_AUDITOR").exists())
        self.assertTrue(Permission.objects.filter(code="custom.audit").exists())
        self.assertEqual(Permission.objects.count(), len(PERMISSION_CODES) + 1)
        self.assertEqual(Role.objects.count(), len(ROLE_DEFINITIONS) + 1)
