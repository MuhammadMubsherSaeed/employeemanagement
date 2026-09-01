from django.test import TestCase

from apps.notifications.models import (
    DevicePlatform,
    DeviceToken,
    NotificationType,
)
from apps.notifications.tests import NotificationFixtureMixin


class NotificationModelTests(NotificationFixtureMixin, TestCase):
    def test_creates_unread_with_company_and_recipient(self) -> None:
        row = self.make_notification(self.employee_a, type=NotificationType.SYSTEM)
        self.assertEqual(row.company_id, self.company_a.id)
        self.assertEqual(row.recipient_id, self.employee_a.id)
        self.assertFalse(row.is_read)
        self.assertIsNone(row.read_at)
        self.assertEqual(row.metadata, {})
        self.assertIn(NotificationType.LEAVE_APPROVED, NotificationType.values)
        self.assertIn(NotificationType.DOCUMENT_EXPIRING, NotificationType.values)

    def test_entity_reference_and_metadata(self) -> None:
        row = self.make_notification(
            self.employee_a,
            type=NotificationType.DEVICE_ASSIGNED,
            entity_type="device",
            entity_id="abc",
            metadata={"device_asset_code": "LAP-001"},
        )
        self.assertEqual(row.entity_type, "device")
        self.assertEqual(row.entity_id, "abc")
        self.assertEqual(row.metadata["device_asset_code"], "LAP-001")

    def test_device_token_unique_and_platforms(self) -> None:
        token = DeviceToken.objects.create(
            company=self.company_a,
            user=self.employee_a,
            token="fcm-token-employee-a-1",
            platform=DevicePlatform.ANDROID,
        )
        self.assertTrue(token.is_active)
        self.assertIn(DevicePlatform.IOS, DevicePlatform.values)
        self.assertEqual(
            DeviceToken.objects.filter(token="fcm-token-employee-a-1").count(),
            1,
        )
