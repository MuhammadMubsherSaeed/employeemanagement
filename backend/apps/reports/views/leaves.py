from drf_spectacular.utils import OpenApiParameter

from apps.leave.models import LeaveRequest
from apps.reports.filters import LeaveReportFilter
from apps.reports.serializers import LeaveReportSerializer
from apps.reports.services.leave_reports import LeaveReportService
from apps.reports.views.base import (
    ReportExportAPIView,
    ReportListAPIView,
    export_schema,
    list_schema,
)

_service = LeaveReportService()
_PARAMETERS = [
    OpenApiParameter("date_from", str, description="Leave overlapping this start date"),
    OpenApiParameter("date_to", str, description="Leave overlapping this end date"),
    OpenApiParameter("employee", str, description="Employee UUID"),
    OpenApiParameter("department", str, description="Department UUID"),
    OpenApiParameter("status", str),
    OpenApiParameter("leave_type", str, description="Leave type UUID"),
]


@list_schema(
    tags=["Reports"],
    description=(
        "Paginated leave request report. Requires reports.view. "
        "date_from/date_to match overlapping leave periods. "
        "Managers see self and direct reports. company_id is ignored."
    ),
    parameters=_PARAMETERS,
    responses=LeaveReportSerializer,
)
class LeaveReportView(ReportListAPIView):
    queryset = LeaveRequest.objects.none()
    serializer_class = LeaveReportSerializer
    filterset_class = LeaveReportFilter
    search_fields = (
        "employee__employee_code",
        "employee__first_name",
        "employee__last_name",
        "leave_type__name",
        "leave_type__code",
        "status",
    )
    ordering_fields = ("start_date", "end_date", "status", "created_at")
    ordering = ("-start_date", "-created_at")

    def get_queryset(self):
        return _service.queryset(self.request)


@export_schema(
    tags=["Reports"],
    description=(
        "Export the leave report. Requires reports.export. "
        "Uses the same filters and authorization as the list endpoint."
    ),
    parameters=_PARAMETERS,
)
class LeaveReportExportView(ReportExportAPIView):
    queryset = LeaveRequest.objects.none()
    serializer_class = LeaveReportSerializer
    filterset_class = LeaveReportFilter
    search_fields = LeaveReportView.search_fields
    ordering_fields = LeaveReportView.ordering_fields
    ordering = LeaveReportView.ordering
    report_type = "leave"
    report_title = _service.title
    filename_stem = _service.filename_stem

    def get_queryset(self):
        return _service.queryset(self.request)

    def get_columns(self, request):
        return _service.columns()
