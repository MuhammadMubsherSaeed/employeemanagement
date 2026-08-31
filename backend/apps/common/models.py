import uuid

from django.db import models


class TimeStampedModel(models.Model):
    """Abstract timestamps for future domain models. Timezone-aware via USE_TZ."""

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class AuditEvent(TimeStampedModel):
    """Company-scoped audit trail. One system for all modules; do not duplicate."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        "companies.Company",
        on_delete=models.CASCADE,
        related_name="audit_events",
        null=True,
        blank=True,
    )
    actor = models.ForeignKey(
        "accounts.User",
        on_delete=models.SET_NULL,
        related_name="audit_events",
        null=True,
        blank=True,
    )
    action = models.CharField(max_length=64, db_index=True)
    resource = models.CharField(max_length=64, db_index=True)
    resource_id = models.CharField(max_length=64, db_index=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=("company", "action")),
            models.Index(fields=("company", "resource", "resource_id")),
        ]

    def __str__(self) -> str:
        return f"{self.action} {self.resource}:{self.resource_id}"
