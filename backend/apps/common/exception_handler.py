from __future__ import annotations

import logging
from typing import Any

from django.conf import settings
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import IntegrityError
from rest_framework import status
from rest_framework.exceptions import (
    APIException,
    AuthenticationFailed,
    MethodNotAllowed,
    NotAuthenticated,
    NotFound,
    ParseError,
    PermissionDenied,
    ValidationError,
)
from rest_framework.views import exception_handler as drf_exception_handler

from apps.common.responses import error_response

logger = logging.getLogger("apps.common")

_CODE_BY_STATUS = {
    status.HTTP_400_BAD_REQUEST: "VALIDATION_ERROR",
    status.HTTP_401_UNAUTHORIZED: "AUTHENTICATION_ERROR",
    status.HTTP_403_FORBIDDEN: "PERMISSION_DENIED",
    status.HTTP_404_NOT_FOUND: "NOT_FOUND",
    status.HTTP_405_METHOD_NOT_ALLOWED: "METHOD_NOT_ALLOWED",
    status.HTTP_409_CONFLICT: "CONFLICT",
    status.HTTP_429_TOO_MANY_REQUESTS: "THROTTLED",
    status.HTTP_500_INTERNAL_SERVER_ERROR: "SERVER_ERROR",
}


def api_exception_handler(exc: Exception, context: dict[str, Any]):
    response = drf_exception_handler(exc, context)

    if response is not None:
        return error_response(
            message=_message_from_exc(exc, response.data),
            code=_code_from_exc(exc, response.status_code),
            errors=_errors_from_data(exc, response.data),
            status=response.status_code,
        )

    if isinstance(exc, DjangoValidationError):
        return error_response(
            message="Validation failed.",
            code="VALIDATION_ERROR",
            errors=_django_validation_errors(exc),
            status=status.HTTP_400_BAD_REQUEST,
        )

    if isinstance(exc, IntegrityError):
        logger.warning("Database integrity error")
        return error_response(
            message="Could not complete this request.",
            code="CONFLICT",
            status=status.HTTP_409_CONFLICT,
        )

    logger.exception("Unhandled API exception")
    message = str(exc) if settings.DEBUG else "An unexpected error occurred."
    return error_response(
        message=message,
        code="SERVER_ERROR",
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )


_CODE_ALIASES = {
    "TOKEN_NOT_VALID": "TOKEN_INVALID",
    "NOT_AUTHENTICATED": "UNAUTHORIZED",
    "AUTHENTICATION_FAILED": "UNAUTHORIZED",
    "NO_ACTIVE_ACCOUNT": "INVALID_CREDENTIALS",
}


def _code_from_exc(exc: Exception, status_code: int) -> str:
    if isinstance(exc, APIException) and getattr(exc, "default_code", None):
        code = str(exc.default_code).upper()
        code = _CODE_ALIASES.get(code, code)
        if code not in {"ERROR", "INVALID"}:
            return code
    if isinstance(exc, (NotAuthenticated, AuthenticationFailed)):
        return "UNAUTHORIZED"
    if isinstance(exc, PermissionDenied):
        return "PERMISSION_DENIED"
    if isinstance(exc, NotFound):
        return "NOT_FOUND"
    if isinstance(exc, MethodNotAllowed):
        return "METHOD_NOT_ALLOWED"
    if isinstance(exc, ParseError):
        return "PARSE_ERROR"
    if isinstance(exc, ValidationError):
        return "VALIDATION_ERROR"
    return _CODE_BY_STATUS.get(status_code, "ERROR")


def _message_from_exc(exc: Exception, data: Any) -> str:
    if isinstance(exc, ValidationError):
        return "Validation failed."
    if isinstance(exc, ParseError):
        return "Could not parse the request."
    if isinstance(data, dict):
        detail = data.get("detail")
        if isinstance(detail, str) and detail:
            return detail
        if isinstance(detail, list) and detail:
            return str(detail[0])
    if isinstance(data, list) and data:
        return str(data[0])
    if isinstance(data, str) and data:
        return data
    return "Request failed."


def _errors_from_data(exc: Exception, data: Any) -> dict[str, Any]:
    if isinstance(exc, ValidationError) and isinstance(data, dict):
        return {key: value for key, value in data.items() if key != "detail"}
    if isinstance(data, dict) and "detail" not in data:
        return data
    return {}


def _django_validation_errors(exc: DjangoValidationError) -> dict[str, Any]:
    if hasattr(exc, "message_dict"):
        return exc.message_dict
    return {"non_field_errors": exc.messages}
