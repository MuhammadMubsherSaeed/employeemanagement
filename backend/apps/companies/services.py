from django.core.exceptions import ValidationError
from django.db import transaction

from apps.accounts.models import RoleScope, UserRole
from apps.companies.models import CompanyMembership


class MembershipService:
    """Internal membership writes. No public role-escalation API."""

    @transaction.atomic
    def assign(
        self,
        *,
        user,
        company,
        role,
        is_active: bool = True,
    ) -> CompanyMembership:
        if user.is_platform_admin:
            raise ValidationError(
                "Platform administrators cannot be assigned to a company."
            )
        if role.scope != RoleScope.COMPANY or role.code == UserRole.SUPER_ADMIN:
            raise ValidationError(
                "SUPER_ADMIN cannot be granted through company membership."
            )
        if is_active:
            other = (
                CompanyMembership.objects.select_for_update()
                .filter(user=user, is_active=True)
                .exclude(company=company)
                .first()
            )
            if other is not None:
                raise ValidationError(
                    "User already has an active company membership."
                )

        membership, _created = CompanyMembership.objects.update_or_create(
            user=user,
            company=company,
            defaults={"role": role, "is_active": is_active},
        )
        if user.role != UserRole.SUPER_ADMIN:
            user.role = role.code
            user.save(update_fields=["role", "updated_at"])
        return membership

    def deactivate(self, membership: CompanyMembership) -> CompanyMembership:
        membership.is_active = False
        membership.save(update_fields=["is_active", "updated_at"])
        return membership
