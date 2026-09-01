from django.contrib.auth import get_user_model
from rest_framework import serializers

from apps.audit_logs.models import AuditLog

User = get_user_model()


class AuditActorSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="get_full_name", read_only=True)

    class Meta:
        model = User
        fields = ("id", "name")


class AuditLogSerializer(serializers.ModelSerializer):
    user = AuditActorSerializer(read_only=True)

    class Meta:
        model = AuditLog
        fields = (
            "id",
            "action",
            "entity_type",
            "entity_id",
            "user",
            "old_value",
            "new_value",
            "ip_address",
            "user_agent",
            "created_at",
        )
        read_only_fields = fields
