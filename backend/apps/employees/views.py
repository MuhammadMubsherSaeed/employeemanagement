from drf_spectacular.utils import extend_schema, extend_schema_view
from rest_framework.decorators import action
from rest_framework.exceptions import NotFound
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.viewsets import ModelViewSet

from apps.common.mixins import EnvelopeMixin, TenantAwareQuerySetMixin
from apps.common.permissions import HasPermission, IsAuthenticatedUser
from apps.common.responses import success_response
from apps.common.tenancy import get_tenant_context
from apps.employees.filters import DepartmentFilter, EmployeeFilter, PositionFilter
from apps.employees.permissions import ORGANIZATION_WRITE_PERMISSION
from apps.employees.selectors import (
    department_queryset,
    employee_for_user,
    employee_queryset,
    position_queryset,
)
from apps.employees.serializers import (
    DepartmentSerializer,
    EmployeeCreateSerializer,
    EmployeeDetailSerializer,
    EmployeeListSerializer,
    EmployeeSelfSerializer,
    EmployeeUpdateSerializer,
    PositionSerializer,
    ProfileImageUploadSerializer,
)
from apps.employees.services import (
    clear_profile_image,
    open_profile_image,
    set_profile_image,
)

_EMPLOYEE_PERMISSIONS = {
    "list": "employees.view",
    "retrieve": "employees.view",
    "me": "employees.view",
    "create": "employees.create",
    "update": "employees.update",
    "partial_update": "employees.update",
    "destroy": "employees.delete",
    "profile_image": "employees.view",
}

_ORG_WRITE = {
    "create": ORGANIZATION_WRITE_PERMISSION,
    "update": ORGANIZATION_WRITE_PERMISSION,
    "partial_update": ORGANIZATION_WRITE_PERMISSION,
    "destroy": ORGANIZATION_WRITE_PERMISSION,
}


@extend_schema_view(
    list=extend_schema(
        tags=["Employees"],
        description="List employees in the authenticated company only.",
    ),
    retrieve=extend_schema(
        tags=["Employees"],
        description="Fetch one employee. Other companies' IDs return 404.",
    ),
    create=extend_schema(
        tags=["Employees"],
        description="Create an employee in the authenticated company.",
    ),
    update=extend_schema(tags=["Employees"]),
    partial_update=extend_schema(tags=["Employees"]),
    destroy=extend_schema(tags=["Employees"]),
)
class EmployeeViewSet(EnvelopeMixin, TenantAwareQuerySetMixin, ModelViewSet):
    queryset = employee_queryset()
    permission_classes = (IsAuthenticatedUser,)
    parser_classes = (JSONParser, MultiPartParser, FormParser)
    filterset_class = EmployeeFilter
    search_fields = (
        "employee_code",
        "first_name",
        "last_name",
        "phone",
        "user__email",
    )
    ordering_fields = (
        "first_name",
        "last_name",
        "joining_date",
        "created_at",
        "employee_code",
    )
    ordering = ("last_name", "first_name")

    def get_permissions(self):
        code = _EMPLOYEE_PERMISSIONS.get(self.action, "employees.view")
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_serializer_class(self):
        if self.action == "list":
            return EmployeeListSerializer
        if self.action == "create":
            return EmployeeCreateSerializer
        if self.action in ("update", "partial_update"):
            return EmployeeUpdateSerializer
        if self.action == "me":
            return EmployeeSelfSerializer
        return EmployeeDetailSerializer

    def get_read_serializer(self, instance):
        return EmployeeDetailSerializer(instance, context=self.get_serializer_context())

    @extend_schema(
        tags=["Employees"],
        description="Employee profile for the authenticated user in this company.",
    )
    @action(detail=False, methods=["get"], url_path="me")
    def me(self, request, **_kwargs):
        ctx = get_tenant_context(request)
        employee = employee_for_user(user=request.user, company=ctx.company)
        if employee is None:
            raise NotFound()
        self.check_object_permissions(request, employee)
        serializer = EmployeeSelfSerializer(
            employee, context=self.get_serializer_context()
        )
        return success_response(data=serializer.data)

    def check_object_permissions(self, request, obj):
        if self.action == "profile_image" and request.method not in (
            "GET",
            "HEAD",
            "OPTIONS",
        ):
            super(TenantAwareQuerySetMixin, self).check_object_permissions(
                request, obj
            )
            ctx = get_tenant_context(request)
            from apps.common.authorization import ObjectAuthorization

            if not ObjectAuthorization().can_view(ctx, obj):
                raise NotFound()
            return
        super().check_object_permissions(request, obj)

    @extend_schema(
        tags=["Employees"],
        request={"multipart/form-data": ProfileImageUploadSerializer},
        description=(
            "GET streams a private profile image after authorization. "
            "POST uploads a JPEG/PNG/WebP (multipart field ``file``) and replaces "
            "the previous object. DELETE removes the stored image. "
            "Employees may update their own photo; managers/admins follow "
            "existing employee update scope. Does not return a public URL."
        ),
        responses={200: bytes},
    )
    @action(detail=True, methods=["get", "post", "delete"], url_path="profile-image")
    def profile_image(self, request, pk=None, **_kwargs):
        employee = self.get_object()
        if request.method == "GET":
            return open_profile_image(request=request, employee=employee)
        if request.method == "DELETE":
            clear_profile_image(request=request, employee=employee)
            return success_response(
                data=self.get_read_serializer(employee).data,
                message="Deleted.",
            )
        serializer = ProfileImageUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        set_profile_image(
            request=request,
            employee=employee,
            upload=serializer.validated_data["file"],
        )
        employee.refresh_from_db()
        return success_response(
            data=self.get_read_serializer(employee).data,
            message="Updated.",
        )


@extend_schema_view(
    list=extend_schema(tags=["Departments"]),
    retrieve=extend_schema(tags=["Departments"]),
    create=extend_schema(tags=["Departments"]),
    update=extend_schema(tags=["Departments"]),
    partial_update=extend_schema(tags=["Departments"]),
    destroy=extend_schema(tags=["Departments"]),
)
class DepartmentViewSet(EnvelopeMixin, TenantAwareQuerySetMixin, ModelViewSet):
    queryset = department_queryset()
    serializer_class = DepartmentSerializer
    permission_classes = (IsAuthenticatedUser,)
    filterset_class = DepartmentFilter
    search_fields = ("name",)
    ordering_fields = ("name", "created_at")
    ordering = ("name",)

    def get_permissions(self):
        if self.action in _ORG_WRITE:
            code = _ORG_WRITE[self.action]
        else:
            code = "employees.view"
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_read_serializer(self, instance):
        return DepartmentSerializer(instance, context=self.get_serializer_context())


@extend_schema_view(
    list=extend_schema(tags=["Positions"]),
    retrieve=extend_schema(tags=["Positions"]),
    create=extend_schema(tags=["Positions"]),
    update=extend_schema(tags=["Positions"]),
    partial_update=extend_schema(tags=["Positions"]),
    destroy=extend_schema(tags=["Positions"]),
)
class PositionViewSet(EnvelopeMixin, TenantAwareQuerySetMixin, ModelViewSet):
    queryset = position_queryset()
    serializer_class = PositionSerializer
    permission_classes = (IsAuthenticatedUser,)
    filterset_class = PositionFilter
    search_fields = ("title",)
    ordering_fields = ("title", "created_at")
    ordering = ("title",)

    def get_permissions(self):
        if self.action in _ORG_WRITE:
            code = _ORG_WRITE[self.action]
        else:
            code = "employees.view"
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_read_serializer(self, instance):
        return PositionSerializer(instance, context=self.get_serializer_context())
