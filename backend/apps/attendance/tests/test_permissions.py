from django.test import TestCase

from apps.attendance.models import Attendance, AttendanceStatus
from apps.attendance.tests.fixtures import (
    ATTENDANCE,
    ON_TIME,
    AttendanceFixtureMixin,
    check_in,
)
from apps.employees.tests.fixtures import ids


class RolePermissionTests(AttendanceFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        self.own = Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        self.manager_row = Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_manager_a,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        self.other = Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a2,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.LATE,
        )
        self.foreign = Attendance.objects.create(
            company=self.company_b,
            employee=self.emp_b1,
            date="2026-03-16",
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )

    def test_employee_sees_only_own(self) -> None:
        client = self.authenticate(self.employee_a)
        listed = ids(client.get(f"{ATTENDANCE}/"))
        self.assertEqual(listed, {str(self.own.id)})
        self.assertEqual(client.get(f"{ATTENDANCE}/{self.own.id}/").status_code, 200)
        self.assertEqual(client.get(f"{ATTENDANCE}/{self.other.id}/").status_code, 404)
        self.assertEqual(client.get(f"{ATTENDANCE}/{self.foreign.id}/").status_code, 404)
        me = ids(client.get(f"{ATTENDANCE}/me/"))
        self.assertEqual(me, {str(self.own.id)})
        detail = client.get(f"{ATTENDANCE}/{self.own.id}/").json()["data"]
        self.assertNotIn("check_in_ip", detail)

    def test_employee_cannot_request_another_summary(self) -> None:
        client = self.authenticate(self.employee_a)
        response = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-01&end_date=2026-03-31"
            f"&employee_id={self.emp_a2.id}"
        )
        self.assertEqual(response.status_code, 404)

    def test_manager_sees_self_and_direct_reports(self) -> None:
        client = self.authenticate(self.manager_a)
        listed = ids(client.get(f"{ATTENDANCE}/"))
        self.assertIn(str(self.own.id), listed)
        self.assertIn(str(self.manager_row.id), listed)
        self.assertNotIn(str(self.other.id), listed)
        self.assertNotIn(str(self.foreign.id), listed)
        self.assertEqual(client.get(f"{ATTENDANCE}/{self.own.id}/").status_code, 200)
        self.assertEqual(client.get(f"{ATTENDANCE}/{self.other.id}/").status_code, 404)
        detail = client.get(f"{ATTENDANCE}/{self.own.id}/").json()["data"]
        self.assertIn("check_in_ip", detail)

    def test_manager_summary_cannot_target_unauthorized(self) -> None:
        client = self.authenticate(self.manager_a)
        denied = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-01&end_date=2026-03-31"
            f"&employee_id={self.emp_a2.id}"
        )
        allowed = client.get(
            f"{ATTENDANCE}/summary/?start_date=2026-03-01&end_date=2026-03-31"
            f"&employee_id={self.emp_a1.id}"
        )
        self.assertEqual(denied.status_code, 404)
        self.assertEqual(allowed.status_code, 200)

    def test_admin_sees_company_not_other(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{ATTENDANCE}/"))
        self.assertIn(str(self.own.id), listed)
        self.assertIn(str(self.other.id), listed)
        self.assertNotIn(str(self.foreign.id), listed)
        self.assertEqual(client.get(f"{ATTENDANCE}/{self.foreign.id}/").status_code, 404)

    def test_admin_detail_includes_sensitive_fields(self) -> None:
        self.own.check_in_ip = "203.0.113.10"
        self.own.save(update_fields=["check_in_ip", "updated_at"])
        client = self.authenticate(self.admin_a)
        data = client.get(f"{ATTENDANCE}/{self.own.id}/").json()["data"]
        self.assertEqual(data["check_in_ip"], "203.0.113.10")

    def test_list_omits_sensitive_fields(self) -> None:
        client = self.authenticate(self.admin_a)
        row = client.get(f"{ATTENDANCE}/").json()["data"]["results"][0]
        self.assertNotIn("check_in_ip", row)
        self.assertNotIn("check_in_latitude", row)
