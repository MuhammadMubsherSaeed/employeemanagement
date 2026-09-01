from __future__ import annotations

from io import BytesIO

from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.files.base import File
from django.db import transaction
from django.http import FileResponse
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.services import AuditService
from apps.common.authorization import ObjectAuthorization
from apps.common.events import emit
from apps.common.storage import (
    StorageDeleteError,
    StorageError,
    StorageUnavailable,
    get_object_storage,
)
from apps.common.tenancy import TenantContext, get_tenant_context
from apps.documents.models import (
    STATUS_TRANSITIONS,
    DocumentStatus,
    EmployeeDocument,
    detected_mime_type,
    sanitize_file_name,
    validate_employee_document_file,
)
from apps.employees.models import Employee
from apps.employees.selectors import employee_queryset

_authz = ObjectAuthorization()
RESOURCE = "documents.EmployeeDocument"


class DocumentService:
    def create_document(self, *, request, validated: dict) -> EmployeeDocument:
        ctx = _require_company(request)
        employee = validated["employee"]
        self._assert_upload_target(ctx, employee)
        upload = validated["file"]
        metadata = _file_metadata(upload)
        document = EmployeeDocument(
            company=ctx.company,
            employee=employee,
            document_type=validated["document_type"],
            title=validated["title"],
            description=validated.get("description") or "",
            file=upload,
            expiry_date=validated.get("expiry_date"),
            status=DocumentStatus.ACTIVE,
            uploaded_by=ctx.user,
            **metadata,
        )
        try:
            with transaction.atomic():
                document.save()
                _audit_log(
                    request=request,
                    ctx=ctx,
                    action=AuditAction.DOCUMENT_UPLOADED,
                    document=document,
                    extra={"document_type": document.document_type},
                )
        except DjangoValidationError as exc:
            raise ValidationError(_django_errors(exc))
        emit(
            "document.uploaded",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE,
            resource_id=document.id,
            metadata={
                "employee_id": str(employee.id),
                "document_type": document.document_type,
            },
        )
        return document

    def update_document(
        self,
        *,
        request,
        document: EmployeeDocument,
        validated: dict,
    ) -> EmployeeDocument:
        ctx = _require_company(request)
        self._assert_same_company(ctx, document)
        if not _authz.can_view(ctx, document):
            raise NotFound()
        upload = validated.pop("file", None)
        status = validated.pop("status", None)
        replaced = False
        old_name = document.file.name if document.file else ""
        with transaction.atomic():
            row = (
                EmployeeDocument.objects.select_for_update()
                .select_related(
                    "employee",
                    "company",
                )
                .get(pk=document.pk)
            )
            self._assert_same_company(ctx, row)
            if not _authz.can_view(ctx, row):
                raise NotFound()
            for field, value in validated.items():
                setattr(row, field, value)
            if upload is not None:
                metadata = _file_metadata(upload)
                row.file = upload
                row.file_name = metadata["file_name"]
                row.file_size = metadata["file_size"]
                row.mime_type = metadata["mime_type"]
                replaced = True
            if status is not None and status != row.status:
                self._apply_status(row, status)
            try:
                row.save()
            except DjangoValidationError as exc:
                raise ValidationError(_django_errors(exc))
            if replaced and old_name and old_name != row.file.name:
                transaction.on_commit(lambda: _delete_storage(old_name))
        action = "document.replaced" if replaced else "document.updated"
        if status == DocumentStatus.ARCHIVED and not replaced:
            action = "document.archived"
        emit(
            action,
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE,
            resource_id=row.id,
            metadata={"replaced": replaced, "status": row.status},
        )
        return row

    def delete_document(self, *, request, document: EmployeeDocument) -> None:
        ctx = _require_company(request)
        self._assert_same_company(ctx, document)
        if not _authz.can_view(ctx, document):
            raise NotFound()
        with transaction.atomic():
            row = EmployeeDocument.objects.select_for_update().get(pk=document.pk)
            self._assert_same_company(ctx, row)
            path = row.file.name if row.file else ""
            pk = row.id
            title = row.title
            meta = _document_meta(row)
            for holder in (document, row):
                if holder.file:
                    try:
                        holder.file.close()
                    except Exception:
                        pass
            if path:
                try:
                    get_object_storage().delete(path, missing_ok=True)
                except StorageDeleteError as exc:
                    raise StorageUnavailable(detail=str(exc)) from exc
            row.file = None
            row.delete()
            _audit_log(
                request=request,
                ctx=ctx,
                action=AuditAction.DOCUMENT_DELETED,
                document_id=pk,
                extra={"title": title, **meta},
            )
        emit(
            "document.deleted",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE,
            resource_id=pk,
            metadata={"title": title},
        )

    def download_document(self, *, request, document: EmployeeDocument) -> FileResponse:
        ctx = _require_company(request)
        self._assert_same_company(ctx, document)
        if not _authz.can_view(ctx, document):
            raise NotFound()
        if not document.file:
            raise NotFound()
        try:
            payload = get_object_storage().read(document.file.name)
        except StorageError:
            raise NotFound()
        emit(
            "document.downloaded",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE,
            resource_id=document.id,
            metadata={"file_name": document.file_name},
        )
        _audit_log(
            request=request,
            ctx=ctx,
            action=AuditAction.DOCUMENT_DOWNLOADED,
            document=document,
        )
        response = FileResponse(
            BytesIO(payload),
            as_attachment=True,
            filename=document.file_name or "document",
        )
        if document.mime_type:
            response["Content-Type"] = document.mime_type
        return response

    def access_document(self, *, request, document: EmployeeDocument) -> dict:
        ctx = _require_company(request)
        self._assert_same_company(ctx, document)
        if not _authz.can_view(ctx, document):
            raise NotFound()
        if not document.file:
            raise NotFound()
        if not get_object_storage().exists(document.file.name):
            raise NotFound()
        url = get_object_storage().signed_url(document.file.name)
        from django.conf import settings

        return {
            "mode": "signed" if url else "stream",
            "url": url,
            "file_name": document.file_name,
            "mime_type": document.mime_type,
            "expires_in": (
                int(getattr(settings, "AWS_QUERYSTRING_EXPIRE", 300)) if url else None
            ),
        }

    def _apply_status(self, document: EmployeeDocument, status: str) -> None:
        allowed = STATUS_TRANSITIONS.get(document.status, frozenset())
        if status not in allowed:
            raise ValidationError(
                {
                    "status": [
                        f"Cannot change status from {document.status} to {status}."
                    ]
                }
            )
        if status == DocumentStatus.EXPIRED:
            from django.utils import timezone

            today = timezone.localdate()
            if document.expiry_date is None or document.expiry_date >= today:
                raise ValidationError(
                    {
                        "status": [
                            "EXPIRED is only allowed when expiry_date is in the past."
                        ]
                    }
                )
        document.status = status

    def _assert_upload_target(self, ctx: TenantContext, employee: Employee) -> None:
        if ctx.company is None or employee.company_id != ctx.company.id:
            raise ValidationError(
                {"employee_id": "Employee must belong to the same company."}
            )
        if not _authz.can_view(ctx, employee):
            raise NotFound()

    def _assert_same_company(
        self, ctx: TenantContext, document: EmployeeDocument
    ) -> None:
        if ctx.company is None or document.company_id != ctx.company.id:
            raise NotFound()


def resolve_employee(*, company, employee_id) -> Employee:
    employee = employee_queryset().filter(company=company, pk=employee_id).first()
    if employee is None:
        raise ValidationError({"employee_id": "Unknown employee."})
    return employee


def resolve_visible_employee(*, request, employee_id) -> Employee:
    from django.core.exceptions import ValidationError as DjangoValidationError

    ctx = _require_company(request)
    try:
        employee = (
            employee_queryset().filter(company=ctx.company, pk=employee_id).first()
        )
    except (DjangoValidationError, ValueError, TypeError):
        raise NotFound()
    if employee is None or not _authz.can_view(ctx, employee):
        raise NotFound()
    return employee


def _file_metadata(upload: File) -> dict:
    validate_employee_document_file(upload)
    return {
        "file_name": sanitize_file_name(getattr(upload, "name", "document")),
        "file_size": int(getattr(upload, "size", 0) or 0),
        "mime_type": detected_mime_type(upload),
    }


def _delete_storage(path: str) -> None:
    try:
        get_object_storage().delete(path, missing_ok=True)
    except StorageDeleteError:
        return


def _document_meta(document: EmployeeDocument | None) -> dict:
    if document is None:
        return {}
    return {
        "file_name": document.file_name,
        "file_size": document.file_size,
        "mime_type": document.mime_type,
        "document_type": document.document_type,
    }


def _audit_log(
    *,
    request,
    ctx: TenantContext,
    action: str,
    document: EmployeeDocument | None = None,
    document_id=None,
    extra: dict | None = None,
) -> None:
    payload = {**(extra or {})}
    if document is not None:
        payload.update(_document_meta(document))
        document_id = document.id
    AuditService.log(
        company=ctx.company,
        user=ctx.user,
        action=action,
        entity_type=AuditEntityType.EMPLOYEE_DOCUMENT,
        entity_id=document_id,
        new_value=payload,
        request=request,
    )


def _require_company(request) -> TenantContext:
    ctx = get_tenant_context(request)
    if ctx.company is None:
        raise PermissionDenied("You do not have access to this company.")
    return ctx


def _django_errors(exc: DjangoValidationError) -> dict:
    if hasattr(exc, "message_dict"):
        return exc.message_dict
    return {"non_field_errors": list(exc.messages)}
