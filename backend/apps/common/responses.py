from typing import Any

from rest_framework.response import Response
from rest_framework.status import HTTP_200_OK


def success_response(
    data: Any | None = None,
    message: str = "Request successful.",
    status: int = HTTP_200_OK,
) -> Response:
    payload: dict[str, Any] = {
        "success": True,
        "message": message,
    }
    if data is not None:
        payload["data"] = data
    return Response(payload, status=status)


def error_response(
    message: str,
    *,
    code: str = "ERROR",
    errors: dict[str, Any] | None = None,
    status: int = 400,
) -> Response:
    return Response(
        {
            "success": False,
            "message": message,
            "code": code,
            "errors": errors or {},
        },
        status=status,
    )
