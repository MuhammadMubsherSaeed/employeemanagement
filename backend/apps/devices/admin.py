from django.contrib import admin

from apps.devices.models import Device, DeviceAssignment, DeviceStatus


@admin.register(Device)
class DeviceAdmin(admin.ModelAdmin):
    list_display = (
        "asset_code",
        "type",
        "manufacturer",
        "model",
        "status",
        "company",
        "serial_number",
    )
    list_filter = ("status", "type", "company")
    search_fields = (
        "asset_code",
        "manufacturer",
        "model",
        "serial_number",
        "company__slug",
    )
    raw_id_fields = ("company",)
    readonly_fields = ("created_at", "updated_at")

    def get_readonly_fields(self, request, obj=None):
        fields = list(super().get_readonly_fields(request, obj))
        if obj is not None and obj.status == DeviceStatus.ASSIGNED:
            fields.append("status")
        return fields

    def formfield_for_choice_field(self, db_field, request, **kwargs):
        if db_field.name == "status":
            kwargs["choices"] = [
                choice
                for choice in DeviceStatus.choices
                if choice[0] != DeviceStatus.ASSIGNED
            ]
        return super().formfield_for_choice_field(db_field, request, **kwargs)


@admin.register(DeviceAssignment)
class DeviceAssignmentAdmin(admin.ModelAdmin):
    list_display = (
        "device",
        "employee",
        "assigned_at",
        "returned_at",
        "company",
    )
    list_filter = ("company",)
    search_fields = (
        "device__asset_code",
        "employee__employee_code",
        "employee__first_name",
        "employee__last_name",
    )
    raw_id_fields = ("company", "device", "employee")
    readonly_fields = ("created_at", "updated_at")

    def save_model(self, request, obj, form, change):
        obj.full_clean()
        super().save_model(request, obj, form, change)
