from django.conf import settings
from django.db import connection
from django.db.utils import OperationalError
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.request import Request

from apps.common.responses import error_response, success_response


def _database_ok() -> bool:
    try:
        connection.ensure_connection()
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        return True
    except OperationalError:
        return False


def _cache_ok() -> bool | None:
    redis_url = (getattr(settings, "REDIS_URL", "") or "").strip()
    if not redis_url:
        return None
    try:
        import redis

        client = redis.from_url(
            redis_url,
            socket_connect_timeout=1,
            socket_timeout=1,
        )
        try:
            return bool(client.ping())
        finally:
            client.close()
    except Exception:
        return False


@api_view(["GET"])
@permission_classes([AllowAny])
def health(_request: Request, **_kwargs):
    if not _database_ok():
        return error_response(
            "Service unavailable.",
            code="UNAVAILABLE",
            status=503,
        )
    cache_ok = _cache_ok()
    if cache_ok is False:
        return error_response(
            "Service unavailable.",
            code="UNAVAILABLE",
            status=503,
        )
    return success_response(
        data={"status": "ok"},
        message="API is healthy.",
    )
