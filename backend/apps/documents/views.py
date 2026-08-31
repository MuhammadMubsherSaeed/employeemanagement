from drf_spectacular.utils import (
    OpenApiParameter,
    extend_schema,
    extend_schema_view,
)
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.viewsets import ModelViewSet

from apps.common.mixins import EnvelopeMixin, TenantAwareQuerySetMixin
from apps.common.permissions import HasPermission, IsAuthenticatedUser
from apps.common.responses import success_response
from apps.common.tenancy import get_tenant_context
from apps.documents.filters import DocumentFilter
from apps.documents.permissions import (
    DOCUMENTS_CREATE,
    DOCUMENTS_DELETE,
    DOCUMENTS_DOWNLOAD,
    DOCUMENTS_UPDATE,
    DOCUMENTS_VIEW,
)
from apps.documents.selectors import document_queryset
from apps.documents.serializers import (
    CreateDocumentSerializer,
    DocumentDetailSerializer,
    DocumentListSerializer,
    UpdateDocumentSerializer,
)
from apps.documents.services import DocumentService, resolve_employee

_ACTION_PERMISSIONS = {
    "list": DOCUMENTS_VIEW,
    "retrieve": DOCUMENTS_VIEW,
    "create": DOCUMENTS_CREATE,
    "update": DOCUMENTS_UPDATE,
    "partial_update": DOCUMENTS_UPDATE,
    "destroy": DOCUMENTS_DELETE,
    "download": DOCUMENTS_DOWNLOAD,
}


@extend_schema_view(
    list=extend_schema(
        tags=["Documents"],
        description=(
            "List employee documents in authorization scope. Employees see only "
            "their own documents. Managers see their direct reports. "
            "File contents are not included; use the download action."
        ),
        parameters=[
            OpenApiParameter("status", type=str),
            OpenApiParameter("document_type", type=str),
            OpenApiParameter("employee", type=str),
            OpenApiParameter("expired", type=bool),
            OpenApiParameter("expiring_soon", type=bool),
            OpenApiParameter("expiry_date_from", type=str),
            OpenApiParameter("expiry_date_to", type=str),
            OpenApiParameter("search", type=str),
        ],
    ),
    retrieve=extend_schema(
        tags=["Documents"],
        description="Fetch document metadata. Other companies' IDs return 404.",
    ),
    create=extend_schema(
        tags=["Documents"],
        request={"multipart/form-data": CreateDocumentSerializer},
        description=(
            "Upload an employee document (multipart). Company, uploaded_by, "
            "file_name, file_size, and mime_type are set by the server. "
            "Requires documents.create."
        ),
    ),
    update=extend_schema(
        tags=["Documents"],
        description="Update document metadata and optionally replace the file.",
    ),
    partial_update=extend_schema(tags=["Documents"]),
    destroy=extend_schema(
        tags=["Documents"],
        description="Delete a document and its stored file. Requires documents.delete.",
    ),
)
class DocumentViewSet(EnvelopeMixin, TenantAwareQuerySetMixin, ModelViewSet):
    queryset = document_queryset()
    permission_classes = (IsAuthenticatedUser,)
    parser_classes = (JSONParser, MultiPartParser, FormParser)
    filterset_class = DocumentFilter
    search_fields = (
        "title",
        "file_name",
        "document_type",
        "employee__first_name",
        "employee__last_name",
        "employee__employee_code",
    )
    ordering_fields = (
        "created_at",
        "title",
        "document_type",
        "status",
        "expiry_date",
        "file_name",
    )
    ordering = ("-created_at",)

    def get_permissions(self):
        code = _ACTION_PERMISSIONS.get(self.action, DOCUMENTS_VIEW)
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_serializer_class(self):
        if self.action == "create":
            return CreateDocumentSerializer
        if self.action in ("update", "partial_update"):
            return UpdateDocumentSerializer
        if self.action == "list":
            return DocumentListSerializer
        return DocumentDetailSerializer

    def get_read_serializer(self, instance):
        return DocumentDetailSerializer(instance, context=self.get_serializer_context())

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        ctx = get_tenant_context(request)
        employee = resolve_employee(
            company=ctx.company,
            employee_id=serializer.validated_data["employee_id"],
        )
        document = DocumentService().create_document(
            request=request,
            validated={**serializer.validated_data, "employee": employee},
        )
        return success_response(
            data=self.get_read_serializer(document).data,
            message="Uploaded.",
        )

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(
            instance,
            data=request.data,
            partial=partial,
        )
        serializer.is_valid(raise_exception=True)
        document = DocumentService().update_document(
            request=request,
            document=instance,
            validated=dict(serializer.validated_data),
        )
        return success_response(
            data=self.get_read_serializer(document).data,
            message="Updated.",
        )

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        DocumentService().delete_document(request=request, document=instance)
        return success_response(data={}, message="Deleted.")

    @extend_schema(
        tags=["Documents"],
        description=(
            "Download the stored file after authentication, tenant, and "
            "object-level authorization. Requires documents.download. "
            "Does not return a public URL."
        ),
        responses={200: bytes},
    )
    @action(detail=True, methods=["get"], url_path="download")
    def download(self, request, pk=None, **_kwargs):
        document = self.get_object()
        return DocumentService().download_document(
            request=request,
            document=document,
        )
