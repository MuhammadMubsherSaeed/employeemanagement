from apps.companies.models import RecordVisibility, TenantOwnedRecord
from apps.companies.tests.fixtures import TENANCY, TenancyAPITestCase


class CrossCompanyIsolationTests(TenancyAPITestCase):
    def test_company_a_cannot_read_company_b_record(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(f"{TENANCY}/records/{self.record_b.id}/")
        self.assertEqual(response.status_code, 404)

    def test_company_a_cannot_patch_company_b_record(self) -> None:
        client = self.authenticate(self.manager_a)
        response = client.patch(
            f"{TENANCY}/records/{self.record_b.id}/",
            {"title": "hacked"},
            format="json",
        )
        self.assertEqual(response.status_code, 404)
        self.record_b.refresh_from_db()
        self.assertEqual(self.record_b.title, "Beta public")

    def test_company_a_cannot_put_company_b_record(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.put(
            f"{TENANCY}/records/{self.record_b.id}/",
            {"title": "hacked", "visibility": RecordVisibility.COMPANY},
            format="json",
        )
        self.assertEqual(response.status_code, 404)

    def test_company_a_cannot_delete_company_b_record(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.delete(f"{TENANCY}/records/{self.record_b.id}/")
        self.assertEqual(response.status_code, 404)
        self.assertTrue(
            TenantOwnedRecord.objects.filter(pk=self.record_b.pk).exists()
        )

    def test_payload_cannot_override_tenant_on_create(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{TENANCY}/records/",
            {
                "title": "Should stay in Acme",
                "visibility": RecordVisibility.COMPANY,
                "company": str(self.company_b.id),
                "company_id": str(self.company_b.id),
            },
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        created = TenantOwnedRecord.objects.get(title="Should stay in Acme")
        self.assertEqual(created.company_id, self.company_a.id)

    def test_cannot_assign_user_from_another_company(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.post(
            f"{TENANCY}/records/",
            {
                "title": "Bad assignment",
                "visibility": RecordVisibility.COMPANY,
                "assigned_to": self.employee_b.id,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_list_does_not_include_other_company_rows(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(f"{TENANCY}/records/")
        self.assertEqual(response.status_code, 200)
        titles = {row["title"] for row in response.json()["data"]}
        self.assertIn("Acme public", titles)
        self.assertNotIn("Beta public", titles)
        self.assertNotIn("Employee B private", titles)
