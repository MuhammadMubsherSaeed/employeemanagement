from typing import ClassVar

from django.contrib.auth.base_user import AbstractBaseUser
from django.contrib.auth.models import PermissionsMixin
from django.db import models

from apps.accounts.managers import UserManager
from apps.common.models import TimeStampedModel


class UserRole(models.TextChoices):
    """Platform vs company roles.

    SUPER_ADMIN is platform-level. COMPANY_ADMIN, MANAGER, and EMPLOYEE are
    company-level. Tenant assignment is implemented in a later prompt.
    """

    SUPER_ADMIN = "SUPER_ADMIN", "Super Admin"
    COMPANY_ADMIN = "COMPANY_ADMIN", "Company Admin"
    MANAGER = "MANAGER", "Manager"
    EMPLOYEE = "EMPLOYEE", "Employee"


class User(AbstractBaseUser, PermissionsMixin, TimeStampedModel):
    """Email-identified user. No company FK yet — keep this model extensible."""

    Role = UserRole

    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    role = models.CharField(
        max_length=32,
        choices=UserRole.choices,
        default=UserRole.EMPLOYEE,
        db_index=True,
    )
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS: ClassVar[list[str]] = []

    class Meta:
        verbose_name = "user"
        verbose_name_plural = "users"
        ordering = ("email",)

    def __str__(self) -> str:
        return self.email

    def get_full_name(self) -> str:
        name = f"{self.first_name} {self.last_name}".strip()
        return name or self.email

    def get_short_name(self) -> str:
        return self.first_name or self.email
