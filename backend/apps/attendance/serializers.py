from rest_framework import serializers

from apps.accounts.models import UserRole
from apps.attendance.models import Attendance, Holiday
from apps.common.tenancy import get_tenant_context
from apps.employees.models import Employee
from apps.employees.serializers import TenantPayloadMixin

_SENSITIVE_ROLES = frozenset(
    {UserRole.COMPANY_ADMIN, UserRole.MANAGER, UserRole.SUPER_ADMIN}
)


def _can_see_sensitive(request) -> bool:
    if request is None:
        return False
    ctx = get_tenant_context(request)
    if ctx.is_super_admin:
        return True
    return ctx.role_code in _SENSITIVE_ROLES


class AttendanceEmployeeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Employee
        fields = ("id", "employee_code", "first_name", "last_name")


class AttendanceListSerializer(serializers.ModelSerializer):
    employee = AttendanceEmployeeSerializer(read_only=True)

    class Meta:
        model = Attendance
        fields = (
            "id",
            "employee",
            "date",
            "check_in",
            "check_out",
            "total_minutes",
            "status",
            "created_at",
        )
        read_only_fields = fields


class AttendanceDetailSerializer(AttendanceListSerializer):
    class Meta(AttendanceListSerializer.Meta):
        fields = (
            *AttendanceListSerializer.Meta.fields,
            "updated_at",
            "check_in_ip",
            "check_out_ip",
            "check_in_latitude",
            "check_in_longitude",
            "check_out_latitude",
            "check_out_longitude",
        )

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get("request")
        if not _can_see_sensitive(request):
            for key in (
                "check_in_ip",
                "check_out_ip",
                "check_in_latitude",
                "check_in_longitude",
                "check_out_latitude",
                "check_out_longitude",
            ):
                data.pop(key, None)
        return data


class LocationSerializer(TenantPayloadMixin, serializers.Serializer):
    latitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        min_value=-90,
        max_value=90,
        required=False,
        allow_null=True,
    )
    longitude = serializers.DecimalField(
        max_digits=10,
        decimal_places=6,
        min_value=-180,
        max_value=180,
        required=False,
        allow_null=True,
    )

    def validate(self, attrs):
        latitude = attrs.get("latitude")
        longitude = attrs.get("longitude")
        if (latitude is None) ^ (longitude is None):
            raise serializers.ValidationError(
                "latitude and longitude must be provided together."
            )
        return attrs


class CheckInSerializer(LocationSerializer):
    pass


class CheckOutSerializer(LocationSerializer):
    pass


class AttendanceSummarySerializer(serializers.Serializer):
    start_date = serializers.DateField()
    end_date = serializers.DateField()
    employee_id = serializers.UUIDField(allow_null=True)
    total_days = serializers.IntegerField()
    present_days = serializers.IntegerField()
    absent_days = serializers.IntegerField()
    late_days = serializers.IntegerField()
    half_days = serializers.IntegerField()
    leave_days = serializers.IntegerField()
    holiday_days = serializers.IntegerField()
    weekend_days = serializers.IntegerField()
    total_working_minutes = serializers.IntegerField()
    overtime_minutes = serializers.IntegerField()


class SummaryQuerySerializer(serializers.Serializer):
    start_date = serializers.DateField(required=False)
    end_date = serializers.DateField(required=False)
    employee_id = serializers.UUIDField(required=False)


class HolidaySerializer(TenantPayloadMixin, serializers.ModelSerializer):
    class Meta:
        model = Holiday
        fields = (
            "id",
            "name",
            "date",
            "description",
            "is_active",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_date(self, value):
        ctx = get_tenant_context(self.context["request"])
        if ctx.company is None:
            return value
        queryset = Holiday.objects.filter(company=ctx.company, date=value)
        if self.instance is not None:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError(
                "A holiday already exists on this date."
            )
        return value
