from django.test import TestCase
from rest_framework.test import APIClient

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
from apps.companies.models import CompanyMembership
from apps.companies.services import MembershipService
from apps.companies.tests.fixtures import PASSWORD, User
from apps.employees.tests.fixtures import ids


class CheckInTests(AttendanceFixtureMixin, TestCase):
    def test_successful_check_in(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_in(client)
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["status"], AttendanceStatus.PRESENT)
        self.assertEqual(data["date"], "2026-03-16")
        self.assertIsNotNone(data["check_in"])
        self.assertIsNone(data["check_out"])
        self.assertNotIn("check_in_ip", data)
        row = Attendance.objects.get(pk=data["id"])
        self.assertEqual(row.employee_id, self.emp_a1.id)
        self.assertEqual(row.company_id, self.company_a.id)

    def test_duplicate_check_in(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(check_in(client).status_code, 200)
        response = check_in(client)
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["code"], "VALIDATION_ERROR")
        self.assertEqual(
            Attendance.objects.filter(employee=self.emp_a1, date="2026-03-16").count(),
            1,
        )

    def test_unauthenticated_check_in(self) -> None:
        response = APIClient().post(f"{ATTENDANCE}/check-in/", {}, format="json")
        self.assertEqual(response.status_code, 401)

    def test_user_without_employee_profile(self) -> None:
        user = User.objects.create_user(
            email="no-profile@example.com",
            password=PASSWORD,
            role="EMPLOYEE",
        )
        MembershipService().assign(
            user=user,
            company=self.company_a,
            role=self.roles["EMPLOYEE"],
        )
        client = self.authenticate(user)
        response = check_in(client)
        self.assertEqual(response.status_code, 400)

    def test_inactive_membership(self) -> None:
        MembershipService().deactivate(
            CompanyMembership.objects.get(user=self.employee_a, company=self.company_a)
        )
        client = self.authenticate(self.employee_a)
        self.assertEqual(check_in(client).status_code, 403)

    def test_inactive_company(self) -> None:
        self.company_a.is_active = False
        self.company_a.save(update_fields=["is_active", "updated_at"])
        client = self.authenticate(self.employee_a)
        self.assertEqual(check_in(client).status_code, 403)

    def test_weekend_check_in(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_in(client, WEEKEND)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["status"], AttendanceStatus.WEEKEND)
        self.assertEqual(response.json()["data"]["date"], "2026-03-21")

    def test_holiday_check_in(self) -> None:
        Holiday.objects.create(
            company=self.company_a,
            name="Foundation Day",
            date="2026-03-16",
        )
        client = self.authenticate(self.employee_a)
        response = check_in(client, ON_TIME)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["status"], AttendanceStatus.HOLIDAY)

    def test_late_check_in(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_in(client, LATE)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["status"], AttendanceStatus.LATE)

    def test_on_time_check_in(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_in(client, ON_TIME)
        self.assertEqual(response.json()["data"]["status"], AttendanceStatus.PRESENT)

    def test_latitude_out_of_range(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_in(
            client, payload={"latitude": 100, "longitude": 74.3}
        )
        self.assertEqual(response.status_code, 400)

    def test_longitude_out_of_range(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_in(
            client, payload={"latitude": 31.5, "longitude": 200}
        )
        self.assertEqual(response.status_code, 400)

    def test_latitude_without_longitude(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_in(client, payload={"latitude": 31.5})
        self.assertEqual(response.status_code, 400)

    def test_valid_location_and_server_ip(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_in(
            client,
            payload={"latitude": "31.520400", "longitude": "74.358700"},
            REMOTE_ADDR="203.0.113.10",
        )
        self.assertEqual(response.status_code, 200)
        row = Attendance.objects.get(pk=response.json()["data"]["id"])
        self.assertEqual(str(row.check_in_ip), "203.0.113.10")
        self.assertEqual(str(row.check_in_latitude), "31.520400")
        self.assertNotIn("check_in_ip", response.json()["data"])

    def test_client_cannot_set_timestamp_or_status(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_in(
            client,
            payload={
                "check_in": "2020-01-01T00:00:00Z",
                "status": AttendanceStatus.LEAVE,
                "date": "2020-01-01",
                "company_id": str(self.company_b.id),
                "employee": str(self.emp_b1.id),
                "total_minutes": 9,
            },
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["date"], "2026-03-16")
        self.assertEqual(data["status"], AttendanceStatus.PRESENT)
        self.assertNotEqual(data["employee"]["id"], str(self.emp_b1.id))

    def test_server_timestamp_is_authoritative(self) -> None:
        client = self.authenticate(self.employee_a)
        data = check_in(client, ON_TIME).json()["data"]
        self.assertTrue(data["check_in"].startswith("2026-03-16T04:10:00"))

    def test_manager_cannot_check_in(self) -> None:
        client = self.authenticate(self.manager_a)
        self.assertEqual(check_in(client).status_code, 403)

    def test_cannot_check_in_for_another_employee(self) -> None:
        client = self.authenticate(self.employee_a)
        response = check_in(
            client, payload={"employee_id": str(self.emp_a2.id)}
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json()["data"]["employee"]["id"], str(self.emp_a1.id)
        )
