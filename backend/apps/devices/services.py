from __future__ import annotations

from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.services import AuditService
from apps.accounts.models import UserRole
from apps.common.authorization import ObjectAuthorization
from apps.common.events import emit
from apps.common.tenancy import TenantContext, get_tenant_context
from apps.devices.models import Device, DeviceAssignment, DeviceStatus, STATUS_TRANSITIONS
from apps.devices.selectors import active_assignment, assignment_queryset
from apps.employees.models import Employee
from apps.employees.selectors import employee_queryset

_authz = ObjectAuthorization()
RESOURCE_DEVICE = "devices.Device"


class DeviceService:
    def create_device(self, *, request, validated: dict) -> Device:
        ctx = _require_company(request)
        payload = {**validated, "company": ctx.company, "status": DeviceStatus.AVAILABLE}
        device = Device(**payload)
        try:
            with transaction.atomic():
                device.save()
        except DjangoValidationError as exc:
            raise ValidationError(_django_errors(exc))
        except IntegrityError:
            raise ValidationError(_integrity_errors(device))
        emit(
            "device.created",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_DEVICE,
            resource_id=device.id,
            metadata={"asset_code": device.asset_code},
        )
        return device

    def update_device(self, *, request, device: Device, validated: dict) -> Device:
        ctx = _require_company(request)
        self._assert_same_company(ctx, device)
        if not _authz.can_view(ctx, device):
            raise NotFound()
        status = validated.pop("status", None)
        with transaction.atomic():
            row = Device.objects.select_for_update().get(pk=device.pk)
            self._assert_same_company(ctx, row)
            for field, value in validated.items():
                setattr(row, field, value)
            try:
                row.save()
            except DjangoValidationError as exc:
                raise ValidationError(_django_errors(exc))
            except IntegrityError:
                raise ValidationError(_integrity_errors(row))
            if status is not None and status != row.status:
                row = self._change_status_locked(ctx=ctx, device=row, status=status)
        emit(
            "device.updated",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_DEVICE,
            resource_id=row.id,
            metadata={"asset_code": row.asset_code},
        )
        return row

    def delete_device(self, *, request, device: Device) -> None:
        ctx = _require_company(request)
        self._assert_same_company(ctx, device)
        if not _authz.can_view(ctx, device):
            raise NotFound()
        with transaction.atomic():
            row = Device.objects.select_for_update().get(pk=device.pk)
            self._assert_same_company(ctx, row)
            if assignment_queryset().filter(device=row).exists():
                raise ValidationError(
                    {
                        "non_field_errors": [
                            "This device has assignment history. Retire it instead of deleting."
                        ]
                    }
                )
            asset_code = row.asset_code
            pk = row.id
            row.delete()
        emit(
            "device.deleted",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_DEVICE,
            resource_id=pk,
            metadata={"asset_code": asset_code},
        )

    def change_device_status(self, *, request, device: Device, status: str) -> Device:
        ctx = _require_company(request)
        self._assert_same_company(ctx, device)
        if not _authz.can_view(ctx, device):
            raise NotFound()
        with transaction.atomic():
            row = Device.objects.select_for_update().get(pk=device.pk)
            self._assert_same_company(ctx, row)
            return self._change_status_locked(ctx=ctx, device=row, status=status)

    def assign_device(
        self,
        *,
        request,
        device: Device,
        employee: Employee,
        condition_on_assignment: str = "",
        notes: str = "",
    ) -> Device:
        ctx = _require_company(request)
        self._assert_same_company(ctx, device)
        if not _authz.can_view(ctx, device):
            raise NotFound()
        self._assert_assignable_employee(ctx, employee)
        with transaction.atomic():
            row = (
                Device.objects.select_for_update()
                .select_related("company")
                .get(pk=device.pk)
            )
            self._assert_same_company(ctx, row)
            if row.status != DeviceStatus.AVAILABLE:
                raise ValidationError(
                    {
                        "non_field_errors": [
                            f"Only available devices can be assigned (status is {row.status})."
                        ]
                    }
                )
            if active_assignment(device=row) is not None:
                raise ValidationError(
                    {
                        "non_field_errors": [
                            "This device already has an active assignment."
                        ]
                    }
                )
            now = timezone.now()
            assignment = DeviceAssignment(
                company=ctx.company,
                device=row,
                employee=employee,
                assigned_at=now,
                condition_on_assignment=(condition_on_assignment or "").strip(),
                notes=(notes or "").strip(),
            )
            try:
                assignment.save()
            except DjangoValidationError as exc:
                raise ValidationError(_django_errors(exc))
            except IntegrityError:
                raise ValidationError(
                    {
                        "non_field_errors": [
                            "This device already has an active assignment."
                        ]
                    }
                )
            row.status = DeviceStatus.ASSIGNED
            row.save(update_fields=["status", "updated_at"])
            AuditService.log(
                company=ctx.company,
                user=ctx.user,
                action=AuditAction.DEVICE_ASSIGNED,
                entity_type=AuditEntityType.DEVICE,
                entity_id=row.id,
                old_value={
                    "status": DeviceStatus.AVAILABLE,
                    "employee_id": None,
                    "assignment_id": None,
                },
                new_value={
                    "status": DeviceStatus.ASSIGNED,
                    "device_id": str(row.id),
                    "asset_code": row.asset_code,
                    "employee_id": str(employee.id),
                    "employee_code": employee.employee_code,
                    "assignment_id": str(assignment.id),
                },
                request=request,
            )
        emit(
            "device.assigned",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_DEVICE,
            resource_id=row.id,
            metadata={
                "assignment_id": str(assignment.id),
                "employee_id": str(employee.id),
            },
        )
        from apps.notifications.integration import notify_device_assigned

        notify_device_assigned(row, employee, actor=ctx.user)
        return row

    def return_device(
        self,
        *,
        request,
        device: Device,
        condition_on_return: str = "",
        notes: str = "",
    ) -> Device:
        ctx = _require_company(request)
        self._assert_same_company(ctx, device)
        if not _authz.can_view(ctx, device):
            raise NotFound()
        with transaction.atomic():
            row = (
                Device.objects.select_for_update()
                .select_related("company")
                .get(pk=device.pk)
            )
            self._assert_same_company(ctx, row)
            assignment = (
                DeviceAssignment.objects.select_for_update()
                .select_related("device", "employee")
                .filter(device=row, returned_at__isnull=True)
                .first()
            )
            if assignment is None:
                raise ValidationError(
                    {
                        "non_field_errors": [
                            "This device has no active assignment to return."
                        ]
                    }
                )
            now = timezone.now()
            if now < assignment.assigned_at:
                raise ValidationError(
                    {
                        "non_field_errors": [
                            "returned_at must be on or after assigned_at."
                        ]
                    }
                )
            extra_notes = (notes or "").strip()
            combined = assignment.notes.strip()
            if extra_notes:
                combined = f"{combined}\n{extra_notes}".strip() if combined else extra_notes
            assignment.returned_at = now
            assignment.condition_on_return = (condition_on_return or "").strip()
            assignment.notes = combined
            assignment.save()
            row.status = DeviceStatus.AVAILABLE
            row.save(update_fields=["status", "updated_at"])
            AuditService.log(
                company=ctx.company,
                user=ctx.user,
                action=AuditAction.DEVICE_RETURNED,
                entity_type=AuditEntityType.DEVICE,
                entity_id=row.id,
                old_value={
                    "status": DeviceStatus.ASSIGNED,
                    "employee_id": str(assignment.employee_id),
                    "employee_code": assignment.employee.employee_code,
                    "assignment_id": str(assignment.id),
                    "returned_at": None,
                },
                new_value={
                    "status": DeviceStatus.AVAILABLE,
                    "device_id": str(row.id),
                    "asset_code": row.asset_code,
                    "employee_id": str(assignment.employee_id),
                    "employee_code": assignment.employee.employee_code,
                    "assignment_id": str(assignment.id),
                    "returned_at": now.isoformat(),
                },
                request=request,
            )
        emit(
            "device.returned",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_DEVICE,
            resource_id=row.id,
            metadata={"assignment_id": str(assignment.id)},
        )
        from apps.notifications.integration import notify_device_returned

        notify_device_returned(row, assignment.employee, actor=ctx.user)
        return row

    def _change_status_locked(
        self, *, ctx: TenantContext, device: Device, status: str
    ) -> Device:
        if status == DeviceStatus.ASSIGNED:
            raise ValidationError(
                {
                    "status": [
                        "Devices become assigned only through the assign action."
                    ]
                }
            )
        if (
            device.status == DeviceStatus.ASSIGNED
            and status == DeviceStatus.AVAILABLE
        ):
            raise ValidationError(
                {
                    "status": [
                        "Assigned devices become available only through the return action."
                    ]
                }
            )
        allowed = STATUS_TRANSITIONS.get(device.status, frozenset())
        if status not in allowed:
            raise ValidationError(
                {
                    "status": [
                        f"Cannot change status from {device.status} to {status}."
                    ]
                }
            )
        if device.status == DeviceStatus.ASSIGNED and status == DeviceStatus.LOST:
            assignment = (
                DeviceAssignment.objects.select_for_update()
                .filter(device=device, returned_at__isnull=True)
                .first()
            )
            if assignment is not None:
                now = timezone.now()
                assignment.returned_at = now
                lost_note = "Closed because the device was marked lost."
                assignment.notes = (
                    f"{assignment.notes}\n{lost_note}".strip()
                    if assignment.notes
                    else lost_note
                )
                assignment.save()
        previous = device.status
        device.status = status
        device.save(update_fields=["status", "updated_at"])
        action = {
            DeviceStatus.RETIRED: "device.retired",
            DeviceStatus.LOST: "device.lost",
        }.get(status, "device.status_changed")
        emit(
            action,
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_DEVICE,
            resource_id=device.id,
            metadata={"from": previous, "to": status},
        )
        return device

    def _assert_assignable_employee(self, ctx: TenantContext, employee: Employee) -> None:
        if ctx.company is None or employee.company_id != ctx.company.id:
            raise ValidationError(
                {"employee_id": "Employee must belong to the same company."}
            )
        if not _authz.can_view(ctx, employee):
            raise NotFound()
        if ctx.role_code == UserRole.MANAGER and not _authz._is_direct_report(
            ctx, employee
        ):
            raise NotFound()

    def _assert_same_company(self, ctx: TenantContext, device: Device) -> None:
        if ctx.company is None or device.company_id != ctx.company.id:
            raise NotFound()


def _require_company(request) -> TenantContext:
    ctx = get_tenant_context(request)
    if ctx.company is None:
        raise PermissionDenied("You do not have access to this company.")
    return ctx


def _django_errors(exc: DjangoValidationError) -> dict:
    if hasattr(exc, "message_dict"):
        return exc.message_dict
    return {"non_field_errors": list(exc.messages)}


def _integrity_errors(device: Device) -> dict:
    qs = Device.objects.filter(company_id=device.company_id)
    if device.pk:
        qs = qs.exclude(pk=device.pk)
    if qs.filter(asset_code=device.asset_code).exists():
        return {
            "asset_code": [
                "A device with this asset code already exists in this company."
            ]
        }
    if device.serial_number and qs.filter(serial_number=device.serial_number).exists():
        return {
            "serial_number": [
                "A device with this serial number already exists in this company."
            ]
        }
    return {
        "non_field_errors": ["This device conflicts with an existing company record."]
    }


def resolve_employee(*, company, employee_id) -> Employee:
    employee = employee_queryset().filter(company=company, pk=employee_id).first()
    if employee is None:
        raise ValidationError({"employee_id": "Unknown employee."})
    return employee
