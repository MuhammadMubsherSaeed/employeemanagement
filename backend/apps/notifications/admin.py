from django.contrib import admin

from apps.notifications.models import DeviceToken, Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = (
        "type",
        "title",
        "recipient",
        "is_read",
        "company",
        "created_at",
    )
    list_filter = ("type", "is_read", "company")
    search_fields = ("title", "message", "recipient__email", "company__slug")
    raw_id_fields = ("company", "recipient")
    readonly_fields = ("created_at", "updated_at", "read_at", "event_key")


@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "platform",
        "token_preview",
        "is_active",
        "company",
        "last_seen_at",
    )
    list_filter = ("platform", "is_active", "company")
    search_fields = ("user__email", "device_name", "company__slug")
    raw_id_fields = ("company", "user")
    readonly_fields = ("created_at", "updated_at", "last_seen_at", "token_preview")
    exclude = ("token",)

    @admin.display(description="token")
    def token_preview(self, obj: DeviceToken) -> str:
        token = obj.token or ""
        if len(token) <= 12:
            return "••••"
        return f"{token[:6]}…{token[-4:]}"
