from django.contrib import admin

from apps.audit_logs.models import AuditLog


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = (
        "created_at",
        "action",
        "entity_type",
        "entity_id",
        "user",
        "company",
        "ip_address",
    )
    list_filter = ("action", "entity_type", "created_at")
    search_fields = ("entity_id", "action", "user__email")
    readonly_fields = (
        "id",
        "company",
        "user",
        "action",
        "entity_type",
        "entity_id",
        "old_value",
        "new_value",
        "ip_address",
        "user_agent",
        "created_at",
    )
    ordering = ("-created_at",)

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
