from drf_spectacular.utils import (
    OpenApiParameter,
    extend_schema,
    extend_schema_view,
)
from rest_framework.decorators import action
from rest_framework.viewsets import ModelViewSet

from apps.accounts.models import UserRole
from apps.common.mixins import EnvelopeMixin, TenantAwareQuerySetMixin
from apps.common.permissions import HasPermission, IsAuthenticatedUser
from apps.common.responses import success_response
from apps.common.tenancy import get_tenant_context
from apps.devices.filters import DeviceFilter
from apps.devices.permissions import (
    DEVICES_ASSIGN,
    DEVICES_CREATE,
    DEVICES_DELETE,
    DEVICES_RETURN,
    DEVICES_UPDATE,
    DEVICES_VIEW,
)
from apps.devices.selectors import device_queryset, get_device_history
from apps.devices.serializers import (
    AssignDeviceSerializer,
    CreateDeviceSerializer,
    DeviceAssignmentHistorySerializer,
    DeviceDetailSerializer,
    DeviceListSerializer,
    ReturnDeviceSerializer,
    UpdateDeviceSerializer,
)
from apps.devices.services import DeviceService, resolve_employee

_ACTION_PERMISSIONS = {
    "list": DEVICES_VIEW,
    "retrieve": DEVICES_VIEW,
    "create": DEVICES_CREATE,
    "update": DEVICES_UPDATE,
    "partial_update": DEVICES_UPDATE,
    "destroy": DEVICES_DELETE,
    "assign": DEVICES_ASSIGN,
    "return_device": DEVICES_RETURN,
    "history": DEVICES_VIEW,
}


@extend_schema_view(
    list=extend_schema(
        tags=["Devices"],
        description=(
            "List devices in authorization scope. Employees see only devices "
            "currently assigned to them. Cost and notes are omitted unless the "
            "caller can manage inventory."
        ),
        parameters=[
            OpenApiParameter("status", type=str),
            OpenApiParameter("type", type=str),
            OpenApiParameter("manufacturer", type=str),
            OpenApiParameter("assigned", type=bool),
            OpenApiParameter("employee", type=str),
            OpenApiParameter("search", type=str),
        ],
    ),
    retrieve=extend_schema(
        tags=["Devices"],
        description="Fetch one device. Other companies' IDs return 404.",
    ),
    create=extend_schema(
        tags=["Devices"],
        description="Create a company device. Status is always AVAILABLE. Requires devices.create.",
    ),
    update=extend_schema(
        tags=["Devices"],
        description=(
            "Update device fields. Status ASSIGNED cannot be set here; use assign/. "
            "AVAILABLE cannot be forced on an assigned device; use return/."
        ),
    ),
    partial_update=extend_schema(tags=["Devices"]),
    destroy=extend_schema(
        tags=["Devices"],
        description=(
            "Delete a device with no assignment history. Devices with history "
            "must be retired. Requires devices.delete."
        ),
    ),
)
class DeviceViewSet(EnvelopeMixin, TenantAwareQuerySetMixin, ModelViewSet):
    queryset = device_queryset()
    permission_classes = (IsAuthenticatedUser,)
    filterset_class = DeviceFilter
    search_fields = (
        "asset_code",
        "manufacturer",
        "model",
        "serial_number",
        "type",
    )
    ordering_fields = (
        "asset_code",
        "status",
        "type",
        "created_at",
        "purchase_date",
        "warranty_expiry",
    )
    ordering = ("asset_code",)

    def get_permissions(self):
        code = _ACTION_PERMISSIONS.get(self.action, DEVICES_VIEW)
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_serializer_class(self):
        if self.action == "create":
            return CreateDeviceSerializer
        if self.action in ("update", "partial_update"):
            return UpdateDeviceSerializer
        if self.action == "assign":
            return AssignDeviceSerializer
        if self.action == "return_device":
            return ReturnDeviceSerializer
        if self.action == "history":
            return DeviceAssignmentHistorySerializer
        if self.action == "list":
            return DeviceListSerializer
        return DeviceDetailSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["show_sensitive"] = self._can_see_sensitive()
        return context

    def get_read_serializer(self, instance):
        return DeviceDetailSerializer(instance, context=self.get_serializer_context())

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        device = DeviceService().create_device(
            request=request,
            validated=serializer.validated_data,
        )
        return success_response(
            data=self.get_read_serializer(device).data,
            message="Created.",
        )

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(
            instance,
            data=request.data,
            partial=partial,
        )
        serializer.is_valid(raise_exception=True)
        device = DeviceService().update_device(
            request=request,
            device=instance,
            validated=dict(serializer.validated_data),
        )
        return success_response(
            data=self.get_read_serializer(device).data,
            message="Updated.",
        )

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        DeviceService().delete_device(request=request, device=instance)
        return success_response(data={}, message="Deleted.")

    @extend_schema(
        tags=["Devices"],
        request=AssignDeviceSerializer,
        responses={200: DeviceDetailSerializer},
        description=(
            "Assign an AVAILABLE device to an employee in the same company. "
            "Creates a history row and sets status to ASSIGNED. "
            "Managers may only assign to their direct reports. Requires devices.assign."
        ),
    )
    @action(detail=True, methods=["post"], url_path="assign")
    def assign(self, request, pk=None, **_kwargs):
        device = self.get_object()
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        ctx = get_tenant_context(request)
        employee = resolve_employee(
            company=ctx.company,
            employee_id=serializer.validated_data["employee_id"],
        )
        device = DeviceService().assign_device(
            request=request,
            device=device,
            employee=employee,
            condition_on_assignment=serializer.validated_data.get(
                "condition_on_assignment",
                "",
            ),
            notes=serializer.validated_data.get("notes", ""),
        )
        return success_response(
            data=self.get_read_serializer(device).data,
            message="Assigned.",
        )

    @extend_schema(
        tags=["Devices"],
        request=ReturnDeviceSerializer,
        responses={200: DeviceDetailSerializer},
        description=(
            "Return the active assignment. Status becomes AVAILABLE. "
            "Requires devices.return. Employees cannot self-return."
        ),
    )
    @action(detail=True, methods=["post"], url_path="return")
    def return_device(self, request, pk=None, **_kwargs):
        device = self.get_object()
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        device = DeviceService().return_device(
            request=request,
            device=device,
            condition_on_return=serializer.validated_data.get(
                "condition_on_return",
                "",
            ),
            notes=serializer.validated_data.get("notes", ""),
        )
        return success_response(
            data=self.get_read_serializer(device).data,
            message="Returned.",
        )

    @extend_schema(
        tags=["Devices"],
        responses={200: DeviceAssignmentHistorySerializer(many=True)},
        description=(
            "Assignment history for a visible device, newest first. "
            "Employees only see their own assignment rows."
        ),
    )
    @action(detail=True, methods=["get"], url_path="history")
    def history(self, request, pk=None, **_kwargs):
        device = self.get_object()
        queryset = get_device_history(device=device)
        ctx = get_tenant_context(request)
        if ctx.role_code == UserRole.EMPLOYEE:
            queryset = queryset.filter(employee__user_id=ctx.user.id)
        page = self.paginate_queryset(queryset)
        serializer = DeviceAssignmentHistorySerializer(
            queryset if page is None else page,
            many=True,
            context=self.get_serializer_context(),
        )
        if page is not None:
            return self.get_paginated_response(serializer.data)
        return success_response(data=serializer.data)

    def _can_see_sensitive(self) -> bool:
        ctx = get_tenant_context(self.request)
        return ctx.has_any_permission((DEVICES_CREATE, DEVICES_UPDATE, DEVICES_DELETE))
