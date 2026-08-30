from django.contrib import admin

from apps.employees.models import Department, Employee, Position


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ("name", "company", "status", "manager")
    list_filter = ("status", "company")
    search_fields = ("name", "company__slug")
    raw_id_fields = ("company", "manager")
    readonly_fields = ("created_at", "updated_at")


@admin.register(Position)
class PositionAdmin(admin.ModelAdmin):
    list_display = ("title", "department", "company", "status")
    list_filter = ("status", "company", "department")
    search_fields = ("title", "department__name", "company__slug")
    raw_id_fields = ("company", "department")
    readonly_fields = ("created_at", "updated_at")


@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    list_display = (
        "employee_code",
        "first_name",
        "last_name",
        "company",
        "department",
        "position",
        "status",
        "employment_type",
    )
    list_filter = ("status", "employment_type", "company")
    search_fields = (
        "employee_code",
        "first_name",
        "last_name",
        "user__email",
        "phone",
    )
    raw_id_fields = ("company", "user", "department", "position", "manager")
    readonly_fields = ("created_at", "updated_at")
