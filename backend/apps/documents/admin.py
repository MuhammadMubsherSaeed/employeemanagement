from django.contrib import admin

from apps.documents.models import EmployeeDocument


@admin.register(EmployeeDocument)
class EmployeeDocumentAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "document_type",
        "status",
        "employee",
        "file_name",
        "mime_type",
        "file_size",
        "uploaded_by",
        "expiry_date",
        "company",
        "created_at",
    )
    list_filter = ("status", "document_type", "company")
    search_fields = (
        "title",
        "file_name",
        "employee__employee_code",
        "employee__first_name",
        "employee__last_name",
        "company__slug",
    )
    raw_id_fields = ("company", "employee", "uploaded_by")
    exclude = ("file",)
    readonly_fields = (
        "file_name",
        "file_size",
        "mime_type",
        "uploaded_by",
        "created_at",
        "updated_at",
    )

    def save_model(self, request, obj, form, change):
        if obj.company_id is None and obj.employee_id:
            obj.company_id = obj.employee.company_id
        if obj.uploaded_by_id is None:
            obj.uploaded_by = request.user
        obj.full_clean()
        super().save_model(request, obj, form, change)
