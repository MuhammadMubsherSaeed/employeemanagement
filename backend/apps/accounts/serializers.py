from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from apps.accounts.models import User
from apps.accounts.rbac_catalog import PERMISSION_CODES


class CompanySummarySerializer(serializers.Serializer):
    id = serializers.UUIDField()
    name = serializers.CharField()
    slug = serializers.CharField()


class LoginUserSerializer(serializers.ModelSerializer):
    """Public user payload after login. Company comes from membership."""

    full_name = serializers.CharField(source="get_full_name", read_only=True)
    role = serializers.SerializerMethodField()
    company = serializers.SerializerMethodField()
    permissions = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "first_name",
            "last_name",
            "full_name",
            "role",
            "company",
            "permissions",
        )
        read_only_fields = fields

    def get_role(self, user: User) -> str:
        return user.resolve_role_code()

    @extend_schema_field(CompanySummarySerializer(allow_null=True))
    def get_company(self, user: User):
        company = user.current_company
        if company is None:
            return None
        return CompanySummarySerializer(company).data

    @extend_schema_field(serializers.ListField(child=serializers.CharField()))
    def get_permissions(self, user: User) -> list[str]:
        """Permission codes for the Flutter UX layer. Django remains authoritative."""
        if user.is_platform_admin:
            return list(PERMISSION_CODES)
        membership = user.get_active_membership()
        if membership is None:
            return []
        return list(membership.role.permissions.values_list("code", flat=True))


class CurrentUserSerializer(LoginUserSerializer):
    class Meta(LoginUserSerializer.Meta):
        fields = (*LoginUserSerializer.Meta.fields, "is_active")
        read_only_fields = fields


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, trim_whitespace=False)


class RefreshTokenSerializer(serializers.Serializer):
    refresh = serializers.CharField()


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()


class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()


class ResetPasswordSerializer(serializers.Serializer):
    uid = serializers.CharField()
    token = serializers.CharField()
    new_password = serializers.CharField(write_only=True, trim_whitespace=False)
    confirm_password = serializers.CharField(write_only=True, trim_whitespace=False)

    def validate(self, attrs: dict) -> dict:
        if attrs["new_password"] != attrs["confirm_password"]:
            raise serializers.ValidationError(
                {"confirm_password": "Passwords do not match."}
            )
        try:
            validate_password(attrs["new_password"])
        except DjangoValidationError as exc:
            raise serializers.ValidationError(
                {"new_password": list(exc.messages)}
            ) from exc
        return attrs
