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

    def test_attendance_and_holiday_paths_are_documented(self) -> None:
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

