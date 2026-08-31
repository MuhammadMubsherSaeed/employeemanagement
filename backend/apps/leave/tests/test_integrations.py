from datetime import date

from django.test import TestCase

from apps.attendance.models import Attendance, AttendanceStatus
from apps.attendance.services import AttendanceService, leave_covers_date
from apps.attendance.tests.fixtures import ON_TIME, check_in
from apps.common.events import clear_events, recorded_events
from apps.common.models import AuditEvent
from apps.leave.models import LeaveRequestStatus
from apps.leave.tests.fixtures import REQUESTS, TODAY, LeaveFixtureMixin


class AttendanceIntegrationTests(LeaveFixtureMixin, TestCase):
    def test_approved_leave_is_not_absent_and_does_not_create_rows(self) -> None:
        row = self.pending_request(start=TODAY, end=TODAY, total_days=1)
        before = Attendance.objects.count()
        client = self.authenticate(self.manager_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{row.id}/approve/", {}, format="json").status_code,
            200,
        )
        self.assertEqual(Attendance.objects.count(), before)
        self.assertTrue(leave_covers_date(employee=self.emp_a1, on_date=TODAY))
        self.assertFalse(
            AttendanceService().is_absent_on(employee=self.emp_a1, on_date=TODAY)
        )

    def test_check_in_on_approved_leave_is_leave_not_absent(self) -> None:
        row = self.pending_request(start=TODAY, end=TODAY, total_days=1)
        self.authenticate(self.manager_a).post(
            f"{REQUESTS}/{row.id}/approve/", {}, format="json"
        )
        employee = self.authenticate(self.employee_a)
        data = check_in(employee, ON_TIME).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.LEAVE)
        self.assertEqual(
            Attendance.objects.filter(employee=self.emp_a1, date=TODAY).count(),
            1,
        )

    def test_cancelled_approved_leave_no_longer_covers_date(self) -> None:
        row = self.pending_request(start=TODAY, end=TODAY, total_days=1)
        manager = self.authenticate(self.manager_a)
        manager.post(f"{REQUESTS}/{row.id}/approve/", {}, format="json")
        self.authenticate(self.employee_a).post(
            f"{REQUESTS}/{row.id}/cancel/", {}, format="json"
        )
        self.assertFalse(leave_covers_date(employee=self.emp_a1, on_date=TODAY))
        self.assertTrue(
            AttendanceService().is_absent_on(employee=self.emp_a1, on_date=TODAY)
        )

    def test_weekend_still_wins_over_leave_range(self) -> None:
        row = self.pending_request(
            start=date(2026, 3, 20),
            end=date(2026, 3, 20),
            total_days=1,
            status=LeaveRequestStatus.APPROVED,
        )
        saturday = date(2026, 3, 21)
        self.assertFalse(leave_covers_date(employee=self.emp_a1, on_date=saturday))
        row.start_date = date(2026, 3, 20)
        row.end_date = date(2026, 3, 22)
        row.save()
        self.assertTrue(leave_covers_date(employee=self.emp_a1, on_date=saturday))
        self.assertFalse(
            AttendanceService().is_absent_on(employee=self.emp_a1, on_date=saturday)
        )
        status = AttendanceService().status_service.calculate(
            local_date=saturday,
            settings=self.settings_a,
            is_holiday=False,
            is_leave=True,
            check_in=None,
            check_out=None,
            total_minutes=None,
        )
        self.assertEqual(status, AttendanceStatus.WEEKEND)


class NotificationAndAuditTests(LeaveFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        clear_events()

    def test_create_emits_event_and_audit(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(client)
        self.assertEqual(response.status_code, 200)
        request_id = response.json()["data"]["id"]
        events = recorded_events(action="leave.request.created")
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["resource_id"], request_id)
        self.assertTrue(
            AuditEvent.objects.filter(
                action="leave.request.created",
                resource="leave.LeaveRequest",
                resource_id=request_id,
                actor=self.employee_a,
                company=self.company_a,
            ).exists()
        )

    def test_approve_reject_cancel_events(self) -> None:
        created = self.post_request(self.authenticate(self.employee_a))
        request_id = created.json()["data"]["id"]
        manager = self.authenticate(self.manager_a)
        manager.post(f"{REQUESTS}/{request_id}/approve/", {}, format="json")
        self.assertEqual(len(recorded_events(action="leave.request.approved")), 1)
        self.authenticate(self.employee_a).post(
            f"{REQUESTS}/{request_id}/cancel/", {}, format="json"
        )
        self.assertEqual(len(recorded_events(action="leave.request.cancelled")), 1)

        other = self.pending_request(start=date(2026, 3, 19), end=date(2026, 3, 19))
        manager.post(
            f"{REQUESTS}/{other.id}/reject/",
            {"rejection_reason": "Not now"},
            format="json",
        )
        self.assertEqual(len(recorded_events(action="leave.request.rejected")), 1)
        for action in (
            "leave.request.created",
            "leave.request.approved",
            "leave.request.cancelled",
            "leave.request.rejected",
        ):
            self.assertTrue(AuditEvent.objects.filter(action=action).exists())
