from drf_spectacular.utils import extend_schema, extend_schema_view
from rest_framework.views import APIView
from rest_framework.viewsets import ModelViewSet

from apps.common.mixins import TenantAwareQuerySetMixin
from apps.common.permissions import HasPermission, IsAuthenticatedUser, IsSuperAdmin
from apps.common.responses import success_response
from apps.common.tenancy import get_tenant_context
from apps.companies.models import TenantOwnedRecord
from apps.companies.serializers import TenantOwnedRecordSerializer

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
    permission_classes = (IsAuthenticatedUser, HasPermission("settings.manage"))

    @extend_schema(
        tags=["Tenancy"],
        description=(
            "Company settings probe. Requires settings.manage. "
            "Managers and employees are denied. SUPER_ADMIN sees platform scope."
        ),
    )
    def get(self, request, **_kwargs):
        ctx = get_tenant_context(request)
        if ctx.is_super_admin:
            return success_response(
                data={"scope": "PLATFORM", "company": None},
                message="Platform settings.",
            )
        return success_response(
            data={
                "scope": "COMPANY",
                "company": {
                    "id": str(ctx.company.id),
                    "name": ctx.company.name,
                    "slug": ctx.company.slug,
                },
            },
            message="Company settings.",
        )


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
