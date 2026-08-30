"""Composable DRF permission classes. Tenant is never taken from the payload."""

from rest_framework.permissions import AllowAny, BasePermission, IsAuthenticated

from apps.accounts.models import UserRole
from apps.common.tenancy import get_tenant_context

__all__ = [
    "AllowAny",
    "HasAllPermissions",
    "HasAnyPermission",
    "HasPermission",
    "IsAuthenticated",
    "IsAuthenticatedUser",
    "IsCompanyAdmin",
    "IsCompanyMember",
    "IsEmployee",
    "IsManager",
    "IsSuperAdmin",
]


class IsAuthenticatedUser(IsAuthenticated):
    """Authenticated access. Unauthenticated requests stay 401."""


class IsSuperAdmin(BasePermission):
    message = "You do not have permission to perform this action."

    def has_permission(self, request, view) -> bool:
        return get_tenant_context(request).is_super_admin


class IsCompanyMember(BasePermission):
    message = "You do not have access to this company."

    def has_permission(self, request, view) -> bool:
        ctx = get_tenant_context(request)
        if ctx.is_super_admin:
            return True
        return ctx.has_company_access


class IsCompanyAdmin(BasePermission):
    message = "You do not have permission to perform this action."

    def has_permission(self, request, view) -> bool:
        ctx = get_tenant_context(request)
        return ctx.has_company_access and ctx.role_code == UserRole.COMPANY_ADMIN


class IsManager(BasePermission):
    message = "You do not have permission to perform this action."

    def has_permission(self, request, view) -> bool:
        ctx = get_tenant_context(request)
        return ctx.has_company_access and ctx.role_code == UserRole.MANAGER


class IsEmployee(BasePermission):
    message = "You do not have permission to perform this action."

    def has_permission(self, request, view) -> bool:
        ctx = get_tenant_context(request)
        return ctx.has_company_access and ctx.role_code == UserRole.EMPLOYEE


def HasPermission(code: str):
    class _HasPermission(BasePermission):
        message = "You do not have permission to perform this action."

        def has_permission(self, request, view) -> bool:
            return get_tenant_context(request).has_permission(code)

    _HasPermission.__name__ = f"HasPermission_{code.replace('.', '_')}"
    return _HasPermission


def HasAnyPermission(*codes: str):
    required = tuple(codes)

    class _HasAnyPermission(BasePermission):
        message = "You do not have permission to perform this action."

        def has_permission(self, request, view) -> bool:
            return get_tenant_context(request).has_any_permission(required)

    return _HasAnyPermission


def HasAllPermissions(*codes: str):
    required = tuple(codes)

    class _HasAllPermissions(BasePermission):
        message = "You do not have permission to perform this action."

        def has_permission(self, request, view) -> bool:
            return get_tenant_context(request).has_all_permissions(required)

    return _HasAllPermissions
