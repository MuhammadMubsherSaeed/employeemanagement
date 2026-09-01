from drf_spectacular.utils import OpenApiParameter

from apps.devices.models import Device
from apps.reports.filters import DeviceReportFilter
from apps.reports.serializers import DeviceReportSerializer
from apps.reports.services.device_reports import DeviceReportService
from apps.reports.views.base import (
    ReportExportAPIView,
    ReportListAPIView,
    device_sensitive_context,
    export_schema,
    list_schema,
)

_service = DeviceReportService()
_PARAMETERS = [
    OpenApiParameter("employee", str, description="Currently assigned employee UUID"),
    OpenApiParameter(
        "department",
        str,
        description="Department UUID of the currently assigned employee",
    ),
    OpenApiParameter("status", str),
]


@list_schema(
    tags=["Reports"],
    description=(
        "Paginated device report with current assignment. Requires reports.view. "
        "Cost is included only when the user can create/update/delete devices. "
        "Managers see available devices plus devices assigned to their team. "
        "company_id is ignored."
    ),
    parameters=_PARAMETERS,
    responses=DeviceReportSerializer,
)
class DeviceReportView(ReportListAPIView):
    queryset = Device.objects.none()
    serializer_class = DeviceReportSerializer
    filterset_class = DeviceReportFilter
    search_fields = (
        "asset_code",
        "serial_number",
        "manufacturer",
        "model",
        "type",
    )
    ordering_fields = ("asset_code", "status", "type", "created_at")
    ordering = ("asset_code",)

    def get_queryset(self):
        return _service.queryset(self.request)

    def get_serializer_context(self):
        return device_sensitive_context(self, super().get_serializer_context())


@export_schema(
    tags=["Reports"],
    description=(
        "Export the device report. Requires reports.export. "
        "Uses the same filters and authorization as the list endpoint. "
        "Cost is exported only when authorized."
    ),
    parameters=_PARAMETERS,
)
class DeviceReportExportView(ReportExportAPIView):
    queryset = Device.objects.none()
    serializer_class = DeviceReportSerializer
    filterset_class = DeviceReportFilter
    search_fields = DeviceReportView.search_fields
    ordering_fields = DeviceReportView.ordering_fields
    ordering = DeviceReportView.ordering
    report_type = "device"
    report_title = _service.title
    filename_stem = _service.filename_stem
    prefetch_for_export = True

    def get_queryset(self):
        return _service.queryset(self.request)

    def get_serializer_context(self):
        return device_sensitive_context(self, super().get_serializer_context())

    def get_columns(self, request):
        return _service.columns(request)
