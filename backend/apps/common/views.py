from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.request import Request

from apps.common.responses import success_response


@api_view(["GET"])
@permission_classes([AllowAny])
def health(_request: Request, **_kwargs):
    return success_response(message="API is healthy.")
