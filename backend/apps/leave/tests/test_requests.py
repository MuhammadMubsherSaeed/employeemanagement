from datetime import date
from tempfile import TemporaryDirectory

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings

from apps.employees.tests.fixtures import ids
from apps.leave.models import LeaveRequest, LeaveRequestStatus
from apps.leave.tests.fixtures import REQUESTS, TODAY, LeaveFixtureMixin, freeze_leave_today


class LeaveRequestCreateTests(LeaveFixtureMixin, TestCase):
    def test_employee_creates_own_request(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(client)
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["status"], LeaveRequestStatus.PENDING)
        self.assertEqual(data["total_days"], 1)
        self.assertEqual(data["employee"]["id"], str(self.emp_a1.id))
        row = LeaveRequest.objects.get(pk=data["id"])
        self.assertEqual(row.company_id, self.company_a.id)
        self.assertIsNone(row.approved_by_id)

    def test_employee_cannot_create_for_another_employee(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(
            client,
            {
                "employee": str(self.emp_a2.id),
                "employee_id": str(self.emp_a2.id),
            },
        )
        self.assertEqual(response.status_code, 200)
        row = LeaveRequest.objects.get(pk=response.json()["data"]["id"])
        self.assertEqual(row.employee_id, self.emp_a1.id)

    def test_company_and_server_fields_cannot_be_set(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(
            client,
            {
                "company": str(self.company_b.id),
                "company_id": str(self.company_b.id),
                "status": LeaveRequestStatus.APPROVED,
                "total_days": 99,
                "approved_by": str(self.admin_a.id),
            },
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["status"], LeaveRequestStatus.PENDING)
        self.assertEqual(data["total_days"], 1)
        self.assertIsNone(data["approved_by"])
        row = LeaveRequest.objects.get(pk=data["id"])
        self.assertEqual(row.company_id, self.company_a.id)

    def test_inactive_leave_type_rejected(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(
            client, {"leave_type": str(self.type_a_sick.id)}
        )
        self.assertEqual(response.status_code, 400)

    def test_other_company_leave_type_rejected(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(
            client, {"leave_type": str(self.type_b.id)}
        )
        self.assertEqual(response.status_code, 400)

    def test_end_before_start_rejected(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(
            client,
            {
                "start_date": "2026-03-20",
                "end_date": "2026-03-16",
            },
        )
        self.assertEqual(response.status_code, 400)

    def test_past_dates_rejected(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(
            client,
            {
                "start_date": "2026-03-15",
                "end_date": "2026-03-16",
            },
        )
        self.assertEqual(response.status_code, 400)

    def test_zero_working_days_rejected(self) -> None:
        client = self.authenticate(self.employee_a)
        response = self.post_request(
            client,
            {
                "start_date": "2026-03-21",
                "end_date": "2026-03-22",
            },
        )
        self.assertEqual(response.status_code, 400)

    def test_multi_year_rejected(self) -> None:
        client = self.authenticate(self.employee_a)
        with freeze_leave_today(date(2026, 12, 30)):
            response = client.post(
                f"{REQUESTS}/",
                {
                    "leave_type": str(self.type_a.id),
                    "start_date": "2026-12-30",
                    "end_date": "2027-01-02",
                    "reason": "Year wrap",
                },
                format="json",
            )
        self.assertEqual(response.status_code, 400)

    def test_total_days_excludes_weekend_and_holiday(self) -> None:
        from apps.attendance.models import Holiday

        Holiday.objects.create(
            company=self.company_a, name="Break", date="2026-03-18"
        )
        client = self.authenticate(self.employee_a)
        response = self.post_request(
            client,
            {
                "start_date": "2026-03-16",
                "end_date": "2026-03-20",
            },
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["total_days"], 4)

    def test_employee_lists_only_own_requests(self) -> None:
        own = self.pending_request()
        other = self.pending_request(employee=self.emp_a2, start=date(2026, 3, 17), end=date(2026, 3, 17))
        foreign = self.pending_request(
            employee=self.emp_b1, leave_type=self.type_b
        )
        client = self.authenticate(self.employee_a)
        listed = ids(client.get(f"{REQUESTS}/"))
        self.assertEqual(listed, {str(own.id)})
        self.assertEqual(client.get(f"{REQUESTS}/{own.id}/").status_code, 200)
        self.assertEqual(client.get(f"{REQUESTS}/{other.id}/").status_code, 404)
        self.assertEqual(client.get(f"{REQUESTS}/{foreign.id}/").status_code, 404)

    def test_status_and_date_filters(self) -> None:
        pending = self.pending_request()
        approved = self.pending_request(
            start=date(2026, 3, 19),
            end=date(2026, 3, 19),
            status=LeaveRequestStatus.APPROVED,
        )
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{REQUESTS}/?status=PENDING"))
        self.assertIn(str(pending.id), listed)
        self.assertNotIn(str(approved.id), listed)
        ranged = ids(
            client.get(f"{REQUESTS}/?start_date=2026-03-19&end_date=2026-03-19")
        )
        self.assertEqual(ranged, {str(approved.id)})


class OverlapTests(LeaveFixtureMixin, TestCase):
    def _create(self, client, start: str, end: str):
        return self.post_request(
            client, {"start_date": start, "end_date": end}
        )

    def test_exact_overlap_rejected(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(self._create(client, "2026-03-16", "2026-03-18").status_code, 200)
        response = self._create(client, "2026-03-16", "2026-03-18")
        self.assertEqual(response.status_code, 400)

    def test_partial_overlap_at_start_and_end(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(self._create(client, "2026-03-17", "2026-03-19").status_code, 200)
        self.assertEqual(self._create(client, "2026-03-16", "2026-03-17").status_code, 400)
        self.assertEqual(self._create(client, "2026-03-19", "2026-03-20").status_code, 400)

    def test_containing_and_contained_ranges(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(self._create(client, "2026-03-17", "2026-03-18").status_code, 200)
        self.assertEqual(self._create(client, "2026-03-16", "2026-03-20").status_code, 400)
        self.pending_request(
            employee=self.emp_a2,
            start=date(2026, 3, 16),
            end=date(2026, 3, 20),
            total_days=5,
        )
        other = self.authenticate(self.employee_a2)
        self.assertEqual(self._create(other, "2026-03-17", "2026-03-18").status_code, 400)

    def test_adjacent_dates_allowed(self) -> None:
        client = self.authenticate(self.employee_a)
        self.assertEqual(self._create(client, "2026-03-16", "2026-03-17").status_code, 200)
        self.assertEqual(self._create(client, "2026-03-18", "2026-03-19").status_code, 200)

    def test_rejected_and_cancelled_do_not_block(self) -> None:
        self.pending_request(
            start=date(2026, 3, 16),
            end=date(2026, 3, 18),
            total_days=3,
            status=LeaveRequestStatus.REJECTED,
        )
        self.pending_request(
            employee=self.emp_a1,
            start=date(2026, 3, 16),
            end=date(2026, 3, 18),
            total_days=3,
            status=LeaveRequestStatus.CANCELLED,
        )
        client = self.authenticate(self.employee_a)
        self.assertEqual(self._create(client, "2026-03-16", "2026-03-18").status_code, 200)

    def test_cross_company_requests_do_not_conflict(self) -> None:
        self.pending_request(
            employee=self.emp_b1,
            leave_type=self.type_b,
            start=date(2026, 3, 16),
            end=date(2026, 3, 20),
            total_days=5,
            status=LeaveRequestStatus.APPROVED,
        )
        client = self.authenticate(self.employee_a)
        self.assertEqual(self._create(client, "2026-03-16", "2026-03-20").status_code, 200)


class AttachmentTests(LeaveFixtureMixin, TestCase):
    def test_pdf_attachment_accepted(self) -> None:
        client = self.authenticate(self.employee_a)
        upload = SimpleUploadedFile(
            "note.pdf", b"%PDF-1.4 test", content_type="application/pdf"
        )
        with TemporaryDirectory() as media:
            with override_settings(MEDIA_ROOT=media):
                with freeze_leave_today():
                    response = client.post(
                        f"{REQUESTS}/",
                        {
                            "leave_type": str(self.type_a.id),
                            "start_date": TODAY.isoformat(),
                            "end_date": TODAY.isoformat(),
                            "reason": "With file",
                            "attachment": upload,
                        },
                        format="multipart",
                    )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["data"]["attachment"])

    def test_executable_attachment_rejected(self) -> None:
        client = self.authenticate(self.employee_a)
        upload = SimpleUploadedFile(
            "payload.exe", b"MZ", content_type="application/octet-stream"
        )
        with TemporaryDirectory() as media:
            with override_settings(MEDIA_ROOT=media):
                with freeze_leave_today():
                    response = client.post(
                        f"{REQUESTS}/",
                        {
                            "leave_type": str(self.type_a.id),
                            "start_date": TODAY.isoformat(),
                            "end_date": TODAY.isoformat(),
                            "attachment": upload,
                        },
                        format="multipart",
                    )
        self.assertEqual(response.status_code, 400)
