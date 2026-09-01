from django.contrib.auth import get_user_model
from django.db import transaction
from rest_framework import serializers

from apps.common.authorization import ObjectAuthorization
from apps.common.tenancy import get_tenant_context
from apps.employees.models import Department, Employee, Position
from apps.employees.services import (
    department_snapshot,
    employee_snapshot,
    record_department_created,
    record_department_updated,
    record_employee_created,
    record_employee_updated,
)

User = get_user_model()
_TENANT_KEYS = ("company", "company_id", "tenant_id", "membership_id")
_authz = ObjectAuthorization()


def _strip_tenant_keys(data):
    if hasattr(data, "copy"):
        data = data.copy()
        for key in _TENANT_KEYS:
            data.pop(key, None)
    return data


class TenantPayloadMixin:
    def to_internal_value(self, data):
        return super().to_internal_value(_strip_tenant_keys(data))


class DepartmentSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = ("id", "name", "status")


class PositionSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Position
        fields = ("id", "title", "status")


class ManagerSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Employee
        fields = ("id", "employee_code", "first_name", "last_name")


class LinkedUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "email")


class EmployeeListSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(read_only=True)
    department = DepartmentSummarySerializer(read_only=True)
    position = PositionSummarySerializer(read_only=True)
    manager = ManagerSummarySerializer(read_only=True)
    user = LinkedUserSerializer(read_only=True)

    class Meta:
        model = Employee
        fields = (
            "id",
            "employee_code",
            "first_name",
            "last_name",
            "full_name",
            "profile_image",
            "department",
            "position",
            "manager",
            "user",
            "joining_date",
            "employment_type",
            "status",
            "created_at",
        )


class EmployeeDetailSerializer(EmployeeListSerializer):
    class Meta(EmployeeListSerializer.Meta):
        fields = (
            *EmployeeListSerializer.Meta.fields,
            "gender",
            "date_of_birth",
            "phone",
            "address",
            "emergency_contact_name",
            "emergency_contact_relationship",
            "emergency_contact_phone",
            "updated_at",
        )


class EmployeeSelfSerializer(EmployeeDetailSerializer):
    pass


class EmployeeWriteSerializer(TenantPayloadMixin, serializers.ModelSerializer):
    class Meta:
        model = Employee
        fields = (
            "employee_code",
            "first_name",
            "last_name",
            "profile_image",
            "gender",
            "date_of_birth",
            "phone",
            "address",
            "emergency_contact_name",
            "emergency_contact_relationship",
            "emergency_contact_phone",
            "user",
            "department",
            "position",
            "manager",
            "joining_date",
            "employment_type",
            "status",
        )

    def validate_employee_code(self, value: str) -> str:
        company = self._company()
        queryset = Employee.objects.filter(company=company, employee_code=value)
        if self.instance is not None:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError(
                "Employee code already exists in this company."
            )
        return value

    def validate_user(self, value):
        ctx = get_tenant_context(self.context["request"])
        if not _authz.assert_same_tenant(ctx, value):
            raise serializers.ValidationError(
                "Linked user must belong to the same company."
            )
        queryset = Employee.objects.filter(user=value)
        if self.instance is not None:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError(
                "This user is already linked to an employee."
            )
        return value

    def validate_department(self, value):
        return self._same_company(value, "Department")

    def validate_position(self, value):
        return self._same_company(value, "Position")

    def validate_manager(self, value):
        return self._same_company(value, "Manager")

    def validate(self, attrs):
        instance = self.instance
        manager = attrs.get("manager", getattr(instance, "manager", None))
        if instance is not None and manager is not None and manager.pk == instance.pk:
            raise serializers.ValidationError(
                {"manager": "An employee cannot be their own manager."}
            )
        if (
            instance is not None
            and manager is not None
            and manager.manager_id == instance.pk
        ):
            raise serializers.ValidationError(
                {"manager": "Circular manager assignment is not allowed."}
            )
        department = attrs.get("department", getattr(instance, "department", None))
        position = attrs.get("position", getattr(instance, "position", None))
        if (
            department is not None
            and position is not None
            and position.department_id != department.id
        ):
            raise serializers.ValidationError(
                {"position": "Position must belong to the employee's department."}
            )
        return attrs

    def _company(self):
        ctx = get_tenant_context(self.context["request"])
        if ctx.company is None:
            raise serializers.ValidationError(
                "You do not have access to this company."
            )
        return ctx.company

    def _same_company(self, value, label: str):
        if value is None:
            return value
        ctx = get_tenant_context(self.context["request"])
        if not _authz.assert_company_owned(ctx, value):
            raise serializers.ValidationError(
                f"{label} must belong to the same company."
            )
        return value


class EmployeeCreateSerializer(EmployeeWriteSerializer):
    def create(self, validated_data):
        request = self.context.get("request")
        with transaction.atomic():
            employee = super().create(validated_data)
            record_employee_created(employee=employee, request=request)
            return employee


class EmployeeUpdateSerializer(EmployeeWriteSerializer):
    def update(self, instance, validated_data):
        request = self.context.get("request")
        previous = employee_snapshot(instance)
        with transaction.atomic():
            employee = super().update(instance, validated_data)
            record_employee_updated(
                previous=previous, employee=employee, request=request
            )
            return employee


class DepartmentSerializer(TenantPayloadMixin, serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = (
            "id",
            "name",
            "description",
            "manager",
            "status",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_name(self, value: str) -> str:
        ctx = get_tenant_context(self.context["request"])
        if ctx.company is None:
            raise serializers.ValidationError(
                "You do not have access to this company."
            )
        queryset = Department.objects.filter(company=ctx.company, name=value)
        if self.instance is not None:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError(
                "A department with this name already exists."
            )
        return value

    def validate_manager(self, value):
        if value is None:
            return value
        ctx = get_tenant_context(self.context["request"])
        if not _authz.assert_company_owned(ctx, value):
            raise serializers.ValidationError(
                "Department manager must belong to the same company."
            )
        return value

    def create(self, validated_data):
        request = self.context.get("request")
        with transaction.atomic():
            department = super().create(validated_data)
            record_department_created(department=department, request=request)
            return department

    def update(self, instance, validated_data):
        request = self.context.get("request")
        previous = department_snapshot(instance)
        with transaction.atomic():
            department = super().update(instance, validated_data)
            record_department_updated(
                previous=previous, department=department, request=request
            )
            return department


class PositionSerializer(TenantPayloadMixin, serializers.ModelSerializer):
    class Meta:
        model = Position
        fields = (
            "id",
            "department",
            "title",
            "description",
            "status",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_department(self, value):
        ctx = get_tenant_context(self.context["request"])
        if not _authz.assert_company_owned(ctx, value):
            raise serializers.ValidationError(
                "Position department must belong to the same company."
            )
        return value

    def validate(self, attrs):
        ctx = get_tenant_context(self.context["request"])
        department = attrs.get("department", getattr(self.instance, "department", None))
        title = attrs.get("title", getattr(self.instance, "title", None))
        if ctx.company is not None and department is not None and title:
            queryset = Position.objects.filter(
                company=ctx.company,
                department=department,
                title=title,
            )
            if self.instance is not None:
                queryset = queryset.exclude(pk=self.instance.pk)
            if queryset.exists():
                raise serializers.ValidationError(
                    {"title": "A position with this title already exists."}
                )
        return attrs
