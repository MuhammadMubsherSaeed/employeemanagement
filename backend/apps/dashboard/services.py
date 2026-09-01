from __future__ import annotations

from datetime import date

from django.db.models import Count, Q
from rest_framework.exceptions import NotFound, PermissionDenied

from apps.attendance.models import Attendance, AttendanceStatus
from apps.attendance.selectors import attendance_for_employee_date, holiday_on
from apps.attendance.services import AttendanceStatusService, CompanyClock
from apps.common.authorization import ObjectAuthorization
from apps.common.models import AuditEvent
from apps.common.tenancy import TenantContext, get_tenant_context
from apps.companies.services import get_company_settings
from apps.dashboard.serializers import (
    DashboardActivitySerializer,
    DashboardLeaveBalanceSerializer,
    DashboardLeaveRequestSerializer,
    DashboardRecentEmployeeSerializer,
    DashboardTodayAttendanceSerializer,
)
from apps.devices.models import DeviceAssignment
from apps.devices.serializers import DeviceListSerializer
from apps.employees.models import Employee, EmployeeStatus
from apps.employees.selectors import employee_for_user
from apps.leave.models import LeaveRequest, LeaveRequestStatus
from apps.leave.selectors import leave_balance_queryset, leave_request_queryset
from apps.notifications.services import NotificationService

RECENT_EMPLOYEES_LIMIT = 5
RECENT_ACTIVITY_LIMIT = 10
RECENT_LEAVE_REQUESTS_LIMIT = 5

_WORKFORCE_STATUSES = (EmployeeStatus.ACTIVE, EmployeeStatus.ON_LEAVE)
_authz = ObjectAuthorization()
_status_service = AttendanceStatusService()


class DashboardService:
    """Company-scoped dashboard aggregations. Tenant comes from the request."""

    def admin_dashboard(self, *, request) -> dict:
        ctx, settings, today = self._company_clock(request)
        employees = self._authorized_employees(ctx)
        present, absent, late, on_leave = self._today_attendance_counts(
            company=ctx.company,
            settings=settings,
            today=today,
            employee_ids=self._workforce_ids(employees),
        )
        counts = employees.aggregate(
            total_employees=Count("id"),
            active_employees=Count(
                "id", filter=Q(status=EmployeeStatus.ACTIVE)
            ),
            inactive_employees=Count(
                "id", filter=Q(status=EmployeeStatus.INACTIVE)
            ),
        )
        recent = list(
            employees.select_related("department", "position").order_by(
                "-created_at"
            )[:RECENT_EMPLOYEES_LIMIT]
        )
        return {
            "total_employees": counts["total_employees"],
            "active_employees": counts["active_employees"],
            "inactive_employees": counts["inactive_employees"],
            "present_today": present,
            "absent_today": absent,
            "late_today": late,
            "on_leave_today": on_leave,
            "pending_leave_requests": self._pending_leave_count(ctx),
            "recent_employees": DashboardRecentEmployeeSerializer(
                recent, many=True
            ).data,
            "recent_activity": self._recent_activity(ctx, employees),
        }

    def manager_dashboard(self, *, request) -> dict:
        ctx, settings, today = self._company_clock(request)
        employees = self._authorized_employees(ctx)
        present, absent, late, on_leave = self._today_attendance_counts(
            company=ctx.company,
            settings=settings,
            today=today,
            employee_ids=self._workforce_ids(employees),
        )
        return {
            "team_size": employees.count(),
            "team_present": present,
            "team_absent": absent,
            "team_late": late,
            "team_on_leave": on_leave,
            "pending_leave_requests": self._pending_leave_count(ctx),
            "recent_activity": self._recent_activity(ctx, employees),
        }

    def employee_dashboard(self, *, request) -> dict:
        ctx, _settings, today = self._company_clock(request)
        employee = employee_for_user(user=ctx.user, company=ctx.company)
        if employee is None:
            raise NotFound("No employee profile is linked to this account.")
        attendance = attendance_for_employee_date(
            company=ctx.company, employee=employee, on_date=today
        )
        today_payload = None
        working_minutes = 0
        if attendance is not None:
            today_payload = DashboardTodayAttendanceSerializer(
                {
                    "id": attendance.id,
                    "date": attendance.date,
                    "check_in": attendance.check_in,
                    "check_out": attendance.check_out,
                    "total_minutes": attendance.total_minutes,
                    "status": attendance.status,
                }
            ).data
            working_minutes = attendance.total_minutes or 0
        year = today.year
        balances = list(
            leave_balance_queryset().filter(employee=employee, year=year)
        )
        requests = list(
            leave_request_queryset()
            .filter(employee=employee)
            .order_by("-created_at")[:RECENT_LEAVE_REQUESTS_LIMIT]
        )
        devices = [
            assignment.device
            for assignment in DeviceAssignment.objects.filter(
                company=ctx.company,
                employee=employee,
                returned_at__isnull=True,
            )
            .select_related("device")
            .order_by("-assigned_at")
        ]
        return {
            "today_attendance": today_payload,
            "working_minutes": working_minutes,
            "leave_balances": DashboardLeaveBalanceSerializer(
                balances, many=True
            ).data,
            "recent_leave_requests": DashboardLeaveRequestSerializer(
                requests, many=True
            ).data,
            "assigned_devices": DeviceListSerializer(
                devices, many=True, context={"show_sensitive": False}
            ).data,
            "notifications_count": NotificationService().unread_count(
                request=request
            ),
        }

    def _company_clock(self, request):
        ctx = _require_company(request)
        settings = get_company_settings(ctx.company)
        today = CompanyClock(settings).local_date()
        return ctx, settings, today

    def _authorized_employees(self, ctx: TenantContext):
        return _authz.filter_queryset(
            Employee.objects.filter(company_id=ctx.company.id),
            ctx,
        )

    def _workforce_ids(self, employees) -> list:
        return list(
            employees.filter(status__in=_WORKFORCE_STATUSES).values_list(
                "id", flat=True
            )
        )

    def _pending_leave_count(self, ctx: TenantContext) -> int:
        return _authz.filter_queryset(
            leave_request_queryset().filter(
                company_id=ctx.company.id,
                status=LeaveRequestStatus.PENDING,
            ),
            ctx,
        ).count()

    def _recent_activity(self, ctx: TenantContext, employees) -> list:
        events = AuditEvent.objects.filter(company_id=ctx.company.id)
        if not ctx.has_permission("audit_logs.view"):
            actor_ids = list(
                employees.exclude(user_id=None).values_list("user_id", flat=True)
            )
            if not actor_ids:
                return []
            events = events.filter(actor_id__in=actor_ids)
        rows = list(
            events.select_related("actor").order_by("-created_at")[
                :RECENT_ACTIVITY_LIMIT
            ]
        )
        return DashboardActivitySerializer(rows, many=True).data

    def _today_attendance_counts(
        self,
        *,
        company,
        settings,
        today: date,
        employee_ids: list,
    ) -> tuple[int, int, int, int]:
        """Apply AttendanceStatusService rules without per-employee queries."""

        if not employee_ids:
            return 0, 0, 0, 0
        is_holiday = holiday_on(company=company, on_date=today) is not None
        on_leave_ids = set(
            LeaveRequest.objects.filter(
                company=company,
                employee_id__in=employee_ids,
                status=LeaveRequestStatus.APPROVED,
                start_date__lte=today,
                end_date__gte=today,
            ).values_list("employee_id", flat=True)
        )
        rows = {
            row.employee_id: row
            for row in Attendance.objects.filter(
                company=company,
                employee_id__in=employee_ids,
                date=today,
            ).only(
                "employee_id",
                "check_in",
                "check_out",
                "total_minutes",
                "status",
            )
        }
        present = absent = late = on_leave = 0
        for employee_id in employee_ids:
            row = rows.get(employee_id)
            status = _status_service.calculate(
                local_date=today,
                settings=settings,
                is_holiday=is_holiday,
                is_leave=employee_id in on_leave_ids,
                check_in=row.check_in if row is not None else None,
                check_out=row.check_out if row is not None else None,
                total_minutes=row.total_minutes if row is not None else None,
            )
            if status in (AttendanceStatus.PRESENT, AttendanceStatus.HALF_DAY):
                present += 1
            elif status == AttendanceStatus.LATE:
                late += 1
            elif status == AttendanceStatus.LEAVE:
                on_leave += 1
            elif status == AttendanceStatus.ABSENT:
                absent += 1
        return present, absent, late, on_leave


def _require_company(request) -> TenantContext:
    ctx = get_tenant_context(request)
    if ctx.company is None:
        raise PermissionDenied("You do not have access to this company.")
    return ctx
