from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import Permission, UserRole
from apps.attendance.tests.fixtures import ON_TIME, freeze_now
from apps.dashboard.tests import ADMIN, EMPLOYEE_DASH, MANAGER, DashboardFixtureMixin


class DashboardPermissionTests(DashboardFixtureMixin, TestCase):
    def test_unauthenticated_is_401(self) -> None:
        client = APIClient()
        for path in (ADMIN, MANAGER, EMPLOYEE_DASH):
            self.assertEqual(client.get(path).status_code, 401)

    def test_role_cannot_access_other_dashboards(self) -> None:
        employee = self.authenticate(self.employee_a)
        manager = self.authenticate(self.manager_a)
        admin = self.authenticate(self.admin_a)
        with freeze_now(ON_TIME):
            self.assertEqual(employee.get(ADMIN).status_code, 403)
            self.assertEqual(employee.get(MANAGER).status_code, 403)
            self.assertEqual(employee.get(EMPLOYEE_DASH).status_code, 200)
            self.assertEqual(manager.get(ADMIN).status_code, 403)
            self.assertEqual(manager.get(MANAGER).status_code, 200)
            self.assertEqual(manager.get(EMPLOYEE_DASH).status_code, 200)
            self.assertEqual(admin.get(ADMIN).status_code, 200)
            self.assertEqual(admin.get(MANAGER).status_code, 200)
            self.assertEqual(admin.get(EMPLOYEE_DASH).status_code, 200)

    def test_missing_permission_is_403(self) -> None:
        view = Permission.objects.get(code="dashboard.admin.view")
        self.roles[UserRole.COMPANY_ADMIN].permissions.remove(view)
        client = self.authenticate(self.admin_a)
        with freeze_now(ON_TIME):
            self.assertEqual(client.get(ADMIN).status_code, 403)
            self.assertEqual(client.get(EMPLOYEE_DASH).status_code, 200)

    def test_super_admin_has_no_company_dashboard(self) -> None:
        client = self.authenticate(self.super_admin)
        with freeze_now(ON_TIME):
            self.assertEqual(client.get(ADMIN).status_code, 403)
            self.assertEqual(client.get(MANAGER).status_code, 403)
            self.assertEqual(client.get(EMPLOYEE_DASH).status_code, 403)

    def test_user_without_membership_is_403(self) -> None:
        client = self.authenticate(self.no_company)
        with freeze_now(ON_TIME):
            self.assertEqual(client.get(ADMIN).status_code, 403)
            self.assertEqual(client.get(EMPLOYEE_DASH).status_code, 403)
