"""Strip secrets from audit snapshots before they are persisted."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from datetime import date, datetime, time
from decimal import Decimal
from typing import Any
from uuid import UUID

REDACTED = "[REDACTED]"

_SENSITIVE_KEYS = frozenset(
    {
        "password",
        "password_hash",
        "hashed_password",
        "passwd",
        "pwd",
        "token",
        "access",
        "access_token",
        "refresh",
        "refresh_token",
        "jwt",
        "id_token",
        "api_key",
        "apikey",
        "secret",
        "client_secret",
        "client_id",
        "oauth",
        "oauth_token",
        "credential",
        "credentials",
        "authorization",
        "auth_token",
        "private_key",
        "secret_key",
        "card_number",
        "cardnumber",
        "cvv",
        "cvc",
        "ssn",
        "pin",
        "payment",
        "payment_method",
        "account_number",
        "routing_number",
    }
)

_SENSITIVE_FRAGMENTS = (
    "password",
    "secret",
    "token",
    "api_key",
    "apikey",
    "credential",
    "authorization",
    "private_key",
)


def is_sensitive_key(key: str) -> bool:
    normalized = str(key).strip().lower().replace("-", "_")
    if normalized in _SENSITIVE_KEYS:
        return True
    return any(fragment in normalized for fragment in _SENSITIVE_FRAGMENTS)


def json_safe(value: Any) -> Any:
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, UUID):
        return str(value)
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, time):
        return value.isoformat()
    if isinstance(value, Mapping):
        return {str(key): json_safe(item) for key, item in value.items()}
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)):
        return [json_safe(item) for item in value]
    if hasattr(value, "pk"):
        return str(value.pk)
    return str(value)


def sanitize_audit_value(value: Any) -> Any:
    if value is None:
        return None
    return _sanitize(json_safe(value))


def _sanitize(value: Any) -> Any:
    if isinstance(value, Mapping):
        cleaned = {}
        for key, item in value.items():
            if is_sensitive_key(key):
                cleaned[str(key)] = REDACTED
            else:
                cleaned[str(key)] = _sanitize(item)
        return cleaned
    if isinstance(value, list):
        return [_sanitize(item) for item in value]
    return value
