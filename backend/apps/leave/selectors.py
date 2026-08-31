from datetime import date

from apps.leave.models import LeaveBalance, LeaveRequest, LeaveRequestStatus, LeaveType


def leave_type_queryset():
    return LeaveType.objects.select_related("company")


def leave_balance_queryset():
    return LeaveBalance.objects.select_related(
        "company",
        "employee",
        "employee__user",
        "employee__manager",
        "leave_type",
    )


def leave_request_queryset():
    return LeaveRequest.objects.select_related(
        "company",
        "employee",
        "employee__user",
        "employee__manager",
        "leave_type",
        "approved_by",
    )


def approved_leave_covers_date(*, employee, on_date: date) -> bool:
    if employee is None or on_date is None:
        return False
    return LeaveRequest.objects.filter(
        company_id=employee.company_id,
        employee=employee,
        status=LeaveRequestStatus.APPROVED,
        start_date__lte=on_date,
        end_date__gte=on_date,
    ).exists()


def overlapping_requests(*, company, employee, start: date, end: date, exclude_id=None):
    queryset = LeaveRequest.objects.filter(
        company=company,
        employee=employee,
        status__in=(LeaveRequestStatus.PENDING, LeaveRequestStatus.APPROVED),
        start_date__lte=end,
        end_date__gte=start,
    )
    if exclude_id is not None:
        queryset = queryset.exclude(pk=exclude_id)
    return queryset


def balance_for(*, employee, leave_type, year: int) -> LeaveBalance | None:
    return (
        leave_balance_queryset()
        .filter(employee=employee, leave_type=leave_type, year=year)
        .first()
    )
