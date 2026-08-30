from django.contrib import admin

from apps.attendance.models import Attendance, Holiday


@admin.register(Holiday)
class HolidayAdmin(admin.ModelAdmin):
    list_display = ("name", "date", "company", "is_active")
    list_filter = ("is_active", "company", "date")
    search_fields = ("name", "company__slug")
    raw_id_fields = ("company",)
    readonly_fields = ("created_at", "updated_at")


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = (
        "date",
        "employee",
        "company",
        "status",
        "check_in",
        "check_out",
        "total_minutes",
    )
    list_filter = ("status", "company", "date")
    search_fields = (
        "employee__employee_code",
        "employee__first_name",
        "employee__last_name",
        "company__slug",
    )
    raw_id_fields = ("company", "employee")
    readonly_fields = ("created_at", "updated_at", "total_minutes", "status")
