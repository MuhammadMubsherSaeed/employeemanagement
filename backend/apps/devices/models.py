import re
import uuid
from decimal import Decimal

from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator
from django.db import models
from django.db.models import F, Q

from apps.common.models import TimeStampedModel
from apps.companies.models import Company
from apps.employees.models import Employee

ASSET_CODE_RE = re.compile(r"^[A-Z0-9][A-Z0-9_-]*$")
MAX_ASSET_CODE_LENGTH = 64
MAX_TYPE_LENGTH = 64
MAX_NAME_LENGTH = 128
MAX_SERIAL_LENGTH = 128
MAX_CONDITION_LENGTH = 2000
MAX_NOTES_LENGTH = 2000


class DeviceStatus(models.TextChoices):
    AVAILABLE = "AVAILABLE", "Available"
    ASSIGNED = "ASSIGNED", "Assigned"
    MAINTENANCE = "MAINTENANCE", "Maintenance"
    RETIRED = "RETIRED", "Retired"
    LOST = "LOST", "Lost"


# Status changes that may go through update/change_status.
# ASSIGNED is never set here — only DeviceService.assign_device.
# AVAILABLE from ASSIGNED is never set here — only DeviceService.return_device.
STATUS_TRANSITIONS = {
    DeviceStatus.AVAILABLE: frozenset(
        {
            DeviceStatus.MAINTENANCE,
            DeviceStatus.RETIRED,
            DeviceStatus.LOST,
        }
    ),
    DeviceStatus.ASSIGNED: frozenset({DeviceStatus.LOST}),
    DeviceStatus.MAINTENANCE: frozenset(
        {
            DeviceStatus.AVAILABLE,
            DeviceStatus.RETIRED,
        }
    ),
    DeviceStatus.RETIRED: frozenset(),
    DeviceStatus.LOST: frozenset(),
}


class Device(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="devices",
    )
    asset_code = models.CharField(max_length=MAX_ASSET_CODE_LENGTH)
    type = models.CharField(max_length=MAX_TYPE_LENGTH)
    manufacturer = models.CharField(max_length=MAX_NAME_LENGTH, blank=True)
    model = models.CharField(max_length=MAX_NAME_LENGTH, blank=True)
    serial_number = models.CharField(
        max_length=MAX_SERIAL_LENGTH,
        blank=True,
        null=True,
    )
    purchase_date = models.DateField(null=True, blank=True)
    warranty_expiry = models.DateField(null=True, blank=True)
    cost = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00"),
        validators=[MinValueValidator(Decimal("0.00"))],
    )
    status = models.CharField(
        max_length=16,
        choices=DeviceStatus.choices,
        default=DeviceStatus.AVAILABLE,
        db_index=True,
    )
    notes = models.TextField(max_length=MAX_NOTES_LENGTH, blank=True)

    class Meta:
        ordering = ("asset_code",)
        constraints = [
            models.UniqueConstraint(
                fields=("company", "asset_code"),
                name="uniq_device_company_asset_code",
            ),
            models.UniqueConstraint(
                fields=("company", "serial_number"),
                condition=Q(serial_number__isnull=False),
                name="uniq_device_company_serial_number",
            ),
            models.CheckConstraint(
                condition=Q(cost__gte=0),
                name="device_cost_gte_0",
            ),
            models.CheckConstraint(
                condition=(
                    Q(warranty_expiry__isnull=True)
                    | Q(purchase_date__isnull=True)
                    | Q(warranty_expiry__gte=F("purchase_date"))
                ),
                name="device_warranty_on_or_after_purchase",
            ),
        ]
        indexes = [
            models.Index(fields=("company",)),
            models.Index(fields=("status",)),
            models.Index(fields=("type",)),
            models.Index(fields=("asset_code",)),
            models.Index(fields=("serial_number",)),
            models.Index(fields=("company", "status")),
            models.Index(fields=("company", "asset_code")),
        ]

    def __str__(self) -> str:
        return f"{self.asset_code} ({self.company})"

    def normalize(self) -> None:
        self.asset_code = (self.asset_code or "").strip().upper()
        self.type = (self.type or "").strip()
        self.manufacturer = (self.manufacturer or "").strip()
        self.model = (self.model or "").strip()
        serial = (self.serial_number or "").strip()
        self.serial_number = serial or None
        self.notes = (self.notes or "").strip()

    def clean(self) -> None:
        self.normalize()
        errors: dict[str, str] = {}
        if not ASSET_CODE_RE.match(self.asset_code):
            errors["asset_code"] = (
                "Asset code must start with a letter or number and contain "
                "only letters, numbers, hyphens, or underscores."
            )
        if len(self.type) < 2:
            errors["type"] = "Enter a device type."
        if self.cost is not None and self.cost < 0:
            errors["cost"] = "Cost cannot be negative."
        if (
            self.purchase_date
            and self.warranty_expiry
            and self.warranty_expiry < self.purchase_date
        ):
            errors["warranty_expiry"] = (
                "Warranty expiry must be on or after the purchase date."
            )
        if errors:
            raise ValidationError(errors)

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class DeviceAssignment(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="device_assignments",
    )
    device = models.ForeignKey(
        Device,
        on_delete=models.PROTECT,
        related_name="assignments",
    )
    employee = models.ForeignKey(
        Employee,
        on_delete=models.PROTECT,
        related_name="device_assignments",
    )
    assigned_at = models.DateTimeField(db_index=True)
    returned_at = models.DateTimeField(null=True, blank=True)
    condition_on_assignment = models.TextField(
        max_length=MAX_CONDITION_LENGTH,
        blank=True,
    )
    condition_on_return = models.TextField(
        max_length=MAX_CONDITION_LENGTH,
        blank=True,
    )
    notes = models.TextField(max_length=MAX_NOTES_LENGTH, blank=True)

    class Meta:
        ordering = ("-assigned_at", "-created_at")
        constraints = [
            models.UniqueConstraint(
                fields=("device",),
                condition=Q(returned_at__isnull=True),
                name="uniq_deviceassignment_active_device",
            ),
            models.CheckConstraint(
                condition=(
                    Q(returned_at__isnull=True)
                    | Q(returned_at__gte=F("assigned_at"))
                ),
                name="deviceassignment_return_on_or_after_assign",
            ),
        ]
        indexes = [
            models.Index(fields=("device",)),
            models.Index(fields=("employee",)),
            models.Index(fields=("assigned_at",)),
            models.Index(fields=("returned_at",)),
            models.Index(fields=("device", "returned_at")),
            models.Index(fields=("company", "device")),
        ]

    def __str__(self) -> str:
        return f"{self.device.asset_code} → {self.employee}"

    @property
    def is_active(self) -> bool:
        return self.returned_at is None

    def clean(self) -> None:
        errors: dict[str, str] = {}
        if self.device_id and self.company_id:
            if self.device.company_id != self.company_id:
                errors["device"] = "Device must belong to the same company."
        if self.employee_id and self.company_id:
            if self.employee.company_id != self.company_id:
                errors["employee"] = "Employee must belong to the same company."
        if self.device_id and self.employee_id:
            if self.device.company_id != self.employee.company_id:
                errors["employee"] = (
                    "Device and employee must belong to the same company."
                )
        if (
            self.returned_at
            and self.assigned_at
            and self.returned_at < self.assigned_at
        ):
            errors["returned_at"] = "returned_at must be on or after assigned_at."
        if self.returned_at is None and self.device_id:
            conflict = DeviceAssignment.objects.filter(
                device_id=self.device_id,
                returned_at__isnull=True,
            )
            if self.pk:
                conflict = conflict.exclude(pk=self.pk)
            if conflict.exists():
                errors["device"] = "This device already has an active assignment."
        if errors:
            raise ValidationError(errors)

    def save(self, *args, **kwargs):
        if self.company_id is None and self.device_id:
            self.company_id = self.device.company_id
        self.full_clean()
        return super().save(*args, **kwargs)
