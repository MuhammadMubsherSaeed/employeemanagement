from __future__ import annotations

from typing import Any

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.models import AuditLog
from apps.audit_logs.request_meta import request_metadata
from apps.audit_logs.sanitize import sanitize_audit_value


class AuditService:
    """Append-only audit writer. Callers should invoke this inside the same atomic block."""

    @staticmethod
    def log(
        *,
        company,
        action: str,
        entity_type: str,
        entity_id,
        user=None,
        old_value: Any = None,
        new_value: Any = None,
        request=None,
    ) -> AuditLog:
        if company is None:
            raise ValueError("company is required for audit logs.")
        ip_address, user_agent = request_metadata(request)
        actor = user if getattr(user, "pk", None) else None
        return AuditLog.objects.create(
            company=company,
            user=actor,
            action=action,
            entity_type=entity_type,
            entity_id=str(entity_id),
            old_value=sanitize_audit_value(old_value),
            new_value=sanitize_audit_value(new_value),
            ip_address=ip_address,
            user_agent=user_agent,
        )


def create_audit_log(**kwargs) -> AuditLog:
    return AuditService.log(**kwargs)


def changed_fields(old_value: dict | None, new_value: dict | None) -> tuple[dict, dict]:
    previous = old_value or {}
    current = new_value or {}
    keys = set(previous) | set(current)
    old_changed = {}
    new_changed = {}
    for key in keys:
        if previous.get(key) != current.get(key):
            if key in previous:
                old_changed[key] = previous[key]
            if key in current:
                new_changed[key] = current[key]
    return old_changed, new_changed


__all__ = [
    "AuditAction",
    "AuditEntityType",
    "AuditService",
    "changed_fields",
    "create_audit_log",
]
