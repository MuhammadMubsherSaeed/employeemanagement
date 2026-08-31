from datetime import date

from django.test import TestCase

from apps.attendance.models import Holiday
from apps.leave.calendar import LeaveCalendarService
from apps.leave.tests.fixtures import LeaveFixtureMixin


class LeaveCalendarTests(LeaveFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        self.calendar = LeaveCalendarService()

    def test_single_working_day(self) -> None:
        self.assertEqual(
            self.calendar.working_days_between(
                company=self.company_a,
                start=date(2026, 3, 16),
                end=date(2026, 3, 16),
            ),
            1,
        )

    def test_multiple_working_days(self) -> None:
        self.assertEqual(
            self.calendar.working_days_between(
                company=self.company_a,
                start=date(2026, 3, 16),
                end=date(2026, 3, 20),
            ),
            5,
        )

    def test_weekend_exclusion(self) -> None:
        self.assertEqual(
            self.calendar.working_days_between(
                company=self.company_a,
                start=date(2026, 3, 16),
                end=date(2026, 3, 22),
            ),
            5,
        )
        self.assertEqual(
            self.calendar.working_days_between(
                company=self.company_a,
                start=date(2026, 3, 21),
                end=date(2026, 3, 22),
            ),
            0,
        )

    def test_holiday_exclusion(self) -> None:
        Holiday.objects.create(
            company=self.company_a, name="Break", date="2026-03-18"
        )
        self.assertEqual(
            self.calendar.working_days_between(
                company=self.company_a,
                start=date(2026, 3, 16),
                end=date(2026, 3, 20),
            ),
            4,
        )

    def test_inactive_holiday_is_ignored(self) -> None:
        Holiday.objects.create(
            company=self.company_a,
            name="Old",
            date="2026-03-18",
            is_active=False,
        )
        self.assertEqual(
            self.calendar.working_days_between(
                company=self.company_a,
                start=date(2026, 3, 16),
                end=date(2026, 3, 20),
            ),
            5,
        )

    def test_other_company_holiday_does_not_apply(self) -> None:
        Holiday.objects.create(
            company=self.company_b, name="Beta", date="2026-03-18"
        )
        self.assertEqual(
            self.calendar.working_days_between(
                company=self.company_a,
                start=date(2026, 3, 16),
                end=date(2026, 3, 20),
            ),
            5,
        )

    def test_weekend_and_holiday_combination(self) -> None:
        Holiday.objects.create(
            company=self.company_a, name="Break", date="2026-03-18"
        )
        self.assertEqual(
            self.calendar.working_days_between(
                company=self.company_a,
                start=date(2026, 3, 16),
                end=date(2026, 3, 22),
            ),
            4,
        )

    def test_invalid_range_is_zero(self) -> None:
        self.assertEqual(
            self.calendar.working_days_between(
                company=self.company_a,
                start=date(2026, 3, 20),
                end=date(2026, 3, 16),
            ),
            0,
        )

    def test_custom_working_week_not_sat_sun_assumption(self) -> None:
        self.settings_a.working_days = [6]
        self.settings_a.save(update_fields=["working_days", "updated_at"])
        self.assertEqual(
            self.calendar.working_days_between(
                company=self.company_a,
                start=date(2026, 3, 16),
                end=date(2026, 3, 22),
            ),
            1,
        )
