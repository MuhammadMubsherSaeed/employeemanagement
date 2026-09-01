from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from rest_framework import serializers

from apps.common.authorization import ObjectAuthorization
from apps.common.tenancy import get_tenant_context
from apps.companies.constants import (
    LOGO_ALLOWED_EXTENSIONS,
    LOGO_MAX_BYTES,
    MAX_COMPANY_NAME_LENGTH,
    normalize_working_days,
    working_day_names,
)
from apps.companies.models import CompanySettings, TenantOwnedRecord

_TENANT_KEYS = ("company", "company_id", "tenant_id", "membership_id")


def _strip_tenant_keys(data):
    if hasattr(data, "copy"):
        data = data.copy()
        for key in _TENANT_KEYS:
            data.pop(key, None)
    return data


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
        return super().to_internal_value(_strip_tenant_keys(data))

    def validate_assigned_to(self, value):
        request = self.context["request"]
        ctx = get_tenant_context(request)
        if not ObjectAuthorization().assert_same_tenant(ctx, value):
            raise serializers.ValidationError(
                "Cannot assign a user from another company."
            )
        return value


class CompanySettingsSerializer(serializers.ModelSerializer):
    company_id = serializers.UUIDField(source="company.id", read_only=True)
    company_name = serializers.CharField(source="company.name", read_only=True)
    logo = serializers.SerializerMethodField()
    working_days = serializers.SerializerMethodField()

    class Meta:
        model = CompanySettings
        fields = (
            "id",
            "company_id",
            "company_name",
            "logo",
            "timezone",
            "work_start_time",
            "work_end_time",
            "grace_period_minutes",
            "minimum_working_minutes",
            "overtime_enabled",
            "working_days",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields

    def get_logo(self, obj) -> str | None:
        if not obj.logo:
            return None
        request = self.context.get("request")
        url = obj.logo.url
        if request is not None:
            return request.build_absolute_uri(url)
        return url

    def get_working_days(self, obj) -> list[str]:
        return working_day_names(obj.working_days)


class CompanySettingsWriteSerializer(serializers.ModelSerializer):
    company_name = serializers.CharField(
        required=False,
        allow_blank=False,
        max_length=MAX_COMPANY_NAME_LENGTH,
        trim_whitespace=True,
    )
    logo = serializers.FileField(required=False, allow_null=True)
    working_days = serializers.JSONField(required=False)

    class Meta:
        model = CompanySettings
        fields = (
            "company_name",
            "logo",
            "timezone",
            "work_start_time",
            "work_end_time",
            "grace_period_minutes",
            "minimum_working_minutes",
            "overtime_enabled",
            "working_days",
        )

    def to_internal_value(self, data):
        return super().to_internal_value(_strip_tenant_keys(data))

    def validate_company_name(self, value: str) -> str:
        name = (value or "").strip()
        if not name:
            raise serializers.ValidationError("Company name cannot be blank.")
        return name

    def validate_logo(self, value):
        if value is None or value == "":
            return None
        name = getattr(value, "name", "") or ""
        suffix = name.rsplit(".", 1)[-1].lower() if "." in name else ""
        if suffix not in LOGO_ALLOWED_EXTENSIONS:
            raise serializers.ValidationError(
                "Logo must be a PNG, JPEG, or WebP image."
            )
        size = getattr(value, "size", None)
        if size is not None and size > LOGO_MAX_BYTES:
            raise serializers.ValidationError("Logo must be 2 MB or smaller.")
        return value

    def validate_working_days(self, value):
        try:
            return normalize_working_days(value)
        except ValueError as exc:
            raise serializers.ValidationError(str(exc)) from exc

    def validate_timezone(self, value: str) -> str:
        name = (value or "").strip()
        try:
            ZoneInfo(name)
        except (ZoneInfoNotFoundError, KeyError, ValueError):
            raise serializers.ValidationError("Unknown IANA timezone.")
        return name

    def validate(self, attrs):
        start = attrs.get("work_start_time")
        end = attrs.get("work_end_time")
        if start is not None and end is not None and end <= start:
            raise serializers.ValidationError(
                {
                    "work_end_time": (
                        "Overnight shifts are not supported. "
                        "work_end_time must be after work_start_time."
                    )
                }
            )
        return attrs
