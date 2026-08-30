from django.contrib.auth import get_user_model
from django.test import TestCase

from apps.accounts.models import UserRole

User = get_user_model()


class UserModelTests(TestCase):
    def test_email_is_the_authentication_identifier(self) -> None:
        self.assertEqual(User.USERNAME_FIELD, "email")
        self.assertFalse(User.REQUIRED_FIELDS)

    def test_create_user_normalizes_email(self) -> None:
        user = User.objects.create_user(
            email="Ada@Example.COM",
            password="a-strong-password-123",
            first_name="Ada",
        )
        self.assertEqual(user.email, "Ada@example.com")
        self.assertTrue(user.check_password("a-strong-password-123"))
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)
        self.assertEqual(user.role, UserRole.EMPLOYEE)

    def test_create_user_requires_email(self) -> None:
        with self.assertRaisesMessage(ValueError, "Email is required."):
            User.objects.create_user(email="", password="x")

    def test_create_superuser_sets_platform_role(self) -> None:
        admin = User.objects.create_superuser(
            email="ops@example.com",
            password="a-strong-password-123",
        )
        self.assertTrue(admin.is_staff)
        self.assertTrue(admin.is_superuser)
        self.assertEqual(admin.role, UserRole.SUPER_ADMIN)

    def test_create_superuser_rejects_is_superuser_false(self) -> None:
        with self.assertRaisesMessage(
            ValueError, "Superuser must have is_superuser=True."
        ):
            User.objects.create_superuser(
                email="bad@example.com",
                password="x",
                is_superuser=False,
            )
