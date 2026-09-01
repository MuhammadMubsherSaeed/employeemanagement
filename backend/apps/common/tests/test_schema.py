from django.conf import settings
from django.test import TestCase
from rest_framework.test import APIClient


class SchemaAPITests(TestCase):
    def test_schema_endpoint_returns_openapi(self) -> None:
        client = APIClient()
        response = client.get("/api/schema/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("openapi", response.content.decode("utf-8")[:64].lower())

    def test_jwt_authentication_is_configured(self) -> None:
        self.assertIn(
            "rest_framework_simplejwt.authentication.JWTAuthentication",
            settings.REST_FRAMEWORK["DEFAULT_AUTHENTICATION_CLASSES"],
        )
        self.assertEqual(settings.SIMPLE_JWT["AUTH_HEADER_TYPES"], ("Bearer",))
        self.assertTrue(settings.SIMPLE_JWT["ROTATE_REFRESH_TOKENS"])

    def test_attendance_holiday_and_leave_paths_are_documented(self) -> None:
        client = APIClient()
        response = client.get("/api/schema/", HTTP_ACCEPT="application/json")
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        paths = payload["paths"]
        joined = " ".join(paths)
        self.assertIn("attendance/check-in/", joined)
        self.assertIn("attendance/check-out/", joined)
        self.assertIn("attendance/me/", joined)
        self.assertIn("attendance/summary/", joined)
        self.assertIn("holidays/", joined)
        self.assertIn("leave/types/", joined)
        self.assertIn("leave/balances/", joined)
        self.assertIn("leave/requests/", joined)
        self.assertIn("approve/", joined)
        self.assertIn("reject/", joined)
        self.assertIn("cancel/", joined)
        self.assertIn("devices/", joined)
        self.assertIn("assign/", joined)
        self.assertIn("history/", joined)
        self.assertIn("documents/", joined)
        self.assertIn("download/", joined)
        self.assertIn("profile-image/", joined)
        self.assertIn("/attachment/", joined)
        self.assertIn("notifications/", joined)
        self.assertIn("unread-count/", joined)
        self.assertIn("mark-read/", joined)
        self.assertIn("mark-all-read/", joined)
        self.assertIn("device-tokens/", joined)
        self.assertIn("dashboard/admin/", joined)
        self.assertIn("dashboard/manager/", joined)
        self.assertIn("dashboard/employee/", joined)
        self.assertIn("reports/attendance/", joined)
        self.assertIn("reports/leaves/", joined)
        self.assertIn("reports/employees/", joined)
        self.assertIn("reports/devices/", joined)
        self.assertIn("reports/attendance/export/", joined)
        self.assertIn("reports/leaves/export/", joined)
        self.assertIn("reports/employees/export/", joined)
        self.assertIn("reports/devices/export/", joined)
        self.assertIn("audit-logs/", joined)
        self.assertIn("/api/v1/settings/", joined)
        settings_path = next(
            p
            for p in paths
            if p.rstrip("/").endswith("settings") and "tenancy" not in p
        )
        self.assertIn("get", paths[settings_path])
        self.assertIn("patch", paths[settings_path])
        self.assertNotIn("put", paths[settings_path])
        self.assertNotIn("delete", paths[settings_path])
        audit_path = next(p for p in paths if p.rstrip("/").endswith("audit-logs"))
        self.assertIn("get", paths[audit_path])
        self.assertNotIn("put", paths[audit_path])
        self.assertNotIn("patch", paths[audit_path])
        self.assertNotIn("post", paths[audit_path])
        self.assertNotIn("delete", paths[audit_path])
        device_return = next(
            p for p in paths if "devices/" in p and p.rstrip("/").endswith("return")
        )
        self.assertIn("post", paths[device_return])
        attendance_item = next(p for p in paths if "attendance/" in p and "{id}" in p)
        self.assertNotIn("put", paths[attendance_item])
        self.assertNotIn("patch", paths[attendance_item])
        list_path = next(
            p
            for p in paths
            if p.rstrip("/").endswith("attendance") or p.endswith("attendance/")
        )
        self.assertIn("get", paths[list_path])
        check_in_path = next(p for p in paths if p.rstrip("/").endswith("check-in"))
        self.assertIn("post", paths[check_in_path])

