import uuid

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models

from apps.accounts.models import Role, RoleScope, UserRole
from apps.common.models import TimeStampedModel


class Company(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=64, unique=True)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=32, blank=True)
    website = models.URLField(blank=True)
    logo = models.CharField(max_length=512, blank=True)
    is_active = models.BooleanField(default=True, db_index=True)

    class Meta:
        ordering = ("name",)
        verbose_name_plural = "companies"
        indexes = [
            models.Index(fields=("is_active", "slug")),
        ]

    def __str__(self) -> str:
        return self.name


class CompanyMembership(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="memberships",
    )
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="memberships",
    )
    role = models.ForeignKey(
        Role,
        on_delete=models.PROTECT,
        related_name="memberships",
    )
    is_active = models.BooleanField(default=True, db_index=True)

    class Meta:
        ordering = ("-created_at",)
        constraints = [
            models.UniqueConstraint(
                fields=("user", "company"),
                name="uniq_membership_user_company",
            ),
            models.UniqueConstraint(
                fields=("user",),
                condition=models.Q(is_active=True),
                name="uniq_one_active_membership_per_user",
            ),
        ]
        indexes = [
            models.Index(fields=("user", "is_active")),
            models.Index(fields=("company", "is_active")),
        ]

    def __str__(self) -> str:
        return f"{self.user} @ {self.company} ({self.role.code})"

    def clean(self) -> None:
        if self.role_id and self.role.scope != RoleScope.COMPANY:
            raise ValidationError(
                {"role": "Platform roles cannot be assigned as company membership."}
            )
        if self.role_id and self.role.code == UserRole.SUPER_ADMIN:
            raise ValidationError(
                {"role": "SUPER_ADMIN cannot be granted through membership."}
            )

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class RecordVisibility(models.TextChoices):
    COMPANY = "COMPANY", "Company"
    PRIVATE = "PRIVATE", "Private"


class TenantOwnedRecord(TimeStampedModel):
    """Reference tenant-owned row. Future HR models should follow this pattern.

    Not an Employee/Attendance product model. Used to enforce and test
    tenant isolation, writes, and object-level rules.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="owned_records",
    )
    title = models.CharField(max_length=120)
    visibility = models.CharField(
        max_length=16,
        choices=RecordVisibility.choices,
        default=RecordVisibility.COMPANY,
        db_index=True,
    )
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="owned_records",
    )
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assigned_records",
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=("company", "visibility")),
            models.Index(fields=("company", "owner")),
        ]

    def __str__(self) -> str:
        return self.title
