from datetime import timedelta

from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from apps.accounts.models import UserRole
from apps.accounts.services.permissions import apply_role_permissions
from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.models import AuditLog
from apps.companies.services import MembershipService
from apps.companies.tests.fixtures import TENANCY
from apps.devices.models import DeviceStatus
from apps.devices.tests.fixtures import DeviceFixtureMixin
from apps.employees.models import EmployeeStatus, EmploymentType, OrgStatus
from apps.employees.tests.fixtures import DEPARTMENTS, EMPLOYEES
from apps.leave.models import LeaveRequestStatus
from apps.leave.tests.fixtures import REQUESTS, LeaveFixtureMixin

AUDIT_LOGS = "/api/v1/audit-logs/"


def rows(response) -> list[dict]:
    return response.json()["data"]["results"]


def make_log(*, company, action=AuditAction.EMPLOYEE_CREATED, **kwargs) -> AuditLog:
    defaults = {
        "action": action,
        "entity_type": AuditEntityType.EMPLOYEE,
        "entity_id": "entity-1",
    }
    defaults.update(kwargs)
    return AuditLog.objects.create(company=company, **defaults)


class AuditLogAPITests(DeviceFixtureMixin, TestCase):
    def setUp(self) -> None:
        self.client = self.authenticate(self.admin_a)

    def test_unauthenticated_is_401(self) -> None:
        self.assertEqual(APIClient().get(AUDIT_LOGS).status_code, 401)

    def test_lists_newest_first_and_paginates(self) -> None:
        older = make_log(
            company=self.company_a,
            user=self.admin_a,
            entity_id="old",
            action=AuditAction.EMPLOYEE_CREATED,
        )
        newer = make_log(
            company=self.company_a,
            user=self.admin_a,
            entity_id="new",
            action=AuditAction.EMPLOYEE_CREATED,
        )
        response = self.client.get(
            AUDIT_LOGS,
            {"action": AuditAction.EMPLOYEE_CREATED, "page_size": 20},
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["success"])
        self.assertEqual(
            response.json()["message"], "Audit logs retrieved successfully."
        )
        ids = [row["id"] for row in rows(response)]
        self.assertLess(ids.index(str(newer.id)), ids.index(str(older.id)))
        first = rows(response)[0]
        self.assertEqual(first["user"]["id"], self.admin_a.id)
        self.assertEqual(first["user"]["name"], self.admin_a.get_full_name())
        self.assertNotIn("company", first)

    def test_pagination_pages_and_empty_page(self) -> None:
        for index in range(25):
            make_log(
                company=self.company_a,
                action=AuditAction.SETTINGS_CHANGED,
                entity_type=AuditEntityType.COMPANY_SETTINGS,
                entity_id=f"page-{index}",
            )
        first = self.client.get(
            AUDIT_LOGS,
            {
                "action": AuditAction.SETTINGS_CHANGED,
                "page": 1,
                "page_size": 20,
            },
        )
        second = self.client.get(
            AUDIT_LOGS,
            {
                "action": AuditAction.SETTINGS_CHANGED,
                "page": 2,
                "page_size": 20,
            },
        )
        empty = self.client.get(
            AUDIT_LOGS,
            {
                "action": AuditAction.SETTINGS_CHANGED,
                "page": 3,
                "page_size": 20,
            },
        )
        self.assertEqual(first.status_code, 200)
        self.assertEqual(first.json()["data"]["count"], 25)
        self.assertEqual(len(rows(first)), 20)
        self.assertEqual(len(rows(second)), 5)
        self.assertEqual(empty.status_code, 404)

    def test_filters_by_user_action_entity_and_dates(self) -> None:
        target = make_log(
            company=self.company_a,
            user=self.admin_a,
            action=AuditAction.LEAVE_APPROVED,
            entity_type=AuditEntityType.LEAVE_REQUEST,
            entity_id="leave-1",
        )
        make_log(
            company=self.company_a,
            user=self.manager_a,
            action=AuditAction.LEAVE_SUBMITTED,
            entity_type=AuditEntityType.LEAVE_REQUEST,
            entity_id="leave-2",
        )
        response = self.client.get(
            AUDIT_LOGS,
            {
                "user": self.admin_a.id,
                "action": AuditAction.LEAVE_APPROVED,
                "entity_type": AuditEntityType.LEAVE_REQUEST,
                "entity_id": "leave-1",
            },
        )
        self.assertEqual(response.status_code, 200)
        result_ids = {row["id"] for row in rows(response)}
        self.assertEqual(result_ids, {str(target.id)})

        today = target.created_at.date()
        dated = self.client.get(
            AUDIT_LOGS,
            {
                "action": AuditAction.LEAVE_APPROVED,
                "date_from": today.isoformat(),
                "date_to": today.isoformat(),
            },
        )
        self.assertEqual(dated.status_code, 200)
        self.assertIn(str(target.id), {row["id"] for row in rows(dated)})

        future = self.client.get(
            AUDIT_LOGS,
            {
                "action": AuditAction.LEAVE_APPROVED,
                "date_from": (today + timedelta(days=2)).isoformat(),
                "date_to": (today + timedelta(days=3)).isoformat(),
            },
        )
        self.assertEqual(future.json()["data"]["count"], 0)

    def test_invalid_filters_return_400(self) -> None:
        invalid_action = self.client.get(AUDIT_LOGS, {"action": "NOT_REAL"})
        self.assertEqual(invalid_action.status_code, 400)
        self.assertIn("action", invalid_action.json()["errors"])
        invalid_entity = self.client.get(AUDIT_LOGS, {"entity_type": "POSITION"})
        self.assertEqual(invalid_entity.status_code, 400)
        inverted = self.client.get(
            AUDIT_LOGS,
            {"date_from": "2026-09-10", "date_to": "2026-09-01"},
        )
        self.assertEqual(inverted.status_code, 400)
        bad_date = self.client.get(AUDIT_LOGS, {"date_from": "not-a-date"})
        self.assertEqual(bad_date.status_code, 400)

    def test_mutations_are_not_allowed(self) -> None:
        log = make_log(company=self.company_a)
        for method in ("post", "put", "patch", "delete"):
            response = getattr(self.client, method)(
                AUDIT_LOGS, {}, format="json"
            )
            self.assertEqual(response.status_code, 405, method)
            item = getattr(self.client, method)(
                f"{AUDIT_LOGS}{log.id}/", {}, format="json"
            )
            self.assertIn(item.status_code, {404, 405}, method)

    def test_query_count_does_not_grow_with_rows(self) -> None:
        make_log(company=self.company_a, user=self.admin_a, entity_id="q1")
        with CaptureQueriesContext(connection) as first:
            first_response = self.client.get(
                AUDIT_LOGS, {"entity_type": AuditEntityType.EMPLOYEE}
            )
        self.assertEqual(first_response.status_code, 200)
        for index in range(8):
            make_log(
                company=self.company_a,
                user=self.manager_a if index % 2 else self.admin_a,
                entity_id=f"q-{index}",
            )
        with CaptureQueriesContext(connection) as second:
            second_response = self.client.get(
                AUDIT_LOGS, {"entity_type": AuditEntityType.EMPLOYEE}
            )
        self.assertEqual(second_response.status_code, 200)
        self.assertEqual(len(first.captured_queries), len(second.captured_queries))
        self.assertLessEqual(len(second.captured_queries), 20)


class EmployeeDepartmentAuditTests(DeviceFixtureMixin, TestCase):
    def test_employee_create_update_and_deactivate(self) -> None:
        client = self.authenticate(self.admin_a)
        created = client.post(
            f"{EMPLOYEES}/",
            {
                "employee_code": "EMP-AUD",
                "first_name": "Aud",
                "last_name": "Itee",
                "department": str(self.dept_a.id),
                "position": str(self.pos_a.id),
                "employment_type": EmploymentType.FULL_TIME,
                "status": EmployeeStatus.ACTIVE,
            },
            format="json",
        )
        self.assertEqual(created.status_code, 200)
        emp_id = created.json()["data"]["id"]
        created_logs = AuditLog.objects.filter(
            action=AuditAction.EMPLOYEE_CREATED,
            entity_id=emp_id,
            company=self.company_a,
        )
        self.assertEqual(created_logs.count(), 1)
        self.assertEqual(created_logs.get().user_id, self.admin_a.id)
        self.assertEqual(created_logs.get().new_value["employee_code"], "EMP-AUD")

        renamed = client.patch(
            f"{EMPLOYEES}/{emp_id}/",
            {"first_name": "Audrey"},
            format="json",
        )
        self.assertEqual(renamed.status_code, 200)
        updated_logs = AuditLog.objects.filter(
            action=AuditAction.EMPLOYEE_UPDATED,
            entity_id=emp_id,
        )
        self.assertEqual(updated_logs.count(), 1)
        self.assertEqual(updated_logs.get().old_value["first_name"], "Aud")
        self.assertEqual(updated_logs.get().new_value["first_name"], "Audrey")

        client.patch(
            f"{EMPLOYEES}/{emp_id}/",
            {"first_name": "Audrey"},
            format="json",
        )
        self.assertEqual(
            AuditLog.objects.filter(
                action=AuditAction.EMPLOYEE_UPDATED, entity_id=emp_id
            ).count(),
            1,
        )

        deactivated = client.patch(
            f"{EMPLOYEES}/{emp_id}/",
            {"status": EmployeeStatus.INACTIVE},
            format="json",
        )
        self.assertEqual(deactivated.status_code, 200)
        deact_logs = AuditLog.objects.filter(
            action=AuditAction.EMPLOYEE_DEACTIVATED, entity_id=emp_id
        )
        self.assertEqual(deact_logs.count(), 1)
        self.assertEqual(deact_logs.get().old_value["status"], EmployeeStatus.ACTIVE)
        self.assertEqual(deact_logs.get().new_value["status"], EmployeeStatus.INACTIVE)
        self.assertFalse(
            AuditLog.objects.filter(
                action=AuditAction.EMPLOYEE_UPDATED,
                entity_id=emp_id,
                new_value__status=EmployeeStatus.INACTIVE,
            ).exists()
        )

    def test_department_create_and_update(self) -> None:
        client = self.authenticate(self.admin_a)
        created = client.post(
            f"{DEPARTMENTS}/",
            {"name": "Audit Ops", "description": "Trail", "status": OrgStatus.ACTIVE},
            format="json",
        )
        self.assertEqual(created.status_code, 200)
        dept_id = created.json()["data"]["id"]
        log = AuditLog.objects.get(
            action=AuditAction.DEPARTMENT_CREATED, entity_id=dept_id
        )
        self.assertEqual(log.company_id, self.company_a.id)
        self.assertEqual(log.user_id, self.admin_a.id)
        self.assertEqual(log.entity_type, AuditEntityType.DEPARTMENT)
        patched = client.patch(
            f"{DEPARTMENTS}/{dept_id}/",
            {"description": "Changed"},
            format="json",
        )
        self.assertEqual(patched.status_code, 200)
        updated = AuditLog.objects.get(
            action=AuditAction.DEPARTMENT_UPDATED, entity_id=dept_id
        )
        self.assertEqual(updated.old_value["description"], "Trail")
        self.assertEqual(updated.new_value["description"], "Changed")


class LeaveDeviceAuditTests(LeaveFixtureMixin, DeviceFixtureMixin, TestCase):
    def test_leave_lifecycle_and_failed_approve(self) -> None:
        employee = self.authenticate(self.employee_a)
        submitted = self.post_request(employee)
        self.assertEqual(submitted.status_code, 200)
        request_id = submitted.json()["data"]["id"]
        submitted_log = AuditLog.objects.get(
            action=AuditAction.LEAVE_SUBMITTED, entity_id=request_id
        )
        self.assertEqual(submitted_log.user_id, self.employee_a.id)
        self.assertEqual(submitted_log.company_id, self.company_a.id)
        self.assertEqual(
            submitted_log.new_value["status"], LeaveRequestStatus.PENDING
        )
        self.assertNotIn("reason", submitted_log.new_value or {})

        manager = self.authenticate(self.manager_a)
        approved = manager.post(
            f"{REQUESTS}/{request_id}/approve/", {}, format="json"
        )
        self.assertEqual(approved.status_code, 200)
        approved_log = AuditLog.objects.get(
            action=AuditAction.LEAVE_APPROVED, entity_id=request_id
        )
        self.assertEqual(approved_log.user_id, self.manager_a.id)
        self.assertEqual(
            approved_log.old_value["status"], LeaveRequestStatus.PENDING
        )
        self.assertEqual(
            approved_log.new_value["status"], LeaveRequestStatus.APPROVED
        )

        cancelled = employee.post(
            f"{REQUESTS}/{request_id}/cancel/", {}, format="json"
        )
        self.assertEqual(cancelled.status_code, 200)
        cancelled_log = AuditLog.objects.get(
            action=AuditAction.LEAVE_CANCELLED, entity_id=request_id
        )
        self.assertEqual(
            cancelled_log.old_value["status"], LeaveRequestStatus.APPROVED
        )
        self.assertEqual(
            cancelled_log.new_value["status"], LeaveRequestStatus.CANCELLED
        )

        rejected_row = self.pending_request(start="2026-03-19", end="2026-03-19")
        rejected = manager.post(
            f"{REQUESTS}/{rejected_row.id}/reject/",
            {"rejection_reason": "Too late"},
            format="json",
        )
        self.assertEqual(rejected.status_code, 200)
        rejected_log = AuditLog.objects.get(
            action=AuditAction.LEAVE_REJECTED, entity_id=str(rejected_row.id)
        )
        self.assertEqual(
            rejected_log.new_value["status"], LeaveRequestStatus.REJECTED
        )
        self.assertNotIn("rejection_reason", rejected_log.new_value or {})

        failed = self.pending_request(start="2026-03-20", end="2026-03-20")
        failed.total_days = 11
        failed.save(update_fields=["total_days", "updated_at"])
        response = manager.post(f"{REQUESTS}/{failed.id}/approve/", {}, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertFalse(
            AuditLog.objects.filter(
                action=AuditAction.LEAVE_APPROVED, entity_id=str(failed.id)
            ).exists()
        )

    def test_device_assigned_and_returned(self) -> None:
        client = self.authenticate(self.admin_a)
        assigned = self.assign_via_api(client, self.device_a, self.emp_a1)
        self.assertEqual(assigned.status_code, 200)
        log = AuditLog.objects.get(
            action=AuditAction.DEVICE_ASSIGNED, entity_id=str(self.device_a.id)
        )
        self.assertEqual(log.user_id, self.admin_a.id)
        self.assertEqual(log.new_value["employee_id"], str(self.emp_a1.id))
        self.assertEqual(log.new_value["status"], DeviceStatus.ASSIGNED)
        self.assertEqual(
            AuditLog.objects.filter(
                action=AuditAction.DEVICE_ASSIGNED, entity_id=str(self.device_a.id)
            ).count(),
            1,
        )
        retry = self.assign_via_api(client, self.device_a, self.emp_a2)
        self.assertEqual(retry.status_code, 400)
        self.assertEqual(
            AuditLog.objects.filter(
                action=AuditAction.DEVICE_ASSIGNED, entity_id=str(self.device_a.id)
            ).count(),
            1,
        )
        returned = self.return_via_api(client, self.device_a)
        self.assertEqual(returned.status_code, 200)
        returned_log = AuditLog.objects.get(
            action=AuditAction.DEVICE_RETURNED, entity_id=str(self.device_a.id)
        )
        self.assertEqual(returned_log.old_value["status"], DeviceStatus.ASSIGNED)
        self.assertEqual(returned_log.new_value["status"], DeviceStatus.AVAILABLE)
        missing = self.return_via_api(client, self.device_a)
        self.assertEqual(missing.status_code, 400)
        self.assertEqual(
            AuditLog.objects.filter(
                action=AuditAction.DEVICE_RETURNED, entity_id=str(self.device_a.id)
            ).count(),
            1,
        )


class RbacSettingsAuditTests(DeviceFixtureMixin, TestCase):
    def test_role_and_permission_changes(self) -> None:
        MembershipService().assign(
            user=self.employee_a2,
            company=self.company_a,
            role=self.roles[UserRole.MANAGER],
            actor=self.admin_a,
        )
        log = AuditLog.objects.filter(
            action=AuditAction.ROLE_CHANGED,
            entity_id=str(self.employee_a2.id),
            company=self.company_a,
        ).latest("created_at")
        self.assertEqual(log.user_id, self.admin_a.id)
        self.assertEqual(log.old_value["role"], UserRole.EMPLOYEE)
        self.assertEqual(log.new_value["role"], UserRole.MANAGER)
        self.assertEqual(log.new_value["affected_user_id"], self.employee_a2.id)

        role = self.roles[UserRole.MANAGER]
        old_codes = list(role.permissions.values_list("code", flat=True))
        apply_role_permissions(
            role,
            old_codes + ["audit_logs.view"],
            company=self.company_a,
            actor=self.admin_a,
        )
        permission_log = AuditLog.objects.get(
            action=AuditAction.PERMISSION_CHANGED,
            entity_id=str(role.id),
            company=self.company_a,
        )
        self.assertIn("audit_logs.view", permission_log.new_value["added"])
        self.assertEqual(permission_log.user_id, self.admin_a.id)
        apply_role_permissions(
            role, old_codes, company=self.company_a, actor=self.admin_a
        )

    def test_settings_changed(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.patch(
            f"{TENANCY}/settings/",
            {"timezone": "Asia/Karachi", "overtime_enabled": True},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        log = AuditLog.objects.get(
            action=AuditAction.SETTINGS_CHANGED, company=self.company_a
        )
        self.assertEqual(log.user_id, self.admin_a.id)
        self.assertEqual(log.entity_type, AuditEntityType.COMPANY_SETTINGS)
        self.assertEqual(log.old_value["timezone"], "UTC")
        self.assertEqual(log.new_value["timezone"], "Asia/Karachi")
        self.assertTrue(log.new_value["overtime_enabled"])
        unchanged = client.patch(
            f"{TENANCY}/settings/",
            {"timezone": "Asia/Karachi", "overtime_enabled": True},
            format="json",
        )
        self.assertEqual(unchanged.status_code, 200)
        self.assertEqual(
            AuditLog.objects.filter(
                action=AuditAction.SETTINGS_CHANGED, company=self.company_a
            ).count(),
            1,
        )
        get_response = client.get(f"{TENANCY}/settings/")
        self.assertEqual(get_response.status_code, 200)
        self.assertEqual(
            AuditLog.objects.filter(
                action=AuditAction.SETTINGS_CHANGED, company=self.company_a
            ).count(),
            1,
        )
