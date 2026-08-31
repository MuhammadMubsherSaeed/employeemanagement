from django.test import TestCase, override_settings

from apps.common.models import AuditEvent
from apps.documents.models import DocumentType, EmployeeDocument, sanitize_file_name
from apps.documents.tests.fixtures import (
    DOCUMENTS,
    DocumentFixtureMixin,
    doc_file,
    docx_file,
    jpeg_alt_file,
    jpeg_file,
    pdf_file,
    png_file,
    uploaded,
)
from apps.employees.tests.fixtures import ids


class DocumentUploadTests(DocumentFixtureMixin, TestCase):
    def test_allowed_types_are_accepted(self) -> None:
        client = self.authenticate(self.admin_a)
        cases = (
            pdf_file(),
            doc_file(),
            docx_file(),
            jpeg_file(),
            jpeg_alt_file(),
            png_file(),
        )
        for upload in cases:
            with self.subTest(name=upload.name):
                response = self.upload(
                    client,
                    self.emp_a1,
                    title=upload.name,
                    file=upload,
                    document_type=DocumentType.OTHER,
                )
                self.assertEqual(response.status_code, 200, response.content)
                data = response.json()["data"]
                self.assertEqual(data["file_name"], upload.name)
                self.assertGreater(data["file_size"], 0)
                self.assertTrue(data["mime_type"])
                self.assertNotIn("file", data)
                self.assertTrue(
                    AuditEvent.objects.filter(
                        action="document.uploaded",
                        resource_id=str(data["id"]),
                    ).exists()
                )

    def test_backend_sets_metadata_and_ignores_client_company(self) -> None:
        client = self.authenticate(self.admin_a)
        response = self.upload(
            client,
            self.emp_a1,
            company_id=str(self.company_b.id),
            uploaded_by=str(self.admin_b.id),
            file_size=1,
            mime_type="application/x-msdownload",
        )
        self.assertEqual(response.status_code, 200)
        row = EmployeeDocument.objects.get(pk=response.json()["data"]["id"])
        self.assertEqual(row.company_id, self.company_a.id)
        self.assertEqual(row.uploaded_by_id, self.admin_a.id)
        self.assertEqual(row.mime_type, "application/pdf")
        self.assertNotEqual(row.file_size, 1)

    def test_rejects_executable_and_mismatched_content(self) -> None:
        client = self.authenticate(self.admin_a)
        exe = self.upload(
            client,
            self.emp_a1,
            file=uploaded("payload.exe", b"MZ", "application/octet-stream"),
        )
        self.assertEqual(exe.status_code, 400)
        spoofed = self.upload(
            client,
            self.emp_a1,
            file=uploaded("not-a-pdf.pdf", b"MZ executable", "application/pdf"),
        )
        self.assertEqual(spoofed.status_code, 400)

    def test_missing_and_oversized_files(self) -> None:
        client = self.authenticate(self.admin_a)
        missing = client.post(
            f"{DOCUMENTS}/",
            {
                "employee_id": str(self.emp_a1.id),
                "document_type": DocumentType.CNIC,
                "title": "No file",
            },
            format="multipart",
        )
        self.assertEqual(missing.status_code, 400)
        with override_settings(MAX_DOCUMENT_UPLOAD_SIZE=40):
            huge = self.upload(
                client,
                self.emp_a1,
                file=uploaded("big.pdf", b"%PDF-1.4 " + b"x" * 80, "application/pdf"),
            )
        self.assertEqual(huge.status_code, 400)

    def test_unsafe_filename_is_sanitized(self) -> None:
        self.assertEqual(sanitize_file_name("../../etc/passwd.pdf"), "passwd.pdf")
        self.assertEqual(sanitize_file_name("a\\b\\cnic.pdf"), "cnic.pdf")
        client = self.authenticate(self.admin_a)
        response = self.upload(
            client,
            self.emp_a1,
            file=uploaded("..\\..\\secret.pdf", pdf_file().read(), "application/pdf"),
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["file_name"], "secret.pdf")
        row = EmployeeDocument.objects.get(pk=response.json()["data"]["id"])
        self.assertNotIn("..", row.file.name)

    def test_search_uses_authorized_fields(self) -> None:
        client = self.authenticate(self.admin_a)
        created = self.upload(client, self.emp_a1, title="Engineering contract")
        self.assertEqual(created.status_code, 200)
        listed = ids(client.get(f"{DOCUMENTS}/?search=Engineering"))
        self.assertIn(created.json()["data"]["id"], listed)
        listed_code = ids(client.get(f"{DOCUMENTS}/?search=EMP-001"))
        self.assertIn(created.json()["data"]["id"], listed_code)
