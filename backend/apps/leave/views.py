from drf_spectacular.utils import (
    OpenApiParameter,
    extend_schema,
    extend_schema_view,
)
from rest_framework.decorators import action
from rest_framework.exceptions import MethodNotAllowed
from rest_framework.mixins import (
    CreateModelMixin,
    ListModelMixin,
    RetrieveModelMixin,
    UpdateModelMixin,
)
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.viewsets import GenericViewSet

from apps.common.mixins import EnvelopeMixin, TenantAwareQuerySetMixin
from apps.common.permissions import HasAnyPermission, HasPermission, IsAuthenticatedUser
from apps.common.responses import success_response
from apps.leave.filters import LeaveBalanceFilter, LeaveRequestFilter, LeaveTypeFilter
from apps.leave.permissions import (
    LEAVE_APPROVE,
    LEAVE_CREATE,
    LEAVE_MANAGE,
    LEAVE_REJECT,
    LEAVE_VIEW,
)
from apps.leave.selectors import (
    leave_balance_queryset,
    leave_request_queryset,
    leave_type_queryset,
)
from apps.leave.serializers import (
    ApproveLeaveRequestSerializer,
    CancelLeaveRequestSerializer,
    CreateLeaveRequestSerializer,
    LeaveBalanceAllocateSerializer,
    LeaveBalanceSerializer,
    LeaveRequestDetailSerializer,
    LeaveRequestListSerializer,
    LeaveTypeSerializer,
    RejectLeaveRequestSerializer,
)
from apps.leave.services import LeaveService

_TYPE_PERMISSIONS = {
    "list": LEAVE_VIEW,
    "retrieve": LEAVE_VIEW,
    "create": LEAVE_MANAGE,
    "update": LEAVE_MANAGE,
    "partial_update": LEAVE_MANAGE,
}

_BALANCE_PERMISSIONS = {
    "list": LEAVE_VIEW,
    "retrieve": LEAVE_VIEW,
    "partial_update": LEAVE_MANAGE,
}

_REQUEST_PERMISSIONS = {
    "list": LEAVE_VIEW,
    "retrieve": LEAVE_VIEW,
    "create": LEAVE_CREATE,
    "approve": LEAVE_APPROVE,
    "reject": LEAVE_REJECT,
    "attachment": LEAVE_VIEW,
}


@extend_schema_view(
    list=extend_schema(
        tags=["Leave"],
        description="List leave types in the authenticated company.",
        parameters=[OpenApiParameter("status", type=str)],
    ),
    retrieve=extend_schema(tags=["Leave"]),
    create=extend_schema(tags=["Leave"], description="Create a company leave type."),
    partial_update=extend_schema(tags=["Leave"]),
)
class LeaveTypeViewSet(
    EnvelopeMixin,
    TenantAwareQuerySetMixin,
    CreateModelMixin,
    ListModelMixin,
    RetrieveModelMixin,
    UpdateModelMixin,
    GenericViewSet,
):
    queryset = leave_type_queryset()
    serializer_class = LeaveTypeSerializer
    permission_classes = (IsAuthenticatedUser,)
    filterset_class = LeaveTypeFilter
    search_fields = ("name", "code")
    ordering_fields = ("name", "code", "created_at")
    ordering = ("name",)
    http_method_names = ["get", "post", "patch", "head", "options"]

    def get_permissions(self):
        code = _TYPE_PERMISSIONS.get(self.action, LEAVE_VIEW)
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_read_serializer(self, instance):
        return LeaveTypeSerializer(instance, context=self.get_serializer_context())


@extend_schema_view(
    list=extend_schema(
        tags=["Leave"],
        description=(
            "List leave balances in authorization scope. "
            "Employees see only their own rows."
        ),
        parameters=[
            OpenApiParameter("employee", type=str),
            OpenApiParameter("leave_type", type=str),
            OpenApiParameter("year", type=int),
        ],
    ),
    retrieve=extend_schema(tags=["Leave"]),
    partial_update=extend_schema(
        tags=["Leave"],
        description="Set allocated_days. Requires leave.manage. Does not change used_days.",
    ),
)
class LeaveBalanceViewSet(
    EnvelopeMixin,
    TenantAwareQuerySetMixin,
    ListModelMixin,
    RetrieveModelMixin,
    UpdateModelMixin,
    GenericViewSet,
):
    queryset = leave_balance_queryset()
    serializer_class = LeaveBalanceSerializer
    permission_classes = (IsAuthenticatedUser,)
    filterset_class = LeaveBalanceFilter
    ordering_fields = ("year", "created_at")
    ordering = ("-year",)
    http_method_names = ["get", "patch", "head", "options"]

    def get_permissions(self):
        code = _BALANCE_PERMISSIONS.get(self.action, LEAVE_VIEW)
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_serializer_class(self):
        if self.action in ("update", "partial_update"):
            return LeaveBalanceAllocateSerializer
        return LeaveBalanceSerializer

    def get_read_serializer(self, instance):
        return LeaveBalanceSerializer(instance, context=self.get_serializer_context())

    def update(self, request, *args, **kwargs):
        if not kwargs.get("partial", False) and request.method.lower() == "put":
            raise MethodNotAllowed("PUT")
        instance = self.get_object()
        serializer = self.get_serializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        balance = LeaveService().allocate_balance(
            request=request,
            balance=instance,
            allocated_days=serializer.validated_data["allocated_days"],
        )
        body = self.get_read_serializer(balance)
        return success_response(data=body.data, message="Updated.")


@extend_schema_view(
    list=extend_schema(
        tags=["Leave"],
        description="List leave requests in authorization scope.",
        parameters=[
            OpenApiParameter("employee", type=str),
            OpenApiParameter("leave_type", type=str),
            OpenApiParameter("status", type=str),
            OpenApiParameter("start_date", type=str),
            OpenApiParameter("end_date", type=str),
            OpenApiParameter("ordering", type=str),
        ],
    ),
    retrieve=extend_schema(
        tags=["Leave"],
        description="Fetch one leave request. Other companies' IDs return 404.",
    ),
    create=extend_schema(
        tags=["Leave"],
        description=(
            "Create a leave request for the authenticated employee. "
            "total_days is calculated from company working days and holidays. "
            "Past dates and multi-year ranges are rejected."
        ),
    ),
)
class LeaveRequestViewSet(
    EnvelopeMixin,
    TenantAwareQuerySetMixin,
    ListModelMixin,
    RetrieveModelMixin,
    GenericViewSet,
):
    queryset = leave_request_queryset()
    permission_classes = (IsAuthenticatedUser,)
    filterset_class = LeaveRequestFilter
    parser_classes = (JSONParser, MultiPartParser, FormParser)
    search_fields = (
        "employee__employee_code",
        "employee__first_name",
        "employee__last_name",
        "reason",
        "status",
    )
    ordering_fields = ("start_date", "end_date", "created_at", "status")
    ordering = ("-start_date", "-created_at")
    http_method_names = ["get", "post", "delete", "head", "options"]

    def get_permissions(self):
        if self.action == "cancel":
            return [
                IsAuthenticatedUser(),
                HasAnyPermission(LEAVE_CREATE, LEAVE_MANAGE, LEAVE_APPROVE)(),
            ]
        code = _REQUEST_PERMISSIONS.get(self.action, LEAVE_VIEW)
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_serializer_class(self):
        if self.action == "create":
            return CreateLeaveRequestSerializer
        if self.action == "approve":
            return ApproveLeaveRequestSerializer
        if self.action == "reject":
            return RejectLeaveRequestSerializer
        if self.action == "cancel":
            return CancelLeaveRequestSerializer
        if self.action == "list":
            return LeaveRequestListSerializer
        return LeaveRequestDetailSerializer

    def get_read_serializer(self, instance):
        return LeaveRequestDetailSerializer(
            instance, context=self.get_serializer_context()
        )

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        row = LeaveService().create_request(
            request=request, validated=serializer.validated_data
        )
        body = self.get_read_serializer(row)
        return success_response(data=body.data, message="Created.")

    @extend_schema(
        tags=["Leave"],
        request=ApproveLeaveRequestSerializer,
        responses={200: LeaveRequestDetailSerializer},
        description="Approve a pending request and deduct leave balance atomically.",
    )
    @action(detail=True, methods=["post"], url_path="approve")
    def approve(self, request, pk=None, **_kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        row = LeaveService().approve(request=request, leave_request=self.get_object())
        return success_response(
            data=self.get_read_serializer(row).data, message="Approved."
        )

    @extend_schema(
        tags=["Leave"],
        request=RejectLeaveRequestSerializer,
        responses={200: LeaveRequestDetailSerializer},
        description="Reject a pending request. Does not change leave balance.",
    )
    @action(detail=True, methods=["post"], url_path="reject")
    def reject(self, request, pk=None, **_kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        row = LeaveService().reject(
            request=request,
            leave_request=self.get_object(),
            rejection_reason=serializer.validated_data["rejection_reason"],
        )
        return success_response(
            data=self.get_read_serializer(row).data, message="Rejected."
        )

    @extend_schema(
        tags=["Leave"],
        request=CancelLeaveRequestSerializer,
        responses={200: LeaveRequestDetailSerializer},
        description=(
            "Cancel a pending or approved request. Approved cancellation restores balance."
        ),
    )
    @action(detail=True, methods=["post"], url_path="cancel")
    def cancel(self, request, pk=None, **_kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        row = LeaveService().cancel(request=request, leave_request=self.get_object())
        return success_response(
            data=self.get_read_serializer(row).data, message="Cancelled."
        )

    @extend_schema(
        tags=["Leave"],
        description=(
            "GET streams the leave attachment after leave-request authorization. "
            "DELETE removes the stored file. Does not return a public URL."
        ),
        responses={200: bytes},
    )
    @action(detail=True, methods=["get", "delete"], url_path="attachment")
    def attachment(self, request, pk=None, **_kwargs):
        row = self.get_object()
        if request.method == "DELETE":
            updated = LeaveService().delete_attachment(
                request=request, leave_request=row
            )
            return success_response(
                data=self.get_read_serializer(updated).data,
                message="Deleted.",
            )
        return LeaveService().download_attachment(
            request=request, leave_request=row
        )
