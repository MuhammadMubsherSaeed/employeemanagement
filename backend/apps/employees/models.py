import uuid

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models import F, Q

from apps.common.models import TimeStampedModel
from apps.companies.models import Company


class EmploymentType(models.TextChoices):
    FULL_TIME = "FULL_TIME", "Full time"
    PART_TIME = "PART_TIME", "Part time"
    CONTRACT = "CONTRACT", "Contract"
    INTERN = "INTERN", "Intern"
    TEMPORARY = "TEMPORARY", "Temporary"


class EmployeeStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    INACTIVE = "INACTIVE", "Inactive"
    ON_LEAVE = "ON_LEAVE", "On leave"
    TERMINATED = "TERMINATED", "Terminated"


class OrgStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    INACTIVE = "INACTIVE", "Inactive"


class Gender(models.TextChoices):
    MALE = "MALE", "Male"
    FEMALE = "FEMALE", "Female"
    OTHER = "OTHER", "Other"
    PREFER_NOT_TO_SAY = "PREFER_NOT_TO_SAY", "Prefer not to say"


class Department(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="departments",
    )
    name = models.CharField(max_length=128)
    description = models.TextField(blank=True)
    manager = models.ForeignKey(
        "Employee",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="managed_departments",
    )
    status = models.CharField(
        max_length=16,
        choices=OrgStatus.choices,
        default=OrgStatus.ACTIVE,
        db_index=True,
    )

    class Meta:
        ordering = ("name",)
        constraints = [
            models.UniqueConstraint(
                fields=("company", "name"),
                name="uniq_department_company_name",
            ),
        ]
        indexes = [
            models.Index(fields=("company", "status")),
            models.Index(fields=("company", "name")),
        ]

    def __str__(self) -> str:
        return self.name

    def clean(self) -> None:
        if self.manager_id and self.company_id:
            if self.manager.company_id != self.company_id:
                raise ValidationError(
                    {"manager": "Department manager must belong to the same company."}
                )

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class Position(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="positions",
    )
    department = models.ForeignKey(
        Department,
        on_delete=models.PROTECT,
        related_name="positions",
    )
    title = models.CharField(max_length=128)
    description = models.TextField(blank=True)
    status = models.CharField(
        max_length=16,
        choices=OrgStatus.choices,
        default=OrgStatus.ACTIVE,
        db_index=True,
    )

    class Meta:
        ordering = ("title",)
        constraints = [
            models.UniqueConstraint(
                fields=("company", "department", "title"),
                name="uniq_position_company_department_title",
            ),
        ]
        indexes = [
            models.Index(fields=("company", "status")),
            models.Index(fields=("company", "department")),
            models.Index(fields=("department", "title")),
        ]

    def __str__(self) -> str:
        return self.title

    def clean(self) -> None:
        if self.department_id and self.company_id:
            if self.department.company_id != self.company_id:
                raise ValidationError(
                    {
                        "department": (
                            "Position department must belong to the same company."
                        )
                    }
                )

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class Employee(TimeStampedModel):
    """Company-scoped HR profile. Login identity stays on User + membership."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="employees",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="employee_profiles",
    )
    employee_code = models.CharField(max_length=32)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    profile_image = models.CharField(max_length=512, blank=True)
    gender = models.CharField(
        max_length=32,
        choices=Gender.choices,
        blank=True,
    )
    date_of_birth = models.DateField(null=True, blank=True)
    phone = models.CharField(max_length=32, blank=True)
    address = models.TextField(blank=True)
    emergency_contact_name = models.CharField(max_length=150, blank=True)
    emergency_contact_relationship = models.CharField(max_length=64, blank=True)
    emergency_contact_phone = models.CharField(max_length=32, blank=True)
    department = models.ForeignKey(
        Department,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="employees",
    )
    position = models.ForeignKey(
        Position,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="employees",
    )
    manager = models.ForeignKey(
        "self",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="direct_reports",
    )
    joining_date = models.DateField(null=True, blank=True)
    employment_type = models.CharField(
        max_length=16,
        choices=EmploymentType.choices,
        default=EmploymentType.FULL_TIME,
        db_index=True,
    )
    status = models.CharField(
        max_length=16,
        choices=EmployeeStatus.choices,
        default=EmployeeStatus.ACTIVE,
        db_index=True,
    )

    class Meta:
        ordering = ("last_name", "first_name")
        constraints = [
            models.UniqueConstraint(
                fields=("company", "employee_code"),
                name="uniq_employee_company_code",
            ),
            models.UniqueConstraint(
                fields=("user",),
                condition=Q(user__isnull=False),
                name="uniq_employee_user",
            ),
            models.CheckConstraint(
                condition=Q(manager__isnull=True) | ~Q(manager=F("id")),
                name="employee_manager_not_self",
            ),
        ]
        indexes = [
            models.Index(fields=("company", "status")),
            models.Index(fields=("company", "employee_code")),
            models.Index(fields=("company", "department")),
            models.Index(fields=("company", "position")),
            models.Index(fields=("company", "manager")),
            models.Index(fields=("company", "joining_date")),
            models.Index(fields=("user",)),
        ]

    def __str__(self) -> str:
        return f"{self.employee_code} {self.first_name} {self.last_name}"

    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}".strip()

    def clean(self) -> None:
        errors: dict[str, str] = {}
        if self.manager_id and self.pk and self.manager_id == self.pk:
            errors["manager"] = "An employee cannot be their own manager."
        if self.manager_id and self.company_id:
            if self.manager.company_id != self.company_id:
                errors["manager"] = "Manager must belong to the same company."
            elif self.pk and self.manager.manager_id == self.pk:
                errors["manager"] = "Circular manager assignment is not allowed."
        if self.department_id and self.company_id:
            if self.department.company_id != self.company_id:
                errors["department"] = "Department must belong to the same company."
        if self.position_id and self.company_id:
            if self.position.company_id != self.company_id:
                errors["position"] = "Position must belong to the same company."
            elif (
                self.department_id
                and self.position.department_id
                and self.position.department_id != self.department_id
            ):
                errors["position"] = (
                    "Position must belong to the employee's department."
                )
        if self.user_id and self.company_id:
            membership = self.user.get_active_membership()
            if (
                membership is None
                or membership.company_id != self.company_id
            ):
                errors["user"] = "Linked user must belong to the same company."
        if errors:
            raise ValidationError(errors)

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)
