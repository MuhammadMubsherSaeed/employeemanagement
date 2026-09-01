from __future__ import annotations

import logging

from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from apps.common.authorization import ObjectAuthorization
from apps.common.events import emit
from apps.common.tenancy import TenantContext, get_tenant_context
from apps.notifications.models import (
    DeviceToken,
    Notification,
)
from apps.notifications.push import PushNotificationService

logger = logging.getLogger("apps.notifications")
_authz = ObjectAuthorization()
RESOURCE_NOTIFICATION = "notifications.Notification"
RESOURCE_TOKEN = "notifications.DeviceToken"


class NotificationService:
    def __init__(self, push: PushNotificationService | None = None) -> None:
        self.push = push or PushNotificationService()

    def create_notification(
        self,
        *,
        company,
        recipient,
        type: str,
        title: str,
        message: str,
        entity_type: str = "",
        entity_id: str | None = None,
        metadata: dict | None = None,
        event_key: str = "",
        actor=None,
    ) -> Notification | None:
        if recipient is None or getattr(recipient, "pk", None) is None:
            return None
        if company is None:
            return None
        membership = recipient.get_active_membership()
        if (
            membership is None
            or not membership.is_active
            or membership.company_id != company.id
        ):
            logger.warning(
                "Skipped notification %s; recipient is not in company %s",
                type,
                company.id,
            )
            return None
        payload = {
            "company": company,
            "recipient": recipient,
            "type": type,
            "title": (title or "").strip(),
            "message": (message or "").strip(),
            "entity_type": (entity_type or "").strip(),
            "entity_id": str(entity_id or "").strip(),
            "metadata": dict(metadata or {}),
            "event_key": (event_key or "").strip(),
        }
        if payload["event_key"]:
            existing = Notification.objects.filter(
                company=company,
                recipient=recipient,
                event_key=payload["event_key"],
            ).first()
            if existing is not None:
                return existing
        row = Notification(**payload)
        try:
            row.full_clean()
            row.save()
        except IntegrityError:
            return Notification.objects.filter(
                company=company,
                recipient=recipient,
                event_key=payload["event_key"],
            ).first()
        except DjangoValidationError as exc:
            raise ValidationError(_django_errors(exc))
        emit(
            "notification.created",
            actor=actor,
            company=company,
            resource=RESOURCE_NOTIFICATION,
            resource_id=row.id,
            metadata={"type": row.type, "recipient_id": recipient.id},
        )
        try:
            self.push.notify(row)
        except Exception:
            logger.exception("Push delivery failed for notification %s", row.id)
        return row

    def create_notifications_for_users(
        self,
        *,
        company,
        recipients,
        type: str,
        title: str,
        message: str,
        entity_type: str = "",
        entity_id: str | None = None,
        metadata: dict | None = None,
        event_key_prefix: str = "",
        actor=None,
    ) -> list[Notification]:
        created: list[Notification] = []
        seen: set[int] = set()
        for recipient in recipients:
            user_id = getattr(recipient, "id", None)
            if user_id is None or user_id in seen:
                continue
            seen.add(user_id)
            event_key = ""
            if event_key_prefix:
                event_key = f"{event_key_prefix}:{user_id}"
            row = self.create_notification(
                company=company,
                recipient=recipient,
                type=type,
                title=title,
                message=message,
                entity_type=entity_type,
                entity_id=entity_id,
                metadata=metadata,
                event_key=event_key,
                actor=actor,
            )
            if row is not None:
                created.append(row)
        return created

    def mark_read(self, *, request, notification: Notification) -> Notification:
        ctx = _require_company(request)
        self._assert_inbox_item(ctx, notification)
        if notification.is_read:
            return notification
        now = timezone.now()
        Notification.objects.filter(pk=notification.pk, is_read=False).update(
            is_read=True,
            read_at=now,
        )
        notification.refresh_from_db()
        emit(
            "notification.marked_read",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_NOTIFICATION,
            resource_id=notification.id,
        )
        return notification

    def mark_all_read(self, *, request) -> int:
        ctx = _require_company(request)
        now = timezone.now()
        updated = Notification.objects.filter(
            company=ctx.company,
            recipient=ctx.user,
            is_read=False,
        ).update(is_read=True, read_at=now)
        emit(
            "notification.marked_all_read",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_NOTIFICATION,
            resource_id=str(ctx.user.id),
            metadata={"updated": updated},
        )
        return updated

    def unread_count(self, *, request) -> int:
        ctx = _require_company(request)
        return Notification.objects.filter(
            company=ctx.company,
            recipient=ctx.user,
            is_read=False,
        ).count()

    def _assert_inbox_item(
        self, ctx: TenantContext, notification: Notification
    ) -> None:
        if ctx.company is None or notification.company_id != ctx.company.id:
            raise NotFound()
        if notification.recipient_id != ctx.user.id:
            raise NotFound()
        if not _authz.can_view(ctx, notification):
            raise NotFound()


class DeviceTokenService:
    def register(self, *, request, validated: dict) -> DeviceToken:
        ctx = _require_company(request)
        token = (validated["token"] or "").strip()
        platform = validated.get("platform") or "UNKNOWN"
        device_name = (validated.get("device_name") or "").strip()
        now = timezone.now()
        with transaction.atomic():
            row = DeviceToken.objects.select_for_update().filter(token=token).first()
            if row is None:
                row = DeviceToken(
                    company=ctx.company,
                    user=ctx.user,
                    token=token,
                    platform=platform,
                    device_name=device_name,
                    is_active=True,
                    last_seen_at=now,
                )
                try:
                    row.full_clean()
                    row.save()
                except DjangoValidationError as exc:
                    raise ValidationError(_django_errors(exc))
                action = "device_token.registered"
            else:
                row.company = ctx.company
                row.user = ctx.user
                row.platform = platform
                if device_name:
                    row.device_name = device_name
                row.is_active = True
                row.last_seen_at = now
                try:
                    row.full_clean()
                    row.save()
                except DjangoValidationError as exc:
                    raise ValidationError(_django_errors(exc))
                action = "device_token.updated"
        emit(
            action,
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_TOKEN,
            resource_id=row.id,
            metadata={"platform": row.platform},
        )
        return row

    def update_token(
        self, *, request, device_token: DeviceToken, validated: dict
    ) -> DeviceToken:
        ctx = _require_company(request)
        self._assert_own_token(ctx, device_token)
        with transaction.atomic():
            row = DeviceToken.objects.select_for_update().get(pk=device_token.pk)
            self._assert_own_token(ctx, row)
            if validated.get("token"):
                row.token = validated["token"].strip()
            if validated.get("platform"):
                row.platform = validated["platform"]
            if "device_name" in validated:
                row.device_name = (validated["device_name"] or "").strip()
            row.is_active = True
            row.last_seen_at = timezone.now()
            try:
                row.full_clean()
                row.save()
            except DjangoValidationError as exc:
                raise ValidationError(_django_errors(exc))
            except IntegrityError:
                raise ValidationError(
                    {"token": ["This device token is already registered."]}
                )
        emit(
            "device_token.updated",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_TOKEN,
            resource_id=row.id,
        )
        return row

    def deactivate(self, *, request, device_token: DeviceToken) -> None:
        ctx = _require_company(request)
        self._assert_own_token(ctx, device_token)
        DeviceToken.objects.filter(
            pk=device_token.pk,
            user_id=ctx.user.id,
            company_id=ctx.company.id,
        ).update(is_active=False)
        emit(
            "device_token.deactivated",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_TOKEN,
            resource_id=device_token.id,
        )

    def _assert_own_token(self, ctx: TenantContext, device_token: DeviceToken) -> None:
        if ctx.company is None or device_token.company_id != ctx.company.id:
            raise NotFound()
        if device_token.user_id != ctx.user.id:
            raise NotFound()
        if not _authz.can_view(ctx, device_token):
            raise NotFound()


def _require_company(request) -> TenantContext:
    ctx = get_tenant_context(request)
    if ctx.company is None:
        raise PermissionDenied("You do not have access to this company.")
    return ctx


def _django_errors(exc: DjangoValidationError) -> dict:
    if hasattr(exc, "message_dict"):
        return exc.message_dict
    return {"non_field_errors": list(exc.messages)}
