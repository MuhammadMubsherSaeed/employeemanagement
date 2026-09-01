from datetime import timedelta

from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from django.utils import timezone

from apps.accounts.models import UserRole
from apps.attendance.models import Attendance, AttendanceStatus
from apps.attendance.tests.fixtures import ON_TIME, freeze_now
from apps.companies.services import MembershipService
from apps.dashboard.tests import EMPLOYEE_DASH, DashboardFixtureMixin
from apps.leave.models import LeaveRequestStatus
from apps.leave.tests.fixtures import TODAY
from apps.notifications.models import Notification


class EmployeeDashboardTests(DashboardFixtureMixin, TestCase):
    def test_success_empty_state(self) -> None:
        client = self.authenticate(self.employee_a)
        with freeze_now(ON_TIME):
            response = client.get(EMPLOYEE_DASH)
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertIsNone(data["today_attendance"])
        self.assertEqual(data["working_minutes"], 0)
        self.assertEqual(len(data["leave_balances"]), 1)
        self.assertEqual(data["leave_balances"][0]["year"], 2026)
        self.assertEqual(data["leave_balances"][0]["allocated_days"], 10)
        self.assertEqual(data["recent_leave_requests"], [])
        self.assertEqual(data["assigned_devices"], [])
        self.assertEqual(data["notifications_count"], 0)

    def test_today_attendance_minutes_leave_devices_notifications(self) -> None:
        checkout = ON_TIME + timedelta(hours=8)
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date=TODAY,
            check_in=ON_TIME,
            check_out=checkout,
            total_minutes=480,
            status=AttendanceStatus.PRESENT,
        )
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a2,
            date=TODAY,
            check_in=ON_TIME,
            total_minutes=120,
            status=AttendanceStatus.PRESENT,
        )
        own = self.pending_request(employee=self.emp_a1)
        self.pending_request(
            employee=self.emp_a1,
            status=LeaveRequestStatus.REJECTED,
        )
        self.pending_request(employee=self.emp_a2)
        self.bind(self.device_a, self.emp_a1)
        other = self.make_device(
            self.company_a, "LAPTOP-OTH", serial_number="SN-OTH"
        )
        self.bind(other, self.emp_a2)
        self.bind(self.device_b, self.emp_b1)
        returned = self.make_device(
            self.company_a, "LAPTOP-OLD", serial_number="SN-OLD"
        )
        assignment = self.bind(returned, self.emp_a1)
        assignment.returned_at = timezone.now()
        assignment.save(update_fields=["returned_at", "updated_at"])
        self.make_notification(self.employee_a, title="One")
        read = self.make_notification(self.employee_a, title="Read")
        Notification.objects.filter(pk=read.pk).update(
            is_read=True, read_at=timezone.now()
        )
        self.make_notification(self.employee_a2, title="Peer")
        self.make_notification(self.employee_b, title="Beta")
        client = self.authenticate(self.employee_a)
        with freeze_now(ON_TIME):
            data = client.get(
                EMPLOYEE_DASH, {"employee_id": str(self.emp_a2.id)}
            ).json()["data"]
        attendance = data["today_attendance"]
        self.assertEqual(attendance["id"], str(self.emp_a1.attendances.get().id))
        self.assertEqual(attendance["status"], AttendanceStatus.PRESENT)
        self.assertEqual(data["working_minutes"], 480)
        self.assertNotIn("check_in_ip", attendance)
        self.assertEqual(len(data["recent_leave_requests"]), 2)
        request_ids = {row["id"] for row in data["recent_leave_requests"]}
        self.assertIn(str(own.id), request_ids)
        self.assertEqual(len(data["assigned_devices"]), 1)
        self.assertEqual(
            data["assigned_devices"][0]["id"], str(self.device_a.id)
        )
        self.assertNotIn("cost", data["assigned_devices"][0])
        self.assertEqual(data["notifications_count"], 1)

    def test_open_shift_uses_stored_total_minutes(self) -> None:
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date=TODAY,
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        client = self.authenticate(self.employee_a)
        with freeze_now(ON_TIME + timedelta(hours=3)):
            data = client.get(EMPLOYEE_DASH).json()["data"]
        self.assertIsNotNone(data["today_attendance"])
        self.assertEqual(data["working_minutes"], 0)
        self.assertIsNone(data["today_attendance"]["total_minutes"])

    def test_cannot_see_other_employee_or_company(self) -> None:
        self.pending_request(employee=self.emp_b1, leave_type=self.type_b)
        self.bind(self.device_b, self.emp_b1)
        self.make_notification(self.employee_b, title="Beta")
        client = self.authenticate(self.employee_a)
        with freeze_now(ON_TIME):
            data = client.get(
                EMPLOYEE_DASH,
                {"employee_id": str(self.emp_b1.id)},
            ).json()["data"]
        self.assertEqual(data["recent_leave_requests"], [])
        self.assertEqual(data["assigned_devices"], [])
        self.assertEqual(data["notifications_count"], 0)
        self.assertEqual(data["leave_balances"][0]["allocated_days"], 10)

    def test_missing_profile_is_404(self) -> None:
        user = self._member("no-profile@example.com", UserRole.EMPLOYEE)
        MembershipService().assign(
            user=user,
            company=self.company_a,
            role=self.roles[UserRole.EMPLOYEE],
        )
        client = self.authenticate(user)
        with freeze_now(ON_TIME):
            response = client.get(EMPLOYEE_DASH)
        self.assertEqual(response.status_code, 404)
        self.assertFalse(response.json()["success"])

    def test_employee_without_balance_device_or_notification(self) -> None:
        client = self.authenticate(self.manager_b)
        with freeze_now(ON_TIME):
            data = client.get(EMPLOYEE_DASH).json()["data"]
        self.assertEqual(data["leave_balances"], [])
        self.assertEqual(data["assigned_devices"], [])
        self.assertEqual(data["notifications_count"], 0)
        self.assertIsNone(data["today_attendance"])

    def test_query_count_is_bounded(self) -> None:
        self.bind(self.device_a, self.emp_a1)
        self.pending_request(employee=self.emp_a1)
        self.make_notification(self.employee_a)
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date=TODAY,
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        client = self.authenticate(self.employee_a)
        with freeze_now(ON_TIME):
            with CaptureQueriesContext(connection) as captured:
                response = client.get(EMPLOYEE_DASH)
        self.assertEqual(response.status_code, 200)
        self.assertLessEqual(len(captured.captured_queries), 30)
