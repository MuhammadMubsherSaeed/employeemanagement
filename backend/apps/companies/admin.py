from django.contrib import admin

from apps.companies.models import Company, CompanyMembership, TenantOwnedRecord

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
