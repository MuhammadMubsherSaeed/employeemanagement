from django.contrib import admin

from apps.common.models import AuditEvent

admin.site.site_header = "HRMS Administration"
admin.site.site_title = "HRMS Admin"
admin.site.index_title = "Foundation"


@admin.register(AuditEvent)
class AuditEventAdmin(admin.ModelAdmin):
    list_display = ("action", "resource", "resource_id", "company", "actor", "created_at")
    list_filter = ("action", "resource", "company")
    search_fields = ("action", "resource", "resource_id", "actor__email")
    raw_id_fields = ("company", "actor")
    readonly_fields = (
        "company",
        "actor",
        "action",
        "resource",
        "resource_id",
        "metadata",
        "created_at",
        "updated_at",
    )
