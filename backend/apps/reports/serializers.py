from rest_framework import serializers

from apps.attendance.models import Attendance
from apps.devices.models import Device
from apps.employees.models import Employee
from apps.employees.serializers import (
    DepartmentSummarySerializer,
    ManagerSummarySerializer,
    PositionSummarySerializer,
)
from apps.leave.models import LeaveRequest
from apps.leave.serializers import LeaveEmployeeSerializer
from apps.reports.services.scope import active_assignment


class ReportEmployeeSerializer(LeaveEmployeeSerializer):
    department = DepartmentSummarySerializer(read_only=True)

    class Meta(LeaveEmployeeSerializer.Meta):
        fields = (*LeaveEmployeeSerializer.Meta.fields, "department")


class AttendanceReportSerializer(serializers.ModelSerializer):
    employee = ReportEmployeeSerializer(read_only=True)
    working_minutes = serializers.IntegerField(
        source="total_minutes", allow_null=True, read_only=True
    )

    class Meta:
        model = Attendance
        fields = (
            "id",
            "employee",
            "date",
            "check_in",
            "check_out",
            "working_minutes",
            "status",
        )
        read_only_fields = fields


class LeaveReportSerializer(serializers.ModelSerializer):
    employee = ReportEmployeeSerializer(read_only=True)
    leave_type = serializers.SerializerMethodField()
    approved_by = serializers.SerializerMethodField()

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
            "approved_by",
            "approved_at",
        )
        read_only_fields = fields

    def get_leave_type(self, instance) -> dict:
        leave_type = instance.leave_type
        return {
            "id": str(leave_type.id),
            "name": leave_type.name,
            "code": leave_type.code,
        }

    def get_approved_by(self, instance) -> dict | None:
        actor = instance.approved_by
        if actor is None:
            return None
        return {"id": actor.id, "email": actor.email}


class EmployeeReportSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(read_only=True)
    department = DepartmentSummarySerializer(read_only=True)
    position = PositionSummarySerializer(read_only=True)
    manager = ManagerSummarySerializer(read_only=True)

    class Meta:
        model = Employee
        fields = (
            "id",
            "employee_code",
            "first_name",
            "last_name",
            "full_name",
            "department",
            "position",
            "manager",
            "employment_type",
            "joining_date",
            "status",
        )
        read_only_fields = fields


class DeviceReportSerializer(serializers.ModelSerializer):
    assigned_employee = serializers.SerializerMethodField()
    assigned_at = serializers.SerializerMethodField()
    returned_at = serializers.SerializerMethodField()

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
            "assigned_employee",
            "assigned_at",
            "returned_at",
            "cost",
        )
        read_only_fields = fields

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if not self.context.get("show_sensitive"):
            data.pop("cost", None)
        return data

    def get_assigned_employee(self, instance) -> dict | None:
        assignment = active_assignment(instance)
        if assignment is None:
            return None
        return LeaveEmployeeSerializer(assignment.employee).data

    def get_assigned_at(self, instance):
        assignment = active_assignment(instance)
        return assignment.assigned_at if assignment else None

    def get_returned_at(self, instance):
        assignment = active_assignment(instance)
        return assignment.returned_at if assignment else None
