from __future__ import annotations

import logging

from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.mail import send_mail
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework import serializers

from apps.accounts.services.authentication import AuthenticationService
from apps.common.exceptions import PasswordResetFailed

logger = logging.getLogger("apps.accounts")

User = get_user_model()
_token_generator = PasswordResetTokenGenerator()


class PasswordResetService:
    def request_reset(self, email: str) -> None:
        normalized = User.objects.normalize_email(email.strip())
        user = User.objects.filter(email__iexact=normalized, is_active=True).first()
        if user is None:
            return
        uid = urlsafe_base64_encode(force_bytes(user.pk))
        token = _token_generator.make_token(user)
        self._send_reset_email(user.email, uid=uid, token=token)

    def reset_password(self, *, uid: str, token: str, new_password: str) -> None:
        user = self._user_from_uid(uid)
        if user is None or not _token_generator.check_token(user, token):
            raise PasswordResetFailed
        try:
            validate_password(new_password, user=user)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(
                {"new_password": list(exc.messages)}
            ) from exc
        user.set_password(new_password)
        user.save(update_fields=["password"])
        AuthenticationService().blacklist_user_refresh_tokens(user)

    def _user_from_uid(self, uid: str):
        try:
            pk = force_str(urlsafe_base64_decode(uid))
            return User.objects.filter(pk=pk, is_active=True).first()
        except (ValueError, TypeError, OverflowError):
            return None

    def _send_reset_email(self, email: str, *, uid: str, token: str) -> None:
        reset_url = (
            f"{settings.FRONTEND_PASSWORD_RESET_URL}"
            f"?uid={uid}&token={token}"
        )
        send_mail(
            subject="Reset your HRMS password",
            message=(
                "Use the link below to choose a new password. "
                "If you did not request this, you can ignore this email.\n\n"
                f"{reset_url}\n"
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            fail_silently=False,
        )
        logger.info("Password reset instructions sent")
