from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import Role, RoleScope, UserRole
from apps.companies.models import Company, RecordVisibility, TenantOwnedRecord
from apps.companies.services import MembershipService

User = get_user_model()
TENANCY = "/api/v1/tenancy"
PASSWORD = "a-strong-password-123"


class TenancyFixtureMixin:
    @classmethod
    def setUpTestData(cls) -> None:
        call_command("seed_rbac", verbosity=0)
        cls.roles = {
            role.code: role
            for role in Role.objects.filter(scope=RoleScope.COMPANY)
        }
        cls.company_a = Company.objects.create(name="Acme", slug="acme")
        cls.company_b = Company.objects.create(name="Beta", slug="beta")
        cls.inactive_company = Company.objects.create(
            name="Idle Co",
            slug="idle",
            is_active=False,
        )
        service = MembershipService()
        cls.admin_a = cls._member("admin-a@example.com", UserRole.COMPANY_ADMIN)
        cls.manager_a = cls._member("manager-a@example.com", UserRole.MANAGER)
        cls.employee_a = cls._member("employee-a@example.com", UserRole.EMPLOYEE)
        cls.admin_b = cls._member(
            "admin-b@example.com", UserRole.COMPANY_ADMIN
        )
        cls.manager_b = cls._member("manager-b@example.com", UserRole.MANAGER)
        cls.employee_b = cls._member("employee-b@example.com", UserRole.EMPLOYEE)
        cls.super_admin = User.objects.create_superuser(
            email="ops@example.com",
            password=PASSWORD,
        )
        cls.no_company = User.objects.create_user(
            email="freelance@example.com",
            password=PASSWORD,
        )
        service.assign(
            user=cls.admin_a,
            company=cls.company_a,
            role=cls.roles[UserRole.COMPANY_ADMIN],
        )
        service.assign(
            user=cls.manager_a,
            company=cls.company_a,
            role=cls.roles[UserRole.MANAGER],
        )
        service.assign(
            user=cls.employee_a,
            company=cls.company_a,
            role=cls.roles[UserRole.EMPLOYEE],
        )
        service.assign(
            user=cls.admin_b,
            company=cls.company_b,
            role=cls.roles[UserRole.COMPANY_ADMIN],
        )
        service.assign(
            user=cls.manager_b,
            company=cls.company_b,
            role=cls.roles[UserRole.MANAGER],
        )
        service.assign(
            user=cls.employee_b,
            company=cls.company_b,
            role=cls.roles[UserRole.EMPLOYEE],
        )
        cls.record_a = TenantOwnedRecord.objects.create(
            company=cls.company_a,
            title="Acme public",
            visibility=RecordVisibility.COMPANY,
            owner=cls.admin_a,
        )
        cls.private_a = TenantOwnedRecord.objects.create(
            company=cls.company_a,
            title="Employee A private",
            visibility=RecordVisibility.PRIVATE,
            owner=cls.employee_a,
        )
        cls.record_b = TenantOwnedRecord.objects.create(
            company=cls.company_b,
            title="Beta public",
            visibility=RecordVisibility.COMPANY,
            owner=cls.admin_b,
        )
        cls.private_b = TenantOwnedRecord.objects.create(
            company=cls.company_b,
            title="Employee B private",
            visibility=RecordVisibility.PRIVATE,
            owner=cls.employee_b,
        )

    @classmethod
    def _member(cls, email: str, role: str):
        return User.objects.create_user(
            email=email,
            password=PASSWORD,
            role=role,
        )

    def authenticate(self, user) -> APIClient:
        client = APIClient()
        response = client.post(
            "/api/v1/auth/login/",
            {"email": user.email, "password": PASSWORD},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {response.json()['data']['access']}"
        )
        return client


class TenancyAPITestCase(TenancyFixtureMixin, TestCase):
    pass
