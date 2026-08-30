from rest_framework import serializers

from apps.common.authorization import ObjectAuthorization
from apps.common.tenancy import get_tenant_context
from apps.companies.models import TenantOwnedRecord


class TenantOwnedRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = TenantOwnedRecord
        fields = (
            "id",
            "title",
            "visibility",
            "owner",
            "assigned_to",
            "created_at",
        )
        read_only_fields = ("id", "owner", "created_at")

    def to_internal_value(self, data):
        if hasattr(data, "copy"):
            data = data.copy()
            for key in ("company", "company_id", "tenant_id", "membership_id"):
                data.pop(key, None)
        return super().to_internal_value(data)

    def validate_assigned_to(self, value):
        request = self.context["request"]
        ctx = get_tenant_context(request)
        if not ObjectAuthorization().assert_same_tenant(ctx, value):
            raise serializers.ValidationError(
                "Cannot assign a user from another company."
            )
        return value
