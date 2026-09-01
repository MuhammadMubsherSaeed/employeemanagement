from django.test import TestCase

from apps.employees.tests.fixtures import ids
from apps.notifications.models import NotificationType
from apps.notifications.tests import NOTIFICATIONS, NotificationFixtureMixin


class NotificationIsolationTests(NotificationFixtureMixin, TestCase):
    def test_company_a_cannot_access_company_b_notifications(self) -> None:
        own = self.make_notification(self.admin_a, title="Acme notice")
        other = self.make_notification(
            self.admin_b,
            title="Beta notice",
            type=NotificationType.SYSTEM,
        )
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{NOTIFICATIONS}/"))
        self.assertIn(str(own.id), listed)
        self.assertNotIn(str(other.id), listed)
        self.assertEqual(client.get(f"{NOTIFICATIONS}/{other.id}/").status_code, 404)
        self.assertEqual(
            client.post(f"{NOTIFICATIONS}/{other.id}/mark-read/").status_code,
            404,
        )
        count = client.get(f"{NOTIFICATIONS}/unread-count/").json()["data"]["count"]
        self.assertEqual(count, 1)

    def test_same_company_users_cannot_see_each_others_inbox(self) -> None:
        own = self.make_notification(self.employee_a, title="Ada notice")
        peer = self.make_notification(self.employee_a2, title="Nia notice")
        admin_note = self.make_notification(self.admin_a, title="Admin notice")
        client = self.authenticate(self.employee_a)
        listed = ids(client.get(f"{NOTIFICATIONS}/"))
        self.assertEqual(listed, {str(own.id)})
        self.assertEqual(client.get(f"{NOTIFICATIONS}/{peer.id}/").status_code, 404)
        self.assertEqual(
            client.get(f"{NOTIFICATIONS}/{admin_note.id}/").status_code,
            404,
        )
        self.assertEqual(
            client.post(f"{NOTIFICATIONS}/{peer.id}/mark-read/").status_code,
            404,
        )
        admin = self.authenticate(self.admin_a)
        admin_listed = ids(admin.get(f"{NOTIFICATIONS}/"))
        self.assertEqual(admin_listed, {str(admin_note.id)})
        self.assertEqual(admin.get(f"{NOTIFICATIONS}/{own.id}/").status_code, 404)
        self.assertEqual(
            admin.post(f"{NOTIFICATIONS}/{own.id}/mark-read/").status_code,
            404,
        )
