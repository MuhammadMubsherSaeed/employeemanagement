from __future__ import annotations

import logging
from dataclasses import dataclass

from django.conf import settings

from apps.notifications.models import DeviceToken, Notification

logger = logging.getLogger("apps.notifications")


@dataclass(frozen=True)
class PushResult:
    skipped: bool = False
    ok: bool = False
    invalid_token: bool = False
    error: str = ""


class PushBackend:
    """Send one FCM message. Implementations must not raise to callers."""

    def send(
        self,
        *,
        token: str,
        title: str,
        body: str,
        data: dict[str, str],
    ) -> PushResult:
        raise NotImplementedError


class DisabledPushBackend(PushBackend):
    """Used when Firebase Admin credentials are not configured."""

    def send(
        self,
        *,
        token: str,
        title: str,
        body: str,
        data: dict[str, str],
    ) -> PushResult:
        logger.debug("Push delivery skipped; FCM backend is disabled.")
        return PushResult(skipped=True)


def default_push_backend() -> PushBackend:
    credentials = getattr(settings, "FIREBASE_CREDENTIALS_PATH", "") or ""
    if credentials:
        logger.warning(
            "FIREBASE_CREDENTIALS_PATH is set but firebase-admin is not wired; "
            "push delivery remains disabled."
        )
    return DisabledPushBackend()


class PushNotificationService:
    def __init__(self, backend: PushBackend | None = None) -> None:
        self.backend = backend or default_push_backend()

    def notify(self, notification: Notification) -> None:
        tokens = DeviceToken.objects.filter(
            company_id=notification.company_id,
            user_id=notification.recipient_id,
            is_active=True,
        )
        payload = {
            "notification_id": str(notification.id),
            "notification_type": notification.type,
            "entity_type": notification.entity_type or "",
            "entity_id": notification.entity_id or "",
        }
        for row in tokens:
            try:
                result = self.backend.send(
                    token=row.token,
                    title=notification.title,
                    body=notification.message,
                    data=payload,
                )
            except Exception:
                logger.exception("Push backend failed for token %s", row.id)
                continue
            if result.invalid_token:
                row.is_active = False
                row.save(update_fields=["is_active", "updated_at"])
