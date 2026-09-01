from django.test import TestCase

from apps.common.models import AuditEvent
from apps.notifications.models import DeviceToken
from apps.notifications.tests import TOKENS, NotificationFixtureMixin


class DeviceTokenApiTests(NotificationFixtureMixin, TestCase):
    def test_register_update_and_deactivate_own_token(self) -> None:
        client = self.authenticate(self.employee_a)
        created = client.post(
            f"{TOKENS}/",
            {
                "token": "fcm-token-ada-device",
                "platform": "ANDROID",
                "device_name": "Pixel",
                "user_id": self.employee_b.id,
                "company_id": str(self.company_b.id),
            },
            format="json",
        )
        self.assertEqual(created.status_code, 200)
        data = created.json()["data"]
        self.assertNotIn("token", data)
        self.assertEqual(data["platform"], "ANDROID")
        row = DeviceToken.objects.get(pk=data["id"])
        self.assertEqual(row.user_id, self.employee_a.id)
        self.assertEqual(row.company_id, self.company_a.id)
        self.assertEqual(row.token, "fcm-token-ada-device")
        again = client.post(
            f"{TOKENS}/",
            {"token": "fcm-token-ada-device", "platform": "ANDROID"},
            format="json",
        )
        self.assertEqual(again.status_code, 200)
        self.assertEqual(
            DeviceToken.objects.filter(token="fcm-token-ada-device").count(),
            1,
        )
        patched = client.patch(
            f"{TOKENS}/{row.id}/",
            {"device_name": "Pixel 9", "token": "fcm-token-ada-refreshed"},
            format="json",
        )
        self.assertEqual(patched.status_code, 200)
        row.refresh_from_db()
        self.assertEqual(row.device_name, "Pixel 9")
        self.assertEqual(row.token, "fcm-token-ada-refreshed")
        deleted = client.delete(f"{TOKENS}/{row.id}/")
        self.assertEqual(deleted.status_code, 200)
        row.refresh_from_db()
        self.assertFalse(row.is_active)
        self.assertTrue(
            AuditEvent.objects.filter(
                action="device_token.deactivated",
                resource_id=str(row.id),
            ).exists()
        )

    def test_token_moves_to_authenticated_user(self) -> None:
        DeviceToken.objects.create(
            company=self.company_b,
            user=self.employee_b,
            token="shared-fcm-token-xyz",
            platform="ANDROID",
        )
        client = self.authenticate(self.employee_a)
        response = client.post(
            f"{TOKENS}/",
            {"token": "shared-fcm-token-xyz", "platform": "IOS"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        row = DeviceToken.objects.get(token="shared-fcm-token-xyz")
        self.assertEqual(row.user_id, self.employee_a.id)
        self.assertEqual(row.company_id, self.company_a.id)
        self.assertEqual(row.platform, "IOS")
        self.assertEqual(
            DeviceToken.objects.filter(token="shared-fcm-token-xyz").count(),
            1,
        )

    def test_cannot_update_or_delete_another_users_token(self) -> None:
        other = DeviceToken.objects.create(
            company=self.company_a,
            user=self.employee_a2,
            token="nia-secret-token",
            platform="ANDROID",
        )
        foreign = DeviceToken.objects.create(
            company=self.company_b,
            user=self.employee_b,
            token="bea-secret-token",
            platform="ANDROID",
        )
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.patch(
                f"{TOKENS}/{other.id}/",
                {"device_name": "Hacked"},
                format="json",
            ).status_code,
            404,
        )
        self.assertEqual(client.delete(f"{TOKENS}/{other.id}/").status_code, 404)
        self.assertEqual(client.delete(f"{TOKENS}/{foreign.id}/").status_code, 404)
        other.refresh_from_db()
        self.assertTrue(other.is_active)
        self.assertEqual(other.device_name, "")
