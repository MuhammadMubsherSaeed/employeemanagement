from datetime import date, timedelta

from django.test import TestCase

from apps.documents.models import DocumentStatus, DocumentType
from apps.documents.tests.fixtures import DOCUMENTS, DocumentFixtureMixin, pdf_file
from apps.employees.tests.fixtures import ids


class DocumentFilterTests(DocumentFixtureMixin, TestCase):
    def setUp(self) -> None:
        super().setUp()
        self.today = date.today()
        self.cnic = self.make_document(
            self.emp_a1,
            title="Ada CNIC",
            document_type=DocumentType.CNIC,
            file=pdf_file("ada-cnic.pdf"),
        )
        self.passport = self.make_document(
            self.emp_a1,
            title="Ada passport",
            document_type=DocumentType.PASSPORT,
            expiry_date=self.today + timedelta(days=10),
            file=pdf_file("ada-passport.pdf"),
        )
        self.hr_contract = self.make_document(
            self.emp_a2,
            title="Nia contract",
            document_type=DocumentType.CONTRACT,
            status=DocumentStatus.ARCHIVED,
            file=pdf_file("nia-contract.pdf"),
        )
        self.old_visa = self.make_document(
            self.emp_a2,
            title="Expired visa",
            document_type=DocumentType.PASSPORT,
            expiry_date=self.today - timedelta(days=3),
            file=pdf_file("old-visa.pdf"),
        )
        self.other_company = self.make_document(
            self.emp_b1,
            title="Ada CNIC",
            file=pdf_file("beta.pdf"),
        )

    def test_employee_type_status_and_search(self) -> None:
        client = self.authenticate(self.admin_a)
        by_employee = ids(client.get(f"{DOCUMENTS}/?employee={self.emp_a1.id}"))
        self.assertEqual(by_employee, {str(self.cnic.id), str(self.passport.id)})
        by_type = ids(
            client.get(f"{DOCUMENTS}/?document_type={DocumentType.CONTRACT}")
        )
        self.assertEqual(by_type, {str(self.hr_contract.id)})
        archived = ids(client.get(f"{DOCUMENTS}/?status={DocumentStatus.ARCHIVED}"))
        self.assertEqual(archived, {str(self.hr_contract.id)})
        searched = ids(client.get(f"{DOCUMENTS}/?search=passport"))
        self.assertIn(str(self.passport.id), searched)
        searched_code = ids(client.get(f"{DOCUMENTS}/?search=EMP-002"))
        self.assertIn(str(self.hr_contract.id), searched_code)
        searched_name = ids(client.get(f"{DOCUMENTS}/?search=Nia"))
        self.assertIn(str(self.hr_contract.id), searched_name)

    def test_expiry_filters(self) -> None:
        client = self.authenticate(self.admin_a)
        expired = ids(client.get(f"{DOCUMENTS}/?expired=true"))
        self.assertEqual(expired, {str(self.old_visa.id)})
        soon = ids(client.get(f"{DOCUMENTS}/?expiring_soon=true"))
        self.assertEqual(soon, {str(self.passport.id)})
        window = ids(
            client.get(
                f"{DOCUMENTS}/?expiry_date_from={self.today.isoformat()}"
                f"&expiry_date_to={(self.today + timedelta(days=15)).isoformat()}"
            )
        )
        self.assertEqual(window, {str(self.passport.id)})

    def test_ordering_and_pagination_stay_tenant_scoped(self) -> None:
        client = self.authenticate(self.admin_a)
        page = client.get(f"{DOCUMENTS}/?ordering=title&page_size=2")
        self.assertEqual(page.status_code, 200)
        payload = page.json()["data"]
        self.assertEqual(payload["count"], 4)
        titles = [row["title"] for row in payload["results"]]
        self.assertEqual(titles, ["Ada CNIC", "Ada passport"])
        listed = ids(client.get(f"{DOCUMENTS}/?search=Ada"))
        self.assertNotIn(str(self.other_company.id), listed)

    def test_employee_cannot_filter_to_a_peer(self) -> None:
        client = self.authenticate(self.employee_a)
        listed = ids(client.get(f"{DOCUMENTS}/?employee={self.emp_a2.id}"))
        self.assertEqual(listed, {str(self.cnic.id), str(self.passport.id)})
        self.assertNotIn(str(self.hr_contract.id), listed)
