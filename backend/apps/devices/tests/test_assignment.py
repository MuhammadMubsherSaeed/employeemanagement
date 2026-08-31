from django.test import TestCase

from apps.common.models import AuditEvent
from apps.devices.models import DeviceAssignment, DeviceStatus
from apps.devices.tests.fixtures import DEVICES, DeviceFixtureMixin


class DeviceAssignmentTests(DeviceFixtureMixin, TestCase):
    def test_admin_assigns_available_device(self) -> None:
        client = self.authenticate(self.admin_a)
        response = self.assign_via_api(
            client,
            self.device_a,
            self.emp_a1,
            condition_on_assignment="New, box opened",
            notes="Desk 12",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["status"], DeviceStatus.ASSIGNED)
        self.device_a.refresh_from_db()
        self.assertEqual(self.device_a.status, DeviceStatus.ASSIGNED)
        assignment = DeviceAssignment.objects.get(device=self.device_a)
        self.assertIsNone(assignment.returned_at)
        self.assertEqual(assignment.employee_id, self.emp_a1.id)
        self.assertEqual(assignment.condition_on_assignment, "New, box opened")
        self.assertTrue(
            AuditEvent.objects.filter(
                action="device.assigned",
                resource_id=str(self.device_a.id),
            ).exists()
        )

    def test_assign_already_assigned_is_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assertEqual(
            self.assign_via_api(client, self.device_a, self.emp_a1).status_code,
            200,
        )
        second = self.assign_via_api(client, self.device_a, self.emp_a2)
        self.assertEqual(second.status_code, 400)
        self.assertEqual(
            DeviceAssignment.objects.filter(
                device=self.device_a, returned_at__isnull=True
            ).count(),
            1,
        )

    def test_cannot_assign_maintenance_retired_or_lost(self) -> None:
        client = self.authenticate(self.admin_a)
        for status in (
            DeviceStatus.MAINTENANCE,
            DeviceStatus.RETIRED,
            DeviceStatus.LOST,
        ):
            device = self.make_device(
                self.company_a,
                f"{status[:3]}-1",
                serial_number=f"SN-{status}",
                status=status,
            )
            response = self.assign_via_api(client, device, self.emp_a1)
            self.assertEqual(response.status_code, 400, status)
            device.refresh_from_db()
            self.assertEqual(device.status, status)

    def test_cannot_assign_other_company_employee(self) -> None:
        client = self.authenticate(self.admin_a)
        response = self.assign_via_api(client, self.device_a, self.emp_b1)
        self.assertIn(response.status_code, (400, 404))
        self.device_a.refresh_from_db()
        self.assertEqual(self.device_a.status, DeviceStatus.AVAILABLE)

    def test_unauthorized_user_cannot_assign(self) -> None:
        employee = self.authenticate(self.employee_a)
        self.assertEqual(
            self.assign_via_api(employee, self.device_a, self.emp_a1).status_code,
            403,
        )

    def test_manager_assigns_direct_report_not_other_employee(self) -> None:
        client = self.authenticate(self.manager_a)
        ok = self.assign_via_api(client, self.device_a, self.emp_a1)
        self.assertEqual(ok.status_code, 200)
        other = self.make_device(
            self.company_a,
            "LAPTOP-MGR",
            serial_number="SN-MGR",
        )
        blocked = self.assign_via_api(client, other, self.emp_a2)
        self.assertEqual(blocked.status_code, 404)

    def test_assignment_history_is_a_new_row(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assign_via_api(client, self.device_a, self.emp_a1)
        self.return_via_api(client, self.device_a)
        self.assign_via_api(client, self.device_a, self.emp_a2)
        rows = list(
            DeviceAssignment.objects.filter(device=self.device_a).order_by("assigned_at")
        )
        self.assertEqual(len(rows), 2)
        self.assertIsNotNone(rows[0].returned_at)
        self.assertIsNone(rows[1].returned_at)
        self.assertEqual(rows[0].employee_id, self.emp_a1.id)
        self.assertEqual(rows[1].employee_id, self.emp_a2.id)

    def test_assign_ignores_company_device_and_status_in_body(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{DEVICES}/{self.device_a.id}/assign/",
            {
                "employee_id": str(self.emp_a1.id),
                "company_id": str(self.company_b.id),
                "device_id": str(self.device_b.id),
                "status": DeviceStatus.AVAILABLE,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.device_a.refresh_from_db()
        self.assertEqual(self.device_a.status, DeviceStatus.ASSIGNED)
        self.assertEqual(
            DeviceAssignment.objects.get(device=self.device_a).employee_id,
            self.emp_a1.id,
        )
