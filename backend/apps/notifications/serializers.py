from rest_framework import serializers

from apps.employees.serializers import TenantPayloadMixin
from apps.notifications.models import (
    MAX_DEVICE_NAME_LENGTH,
    MAX_TOKEN_LENGTH,
    DevicePlatform,
    DeviceToken,
    Notification,
)


class NotificationListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = (
            "id",
            "type",
            "title",
            "message",
            "entity_type",
            "entity_id",
            "metadata",
            "is_read",
            "read_at",
            "created_at",
        )


class NotificationDetailSerializer(NotificationListSerializer):
    class Meta(NotificationListSerializer.Meta):
        fields = (*NotificationListSerializer.Meta.fields, "updated_at")


class UnreadCountSerializer(serializers.Serializer):
    count = serializers.IntegerField()


class MarkAllReadSerializer(serializers.Serializer):
    updated = serializers.IntegerField()


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = (
            "id",
            "platform",
            "device_name",
            "is_active",
            "last_seen_at",
            "created_at",
            "updated_at",
        )


class DeviceTokenCreateSerializer(TenantPayloadMixin, serializers.Serializer):
    token = serializers.CharField(max_length=MAX_TOKEN_LENGTH)
    platform = serializers.ChoiceField(
        choices=DevicePlatform.choices,
        default=DevicePlatform.UNKNOWN,
    )
    device_name = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=MAX_DEVICE_NAME_LENGTH,
    )

    def validate_token(self, value: str) -> str:
        token = (value or "").strip()
        if len(token) < 8:
            raise serializers.ValidationError("Enter a valid device token.")
        return token


class DeviceTokenUpdateSerializer(TenantPayloadMixin, serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ("token", "platform", "device_name")
        extra_kwargs = {
            "token": {"required": False},
            "platform": {"required": False},
            "device_name": {"required": False, "allow_blank": True},
        }

    def validate_token(self, value: str) -> str:
        token = (value or "").strip()
        if token and len(token) < 8:
            raise serializers.ValidationError("Enter a valid device token.")
        return token
