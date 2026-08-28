from rest_framework.test import APIClient


def test_health_endpoint_is_public():
    client = APIClient()
    response = client.get("/api/health/")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_api_v1_root_is_initialized():
    client = APIClient()
    response = client.get("/api/v1/")
    assert response.status_code == 200
    assert response.json()["version"] == "v1"
