from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import Permission, UserRole
from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.models import AuditLog
from apps.devices.tests.fixtures import DeviceFixtureMixin

AUDIT_LOGS = "/api/v1/audit-logs/"


def make_log(*, company, **kwargs) -> AuditLog:
    defaults = {
        "action": AuditAction.EMPLOYEE_CREATED,
        "entity_type": AuditEntityType.EMPLOYEE,
        "entity_id": "entity-1",
    }
    defaults.update(kwargs)
    return AuditLog.objects.create(company=company, **defaults)


def result_ids(response) -> set[str]:
    return {row["id"] for row in response.json()["data"]["results"]}


class AuditLogPermissionTests(DeviceFixtureMixin, TestCase):
    def setUp(self) -> None:
        self.log_a = make_log(
            company=self.company_a,
            user=self.admin_a,
            entity_id=str(self.emp_a1.id),
        )
        self.log_b = make_log(
            company=self.company_b,
            user=self.admin_b,
            action=AuditAction.LEAVE_APPROVED,
            entity_type=AuditEntityType.LEAVE_REQUEST,
            entity_id=str(self.emp_b1.id),
        )

    def test_admin_with_permission_can_list_own_company(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(AUDIT_LOGS)
        self.assertEqual(response.status_code, 200)
        ids = result_ids(response)
        self.assertIn(str(self.log_a.id), ids)
        self.assertNotIn(str(self.log_b.id), ids)

    def test_employee_without_permission_is_403(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(client.get(AUDIT_LOGS).status_code, 403)

    def test_manager_without_permission_is_403(self) -> None:
        client = self.authenticate(self.manager_a)
        self.assertEqual(client.get(AUDIT_LOGS).status_code, 403)

    def test_admin_without_permission_is_403(self) -> None:
        view = Permission.objects.get(code="audit_logs.view")
        self.roles[UserRole.COMPANY_ADMIN].permissions.remove(view)
        client = self.authenticate(self.admin_a)
        self.assertEqual(client.get(AUDIT_LOGS).status_code, 403)

    def test_manager_with_granted_permission_is_scoped(self) -> None:
        view = Permission.objects.get(code="audit_logs.view")
        self.roles[UserRole.MANAGER].permissions.add(view)
        client = self.authenticate(self.manager_a)
        response = client.get(AUDIT_LOGS)
        self.assertEqual(response.status_code, 200)
        ids = result_ids(response)
        self.assertIn(str(self.log_a.id), ids)
        self.assertNotIn(str(self.log_b.id), ids)

    def test_super_admin_has_no_company_scope(self) -> None:
        client = self.authenticate(self.super_admin)
        self.assertEqual(client.get(AUDIT_LOGS).status_code, 403)

    def test_unauthenticated_is_401(self) -> None:
        self.assertEqual(APIClient().get(AUDIT_LOGS).status_code, 401)


class AuditLogTenantIsolationTests(DeviceFixtureMixin, TestCase):
    def setUp(self) -> None:
        self.log_a = make_log(
            company=self.company_a,
            user=self.admin_a,
            entity_id="emp-a",
        )
        self.log_b = make_log(
            company=self.company_b,
            user=self.admin_b,
            action=AuditAction.EMPLOYEE_UPDATED,
            entity_id="emp-b",
        )
        self.client = self.authenticate(self.admin_a)

    def test_cannot_read_other_company_logs(self) -> None:
        response = self.client.get(AUDIT_LOGS)
        self.assertEqual(response.status_code, 200)
        ids = result_ids(response)
        self.assertIn(str(self.log_a.id), ids)
        self.assertNotIn(str(self.log_b.id), ids)

    def test_query_params_cannot_select_another_company(self) -> None:
        response = self.client.get(
            AUDIT_LOGS,
            {
                "company_id": str(self.company_b.id),
                "tenant_id": str(self.company_b.id),
                "company": str(self.company_b.id),
            },
        )
        self.assertEqual(response.status_code, 200)
        ids = result_ids(response)
        self.assertNotIn(str(self.log_b.id), ids)

    def test_user_filter_cannot_cross_companies(self) -> None:
        response = self.client.get(AUDIT_LOGS, {"user": self.admin_b.id})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["count"], 0)
        self.assertNotIn(str(self.log_b.id), result_ids(response))

    def test_entity_filters_cannot_cross_companies(self) -> None:
        by_type = self.client.get(
            AUDIT_LOGS,
            {"entity_type": AuditEntityType.EMPLOYEE, "entity_id": "emp-b"},
        )
        self.assertEqual(by_type.status_code, 200)
        self.assertEqual(by_type.json()["data"]["count"], 0)
        by_action = self.client.get(
            AUDIT_LOGS, {"action": AuditAction.EMPLOYEE_UPDATED}
        )
        self.assertEqual(by_action.json()["data"]["count"], 0)
