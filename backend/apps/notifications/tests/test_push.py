from django.test import TestCase

from apps.notifications.models import DeviceToken, Notification, NotificationType
from apps.notifications.push import PushNotificationService, PushResult
from apps.notifications.services import NotificationService
from apps.notifications.tests import NotificationFixtureMixin


class RecordingBackend:
    def __init__(self, result: PushResult | None = None) -> None:
        self.calls: list[dict] = []
        self.result = result or PushResult(ok=True)

    def send(self, *, token, title, body, data):
        self.calls.append(
            {"token": token, "title": title, "body": body, "data": data}
        )
        return self.result


class PushNotificationServiceTests(NotificationFixtureMixin, TestCase):
    def test_push_failure_does_not_remove_inbox_row(self) -> None:
        backend = RecordingBackend(PushResult(ok=False, error="provider down"))
        service = NotificationService(push=PushNotificationService(backend=backend))
        row = service.create_notification(
            company=self.company_a,
            recipient=self.employee_a,
            type=NotificationType.SYSTEM,
            title="Hello",
            message="World",
        )
        self.assertIsNotNone(row)
        self.assertTrue(Notification.objects.filter(pk=row.id).exists())

    def test_invalid_token_is_deactivated(self) -> None:
        token = DeviceToken.objects.create(
            company=self.company_a,
            user=self.employee_a,
            token="dead-fcm-token-123",
            platform="ANDROID",
        )
        backend = RecordingBackend(PushResult(invalid_token=True))
        notification = self.make_notification(self.employee_a, title="Push me")
        PushNotificationService(backend=backend).notify(notification)
        token.refresh_from_db()
        self.assertFalse(token.is_active)
        self.assertEqual(
            backend.calls[0]["data"]["notification_id"],
            str(notification.id),
        )
        self.assertEqual(backend.calls[0]["data"]["notification_type"], "SYSTEM")

    def test_disabled_backend_skips_without_error(self) -> None:
        DeviceToken.objects.create(
            company=self.company_a,
            user=self.employee_a,
            token="live-fcm-token-123",
            platform="ANDROID",
        )
        row = NotificationService().create_notification(
            company=self.company_a,
            recipient=self.employee_a,
            type=NotificationType.SYSTEM,
            title="Inbox only",
            message="Push is disabled.",
        )
        self.assertIsNotNone(row)
        self.assertTrue(
            DeviceToken.objects.get(token="live-fcm-token-123").is_active
        )
