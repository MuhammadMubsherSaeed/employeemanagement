from decimal import Decimal

from rest_framework import serializers

from apps.common.tenancy import get_tenant_context
from apps.devices.models import (
    ASSET_CODE_RE,
    MAX_CONDITION_LENGTH,
    MAX_NOTES_LENGTH,
    Device,
    DeviceAssignment,
    DeviceStatus,
)
from apps.employees.models import Employee
from apps.employees.serializers import TenantPayloadMixin
from apps.leave.serializers import LeaveEmployeeSerializer


class DeviceListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = (
            "id",
            "asset_code",
            "type",
            "manufacturer",
            "model",
            "serial_number",
            "status",
            "purchase_date",
            "warranty_expiry",
            "cost",
            "notes",
            "created_at",
        )

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if not self.context.get("show_sensitive"):
            data.pop("cost", None)
            data.pop("notes", None)
        return data


class DeviceDetailSerializer(DeviceListSerializer):
    class Meta(DeviceListSerializer.Meta):
        fields = (
            *DeviceListSerializer.Meta.fields,
            "updated_at",
        )


class CreateDeviceSerializer(TenantPayloadMixin, serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = (
            "asset_code",
            "type",
            "manufacturer",
            "model",
            "serial_number",
            "purchase_date",
            "warranty_expiry",
            "cost",
            "notes",
        )

    def _company(self):
        request = self.context.get("request")
        if request is None:
            return None
        return get_tenant_context(request).company

    def validate_asset_code(self, value: str) -> str:
        code = (value or "").strip().upper()
        if not ASSET_CODE_RE.match(code):
            raise serializers.ValidationError(
                "Asset code must start with a letter or number and contain "
                "only letters, numbers, hyphens, or underscores."
            )
        company = self._company()
        queryset = Device.objects.filter(company=company, asset_code=code)
        if self.instance is not None:
            queryset = queryset.exclude(pk=self.instance.pk)
        if company is not None and queryset.exists():
            raise serializers.ValidationError(
                "A device with this asset code already exists in this company."
            )
        return code

    def validate_type(self, value: str) -> str:
        type_name = (value or "").strip()
        if len(type_name) < 2:
            raise serializers.ValidationError("Enter a device type.")
        return type_name

    def validate_serial_number(self, value):
        serial = (value or "").strip() or None
        if serial is None:
            return None
        company = self._company()
        queryset = Device.objects.filter(company=company, serial_number=serial)
        if self.instance is not None:
            queryset = queryset.exclude(pk=self.instance.pk)
        if company is not None and queryset.exists():
            raise serializers.ValidationError(
                "A device with this serial number already exists in this company."
            )
        return serial

    def validate_cost(self, value):
        if value is None:
            return Decimal("0.00")
        if value < 0:
            raise serializers.ValidationError("Cost cannot be negative.")
        return value

    def validate(self, attrs):
        purchase = attrs.get("purchase_date")
        warranty = attrs.get("warranty_expiry")
        if self.instance is not None:
            if "purchase_date" not in attrs:
                purchase = self.instance.purchase_date
            if "warranty_expiry" not in attrs:
                warranty = self.instance.warranty_expiry
        if purchase and warranty and warranty < purchase:
            raise serializers.ValidationError(
                {
                    "warranty_expiry": (
                        "Warranty expiry must be on or after the purchase date."
                    )
                }
            )
        return attrs


class UpdateDeviceSerializer(CreateDeviceSerializer):
    status = serializers.ChoiceField(
        choices=DeviceStatus.choices,
        required=False,
    )

    class Meta(CreateDeviceSerializer.Meta):
        fields = (*CreateDeviceSerializer.Meta.fields, "status")


class AssignDeviceSerializer(TenantPayloadMixin, serializers.Serializer):
    employee_id = serializers.UUIDField()
    condition_on_assignment = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=MAX_CONDITION_LENGTH,
    )
    notes = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=MAX_NOTES_LENGTH,
    )

    def validate_employee_id(self, value):
        request = self.context.get("request")
        company = None
        if request is not None:
            company = get_tenant_context(request).company
        queryset = Employee.objects.all()
        if company is not None:
            queryset = queryset.filter(company=company)
        if not queryset.filter(pk=value).exists():
            raise serializers.ValidationError("Unknown employee.")
        return value


class ReturnDeviceSerializer(TenantPayloadMixin, serializers.Serializer):
    condition_on_return = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=MAX_CONDITION_LENGTH,
    )
    notes = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=MAX_NOTES_LENGTH,
    )


class DeviceAssignmentHistorySerializer(serializers.ModelSerializer):
    employee = LeaveEmployeeSerializer(read_only=True)

    class Meta:
        model = DeviceAssignment
        fields = (
            "id",
            "employee",
            "assigned_at",
            "returned_at",
            "condition_on_assignment",
            "condition_on_return",
            "notes",
            "created_at",
        )
