from django.test import TestCase
from rest_framework.test import APIClient

# Static OpenAPI fragments the Flutter client calls. Keep aligned with
# mobile/test/integration/django_api_contract_test.dart.
FLUTTER_PRODUCT_FRAGMENTS = (
    "auth/login/",
    "auth/refresh/",
    "auth/logout/",
    "auth/me/",
    "auth/forgot-password/",
    "auth/reset-password/",
    "employees/me/",
    "profile-image/",
    "departments/",
    "positions/",
    "attendance/me/",
    "attendance/check-in/",
    "attendance/check-out/",
    "attendance/summary/",
    "leave/types/",
    "leave/balances/",
    "leave/requests/",
    "/approve/",
    "/reject/",
    "/cancel/",
    "/attachment/",
    "devices/",
    "/assign/",
    "/history/",
    "/documents/",
    "/download/",
    "notifications/unread-count/",
    "mark-read/",
    "mark-all-read/",
    "notifications/device-tokens/",
    "dashboard/admin/",
    "dashboard/manager/",
    "dashboard/employee/",
    "reports/attendance/",
    "reports/attendance/export/",
    "reports/leaves/",
    "reports/leaves/export/",
    "reports/employees/",
    "reports/employees/export/",
    "reports/devices/",
    "reports/devices/export/",
    "audit-logs/",
)

BACKEND_ONLY_MOUNTED_PATHS = (
    "/api/v1/holidays/",
    "/api/v1/documents/",
    "/api/v1/tenancy/settings/",
    "/api/v1/tenancy/records/",
    "/api/v1/tenancy/platform/",
)


class FlutterRouteParityTests(TestCase):
    def setUp(self) -> None:
        self.client = APIClient()

    def _joined_paths(self) -> str:
        response = self.client.get("/api/schema/", HTTP_ACCEPT="application/json")
        self.assertEqual(response.status_code, 200)
        return " ".join(response.json()["paths"])

    def test_flutter_product_paths_exist_in_openapi(self) -> None:
        response = self.client.get("/api/schema/", HTTP_ACCEPT="application/json")
        self.assertEqual(response.status_code, 200)
        paths = response.json()["paths"]
        joined = " ".join(paths)
        for fragment in FLUTTER_PRODUCT_FRAGMENTS:
            self.assertIn(fragment, joined, fragment)
        settings_path = next(
            p
            for p in paths
            if p.rstrip("/").endswith("settings") and "tenancy" not in p
        )
        self.assertIn("get", paths[settings_path])
        self.assertIn("patch", paths[settings_path])
        device_return = next(
            p for p in paths if "devices/" in p and p.rstrip("/").endswith("return")
        )
        self.assertIn("post", paths[device_return])

    def test_backend_only_routes_are_mounted(self) -> None:
        joined = self._joined_paths()
        self.assertIn("holidays/", joined)
        self.assertIn("/access/", joined)
        for path in BACKEND_ONLY_MOUNTED_PATHS:
            response = self.client.get(path)
            self.assertNotEqual(response.status_code, 404, path)

    def test_health_is_public_and_unauthenticated(self) -> None:
        response = self.client.get("/api/v1/health/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["success"], True)
        self.assertEqual(response.json()["message"], "API is healthy.")
