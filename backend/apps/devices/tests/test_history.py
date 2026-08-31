from django.test import TestCase

from apps.devices.models import DeviceAssignment
from apps.devices.tests.fixtures import DEVICES, DeviceFixtureMixin
from apps.employees.tests.fixtures import ids


class DeviceHistoryTests(DeviceFixtureMixin, TestCase):
    def test_history_order_and_pagination(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assign_via_api(client, self.device_a, self.emp_a1)
        self.return_via_api(client, self.device_a)
        self.assign_via_api(client, self.device_a, self.emp_a2)
        self.return_via_api(client, self.device_a)
        self.assign_via_api(client, self.device_a, self.emp_manager_a)
        response = client.get(f"{DEVICES}/{self.device_a.id}/history/")
        self.assertEqual(response.status_code, 200)
        rows = response.json()["data"]["results"]
        self.assertEqual(len(rows), 3)
        assigned_times = [row["assigned_at"] for row in rows]
        self.assertEqual(assigned_times, sorted(assigned_times, reverse=True))
        page = client.get(f"{DEVICES}/{self.device_a.id}/history/?page_size=1")
        payload = page.json()["data"]
        self.assertEqual(len(payload["results"]), 1)
        self.assertEqual(payload["count"], 3)
        self.assertEqual(
            payload["results"][0]["employee"]["id"],
            str(self.emp_manager_a.id),
        )

    def test_employee_sees_only_own_history_rows(self) -> None:
        admin = self.authenticate(self.admin_a)
        self.assign_via_api(admin, self.device_a, self.emp_a1)
        self.return_via_api(admin, self.device_a)
        self.assign_via_api(admin, self.device_a, self.emp_a2)
        employee = self.authenticate(self.employee_a2)
        response = employee.get(f"{DEVICES}/{self.device_a.id}/history/")
        self.assertEqual(response.status_code, 200)
        rows = response.json()["data"]["results"]
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["employee"]["id"], str(self.emp_a2.id))
        previous = self.authenticate(self.employee_a)
        self.assertEqual(
            previous.get(f"{DEVICES}/{self.device_a.id}/history/").status_code,
            404,
        )

    def test_manager_cannot_read_unauthorized_history(self) -> None:
        self.bind(self.device_a, self.emp_a2)
        manager = self.authenticate(self.manager_a)
        self.assertEqual(
            manager.get(f"{DEVICES}/{self.device_a.id}/history/").status_code,
            404,
        )
        team_device = self.make_device(
            self.company_a,
            "LAPTOP-TEAM",
            serial_number="SN-TEAM",
        )
        self.bind(team_device, self.emp_a1)
        listed = manager.get(f"{DEVICES}/{team_device.id}/history/")
        self.assertEqual(listed.status_code, 200)

    def test_history_is_tenant_scoped(self) -> None:
        self.bind(self.device_b, self.emp_b1)
        client = self.authenticate(self.admin_a)
        self.assertEqual(
            client.get(f"{DEVICES}/{self.device_b.id}/history/").status_code,
            404,
        )
        self.assertNotIn(
            str(self.device_b.id),
            ids(client.get(f"{DEVICES}/")),
        )
        self.assertEqual(DeviceAssignment.objects.filter(device=self.device_b).count(), 1)
