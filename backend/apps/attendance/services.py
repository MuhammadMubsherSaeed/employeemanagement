from __future__ import annotations

from datetime import date, datetime, timedelta
from decimal import Decimal

from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from apps.attendance.models import Attendance, AttendanceStatus
from apps.attendance.selectors import (
    attendance_for_employee_date,
    attendance_queryset,
    holiday_on,
)
from apps.companies.models import CompanySettings
from apps.companies.services import get_company_settings
from apps.employees.models import Employee
from apps.employees.selectors import employee_for_user

MAX_DATE_RANGE_DAYS = 366


def client_ip(request) -> str | None:
    """Trusted peer address only. Do not read X-Forwarded-For here."""

    addr = request.META.get("REMOTE_ADDR")
    return addr or None


def leave_covers_date(*, employee: Employee, on_date: date) -> bool:
    """Future Leave module hook.

    Must return True only when an approved leave covers ``on_date``.
    Leave is not implemented; never fabricate LEAVE status.
    """

    return False


class CompanyClock:
    """Company-local calendar date and instants from timezone-aware UTC now."""

    def __init__(self, settings: CompanySettings) -> None:
        self.settings = settings
        self.tz = settings.zoneinfo()

    def now(self) -> datetime:
        current = timezone.now()
        if timezone.is_naive(current):
            current = timezone.make_aware(current, timezone.utc)
        return current

    def local_now(self) -> datetime:
        return self.now().astimezone(self.tz)

    def local_date(self, instant: datetime | None = None) -> date:
        moment = instant if instant is not None else self.now()
        if timezone.is_naive(moment):
            moment = timezone.make_aware(moment, timezone.utc)
        return moment.astimezone(self.tz).date()


class AttendanceStatusService:
    """Single place for attendance status. Do not reimplement in views."""

    def calculate(
        self,
        *,
        local_date: date,
        settings: CompanySettings,
        is_holiday: bool,
        is_leave: bool,
        check_in: datetime | None,
        check_out: datetime | None,
        total_minutes: int | None,
    ) -> str:
        """Precedence: WEEKEND, HOLIDAY, LEAVE, ABSENT, HALF_DAY, LATE, PRESENT."""

        if not settings.is_working_weekday(local_date.weekday()):
            return AttendanceStatus.WEEKEND
        if is_holiday:
            return AttendanceStatus.HOLIDAY
        if is_leave:
            return AttendanceStatus.LEAVE
        if check_in is None:
            return AttendanceStatus.ABSENT
        if (
            check_out is not None
            and total_minutes is not None
            and total_minutes < settings.minimum_working_minutes
        ):
            return AttendanceStatus.HALF_DAY
        if self._is_late(settings, local_date, check_in):
            return AttendanceStatus.LATE
        return AttendanceStatus.PRESENT

    def _is_late(
        self,
        settings: CompanySettings,
        local_date: date,
        check_in: datetime,
    ) -> bool:
        tz = settings.zoneinfo()
        start = datetime.combine(local_date, settings.work_start_time, tzinfo=tz)
        allowed = start + timedelta(minutes=settings.grace_period_minutes)
        local_check_in = check_in.astimezone(tz)
        return local_check_in > allowed


class AttendanceService:
    def __init__(self) -> None:
        self.status_service = AttendanceStatusService()

    def check_in(
        self,
        *,
        request,
        latitude: Decimal | None = None,
        longitude: Decimal | None = None,
    ) -> Attendance:
        company, employee, settings, clock = self._require_employee_context(request)
        instant = clock.now()
        local_date = clock.local_date(instant)
        holiday = holiday_on(company=company, on_date=local_date)
        status = self.status_service.calculate(
            local_date=local_date,
            settings=settings,
            is_holiday=holiday is not None,
            is_leave=leave_covers_date(employee=employee, on_date=local_date),
            check_in=instant,
            check_out=None,
            total_minutes=None,
        )
        try:
            with transaction.atomic():
                existing = (
                    Attendance.objects.select_for_update()
                    .filter(company=company, employee=employee, date=local_date)
                    .first()
                )
                if existing is not None and existing.check_in is not None:
                    raise ValidationError(
                        {"non_field_errors": ["Already checked in for this date."]}
                    )
                if existing is not None:
                    existing.check_in = instant
                    existing.check_in_ip = client_ip(request)
                    existing.check_in_latitude = latitude
                    existing.check_in_longitude = longitude
                    existing.status = status
                    existing.save()
                    return existing
                return Attendance.objects.create(
                    company=company,
                    employee=employee,
                    date=local_date,
                    check_in=instant,
                    status=status,
                    check_in_ip=client_ip(request),
                    check_in_latitude=latitude,
                    check_in_longitude=longitude,
                )
        except IntegrityError as exc:
            raise ValidationError(
                {"non_field_errors": ["Already checked in for this date."]}
            ) from exc

    def check_out(
        self,
        *,
        request,
        latitude: Decimal | None = None,
        longitude: Decimal | None = None,
    ) -> Attendance:
        company, employee, settings, clock = self._require_employee_context(request)
        instant = clock.now()
        local_date = clock.local_date(instant)
        with transaction.atomic():
            attendance = (
                Attendance.objects.select_for_update()
                .select_related("employee", "company")
                .filter(company=company, employee=employee, date=local_date)
                .first()
            )
            if attendance is None or attendance.check_in is None:
                raise ValidationError(
                    {"non_field_errors": ["Check-in is required before check-out."]}
                )
            if attendance.check_out is not None:
                raise ValidationError(
                    {"non_field_errors": ["Already checked out for this date."]}
                )
            if instant < attendance.check_in:
                raise ValidationError(
                    {"check_out": "Check-out cannot be before check-in."}
                )
            total_minutes = working_minutes(attendance.check_in, instant)
            holiday = holiday_on(company=company, on_date=attendance.date)
            attendance.check_out = instant
            attendance.check_out_ip = client_ip(request)
            attendance.check_out_latitude = latitude
            attendance.check_out_longitude = longitude
            attendance.total_minutes = total_minutes
            attendance.status = self.status_service.calculate(
                local_date=attendance.date,
                settings=settings,
                is_holiday=holiday is not None,
                is_leave=leave_covers_date(
                    employee=employee, on_date=attendance.date
                ),
                check_in=attendance.check_in,
                check_out=instant,
                total_minutes=total_minutes,
            )
            attendance.save()
            return attendance

    def is_absent_on(
        self,
        *,
        employee: Employee,
        on_date: date,
        settings: CompanySettings | None = None,
    ) -> bool:
        """Whether this date would be ABSENT. Does not create a row."""

        company = employee.company
        settings = settings or get_company_settings(company)
        holiday = holiday_on(company=company, on_date=on_date)
        row = attendance_for_employee_date(
            company=company, employee=employee, on_date=on_date
        )
        check_in = row.check_in if row is not None else None
        status = self.status_service.calculate(
            local_date=on_date,
            settings=settings,
            is_holiday=holiday is not None,
            is_leave=leave_covers_date(employee=employee, on_date=on_date),
            check_in=check_in,
            check_out=row.check_out if row is not None else None,
            total_minutes=row.total_minutes if row is not None else None,
        )
        return status == AttendanceStatus.ABSENT

    def summarize(
        self,
        *,
        company,
        employees: list[Employee],
        start: date,
        end: date,
        settings: CompanySettings,
    ) -> dict:
        rows = list(
            attendance_queryset().filter(
                company=company,
                employee_id__in=[employee.id for employee in employees],
                date__gte=start,
                date__lte=end,
            )
        )
        counts = {status: 0 for status in AttendanceStatus.values}
        total_working_minutes = 0
        for row in rows:
            counts[row.status] = counts.get(row.status, 0) + 1
            if row.total_minutes:
                total_working_minutes += row.total_minutes

        absent_days = 0
        cursor = start
        while cursor <= end:
            for employee in employees:
                if self.is_absent_on(
                    employee=employee, on_date=cursor, settings=settings
                ):
                    absent_days += 1
            cursor += timedelta(days=1)

        payload = {
            "start_date": start,
            "end_date": end,
            "employee_id": (
                str(employees[0].id) if len(employees) == 1 else None
            ),
            "total_days": (end - start).days + 1,
            "present_days": counts[AttendanceStatus.PRESENT],
            "absent_days": absent_days,
            "late_days": counts[AttendanceStatus.LATE],
            "half_days": counts[AttendanceStatus.HALF_DAY],
            "leave_days": counts[AttendanceStatus.LEAVE],
            "holiday_days": counts[AttendanceStatus.HOLIDAY],
            "weekend_days": counts[AttendanceStatus.WEEKEND],
            "total_working_minutes": total_working_minutes,
        }
        if settings.overtime_enabled:
            payload["overtime_minutes"] = 0
        else:
            payload["overtime_minutes"] = 0
        return payload

    def _require_employee_context(self, request):
        from apps.common.tenancy import get_tenant_context

        ctx = get_tenant_context(request)
        if ctx.company is None:
            raise PermissionDenied("You do not have access to this company.")
        employee = employee_for_user(user=request.user, company=ctx.company)
        if employee is None:
            raise ValidationError(
                {
                    "non_field_errors": [
                        "No employee profile is linked to this account."
                    ]
                }
            )
        settings = get_company_settings(ctx.company)
        return ctx.company, employee, settings, CompanyClock(settings)


def working_minutes(check_in: datetime, check_out: datetime) -> int:
    delta = check_out - check_in
    return max(0, int(delta.total_seconds() // 60))


def validate_date_range(start: date, end: date) -> None:
    if start > end:
        raise ValidationError(
            {"end_date": "end_date must be on or after start_date."}
        )
    if (end - start).days + 1 > MAX_DATE_RANGE_DAYS:
        raise ValidationError(
            {
                "end_date": (
                    f"Date range cannot exceed {MAX_DATE_RANGE_DAYS} days."
                )
            }
        )


def resolve_summary_employees(*, ctx, employee_id, queryset) -> list[Employee]:
    from apps.common.authorization import ObjectAuthorization

    authz = ObjectAuthorization()
    if employee_id:
        try:
            employee = Employee.objects.select_related("company").get(pk=employee_id)
        except (Employee.DoesNotExist, ValueError):
            raise NotFound()
        if not authz.can_view(ctx, employee):
            raise NotFound()
        return [employee]
    if ctx.role_code == "EMPLOYEE":
        own = employee_for_user(user=ctx.user, company=ctx.company)
        if own is None:
            raise NotFound()
        return [own]
    return list(queryset)
