from django_filters import rest_framework as filters

from apps.employees.models import Department, Employee, Position


class EmployeeFilter(filters.FilterSet):
    department = filters.UUIDFilter(field_name="department_id")
    position = filters.UUIDFilter(field_name="position_id")
    manager = filters.UUIDFilter(field_name="manager_id")

    class Meta:
        model = Employee
        fields = ("department", "position", "status", "employment_type", "manager")


class DepartmentFilter(filters.FilterSet):
    class Meta:
        model = Department
        fields = ("status",)


class PositionFilter(filters.FilterSet):
    department = filters.UUIDFilter(field_name="department_id")

    class Meta:
        model = Position
        fields = ("department", "status")
