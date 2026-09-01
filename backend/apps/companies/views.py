from drf_spectacular.utils import OpenApiResponse, extend_schema, extend_schema_view
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.views import APIView
from rest_framework.viewsets import ModelViewSet

from apps.common.mixins import TenantAwareQuerySetMixin
from apps.common.permissions import (
    HasPermission,
    IsAuthenticatedUser,
    IsCompanyMember,
    IsSuperAdmin,
)
from apps.common.responses import success_response
from apps.common.tenancy import get_tenant_context
from apps.companies.models import TenantOwnedRecord
from apps.companies.serializers import (
    CompanySettingsSerializer,
    CompanySettingsWriteSerializer,
    TenantOwnedRecordSerializer,
)
from apps.companies.services import CompanySettingsService, get_company_settings

_ACTION_PERMISSIONS = {
    "list": "employees.view",
    "retrieve": "employees.view",
    "create": "employees.create",
    "update": "employees.update",
    "partial_update": "employees.update",
    "destroy": "employees.delete",
}


@extend_schema_view(
    list=extend_schema(
        tags=["Tenancy"],
        description="List tenant-owned records for the authenticated company only.",
    ),
    retrieve=extend_schema(
        tags=["Tenancy"],
        description="Fetch one record. Other companies' IDs return 404.",
    ),
    create=extend_schema(
        tags=["Tenancy"],
        description=(
            "Create in the authenticated company. "
            "company_id in the body is ignored."
        ),
    ),
    update=extend_schema(tags=["Tenancy"]),
    partial_update=extend_schema(tags=["Tenancy"]),
    destroy=extend_schema(
        tags=["Tenancy"],
        description=(
            "Delete a record in the authenticated company. "
            "Cross-company IDs return 404."
        ),
    ),
)
class TenantOwnedRecordViewSet(TenantAwareQuerySetMixin, ModelViewSet):
    """Reference tenant-owned CRUD. Future HR ViewSets should copy this pattern."""

    queryset = TenantOwnedRecord.objects.select_related(
        "company", "owner", "assigned_to"
    )
    serializer_class = TenantOwnedRecordSerializer
    permission_classes = (IsAuthenticatedUser,)

    def get_permissions(self):
        code = _ACTION_PERMISSIONS.get(self.action, "employees.view")
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        serializer = self.get_serializer(queryset, many=True)
        return success_response(data=serializer.data)

    def retrieve(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_object())
        return success_response(data=serializer.data)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        return success_response(data=serializer.data, message="Created.")

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        serializer = self.get_serializer(
            self.get_object(), data=request.data, partial=partial
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return success_response(data=serializer.data, message="Updated.")

    def destroy(self, request, *args, **kwargs):
        self.get_object().delete()
        return success_response(data={}, message="Deleted.")


class CompanySettingsView(APIView):
    parser_classes = (JSONParser, MultiPartParser, FormParser)
    http_method_names = ["get", "patch", "head", "options"]

    def get_permissions(self):
        if self.request.method in ("PATCH", "PUT"):
            return [IsAuthenticatedUser(), HasPermission("settings.manage")()]
        return [IsAuthenticatedUser(), IsCompanyMember()]

    @extend_schema(
        tags=["Settings"],
        responses={
            200: CompanySettingsSerializer,
            401: OpenApiResponse(description="Unauthenticated."),
            403: OpenApiResponse(description="No company membership."),
        },
        description=(
            "Company attendance and identity settings for the authenticated "
            "company. Company members may read. company_id is ignored. "
            "SUPER_ADMIN without a company sees platform scope on the tenancy probe."
        ),
    )
    def get(self, request, **_kwargs):
        ctx = get_tenant_context(request)
        if ctx.is_super_admin:
            return success_response(
                data={"scope": "PLATFORM", "company": None},
                message="Platform settings.",
            )
        if ctx.company is None:
            raise PermissionDenied("You do not have access to this company.")
        row = get_company_settings(ctx.company)
        return success_response(
            data=_settings_response(request, row),
            message="Company settings.",
        )

    @extend_schema(
        tags=["Settings"],
        request=CompanySettingsWriteSerializer,
        responses={
            200: CompanySettingsSerializer,
            400: OpenApiResponse(description="Validation error."),
            401: OpenApiResponse(description="Unauthenticated."),
            403: OpenApiResponse(description="Missing settings.manage."),
        },
        description=(
            "Partial update of company settings. Requires settings.manage. "
            "Supports JSON or multipart (logo upload). company_id in the body "
            "is ignored. Overnight work times are rejected."
        ),
    )
    def patch(self, request, **_kwargs):
        ctx = get_tenant_context(request)
        if ctx.company is None:
            raise PermissionDenied("You do not have access to this company.")
        serializer = CompanySettingsWriteSerializer(
            data=request.data, partial=True, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        row = CompanySettingsService().update(
            company=ctx.company,
            validated=dict(serializer.validated_data),
            actor=ctx.user,
            request=request,
        )
        return success_response(
            data=_settings_response(request, row),
            message="Company settings updated.",
        )


def _settings_response(request, row) -> dict:
    ctx = get_tenant_context(request)
    payload = CompanySettingsSerializer(row, context={"request": request}).data
    return {
        "scope": "COMPANY",
        "company": {
            "id": str(ctx.company.id),
            "name": ctx.company.name,
            "slug": ctx.company.slug,
        },
        **payload,
    }


class PlatformScopeView(APIView):
    permission_classes = (IsAuthenticatedUser, IsSuperAdmin)

    @extend_schema(
        tags=["Tenancy"],
        description=(
            "Platform-only probe. "
            "COMPANY_ADMIN cannot reach this by query params."
        ),
    )
    def get(self, request, **_kwargs):
        return success_response(
            data={"scope": "PLATFORM"},
            message="Platform access granted.",
        )
