from drf_spectacular.utils import OpenApiParameter, OpenApiResponse, extend_schema
from rest_framework.exceptions import PermissionDenied
from rest_framework.generics import GenericAPIView

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.filters import AuditLogFilter
from apps.audit_logs.models import AuditLog
from apps.audit_logs.permissions import AUDIT_LOGS_VIEW
from apps.audit_logs.serializers import AuditLogSerializer
from apps.common.pagination import StandardPagination
from apps.common.permissions import HasPermission, IsAuthenticatedUser
from apps.common.tenancy import get_tenant_context


class AuditLogPagination(StandardPagination):
    def get_paginated_response(self, data):
        response = super().get_paginated_response(data)
        response.data["message"] = "Audit logs retrieved successfully."
        return response


class AuditLogListView(GenericAPIView):
    permission_classes = (IsAuthenticatedUser, HasPermission(AUDIT_LOGS_VIEW))
    serializer_class = AuditLogSerializer
    filterset_class = AuditLogFilter
    pagination_class = AuditLogPagination
    http_method_names = ["get", "head", "options"]
    search_fields = ()
    ordering_fields = ("created_at",)
    ordering = ("-created_at",)

    def get_queryset(self):
        ctx = get_tenant_context(self.request)
        if ctx.company is None:
            raise PermissionDenied("You do not have access to this company.")
        return (
            AuditLog.objects.filter(company=ctx.company)
            .select_related("user")
            .order_by("-created_at")
        )

    @extend_schema(
        tags=["Audit logs"],
        description=(
            "Paginated, newest-first audit logs for the authenticated company. "
            "Requires audit_logs.view. company_id and tenant_id query parameters "
            "are ignored. Mutation methods are not supported."
        ),
        parameters=[
            OpenApiParameter("page", int, description="Page number"),
            OpenApiParameter("page_size", int, description="Page size (max 100)"),
            OpenApiParameter(
                "date_from",
                str,
                description="Inclusive start date (YYYY-MM-DD) in the company timezone.",
            ),
            OpenApiParameter(
                "date_to",
                str,
                description="Inclusive end date (YYYY-MM-DD) in the company timezone.",
            ),
            OpenApiParameter(
                "user",
                int,
                description="Actor user id. Still scoped to the authenticated company.",
            ),
            OpenApiParameter(
                "action",
                str,
                enum=list(AuditAction.values),
                description="Centralized audit action.",
            ),
            OpenApiParameter(
                "entity_type",
                str,
                enum=list(AuditEntityType.values),
                description="Centralized entity type.",
            ),
            OpenApiParameter("entity_id", str, description="Stored entity identifier."),
            OpenApiParameter(
                "ordering",
                str,
                description="Whitelisted ordering. Default -created_at.",
            ),
        ],
        responses={
            200: AuditLogSerializer,
            400: OpenApiResponse(description="Invalid filter values."),
            401: OpenApiResponse(description="Unauthenticated."),
            403: OpenApiResponse(description="Missing audit_logs.view."),
        },
    )
    def get(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)
