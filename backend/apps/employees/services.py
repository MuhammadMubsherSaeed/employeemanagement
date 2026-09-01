"""Employee writes stay in serializers + tenant mixins.

Audit logs are written in the same database transaction as the employee row.
"""

from django.db import transaction

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.services import AuditService, changed_fields
from apps.employees.models import EmployeeStatus


def employee_snapshot(employee) -> dict:
    department = getattr(employee, "department", None)
    position = getattr(employee, "position", None)
    return {
        "employee_code": employee.employee_code,
        "first_name": employee.first_name,
        "last_name": employee.last_name,
        "status": employee.status,
        "department_id": str(employee.department_id) if employee.department_id else None,
        "department": department.name if department is not None else None,
        "position_id": str(employee.position_id) if employee.position_id else None,
        "position": position.title if position is not None else None,
        "manager_id": str(employee.manager_id) if employee.manager_id else None,
        "employment_type": employee.employment_type,
        "joining_date": (
            employee.joining_date.isoformat() if employee.joining_date else None
        ),
        "user_id": employee.user_id,
    }


def _is_public_profile_image(value: str) -> bool:
    text = (value or "").strip()
    return text.startswith("http://") or text.startswith("https://")


def public_profile_image_value(employee) -> str:
    value = (getattr(employee, "profile_image", None) or "").strip()
    if _is_public_profile_image(value):
        return value
    return ""


def set_profile_image(*, request, employee, upload) -> None:
    from apps.common.authorization import ObjectAuthorization
    from apps.common.storage import StorageDeleteError, StorageUnavailable, get_object_storage
    from apps.common.tenancy import get_tenant_context
    from apps.documents.models import (
        detected_mime_type,
        profile_image_upload_path,
        sanitize_file_name,
        validate_profile_image_file,
    )
    from rest_framework.exceptions import NotFound, PermissionDenied

    ctx = get_tenant_context(request)
    authz = ObjectAuthorization()
    if ctx.company is None or employee.company_id != ctx.company.id:
        raise NotFound()
    if not authz.can_view(ctx, employee):
        raise NotFound()
    is_self = employee.user_id == ctx.user.id
    if not is_self:
        if not ctx.has_permission("employees.update"):
            raise PermissionDenied(
                "You do not have permission to perform this action."
            )
        if not authz.can_change(ctx, employee):
            raise PermissionDenied(
                "You do not have permission to perform this action."
            )
    validate_profile_image_file(upload)
    key = profile_image_upload_path(employee, getattr(upload, "name", "photo.jpg"))
    storage = get_object_storage()
    saved = storage.save(key, upload)
    previous = (employee.profile_image or "").strip()
    employee.profile_image = saved
    employee.save(update_fields=["profile_image", "updated_at"])
    if previous and previous != saved and not _is_public_profile_image(previous):
        try:
            storage.delete(previous, missing_ok=True)
        except StorageDeleteError as exc:
            raise StorageUnavailable(detail=str(exc)) from exc
    AuditService.log(
        company=ctx.company,
        user=ctx.user,
        action=AuditAction.PROFILE_IMAGE_UPDATED,
        entity_type=AuditEntityType.EMPLOYEE,
        entity_id=employee.id,
        new_value={
            "file_name": sanitize_file_name(getattr(upload, "name", "photo")),
            "file_size": int(getattr(upload, "size", 0) or 0),
            "mime_type": detected_mime_type(upload),
        },
        request=request,
    )


def clear_profile_image(*, request, employee) -> None:
    from apps.common.authorization import ObjectAuthorization
    from apps.common.storage import StorageDeleteError, StorageUnavailable, get_object_storage
    from apps.common.tenancy import get_tenant_context
    from rest_framework.exceptions import NotFound, PermissionDenied

    ctx = get_tenant_context(request)
    authz = ObjectAuthorization()
    if ctx.company is None or employee.company_id != ctx.company.id:
        raise NotFound()
    if not authz.can_view(ctx, employee):
        raise NotFound()
    is_self = employee.user_id == ctx.user.id
    if not is_self:
        if not ctx.has_permission("employees.update"):
            raise PermissionDenied(
                "You do not have permission to perform this action."
            )
        if not authz.can_change(ctx, employee):
            raise PermissionDenied(
                "You do not have permission to perform this action."
            )
    previous = (employee.profile_image or "").strip()
    employee.profile_image = ""
    employee.save(update_fields=["profile_image", "updated_at"])
    if previous and not _is_public_profile_image(previous):
        try:
            get_object_storage().delete(previous, missing_ok=True)
        except StorageDeleteError as exc:
            raise StorageUnavailable(detail=str(exc)) from exc
    AuditService.log(
        company=ctx.company,
        user=ctx.user,
        action=AuditAction.PROFILE_IMAGE_UPDATED,
        entity_type=AuditEntityType.EMPLOYEE,
        entity_id=employee.id,
        new_value={"cleared": True},
        request=request,
    )


def open_profile_image(*, request, employee):
    from io import BytesIO

    from apps.common.authorization import ObjectAuthorization
    from apps.common.storage import StorageError, get_object_storage
    from apps.common.tenancy import get_tenant_context
    from apps.documents.models import MIME_BY_KIND, sniff_document_kind
    from django.http import FileResponse
    from rest_framework.exceptions import NotFound

    ctx = get_tenant_context(request)
    authz = ObjectAuthorization()
    if ctx.company is None or employee.company_id != ctx.company.id:
        raise NotFound()
    if not authz.can_view(ctx, employee):
        raise NotFound()
    key = (employee.profile_image or "").strip()
    if not key or _is_public_profile_image(key):
        raise NotFound()
    try:
        payload = get_object_storage().read(key)
    except StorageError:
        raise NotFound()
    content_type = "application/octet-stream"
    try:
        kind = sniff_document_kind(BytesIO(payload))
        content_type = MIME_BY_KIND.get(kind, content_type)
    except Exception:
        pass
    return FileResponse(BytesIO(payload), content_type=content_type)


def department_snapshot(department) -> dict:
    return {
        "name": department.name,
        "description": department.description,
        "status": department.status,
        "manager_id": str(department.manager_id) if department.manager_id else None,
    }


def _actor(request):
    if request is None:
        return None
    user = getattr(request, "user", None)
    return user if getattr(user, "is_authenticated", False) else None


def record_employee_created(*, employee, request) -> None:
    AuditService.log(
        company=employee.company,
        user=_actor(request),
        action=AuditAction.EMPLOYEE_CREATED,
        entity_type=AuditEntityType.EMPLOYEE,
        entity_id=employee.id,
        new_value=employee_snapshot(employee),
        request=request,
    )


def record_employee_updated(*, previous: dict, employee, request) -> None:
    current = employee_snapshot(employee)
    old_value, new_value = changed_fields(previous, current)
    if not old_value and not new_value:
        return
    deactivated = previous.get("status") not in {
        EmployeeStatus.INACTIVE,
        EmployeeStatus.TERMINATED,
    } and employee.status in {EmployeeStatus.INACTIVE, EmployeeStatus.TERMINATED}
    AuditService.log(
        company=employee.company,
        user=_actor(request),
        action=(
            AuditAction.EMPLOYEE_DEACTIVATED
            if deactivated
            else AuditAction.EMPLOYEE_UPDATED
        ),
        entity_type=AuditEntityType.EMPLOYEE,
        entity_id=employee.id,
        old_value=old_value,
        new_value=new_value,
        request=request,
    )


def record_department_created(*, department, request) -> None:
    AuditService.log(
        company=department.company,
        user=_actor(request),
        action=AuditAction.DEPARTMENT_CREATED,
        entity_type=AuditEntityType.DEPARTMENT,
        entity_id=department.id,
        new_value=department_snapshot(department),
        request=request,
    )


def record_department_updated(*, previous: dict, department, request) -> None:
    current = department_snapshot(department)
    old_value, new_value = changed_fields(previous, current)
    if not old_value and not new_value:
        return
    AuditService.log(
        company=department.company,
        user=_actor(request),
        action=AuditAction.DEPARTMENT_UPDATED,
        entity_type=AuditEntityType.DEPARTMENT,
        entity_id=department.id,
        old_value=old_value,
        new_value=new_value,
        request=request,
    )


class EmployeeService:
    """Trusted server-side employee writes that also emit audit logs."""

    @transaction.atomic
    def create(self, *, serializer, extras: dict):
        request = serializer.context.get("request")
        employee = serializer.save(**extras)
        record_employee_created(employee=employee, request=request)
        return employee
