from datetime import datetime, timedelta
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from django.core import mail
from django.test import TestCase, override_settings
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import UserRole

User = get_user_model()

PASSWORD = "a-strong-password-123"
AUTH = "/api/v1/auth"


@override_settings(EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend")
class AuthAPITests(TestCase):
    def setUp(self) -> None:
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="user@example.com",
            password=PASSWORD,
            first_name="User",
            last_name="Name",
            role=UserRole.EMPLOYEE,
        )

    def _login(self, email="user@example.com", password=PASSWORD):
        return self.client.post(
            f"{AUTH}/login/",
            {"email": email, "password": password},
            format="json",
        )

    def _tokens(self) -> dict:
        response = self._login()
        self.assertEqual(response.status_code, 200)
        return response.json()["data"]

    def test_login_success(self) -> None:
        response = self._login()
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["message"], "Login successful.")
        self.assertIn("access", body["data"])
        self.assertIn("refresh", body["data"])
        user = body["data"]["user"]
        self.assertEqual(user["email"], "user@example.com")
        self.assertEqual(user["full_name"], "User Name")
        self.assertEqual(user["role"], "EMPLOYEE")
        self.assertNotIn("password", user)
        self.assertNotIn("is_superuser", user)
        self.user.refresh_from_db()
        self.assertIsNotNone(self.user.last_login)

    def test_login_normalizes_email(self) -> None:
        response = self._login(email="User@Example.COM")
        self.assertEqual(response.status_code, 200)

    def test_login_invalid_email_format(self) -> None:
        response = self._login(email="not-an-email")
        self.assertEqual(response.status_code, 400)
        body = response.json()
        self.assertFalse(body["success"])
        self.assertEqual(body["code"], "VALIDATION_ERROR")

    def test_login_invalid_credentials(self) -> None:
        response = self._login(password="wrong-password-123")
        self.assertEqual(response.status_code, 401)
        body = response.json()
        self.assertEqual(body["code"], "INVALID_CREDENTIALS")
        self.assertEqual(body["message"], "Invalid email or password.")

    def test_login_unknown_email_does_not_enumerate(self) -> None:
        missing = self._login(email="nobody@example.com")
        wrong = self._login(password="wrong-password-123")
        self.assertEqual(missing.status_code, 401)
        self.assertEqual(missing.json()["code"], wrong.json()["code"])
        self.assertEqual(missing.json()["message"], wrong.json()["message"])

    def test_login_inactive_user(self) -> None:
        self.user.is_active = False
        self.user.save(update_fields=["is_active"])
        response = self._login()
        self.assertEqual(response.status_code, 403)
        self.assertEqual(response.json()["code"], "ACCOUNT_INACTIVE")

    def test_refresh_success_returns_rotated_refresh(self) -> None:
        tokens = self._tokens()
        response = self.client.post(
            f"{AUTH}/refresh/",
            {"refresh": tokens["refresh"]},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertIn("access", body["data"])
        self.assertIn("refresh", body["data"])
        self.assertNotEqual(body["data"]["refresh"], tokens["refresh"])

    def test_refresh_rejects_old_token_after_rotation(self) -> None:
        tokens = self._tokens()
        first = self.client.post(
            f"{AUTH}/refresh/",
            {"refresh": tokens["refresh"]},
            format="json",
        )
        self.assertEqual(first.status_code, 200)
        second = self.client.post(
            f"{AUTH}/refresh/",
            {"refresh": tokens["refresh"]},
            format="json",
        )
        self.assertEqual(second.status_code, 401)
        self.assertIn(second.json()["code"], {"TOKEN_BLACKLISTED", "TOKEN_INVALID"})

    def test_refresh_invalid_token(self) -> None:
        response = self.client.post(
            f"{AUTH}/refresh/",
            {"refresh": "not-a-token"},
            format="json",
        )
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["code"], "TOKEN_INVALID")

    def test_refresh_expired_token(self) -> None:
        refresh = RefreshToken.for_user(self.user)
        refresh.set_exp(lifetime=timedelta(seconds=-1))
        response = self.client.post(
            f"{AUTH}/refresh/",
            {"refresh": str(refresh)},
            format="json",
        )
        self.assertEqual(response.status_code, 401)
        self.assertIn(response.json()["code"], {"TOKEN_EXPIRED", "TOKEN_INVALID"})

    def test_logout_success_and_blacklists_refresh(self) -> None:
        tokens = self._tokens()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        response = self.client.post(
            f"{AUTH}/logout/",
            {"refresh": tokens["refresh"]},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["message"], "Logout successful.")
        self.assertEqual(response.json()["data"], {})

        replay = self.client.post(
            f"{AUTH}/refresh/",
            {"refresh": tokens["refresh"]},
            format="json",
        )
        self.assertEqual(replay.status_code, 401)

    def test_logout_missing_refresh(self) -> None:
        tokens = self._tokens()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        response = self.client.post(f"{AUTH}/logout/", {}, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "VALIDATION_ERROR")

    def test_logout_invalid_refresh(self) -> None:
        tokens = self._tokens()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        response = self.client.post(
            f"{AUTH}/logout/",
            {"refresh": "not-a-token"},
            format="json",
        )
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["code"], "TOKEN_INVALID")

    def test_logout_already_blacklisted_is_idempotent(self) -> None:
        tokens = self._tokens()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        first = self.client.post(
            f"{AUTH}/logout/",
            {"refresh": tokens["refresh"]},
            format="json",
        )
        second = self.client.post(
            f"{AUTH}/logout/",
            {"refresh": tokens["refresh"]},
            format="json",
        )
        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200)

    def test_me_requires_authentication(self) -> None:
        response = self.client.get(f"{AUTH}/me/")
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["code"], "UNAUTHORIZED")

    def test_me_rejects_invalid_access_token(self) -> None:
        self.client.credentials(HTTP_AUTHORIZATION="Bearer not-a-token")
        response = self.client.get(f"{AUTH}/me/")
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["code"], "TOKEN_INVALID")

    def test_me_returns_authenticated_user(self) -> None:
        tokens = self._tokens()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        response = self.client.get(f"{AUTH}/me/")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["message"], "User retrieved successfully.")
        data = body["data"]
        self.assertEqual(data["email"], "user@example.com")
        self.assertEqual(data["role"], "EMPLOYEE")
        self.assertTrue(data["is_active"])
        self.assertNotIn("company", data)
        self.assertNotIn("company_id", data)

    def test_forgot_password_existing_and_missing_look_the_same(self) -> None:
        existing = self.client.post(
            f"{AUTH}/forgot-password/",
            {"email": "user@example.com"},
            format="json",
        )
        missing = self.client.post(
            f"{AUTH}/forgot-password/",
            {"email": "nobody@example.com"},
            format="json",
        )
        self.assertEqual(existing.status_code, 200)
        self.assertEqual(missing.status_code, 200)
        self.assertEqual(existing.json()["message"], missing.json()["message"])
        self.assertEqual(existing.json()["data"], {})
        self.assertEqual(len(mail.outbox), 1)

    def test_forgot_password_invalid_email(self) -> None:
        response = self.client.post(
            f"{AUTH}/forgot-password/",
            {"email": "bad"},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "VALIDATION_ERROR")

    def _reset_payload(self, password="another-strong-pass-123", token=None, uid=None):
        self.user.refresh_from_db()
        return {
            "uid": uid or urlsafe_base64_encode(force_bytes(self.user.pk)),
            "token": token or PasswordResetTokenGenerator().make_token(self.user),
            "new_password": password,
            "confirm_password": password,
        }

    def test_reset_password_success_blacklists_refresh(self) -> None:
        tokens = self._tokens()
        response = self.client.post(
            f"{AUTH}/reset-password/",
            self._reset_payload(),
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["message"], "Password reset successful.")
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("another-strong-pass-123"))
        replay = self.client.post(
            f"{AUTH}/refresh/",
            {"refresh": tokens["refresh"]},
            format="json",
        )
        self.assertEqual(replay.status_code, 401)

    def test_reset_password_invalid_token(self) -> None:
        response = self.client.post(
            f"{AUTH}/reset-password/",
            self._reset_payload(token="invalid-token"),
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "PASSWORD_RESET_FAILED")

    def test_reset_password_invalid_uid(self) -> None:
        response = self.client.post(
            f"{AUTH}/reset-password/",
            self._reset_payload(uid="not-valid"),
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "PASSWORD_RESET_FAILED")

    def test_reset_password_mismatch(self) -> None:
        payload = self._reset_payload()
        payload["confirm_password"] = "does-not-match-123"
        response = self.client.post(
            f"{AUTH}/reset-password/",
            payload,
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "VALIDATION_ERROR")

    def test_reset_password_weak_password(self) -> None:
        response = self.client.post(
            f"{AUTH}/reset-password/",
            self._reset_payload(password="password"),
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "VALIDATION_ERROR")

    def test_reset_password_expired_token(self) -> None:
        payload = self._reset_payload()
        expired_now = datetime.now() + timedelta(days=2)
        with patch(
            "django.contrib.auth.tokens.PasswordResetTokenGenerator._now",
            return_value=expired_now,
        ):
            response = self.client.post(
                f"{AUTH}/reset-password/",
                payload,
                format="json",
            )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "PASSWORD_RESET_FAILED")
