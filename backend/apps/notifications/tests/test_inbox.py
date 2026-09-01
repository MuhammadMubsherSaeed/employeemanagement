from datetime import timedelta

from django.test import TestCase
from django.utils import timezone

from apps.common.models import AuditEvent
from apps.employees.tests.fixtures import ids
from apps.notifications.models import Notification, NotificationType
from apps.notifications.tests import NOTIFICATIONS, NotificationFixtureMixin


class NotificationInboxTests(NotificationFixtureMixin, TestCase):
    def test_list_detail_unread_and_filters(self) -> None:
        older = self.make_notification(
            self.employee_a,
            title="Older",
            type=NotificationType.SYSTEM,
        )
        Notification.objects.filter(pk=older.pk).update(
            created_at=timezone.now() - timedelta(days=2)
        )
        newer = self.make_notification(
            self.employee_a,
            title="Newer leave",
            type=NotificationType.LEAVE_APPROVED,
        )
        client = self.authenticate(self.employee_a)
        listed = client.get(f"{NOTIFICATIONS}/")
        self.assertEqual(listed.status_code, 200)
        payload = listed.json()["data"]
        self.assertEqual(payload["count"], 2)
        self.assertEqual(payload["results"][0]["id"], str(newer.id))
        unread = client.get(f"{NOTIFICATIONS}/unread-count/")
        self.assertEqual(unread.json()["data"]["count"], 2)
        filtered = ids(client.get(f"{NOTIFICATIONS}/?type=LEAVE_APPROVED"))
        self.assertEqual(filtered, {str(newer.id)})
        unread_only = ids(client.get(f"{NOTIFICATIONS}/?is_read=false"))
        self.assertEqual(len(unread_only), 2)
        detail = client.get(f"{NOTIFICATIONS}/{newer.id}/")
        self.assertEqual(detail.status_code, 200)
        self.assertEqual(detail.json()["data"]["title"], "Newer leave")
        missing = client.get(
            f"{NOTIFICATIONS}/00000000-0000-0000-0000-000000000000/"
        )
        self.assertEqual(missing.status_code, 404)

    def test_mark_one_is_idempotent_and_writes_audit(self) -> None:
        row = self.make_notification(self.employee_a, title="To read")
        client = self.authenticate(self.employee_a)
        first = client.post(f"{NOTIFICATIONS}/{row.id}/mark-read/")
        self.assertEqual(first.status_code, 200)
        data = first.json()["data"]
        self.assertTrue(data["is_read"])
        self.assertIsNotNone(data["read_at"])
        read_at = data["read_at"]
        second = client.post(f"{NOTIFICATIONS}/{row.id}/mark-read/")
        self.assertEqual(second.status_code, 200)
        self.assertEqual(second.json()["data"]["read_at"], read_at)
        self.assertEqual(
            client.get(f"{NOTIFICATIONS}/unread-count/").json()["data"]["count"],
            0,
        )
        self.assertTrue(
            AuditEvent.objects.filter(
                action="notification.marked_read",
                resource_id=str(row.id),
            ).exists()
        )

    def test_mark_all_read_is_recipient_and_company_scoped(self) -> None:
        a1 = self.make_notification(self.employee_a, title="Ada 1")
        a2 = self.make_notification(self.employee_a, title="Ada 2")
        peer = self.make_notification(self.employee_a2, title="Nia")
        other = self.make_notification(self.employee_b, title="Bea")
        client = self.authenticate(self.employee_a)
        response = client.post(f"{NOTIFICATIONS}/mark-all-read/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["updated"], 2)
        a1.refresh_from_db()
        a2.refresh_from_db()
        peer.refresh_from_db()
        other.refresh_from_db()
        self.assertTrue(a1.is_read)
        self.assertTrue(a2.is_read)
        self.assertFalse(peer.is_read)
        self.assertFalse(other.is_read)
        self.assertEqual(
            client.get(f"{NOTIFICATIONS}/unread-count/").json()["data"]["count"],
            0,
        )

    def test_pagination(self) -> None:
        self.make_notification(self.employee_a, title="One")
        self.make_notification(self.employee_a, title="Two")
        client = self.authenticate(self.employee_a)
        page = client.get(f"{NOTIFICATIONS}/?page_size=1")
        self.assertEqual(page.status_code, 200)
        payload = page.json()["data"]
        self.assertEqual(payload["count"], 2)
        self.assertIsNotNone(payload["next"])

    def test_empty_inbox(self) -> None:
        client = self.authenticate(self.employee_a)
        listed = client.get(f"{NOTIFICATIONS}/")
        self.assertEqual(listed.json()["data"]["count"], 0)
        self.assertEqual(
            client.get(f"{NOTIFICATIONS}/unread-count/").json()["data"]["count"],
            0,
        )
