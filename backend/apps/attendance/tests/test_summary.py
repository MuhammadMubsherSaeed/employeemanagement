from django.test import TestCase

from apps.attendance.models import Attendance, AttendanceStatus, Holiday
from apps.attendance.tests.fixtures import (
    ATTENDANCE,
    ON_TIME,
    AttendanceFixtureMixin,
    freeze_now,
)
from datetime import datetime, timezone as dt_timezone


class SummaryTests(AttendanceFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date="2026-03-16",
            check_in=ON_TIME,
            check_out=datetime(2026, 3, 16, 10, 10, tzinfo=dt_timezone.utc),
            total_minutes=360,
            status=AttendanceStatus.PRESENT,
        )
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date="2026-03-17",
            check_in=ON_TIME,
            status=AttendanceStatus.LATE,
        )
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a2,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.HALF_DAY,
            total_minutes=100,
        )
        Holiday.objects.create(
            company=self.company_a, name="Off", date="2026-03-23"
        )

    def test_employee_own_summary(self) -> None:
        client = self.authenticate(self.employee_a)
        data = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-16&end_date=2026-03-20"
        ).json()["data"]
        self.assertEqual(data["present_days"], 1)
        self.assertEqual(data["late_days"], 1)
        self.assertEqual(data["total_working_minutes"], 360)
        self.assertEqual(data["employee_id"], str(self.emp_a1.id))
        self.assertGreaterEqual(data["absent_days"], 1)
        self.assertEqual(data["total_days"], 5)

    def test_admin_company_summary(self) -> None:
        client = self.authenticate(self.admin_a)
        data = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-16&end_date=2026-03-17"
        ).json()["data"]
        self.assertIsNone(data["employee_id"])
        self.assertEqual(data["present_days"], 1)
        self.assertEqual(data["late_days"], 1)
        self.assertEqual(data["half_days"], 1)
        self.assertEqual(data["total_working_minutes"], 460)

    def test_admin_employee_summary(self) -> None:
        client = self.authenticate(self.admin_a)
        data = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-16&end_date=2026-03-17"
            f"&employee_id={self.emp_a1.id}"
        ).json()["data"]
        self.assertEqual(data["present_days"], 1)
        self.assertEqual(data["half_days"], 0)

    def test_empty_range(self) -> None:
        client = self.authenticate(self.admin_a)
        data = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-01-01&end_date=2026-01-01"
        ).json()["data"]
        self.assertEqual(data["present_days"], 0)
        self.assertEqual(data["total_working_minutes"], 0)

    def test_invalid_range(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-31&end_date=2026-03-01"
        )
        self.assertEqual(response.status_code, 400)

    def test_range_too_large(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(
            f"{ATTENDANCE}/summary/?start_date=2024-01-01&end_date=2026-12-31"
        )
        self.assertEqual(response.status_code, 400)

    def test_one_bound_without_the_other(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(f"{ATTENDANCE}/summary/?start_date=2026-03-01")
        self.assertEqual(response.status_code, 400)

    def test_overtime_placeholder(self) -> None:
        self.settings_a.overtime_enabled = True
        self.settings_a.save(update_fields=["overtime_enabled", "updated_at"])
        client = self.authenticate(self.admin_a)
        data = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-16&end_date=2026-03-16"
        ).json()["data"]
        self.assertEqual(data["overtime_minutes"], 0)

    def test_overtime_minutes_after_work_end_when_enabled(self) -> None:
        from apps.attendance.tests.fixtures import check_in, check_out

        self.settings_a.overtime_enabled = True
        self.settings_a.save()
        check_in_at = datetime(2026, 3, 18, 4, 10, tzinfo=dt_timezone.utc)
        after_end = datetime(2026, 3, 18, 14, 0, tzinfo=dt_timezone.utc)
        client = self.authenticate(self.employee_a)
        self.assertEqual(check_in(client, check_in_at).status_code, 200)
        self.assertEqual(check_out(client, after_end).status_code, 200)
        data = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-18&end_date=2026-03-18"
        ).json()["data"]
        self.assertEqual(data["overtime_minutes"], 60)

    def test_overtime_stays_zero_when_disabled(self) -> None:
        from apps.attendance.tests.fixtures import check_in, check_out

        self.settings_a.overtime_enabled = False
        self.settings_a.save()
        check_in_at = datetime(2026, 3, 18, 4, 10, tzinfo=dt_timezone.utc)
        after_end = datetime(2026, 3, 18, 14, 0, tzinfo=dt_timezone.utc)
        client = self.authenticate(self.employee_a)
        self.assertEqual(check_in(client, check_in_at).status_code, 200)
        self.assertEqual(check_out(client, after_end).status_code, 200)
        data = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-18&end_date=2026-03-18"
        ).json()["data"]
        self.assertEqual(data["overtime_minutes"], 0)

    def test_default_range_is_company_local_month(self) -> None:
        client = self.authenticate(self.employee_a)
        with freeze_now(ON_TIME):
            data = client.get(f"{ATTENDANCE}/summary/").json()["data"]
        self.assertEqual(data["start_date"], "2026-03-01")
        self.assertEqual(data["end_date"], "2026-03-31")
        self.assertEqual(data["employee_id"], str(self.emp_a1.id))

