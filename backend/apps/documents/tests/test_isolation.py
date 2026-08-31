from django.test import TestCase

from apps.documents.models import DocumentType
from apps.documents.tests.fixtures import DOCUMENTS, DocumentFixtureMixin, pdf_file
from apps.employees.tests.fixtures import ids


class DocumentIsolationTests(DocumentFixtureMixin, TestCase):
    def test_company_a_cannot_access_company_b_document(self) -> None:
        doc_a = self.make_document(self.emp_a1, title="Acme CNIC")
        doc_b = self.make_document(
            self.emp_b1,
            title="Beta CNIC",
            file=pdf_file("b.pdf"),
        )
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{DOCUMENTS}/"))
        self.assertIn(str(doc_a.id), listed)
        self.assertNotIn(str(doc_b.id), listed)
        self.assertEqual(client.get(f"{DOCUMENTS}/{doc_b.id}/").status_code, 404)
        self.assertEqual(
            client.patch(
                f"{DOCUMENTS}/{doc_b.id}/",
                {"title": "Hacked"},
                format="json",
            ).status_code,
            404,
        )
        self.assertEqual(client.delete(f"{DOCUMENTS}/{doc_b.id}/").status_code, 404)
        self.assertEqual(
            client.get(f"{DOCUMENTS}/{doc_b.id}/download/").status_code,
            404,
        )
        searched = ids(client.get(f"{DOCUMENTS}/?search=Beta"))
        self.assertNotIn(str(doc_b.id), searched)

    def test_cannot_upload_for_other_company_employee(self) -> None:
        client = self.authenticate(self.admin_a)
        response = self.upload(client, self.emp_b1, title="Cross")
        self.assertIn(response.status_code, (400, 404))
        self.assertFalse(
            self.emp_b1.documents.filter(title="Cross").exists()
        )

    def test_create_ignores_foreign_company_id(self) -> None:
        client = self.authenticate(self.admin_a)
        response = self.upload(
            client,
            self.emp_a1,
            company_id=str(self.company_b.id),
            document_type=DocumentType.CONTRACT,
            title="Offer",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json()["data"]["employee"]["id"],
            str(self.emp_a1.id),
        )
