from django.contrib import admin

from apps.companies.models import (
    Company,
    CompanyMembership,
    CompanySettings,
    TenantOwnedRecord,
)

admin.site.empty_value_display = "—"


@admin.register(Company)
class CompanyAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "is_active", "email")
    list_filter = ("is_active",)
    search_fields = ("name", "slug", "email")
    prepopulated_fields = {"slug": ("name",)}


@admin.register(CompanyMembership)
class CompanyMembershipAdmin(admin.ModelAdmin):
    list_display = ("user", "company", "role", "is_active")
    list_filter = ("is_active", "role", "company")
    search_fields = ("user__email", "company__slug")
    raw_id_fields = ("user", "company", "role")


@admin.register(TenantOwnedRecord)
class TenantOwnedRecordAdmin(admin.ModelAdmin):
    list_display = ("title", "company", "visibility", "owner")
    list_filter = ("visibility", "company")
    search_fields = ("title",)


@admin.register(CompanySettings)
class CompanySettingsAdmin(admin.ModelAdmin):
    list_display = (
        "company",
        "timezone",
        "work_start_time",
        "work_end_time",
        "grace_period_minutes",
        "overtime_enabled",
    )
    list_filter = ("timezone", "overtime_enabled")
    search_fields = ("company__name", "company__slug", "timezone")
    raw_id_fields = ("company",)
    readonly_fields = ("created_at", "updated_at")
