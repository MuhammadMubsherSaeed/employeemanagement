from drf_spectacular.utils import OpenApiParameter

from apps.attendance.models import Attendance
from apps.reports.filters import AttendanceReportFilter
from apps.reports.serializers import AttendanceReportSerializer
from apps.reports.services.attendance_reports import AttendanceReportService
from apps.reports.views.base import (
    ReportExportAPIView,
    ReportListAPIView,
    export_schema,
    list_schema,
)

_service = AttendanceReportService()
_PARAMETERS = [
    OpenApiParameter("date_from", str, description="Inclusive start date (YYYY-MM-DD)"),
    OpenApiParameter("date_to", str, description="Inclusive end date (YYYY-MM-DD)"),
    OpenApiParameter("employee", str, description="Employee UUID"),
    OpenApiParameter("department", str, description="Department UUID"),
    OpenApiParameter("status", str),
]


@list_schema(
    tags=["Reports"],
    description=(
        "Paginated attendance report for the authenticated company. "
        "Requires reports.view. Managers see self and direct reports. "
        "Employees are denied unless reports.view is granted, in which case "
        "rows are still scoped to the authenticated employee. "
        "company_id is ignored."
    ),
    parameters=_PARAMETERS,
    responses=AttendanceReportSerializer,
)
class AttendanceReportView(ReportListAPIView):
    queryset = Attendance.objects.none()
    serializer_class = AttendanceReportSerializer
    filterset_class = AttendanceReportFilter
    search_fields = (
        "employee__employee_code",
        "employee__first_name",
        "employee__last_name",
        "employee__department__name",
        "status",
    )
    ordering_fields = ("date", "status", "created_at", "check_in")
    ordering = ("-date", "-check_in")

    def get_queryset(self):
        return _service.queryset(self.request)


@export_schema(
    tags=["Reports"],
    description=(
        "Export the attendance report. Requires reports.export. "
        "Uses the same filters and authorization as the list endpoint."
    ),
    parameters=_PARAMETERS,
)
class AttendanceReportExportView(ReportExportAPIView):
    queryset = Attendance.objects.none()
    serializer_class = AttendanceReportSerializer
    filterset_class = AttendanceReportFilter
    search_fields = AttendanceReportView.search_fields
    ordering_fields = AttendanceReportView.ordering_fields
    ordering = AttendanceReportView.ordering
    report_type = "attendance"
    report_title = _service.title
    filename_stem = _service.filename_stem

    def get_queryset(self):
        return _service.queryset(self.request)

    def get_columns(self, request):
        return _service.columns()
