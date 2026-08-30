from django_filters import rest_framework as filters
from rest_framework.exceptions import ValidationError

from apps.attendance.models import Attendance, Holiday
from apps.attendance.services import validate_date_range


class AttendanceFilter(filters.FilterSet):
    employee = filters.UUIDFilter(field_name="employee_id")
    department = filters.UUIDFilter(field_name="employee__department_id")
    start_date = filters.DateFilter(field_name="date", lookup_expr="gte")
    end_date = filters.DateFilter(field_name="date", lookup_expr="lte")

    class Meta:
        model = Attendance
        fields = ("employee", "department", "status", "start_date", "end_date")

    def filter_queryset(self, queryset):
        queryset = super().filter_queryset(queryset)
        start = self.form.cleaned_data.get("start_date") if self.form.is_valid() else None
        end = self.form.cleaned_data.get("end_date") if self.form.is_valid() else None
        if start and end:
            try:
                validate_date_range(start, end)
            except ValidationError:
                raise
        elif start and end is None:
            pass
        return queryset


class HolidayFilter(filters.FilterSet):
    start_date = filters.DateFilter(field_name="date", lookup_expr="gte")
    end_date = filters.DateFilter(field_name="date", lookup_expr="lte")

    class Meta:
        model = Holiday
        fields = ("is_active", "start_date", "end_date")
