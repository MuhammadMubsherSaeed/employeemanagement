from django_filters import rest_framework as filters

from apps.leave.models import LeaveBalance, LeaveRequest, LeaveType


class LeaveTypeFilter(filters.FilterSet):
    class Meta:
        model = LeaveType
        fields = ("status", "is_paid", "carry_forward")


class LeaveBalanceFilter(filters.FilterSet):
    employee = filters.UUIDFilter(field_name="employee_id")
    leave_type = filters.UUIDFilter(field_name="leave_type_id")

    class Meta:
        model = LeaveBalance
        fields = ("employee", "leave_type", "year")


class LeaveRequestFilter(filters.FilterSet):
    employee = filters.UUIDFilter(field_name="employee_id")
    leave_type = filters.UUIDFilter(field_name="leave_type_id")
    start_date = filters.DateFilter(field_name="start_date", lookup_expr="gte")
    end_date = filters.DateFilter(field_name="end_date", lookup_expr="lte")

    class Meta:
        model = LeaveRequest
        fields = ("employee", "leave_type", "status", "start_date", "end_date")
