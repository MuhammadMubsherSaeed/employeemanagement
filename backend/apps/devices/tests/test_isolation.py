from django.test import TestCase

from apps.devices.models import DeviceStatus
from apps.devices.tests.fixtures import DEVICES, DeviceFixtureMixin, device_payload
from apps.employees.tests.fixtures import ids


class DeviceIsolationTests(DeviceFixtureMixin, TestCase):
    def test_company_a_cannot_access_company_b_device(self) -> None:
        self.bind(self.device_b, self.emp_b1)
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{DEVICES}/"))
        self.assertIn(str(self.device_a.id), listed)
        self.assertNotIn(str(self.device_b.id), listed)
        self.assertEqual(client.get(f"{DEVICES}/{self.device_b.id}/").status_code, 404)
        self.assertEqual(
            client.patch(
                f"{DEVICES}/{self.device_b.id}/",
                {"model": "Hacked"},
                format="json",
            ).status_code,
            404,
        )
        self.assertEqual(
            client.delete(f"{DEVICES}/{self.device_b.id}/").status_code,
            404,
        )
        self.assertEqual(
            self.assign_via_api(client, self.device_b, self.emp_a1).status_code,
            404,
        )
        self.assertEqual(
            self.return_via_api(client, self.device_b).status_code,
            404,
        )
        self.assertEqual(
            client.get(f"{DEVICES}/{self.device_b.id}/history/").status_code,
            404,
        )

    def test_cannot_assign_company_a_device_to_company_b_employee(self) -> None:
        client = self.authenticate(self.admin_a)
        response = self.assign_via_api(client, self.device_a, self.emp_b1)
        self.assertIn(response.status_code, (400, 404))
        self.device_a.refresh_from_db()
        self.assertEqual(self.device_a.status, DeviceStatus.AVAILABLE)

    def test_search_does_not_return_other_company_inventory(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{DEVICES}/?search=LAPTOP-001"))
        self.assertIn(str(self.device_a.id), listed)
        self.assertNotIn(str(self.device_b.id), listed)
        created = client.post(
            f"{DEVICES}/",
            device_payload(
                asset_code="LAPTOP-001",
                serial_number="SN-CROSS",
                company_id=str(self.company_b.id),
            ),
            format="json",
        )
        self.assertEqual(created.status_code, 400)
