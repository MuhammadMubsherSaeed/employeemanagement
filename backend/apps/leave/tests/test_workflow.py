from concurrent.futures import ThreadPoolExecutor

from django.db import connections
from django.test import TestCase, TransactionTestCase
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import AccessToken

from apps.common.events import clear_events, recorded_events
from apps.common.models import AuditEvent
from apps.leave.models import LeaveRequestStatus
from apps.leave.tests.fixtures import REQUESTS, LeaveFixtureMixin


class ApprovalTests(LeaveFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        clear_events()
        self.row = self.pending_request(total_days=2)

    def test_manager_approves_direct_report(self) -> None:
        client = self.authenticate(self.manager_a)
        response = client.post(f"{REQUESTS}/{self.row.id}/approve/", {}, format="json")
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["status"], LeaveRequestStatus.APPROVED)
        self.assertEqual(data["approved_by"], self.manager_a.id)
        self.assertIsNotNone(data["approved_at"])
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.used_days, 2)
        self.assertEqual(self.balance_a1.remaining_days, 8)
        self.assertEqual(len(recorded_events(action="leave.request.approved")), 1)
        self.assertTrue(
            AuditEvent.objects.filter(
                action="leave.request.approved",
                resource_id=str(self.row.id),
                actor=self.manager_a,
                company=self.company_a,
            ).exists()
        )

    def test_insufficient_balance_rejected(self) -> None:
        self.row.total_days = 11
        self.row.save(update_fields=["total_days", "updated_at"])
        client = self.authenticate(self.manager_a)
        response = client.post(f"{REQUESTS}/{self.row.id}/approve/", {}, format="json")
        self.assertEqual(response.status_code, 400)
        self.row.refresh_from_db()
        self.assertEqual(self.row.status, LeaveRequestStatus.PENDING)
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.used_days, 0)

    def test_already_approved_cannot_approve_again(self) -> None:
        client = self.authenticate(self.manager_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{self.row.id}/approve/", {}, format="json").status_code,
            200,
        )
        response = client.post(f"{REQUESTS}/{self.row.id}/approve/", {}, format="json")
        self.assertEqual(response.status_code, 400)
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.used_days, 2)

    def test_already_rejected_or_cancelled_cannot_approve(self) -> None:
        client = self.authenticate(self.manager_a)
        rejected = self.pending_request(start="2026-03-19", end="2026-03-19")
        rejected.status = LeaveRequestStatus.REJECTED
        rejected.save(update_fields=["status", "updated_at"])
        cancelled = self.pending_request(start="2026-03-20", end="2026-03-20")
        cancelled.status = LeaveRequestStatus.CANCELLED
        cancelled.save(update_fields=["status", "updated_at"])
        self.assertEqual(
            client.post(f"{REQUESTS}/{rejected.id}/approve/", {}, format="json").status_code,
            400,
        )
        self.assertEqual(
            client.post(f"{REQUESTS}/{cancelled.id}/approve/", {}, format="json").status_code,
            400,
        )
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.used_days, 0)

    def test_unauthorized_manager_cannot_approve(self) -> None:
        other = self.pending_request(employee=self.emp_a2)
        client = self.authenticate(self.manager_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{other.id}/approve/", {}, format="json").status_code,
            404,
        )

    def test_admin_can_approve_non_report(self) -> None:
        other = self.pending_request(employee=self.emp_a2)
        client = self.authenticate(self.admin_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{other.id}/approve/", {}, format="json").status_code,
            200,
        )

    def test_employee_cannot_approve(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{self.row.id}/approve/", {}, format="json").status_code,
            403,
        )

    def test_self_approval_rejected(self) -> None:
        own = self.pending_request(employee=self.emp_admin_a)
        client = self.authenticate(self.admin_a)
        response = client.post(f"{REQUESTS}/{own.id}/approve/", {}, format="json")
        self.assertEqual(response.status_code, 403)
        own.refresh_from_db()
        self.assertEqual(own.status, LeaveRequestStatus.PENDING)


class RejectionTests(LeaveFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        clear_events()
        self.row = self.pending_request()

    def test_successful_rejection(self) -> None:
        client = self.authenticate(self.manager_a)
        response = client.post(
            f"{REQUESTS}/{self.row.id}/reject/",
            {"rejection_reason": "Coverage needed"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["status"], LeaveRequestStatus.REJECTED)
        self.assertEqual(data["rejection_reason"], "Coverage needed")
        self.assertEqual(data["approved_by"], self.manager_a.id)
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.used_days, 0)
        self.assertEqual(len(recorded_events(action="leave.request.rejected")), 1)
        self.assertTrue(
            AuditEvent.objects.filter(
                action="leave.request.rejected",
                resource_id=str(self.row.id),
                actor=self.manager_a,
            ).exists()
        )

    def test_missing_and_empty_reason_rejected(self) -> None:
        client = self.authenticate(self.manager_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{self.row.id}/reject/", {}, format="json").status_code,
            400,
        )
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{self.row.id}/reject/",
                {"rejection_reason": "   "},
                format="json",
            ).status_code,
            400,
        )

    def test_already_decided_cannot_reject(self) -> None:
        client = self.authenticate(self.manager_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{self.row.id}/approve/", {}, format="json").status_code,
            200,
        )
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{self.row.id}/reject/",
                {"rejection_reason": "Too late"},
                format="json",
            ).status_code,
            400,
        )
        cancelled = self.pending_request(start="2026-03-20", end="2026-03-20")
        cancelled.status = LeaveRequestStatus.CANCELLED
        cancelled.save(update_fields=["status", "updated_at"])
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{cancelled.id}/reject/",
                {"rejection_reason": "Too late"},
                format="json",
            ).status_code,
            400,
        )

    def test_employee_cannot_reject(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{self.row.id}/reject/",
                {"rejection_reason": "Nope"},
                format="json",
            ).status_code,
            403,
        )

    def test_unauthorized_manager_cannot_reject(self) -> None:
        other = self.pending_request(employee=self.emp_a2)
        client = self.authenticate(self.manager_a)
        self.assertEqual(
            client.post(
                f"{REQUESTS}/{other.id}/reject/",
                {"rejection_reason": "Nope"},
                format="json",
            ).status_code,
            404,
        )


class CancellationTests(LeaveFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        clear_events()

    def test_employee_cancels_own_pending(self) -> None:
        row = self.pending_request()
        client = self.authenticate(self.employee_a)
        response = client.post(f"{REQUESTS}/{row.id}/cancel/", {}, format="json")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["status"], LeaveRequestStatus.CANCELLED)
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.used_days, 0)
        self.assertEqual(len(recorded_events(action="leave.request.cancelled")), 1)

    def test_approved_cancellation_restores_balance(self) -> None:
        row = self.pending_request(total_days=3)
        manager = self.authenticate(self.manager_a)
        self.assertEqual(
            manager.post(f"{REQUESTS}/{row.id}/approve/", {}, format="json").status_code,
            200,
        )
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.used_days, 3)
        clear_events()
        employee = self.authenticate(self.employee_a)
        response = employee.post(f"{REQUESTS}/{row.id}/cancel/", {}, format="json")
        self.assertEqual(response.status_code, 200)
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.used_days, 0)
        self.assertEqual(self.balance_a1.remaining_days, 10)
        self.assertEqual(len(recorded_events(action="leave.request.cancelled")), 1)

    def test_rejected_cannot_cancel(self) -> None:
        row = self.pending_request()
        row.status = LeaveRequestStatus.REJECTED
        row.save(update_fields=["status", "updated_at"])
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{row.id}/cancel/", {}, format="json").status_code,
            400,
        )

    def test_already_cancelled_is_idempotent_error(self) -> None:
        row = self.pending_request()
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{row.id}/cancel/", {}, format="json").status_code,
            200,
        )
        clear_events()
        response = client.post(f"{REQUESTS}/{row.id}/cancel/", {}, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertEqual(len(recorded_events(action="leave.request.cancelled")), 0)
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.balance_a1.used_days, 0)

    def test_employee_cannot_cancel_another_request(self) -> None:
        row = self.pending_request(employee=self.emp_a2)
        client = self.authenticate(self.employee_a)
        self.assertEqual(
            client.post(f"{REQUESTS}/{row.id}/cancel/", {}, format="json").status_code,
            404,
        )


class ConcurrentApprovalTests(LeaveFixtureMixin, TransactionTestCase):
    def setUp(self) -> None:
        super().setUp()
        type(self).setUpTestData()
        self.row = self.pending_request(total_days=2)

    def test_parallel_approvals_deduct_once(self) -> None:
        token = str(AccessToken.for_user(self.manager_a))

        def attempt():
            connections.close_all()
            client = APIClient()
            client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
            return client.post(
                f"{REQUESTS}/{self.row.id}/approve/", {}, format="json"
            )

        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: attempt(), range(2)))

        codes = [response.status_code for response in results]
        self.row.refresh_from_db()
        self.balance_a1.refresh_from_db()
        self.assertEqual(self.row.status, LeaveRequestStatus.APPROVED)
        self.assertEqual(self.balance_a1.used_days, 2)
        self.assertIn(200, codes)
        self.assertTrue(all(code in (200, 400) for code in codes))
        self.assertEqual(codes.count(200), 1)
