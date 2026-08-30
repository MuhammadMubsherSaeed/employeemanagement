from datetime import datetime, time, timezone as dt_timezone
from unittest.mock import patch

from apps.companies.models import CompanySettings
from apps.employees.tests.fixtures import EmployeeFixtureMixin

ATTENDANCE = "/api/v1/attendance"
HOLIDAYS = "/api/v1/holidays"

# Monday 16 Mar 2026 09:10 Asia/Karachi
ON_TIME = datetime(2026, 3, 16, 4, 10, tzinfo=dt_timezone.utc)
# 09:20 Asia/Karachi — after 09:00 + 15m grace
LATE = datetime(2026, 3, 16, 4, 20, tzinfo=dt_timezone.utc)
# Saturday
WEEKEND = datetime(2026, 3, 21, 4, 10, tzinfo=dt_timezone.utc)
# 00:30 Asia/Karachi on 16 Mar (15 Mar 19:30 UTC)
NEXT_LOCAL_DAY = datetime(2026, 3, 15, 19, 30, tzinfo=dt_timezone.utc)


def freeze_now(instant: datetime):
    return patch("apps.attendance.services.timezone.now", return_value=instant)


class AttendanceFixtureMixin(EmployeeFixtureMixin):
    @classmethod
    def setUpTestData(cls) -> None:
        super().setUpTestData()
        cls.settings_a = CompanySettings.objects.create(
            company=cls.company_a,
            timezone="Asia/Karachi",
            work_start_time=time(9, 0),
            work_end_time=time(18, 0),
            grace_period_minutes=15,
            minimum_working_minutes=240,
            overtime_enabled=False,
            working_days=[0, 1, 2, 3, 4],
        )
        cls.settings_b = CompanySettings.objects.create(
            company=cls.company_b,
            timezone="UTC",
            work_start_time=time(9, 0),
            work_end_time=time(18, 0),
            grace_period_minutes=15,
            minimum_working_minutes=240,
            working_days=[0, 1, 2, 3, 4],
        )


def check_in(client, instant=ON_TIME, payload=None, **extra):
    with freeze_now(instant):
        return client.post(
            f"{ATTENDANCE}/check-in/",
            payload or {},
            format="json",
            **extra,
        )


def check_out(client, instant, payload=None, **extra):
    with freeze_now(instant):
        return client.post(
            f"{ATTENDANCE}/check-out/",
            payload or {},
            format="json",
            **extra,
        )
