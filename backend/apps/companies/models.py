import uuid
from pathlib import Path
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import (
    FileExtensionValidator,
    MaxValueValidator,
    MinValueValidator,
)
from django.db import models

from apps.accounts.models import Role, RoleScope, UserRole
from apps.common.models import TimeStampedModel
from apps.companies.constants import (
    BLOCKED_LOGO_EXTENSIONS,
    DEFAULT_GRACE_MINUTES,
    DEFAULT_MINIMUM_WORKING_MINUTES,
    DEFAULT_WORK_END,
    DEFAULT_WORK_START,
    LOGO_ALLOWED_EXTENSIONS,
    LOGO_MAX_BYTES,
    MAX_GRACE_MINUTES,
    MAX_MINIMUM_WORKING_MINUTES,
    WEEKDAY_MONDAY,
    default_timezone,
    default_working_days,
    normalize_working_days,
    settings_logo_path,
)

# Re-exported so existing imports of WEEKDAY_* from models keep working.
DEFAULT_WORKING_DAYS = [WEEKDAY_MONDAY, 1, 2, 3, 4]


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

    def save(self, *args, **kwargs):
        created = self._state.adding
        result = super().save(*args, **kwargs)
        if created:
            CompanySettings.objects.get_or_create(company=self)
        return result


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


class CompanySettings(TimeStampedModel):
    """Tenant-wide HR settings owned by Company and consumed by Attendance."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.OneToOneField(
        Company,
        on_delete=models.CASCADE,
        related_name="settings",
    )
    logo = models.FileField(
        upload_to=settings_logo_path,
        blank=True,
        null=True,
        validators=[FileExtensionValidator(LOGO_ALLOWED_EXTENSIONS)],
    )
    timezone = models.CharField(
        max_length=64,
        default=default_timezone,
        help_text="IANA timezone used for attendance dates and work-hour rules.",
    )
    work_start_time = models.TimeField(default=DEFAULT_WORK_START)
    work_end_time = models.TimeField(default=DEFAULT_WORK_END)
    grace_period_minutes = models.PositiveIntegerField(
        default=DEFAULT_GRACE_MINUTES,
        validators=[
            MinValueValidator(0),
            MaxValueValidator(MAX_GRACE_MINUTES),
        ],
    )
    minimum_working_minutes = models.PositiveIntegerField(
        default=DEFAULT_MINIMUM_WORKING_MINUTES,
        validators=[
            MinValueValidator(1),
            MaxValueValidator(MAX_MINIMUM_WORKING_MINUTES),
        ],
    )
    overtime_enabled = models.BooleanField(default=False)
    working_days = models.JSONField(default=default_working_days)

    class Meta:
        verbose_name = "company settings"
        verbose_name_plural = "company settings"

    def __str__(self) -> str:
        return f"Settings for {self.company}"

    def clean(self) -> None:
        errors: dict[str, str] = {}
        try:
            ZoneInfo(self.timezone)
        except (ZoneInfoNotFoundError, KeyError, ValueError):
            errors["timezone"] = "Unknown IANA timezone."
        if self.work_end_time <= self.work_start_time:
            errors["work_end_time"] = (
                "Overnight shifts are not supported. "
                "work_end_time must be after work_start_time."
            )
        if self.grace_period_minutes is not None and (
            self.grace_period_minutes < 0
            or self.grace_period_minutes > MAX_GRACE_MINUTES
        ):
            errors["grace_period_minutes"] = (
                f"Grace period must be between 0 and {MAX_GRACE_MINUTES} minutes."
            )
        if self.minimum_working_minutes is not None and (
            self.minimum_working_minutes < 1
            or self.minimum_working_minutes > MAX_MINIMUM_WORKING_MINUTES
        ):
            errors["minimum_working_minutes"] = (
                "Minimum working minutes must be between 1 and "
                f"{MAX_MINIMUM_WORKING_MINUTES}."
            )
        try:
            self.working_days = normalize_working_days(self.working_days)
        except ValueError as exc:
            errors["working_days"] = str(exc)
        if self.logo:
            name = getattr(self.logo, "name", "") or ""
            suffix = Path(name).suffix.lower()
            if suffix in BLOCKED_LOGO_EXTENSIONS:
                errors["logo"] = "This file type is not allowed."
            size = getattr(self.logo, "size", None)
            if size is not None and size > LOGO_MAX_BYTES:
                errors["logo"] = "Logo must be 2 MB or smaller."
        if errors:
            raise ValidationError(errors)

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)

    def zoneinfo(self) -> ZoneInfo:
        return ZoneInfo(self.timezone)

    def is_working_weekday(self, weekday: int) -> bool:
        return weekday in self.working_days
