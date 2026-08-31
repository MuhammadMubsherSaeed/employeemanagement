from datetime import date

from django.test import TestCase

from apps.employees.tests.fixtures import ids
from apps.leave.models import LeaveRequestStatus
from apps.leave.tests.fixtures import BALANCES, REQUESTS, TYPES, LeaveFixtureMixin


class TenantIsolationTests(LeaveFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        self.request_a = self.pending_request()
        self.request_b = self.pending_request(
            employee=self.emp_b1,
            leave_type=self.type_b,
            start=date(2026, 3, 16),
            end=date(2026, 3, 16),
        )

    def test_company_a_cannot_view_company_b_types(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{TYPES}/"))
        self.assertIn(str(self.type_a.id), listed)
        self.assertNotIn(str(self.type_b.id), listed)
        self.assertEqual(client.get(f"{TYPES}/{self.type_b.id}/").status_code, 404)
        self.assertEqual(
            client.patch(
                f"{TYPES}/{self.type_b.id}/",
                {"name": "Hacked"},
                format="json",
            ).status_code,
            404,
        )

    def test_company_a_cannot_view_or_allocate_company_b_balances(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{BALANCES}/"))
        self.assertNotIn(str(self.balance_b1.id), listed)
        self.assertEqual(
            client.get(f"{BALANCES}/{self.balance_b1.id}/").status_code, 404
        )
        self.assertEqual(
            client.patch(
                f"{BALANCES}/{self.balance_b1.id}/",
                {"allocated_days": 99},
                format="json",
            ).status_code,
            404,
        )

    def test_company_a_cannot_view_or_decide_company_b_requests(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{REQUESTS}/"))
        self.assertIn(str(self.request_a.id), listed)
        self.assertNotIn(str(self.request_b.id), listed)
        self.assertEqual(
            client.get(f"{REQUESTS}/{self.request_b.id}/").status_code, 404
        )
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{self.request_b.id}/approve/", {}, format="json"
            ).status_code,
            404,
        )
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{self.request_b.id}/reject/",
                {"rejection_reason": "Cross tenant"},
                format="json",
            ).status_code,
            404,
        )
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{self.request_b.id}/cancel/", {}, format="json"
            ).status_code,
            404,
        )

    def test_filter_cannot_reach_other_company(self) -> None:
        client = self.authenticate(self.admin_a)
        listed = ids(
            client.get(f"{REQUESTS}/?employee={self.emp_b1.id}")
        )
        self.assertEqual(listed, set())
        listed_types = ids(
            client.get(f"{TYPES}/?status={self.type_b.status}")
        )
        self.assertNotIn(str(self.type_b.id), listed_types)

    def test_cannot_use_other_company_leave_type(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(
            client, {"leave_type": str(self.type_b.id)}
        )
        self.assertEqual(response.status_code, 400)
        self.request_b.refresh_from_db()
        self.assertEqual(self.request_b.status, LeaveRequestStatus.PENDING)
