from unittest.mock import patch

from django.test import TestCase

from apps.audit_logs.constants import AuditAction
from apps.audit_logs.models import AuditLog
from apps.common.storage import StorageDeleteError
from apps.documents.models import DocumentType
from apps.documents.tests.fixtures import (
    DocumentFixtureMixin,
    pdf_file,
    read_download,
    uploaded,
)
from apps.employees.tests.fixtures import ids


def nested(employee_id, document_id=None, action: str = "") -> str:
    base = f"/api/v1/employees/{employee_id}/documents/"
    if document_id is None:
        return base
    path = f"{base}{document_id}/"
    if action:
        return f"{path}{action}/"
    return path


class NestedEmployeeDocumentTests(DocumentFixtureMixin, TestCase):
    def test_list_create_retrieve_download_and_delete(self) -> None:
        client = self.authenticate(self.admin_a)
        created = client.post(
            nested(self.emp_a1.id),
            {
                "document_type": DocumentType.CONTRACT,
                "title": "Offer pack",
                "file": pdf_file("contract.pdf"),
                "employee_id": str(self.emp_b1.id),
                "company_id": str(self.company_b.id),
            },
            format="multipart",
        )
        self.assertEqual(created.status_code, 200, created.content)
        data = created.json()["data"]
        self.assertEqual(data["employee_id"], str(self.emp_a1.id))
        self.assertEqual(data["company_id"], str(self.company_a.id))
        self.assertNotIn("file", data)
        self.assertTrue(
            AuditLog.objects.filter(
                action=AuditAction.DOCUMENT_UPLOADED,
                entity_id=str(data["id"]),
            ).exists()
        )
        listed = ids(client.get(nested(self.emp_a1.id)))
        self.assertIn(data["id"], listed)
        detail = client.get(nested(self.emp_a1.id, data["id"]))
        self.assertEqual(detail.status_code, 200)
        download = client.get(nested(self.emp_a1.id, data["id"], "download"))
        self.assertEqual(download.status_code, 200)
        self.assertTrue(read_download(download).startswith(b"%PDF"))
        access = client.get(nested(self.emp_a1.id, data["id"], "access"))
        self.assertEqual(access.status_code, 200)
        self.assertEqual(access.json()["data"]["mode"], "stream")
        self.assertIsNone(access.json()["data"]["url"])
        deleted = client.delete(nested(self.emp_a1.id, data["id"]))
        self.assertEqual(deleted.status_code, 200)
        self.assertTrue(
            AuditLog.objects.filter(
                action=AuditAction.DOCUMENT_DELETED,
                entity_id=str(data["id"]),
            ).exists()
        )

    def test_cross_company_employee_is_404(self) -> None:
        client = self.authenticate(self.admin_a)
        self.assertEqual(client.get(nested(self.emp_b1.id)).status_code, 404)
        created = client.post(
            nested(self.emp_b1.id),
            {"document_type": DocumentType.CNIC, "file": pdf_file()},
            format="multipart",
        )
        self.assertEqual(created.status_code, 404)

    def test_employee_cannot_use_another_employees_nested_routes(self) -> None:
        document = self.make_document(self.emp_a2, title="Peer")
        client = self.authenticate(self.employee_a)
        self.assertEqual(client.get(nested(self.emp_a2.id)).status_code, 404)
        self.assertEqual(
            client.get(nested(self.emp_a2.id, document.id, "download")).status_code,
            404,
        )

    def test_storage_delete_failure_does_not_drop_the_row(self) -> None:
        document = self.make_document(self.emp_a1, title="Keep")
        client = self.authenticate(self.admin_a)
        with patch(
            "apps.documents.services.get_object_storage"
        ) as factory:
            storage = factory.return_value
            storage.delete.side_effect = StorageDeleteError("denied")
            response = client.delete(nested(self.emp_a1.id, document.id))
        self.assertEqual(response.status_code, 503)
        self.assertTrue(
            document.__class__.objects.filter(pk=document.id).exists()
        )


class DocumentFilterExtensionTests(DocumentFixtureMixin, TestCase):
    def test_uploaded_by_and_created_date_filters(self) -> None:
        own = self.make_document(self.emp_a1, title="Ada file")
        other = self.make_document(
            self.emp_a2,
            title="Nia file",
            uploaded_by=self.admin_a,
        )
        client = self.authenticate(self.admin_a)
        by_uploader = ids(
            client.get(f"/api/v1/documents/?uploaded_by={self.admin_a.id}")
        )
        self.assertIn(str(other.id), by_uploader)
        self.assertNotIn(str(own.id), by_uploader)
        today = own.created_at.date().isoformat()
        window = ids(
            client.get(f"/api/v1/documents/?date_from={today}&date_to={today}")
        )
        self.assertIn(str(own.id), window)


class ExcelUploadTests(DocumentFixtureMixin, TestCase):
    def test_xlsx_is_accepted(self) -> None:
        import zipfile
        from io import BytesIO

        buffer = BytesIO()
        with zipfile.ZipFile(buffer, "w") as archive:
            archive.writestr("[Content_Types].xml", "<Types/>")
            archive.writestr("xl/workbook.xml", "<workbook/>")
        client = self.authenticate(self.admin_a)
        response = self.upload(
            client,
            self.emp_a1,
            document_type=DocumentType.SALARY_DOCUMENT,
            title="Payroll",
            file=uploaded(
                "pay.xlsx",
                buffer.getvalue(),
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            ),
        )
        self.assertEqual(response.status_code, 200, response.content)
        self.assertIn("spreadsheet", response.json()["data"]["mime_type"])
