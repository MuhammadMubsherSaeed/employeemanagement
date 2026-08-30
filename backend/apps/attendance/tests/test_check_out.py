from datetime import datetime, timezone as dt_timezone

from django.test import TestCase

from apps.attendance.models import Attendance, AttendanceStatus, Holiday
from apps.attendance.tests.fixtures import (
    ATTENDANCE,
    LATE,
    ON_TIME,
    WEEKEND,
    AttendanceFixtureMixin,
    check_in,
    check_out,
)

HALF_DAY_OUT = datetime(2026, 3, 16, 6, 0, tzinfo=dt_timezone.utc)
FULL_DAY_OUT = datetime(2026, 3, 16, 10, 10, tzinfo=dt_timezone.utc)
BEFORE_CHECK_IN = datetime(2026, 3, 16, 3, 0, tzinfo=dt_timezone.utc)


class CheckOutTests(AttendanceFixtureMixin, TestCase):
    def test_successful_checkout(self) -> None:
        client = self.authenticate(self.employee_a)
        check_in(client, ON_TIME)
        response = check_out(client, FULL_DAY_OUT)
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.PRESENT)
        self.assertEqual(data["total_minutes"], 360)

    def test_checkout_without_check_in(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_out(client, FULL_DAY_OUT)
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "VALIDATION_ERROR")

    def test_duplicate_checkout(self) -> None:
        client = self.authenticate(self.employee_a)
        check_in(client, ON_TIME)
        self.assertEqual(check_out(client, FULL_DAY_OUT).status_code, 200)
        response = check_out(client, FULL_DAY_OUT)
        self.assertEqual(response.status_code, 400)
        row = Attendance.objects.get(employee=self.emp_a1, date="2026-03-16")
        self.assertEqual(row.total_minutes, 360)

    def test_checkout_before_check_in(self) -> None:
        client = self.authenticate(self.employee_a)
        check_in(client, ON_TIME)
        response = check_out(client, BEFORE_CHECK_IN)
        self.assertEqual(response.status_code, 400)

    def test_working_minutes_are_server_calculated(self) -> None:
        client = self.authenticate(self.employee_a)
        check_in(client, ON_TIME)
        data = check_out(
            client, FULL_DAY_OUT, payload={"total_minutes": 1}
        ).json()["data"]
        self.assertEqual(data["total_minutes"], 360)

    def test_late_status_after_full_day(self) -> None:
        client = self.authenticate(self.employee_a)
        check_in(client, LATE)
        data = check_out(client, FULL_DAY_OUT).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.LATE)
        self.assertEqual(data["total_minutes"], 350)

    def test_half_day_status(self) -> None:
        client = self.authenticate(self.employee_a)
        check_in(client, ON_TIME)
        data = check_out(client, HALF_DAY_OUT).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.HALF_DAY)
        self.assertEqual(data["total_minutes"], 110)

    def test_half_day_takes_precedence_over_late(self) -> None:
        client = self.authenticate(self.employee_a)
        check_in(client, LATE)
        data = check_out(client, HALF_DAY_OUT).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.HALF_DAY)

    def test_holiday_status_not_overridden_by_checkout(self) -> None:
        Holiday.objects.create(
            company=self.company_a, name="Day off", date="2026-03-16"
        )
        client = self.authenticate(self.employee_a)
        check_in(client, ON_TIME)
        data = check_out(client, FULL_DAY_OUT).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.HOLIDAY)
        self.assertEqual(data["total_minutes"], 360)

    def test_weekend_status_not_overridden_by_checkout(self) -> None:
        client = self.authenticate(self.employee_a)
        check_in(client, WEEKEND)
        out = datetime(2026, 3, 21, 10, 10, tzinfo=dt_timezone.utc)
        data = check_out(client, out).json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.WEEKEND)

    def test_checkout_location_validation(self) -> None:
        client = self.authenticate(self.employee_a)
        check_in(client, ON_TIME)
        response = check_out(
            client, FULL_DAY_OUT, payload={"latitude": 91, "longitude": 0}
        )
        self.assertEqual(response.status_code, 400)

    def test_server_checkout_timestamp(self) -> None:
        client = self.authenticate(self.employee_a)
        check_in(client, ON_TIME)
        data = check_out(client, FULL_DAY_OUT).json()["data"]
        self.assertTrue(data["check_out"].startswith("2026-03-16T10:10:00"))

    def test_manual_patch_is_not_allowed(self) -> None:
        client = self.authenticate(self.admin_a)
        created = check_in(self.authenticate(self.employee_a), ON_TIME).json()["data"]
        response = client.patch(
            f"{ATTENDANCE}/{created['id']}/",
            {"status": AttendanceStatus.LEAVE},
            format="json",
        )
        self.assertEqual(response.status_code, 405)
