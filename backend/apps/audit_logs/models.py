import uuid

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.companies.models import Company


class AuditLogQuerySet(models.QuerySet):
    def update(self, **kwargs):
        raise ValidationError("Audit logs cannot be modified.")


class AuditLog(models.Model):
    """Append-only company-scoped audit record. Not editable via the API."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="audit_logs",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="audit_logs",
        null=True,
        blank=True,
    )
    action = models.CharField(max_length=32, choices=AuditAction.choices)
    entity_type = models.CharField(max_length=32, choices=AuditEntityType.choices)
    entity_id = models.CharField(max_length=64)
    old_value = models.JSONField(null=True, blank=True)
    new_value = models.JSONField(null=True, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    objects = AuditLogQuerySet.as_manager()

    class Meta:
        ordering = ("-created_at",)
        constraints = [
            models.CheckConstraint(
                condition=models.Q(action__in=AuditAction.values),
                name="audit_log_valid_action",
            ),
            models.CheckConstraint(
                condition=models.Q(entity_type__in=AuditEntityType.values),
                name="audit_log_valid_entity_type",
            ),
        ]
        indexes = [
            models.Index(fields=("company", "created_at")),
            models.Index(fields=("company", "action")),
            models.Index(fields=("company", "entity_type")),
            models.Index(fields=("company", "user")),
            models.Index(fields=("company", "entity_type", "entity_id")),
        ]

    def __str__(self) -> str:
        return f"{self.action} {self.entity_type}:{self.entity_id}"

    def save(self, *args, **kwargs):
        if not self._state.adding:
            raise ValidationError("Audit logs cannot be modified.")
        return super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        raise ValidationError("Audit logs cannot be deleted.")
