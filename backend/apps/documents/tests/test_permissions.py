from django.test import TestCase

from apps.documents.tests.fixtures import (
    DOCUMENTS,
    DocumentFixtureMixin,
    pdf_file,
    read_download,
)
from apps.employees.tests.fixtures import ids


class DocumentPermissionTests(DocumentFixtureMixin, TestCase):
    def test_employee_sees_only_own_documents(self) -> None:
        own = self.make_document(self.emp_a1, title="Ada CNIC")
        peer = self.make_document(
            self.emp_a2,
            title="Nia CNIC",
            file=pdf_file("nia.pdf"),
        )
        client = self.authenticate(self.employee_a)
        listed = ids(client.get(f"{DOCUMENTS}/"))
        self.assertEqual(listed, {str(own.id)})
        self.assertEqual(client.get(f"{DOCUMENTS}/{own.id}/").status_code, 200)
        self.assertEqual(client.get(f"{DOCUMENTS}/{peer.id}/").status_code, 404)
        self.assertEqual(
            client.get(f"{DOCUMENTS}/{peer.id}/download/").status_code,
            404,
        )
        self.assertEqual(
            client.patch(
                f"{DOCUMENTS}/{peer.id}/",
                {"title": "Nope"},
                format="json",
            ).status_code,
            403,
        )
        self.assertEqual(client.delete(f"{DOCUMENTS}/{peer.id}/").status_code, 403)
        self.assertEqual(
            self.upload(client, self.emp_a2, title="For Nia").status_code,
            404,
        )

    def test_employee_can_upload_and_download_own(self) -> None:
        client = self.authenticate(self.employee_a)
        created = self.upload(client, self.emp_a1, title="My resume")
        self.assertEqual(created.status_code, 200)
        doc_id = created.json()["data"]["id"]
        download = client.get(f"{DOCUMENTS}/{doc_id}/download/")
        self.assertEqual(download.status_code, 200)
        self.assertTrue(read_download(download).startswith(b"%PDF"))
        self.assertEqual(
            client.patch(
                f"{DOCUMENTS}/{doc_id}/",
                {"title": "Edited"},
                format="json",
            ).status_code,
            403,
        )
        self.assertEqual(client.delete(f"{DOCUMENTS}/{doc_id}/").status_code, 403)

    def test_manager_sees_team_not_other_department(self) -> None:
        team = self.make_document(self.emp_a1, title="Report CNIC")
        other = self.make_document(
            self.emp_a2,
            title="HR CNIC",
            file=pdf_file("hr.pdf"),
        )
        client = self.authenticate(self.manager_a)
        listed = ids(client.get(f"{DOCUMENTS}/"))
        self.assertIn(str(team.id), listed)
        self.assertNotIn(str(other.id), listed)
        self.assertEqual(client.get(f"{DOCUMENTS}/{other.id}/").status_code, 404)
        self.assertEqual(
            self.upload(client, self.emp_a1, title="Team contract").status_code,
            200,
        )
        self.assertEqual(
            self.upload(client, self.emp_a2, title="HR contract").status_code,
            404,
        )
        self.assertEqual(client.delete(f"{DOCUMENTS}/{team.id}/").status_code, 403)

    def test_admin_manages_company_documents(self) -> None:
        document = self.make_document(self.emp_a2, title="HR file")
        client = self.authenticate(self.admin_a)
        listed = ids(client.get(f"{DOCUMENTS}/"))
        self.assertIn(str(document.id), listed)
        self.assertEqual(
            client.patch(
                f"{DOCUMENTS}/{document.id}/",
                {"title": "HR file updated"},
                format="json",
            ).status_code,
            200,
        )
        downloaded = client.get(f"{DOCUMENTS}/{document.id}/download/")
        self.assertEqual(downloaded.status_code, 200)
        read_download(downloaded)
        self.assertEqual(client.delete(f"{DOCUMENTS}/{document.id}/").status_code, 200)
        self.assertFalse(
            self.emp_a2.documents.filter(pk=document.id).exists()
        )
