from django.test import TestCase

from apps.devices.tests.fixtures import DeviceFixtureMixin
from apps.leave.tests.fixtures import REQUESTS, LeaveFixtureMixin
from apps.notifications.models import Notification, NotificationType
from apps.notifications.tests import NOTIFICATIONS


class LeaveNotificationEventTests(LeaveFixtureMixin, TestCase):
    def test_submit_notifies_manager_not_submitter(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(client)
        self.assertEqual(response.status_code, 200)
        request_id = response.json()["data"]["id"]
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.manager_a,
                type=NotificationType.LEAVE_SUBMITTED,
                entity_id=str(request_id),
            ).exists()
        )
        self.assertFalse(
            Notification.objects.filter(
                recipient=self.employee_a,
                type=NotificationType.LEAVE_SUBMITTED,
            ).exists()
        )

    def test_approve_and_reject_notify_employee(self) -> None:
        pending = self.pending_request()
        manager = self.authenticate(self.manager_a)
        approved = manager.post(
            f"{REQUESTS}/{pending.id}/approve/",
            {},
            format="json",
        )
        self.assertEqual(approved.status_code, 200)
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.employee_a,
                type=NotificationType.LEAVE_APPROVED,
                entity_id=str(pending.id),
            ).exists()
        )
        other = self.pending_request()
        rejected = manager.post(
            f"{REQUESTS}/{other.id}/reject/",
            {"rejection_reason": "Coverage is too thin this week."},
            format="json",
        )
        self.assertEqual(rejected.status_code, 200)
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.employee_a,
                type=NotificationType.LEAVE_REJECTED,
                entity_id=str(other.id),
            ).exists()
        )

    def test_cancel_notifies_manager(self) -> None:
        client = self.authenticate(self.employee_a)
        created = self.post_request(client)
        request_id = created.json()["data"]["id"]
        cancelled = client.post(
            f"{REQUESTS}/{request_id}/cancel/",
            {},
            format="json",
        )
        self.assertEqual(cancelled.status_code, 200)
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.manager_a,
                type=NotificationType.LEAVE_CANCELLED,
                entity_id=str(request_id),
            ).exists()
        )


class DeviceNotificationEventTests(DeviceFixtureMixin, TestCase):
    def test_assign_and_return_notify_employee(self) -> None:
        admin = self.authenticate(self.admin_a)
        assigned = self.assign_via_api(admin, self.device_a, self.emp_a1)
        self.assertEqual(assigned.status_code, 200)
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.employee_a,
                type=NotificationType.DEVICE_ASSIGNED,
                entity_id=str(self.device_a.id),
            ).exists()
        )
        returned = self.return_via_api(admin, self.device_a)
        self.assertEqual(returned.status_code, 200)
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.employee_a,
                type=NotificationType.DEVICE_RETURNED,
                entity_id=str(self.device_a.id),
            ).exists()
        )
        self.assertFalse(
            Notification.objects.filter(
                recipient=self.admin_a,
                type=NotificationType.DEVICE_ASSIGNED,
            ).exists()
        )


class NotificationTenantEventTests(LeaveFixtureMixin, TestCase):
    def test_leave_events_do_not_cross_companies(self) -> None:
        client = self.authenticate(self.employee_a)
        self.post_request(client)
        self.assertFalse(
            Notification.objects.filter(
                company=self.company_b,
                type=NotificationType.LEAVE_SUBMITTED,
            ).exists()
        )
        inbox = self.authenticate(self.manager_b).get(f"{NOTIFICATIONS}/")
        self.assertEqual(inbox.json()["data"]["count"], 0)
