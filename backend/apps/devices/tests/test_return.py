from django.test import TestCase

from apps.common.models import AuditEvent
from apps.devices.models import DeviceAssignment, DeviceStatus
from apps.devices.tests.fixtures import DeviceFixtureMixin


class DeviceReturnTests(DeviceFixtureMixin, TestCase):
    def test_successful_return(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assign_via_api(
            client,
            self.device_a,
            self.emp_a1,
            notes="Issued with charger",
        )
        response = self.return_via_api(
            client,
            self.device_a,
            condition_on_return="Minor scuff",
            notes="Returned at reception",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["status"], DeviceStatus.AVAILABLE)
        self.device_a.refresh_from_db()
        self.assertEqual(self.device_a.status, DeviceStatus.AVAILABLE)
        assignment = DeviceAssignment.objects.get(device=self.device_a)
        self.assertIsNotNone(assignment.returned_at)
        self.assertGreaterEqual(assignment.returned_at, assignment.assigned_at)
        self.assertEqual(assignment.condition_on_return, "Minor scuff")
        self.assertIn("Returned at reception", assignment.notes)
        self.assertEqual(
            DeviceAssignment.objects.filter(device=self.device_a).count(),
            1,
        )
        self.assertTrue(
            AuditEvent.objects.filter(
                action="device.returned",
                resource_id=str(self.device_a.id),
            ).exists()
        )

    def test_return_without_assignment_is_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = self.return_via_api(client, self.device_a)
        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            DeviceAssignment.objects.filter(device=self.device_a).count(),
            0,
        )

    def test_double_return_is_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assign_via_api(client, self.device_a, self.emp_a1)
        self.assertEqual(self.return_via_api(client, self.device_a).status_code, 200)
        second = self.return_via_api(client, self.device_a)
        self.assertEqual(second.status_code, 400)
        self.assertEqual(
            DeviceAssignment.objects.filter(
                device=self.device_a, returned_at__isnull=True
            ).count(),
            0,
        )

    def test_unauthorized_return(self) -> None:
        self.bind(self.device_a, self.emp_a1)
        employee = self.authenticate(self.employee_a)
        self.assertEqual(self.return_via_api(employee, self.device_a).status_code, 403)
        other = self.authenticate(self.employee_a2)
        self.assertIn(
            self.return_via_api(other, self.device_a).status_code,
            (403, 404),
        )
        self.device_a.refresh_from_db()
        self.assertEqual(self.device_a.status, DeviceStatus.ASSIGNED)
