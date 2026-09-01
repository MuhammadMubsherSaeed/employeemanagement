from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, time, timezone as dt_timezone

from django.core.exceptions import ValidationError
from django.db import IntegrityError, connections
from django.test import TestCase, TransactionTestCase
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import AccessToken

from apps.attendance.models import Attendance, AttendanceStatus, Holiday
from apps.attendance.services import AttendanceStatusService, CompanyClock
from apps.attendance.tests.fixtures import (
    ATTENDANCE,
    LATE,
    NEXT_LOCAL_DAY,
    ON_TIME,
    WEEKEND,
    AttendanceFixtureMixin,
    check_in,
    check_out,
    freeze_now,
)
from apps.companies.models import CompanySettings


class ConstraintTests(AttendanceFixtureMixin, TestCase):
    def test_unique_employee_date_constraint(self) -> None:
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        with self.assertRaises(IntegrityError):
            Attendance.objects.bulk_create(
                [
                    Attendance(
                        company=self.company_a,
                        employee=self.emp_a1,
                        date="2026-03-16",
                        check_in=ON_TIME,
                        status=AttendanceStatus.LATE,
                    )
                ]
            )

    def test_same_date_other_company_allowed(self) -> None:
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        other = Attendance.objects.create(
            company=self.company_b,
            employee=self.emp_b1,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        self.assertEqual(other.date.isoformat(), "2026-03-16")

    def test_cross_company_employee_rejected(self) -> None:
        with self.assertRaises(ValidationError):
            Attendance.objects.create(
                company=self.company_a,
                employee=self.emp_b1,
                date="2026-03-16",
                check_in=ON_TIME,
                status=AttendanceStatus.PRESENT,
            )

    def test_checkout_before_checkin_constraint(self) -> None:
        with self.assertRaises(ValidationError):
            Attendance.objects.create(
                company=self.company_a,
                employee=self.emp_a1,
                date="2026-03-16",
                check_in=ON_TIME,
                check_out=datetime(2026, 3, 16, 3, 0, tzinfo=dt_timezone.utc),
                status=AttendanceStatus.PRESENT,
            )


class TimezoneTests(AttendanceFixtureMixin, TestCase):
    def test_attendance_date_uses_company_timezone(self) -> None:
        client = self.authenticate(self.employee_a)
        data = check_in(client, NEXT_LOCAL_DAY).json()["data"]
        self.assertEqual(data["date"], "2026-03-16")

    def test_clock_converts_utc_to_company_zone(self) -> None:
        clock = CompanyClock(self.settings_a)
        self.assertEqual(clock.local_date(ON_TIME).isoformat(), "2026-03-16")
        self.assertEqual(clock.local_date(NEXT_LOCAL_DAY).isoformat(), "2026-03-16")


class StatusServiceTests(AttendanceFixtureMixin, TestCase):
    def test_weekend_from_working_days_not_saturday_sunday_assumption(self) -> None:
        self.settings_a.working_days = [6]
        self.settings_a.save(update_fields=["working_days", "updated_at"])
        service = AttendanceStatusService()
        monday = service.calculate(
            local_date=ON_TIME.date(),
            settings=self.settings_a,
            is_holiday=False,
            is_leave=False,
            check_in=ON_TIME,
            check_out=None,
            total_minutes=None,
        )
        self.assertEqual(monday, AttendanceStatus.WEEKEND)

    def test_leave_is_not_fabricated(self) -> None:
        from apps.attendance.services import leave_covers_date

        self.assertFalse(
            leave_covers_date(employee=self.emp_a1, on_date=ON_TIME.date())
        )

    def test_absence_helper_does_not_create_rows(self) -> None:
        from apps.attendance.services import AttendanceService

        before = Attendance.objects.count()
        absent = AttendanceService().is_absent_on(
            employee=self.emp_a1, on_date=ON_TIME.date()
        )
        self.assertTrue(absent)
        self.assertEqual(Attendance.objects.count(), before)


class CompanySettingsTests(AttendanceFixtureMixin, TestCase):
    def test_overnight_configuration_rejected(self) -> None:
        self.settings_a.work_start_time = time(22, 0)
        self.settings_a.work_end_time = time(6, 0)
        with self.assertRaises(ValidationError):
            self.settings_a.save()

    def test_invalid_timezone_rejected(self) -> None:
        self.settings_a.timezone = "Not/A_Zone"
        with self.assertRaises(ValidationError):
            self.settings_a.save()

    def test_invalid_working_days_rejected(self) -> None:
        self.settings_a.working_days = [9]
        with self.assertRaises(ValidationError):
            self.settings_a.save()

    def test_grace_period_changes_late_threshold(self) -> None:
        self.settings_a.grace_period_minutes = 30
        self.settings_a.save()
        client = self.authenticate(self.employee_a)
        data = check_in(client, LATE).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.PRESENT)

    def test_working_days_control_weekend_status(self) -> None:
        self.settings_a.working_days = [0, 1, 2, 3, 4, 5]
        self.settings_a.save()
        client = self.authenticate(self.employee_a)
        data = check_in(client, WEEKEND).json()["data"]
        self.assertNotEqual(data["status"], AttendanceStatus.WEEKEND)

    def test_minimum_working_minutes_drives_half_day(self) -> None:
        from datetime import datetime, timezone as dt_timezone

        self.settings_a.minimum_working_minutes = 600
        self.settings_a.save()
        client = self.authenticate(self.employee_a)
        self.assertEqual(check_in(client, ON_TIME).status_code, 200)
        # 04:10–09:00 UTC ≈ 290 minutes: above the fixture minimum (240), below 600.
        mid_day = datetime(2026, 3, 16, 9, 0, tzinfo=dt_timezone.utc)
        data = check_out(client, mid_day).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.HALF_DAY)

    def test_timezone_changes_late_threshold(self) -> None:
        self.settings_a.timezone = "UTC"
        self.settings_a.save()
        client = self.authenticate(self.employee_a)
        data = check_in(client, LATE).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.PRESENT)

    def test_work_start_time_changes_late_threshold(self) -> None:
        self.settings_a.work_start_time = time(9, 30)
        self.settings_a.save()
        client = self.authenticate(self.employee_a)
        data = check_in(client, LATE).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.PRESENT)

    def test_holiday_unique_per_company(self) -> None:
        Holiday.objects.create(company=self.company_a, name="A", date="2026-03-23")
        with self.assertRaises(ValidationError):
            Holiday.objects.create(company=self.company_a, name="B", date="2026-03-23")
        other = Holiday.objects.create(
            company=self.company_b, name="B", date="2026-03-23"
        )
        self.assertEqual(other.company_id, self.company_b.id)

    def test_inactive_holiday_does_not_mark_holiday(self) -> None:
        Holiday.objects.create(
            company=self.company_a,
            name="Old",
            date="2026-03-16",
            is_active=False,
        )
        client = self.authenticate(self.employee_a)
        data = check_in(client, ON_TIME).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.PRESENT)

    def test_holiday_api_is_company_scoped(self) -> None:
        from apps.attendance.tests.fixtures import HOLIDAYS

        Holiday.objects.create(company=self.company_b, name="Beta", date="2026-04-01")
        client = self.authenticate(self.admin_a)
        created = client.post(
            f"{HOLIDAYS}/",
            {"name": "Acme Day", "date": "2026-04-01"},
            format="json",
        )
        self.assertEqual(created.status_code, 200)
        listed = client.get(f"{HOLIDAYS}/").json()["data"]["results"]
        names = {row["name"] for row in listed}
        self.assertIn("Acme Day", names)
        self.assertNotIn("Beta", names)

    def test_employee_cannot_create_holiday(self) -> None:
        from apps.attendance.tests.fixtures import HOLIDAYS

        client = self.authenticate(self.employee_a)
        response = client.post(
            f"{HOLIDAYS}/",
            {"name": "Nope", "date": "2026-04-02"},
            format="json",
        )
        self.assertEqual(response.status_code, 403)


class ConcurrentCheckInTests(AttendanceFixtureMixin, TransactionTestCase):
    def setUp(self) -> None:
        super().setUp()
        type(self).setUpTestData()

    def test_parallel_check_ins_cannot_create_duplicates(self) -> None:
        token = str(AccessToken.for_user(self.employee_a))

        def attempt():
            connections.close_all()
            client = APIClient()
            client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
            with freeze_now(ON_TIME):
                return client.post(f"{ATTENDANCE}/check-in/", {}, format="json")

        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: attempt(), range(2)))

        codes = [response.status_code for response in results]
        self.assertEqual(
            Attendance.objects.filter(
                employee=self.emp_a1, date="2026-03-16"
            ).count(),
            1,
        )
        self.assertIn(200, codes)
        self.assertTrue(all(code in (200, 400) for code in codes))

