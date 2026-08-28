"""Versioned API root. Feature routes will be included here later."""

from django.urls import path
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response


@api_view(["GET"])
@permission_classes([AllowAny])
def api_root(_request):
    return Response(
        {
            "name": "HRMS API",
            "version": "v1",
            "status": "initialized",
        }
    )


urlpatterns = [
    path("", api_root, name="api-root"),
]
