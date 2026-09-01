from drf_spectacular.utils import OpenApiParameter

from apps.employees.models import Employee
from apps.reports.filters import EmployeeReportFilter
from apps.reports.serializers import EmployeeReportSerializer
from apps.reports.services.employee_reports import EmployeeReportService
from apps.reports.views.base import (
    ReportExportAPIView,
    ReportListAPIView,
    export_schema,
    list_schema,
)

_service = EmployeeReportService()
_PARAMETERS = [
    OpenApiParameter("employee", str, description="Employee UUID"),
    OpenApiParameter("department", str, description="Department UUID"),
    OpenApiParameter("status", str),
    OpenApiParameter("employment_type", str),
]


@list_schema(
    tags=["Reports"],
    description=(
        "Paginated employee directory report. Requires reports.view. "
        "Employees without reports.view receive 403. Managers see self and "
        "direct reports only. Does not include profile contact fields. "
        "company_id is ignored."
    ),
    parameters=_PARAMETERS,
    responses=EmployeeReportSerializer,
)
class EmployeeReportView(ReportListAPIView):
    queryset = Employee.objects.none()
    serializer_class = EmployeeReportSerializer
    filterset_class = EmployeeReportFilter
    search_fields = (
        "employee_code",
        "first_name",
        "last_name",
        "department__name",
        "position__title",
    )
    ordering_fields = (
        "employee_code",
        "first_name",
        "last_name",
        "joining_date",
        "status",
        "created_at",
    )
    ordering = ("employee_code",)

    def get_queryset(self):
        return _service.queryset(self.request)


@export_schema(
    tags=["Reports"],
    description=(
        "Export the employee report. Requires reports.export. "
        "Uses the same filters and authorization as the list endpoint."
    ),
    parameters=_PARAMETERS,
)
class EmployeeReportExportView(ReportExportAPIView):
    queryset = Employee.objects.none()
    serializer_class = EmployeeReportSerializer
    filterset_class = EmployeeReportFilter
    search_fields = EmployeeReportView.search_fields
    ordering_fields = EmployeeReportView.ordering_fields
    ordering = EmployeeReportView.ordering
    report_type = "employee"
    report_title = _service.title
    filename_stem = _service.filename_stem

    def get_queryset(self):
        return _service.queryset(self.request)

    def get_columns(self, request):
        return _service.columns()
