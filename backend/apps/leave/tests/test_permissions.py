from django.test import TestCase

from apps.employees.tests.fixtures import ids
from apps.leave.tests.fixtures import BALANCES, REQUESTS, TYPES, LeaveFixtureMixin


class ManagerAuthorizationTests(LeaveFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        self.report = self.pending_request()
        self.unmanaged = self.pending_request(employee=self.emp_a2)
        self.foreign = self.pending_request(
            employee=self.emp_b1, leave_type=self.type_b
        )

    def test_manager_sees_permitted_team_only(self) -> None:
        client = self.authenticate(self.manager_a)
        listed = ids(client.get(f"{REQUESTS}/"))
        self.assertIn(str(self.report.id), listed)
        self.assertNotIn(str(self.unmanaged.id), listed)
        self.assertNotIn(str(self.foreign.id), listed)
        self.assertEqual(client.get(f"{REQUESTS}/{self.report.id}/").status_code, 200)
        self.assertEqual(
            client.get(f"{REQUESTS}/{self.unmanaged.id}/").status_code, 404
        )

    def test_manager_cannot_approve_or_reject_unauthorized(self) -> None:
        client = self.authenticate(self.manager_a)
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{self.unmanaged.id}/approve/", {}, format="json"
            ).status_code,
            404,
        )
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{self.unmanaged.id}/reject/",
                {"rejection_reason": "No access"},
                format="json",
            ).status_code,
            404,
        )
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{self.foreign.id}/approve/", {}, format="json"
            ).status_code,
            404,
        )

    def test_manager_can_approve_direct_report(self) -> None:
        client = self.authenticate(self.manager_a)
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{self.report.id}/approve/", {}, format="json"
            ).status_code,
            200,
        )


class EmployeeSecurityTests(LeaveFixtureMixin, TestCase):
    def test_employee_can_create_view_cancel_own(self) -> None:
        client = self.authenticate(self.employee_a)
        created = self.post_request(client)
        self.assertEqual(created.status_code, 200)
        request_id = created.json()["data"]["id"]
        self.assertEqual(client.get(f"{REQUESTS}/{request_id}/").status_code, 200)
        self.assertEqual(
            client.post(f"{REQUESTS}/{request_id}/cancel/", {}, format="json").status_code,
            200,
        )

    def test_employee_cannot_approve_or_reject(self) -> None:
        row = self.pending_request()
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{row.id}/approve/", {}, format="json").status_code,
            403,
        )
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{row.id}/reject/",
                {"rejection_reason": "Self"},
                format="json",
            ).status_code,
            403,
        )

    def test_employee_cannot_access_peer_balance_or_request(self) -> None:
        other = self.pending_request(employee=self.emp_a2)
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.get(f"{BALANCES}/{self.balance_a2.id}/").status_code, 404
        )
        self.assertEqual(client.get(f"{REQUESTS}/{other.id}/").status_code, 404)

    def test_employee_cannot_create_leave_types(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.post(
                f"{TYPES}/",
                {"name": "Secret", "code": "SEC", "days_allowed": 1},
                format="json",
            ).status_code,
            403,
        )

    def test_manager_cannot_create_requests_without_leave_create(self) -> None:
        client = self.authenticate(self.manager_a)
        response = self.post_request(client)
        self.assertEqual(response.status_code, 403)
