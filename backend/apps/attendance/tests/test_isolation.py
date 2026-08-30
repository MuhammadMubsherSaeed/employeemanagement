from django.test import TestCase

from apps.attendance.models import Attendance, AttendanceStatus
from apps.attendance.tests.fixtures import (
    ATTENDANCE,
    ON_TIME,
    AttendanceFixtureMixin,
    check_in,
)
from apps.employees.tests.fixtures import ids


class TenantIsolationTests(AttendanceFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        self.row_a = Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        self.row_b = Attendance.objects.create(
            company=self.company_b,
            employee=self.emp_b1,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )

    def test_admin_cannot_list_other_company(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{ATTENDANCE}/"))
        self.assertIn(str(self.row_a.id), listed)
        self.assertNotIn(str(self.row_b.id), listed)

    def test_admin_cannot_retrieve_other_company(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assertEqual(
            client.get(f"{ATTENDANCE}/{self.row_b.id}/").status_code, 404
        )

    def test_filter_cannot_reach_other_company(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(f"{ATTENDANCE}/?employee={self.emp_b1.id}")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(ids(response), set())

    def test_summary_cannot_target_other_company(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-01&end_date=2026-03-31"
            f"&employee_id={self.emp_b1.id}"
        )
        self.assertEqual(response.status_code, 404)

    def test_company_id_in_query_is_ignored(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{ATTENDANCE}/?company_id={self.company_b.id}"))
        self.assertNotIn(str(self.row_b.id), listed)
        self.assertIn(str(self.row_a.id), listed)
