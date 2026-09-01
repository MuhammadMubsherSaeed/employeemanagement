from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import Permission, UserRole
from apps.notifications.tests import NOTIFICATIONS, NotificationFixtureMixin


class NotificationRbacTests(NotificationFixtureMixin, TestCase):
    def test_unauthenticated_is_401(self) -> None:
        client = APIClient()
        self.assertEqual(client.get(f"{NOTIFICATIONS}/").status_code, 401)
        self.assertEqual(
            client.get(f"{NOTIFICATIONS}/unread-count/").status_code,
            401,
        )

    def test_missing_view_and_mark_read(self) -> None:
        row = self.make_notification(self.employee_a)
        view = Permission.objects.get(code="notifications.view")
        mark = Permission.objects.get(code="notifications.mark_read")
        self.roles[UserRole.EMPLOYEE].permissions.remove(view)
        client = self.authenticate(self.employee_a)
        self.assertEqual(client.get(f"{NOTIFICATIONS}/").status_code, 403)
        self.roles[UserRole.EMPLOYEE].permissions.add(view)
        self.roles[UserRole.EMPLOYEE].permissions.remove(mark)
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.post(f"{NOTIFICATIONS}/{row.id}/mark-read/").status_code,
            403,
        )
        self.assertEqual(
            client.post(f"{NOTIFICATIONS}/mark-all-read/").status_code,
            403,
        )
