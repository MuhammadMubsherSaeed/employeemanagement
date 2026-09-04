from django.test import TestCase
from rest_framework.test import APIClient


class HealthAPITests(TestCase):
    def setUp(self) -> None:
        self.client = APIClient()

    def test_health_is_public_and_shaped_correctly(self) -> None:
        response = self.client.get("/api/v1/health/")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["success"], True)
        self.assertEqual(body["message"], "API is healthy.")
        self.assertEqual(body["data"]["status"], "ok")

    def test_health_rejects_post(self) -> None:
        response = self.client.post("/api/v1/health/")
        self.assertEqual(response.status_code, 405)
        body = response.json()
        self.assertFalse(body["success"])
        self.assertEqual(body["code"], "METHOD_NOT_ALLOWED")
