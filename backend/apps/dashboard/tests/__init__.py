from decimal import Decimal

from django.utils import timezone

from apps.devices.models import Device, DeviceAssignment, DeviceStatus
from apps.leave.tests.fixtures import LeaveFixtureMixin
from apps.notifications.models import Notification, NotificationType

ADMIN = "/api/v1/dashboard/admin/"
MANAGER = "/api/v1/dashboard/manager/"
EMPLOYEE_DASH = "/api/v1/dashboard/employee/"


class DashboardFixtureMixin(LeaveFixtureMixin):
    @classmethod
    def setUpTestData(cls) -> None:
        super().setUpTestData()
        cls.device_a = cls.make_device(
            cls.company_a, "LAPTOP-001", serial_number="SN-A-001"
        )
        cls.device_b = cls.make_device(
            cls.company_b, "LAPTOP-001", serial_number="SN-B-001"
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
            company=company, asset_code=asset_code, **defaults
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

    def make_notification(self, recipient, company=None, **kwargs) -> Notification:
        defaults = {
            "company": company or recipient.get_active_membership().company,
            "recipient": recipient,
            "type": NotificationType.SYSTEM,
            "title": "System notice",
            "message": "A system notification.",
        }
        defaults.update(kwargs)
        return Notification.objects.create(**defaults)
