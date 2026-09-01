from rest_framework import serializers

from apps.common.models import AuditEvent
from apps.devices.serializers import DeviceListSerializer
from apps.employees.models import Employee
from apps.employees.serializers import (
    DepartmentSummarySerializer,
    PositionSummarySerializer,
)
from apps.leave.models import LeaveBalance, LeaveRequest, LeaveType


class DashboardLeaveTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = LeaveType
        fields = ("id", "name", "code")


class DashboardRecentEmployeeSerializer(serializers.ModelSerializer):
    department = DepartmentSummarySerializer(read_only=True)
    position = PositionSummarySerializer(read_only=True)
    profile_image = serializers.SerializerMethodField()

    class Meta:
        model = Employee
        fields = (
            "id",
            "employee_code",
            "first_name",
            "last_name",
            "profile_image",
            "department",
            "position",
            "status",
            "joining_date",
            "created_at",
        )
        read_only_fields = fields

    def get_profile_image(self, obj) -> str:
        from apps.employees.services import public_profile_image_value

        return public_profile_image_value(obj)


class DashboardAuditActorSerializer(serializers.Serializer):
    id = serializers.IntegerField(allow_null=True)
    email = serializers.EmailField(allow_null=True)


class DashboardActivitySerializer(serializers.ModelSerializer):
    actor = DashboardAuditActorSerializer(read_only=True, allow_null=True)

    class Meta:
        model = AuditEvent
        fields = (
            "id",
            "action",
            "resource",
            "resource_id",
            "created_at",
            "actor",
        )
        read_only_fields = fields


class DashboardTodayAttendanceSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    date = serializers.DateField()
    check_in = serializers.DateTimeField(allow_null=True)
    check_out = serializers.DateTimeField(allow_null=True)
    total_minutes = serializers.IntegerField(allow_null=True)
    status = serializers.CharField()


class DashboardLeaveBalanceSerializer(serializers.ModelSerializer):
    leave_type = DashboardLeaveTypeSerializer(read_only=True)

    class Meta:
        model = LeaveBalance
        fields = (
            "leave_type",
            "allocated_days",
            "used_days",
            "remaining_days",
            "year",
        )
        read_only_fields = fields


class DashboardLeaveRequestSerializer(serializers.ModelSerializer):
    leave_type = DashboardLeaveTypeSerializer(read_only=True)

    class Meta:
        model = LeaveRequest
        fields = (
            "id",
            "leave_type",
            "start_date",
            "end_date",
            "total_days",
            "status",
            "created_at",
            "rejection_reason",
        )
        read_only_fields = fields


class AdminDashboardSerializer(serializers.Serializer):
    total_employees = serializers.IntegerField()
    active_employees = serializers.IntegerField()
    inactive_employees = serializers.IntegerField()
    present_today = serializers.IntegerField()
    absent_today = serializers.IntegerField()
    late_today = serializers.IntegerField()
    on_leave_today = serializers.IntegerField()
    pending_leave_requests = serializers.IntegerField()
    recent_employees = DashboardRecentEmployeeSerializer(many=True)
    recent_activity = DashboardActivitySerializer(many=True)


class ManagerDashboardSerializer(serializers.Serializer):
    team_size = serializers.IntegerField()
    team_present = serializers.IntegerField()
    team_absent = serializers.IntegerField()
    team_late = serializers.IntegerField()
    team_on_leave = serializers.IntegerField()
    pending_leave_requests = serializers.IntegerField()
    recent_activity = DashboardActivitySerializer(many=True)


class EmployeeDashboardSerializer(serializers.Serializer):
    today_attendance = DashboardTodayAttendanceSerializer(allow_null=True)
    working_minutes = serializers.IntegerField()
    leave_balances = DashboardLeaveBalanceSerializer(many=True)
    recent_leave_requests = DashboardLeaveRequestSerializer(many=True)
    assigned_devices = DeviceListSerializer(many=True)
    notifications_count = serializers.IntegerField()
