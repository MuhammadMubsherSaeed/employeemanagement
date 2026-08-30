from drf_spectacular.utils import extend_schema, extend_schema_view
from rest_framework.decorators import action
from rest_framework.exceptions import NotFound
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
)

_EMPLOYEE_PERMISSIONS = {
    "list": "employees.view",
    "retrieve": "employees.view",
    "me": "employees.view",
    "create": "employees.create",
    "update": "employees.update",
    "partial_update": "employees.update",
    "destroy": "employees.delete",
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
