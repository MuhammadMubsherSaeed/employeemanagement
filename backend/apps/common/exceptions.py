from rest_framework.exceptions import APIException
from rest_framework.status import (
    HTTP_400_BAD_REQUEST,
    HTTP_401_UNAUTHORIZED,
    HTTP_403_FORBIDDEN,
    HTTP_404_NOT_FOUND,
    HTTP_409_CONFLICT,
    HTTP_500_INTERNAL_SERVER_ERROR,
)


class APIError(APIException):
    status_code = HTTP_400_BAD_REQUEST
    default_detail = "Request failed."
    default_code = "API_ERROR"


class ValidationFailed(APIError):
    status_code = HTTP_400_BAD_REQUEST
    default_detail = "Validation failed."
    default_code = "VALIDATION_ERROR"


class AuthenticationFailedError(APIError):
    status_code = HTTP_401_UNAUTHORIZED
    default_detail = "Authentication required."
    default_code = "AUTHENTICATION_ERROR"


class PermissionDeniedError(APIError):
    status_code = HTTP_403_FORBIDDEN
    default_detail = "You do not have permission to perform this action."
    default_code = "PERMISSION_DENIED"


class NotFoundError(APIError):
    status_code = HTTP_404_NOT_FOUND
    default_detail = "The requested resource was not found."
    default_code = "NOT_FOUND"


class ConflictError(APIError):
    status_code = HTTP_409_CONFLICT
    default_detail = "Could not complete this request."
    default_code = "CONFLICT"


class ServerError(APIError):
    status_code = HTTP_500_INTERNAL_SERVER_ERROR
    default_detail = "An unexpected error occurred."
    default_code = "SERVER_ERROR"
