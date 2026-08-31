from __future__ import annotations

from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.files.base import File
from django.db import transaction
from django.http import FileResponse
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from apps.common.authorization import ObjectAuthorization
from apps.common.events import emit
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
        storage = document.file.storage if document.file else None
        with transaction.atomic():
            row = EmployeeDocument.objects.select_for_update().select_related(
                "employee",
                "company",
            ).get(pk=document.pk)
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
            if replaced and storage and old_name and old_name != row.file.name:
                transaction.on_commit(lambda: _delete_storage(storage, old_name))
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
            storage = row.file.storage if row.file else None
            pk = row.id
            title = row.title
            row.delete()
        if storage and path:
            transaction.on_commit(lambda: _delete_storage(storage, path))
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
            handle = document.file.open("rb")
        except (FileNotFoundError, OSError, ValueError):
            raise NotFound()
        emit(
            "document.downloaded",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE,
            resource_id=document.id,
            metadata={"file_name": document.file_name},
        )
        response = FileResponse(
            handle,
            as_attachment=True,
            filename=document.file_name or "document",
        )
        if document.mime_type:
            response["Content-Type"] = document.mime_type
        return response

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


def _file_metadata(upload: File) -> dict:
    validate_employee_document_file(upload)
    return {
        "file_name": sanitize_file_name(getattr(upload, "name", "document")),
        "file_size": int(getattr(upload, "size", 0) or 0),
        "mime_type": detected_mime_type(upload),
    }


def _delete_storage(storage, path: str) -> None:
    try:
        if path and storage.exists(path):
            storage.delete(path)
    except OSError:
        return


def _require_company(request) -> TenantContext:
    ctx = get_tenant_context(request)
    if ctx.company is None:
        raise PermissionDenied("You do not have access to this company.")
    return ctx


def _django_errors(exc: DjangoValidationError) -> dict:
    if hasattr(exc, "message_dict"):
        return exc.message_dict
    return {"non_field_errors": list(exc.messages)}
