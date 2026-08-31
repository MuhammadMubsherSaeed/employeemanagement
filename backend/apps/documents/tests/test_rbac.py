from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import Permission, UserRole
from apps.documents.tests.fixtures import DOCUMENTS, DocumentFixtureMixin


class DocumentRbacTests(DocumentFixtureMixin, TestCase):
    def _drop(self, role_code: str, permission_code: str) -> None:
        permission = Permission.objects.get(code=permission_code)
        self.roles[role_code].permissions.remove(permission)

    def test_unauthenticated_requests_are_401(self) -> None:
        client = APIClient()
        self.assertEqual(client.get(f"{DOCUMENTS}/").status_code, 401)
        self.assertEqual(self.upload(client, self.emp_a1).status_code, 401)

    def test_missing_view_create_update_delete_and_download(self) -> None:
        document = self.make_document(self.emp_a1, title="Locked")
        self._drop(UserRole.EMPLOYEE, "documents.view")
        employee = self.authenticate(self.employee_a)
        self.assertEqual(employee.get(f"{DOCUMENTS}/").status_code, 403)
        self.assertEqual(employee.get(f"{DOCUMENTS}/{document.id}/").status_code, 403)

        self._drop(UserRole.EMPLOYEE, "documents.create")
        self.assertEqual(self.upload(employee, self.emp_a1).status_code, 403)

        self._drop(UserRole.EMPLOYEE, "documents.download")
        self.assertEqual(
            employee.get(f"{DOCUMENTS}/{document.id}/download/").status_code,
            403,
        )

        self._drop(UserRole.MANAGER, "documents.update")
        manager = self.authenticate(self.manager_a)
        self.assertEqual(
            manager.patch(
                f"{DOCUMENTS}/{document.id}/",
                {"title": "Nope"},
                format="json",
            ).status_code,
            403,
        )

        self._drop(UserRole.COMPANY_ADMIN, "documents.delete")
        admin = self.authenticate(self.admin_a)
        self.assertEqual(admin.delete(f"{DOCUMENTS}/{document.id}/").status_code, 403)

    def test_seeded_role_bindings(self) -> None:
        employee_codes = set(
            self.roles[UserRole.EMPLOYEE].permissions.values_list("code", flat=True)
        )
        manager_codes = set(
            self.roles[UserRole.MANAGER].permissions.values_list("code", flat=True)
        )
        admin_codes = set(
            self.roles[UserRole.COMPANY_ADMIN].permissions.values_list(
                "code",
                flat=True,
            )
        )
        self.assertTrue(
            {"documents.view", "documents.create", "documents.download"}.issubset(
                employee_codes
            )
        )
        self.assertFalse("documents.update" in employee_codes)
        self.assertFalse("documents.delete" in employee_codes)
        self.assertTrue(
            {
                "documents.view",
                "documents.create",
                "documents.update",
                "documents.download",
            }.issubset(manager_codes)
        )
        self.assertFalse("documents.delete" in manager_codes)
        self.assertTrue(
            {
                "documents.view",
                "documents.create",
                "documents.update",
                "documents.delete",
                "documents.download",
            }.issubset(admin_codes)
        )
