"""Shared permission classes.

Tenant-aware RBAC and company-scoped permissions will be added in a later
prompt. Default API access is authenticated; public views opt in to AllowAny.
"""

from rest_framework.permissions import AllowAny, IsAuthenticated

__all__ = ["AllowAny", "IsAuthenticated"]
