from datetime import time

from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.models import AuditLog
from apps.companies.constants import WEEKDAY_NAMES
from apps.companies.models import Company, CompanySettings
from apps.companies.tests.fixtures import TENANCY, TenancyFixtureMixin

SETTINGS = "/api/v1/settings/"
TINY_PNG = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01"
    b"\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00"
    b"\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N"
    b"\x00\x00\x00\x00IEND\xaeB`\x82"
)


class CompanySettingsModelTests(TenancyFixtureMixin, TestCase):
    def test_company_create_also_creates_settings(self) -> None:
        company = Company.objects.create(name="Nova", slug="nova")
        settings = CompanySettings.objects.get(company=company)
        self.assertEqual(settings.work_start_time, time(9, 0))
        self.assertEqual(settings.work_end_time, time(17, 0))
        self.assertEqual(settings.grace_period_minutes, 15)
        self.assertEqual(settings.minimum_working_minutes, 480)
        self.assertFalse(settings.overtime_enabled)
        self.assertEqual(settings.working_days, [0, 1, 2, 3, 4])
        self.assertTrue(settings.timezone)

    def test_one_settings_row_per_company(self) -> None:
        with self.assertRaises(ValidationError):
            CompanySettings.objects.create(company=self.company_a)

    def test_invalid_timezone_rejected(self) -> None:
        row = self.company_a.settings
        row.timezone = "Not/A_Zone"
        with self.assertRaises(ValidationError):
            row.save()

    def test_overnight_times_rejected(self) -> None:
        row = self.company_a.settings
        row.work_start_time = time(22, 0)
        row.work_end_time = time(6, 0)
        with self.assertRaises(ValidationError):
            row.save()

    def test_identical_times_rejected(self) -> None:
        row = self.company_a.settings
        row.work_start_time = time(9, 0)
        row.work_end_time = time(9, 0)
        with self.assertRaises(ValidationError):
            row.save()

    def test_invalid_working_days_rejected(self) -> None:
        row = self.company_a.settings
        row.working_days = ["funday"]
        with self.assertRaises(ValidationError):
            row.save()
        row.refresh_from_db()
        row.working_days = []
        with self.assertRaises(ValidationError):
            row.save()

    def test_named_working_days_are_normalized(self) -> None:
        row = self.company_a.settings
        row.working_days = ["Friday", "monday", "monday"]
        row.save()
        row.refresh_from_db()
        self.assertEqual(row.working_days, [0, 4])

    def test_grace_and_minimum_bounds(self) -> None:
        row = self.company_a.settings
        row.grace_period_minutes = -1
        with self.assertRaises(ValidationError):
            row.save()
        row.refresh_from_db()
        row.grace_period_minutes = 241
        with self.assertRaises(ValidationError):
            row.save()
        row.refresh_from_db()
        row.minimum_working_minutes = 0
        with self.assertRaises(ValidationError):
            row.save()


class CompanySettingsAPITests(TenancyFixtureMixin, TestCase):
    def test_unauthenticated_is_401(self) -> None:
        self.assertEqual(APIClient().get(SETTINGS).status_code, 401)
        self.assertEqual(
            APIClient().patch(SETTINGS, {"timezone": "UTC"}, format="json").status_code,
            401,
        )

    def test_company_members_can_get_own_settings(self) -> None:
        for user in (self.admin_a, self.manager_a, self.employee_a):
            client = self.authenticate(user)
            response = client.get(SETTINGS)
            self.assertEqual(response.status_code, 200, user.email)
            data = response.json()["data"]
            self.assertEqual(data["company_id"], str(self.company_a.id))
            self.assertEqual(data["company_name"], "Acme")
            self.assertEqual(data["working_days"], list(WEEKDAY_NAMES[:5]))
            self.assertNotIn("company_b", str(data))

    def test_tenant_isolation(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.get(SETTINGS, {"company_id": str(self.company_b.id)})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["company_id"], str(self.company_a.id))
        other = self.authenticate(self.admin_b)
        self.assertEqual(
            other.get(SETTINGS).json()["data"]["company_id"],
            str(self.company_b.id),
        )

    def test_admin_partial_patch(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.patch(
            SETTINGS,
            {
                "timezone": "Asia/Karachi",
                "grace_period_minutes": 20,
                "company_name": " Acme Corp ",
                "working_days": [
                    "monday",
                    "tuesday",
                    "wednesday",
                    "thursday",
                    "friday",
                ],
            },
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["timezone"], "Asia/Karachi")
        self.assertEqual(data["grace_period_minutes"], 20)
        self.assertEqual(data["company_name"], "Acme Corp")
        self.company_a.refresh_from_db()
        self.assertEqual(self.company_a.name, "Acme Corp")
        tenancy = client.get(f"{TENANCY}/settings/")
        self.assertEqual(tenancy.status_code, 200)
        self.assertEqual(tenancy.json()["data"]["timezone"], "Asia/Karachi")

    def test_manager_and_employee_cannot_patch(self) -> None:
        for user in (self.manager_a, self.employee_a):
            client = self.authenticate(user)
            response = client.patch(
                SETTINGS, {"grace_period_minutes": 5}, format="json"
            )
            self.assertEqual(response.status_code, 403, user.email)

    def test_cross_company_patch_cannot_target_another_tenant(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.patch(
            SETTINGS,
            {
                "company_id": str(self.company_b.id),
                "company_name": "Hijacked",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.company_a.refresh_from_db()
        self.company_b.refresh_from_db()
        self.assertEqual(self.company_a.name, "Hijacked")
        self.assertEqual(self.company_b.name, "Beta")

    def test_validation_errors(self) -> None:
        client = self.authenticate(self.admin_a)
        overnight = client.patch(
            SETTINGS,
            {"work_start_time": "22:00:00", "work_end_time": "06:00:00"},
            format="json",
        )
        self.assertEqual(overnight.status_code, 400)
        identical = client.patch(
            SETTINGS,
            {"work_start_time": "09:00:00", "work_end_time": "09:00:00"},
            format="json",
        )
        self.assertEqual(identical.status_code, 400)
        timezone = client.patch(
            SETTINGS, {"timezone": "Not/A_Zone"}, format="json"
        )
        self.assertEqual(timezone.status_code, 400)
        days = client.patch(SETTINGS, {"working_days": []}, format="json")
        self.assertEqual(days.status_code, 400)
        grace = client.patch(
            SETTINGS, {"grace_period_minutes": -1}, format="json"
        )
        self.assertEqual(grace.status_code, 400)

    def test_logo_upload(self) -> None:
        client = self.authenticate(self.admin_a)
        upload = SimpleUploadedFile("logo.png", TINY_PNG, content_type="image/png")
        response = client.patch(SETTINGS, {"logo": upload}, format="multipart")
        self.assertEqual(response.status_code, 200)
        self.assertIsNotNone(response.json()["data"]["logo"])
        self.assertIn("/media/", response.json()["data"]["logo"])

    def test_settings_change_is_audited(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.patch(
            SETTINGS, {"overtime_enabled": True}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        log = AuditLog.objects.get(
            action=AuditAction.SETTINGS_CHANGED, company=self.company_a
        )
        self.assertEqual(log.entity_type, AuditEntityType.COMPANY_SETTINGS)
        self.assertEqual(log.user_id, self.admin_a.id)
        self.assertFalse(log.old_value["overtime_enabled"])
        self.assertTrue(log.new_value["overtime_enabled"])

    def test_super_admin_has_no_company_settings(self) -> None:
        client = self.authenticate(self.super_admin)
        self.assertEqual(client.get(SETTINGS).status_code, 200)
        self.assertEqual(client.get(SETTINGS).json()["data"]["scope"], "PLATFORM")
        self.assertEqual(
            client.patch(SETTINGS, {"timezone": "UTC"}, format="json").status_code,
            403,
        )
