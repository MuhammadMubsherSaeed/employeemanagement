"""Extract client IP and user-agent without trusting arbitrary forwarded headers."""

from __future__ import annotations

import ipaddress

_USER_AGENT_MAX_LENGTH = 2048


def request_metadata(request) -> tuple[str | None, str | None]:
    if request is None:
        return None, None
    try:
        return client_ip(request), user_agent(request)
    except Exception:
        return None, None


def client_ip(request) -> str | None:
    """Use REMOTE_ADDR only.

    Production sets SECURE_PROXY_SSL_HEADER but does not declare a trusted
    proxy count, so X-Forwarded-For is not treated as the client address.
    """

    if request is None:
        return None
    meta = getattr(request, "META", None) or {}
    raw = meta.get("REMOTE_ADDR")
    if not raw:
        return None
    candidate = str(raw).split("%", 1)[0].strip()
    if not candidate:
        return None
    try:
        ipaddress.ip_address(candidate)
    except ValueError:
        return None
    return candidate


def user_agent(request) -> str | None:
    if request is None:
        return None
    meta = getattr(request, "META", None) or {}
    raw = meta.get("HTTP_USER_AGENT")
    if not raw:
        return None
    text = str(raw).strip()
    if not text:
        return None
    return text[:_USER_AGENT_MAX_LENGTH]
