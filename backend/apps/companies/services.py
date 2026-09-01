from django.core.exceptions import ValidationError
from django.db import transaction
from rest_framework.exceptions import ValidationError as APIValidationError

from apps.accounts.models import RoleScope, UserRole
from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.services import AuditService, changed_fields
from apps.companies.models import Company, CompanyMembership, CompanySettings

_SETTINGS_FIELDS = (
    "timezone",
    "work_start_time",
    "work_end_time",
    "grace_period_minutes",
    "minimum_working_minutes",
    "overtime_enabled",
    "working_days",
)


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
        actor=None,
        request=None,
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

        existing = CompanyMembership.objects.filter(
            user=user, company=company
        ).select_related("role").first()
        old_role = existing.role.code if existing is not None else None

        membership, _created = CompanyMembership.objects.update_or_create(
            user=user,
            company=company,
            defaults={"role": role, "is_active": is_active},
        )
        if user.role != UserRole.SUPER_ADMIN:
            user.role = role.code
            user.save(update_fields=["role", "updated_at"])
        if old_role != role.code:
            acting = actor or getattr(request, "user", None)
            AuditService.log(
                company=company,
                user=acting if getattr(acting, "pk", None) else None,
                action=AuditAction.ROLE_CHANGED,
                entity_type=AuditEntityType.USER,
                entity_id=user.id,
                old_value={"role": old_role} if old_role is not None else None,
                new_value={
                    "role": role.code,
                    "affected_user_id": user.id,
                    "affected_user_email": user.email,
                    "is_active": is_active,
                },
                request=request,
            )
        return membership

    def deactivate(self, membership: CompanyMembership) -> CompanyMembership:
        membership.is_active = False
        membership.save(update_fields=["is_active", "updated_at"])
        return membership


def get_company_settings(company: Company) -> CompanySettings:
    """Return persisted tenant settings, creating defaults if missing."""

    settings, _created = CompanySettings.objects.get_or_create(company=company)
    return settings


def settings_snapshot(row: CompanySettings) -> dict:
    return {
        "timezone": row.timezone,
        "work_start_time": row.work_start_time.isoformat(),
        "work_end_time": row.work_end_time.isoformat(),
        "grace_period_minutes": row.grace_period_minutes,
        "minimum_working_minutes": row.minimum_working_minutes,
        "overtime_enabled": row.overtime_enabled,
        "working_days": list(row.working_days),
    }


class CompanySettingsService:
    @transaction.atomic
    def update(self, *, company: Company, validated: dict, actor=None, request=None):
        row, _created = (
            CompanySettings.objects.select_for_update()
            .select_related("company")
            .get_or_create(company=company)
        )
        previous = settings_snapshot(row)
        for field in _SETTINGS_FIELDS:
            if field in validated:
                setattr(row, field, validated[field])
        try:
            row.save()
        except ValidationError as exc:
            raise APIValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc
        old_value, new_value = changed_fields(previous, settings_snapshot(row))
        if old_value or new_value:
            AuditService.log(
                company=company,
                user=actor if getattr(actor, "pk", None) else None,
                action=AuditAction.SETTINGS_CHANGED,
                entity_type=AuditEntityType.COMPANY_SETTINGS,
                entity_id=row.id,
                old_value=old_value,
                new_value=new_value,
                request=request,
            )
        return row
