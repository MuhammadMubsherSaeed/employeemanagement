from datetime import date
from unittest.mock import patch

from apps.attendance.tests.fixtures import AttendanceFixtureMixin
from apps.leave.models import (
    LeaveBalance,
    LeaveRequest,
    LeaveRequestStatus,
    LeaveType,
    LeaveTypeStatus,
)

TYPES = "/api/v1/leave/types"
BALANCES = "/api/v1/leave/balances"
REQUESTS = "/api/v1/leave/requests"

# Monday 16 Mar 2026 — same calendar as attendance fixtures.
TODAY = date(2026, 3, 16)


def freeze_leave_today(value: date = TODAY):
    return patch(
        "apps.leave.calendar.LeaveCalendarService.company_today",
        return_value=value,
    )


class LeaveFixtureMixin(AttendanceFixtureMixin):
    @classmethod
    def setUpTestData(cls) -> None:
        super().setUpTestData()
        cls.type_a = LeaveType.objects.create(
            company=cls.company_a,
            name="Annual Leave",
            code="ANNUAL",
            days_allowed=10,
            is_paid=True,
            carry_forward=True,
        )
        cls.type_a_sick = LeaveType.objects.create(
            company=cls.company_a,
            name="Sick Leave",
            code="SICK",
            days_allowed=5,
            is_paid=True,
            carry_forward=False,
            status=LeaveTypeStatus.INACTIVE,
        )
        cls.type_b = LeaveType.objects.create(
            company=cls.company_b,
            name="Annual Leave",
            code="ANNUAL",
            days_allowed=12,
            is_paid=True,
        )
        cls.balance_a1 = cls._balance(cls.emp_a1, cls.type_a, 10)
        cls.balance_a2 = cls._balance(cls.emp_a2, cls.type_a, 10)
        cls.balance_manager = cls._balance(cls.emp_manager_a, cls.type_a, 10)
        cls.balance_admin = cls._balance(cls.emp_admin_a, cls.type_a, 10)
        cls.balance_b1 = cls._balance(cls.emp_b1, cls.type_b, 12)

    @classmethod
    def _balance(cls, employee, leave_type, allocated: int, year: int = 2026):
        return LeaveBalance.objects.create(
            company=employee.company,
            employee=employee,
            leave_type=leave_type,
            year=year,
            allocated_days=allocated,
            used_days=0,
        )

    def pending_request(
        self,
        *,
        employee=None,
        leave_type=None,
        start=None,
        end=None,
        total_days=1,
        status=LeaveRequestStatus.PENDING,
        company=None,
    ) -> LeaveRequest:
        employee = employee or self.emp_a1
        leave_type = leave_type or self.type_a
        start = start or TODAY
        end = end or start
        return LeaveRequest.objects.create(
            company=company or employee.company,
            employee=employee,
            leave_type=leave_type,
            start_date=start,
            end_date=end,
            total_days=total_days,
            reason="Need time off",
            status=status,
        )

    def post_request(self, client, payload=None, today=TODAY, **extra):
        body = {
            "leave_type": str(self.type_a.id),
            "start_date": TODAY.isoformat(),
            "end_date": TODAY.isoformat(),
            "reason": "Need time off",
        }
        if payload:
            body.update(payload)
        with freeze_leave_today(today):
            return client.post(f"{REQUESTS}/", body, format="json", **extra)
