import uuid

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models import Q

from apps.common.models import TimeStampedModel
from apps.companies.models import Company

MAX_TITLE_LENGTH = 255
MAX_MESSAGE_LENGTH = 2000
MAX_TOKEN_LENGTH = 512
MAX_DEVICE_NAME_LENGTH = 128
MAX_EVENT_KEY_LENGTH = 128
MAX_ENTITY_ID_LENGTH = 64


class NotificationType(models.TextChoices):
    LEAVE_SUBMITTED = "LEAVE_SUBMITTED", "Leave submitted"
    LEAVE_APPROVED = "LEAVE_APPROVED", "Leave approved"
    LEAVE_REJECTED = "LEAVE_REJECTED", "Leave rejected"
    LEAVE_CANCELLED = "LEAVE_CANCELLED", "Leave cancelled"
    DEVICE_ASSIGNED = "DEVICE_ASSIGNED", "Device assigned"
    DEVICE_RETURNED = "DEVICE_RETURNED", "Device returned"
    ATTENDANCE_REMINDER = "ATTENDANCE_REMINDER", "Attendance reminder"
    ATTENDANCE_LATE = "ATTENDANCE_LATE", "Attendance late"
    DOCUMENT_EXPIRING = "DOCUMENT_EXPIRING", "Document expiring"
    SYSTEM = "SYSTEM", "System"


class EntityType(models.TextChoices):
    LEAVE_REQUEST = "leave_request", "Leave request"
    DEVICE = "device", "Device"
    ATTENDANCE = "attendance", "Attendance"
    EMPLOYEE_DOCUMENT = "employee_document", "Employee document"


class DevicePlatform(models.TextChoices):
    ANDROID = "ANDROID", "Android"
    IOS = "IOS", "iOS"
    WEB = "WEB", "Web"
    UNKNOWN = "UNKNOWN", "Unknown"


class Notification(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    type = models.CharField(
        max_length=32,
        choices=NotificationType.choices,
        db_index=True,
    )
    title = models.CharField(max_length=MAX_TITLE_LENGTH)
    message = models.TextField(max_length=MAX_MESSAGE_LENGTH)
    entity_type = models.CharField(
        max_length=32,
        choices=EntityType.choices,
        blank=True,
    )
    entity_id = models.CharField(max_length=MAX_ENTITY_ID_LENGTH, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False, db_index=True)
    read_at = models.DateTimeField(null=True, blank=True)
    event_key = models.CharField(max_length=MAX_EVENT_KEY_LENGTH, blank=True)

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=("company",)),
            models.Index(fields=("recipient",)),
            models.Index(fields=("is_read",)),
            models.Index(fields=("type",)),
            models.Index(fields=("created_at",)),
            models.Index(fields=("company", "recipient", "is_read")),
            models.Index(fields=("recipient", "created_at")),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=("company", "recipient", "event_key"),
                condition=Q(event_key__gt=""),
                name="uniq_notification_event_key",
            )
        ]

    def __str__(self) -> str:
        return f"{self.type} → {self.recipient_id}"

    def clean(self) -> None:
        self.title = (self.title or "").strip()
        self.message = (self.message or "").strip()
        self.entity_type = (self.entity_type or "").strip()
        self.entity_id = str(self.entity_id or "").strip()
        self.event_key = (self.event_key or "").strip()
        if not isinstance(self.metadata, dict):
            raise ValidationError({"metadata": "metadata must be an object."})
        if len(self.title) < 1:
            raise ValidationError({"title": "Enter a notification title."})
        if len(self.message) < 1:
            raise ValidationError({"message": "Enter a notification message."})
        if self.entity_id and not self.entity_type:
            raise ValidationError(
                {"entity_type": "entity_type is required when entity_id is set."}
            )


class DeviceToken(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="device_tokens",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="device_tokens",
    )
    token = models.CharField(max_length=MAX_TOKEN_LENGTH, unique=True)
    platform = models.CharField(
        max_length=16,
        choices=DevicePlatform.choices,
        default=DevicePlatform.UNKNOWN,
    )
    device_name = models.CharField(max_length=MAX_DEVICE_NAME_LENGTH, blank=True)
    is_active = models.BooleanField(default=True, db_index=True)
    last_seen_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("-updated_at",)
        indexes = [
            models.Index(fields=("user",)),
            models.Index(fields=("company",)),
            models.Index(fields=("is_active",)),
            models.Index(fields=("company", "user", "is_active")),
        ]

    def __str__(self) -> str:
        return f"{self.platform} token for {self.user_id}"

    def clean(self) -> None:
        self.token = (self.token or "").strip()
        self.device_name = (self.device_name or "").strip()
        if len(self.token) < 8:
            raise ValidationError({"token": "Enter a valid device token."})
