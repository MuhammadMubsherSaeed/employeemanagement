from __future__ import annotations

from django.db.models import Q

from apps.accounts.models import UserRole
from apps.common.tenancy import TenantContext


class TeamScope:
    """Future reporting/team membership hook.

    Until an Employee reporting graph exists, managers are not treated as
    having access to every colleague's private records.
    """

    def is_in_team(self, ctx: TenantContext, target_user_id: int) -> bool:
        return False


class ObjectAuthorization:
    """Can this actor access this tenant-owned object?"""

    def __init__(self, team_scope: TeamScope | None = None) -> None:
        self.team_scope = team_scope or TeamScope()

    def belongs_to_tenant(self, ctx: TenantContext, obj) -> bool:
        company_id = getattr(obj, "company_id", None)
        if company_id is None:
            return False
        if ctx.is_super_admin:
            return True
        if ctx.company is None:
            return False
        return company_id == ctx.company.id

    def can_view(self, ctx: TenantContext, obj) -> bool:
        if not self.belongs_to_tenant(ctx, obj):
            return False
        if ctx.is_super_admin:
            return True
        visibility = getattr(obj, "visibility", "COMPANY")
        owner_id = getattr(obj, "owner_id", None)
        if visibility == "PRIVATE":
            return self._can_view_private(ctx, owner_id)
        return True

    def can_change(self, ctx: TenantContext, obj) -> bool:
        if not self.can_view(ctx, obj):
            return False
        if ctx.is_super_admin or ctx.role_code == UserRole.COMPANY_ADMIN:
            return True
        owner_id = getattr(obj, "owner_id", None)
        if ctx.role_code == UserRole.MANAGER:
            return owner_id == ctx.user.id or self.team_scope.is_in_team(
                ctx, owner_id
            )
        return owner_id == ctx.user.id

    def filter_queryset(self, queryset, ctx: TenantContext):
        if ctx.is_super_admin:
            return queryset
        if ctx.company is None:
            return queryset.none()
        queryset = queryset.filter(company_id=ctx.company.id)
        if ctx.role_code == UserRole.COMPANY_ADMIN:
            return queryset
        if not hasattr(queryset.model, "visibility"):
            return queryset
        user_id = ctx.user.id
        return queryset.filter(
            Q(visibility="COMPANY") | Q(visibility="PRIVATE", owner_id=user_id)
        )

    def assert_same_tenant(self, ctx: TenantContext, related_user) -> bool:
        if related_user is None:
            return True
        if ctx.is_super_admin:
            return True
        if ctx.company is None:
            return False
        membership = related_user.get_active_membership()
        return bool(
            membership
            and membership.is_active
            and membership.company_id == ctx.company.id
        )

    def _can_view_private(self, ctx: TenantContext, owner_id) -> bool:
        if ctx.role_code == UserRole.COMPANY_ADMIN:
            return True
        if owner_id == ctx.user.id:
            return True
        if ctx.role_code == UserRole.MANAGER:
            return self.team_scope.is_in_team(ctx, owner_id)
        return False
