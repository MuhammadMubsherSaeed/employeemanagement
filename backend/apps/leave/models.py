import re
import uuid
from pathlib import Path

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import FileExtensionValidator, MinValueValidator
from django.db import models
from django.db.models import F, Q

from apps.common.models import TimeStampedModel
from apps.common.storage import STORAGE_OBJECT_KEY_MAX_LENGTH
from apps.companies.models import Company
from apps.employees.models import Employee, OrgStatus

LEAVE_CODE_RE = re.compile(r"^[A-Z0-9_]+$")
MAX_REASON_LENGTH = 1000
MAX_REJECTION_LENGTH = 500
MIN_REJECTION_LENGTH = 3
ALLOWED_ATTACHMENT_EXTENSIONS = ("pdf", "png", "jpg", "jpeg", "webp", "doc", "docx")
BLOCKED_ATTACHMENT_EXTENSIONS = frozenset(
    {".exe", ".bat", ".cmd", ".com", ".msi", ".js", ".sh", ".ps1", ".dll"}
)


from apps.documents.models import (
    LEAVE_SNIFF_EXTENSIONS,
    is_committed_storage_file,
    leave_attachment_object_path,
    sniff_document_kind,
)


def leave_attachment_path(instance, filename: str) -> str:
    return leave_attachment_object_path(instance, filename)


def validate_leave_attachment(file) -> None:
    if is_committed_storage_file(file):
        return
    name = getattr(file, "name", "") or ""
    suffix = Path(name).suffix.lower()
    if suffix in BLOCKED_ATTACHMENT_EXTENSIONS:
        raise ValidationError("This file type is not allowed.")
    allowed = {f".{ext}" for ext in ALLOWED_ATTACHMENT_EXTENSIONS}
    if suffix not in allowed:
        raise ValidationError("Attachment must be a PDF, image, or Word document.")
    max_bytes = int(getattr(settings, "LEAVE_ATTACHMENT_MAX_BYTES", 5 * 1024 * 1024))
    size = getattr(file, "size", None)
    if size is None or size <= 0:
        raise ValidationError("Upload a file.")
    if size > max_bytes:
        raise ValidationError("Attachment is too large.")
    kind = sniff_document_kind(file)
    if kind not in LEAVE_SNIFF_EXTENSIONS.get(suffix, set()):
        raise ValidationError("File content does not match the file extension.")


class LeaveTypeStatus(models.TextChoices):
    ACTIVE = OrgStatus.ACTIVE, "Active"
    INACTIVE = OrgStatus.INACTIVE, "Inactive"


class LeaveRequestStatus(models.TextChoices):
    PENDING = "PENDING", "Pending"
    APPROVED = "APPROVED", "Approved"
    REJECTED = "REJECTED", "Rejected"
    CANCELLED = "CANCELLED", "Cancelled"


ACTIVE_LEAVE_STATUSES = (
    LeaveRequestStatus.PENDING,
    LeaveRequestStatus.APPROVED,
)


class LeaveType(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="leave_types",
    )
    name = models.CharField(max_length=128)
    code = models.CharField(max_length=32)
    days_allowed = models.PositiveIntegerField(default=0)
    is_paid = models.BooleanField(default=True)
    carry_forward = models.BooleanField(default=False)
    status = models.CharField(
        max_length=16,
        choices=LeaveTypeStatus.choices,
        default=LeaveTypeStatus.ACTIVE,
        db_index=True,
    )

    class Meta:
        ordering = ("name",)
        constraints = [
            models.UniqueConstraint(
                fields=("company", "code"),
                name="uniq_leavetype_company_code",
            ),
            models.CheckConstraint(
                condition=Q(days_allowed__gte=0),
                name="leave_type_days_allowed_gte_0",
            ),
        ]
        indexes = [
            models.Index(fields=("company", "status")),
            models.Index(fields=("company", "code")),
        ]

    def __str__(self) -> str:
        return f"{self.code} ({self.company})"

    def clean(self) -> None:
        errors: dict[str, str] = {}
        self.name = (self.name or "").strip()
        if len(self.name) < 2:
            errors["name"] = "Enter a leave type name."
        self.code = (self.code or "").strip().upper()
        if not LEAVE_CODE_RE.match(self.code):
            errors["code"] = (
                "Code must be uppercase letters, numbers, or underscores."
            )
        if errors:
            raise ValidationError(errors)

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class LeaveBalance(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="leave_balances",
    )
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name="leave_balances",
    )
    leave_type = models.ForeignKey(
        LeaveType,
        on_delete=models.PROTECT,
        related_name="balances",
    )
    year = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(2000)],
        db_index=True,
    )
    allocated_days = models.PositiveIntegerField(default=0)
    used_days = models.PositiveIntegerField(default=0)
    remaining_days = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ("-year", "leave_type__name")
        constraints = [
            models.UniqueConstraint(
                fields=("employee", "leave_type", "year"),
                name="uniq_leavebalance_employee_type_year",
            ),
            models.CheckConstraint(
                condition=Q(allocated_days__gte=0),
                name="leave_balance_allocated_gte_0",
            ),
            models.CheckConstraint(
                condition=Q(used_days__gte=0),
                name="leave_balance_used_gte_0",
            ),
            models.CheckConstraint(
                condition=Q(remaining_days__gte=0),
                name="leave_balance_remaining_gte_0",
            ),
            models.CheckConstraint(
                condition=Q(used_days__lte=F("allocated_days")),
                name="leave_balance_used_lte_allocated",
            ),
        ]
        indexes = [
            models.Index(fields=("employee", "year")),
            models.Index(fields=("leave_type", "year")),
            models.Index(fields=("company", "year")),
            models.Index(fields=("employee",)),
        ]

    def __str__(self) -> str:
        return f"{self.employee} {self.leave_type.code} {self.year}"

    def recast_remaining(self) -> None:
        self.remaining_days = self.allocated_days - self.used_days

    def clean(self) -> None:
        errors: dict[str, str] = {}
        if self.employee_id and self.company_id:
            if self.employee.company_id != self.company_id:
                errors["employee"] = "Employee must belong to the same company."
        if self.leave_type_id and self.company_id:
            if self.leave_type.company_id != self.company_id:
                errors["leave_type"] = "Leave type must belong to the same company."
        if self.employee_id and self.leave_type_id:
            if self.employee.company_id != self.leave_type.company_id:
                errors["leave_type"] = (
                    "Employee and leave type must belong to the same company."
                )
        if self.used_days > self.allocated_days:
            errors["used_days"] = "Used days cannot exceed allocated days."
        if errors:
            raise ValidationError(errors)
        self.recast_remaining()

    def save(self, *args, **kwargs):
        if self.company_id is None and self.employee_id:
            self.company_id = self.employee.company_id
        self.recast_remaining()
        self.full_clean()
        return super().save(*args, **kwargs)


class LeaveRequest(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="leave_requests",
    )
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name="leave_requests",
    )
    leave_type = models.ForeignKey(
        LeaveType,
        on_delete=models.PROTECT,
        related_name="requests",
    )
    start_date = models.DateField(db_index=True)
    end_date = models.DateField(db_index=True)
    total_days = models.PositiveIntegerField()
    reason = models.TextField(max_length=MAX_REASON_LENGTH, blank=True)
    attachment = models.FileField(
        upload_to=leave_attachment_path,
        max_length=STORAGE_OBJECT_KEY_MAX_LENGTH,
        blank=True,
        null=True,
        validators=[
            FileExtensionValidator(ALLOWED_ATTACHMENT_EXTENSIONS),
            validate_leave_attachment,
        ],
    )
    status = models.CharField(
        max_length=16,
        choices=LeaveRequestStatus.choices,
        default=LeaveRequestStatus.PENDING,
        db_index=True,
    )
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="leave_decisions",
    )
    approved_at = models.DateTimeField(null=True, blank=True)
    rejection_reason = models.CharField(max_length=MAX_REJECTION_LENGTH, blank=True)

    class Meta:
        ordering = ("-start_date", "-created_at")
        constraints = [
            models.CheckConstraint(
                condition=Q(total_days__gt=0),
                name="leave_request_total_days_gt_0",
            ),
            models.CheckConstraint(
                condition=Q(end_date__gte=F("start_date")),
                name="leave_request_end_on_or_after_start",
            ),
        ]
        indexes = [
            models.Index(fields=("company", "status")),
            models.Index(fields=("employee", "status")),
            models.Index(fields=("leave_type",)),
            models.Index(fields=("start_date", "end_date")),
            models.Index(fields=("company", "employee", "status")),
            models.Index(fields=("company", "start_date")),
        ]

    def __str__(self) -> str:
        return f"{self.employee} {self.start_date}–{self.end_date} {self.status}"

    def clean(self) -> None:
        errors: dict[str, str] = {}
        if self.employee_id and self.company_id:
            if self.employee.company_id != self.company_id:
                errors["employee"] = "Employee must belong to the same company."
        if self.leave_type_id and self.company_id:
            if self.leave_type.company_id != self.company_id:
                errors["leave_type"] = "Leave type must belong to the same company."
        if self.start_date and self.end_date and self.start_date > self.end_date:
            errors["end_date"] = "end_date must be on or after start_date."
        if errors:
            raise ValidationError(errors)

    def save(self, *args, **kwargs):
        if self.company_id is None and self.employee_id:
            self.company_id = self.employee.company_id
        self.full_clean()
        return super().save(*args, **kwargs)
