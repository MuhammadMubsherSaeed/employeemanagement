from __future__ import annotations

from datetime import date

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.services import AuditService
from apps.common.authorization import ObjectAuthorization
from apps.common.events import emit
from apps.common.tenancy import TenantContext
from apps.employees.models import Employee
from apps.employees.selectors import employee_for_user
from apps.leave.calendar import LeaveCalendarService
from apps.leave.models import (
    ACTIVE_LEAVE_STATUSES,
    MAX_REASON_LENGTH,
    MIN_REJECTION_LENGTH,
    LeaveBalance,
    LeaveRequest,
    LeaveRequestStatus,
    LeaveType,
    LeaveTypeStatus,
)
from apps.leave.selectors import overlapping_requests

_authz = ObjectAuthorization()
RESOURCE_REQUEST = "leave.LeaveRequest"
RESOURCE_BALANCE = "leave.LeaveBalance"


class LeaveService:
    def __init__(self, calendar: LeaveCalendarService | None = None) -> None:
        self.calendar = calendar or LeaveCalendarService()

    def create_request(self, *, request, validated: dict) -> LeaveRequest:
        ctx = _require_company(request)
        employee = _actor_employee(ctx)
        leave_type = validated["leave_type"]
        start = validated["start_date"]
        end = validated["end_date"]
        reason = (validated.get("reason") or "").strip()
        if len(reason) > MAX_REASON_LENGTH:
            raise ValidationError({"reason": "Reason is too long."})
        self._validate_type_and_dates(ctx, employee, leave_type, start, end)
        total_days = self.calendar.working_days_between(
            company=ctx.company, start=start, end=end
        )
        if total_days <= 0:
            raise ValidationError(
                {
                    "non_field_errors": [
                        "The selected dates contain no working days."
                    ]
                }
            )
        with transaction.atomic():
            Employee.objects.select_for_update().get(pk=employee.pk)
            if overlapping_requests(
                company=ctx.company,
                employee=employee,
                start=start,
                end=end,
            ).exists():
                raise ValidationError(
                    {
                        "non_field_errors": [
                            "This request overlaps an existing pending or approved leave."
                        ]
                    }
                )
            row = LeaveRequest(
                company=ctx.company,
                employee=employee,
                leave_type=leave_type,
                start_date=start,
                end_date=end,
                total_days=total_days,
                reason=reason,
                attachment=validated.get("attachment"),
                status=LeaveRequestStatus.PENDING,
            )
            row.save()
            AuditService.log(
                company=ctx.company,
                user=ctx.user,
                action=AuditAction.LEAVE_SUBMITTED,
                entity_type=AuditEntityType.LEAVE_REQUEST,
                entity_id=row.id,
                new_value=_leave_snapshot(row),
                request=request,
            )
        emit(
            "leave.request.created",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_REQUEST,
            resource_id=row.id,
            metadata={"total_days": total_days},
        )
        from apps.notifications.integration import notify_leave_submitted

        notify_leave_submitted(row, actor=ctx.user)
        return row

    def approve(self, *, request, leave_request: LeaveRequest) -> LeaveRequest:
        ctx = _require_company(request)
        self._assert_can_decide(ctx, leave_request)
        if leave_request.employee.user_id == ctx.user.id:
            raise PermissionDenied("You cannot approve your own leave request.")
        with transaction.atomic():
            row = (
                LeaveRequest.objects.select_for_update()
                .select_related("company", "employee", "leave_type")
                .get(pk=leave_request.pk)
            )
            self._assert_same_company(ctx, row)
            if row.status != LeaveRequestStatus.PENDING:
                raise ValidationError(
                    {
                        "non_field_errors": [
                            f"Only pending requests can be approved (status is {row.status})."
                        ]
                    }
                )
            year = row.start_date.year
            balance = (
                LeaveBalance.objects.select_for_update()
                .select_related("company", "employee", "leave_type")
                .filter(
                    company=ctx.company,
                    employee=row.employee,
                    leave_type=row.leave_type,
                    year=year,
                )
                .first()
            )
            if balance is None:
                raise ValidationError(
                    {
                        "non_field_errors": [
                            "No leave balance exists for this type and year."
                        ]
                    }
                )
            if balance.remaining_days < row.total_days:
                raise ValidationError(
                    {
                        "non_field_errors": [
                            "Insufficient leave balance for this request."
                        ]
                    }
                )
            previous = _leave_snapshot(row)
            balance.used_days += row.total_days
            balance.save()
            row.status = LeaveRequestStatus.APPROVED
            row.approved_by = ctx.user
            row.approved_at = timezone.now()
            row.rejection_reason = ""
            row.save()
            AuditService.log(
                company=ctx.company,
                user=ctx.user,
                action=AuditAction.LEAVE_APPROVED,
                entity_type=AuditEntityType.LEAVE_REQUEST,
                entity_id=row.id,
                old_value=previous,
                new_value=_leave_snapshot(row),
                request=request,
            )
        emit(
            "leave.request.approved",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_REQUEST,
            resource_id=row.id,
            metadata={"total_days": row.total_days},
        )
        emit(
            "leave.balance.changed",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_BALANCE,
            resource_id=balance.id,
            metadata={"used_days": balance.used_days, "delta": row.total_days},
        )
        from apps.notifications.integration import notify_leave_approved

        notify_leave_approved(row, actor=ctx.user)
        return row

    def reject(
        self, *, request, leave_request: LeaveRequest, rejection_reason: str
    ) -> LeaveRequest:
        ctx = _require_company(request)
        self._assert_can_decide(ctx, leave_request)
        if leave_request.employee.user_id == ctx.user.id:
            raise PermissionDenied("You cannot reject your own leave request.")
        reason = (rejection_reason or "").strip()
        if len(reason) < MIN_REJECTION_LENGTH:
            raise ValidationError(
                {"rejection_reason": "Enter a meaningful rejection reason."}
            )
        with transaction.atomic():
            row = (
                LeaveRequest.objects.select_for_update()
                .select_related("company", "employee", "leave_type")
                .get(pk=leave_request.pk)
            )
            self._assert_same_company(ctx, row)
            if row.status != LeaveRequestStatus.PENDING:
                raise ValidationError(
                    {
                        "non_field_errors": [
                            f"Only pending requests can be rejected (status is {row.status})."
                        ]
                    }
                )
            previous = _leave_snapshot(row)
            row.status = LeaveRequestStatus.REJECTED
            row.approved_by = ctx.user
            row.approved_at = timezone.now()
            row.rejection_reason = reason
            row.save()
            AuditService.log(
                company=ctx.company,
                user=ctx.user,
                action=AuditAction.LEAVE_REJECTED,
                entity_type=AuditEntityType.LEAVE_REQUEST,
                entity_id=row.id,
                old_value=previous,
                new_value=_leave_snapshot(row),
                request=request,
            )
        emit(
            "leave.request.rejected",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_REQUEST,
            resource_id=row.id,
            metadata={"rejection_reason": reason},
        )
        from apps.notifications.integration import notify_leave_rejected

        notify_leave_rejected(row, actor=ctx.user)
        return row

    def cancel(self, *, request, leave_request: LeaveRequest) -> LeaveRequest:
        ctx = _require_company(request)
        self._assert_can_cancel(ctx, leave_request)
        with transaction.atomic():
            row = (
                LeaveRequest.objects.select_for_update()
                .select_related("company", "employee", "leave_type")
                .get(pk=leave_request.pk)
            )
            self._assert_same_company(ctx, row)
            previous = row.status
            if previous == LeaveRequestStatus.CANCELLED:
                raise ValidationError(
                    {"non_field_errors": ["This leave request is already cancelled."]}
                )
            if previous == LeaveRequestStatus.REJECTED:
                raise ValidationError(
                    {"non_field_errors": ["Rejected leave cannot be cancelled."]}
                )
            if previous not in ACTIVE_LEAVE_STATUSES:
                raise ValidationError(
                    {
                        "non_field_errors": [
                            f"This leave request cannot be cancelled (status is {previous})."
                        ]
                    }
                )
            restored = 0
            if previous == LeaveRequestStatus.APPROVED:
                restored = self._restore_balance(ctx, row)
            old_value = _leave_snapshot(row)
            row.status = LeaveRequestStatus.CANCELLED
            row.save(update_fields=["status", "updated_at"])
            AuditService.log(
                company=ctx.company,
                user=ctx.user,
                action=AuditAction.LEAVE_CANCELLED,
                entity_type=AuditEntityType.LEAVE_REQUEST,
                entity_id=row.id,
                old_value=old_value,
                new_value=_leave_snapshot(row),
                request=request,
            )
        emit(
            "leave.request.cancelled",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_REQUEST,
            resource_id=row.id,
            metadata={"previous_status": previous, "restored_days": restored},
        )
        from apps.notifications.integration import notify_leave_cancelled

        notify_leave_cancelled(row, actor=ctx.user)
        return row

    def allocate_balance(
        self, *, request, balance: LeaveBalance, allocated_days: int
    ) -> LeaveBalance:
        ctx = _require_company(request)
        if not _authz.can_change(ctx, balance):
            raise NotFound()
        if allocated_days < 0:
            raise ValidationError({"allocated_days": "allocated_days cannot be negative."})
        with transaction.atomic():
            row = (
                LeaveBalance.objects.select_for_update()
                .select_related("company", "employee", "leave_type")
                .get(pk=balance.pk)
            )
            if allocated_days < row.used_days:
                raise ValidationError(
                    {
                        "allocated_days": (
                            "allocated_days cannot be less than used days."
                        )
                    }
                )
            row.allocated_days = allocated_days
            row.save()
        emit(
            "leave.balance.changed",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_BALANCE,
            resource_id=row.id,
            metadata={"allocated_days": allocated_days},
        )
        return row

    def ensure_balances_for_year(self, *, company, year: int) -> int:
        created = 0
        employees = company.employees.all()
        types = LeaveType.objects.filter(
            company=company, status=LeaveTypeStatus.ACTIVE
        )
        for employee in employees:
            for leave_type in types:
                _, was_created = LeaveBalance.objects.get_or_create(
                    employee=employee,
                    leave_type=leave_type,
                    year=year,
                    defaults={
                        "company": company,
                        "allocated_days": leave_type.days_allowed,
                        "used_days": 0,
                        "remaining_days": leave_type.days_allowed,
                    },
                )
                if was_created:
                    created += 1
        return created

    def _restore_balance(self, ctx: TenantContext, row: LeaveRequest) -> int:
        year = row.start_date.year
        balance = (
            LeaveBalance.objects.select_for_update()
            .select_related("company", "employee", "leave_type")
            .filter(
                company=ctx.company,
                employee=row.employee,
                leave_type=row.leave_type,
                year=year,
            )
            .first()
        )
        if balance is None:
            return 0
        restore = min(row.total_days, balance.used_days)
        balance.used_days -= restore
        balance.save()
        emit(
            "leave.balance.changed",
            actor=ctx.user,
            company=ctx.company,
            resource=RESOURCE_BALANCE,
            resource_id=balance.id,
            metadata={"used_days": balance.used_days, "delta": -restore},
        )
        return restore

    def _validate_type_and_dates(
        self,
        ctx: TenantContext,
        employee,
        leave_type: LeaveType,
        start: date,
        end: date,
    ) -> None:
        if leave_type.company_id != ctx.company.id:
            raise ValidationError({"leave_type": "Unknown leave type."})
        if leave_type.status != LeaveTypeStatus.ACTIVE:
            raise ValidationError({"leave_type": "This leave type is inactive."})
        if employee.company_id != leave_type.company_id:
            raise ValidationError({"leave_type": "Unknown leave type."})
        if start > end:
            raise ValidationError(
                {"end_date": "end_date must be on or after start_date."}
            )
        if start.year != end.year:
            raise ValidationError(
                {
                    "end_date": (
                        "Leave requests cannot span multiple calendar years."
                    )
                }
            )
        today = self.calendar.company_today(ctx.company)
        if start < today:
            raise ValidationError(
                {"start_date": "Retrospective leave is not supported."}
            )

    def _assert_can_decide(self, ctx: TenantContext, row: LeaveRequest) -> None:
        self._assert_same_company(ctx, row)
        if not _authz.can_view(ctx, row):
            raise NotFound()
        if row.employee.user_id == ctx.user.id:
            return
        if ctx.role_code == "COMPANY_ADMIN" or ctx.is_super_admin:
            return
        if ctx.role_code == "MANAGER" and _authz._is_direct_report(ctx, row.employee):
            return
        raise NotFound()

    def _assert_can_cancel(self, ctx: TenantContext, row: LeaveRequest) -> None:
        self._assert_same_company(ctx, row)
        if not _authz.can_view(ctx, row):
            raise NotFound()
        if row.employee.user_id == ctx.user.id:
            return
        if ctx.role_code == "COMPANY_ADMIN" or ctx.is_super_admin:
            return
        if ctx.role_code == "MANAGER" and _authz._is_direct_report(ctx, row.employee):
            return
        raise NotFound()

    def _assert_same_company(self, ctx: TenantContext, row: LeaveRequest) -> None:
        if ctx.company is None or row.company_id != ctx.company.id:
            raise NotFound()


def _leave_snapshot(row: LeaveRequest, *, status: str | None = None) -> dict:
    employee = getattr(row, "employee", None)
    leave_type = getattr(row, "leave_type", None)
    return {
        "employee_id": str(row.employee_id),
        "employee_code": getattr(employee, "employee_code", None),
        "leave_type_id": str(row.leave_type_id),
        "leave_type": getattr(leave_type, "code", None),
        "start_date": row.start_date.isoformat(),
        "end_date": row.end_date.isoformat(),
        "total_days": row.total_days,
        "status": status or row.status,
        "approved_by": row.approved_by_id,
    }


def _require_company(request) -> TenantContext:
    from apps.common.tenancy import get_tenant_context

    ctx = get_tenant_context(request)
    if ctx.company is None:
        raise PermissionDenied("You do not have access to this company.")
    return ctx


def _actor_employee(ctx: TenantContext):
    employee = employee_for_user(user=ctx.user, company=ctx.company)
    if employee is None:
        raise ValidationError(
            {
                "non_field_errors": [
                    "No employee profile is linked to this account."
                ]
            }
        )
    return employee
