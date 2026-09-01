from datetime import timedelta

from django.core.exceptions import ValidationError
from django.test import TestCase
from django.utils import timezone

from apps.documents.models import DocumentStatus, DocumentType, EmployeeDocument
from apps.documents.tests.fixtures import DocumentFixtureMixin, pdf_file


class DocumentModelTests(DocumentFixtureMixin, TestCase):
    def test_creates_metadata_and_company_from_employee(self) -> None:
        document = self.make_document(self.emp_a1, title="  Passport copy  ")
        self.assertEqual(document.company_id, self.company_a.id)
        self.assertEqual(document.employee_id, self.emp_a1.id)
        self.assertEqual(document.title, "Passport copy")
        self.assertEqual(document.document_type, DocumentType.CNIC)
        self.assertEqual(document.status, DocumentStatus.ACTIVE)
        self.assertEqual(document.file_name, "cnic.pdf")
        self.assertGreater(document.file_size, 0)
        self.assertEqual(document.mime_type, "application/pdf")
        self.assertEqual(document.uploaded_by_id, self.emp_a1.user_id)
        self.assertIsNotNone(document.created_at)
        self.assertIsNotNone(document.updated_at)
        self.assertFalse(document.file.name.startswith("cnic"))
        self.assertTrue(document.file.name.startswith("companies/"))
        self.assertIn("/documents/", document.file.name)
        self.assertIn(str(self.company_a.id), document.file.name)
        self.assertIn(str(self.emp_a1.id), document.file.name)

    def test_expiry_may_be_null_or_set(self) -> None:
        open_ended = self.make_document(self.emp_a1, title="Resume")
        self.assertIsNone(open_ended.expiry_date)
        dated = self.make_document(
            self.emp_a1,
            title="Visa",
            document_type=DocumentType.PASSPORT,
            expiry_date=timezone.localdate() + timedelta(days=30),
            file=pdf_file("visa.pdf"),
        )
        self.assertEqual(
            dated.expiry_date, timezone.localdate() + timedelta(days=30)
        )

    def test_expired_status_requires_past_expiry_date(self) -> None:
        with self.assertRaises(ValidationError):
            self.make_document(
                self.emp_a1,
                title="Expired without date",
                status=DocumentStatus.EXPIRED,
            )
        with self.assertRaises(ValidationError):
            self.make_document(
                self.emp_a1,
                title="Expired future",
                status=DocumentStatus.EXPIRED,
                expiry_date=timezone.localdate() + timedelta(days=1),
                file=pdf_file("future.pdf"),
            )
        document = self.make_document(
            self.emp_a1,
            title="Expired ok",
            status=DocumentStatus.EXPIRED,
            expiry_date=timezone.localdate() - timedelta(days=1),
            file=pdf_file("old.pdf"),
        )
        self.assertEqual(document.status, DocumentStatus.EXPIRED)

    def test_employee_must_belong_to_same_company(self) -> None:
        with self.assertRaises(ValidationError):
            EmployeeDocument.objects.create(
                company=self.company_a,
                employee=self.emp_b1,
                document_type=DocumentType.OTHER,
                title="Cross",
                uploaded_by=self.admin_a,
                file=pdf_file("cross.pdf"),
            )

    def test_document_type_and_status_choices(self) -> None:
        self.assertIn(DocumentType.CERTIFICATE, DocumentType.values)
        self.assertIn(DocumentType.SALARY_DOCUMENT, DocumentType.values)
        self.assertIn(DocumentType.CNIC, DocumentType.values)
        self.assertIn(DocumentType.OTHER, DocumentType.values)
        self.assertEqual(
            set(DocumentStatus.values),
            {DocumentStatus.ACTIVE, DocumentStatus.EXPIRED, DocumentStatus.ARCHIVED},
        )
