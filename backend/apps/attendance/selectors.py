from datetime import date

from apps.attendance.models import Attendance, Holiday
from apps.employees.models import Employee


def attendance_queryset():
    return Attendance.objects.select_related(
        "company",
        "employee",
        "employee__user",
        "employee__department",
        "employee__manager",
    )


def holiday_queryset():
    return Holiday.objects.select_related("company")


def holiday_on(*, company, on_date: date) -> Holiday | None:
    return (
        Holiday.objects.filter(
            company=company,
            date=on_date,
            is_active=True,
        )
        .first()
    )


def attendance_for_employee_date(*, company, employee: Employee, on_date: date):
    return (
        attendance_queryset()
        .filter(company=company, employee=employee, date=on_date)
        .first()
    )
