from __future__ import annotations

import logging

from django.contrib.auth import get_user_model
from django.contrib.auth.models import update_last_login
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.settings import api_settings
from rest_framework_simplejwt.token_blacklist.models import (
    BlacklistedToken,
    OutstandingToken,
)
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.serializers import CurrentUserSerializer, LoginUserSerializer
from apps.common.exceptions import (
    AccountInactive,
    InvalidCredentials,
    TokenBlacklisted,
    TokenExpired,
    TokenInvalid,
)

logger = logging.getLogger("apps.accounts")

User = get_user_model()


class AuthenticationService:
    def login(self, *, email: str, password: str) -> dict:
        normalized = User.objects.normalize_email(email.strip())
        user = User.objects.filter(email__iexact=normalized).first()
        if user is None or not user.check_password(password):
            logger.info("Login rejected")
            raise InvalidCredentials
        if not user.is_active:
            raise AccountInactive

        update_last_login(None, user)
        tokens = self._issue_tokens(user)
        logger.info("Login succeeded")
        return {
            "access": tokens["access"],
            "refresh": tokens["refresh"],
            "user": LoginUserSerializer(user).data,
        }

    def refresh(self, refresh_token: str) -> dict:
        refresh = self._load_refresh(refresh_token)
        data: dict[str, str] = {"access": str(refresh.access_token)}
        if api_settings.ROTATE_REFRESH_TOKENS:
            if api_settings.BLACKLIST_AFTER_ROTATION:
                self._blacklist(refresh)
            refresh.set_jti()
            refresh.set_exp()
            refresh.set_iat()
            data["refresh"] = str(refresh)
        return data

    def logout(self, refresh_token: str) -> None:
        try:
            refresh = self._load_refresh(refresh_token)
        except TokenBlacklisted:
            return
        self._blacklist(refresh)

    def current_user(self, user) -> dict:
        return CurrentUserSerializer(user).data

    def blacklist_user_refresh_tokens(self, user) -> None:
        for outstanding in OutstandingToken.objects.filter(user=user):
            BlacklistedToken.objects.get_or_create(token=outstanding)

    def _issue_tokens(self, user) -> dict[str, str]:
        refresh = RefreshToken.for_user(user)
        return {"access": str(refresh.access_token), "refresh": str(refresh)}

    def _load_refresh(self, raw: str) -> RefreshToken:
        try:
            return RefreshToken(raw)
        except TokenError as exc:
            raise self._map_token_error(exc) from exc

    def _blacklist(self, refresh: RefreshToken) -> None:
        try:
            refresh.blacklist()
        except AttributeError:
            logger.warning("Token blacklist app is not configured")
        except TokenError as exc:
            mapped = self._map_token_error(exc)
            if isinstance(mapped, TokenBlacklisted):
                return
            raise mapped from exc

    def _map_token_error(self, exc: TokenError):
        detail = str(exc).lower()
        if "blacklisted" in detail:
            return TokenBlacklisted()
        if "expired" in detail:
            return TokenExpired()
        return TokenInvalid()
