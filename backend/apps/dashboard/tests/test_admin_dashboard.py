from datetime import date, datetime
from datetime import timezone as dt_timezone

from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext

from apps.attendance.models import Attendance, AttendanceStatus, Holiday
from apps.attendance.tests.fixtures import LATE, ON_TIME, WEEKEND, freeze_now
from apps.common.events import emit
from apps.dashboard.tests import ADMIN, DashboardFixtureMixin
from apps.employees.models import Employee, EmployeeStatus, EmploymentType
from apps.leave.models import LeaveRequestStatus
from apps.leave.tests.fixtures import TODAY

TZ_SPLIT = datetime(2026, 3, 18, 19, 30, tzinfo=dt_timezone.utc)


class AdminDashboardTests(DashboardFixtureMixin, TestCase):
    def test_success_counts_and_empty_lists(self) -> None:
        client = self.authenticate(self.admin_a)
        with freeze_now(ON_TIME):
            response = client.get(ADMIN)
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["message"], "Dashboard data retrieved successfully.")
        data = body["data"]
        self.assertEqual(data["total_employees"], 4)
        self.assertEqual(data["active_employees"], 4)
        self.assertEqual(data["inactive_employees"], 0)
        self.assertEqual(data["present_today"], 0)
        self.assertEqual(data["absent_today"], 4)
        self.assertEqual(data["late_today"], 0)
        self.assertEqual(data["on_leave_today"], 0)
        self.assertEqual(data["pending_leave_requests"], 0)
        self.assertEqual(len(data["recent_employees"]), 4)
        self.assertEqual(data["recent_activity"], [])
        recent = data["recent_employees"][0]
        self.assertIn("employee_code", recent)
        self.assertIn("profile_image", recent)
        self.assertNotIn("phone", recent)
        self.assertNotIn("address", recent)

    def test_active_inactive_and_attendance_breakdown(self) -> None:
        Employee.objects.create(
            company=self.company_a,
            employee_code="EMP-INACT",
            first_name="Idle",
            last_name="Acme",
            department=self.dept_a,
            position=self.pos_a,
            employment_type=EmploymentType.FULL_TIME,
            status=EmployeeStatus.INACTIVE,
        )
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date=TODAY,
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a2,
            date=TODAY,
            check_in=LATE,
            status=AttendanceStatus.LATE,
        )
        self.pending_request(
            employee=self.emp_manager_a,
            status=LeaveRequestStatus.APPROVED,
        )
        self.pending_request(employee=self.emp_a1)
        client = self.authenticate(self.admin_a)
        with freeze_now(ON_TIME):
            data = client.get(ADMIN).json()["data"]
        self.assertEqual(data["total_employees"], 5)
        self.assertEqual(data["active_employees"], 4)
        self.assertEqual(data["inactive_employees"], 1)
        self.assertEqual(data["present_today"], 1)
        self.assertEqual(data["late_today"], 1)
        self.assertEqual(data["on_leave_today"], 1)
        self.assertEqual(data["absent_today"], 1)
        self.assertEqual(data["pending_leave_requests"], 1)

    def test_recent_employees_are_limited(self) -> None:
        for index in range(8):
            Employee.objects.create(
                company=self.company_a,
                employee_code=f"EMP-R{index:02d}",
                first_name="New",
                last_name=str(index),
                department=self.dept_a,
                position=self.pos_a,
            )
        client = self.authenticate(self.admin_a)
        with freeze_now(ON_TIME):
            data = client.get(ADMIN).json()["data"]
        self.assertEqual(len(data["recent_employees"]), 5)
        self.assertEqual(data["total_employees"], 12)

    def test_recent_activity_is_company_scoped_and_limited(self) -> None:
        for index in range(12):
            emit(
                f"employee.updated.{index}",
                actor=self.admin_a,
                company=self.company_a,
                resource="employees.Employee",
                resource_id=str(self.emp_a1.id),
            )
        emit(
            "employee.updated.other",
            actor=self.admin_b,
            company=self.company_b,
            resource="employees.Employee",
            resource_id=str(self.emp_b1.id),
        )
        client = self.authenticate(self.admin_a)
        with freeze_now(ON_TIME):
            data = client.get(ADMIN).json()["data"]
        activity = data["recent_activity"]
        self.assertEqual(len(activity), 10)
        actions = {row["action"] for row in activity}
        self.assertNotIn("employee.updated.other", actions)
        self.assertNotIn("metadata", activity[0])

    def test_company_isolation_ignores_client_company_id(self) -> None:
        Attendance.objects.create(
            company=self.company_b,
            employee=self.emp_b1,
            date=TODAY,
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        self.pending_request(employee=self.emp_b1, leave_type=self.type_b)
        self.make_notification(self.admin_b, title="Beta")
        client = self.authenticate(self.admin_a)
        with freeze_now(ON_TIME):
            data = client.get(
                ADMIN, {"company_id": str(self.company_b.id)}
            ).json()["data"]
        self.assertEqual(data["total_employees"], 4)
        self.assertEqual(data["present_today"], 0)
        self.assertEqual(data["pending_leave_requests"], 0)
        codes = {row["employee_code"] for row in data["recent_employees"]}
        names = {
            f"{row['first_name']} {row['last_name']}"
            for row in data["recent_employees"]
        }
        self.assertIn("EMP-001", codes)
        self.assertNotIn("Bea Beta", names)

    def test_timezone_split_uses_company_local_today(self) -> None:
        karachi_date = date(2026, 3, 19)
        utc_date = date(2026, 3, 18)
        karachi_check_in = datetime(2026, 3, 19, 4, 10, tzinfo=dt_timezone.utc)
        utc_check_in = datetime(2026, 3, 18, 9, 10, tzinfo=dt_timezone.utc)
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date=karachi_date,
            check_in=karachi_check_in,
            status=AttendanceStatus.PRESENT,
        )
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_admin_a,
            date=utc_date,
            check_in=utc_check_in,
            status=AttendanceStatus.PRESENT,
        )
        Attendance.objects.create(
            company=self.company_b,
            employee=self.emp_b1,
            date=utc_date,
            check_in=utc_check_in,
            status=AttendanceStatus.PRESENT,
        )
        admin_a = self.authenticate(self.admin_a)
        admin_b = self.authenticate(self.admin_b)
        with freeze_now(TZ_SPLIT):
            data_a = admin_a.get(ADMIN).json()["data"]
            data_b = admin_b.get(ADMIN).json()["data"]
        self.assertEqual(data_a["present_today"], 1)
        self.assertEqual(data_a["absent_today"], 3)
        self.assertEqual(data_b["present_today"], 1)
        self.assertEqual(data_b["absent_today"], 2)

    def test_weekend_and_holiday_are_not_counted_absent(self) -> None:
        client = self.authenticate(self.admin_a)
        with freeze_now(WEEKEND):
            weekend = client.get(ADMIN).json()["data"]
        self.assertEqual(weekend["present_today"], 0)
        self.assertEqual(weekend["absent_today"], 0)
        self.assertEqual(weekend["late_today"], 0)
        Holiday.objects.create(
            company=self.company_a,
            name="Foundation Day",
            date=TODAY,
        )
        with freeze_now(ON_TIME):
            holiday = client.get(ADMIN).json()["data"]
        self.assertEqual(holiday["absent_today"], 0)
        self.assertEqual(holiday["present_today"], 0)

    def test_query_count_does_not_grow_with_headcount(self) -> None:
        for index in range(15):
            Employee.objects.create(
                company=self.company_a,
                employee_code=f"EMP-Q{index:02d}",
                first_name="Query",
                last_name=str(index),
                department=self.dept_a,
                position=self.pos_a,
            )
        client = self.authenticate(self.admin_a)
        with freeze_now(ON_TIME):
            with CaptureQueriesContext(connection) as captured:
                response = client.get(ADMIN)
        self.assertEqual(response.status_code, 200)
        self.assertLessEqual(len(captured.captured_queries), 40)
        self.assertEqual(response.json()["data"]["total_employees"], 19)
