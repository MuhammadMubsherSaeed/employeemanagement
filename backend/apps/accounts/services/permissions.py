from django.db import transaction

from apps.accounts.models import Permission
from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.services import AuditService


@transaction.atomic
def apply_role_permissions(
    role,
    codes,
    *,
    company=None,
    actor=None,
    request=None,
):
    """Replace a role's permission set. Audits only when a company is provided."""

    old = set(role.permissions.values_list("code", flat=True))
    new = set(codes)
    if old == new:
        return role
    if new:
        role.permissions.set(Permission.objects.filter(code__in=new))
    else:
        role.permissions.clear()
    if company is None:
        return role
    AuditService.log(
        company=company,
        user=actor if getattr(actor, "pk", None) else None,
        action=AuditAction.PERMISSION_CHANGED,
        entity_type=AuditEntityType.ROLE,
        entity_id=role.id,
        old_value={"role": role.code, "permissions": sorted(old)},
        new_value={
            "role": role.code,
            "permissions": sorted(new),
            "added": sorted(new - old),
            "removed": sorted(old - new),
        },
        request=request,
    )
    return role
