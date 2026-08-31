from datetime import date, timedelta

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase

from apps.common.models import AuditEvent
from apps.documents.models import DocumentStatus, DocumentType, EmployeeDocument
from apps.documents.tests.fixtures import (
    DOCUMENTS,
    DocumentFixtureMixin,
    pdf_file,
    png_file,
)


class DocumentCrudTests(DocumentFixtureMixin, TestCase):
    def test_list_detail_update_and_replace(self) -> None:
        client = self.authenticate(self.admin_a)
        created = self.upload(
            client,
            self.emp_a1,
            title="Offer letter",
            document_type=DocumentType.OFFER_LETTER,
            description="Signed copy",
            expiry_date=self.next_week(),
        )
        self.assertEqual(created.status_code, 200)
        doc_id = created.json()["data"]["id"]
        detail = client.get(f"{DOCUMENTS}/{doc_id}/")
        self.assertEqual(detail.status_code, 200)
        self.assertEqual(detail.json()["data"]["title"], "Offer letter")
        self.assertNotIn("file", detail.json()["data"])
        put = client.put(
            f"{DOCUMENTS}/{doc_id}/",
            {
                "title": "Offer letter signed",
                "description": "Countersigned",
                "document_type": DocumentType.CONTRACT,
                "expiry_date": self.next_week(),
                "status": DocumentStatus.ACTIVE,
            },
            format="json",
        )
        self.assertEqual(put.status_code, 200)
        self.assertEqual(put.json()["data"]["document_type"], DocumentType.CONTRACT)
        with self.captureOnCommitCallbacks(execute=True):
            patch = client.patch(
                f"{DOCUMENTS}/{doc_id}/",
                {"file": png_file("replacement.png")},
                format="multipart",
            )
        self.assertEqual(patch.status_code, 200)
        self.assertEqual(patch.json()["data"]["file_name"], "replacement.png")
        self.assertEqual(patch.json()["data"]["mime_type"], "image/png")
        self.assertTrue(
            AuditEvent.objects.filter(
                action="document.replaced",
                resource_id=doc_id,
            ).exists()
        )

    def test_invalid_replacement_does_not_clear_existing_file(self) -> None:
        document = self.make_document(self.emp_a1, title="Keep me")
        original = document.file.name
        client = self.authenticate(self.admin_a)
        response = client.patch(
            f"{DOCUMENTS}/{document.id}/",
            {
                "file": SimpleUploadedFile(
                    "x.exe",
                    b"MZ",
                    content_type="application/octet-stream",
                )
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, 400)
        document.refresh_from_db()
        self.assertEqual(document.file.name, original)
        self.assertEqual(document.title, "Keep me")

    def test_status_archive_and_expired_rules(self) -> None:
        document = self.make_document(self.emp_a1, title="Contract")
        client = self.authenticate(self.admin_a)
        expired = client.patch(
            f"{DOCUMENTS}/{document.id}/",
            {"status": DocumentStatus.EXPIRED},
            format="json",
        )
        self.assertEqual(expired.status_code, 400)
        past = date.today() - timedelta(days=2)
        client.patch(
            f"{DOCUMENTS}/{document.id}/",
            {"expiry_date": past.isoformat()},
            format="json",
        )
        ok = client.patch(
            f"{DOCUMENTS}/{document.id}/",
            {"status": DocumentStatus.EXPIRED},
            format="json",
        )
        self.assertEqual(ok.status_code, 200)
        archived = client.patch(
            f"{DOCUMENTS}/{document.id}/",
            {"status": DocumentStatus.ARCHIVED},
            format="json",
        )
        self.assertEqual(archived.status_code, 200)
        self.assertTrue(
            AuditEvent.objects.filter(
                action="document.archived",
                resource_id=str(document.id),
            ).exists()
        )

    def test_delete_removes_row_and_writes_audit(self) -> None:
        document = self.make_document(self.emp_a1, title="To delete")
        path = document.file.name
        storage = document.file.storage
        client = self.authenticate(self.admin_a)
        with self.captureOnCommitCallbacks(execute=True):
            response = client.delete(f"{DOCUMENTS}/{document.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertFalse(EmployeeDocument.objects.filter(pk=document.id).exists())
        self.assertFalse(storage.exists(path))
        self.assertTrue(
            AuditEvent.objects.filter(
                action="document.deleted",
                resource_id=str(document.id),
            ).exists()
        )

    def test_pagination_ordering(self) -> None:
        client = self.authenticate(self.admin_a)
        self.upload(client, self.emp_a1, title="Alpha", file=pdf_file("a.pdf"))
        self.upload(client, self.emp_a1, title="Zulu", file=pdf_file("z.pdf"))
        page = client.get(f"{DOCUMENTS}/?page_size=1&ordering=title")
        self.assertEqual(page.status_code, 200)
        payload = page.json()["data"]
        self.assertEqual(payload["count"], 2)
        self.assertEqual(payload["results"][0]["title"], "Alpha")
        self.assertIsNotNone(payload["next"])
