from decimal import Decimal

from django.utils import timezone

from apps.devices.models import Device, DeviceAssignment, DeviceStatus
from apps.employees.tests.fixtures import EmployeeFixtureMixin

DEVICES = "/api/v1/devices"


def device_payload(**overrides):
    body = {
        "asset_code": "LAPTOP-100",
        "type": "Laptop",
        "manufacturer": "Dell",
        "model": "XPS 15",
        "serial_number": "SN-100",
        "purchase_date": "2026-01-15",
        "warranty_expiry": "2027-01-15",
        "cost": "1299.00",
        "notes": "Engineering pool",
    }
    body.update(overrides)
    return {key: value for key, value in body.items() if value is not None}


class DeviceFixtureMixin(EmployeeFixtureMixin):
    @classmethod
    def setUpTestData(cls) -> None:
        super().setUpTestData()
        cls.device_a = cls.make_device(
            cls.company_a,
            "LAPTOP-001",
            serial_number="SN-A-001",
        )
        cls.device_b = cls.make_device(
            cls.company_b,
            "LAPTOP-001",
            serial_number="SN-B-001",
        )

    @classmethod
    def make_device(cls, company, asset_code, **kwargs):
        defaults = {
            "type": "Laptop",
            "manufacturer": "Dell",
            "model": "XPS 15",
            "status": DeviceStatus.AVAILABLE,
            "cost": Decimal("1299.00"),
            "notes": "Internal pool notes",
        }
        defaults.update(kwargs)
        return Device.objects.create(
            company=company,
            asset_code=asset_code,
            **defaults,
        )

    def bind(self, device, employee, **kwargs):
        assignment = DeviceAssignment.objects.create(
            company=device.company,
            device=device,
            employee=employee,
            assigned_at=timezone.now(),
            **kwargs,
        )
        device.status = DeviceStatus.ASSIGNED
        device.save(update_fields=["status", "updated_at"])
        return assignment

    def assign_via_api(self, client, device, employee, **extra):
        body = {"employee_id": str(employee.id)}
        body.update(extra)
        return client.post(
            f"{DEVICES}/{device.id}/assign/",
            body,
            format="json",
        )

    def return_via_api(self, client, device, **extra):
        return client.post(
            f"{DEVICES}/{device.id}/return/",
            extra,
            format="json",
        )
