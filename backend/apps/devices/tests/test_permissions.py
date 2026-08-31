from django.test import TestCase

from apps.devices.models import DeviceStatus
from apps.devices.tests.fixtures import DEVICES, DeviceFixtureMixin, device_payload
from apps.employees.tests.fixtures import ids


class DevicePermissionTests(DeviceFixtureMixin, TestCase):
    def test_employee_sees_only_own_assigned_device(self) -> None:
        self.bind(self.device_a, self.emp_a1)
        other = self.make_device(
            self.company_a,
            "LAPTOP-OTH",
            serial_number="SN-OTH",
        )
        self.bind(other, self.emp_a2)
        client = self.authenticate(self.employee_a)
        listed = ids(client.get(f"{DEVICES}/"))
        self.assertEqual(listed, {str(self.device_a.id)})
        self.assertEqual(client.get(f"{DEVICES}/{self.device_a.id}/").status_code, 200)
        self.assertEqual(client.get(f"{DEVICES}/{other.id}/").status_code, 404)
        detail = client.get(f"{DEVICES}/{self.device_a.id}/").json()["data"]
        self.assertNotIn("cost", detail)
        self.assertNotIn("notes", detail)

    def test_employee_cannot_mutate_or_assign(self) -> None:
        self.bind(self.device_a, self.emp_a1)
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.post(
                f"{DEVICES}/",
                device_payload(asset_code="NOPE-1", serial_number="SN-NOPE"),
                format="json",
            ).status_code,
            403,
        )
        self.assertEqual(
            client.patch(
                f"{DEVICES}/{self.device_a.id}/",
                {"model": "Hacked"},
                format="json",
            ).status_code,
            403,
        )
        self.assertEqual(
            client.delete(f"{DEVICES}/{self.device_a.id}/").status_code,
            403,
        )
        spare = self.make_device(
            self.company_a,
            "LAPTOP-SPARE",
            serial_number="SN-SPARE",
        )
        self.assertEqual(
            self.assign_via_api(client, spare, self.emp_a1).status_code,
            403,
        )
        other = self.make_device(
            self.company_a,
            "LAPTOP-PEER",
            serial_number="SN-PEER",
        )
        self.bind(other, self.emp_a2)
        self.assertIn(self.return_via_api(client, other).status_code, (403, 404))

    def test_manager_cannot_create_update_or_delete(self) -> None:
        client = self.authenticate(self.manager_a)
        self.assertEqual(
            client.post(
                f"{DEVICES}/",
                device_payload(asset_code="MGR-1", serial_number="SN-MGR-1"),
                format="json",
            ).status_code,
            403,
        )
        self.assertEqual(
            client.patch(
                f"{DEVICES}/{self.device_a.id}/",
                {"notes": "nope"},
                format="json",
            ).status_code,
            403,
        )
        self.assertEqual(
            client.delete(f"{DEVICES}/{self.device_a.id}/").status_code,
            403,
        )

    def test_manager_sees_available_and_team_assigned_not_other_inventory(self) -> None:
        self.bind(self.device_a, self.emp_a1)
        other = self.make_device(
            self.company_a,
            "LAPTOP-HR",
            serial_number="SN-HR",
        )
        self.bind(other, self.emp_a2)
        retired = self.make_device(
            self.company_a,
            "LAPTOP-OLD",
            serial_number="SN-OLD",
            status=DeviceStatus.RETIRED,
        )
        spare = self.make_device(
            self.company_a,
            "LAPTOP-FREE",
            serial_number="SN-FREE",
        )
        client = self.authenticate(self.manager_a)
        listed = ids(client.get(f"{DEVICES}/"))
        self.assertIn(str(self.device_a.id), listed)
        self.assertIn(str(spare.id), listed)
        self.assertNotIn(str(other.id), listed)
        self.assertNotIn(str(retired.id), listed)
        self.assertEqual(client.get(f"{DEVICES}/{other.id}/").status_code, 404)

    def test_admin_has_inventory_access(self) -> None:
        retired = self.make_device(
            self.company_a,
            "LAPTOP-RET",
            serial_number="SN-RET",
            status=DeviceStatus.RETIRED,
        )
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{DEVICES}/"))
        self.assertIn(str(self.device_a.id), listed)
        self.assertIn(str(retired.id), listed)
        self.assertEqual(
            client.patch(
                f"{DEVICES}/{self.device_a.id}/",
                {"status": DeviceStatus.MAINTENANCE},
                format="json",
            ).status_code,
            200,
        )
