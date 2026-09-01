from drf_spectacular.utils import (
    OpenApiParameter,
    extend_schema,
    extend_schema_view,
)
from rest_framework.decorators import action
from rest_framework.mixins import (
    CreateModelMixin,
    DestroyModelMixin,
    ListModelMixin,
    RetrieveModelMixin,
    UpdateModelMixin,
)
from rest_framework.viewsets import GenericViewSet

from apps.common.mixins import EnvelopeMixin, TenantAwareQuerySetMixin
from apps.common.permissions import HasPermission, IsAuthenticatedUser
from apps.common.responses import success_response
from apps.notifications.filters import NotificationFilter
from apps.notifications.permissions import (
    NOTIFICATIONS_MARK_READ,
    NOTIFICATIONS_VIEW,
)
from apps.notifications.selectors import (
    device_token_queryset,
    notification_queryset,
)
from apps.notifications.serializers import (
    DeviceTokenCreateSerializer,
    DeviceTokenSerializer,
    DeviceTokenUpdateSerializer,
    MarkAllReadSerializer,
    NotificationDetailSerializer,
    NotificationListSerializer,
    UnreadCountSerializer,
)
from apps.notifications.services import DeviceTokenService, NotificationService

_INBOX_PERMISSIONS = {
    "list": NOTIFICATIONS_VIEW,
    "retrieve": NOTIFICATIONS_VIEW,
    "unread_count": NOTIFICATIONS_VIEW,
    "mark_read": NOTIFICATIONS_MARK_READ,
    "mark_all_read": NOTIFICATIONS_MARK_READ,
}

_TOKEN_PERMISSIONS = {
    "create": NOTIFICATIONS_VIEW,
    "partial_update": NOTIFICATIONS_VIEW,
    "update": NOTIFICATIONS_VIEW,
    "destroy": NOTIFICATIONS_VIEW,
}


@extend_schema_view(
    list=extend_schema(
        tags=["Notifications"],
        description=(
            "List the authenticated user's notifications in the current company. "
            "Newest first. Other users' inboxes are never included."
        ),
        parameters=[
            OpenApiParameter("is_read", type=bool),
            OpenApiParameter("type", type=str),
            OpenApiParameter("created_at_after", type=str),
            OpenApiParameter("created_at_before", type=str),
        ],
    ),
    retrieve=extend_schema(
        tags=["Notifications"],
        description=(
            "Fetch one of the caller's notifications. Other users' or companies' "
            "IDs return 404."
        ),
    ),
)
class NotificationViewSet(
    EnvelopeMixin,
    TenantAwareQuerySetMixin,
    ListModelMixin,
    RetrieveModelMixin,
    GenericViewSet,
):
    queryset = notification_queryset()
    permission_classes = (IsAuthenticatedUser,)
    filterset_class = NotificationFilter
    search_fields = ("title", "message", "type")
    ordering_fields = ("created_at", "type", "is_read")
    ordering = ("-created_at",)
    http_method_names = ("get", "post", "head", "options")

    def get_permissions(self):
        code = _INBOX_PERMISSIONS.get(self.action, NOTIFICATIONS_VIEW)
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_serializer_class(self):
        if self.action == "list":
            return NotificationListSerializer
        if self.action == "unread_count":
            return UnreadCountSerializer
        if self.action == "mark_all_read":
            return MarkAllReadSerializer
        return NotificationDetailSerializer

    def get_read_serializer(self, instance):
        return NotificationDetailSerializer(
            instance, context=self.get_serializer_context()
        )

    @extend_schema(
        tags=["Notifications"],
        responses=UnreadCountSerializer,
        description="Unread count for the authenticated user in the current company.",
    )
    @action(detail=False, methods=["get"], url_path="unread-count")
    def unread_count(self, request, **_kwargs):
        count = NotificationService().unread_count(request=request)
        return success_response(data={"count": count})

    @extend_schema(
        tags=["Notifications"],
        request=None,
        description="Mark one of the caller's notifications as read. Idempotent.",
    )
    @action(detail=True, methods=["post"], url_path="mark-read")
    def mark_read(self, request, pk=None, **_kwargs):
        notification = self.get_object()
        row = NotificationService().mark_read(
            request=request, notification=notification
        )
        return success_response(
            data=self.get_read_serializer(row).data,
            message="Marked as read.",
        )

    @extend_schema(
        tags=["Notifications"],
        request=None,
        responses=MarkAllReadSerializer,
        description="Mark all of the caller's unread notifications as read.",
    )
    @action(detail=False, methods=["post"], url_path="mark-all-read")
    def mark_all_read(self, request, **_kwargs):
        updated = NotificationService().mark_all_read(request=request)
        return success_response(
            data={"updated": updated},
            message="Marked as read.",
        )


@extend_schema_view(
    create=extend_schema(
        tags=["Notifications"],
        request=DeviceTokenCreateSerializer,
        responses=DeviceTokenSerializer,
        description=(
            "Register or reassign an FCM device token for the authenticated user. "
            "user_id and company_id are taken from the session."
        ),
    ),
    partial_update=extend_schema(
        tags=["Notifications"],
        request=DeviceTokenUpdateSerializer,
        responses=DeviceTokenSerializer,
        description="Update the caller's own device token registration.",
    ),
    destroy=extend_schema(
        tags=["Notifications"],
        description="Deactivate the caller's own device token (current device logout).",
    ),
)
class DeviceTokenViewSet(
    EnvelopeMixin,
    TenantAwareQuerySetMixin,
    CreateModelMixin,
    UpdateModelMixin,
    DestroyModelMixin,
    GenericViewSet,
):
    queryset = device_token_queryset()
    permission_classes = (IsAuthenticatedUser,)
    http_method_names = ("post", "patch", "delete", "head", "options")

    def get_permissions(self):
        code = _TOKEN_PERMISSIONS.get(self.action, NOTIFICATIONS_VIEW)
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_serializer_class(self):
        if self.action == "create":
            return DeviceTokenCreateSerializer
        if self.action in ("update", "partial_update"):
            return DeviceTokenUpdateSerializer
        return DeviceTokenSerializer

    def get_read_serializer(self, instance):
        return DeviceTokenSerializer(instance, context=self.get_serializer_context())

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        row = DeviceTokenService().register(
            request=request, validated=serializer.validated_data
        )
        return success_response(
            data=self.get_read_serializer(row).data,
            message="Registered.",
        )

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(
            instance, data=request.data, partial=partial
        )
        serializer.is_valid(raise_exception=True)
        row = DeviceTokenService().update_token(
            request=request,
            device_token=instance,
            validated=dict(serializer.validated_data),
        )
        return success_response(
            data=self.get_read_serializer(row).data,
            message="Updated.",
        )

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        DeviceTokenService().deactivate(request=request, device_token=instance)
        return success_response(data={}, message="Deactivated.")
