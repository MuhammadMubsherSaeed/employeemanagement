from concurrent.futures import ThreadPoolExecutor
from decimal import Decimal

from django.core.exceptions import ValidationError
from django.db import IntegrityError, connections
from django.test import TestCase, TransactionTestCase
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import AccessToken

from apps.devices.models import Device, DeviceAssignment, DeviceStatus
from apps.devices.tests.fixtures import DEVICES, DeviceFixtureMixin


class DeviceConstraintTests(DeviceFixtureMixin, TestCase):
    def test_asset_code_unique_per_company(self) -> None:
        with self.assertRaises(ValidationError):
            Device.objects.create(
                company=self.company_a,
                asset_code="LAPTOP-001",
                type="Laptop",
            )

    def test_asset_code_may_repeat_across_companies(self) -> None:
        self.assertEqual(self.device_a.asset_code, self.device_b.asset_code)
        self.assertNotEqual(self.device_a.company_id, self.device_b.company_id)

    def test_serial_unique_per_company_allows_multiple_blanks(self) -> None:
        Device.objects.create(
            company=self.company_a,
            asset_code="BLANK-1",
            type="Laptop",
            serial_number=None,
        )
        Device.objects.create(
            company=self.company_a,
            asset_code="BLANK-2",
            type="Laptop",
            serial_number=None,
        )
        with self.assertRaises(ValidationError):
            Device.objects.create(
                company=self.company_a,
                asset_code="DUP-SN",
                type="Laptop",
                serial_number="SN-A-001",
            )

    def test_cost_and_warranty_constraints(self) -> None:
        with self.assertRaises(ValidationError):
            Device.objects.create(
                company=self.company_a,
                asset_code="NEG-1",
                type="Laptop",
                cost=Decimal("-0.01"),
            )
        with self.assertRaises(ValidationError):
            Device.objects.create(
                company=self.company_a,
                asset_code="WAR-1",
                type="Laptop",
                purchase_date="2026-03-16",
                warranty_expiry="2026-03-01",
            )

    def test_one_active_assignment_constraint(self) -> None:
        self.bind(self.device_a, self.emp_a1)
        with self.assertRaises(ValidationError):
            DeviceAssignment.objects.create(
                company=self.company_a,
                device=self.device_a,
                employee=self.emp_a2,
                assigned_at=self.device_a.updated_at,
            )
        with self.assertRaises(IntegrityError):
            DeviceAssignment.objects.bulk_create(
                [
                    DeviceAssignment(
                        company=self.company_a,
                        device=self.device_a,
                        employee=self.emp_a2,
                        assigned_at=self.device_a.updated_at,
                    )
                ]
            )

    def test_cross_company_assignment_rejected(self) -> None:
        with self.assertRaises(ValidationError):
            DeviceAssignment.objects.create(
                company=self.company_a,
                device=self.device_a,
                employee=self.emp_b1,
                assigned_at=self.device_a.updated_at,
            )

    def test_retired_cannot_become_assigned_via_status(self) -> None:
        self.device_a.status = DeviceStatus.RETIRED
        self.device_a.save(update_fields=["status", "updated_at"])
        client = self.authenticate(self.admin_a)
        response = client.patch(
            f"{DEVICES}/{self.device_a.id}/",
            {"status": DeviceStatus.ASSIGNED},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        lost = client.patch(
            f"{DEVICES}/{self.device_a.id}/",
            {"status": DeviceStatus.LOST},
            format="json",
        )
        self.assertEqual(lost.status_code, 400)


class ConcurrentAssignmentTests(DeviceFixtureMixin, TransactionTestCase):
    def setUp(self) -> None:
        super().setUp()
        type(self).setUpTestData()

    def test_parallel_assigns_create_one_active_assignment(self) -> None:
        token = str(AccessToken.for_user(self.admin_a))
        device_id = str(self.device_a.id)
        employee_id = str(self.emp_a1.id)

        def attempt():
            connections.close_all()
            client = APIClient()
            client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
            return client.post(
                f"{DEVICES}/{device_id}/assign/",
                {"employee_id": employee_id},
                format="json",
            )

        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: attempt(), range(2)))

        codes = [response.status_code for response in results]
        self.assertEqual(
            DeviceAssignment.objects.filter(
                device_id=self.device_a.id,
                returned_at__isnull=True,
            ).count(),
            1,
        )
        self.device_a.refresh_from_db()
        self.assertEqual(self.device_a.status, DeviceStatus.ASSIGNED)
        self.assertIn(200, codes)
        self.assertTrue(all(code in (200, 400) for code in codes))
