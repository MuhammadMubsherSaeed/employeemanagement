from django.test import TestCase
from rest_framework.test import APIClient

from apps.common.models import AuditEvent
from apps.documents.tests.fixtures import (
    DOCUMENTS,
    DocumentFixtureMixin,
    pdf_file,
    read_download,
)


class DocumentDownloadTests(DocumentFixtureMixin, TestCase):
    def test_authorized_download_returns_file_bytes(self) -> None:
        document = self.make_document(self.emp_a1, title="CNIC", file=pdf_file())
        client = self.authenticate(self.employee_a)
        response = client.get(f"{DOCUMENTS}/{document.id}/download/")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(read_download(response).startswith(b"%PDF"))
        self.assertIn("attachment", response.get("Content-Disposition", "").lower())
        self.assertIn("cnic.pdf", response.get("Content-Disposition", ""))
        self.assertTrue(
            AuditEvent.objects.filter(
                action="document.downloaded",
                resource_id=str(document.id),
            ).exists()
        )

    def test_unauthorized_and_cross_company_downloads(self) -> None:
        own = self.make_document(self.emp_a1, title="Ada")
        peer = self.make_document(self.emp_a2, title="Nia", file=pdf_file("nia.pdf"))
        other = self.make_document(self.emp_b1, title="Bea", file=pdf_file("bea.pdf"))
        employee = self.authenticate(self.employee_a)
        self.assertEqual(
            employee.get(f"{DOCUMENTS}/{peer.id}/download/").status_code,
            404,
        )
        self.assertEqual(
            employee.get(f"{DOCUMENTS}/{other.id}/download/").status_code,
            404,
        )
        admin_a = self.authenticate(self.admin_a)
        self.assertEqual(
            admin_a.get(f"{DOCUMENTS}/{other.id}/download/").status_code,
            404,
        )
        ok = admin_a.get(f"{DOCUMENTS}/{own.id}/download/")
        self.assertEqual(ok.status_code, 200)
        read_download(ok)

    def test_missing_document_and_missing_storage(self) -> None:
        document = self.make_document(self.emp_a1, title="Gone")
        client = self.authenticate(self.admin_a)
        self.assertEqual(
            client.get(
                f"{DOCUMENTS}/00000000-0000-0000-0000-000000000000/download/"
            ).status_code,
            404,
        )
        document.file.delete(save=False)
        missing = client.get(f"{DOCUMENTS}/{document.id}/download/")
        self.assertEqual(missing.status_code, 404)

    def test_unauthenticated_download_is_401(self) -> None:
        document = self.make_document(self.emp_a1, title="Secret")
        response = APIClient().get(f"{DOCUMENTS}/{document.id}/download/")
        self.assertEqual(response.status_code, 401)
