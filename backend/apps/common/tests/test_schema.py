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
