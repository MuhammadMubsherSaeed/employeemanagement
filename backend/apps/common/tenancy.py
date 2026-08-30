from __future__ import annotations

from dataclasses import dataclass, field

from django.contrib.auth.models import AnonymousUser

from apps.accounts.models import UserRole


@dataclass
class TenantContext:
    """Authoritative tenant for the authenticated user.

    Derived from CompanyMembership, never from request payloads or JWT claims.
    """

    user: object
    membership: object | None
    company: object | None
    role_code: str
    is_super_admin: bool
    permission_codes: frozenset[str] = field(default_factory=frozenset)

    @classmethod
    def anonymous(cls) -> TenantContext:
        return cls(
            user=None,
            membership=None,
            company=None,
            role_code="",
            is_super_admin=False,
        )

    @classmethod
    def resolve(cls, user) -> TenantContext:
        if user is None or isinstance(user, AnonymousUser) or not getattr(
            user, "is_authenticated", False
        ):
            return cls.anonymous()

        if user.is_platform_admin:
            return cls(
                user=user,
                membership=None,
                company=None,
                role_code=UserRole.SUPER_ADMIN,
                is_super_admin=True,
                permission_codes=frozenset(),
            )

        membership = user.get_active_membership()
        if membership is None:
            return cls(
                user=user,
                membership=None,
                company=None,
                role_code=user.role,
                is_super_admin=False,
            )

        codes = frozenset(
            membership.role.permissions.values_list("code", flat=True)
        )
        return cls(
            user=user,
            membership=membership,
            company=membership.company,
            role_code=membership.role.code,
            is_super_admin=False,
            permission_codes=codes,
        )

    @property
    def has_company_access(self) -> bool:
        if self.is_super_admin:
            return True
        membership = self.membership
        company = self.company
        return bool(
            membership is not None
            and membership.is_active
            and company is not None
            and company.is_active
        )

    def has_permission(self, code: str) -> bool:
        if self.is_super_admin:
            return True
        if not self.has_company_access:
            return False
        return code in self.permission_codes

    def has_any_permission(self, codes: tuple[str, ...]) -> bool:
        return any(self.has_permission(code) for code in codes)

    def has_all_permissions(self, codes: tuple[str, ...]) -> bool:
        return all(self.has_permission(code) for code in codes)


def get_tenant_context(request) -> TenantContext:
    cached = getattr(request, "tenant", None)
    if isinstance(cached, TenantContext):
        return cached
    ctx = TenantContext.resolve(getattr(request, "user", None))
    request.tenant = ctx
    return ctx
