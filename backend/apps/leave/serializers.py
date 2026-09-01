from pathlib import Path

from rest_framework import serializers

from apps.common.tenancy import get_tenant_context
from apps.employees.models import Employee
from apps.employees.serializers import TenantPayloadMixin
from apps.leave.models import (
    MAX_REASON_LENGTH,
    MAX_REJECTION_LENGTH,
    MIN_REJECTION_LENGTH,
    LeaveBalance,
    LeaveRequest,
    LeaveType,
    validate_leave_attachment,
)


class LeaveEmployeeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Employee
        fields = ("id", "employee_code", "first_name", "last_name")


class LeaveTypeSerializer(TenantPayloadMixin, serializers.ModelSerializer):
    class Meta:
        model = LeaveType
        fields = (
            "id",
            "name",
            "code",
            "days_allowed",
            "is_paid",
            "carry_forward",
            "status",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_name(self, value: str) -> str:
        name = (value or "").strip()
        if len(name) < 2:
            raise serializers.ValidationError("Enter a leave type name.")
        return name

    def validate_code(self, value: str) -> str:
        code = (value or "").strip().upper()
        request = self.context.get("request")
        company = None
        if request is not None:
            company = get_tenant_context(request).company
        if company is not None:
            queryset = LeaveType.objects.filter(company=company, code=code)
            if self.instance is not None:
                queryset = queryset.exclude(pk=self.instance.pk)
            if queryset.exists():
                raise serializers.ValidationError(
                    "A leave type with this code already exists in this company."
                )
        return code


class LeaveBalanceSerializer(serializers.ModelSerializer):
    employee = LeaveEmployeeSerializer(read_only=True)
    leave_type = LeaveTypeSerializer(read_only=True)

    class Meta:
        model = LeaveBalance
        fields = (
            "id",
            "employee",
            "leave_type",
            "year",
            "allocated_days",
            "used_days",
            "remaining_days",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class LeaveBalanceAllocateSerializer(TenantPayloadMixin, serializers.Serializer):
    allocated_days = serializers.IntegerField(min_value=0)


class LeaveRequestListSerializer(serializers.ModelSerializer):
    employee = LeaveEmployeeSerializer(read_only=True)
    leave_type = LeaveTypeSerializer(read_only=True)

    class Meta:
        model = LeaveRequest
        fields = (
            "id",
            "employee",
            "leave_type",
            "start_date",
            "end_date",
            "total_days",
            "status",
            "created_at",
        )
        read_only_fields = fields


class LeaveRequestDetailSerializer(LeaveRequestListSerializer):
    attachment = serializers.SerializerMethodField()

    class Meta(LeaveRequestListSerializer.Meta):
        fields = (
            *LeaveRequestListSerializer.Meta.fields,
            "reason",
            "attachment",
            "approved_by",
            "approved_at",
            "rejection_reason",
            "updated_at",
        )

    def get_attachment(self, obj) -> str | None:
        if not obj.attachment:
            return None
        name = getattr(obj.attachment, "name", "") or ""
        return Path(name).name or None


class CreateLeaveRequestSerializer(TenantPayloadMixin, serializers.Serializer):
    leave_type = serializers.PrimaryKeyRelatedField(queryset=LeaveType.objects.all())
    start_date = serializers.DateField()
    end_date = serializers.DateField()
    reason = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=MAX_REASON_LENGTH,
    )
    attachment = serializers.FileField(required=False, allow_null=True)

    def validate_attachment(self, value):
        if value is None:
            return value
        validate_leave_attachment(value)
        return value

    def validate_leave_type(self, value):
        request = self.context.get("request")
        company = getattr(getattr(request, "tenant", None), "company", None)
        if company is not None and value.company_id != company.id:
            raise serializers.ValidationError("Unknown leave type.")
        return value


class ApproveLeaveRequestSerializer(TenantPayloadMixin, serializers.Serializer):
    pass


class RejectLeaveRequestSerializer(TenantPayloadMixin, serializers.Serializer):
    rejection_reason = serializers.CharField(max_length=MAX_REJECTION_LENGTH)

    def validate_rejection_reason(self, value: str) -> str:
        reason = (value or "").strip()
        if len(reason) < MIN_REJECTION_LENGTH:
            raise serializers.ValidationError(
                "Enter a meaningful rejection reason."
            )
        return reason


class CancelLeaveRequestSerializer(TenantPayloadMixin, serializers.Serializer):
    pass
