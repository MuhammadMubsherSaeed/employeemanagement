from django.test import TestCase

from apps.attendance.models import Attendance, AttendanceStatus
from apps.attendance.tests.fixtures import (
    ATTENDANCE,
    ON_TIME,
    AttendanceFixtureMixin,
    check_in,
)
from apps.employees.tests.fixtures import ids


class FilterTests(AttendanceFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        self.present = Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        self.late = Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a2,
            date="2026-03-17",
            check_in=ON_TIME,
            status=AttendanceStatus.LATE,
        )
        self.other = Attendance.objects.create(
            company=self.company_b,
            employee=self.emp_b1,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )

    def test_employee_filter(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{ATTENDANCE}/?employee={self.emp_a1.id}"))
        self.assertEqual(listed, {str(self.present.id)})

    def test_department_filter(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{ATTENDANCE}/?department={self.dept_a.id}"))
        self.assertEqual(listed, {str(self.present.id)})

    def test_status_filter(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{ATTENDANCE}/?status=LATE"))
        self.assertEqual(listed, {str(self.late.id)})

    def test_date_range_filter(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(
            client.get(f"{ATTENDANCE}/?start_date=2026-03-16&end_date=2026-03-16")
        )
        self.assertEqual(listed, {str(self.present.id)})

    def test_combined_filters(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(
            client.get(
                f"{ATTENDANCE}/?employee={self.emp_a2.id}&status=LATE"
                "&start_date=2026-03-01&end_date=2026-03-31"
            )
        )
        self.assertEqual(listed, {str(self.late.id)})

    def test_invalid_date_range(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(
            f"{ATTENDANCE}/?start_date=2026-03-31&end_date=2026-03-01"
        )
        self.assertEqual(response.status_code, 400)

    def test_ordering(self) -> None:
        client = self.authenticate(self.admin_a)
        results = client.get(f"{ATTENDANCE}/?ordering=date").json()["data"]["results"]
        dates = [row["date"] for row in results]
        self.assertEqual(dates, sorted(dates))

    def test_unknown_ordering_ignored(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(f"{ATTENDANCE}/?ordering=password")
        self.assertEqual(response.status_code, 200)

    def test_pagination(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(f"{ATTENDANCE}/?page_size=1")
        self.assertEqual(response.status_code, 200)
        payload = response.json()["data"]
        self.assertEqual(payload["count"], 2)
        self.assertEqual(len(payload["results"]), 1)
        self.assertIsNotNone(payload["next"])
