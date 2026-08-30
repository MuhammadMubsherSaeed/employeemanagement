import uuid

from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.db.models import F, Q

from apps.common.models import TimeStampedModel
from apps.companies.models import Company
from apps.employees.models import Employee


class AttendanceStatus(models.TextChoices):
    PRESENT = "PRESENT", "Present"
    ABSENT = "ABSENT", "Absent"
    LATE = "LATE", "Late"
    HALF_DAY = "HALF_DAY", "Half day"
    LEAVE = "LEAVE", "Leave"
    HOLIDAY = "HOLIDAY", "Holiday"
    WEEKEND = "WEEKEND", "Weekend"


class Holiday(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="holidays",
    )
    name = models.CharField(max_length=128)
    date = models.DateField(db_index=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True, db_index=True)

    class Meta:
        ordering = ("-date", "name")
        constraints = [
            models.UniqueConstraint(
                fields=("company", "date"),
                name="uniq_holiday_company_date",
            ),
        ]
        indexes = [
            models.Index(fields=("company", "date")),
            models.Index(fields=("company", "is_active", "date")),
        ]

    def __str__(self) -> str:
        return f"{self.date} {self.name}"

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class Attendance(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="attendances",
    )
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name="attendances",
    )
    date = models.DateField(db_index=True)
    check_in = models.DateTimeField(null=True, blank=True)
    check_out = models.DateTimeField(null=True, blank=True)
    total_minutes = models.PositiveIntegerField(null=True, blank=True)
    status = models.CharField(
        max_length=16,
        choices=AttendanceStatus.choices,
        db_index=True,
    )
    check_in_ip = models.GenericIPAddressField(null=True, blank=True)
    check_out_ip = models.GenericIPAddressField(null=True, blank=True)
    check_in_latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        validators=[MinValueValidator(-90), MaxValueValidator(90)],
    )
    check_in_longitude = models.DecimalField(
        max_digits=10,
        decimal_places=6,
        null=True,
        blank=True,
        validators=[MinValueValidator(-180), MaxValueValidator(180)],
    )
    check_out_latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        validators=[MinValueValidator(-90), MaxValueValidator(90)],
    )
    check_out_longitude = models.DecimalField(
        max_digits=10,
        decimal_places=6,
        null=True,
        blank=True,
        validators=[MinValueValidator(-180), MaxValueValidator(180)],
    )

    class Meta:
        ordering = ("-date", "-check_in")
        constraints = [
            models.UniqueConstraint(
                fields=("company", "employee", "date"),
                name="uniq_attendance_company_employee_date",
            ),
            models.CheckConstraint(
                condition=Q(check_out__isnull=True)
                | Q(check_in__isnull=True)
                | Q(check_out__gte=F("check_in")),
                name="attendance_checkout_not_before_checkin",
            ),
        ]
        indexes = [
            models.Index(fields=("company", "date")),
            models.Index(fields=("company", "status", "date")),
            models.Index(fields=("employee", "date")),
            models.Index(fields=("company", "check_in")),
            models.Index(fields=("company", "check_out")),
        ]

    def __str__(self) -> str:
        return f"{self.employee} {self.date} {self.status}"

    def clean(self) -> None:
        errors: dict[str, str] = {}
        if self.employee_id and self.company_id:
            if self.employee.company_id != self.company_id:
                errors["employee"] = "Employee must belong to the same company."
        if (
            self.check_in is not None
            and self.check_out is not None
            and self.check_out < self.check_in
        ):
            errors["check_out"] = "Check-out cannot be before check-in."
        if errors:
            raise ValidationError(errors)

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)
