from django.contrib import admin

from apps.leave.models import LeaveBalance, LeaveRequest, LeaveType


@admin.register(LeaveType)
class LeaveTypeAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "code",
        "company",
        "days_allowed",
        "is_paid",
        "carry_forward",
        "status",
    )
    list_filter = ("status", "is_paid", "carry_forward", "company")
    search_fields = ("name", "code", "company__slug")
    raw_id_fields = ("company",)
    readonly_fields = ("created_at", "updated_at")


@admin.register(LeaveBalance)
class LeaveBalanceAdmin(admin.ModelAdmin):
    list_display = (
        "employee",
        "leave_type",
        "year",
        "allocated_days",
        "used_days",
        "remaining_days",
        "company",
    )
    list_filter = ("year", "company", "leave_type")
    search_fields = (
        "employee__employee_code",
        "employee__first_name",
        "employee__last_name",
        "leave_type__code",
    )
    raw_id_fields = ("company", "employee", "leave_type")
    readonly_fields = ("remaining_days", "created_at", "updated_at")


@admin.register(LeaveRequest)
class LeaveRequestAdmin(admin.ModelAdmin):
    list_display = (
        "employee",
        "leave_type",
        "start_date",
        "end_date",
        "total_days",
        "status",
        "company",
    )
    list_filter = ("status", "company", "start_date")
    search_fields = (
        "employee__employee_code",
        "employee__first_name",
        "employee__last_name",
        "reason",
    )
    raw_id_fields = ("company", "employee", "leave_type", "approved_by")
    readonly_fields = (
        "total_days",
        "status",
        "approved_by",
        "approved_at",
        "created_at",
        "updated_at",
    )
