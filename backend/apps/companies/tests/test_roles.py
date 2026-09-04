from apps.accounts.models import UserRole
from apps.companies.models import CompanyMembership, RecordVisibility
from apps.companies.services import MembershipService
from apps.companies.tests.fixtures import PASSWORD, TENANCY, TenancyAPITestCase, User


class RoleAuthorizationTests(TenancyAPITestCase):
    def test_company_admin_can_manage_own_company_not_another(self) -> None:
        client = self.authenticate(self.admin_a)
        own = client.get(f"{TENANCY}/records/{self.record_a.id}/")
        other = client.get(f"{TENANCY}/records/{self.record_b.id}/")
        settings = client.get(f"{TENANCY}/settings/")
        platform = client.get(f"{TENANCY}/platform/")
        self.assertEqual(own.status_code, 200)
        self.assertEqual(other.status_code, 404)
        self.assertEqual(settings.status_code, 200)
        self.assertEqual(platform.status_code, 403)

    def test_manager_cannot_manage_settings_or_other_private_data(self) -> None:
        client = self.authenticate(self.manager_a)
        settings = client.get(f"{TENANCY}/settings/")
        patch = client.patch(
            f"{TENANCY}/settings/",
            {"timezone": "UTC"},
            format="json",
        )
        private = client.get(f"{TENANCY}/records/{self.private_a.id}/")
        company_row = client.get(f"{TENANCY}/records/{self.record_a.id}/")
        create = client.post(
            f"{TENANCY}/records/",
            {"title": "nope", "visibility": RecordVisibility.COMPANY},
            format="json",
        )
        self.assertEqual(settings.status_code, 200)
        self.assertEqual(patch.status_code, 403)
        self.assertEqual(private.status_code, 404)
        self.assertEqual(company_row.status_code, 200)
        self.assertEqual(create.status_code, 403)

    def test_employee_is_limited_to_own_private_records(self) -> None:
        client = self.authenticate(self.employee_a)
        own_private = client.get(f"{TENANCY}/records/{self.private_a.id}/")
        other_private = client.get(f"{TENANCY}/records/{self.private_b.id}/")
        company_row = client.get(f"{TENANCY}/records/{self.record_a.id}/")
        delete = client.delete(f"{TENANCY}/records/{self.record_a.id}/")
        self.assertEqual(own_private.status_code, 200)
        self.assertEqual(other_private.status_code, 404)
        self.assertEqual(company_row.status_code, 200)
        self.assertEqual(delete.status_code, 403)

    def test_super_admin_reaches_platform_scope(self) -> None:
        client = self.authenticate(self.super_admin)
        platform = client.get(f"{TENANCY}/platform/")
        settings = client.get(f"{TENANCY}/settings/")
        record = client.get(f"{TENANCY}/records/{self.record_b.id}/")
        self.assertEqual(platform.status_code, 200)
        self.assertEqual(settings.json()["data"]["scope"], "PLATFORM")
        self.assertEqual(record.status_code, 200)

    def test_query_params_cannot_impersonate_super_admin(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(
            f"{TENANCY}/platform/",
            {"role": UserRole.SUPER_ADMIN, "is_superuser": "true"},
        )
        self.assertEqual(response.status_code, 403)

    def test_me_exposes_company_context(self) -> None:
        client = self.authenticate(self.employee_a)
        response = client.get("/api/v1/auth/me/")
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["role"], UserRole.EMPLOYEE)
        self.assertEqual(data["company"]["slug"], "acme")
        self.assertNotIn("memberships", data)
        permissions = data["permissions"]
        self.assertIn("employees.view", permissions)
        self.assertIn("leave.create", permissions)
        self.assertNotIn("employees.delete", permissions)
        self.assertNotIn("settings.manage", permissions)

    def test_me_for_super_admin_has_no_company(self) -> None:
        from apps.accounts.rbac_catalog import PERMISSION_CODES

        client = self.authenticate(self.super_admin)
        data = client.get("/api/v1/auth/me/").json()["data"]
        self.assertEqual(data["role"], UserRole.SUPER_ADMIN)
        self.assertIsNone(data["company"])
        self.assertEqual(data["permissions"], list(PERMISSION_CODES))

    def test_profile_update_is_not_exposed(self) -> None:
        client = self.authenticate(self.employee_a)
        response = client.patch(
            "/api/v1/auth/me/",
            {"role": UserRole.SUPER_ADMIN},
            format="json",
        )
        self.assertEqual(response.status_code, 405)
        self.employee_a.refresh_from_db()
        self.assertEqual(self.employee_a.role, UserRole.EMPLOYEE)

    def test_user_without_membership_cannot_list_records(self) -> None:
        client = self.authenticate(self.no_company)
        response = client.get(f"{TENANCY}/records/")
        self.assertEqual(response.status_code, 403)

    def test_inactive_membership_cannot_access_company_resources(self) -> None:
        membership = CompanyMembership.objects.get(
            user=self.employee_a, company=self.company_a
        )
        MembershipService().deactivate(membership)
        client = self.authenticate(self.employee_a)
        response = client.get(f"{TENANCY}/records/")
        self.assertEqual(response.status_code, 403)

    def test_inactive_company_blocks_normal_users(self) -> None:
        user = User.objects.create_user(
            email="idle-api@example.com",
            password=PASSWORD,
            role=UserRole.EMPLOYEE,
        )
        MembershipService().assign(
            user=user,
            company=self.inactive_company,
            role=self.roles[UserRole.EMPLOYEE],
        )
        client = self.authenticate(user)
        response = client.get(f"{TENANCY}/records/")
        self.assertEqual(response.status_code, 403)
