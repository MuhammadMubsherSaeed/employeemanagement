"""In-process domain events. No email delivery. One dispatcher for all modules."""

from __future__ import annotations

from collections.abc import Callable
from typing import Any

from apps.common.models import AuditEvent

EventHandler = Callable[[dict[str, Any]], None]

_handlers: list[EventHandler] = []
_recorded: list[dict[str, Any]] = []


def listen(handler: EventHandler) -> None:
    _handlers.append(handler)


def clear_events() -> None:
    _recorded.clear()


def recorded_events(*, action: str | None = None) -> list[dict[str, Any]]:
    if action is None:
        return list(_recorded)
    return [event for event in _recorded if event["action"] == action]


def emit(
    action: str,
    *,
    actor=None,
    company=None,
    resource: str = "",
    resource_id: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> dict[str, Any]:
    payload = {
        "action": action,
        "actor_id": getattr(actor, "id", None),
        "company_id": str(getattr(company, "id", company) or "") or None,
        "resource": resource,
        "resource_id": str(resource_id) if resource_id is not None else "",
        "metadata": metadata or {},
    }
    _recorded.append(payload)
    AuditEvent.objects.create(
        company=company,
        actor=actor if getattr(actor, "pk", None) else None,
        action=action,
        resource=resource,
        resource_id=payload["resource_id"],
        metadata=payload["metadata"],
    )
    for handler in _handlers:
        handler(payload)
    return payload
