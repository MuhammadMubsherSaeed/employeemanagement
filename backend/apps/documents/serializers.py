from rest_framework import serializers

from apps.common.tenancy import get_tenant_context
from apps.documents.models import (
    MAX_DESCRIPTION_LENGTH,
    MAX_TITLE_LENGTH,
    DocumentStatus,
    DocumentType,
    EmployeeDocument,
    validate_employee_document_file,
)
from apps.employees.models import Employee
from apps.employees.serializers import LinkedUserSerializer, TenantPayloadMixin
from apps.leave.serializers import LeaveEmployeeSerializer


class DocumentListSerializer(serializers.ModelSerializer):
    employee = LeaveEmployeeSerializer(read_only=True)
    uploaded_by = LinkedUserSerializer(read_only=True)

    class Meta:
        model = EmployeeDocument
        fields = (
            "id",
            "employee",
            "document_type",
            "title",
            "description",
            "file_name",
            "file_size",
            "mime_type",
            "status",
            "expiry_date",
            "uploaded_by",
            "created_at",
        )


class DocumentDetailSerializer(DocumentListSerializer):
    class Meta(DocumentListSerializer.Meta):
        fields = (*DocumentListSerializer.Meta.fields, "updated_at")


class CreateDocumentSerializer(TenantPayloadMixin, serializers.Serializer):
    employee_id = serializers.UUIDField()
    document_type = serializers.ChoiceField(choices=DocumentType.choices)
    title = serializers.CharField(max_length=MAX_TITLE_LENGTH)
    description = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=MAX_DESCRIPTION_LENGTH,
    )
    file = serializers.FileField()
    expiry_date = serializers.DateField(required=False, allow_null=True)

    def validate_title(self, value: str) -> str:
        title = (value or "").strip()
        if len(title) < 2:
            raise serializers.ValidationError("Enter a document title.")
        return title

    def validate_file(self, value):
        validate_employee_document_file(value)
        return value

    def validate_employee_id(self, value):
        request = self.context.get("request")
        company = None
        if request is not None:
            company = get_tenant_context(request).company
        queryset = Employee.objects.all()
        if company is not None:
            queryset = queryset.filter(company=company)
        if not queryset.filter(pk=value).exists():
            raise serializers.ValidationError("Unknown employee.")
        return value


class UpdateDocumentSerializer(TenantPayloadMixin, serializers.ModelSerializer):
    file = serializers.FileField(required=False)

    class Meta:
        model = EmployeeDocument
        fields = (
            "title",
            "description",
            "document_type",
            "expiry_date",
            "status",
            "file",
        )

    def validate_title(self, value: str) -> str:
        title = (value or "").strip()
        if len(title) < 2:
            raise serializers.ValidationError("Enter a document title.")
        return title

    def validate_file(self, value):
        validate_employee_document_file(value)
        return value

    def validate_status(self, value: str) -> str:
        if value not in DocumentStatus.values:
            raise serializers.ValidationError("Unknown status.")
        return value
