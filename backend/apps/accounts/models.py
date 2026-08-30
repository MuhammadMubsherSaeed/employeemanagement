from typing import ClassVar

from django.contrib.auth.base_user import AbstractBaseUser
from django.contrib.auth.models import PermissionsMixin
from django.db import models
from django.db.models.deletion import ProtectedError

from apps.accounts.managers import UserManager
from apps.common.models import TimeStampedModel


class UserRole(models.TextChoices):
    """Platform vs company roles.

    SUPER_ADMIN is platform-level. COMPANY_ADMIN, MANAGER, and EMPLOYEE are
    assigned through CompanyMembership. User.role remains SUPER_ADMIN for
    platform operators; company roles are authoritative on membership.
    """

    SUPER_ADMIN = "SUPER_ADMIN", "Super Admin"
    COMPANY_ADMIN = "COMPANY_ADMIN", "Company Admin"
    MANAGER = "MANAGER", "Manager"
    EMPLOYEE = "EMPLOYEE", "Employee"


class RoleScope(models.TextChoices):
    PLATFORM = "PLATFORM", "Platform"
    COMPANY = "COMPANY", "Company"


class Permission(TimeStampedModel):
    """Application permission. Not Django ContentType permissions."""

    code = models.CharField(max_length=64, unique=True, db_index=True)
    name = models.CharField(max_length=128)
    description = models.TextField(blank=True)
    module = models.CharField(max_length=32, db_index=True)

    class Meta:
        ordering = ("code",)

    def __str__(self) -> str:
        return self.code


class Role(TimeStampedModel):
    name = models.CharField(max_length=64)
    code = models.CharField(max_length=32, db_index=True)
    scope = models.CharField(max_length=16, choices=RoleScope.choices)
    description = models.TextField(blank=True)
    is_system_role = models.BooleanField(default=True)
    permissions = models.ManyToManyField(
        Permission,
        blank=True,
        related_name="roles",
    )

    class Meta:
        ordering = ("scope", "code")
        constraints = [
            models.UniqueConstraint(
                fields=("code", "scope"),
                name="uniq_role_code_scope",
            ),
        ]

    def __str__(self) -> str:
        return f"{self.code} ({self.scope})"

    def delete(self, using=None, keep_parents=False):
        if self.is_system_role:
            raise ProtectedError("System roles cannot be deleted.", [self])
        return super().delete(using=using, keep_parents=keep_parents)


class User(AbstractBaseUser, PermissionsMixin, TimeStampedModel):
    """Email-identified user. Tenant access is via CompanyMembership."""

    Role = UserRole

    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    role = models.CharField(
        max_length=32,
        choices=UserRole.choices,
        default=UserRole.EMPLOYEE,
        db_index=True,
        help_text=(
            "Platform SUPER_ADMIN lives here. Company roles are stored on "
            "CompanyMembership; this field is kept for Django admin and "
            "users without a membership."
        ),
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

    @property
    def is_platform_admin(self) -> bool:
        return self.role == UserRole.SUPER_ADMIN or self.is_superuser

    def get_active_membership(self):
        from apps.companies.models import CompanyMembership

        return (
            CompanyMembership.objects.select_related("company", "role")
            .prefetch_related("role__permissions")
            .filter(user=self, is_active=True, company__is_active=True)
            .order_by("-updated_at", "-created_at")
            .first()
        )

    @property
    def current_company(self):
        if self.is_platform_admin:
            return None
        membership = self.get_active_membership()
        return membership.company if membership else None

    def resolve_role_code(self) -> str:
        if self.is_platform_admin:
            return UserRole.SUPER_ADMIN
        membership = self.get_active_membership()
        if membership is not None:
            return membership.role.code
        return self.role
