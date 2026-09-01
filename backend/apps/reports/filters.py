from django.db.models import Q
from django_filters import rest_framework as filters

from apps.attendance.models import Attendance
from apps.devices.models import Device
from apps.employees.models import Employee
from apps.leave.models import LeaveRequest
from apps.reports.services.dates import validate_report_date_range


class AttendanceReportFilter(filters.FilterSet):
    date_from = filters.DateFilter(field_name="date", lookup_expr="gte")
    date_to = filters.DateFilter(field_name="date", lookup_expr="lte")
    employee = filters.UUIDFilter(field_name="employee_id")
    department = filters.UUIDFilter(field_name="employee__department_id")

    class Meta:
        model = Attendance
        fields = ("date_from", "date_to", "employee", "department", "status")

    def is_valid(self):
        validate_report_date_range(self.data)
        return super().is_valid()


class LeaveReportFilter(filters.FilterSet):
    date_from = filters.DateFilter(method="filter_date_from")
    date_to = filters.DateFilter(method="filter_date_to")
    employee = filters.UUIDFilter(field_name="employee_id")
    department = filters.UUIDFilter(field_name="employee__department_id")
    leave_type = filters.UUIDFilter(field_name="leave_type_id")

    class Meta:
        model = LeaveRequest
        fields = (
            "date_from",
            "date_to",
            "employee",
            "department",
            "status",
            "leave_type",
        )

    def is_valid(self):
        validate_report_date_range(self.data)
        return super().is_valid()

    def filter_date_from(self, queryset, name, value):
        return queryset.filter(end_date__gte=value)

    def filter_date_to(self, queryset, name, value):
        return queryset.filter(start_date__lte=value)


class EmployeeReportFilter(filters.FilterSet):
    employee = filters.UUIDFilter(field_name="id")
    department = filters.UUIDFilter(field_name="department_id")

    class Meta:
        model = Employee
        fields = ("employee", "department", "status", "employment_type")


class DeviceReportFilter(filters.FilterSet):
    employee = filters.UUIDFilter(method="filter_employee")
    department = filters.UUIDFilter(method="filter_department")

    class Meta:
        model = Device
        fields = ("employee", "department", "status")

    def filter_employee(self, queryset, name, value):
        return queryset.filter(
            Q(assignments__employee_id=value)
            & Q(assignments__returned_at__isnull=True)
        ).distinct()

    def filter_department(self, queryset, name, value):
        return queryset.filter(
            Q(assignments__employee__department_id=value)
            & Q(assignments__returned_at__isnull=True)
        ).distinct()
