from django.core.exceptions import ValidationError
from django.test import TestCase
from rest_framework.test import APIRequestFactory

from apps.accounts.models import Role, RoleScope, UserRole
from apps.common.permissions import (
    HasAllPermissions,
    HasAnyPermission,
    HasPermission,
)
from apps.common.tenancy import TenantContext
from apps.companies.models import CompanyMembership
from apps.companies.services import MembershipService
from apps.companies.tests.fixtures import PASSWORD, TenancyFixtureMixin, User


class PermissionMatrixTests(TenancyFixtureMixin, TestCase):
    def test_has_permission_matrix(self) -> None:
        admin = TenantContext.resolve(self.admin_a)
        manager = TenantContext.resolve(self.manager_a)
        employee = TenantContext.resolve(self.employee_a)
        super_admin = TenantContext.resolve(self.super_admin)

        self.assertTrue(admin.has_permission("settings.manage"))
        self.assertTrue(
            admin.has_all_permissions(("employees.view", "employees.delete"))
        )
        self.assertTrue(manager.has_permission("employees.view"))
        self.assertFalse(manager.has_permission("settings.manage"))
        self.assertTrue(
            manager.has_any_permission(("settings.manage", "employees.view"))
        )
        self.assertFalse(
            manager.has_all_permissions(("employees.view", "settings.manage"))
        )
        self.assertTrue(employee.has_permission("attendance.check_in"))
        self.assertFalse(employee.has_permission("employees.create"))
        self.assertTrue(super_admin.has_permission("settings.manage"))
        self.assertTrue(super_admin.is_super_admin)
        self.assertIsNone(super_admin.company)

    def test_inactive_membership_has_no_company_access(self) -> None:
        membership = CompanyMembership.objects.get(
            user=self.employee_a, company=self.company_a
        )
        MembershipService().deactivate(membership)
        ctx = TenantContext.resolve(self.employee_a)
        self.assertFalse(ctx.has_company_access)
        self.assertFalse(ctx.has_permission("employees.view"))

    def test_inactive_company_blocks_access(self) -> None:
        user = User.objects.create_user(
            email="idle-user@example.com",
            password=PASSWORD,
            role=UserRole.EMPLOYEE,
        )
        MembershipService().assign(
            user=user,
            company=self.inactive_company,
            role=self.roles[UserRole.EMPLOYEE],
        )
        ctx = TenantContext.resolve(user)
        self.assertFalse(ctx.has_company_access)
        self.assertIsNone(user.current_company)

    def test_cannot_assign_super_admin_via_membership(self) -> None:
        platform_role = Role.objects.get(
            code=UserRole.SUPER_ADMIN, scope=RoleScope.PLATFORM
        )
        with self.assertRaises(ValidationError):
            MembershipService().assign(
                user=self.no_company,
                company=self.company_a,
                role=platform_role,
            )
        with self.assertRaises(ValidationError):
            MembershipService().assign(
                user=self.super_admin,
                company=self.company_a,
                role=self.roles[UserRole.COMPANY_ADMIN],
            )

    def test_one_active_membership_per_user(self) -> None:
        with self.assertRaises(ValidationError):
            MembershipService().assign(
                user=self.employee_a,
                company=self.company_b,
                role=self.roles[UserRole.EMPLOYEE],
            )

    def test_drf_permission_classes(self) -> None:
        factory = APIRequestFactory()
        request = factory.get("/")
        request.user = self.manager_a
        view = type("V", (), {})()
        self.assertTrue(
            HasPermission("employees.view")().has_permission(request, view)
        )
        self.assertFalse(
            HasPermission("settings.manage")().has_permission(request, view)
        )
        self.assertTrue(
            HasAnyPermission("settings.manage", "employees.view")().has_permission(
                request, view
            )
        )
        self.assertFalse(
            HasAllPermissions("employees.view", "settings.manage")().has_permission(
                request, view
            )
        )
        inactive = factory.get("/")
        inactive.user = self.no_company
        self.assertFalse(
            HasPermission("employees.view")().has_permission(inactive, view)
        )
