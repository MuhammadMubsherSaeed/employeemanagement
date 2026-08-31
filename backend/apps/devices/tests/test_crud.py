from django.test import TestCase
from rest_framework.test import APIClient

from apps.common.models import AuditEvent
from apps.devices.models import Device, DeviceStatus
from apps.devices.tests.fixtures import DEVICES, DeviceFixtureMixin, device_payload
from apps.employees.tests.fixtures import ids


class DeviceCrudTests(DeviceFixtureMixin, TestCase):
    def test_admin_creates_lists_and_retrieves(self) -> None:
        client = self.authenticate(self.admin_a)
        created = client.post(
            f"{DEVICES}/",
            device_payload(asset_code="monitor-002", serial_number="SN-200"),
            format="json",
        )
        self.assertEqual(created.status_code, 200)
        data = created.json()["data"]
        self.assertEqual(data["asset_code"], "MONITOR-002")
        self.assertEqual(data["status"], DeviceStatus.AVAILABLE)
        self.assertEqual(data["cost"], "1299.00")
        self.assertTrue(
            AuditEvent.objects.filter(
                action="device.created", resource_id=str(data["id"])
            ).exists()
        )
        listed = ids(client.get(f"{DEVICES}/"))
        self.assertIn(str(self.device_a.id), listed)
        self.assertIn(data["id"], listed)
        self.assertNotIn(str(self.device_b.id), listed)
        detail = client.get(f"{DEVICES}/{data['id']}/")
        self.assertEqual(detail.status_code, 200)
        self.assertEqual(detail.json()["data"]["model"], "XPS 15")

    def test_create_ignores_client_company_and_status(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{DEVICES}/",
            device_payload(
                asset_code="LAPTOP-101",
                serial_number="SN-101",
                company_id=str(self.company_b.id),
                status=DeviceStatus.ASSIGNED,
            ),
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["status"], DeviceStatus.AVAILABLE)
        row = Device.objects.get(pk=data["id"])
        self.assertEqual(row.company_id, self.company_a.id)

    def test_update_and_partial_update(self) -> None:
        client = self.authenticate(self.admin_a)
        put = client.put(
            f"{DEVICES}/{self.device_a.id}/",
            device_payload(
                asset_code="LAPTOP-001",
                serial_number="SN-A-001",
                manufacturer="Lenovo",
                model="ThinkPad",
                notes="Updated notes",
            ),
            format="json",
        )
        self.assertEqual(put.status_code, 200)
        self.assertEqual(put.json()["data"]["manufacturer"], "Lenovo")
        patch = client.patch(
            f"{DEVICES}/{self.device_a.id}/",
            {"model": "ThinkPad X1"},
            format="json",
        )
        self.assertEqual(patch.status_code, 200)
        self.assertEqual(patch.json()["data"]["model"], "ThinkPad X1")
        self.assertTrue(
            AuditEvent.objects.filter(
                action="device.updated",
                resource_id=str(self.device_a.id),
            ).exists()
        )

    def test_duplicate_asset_code_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{DEVICES}/",
            device_payload(asset_code="laptop-001", serial_number="SN-DUP-A"),
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("asset_code", response.json()["errors"])

    def test_same_asset_code_other_company_allowed(self) -> None:
        admin_a = self.authenticate(self.admin_a)
        created = admin_a.post(
            f"{DEVICES}/",
            device_payload(asset_code="SHARED-9", serial_number="SN-A-SH"),
            format="json",
        )
        self.assertEqual(created.status_code, 200)
        admin_b = self.authenticate(self.admin_b)
        other = admin_b.post(
            f"{DEVICES}/",
            device_payload(asset_code="SHARED-9", serial_number="SN-B-SH"),
            format="json",
        )
        self.assertEqual(other.status_code, 200)
        self.assertEqual(other.json()["data"]["asset_code"], "SHARED-9")

    def test_duplicate_serial_rejected_blank_serials_allowed(self) -> None:
        client = self.authenticate(self.admin_a)
        duplicate = client.post(
            f"{DEVICES}/",
            device_payload(asset_code="LAPTOP-201", serial_number="SN-A-001"),
            format="json",
        )
        self.assertEqual(duplicate.status_code, 400)
        first = client.post(
            f"{DEVICES}/",
            device_payload(asset_code="LAPTOP-202", serial_number=""),
            format="json",
        )
        second = client.post(
            f"{DEVICES}/",
            device_payload(asset_code="LAPTOP-203", serial_number=""),
            format="json",
        )
        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200)
        self.assertIsNone(first.json()["data"]["serial_number"])

    def test_invalid_cost_and_warranty(self) -> None:
        client = self.authenticate(self.admin_a)
        cost = client.post(
            f"{DEVICES}/",
            device_payload(asset_code="LAPTOP-301", serial_number="SN-301", cost="-1"),
            format="json",
        )
        self.assertEqual(cost.status_code, 400)
        warranty = client.post(
            f"{DEVICES}/",
            device_payload(
                asset_code="LAPTOP-302",
                serial_number="SN-302",
                purchase_date="2026-03-16",
                warranty_expiry="2026-03-01",
            ),
            format="json",
        )
        self.assertEqual(warranty.status_code, 400)

    def test_cannot_force_assigned_or_available_status_on_update(self) -> None:
        client = self.authenticate(self.admin_a)
        assigned = client.patch(
            f"{DEVICES}/{self.device_a.id}/",
            {"status": DeviceStatus.ASSIGNED},
            format="json",
        )
        self.assertEqual(assigned.status_code, 400)
        self.bind(self.device_a, self.emp_a1)
        available = client.patch(
            f"{DEVICES}/{self.device_a.id}/",
            {"status": DeviceStatus.AVAILABLE},
            format="json",
        )
        self.assertEqual(available.status_code, 400)
        self.device_a.refresh_from_db()
        self.assertEqual(self.device_a.status, DeviceStatus.ASSIGNED)

    def test_delete_allowed_without_history_rejected_with_history(self) -> None:
        client = self.authenticate(self.admin_a)
        created = client.post(
            f"{DEVICES}/",
            device_payload(asset_code="LAPTOP-401", serial_number="SN-401"),
            format="json",
        )
        device_id = created.json()["data"]["id"]
        self.assertEqual(client.delete(f"{DEVICES}/{device_id}/").status_code, 200)
        self.assertFalse(Device.objects.filter(pk=device_id).exists())
        self.bind(self.device_a, self.emp_a1)
        blocked = client.delete(f"{DEVICES}/{self.device_a.id}/")
        self.assertEqual(blocked.status_code, 400)
        self.assertTrue(Device.objects.filter(pk=self.device_a.id).exists())

    def test_search_filter_and_pagination(self) -> None:
        client = self.authenticate(self.admin_a)
        client.post(
            f"{DEVICES}/",
            device_payload(
                asset_code="PHONE-500",
                type="Mobile",
                manufacturer="Apple",
                model="iPhone",
                serial_number="SN-500",
            ),
            format="json",
        )
        search = ids(client.get(f"{DEVICES}/?search=PHONE-500"))
        self.assertTrue(search)
        self.assertNotIn(str(self.device_b.id), search)
        typed = ids(client.get(f"{DEVICES}/?type=mobile"))
        self.assertTrue(all(row for row in typed))
        page = client.get(f"{DEVICES}/?page_size=1")
        self.assertEqual(page.status_code, 200)
        payload = page.json()["data"]
        self.assertEqual(len(payload["results"]), 1)
        self.assertGreaterEqual(payload["count"], 2)

    def test_unauthenticated_is_401(self) -> None:
        client = APIClient()
        self.assertEqual(client.get(f"{DEVICES}/").status_code, 401)
