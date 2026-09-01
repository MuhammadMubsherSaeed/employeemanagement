from tempfile import TemporaryDirectory

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings

from apps.audit_logs.constants import AuditAction
from apps.audit_logs.models import AuditLog
from apps.documents.tests.fixtures import read_download
from apps.leave.models import LeaveRequest
from apps.leave.tests.fixtures import REQUESTS, TODAY, LeaveFixtureMixin, freeze_leave_today


class LeaveAttachmentDownloadTests(LeaveFixtureMixin, TestCase):
    def test_upload_download_is_private_and_audited(self) -> None:
        client = self.authenticate(self.employee_a)
        upload = SimpleUploadedFile(
            "note.pdf", b"%PDF-1.4 test", content_type="application/pdf"
        )
        with TemporaryDirectory() as media:
            with override_settings(MEDIA_ROOT=media, STORAGE_BACKEND="local"):
                with freeze_leave_today():
                    created = client.post(
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
                self.assertEqual(created.status_code, 200, created.content)
                data = created.json()["data"]
                self.assertTrue(data["attachment"])
                self.assertNotIn("/media/", str(data["attachment"]))
                request_id = data["id"]
                row = LeaveRequest.objects.get(pk=request_id)
                self.assertIn("companies/", row.attachment.name)
                self.assertIn("/leave/", row.attachment.name)
                self.assertTrue(
                    AuditLog.objects.filter(
                        action=AuditAction.LEAVE_ATTACHMENT_UPLOADED,
                        entity_id=str(request_id),
                    ).exists()
                )
                downloaded = client.get(f"{REQUESTS}/{request_id}/attachment/")
                self.assertEqual(downloaded.status_code, 200)
                self.assertTrue(read_download(downloaded).startswith(b"%PDF"))
                deleted = client.delete(f"{REQUESTS}/{request_id}/attachment/")
                self.assertEqual(deleted.status_code, 200)
                self.assertIsNone(deleted.json()["data"]["attachment"])
                self.assertTrue(
                    AuditLog.objects.filter(
                        action=AuditAction.LEAVE_ATTACHMENT_DELETED,
                        entity_id=str(request_id),
                    ).exists()
                )

    def test_cross_company_attachment_is_404(self) -> None:
        client = self.authenticate(self.employee_a)
        upload = SimpleUploadedFile(
            "note.pdf", b"%PDF-1.4 test", content_type="application/pdf"
        )
        with TemporaryDirectory() as media:
            with override_settings(MEDIA_ROOT=media):
                with freeze_leave_today():
                    created = client.post(
                        f"{REQUESTS}/",
                        {
                            "leave_type": str(self.type_a.id),
                            "start_date": TODAY.isoformat(),
                            "end_date": TODAY.isoformat(),
                            "attachment": upload,
                        },
                        format="multipart",
                    )
                request_id = created.json()["data"]["id"]
                other = self.authenticate(self.admin_b)
                self.assertEqual(
                    other.get(f"{REQUESTS}/{request_id}/attachment/").status_code,
                    404,
                )

    def test_mismatched_pdf_content_rejected(self) -> None:
        client = self.authenticate(self.employee_a)
        upload = SimpleUploadedFile(
            "note.pdf", b"MZ executable", content_type="application/pdf"
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
