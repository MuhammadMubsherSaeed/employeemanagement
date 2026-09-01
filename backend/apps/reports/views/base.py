from drf_spectacular.utils import OpenApiParameter, OpenApiResponse, extend_schema
from rest_framework.exceptions import PermissionDenied
from rest_framework.generics import GenericAPIView

from apps.common.pagination import StandardPagination
from apps.common.permissions import HasPermission, IsAuthenticatedUser
from apps.common.tenancy import get_tenant_context
from apps.reports.permissions import REPORTS_EXPORT, REPORTS_VIEW
from apps.reports.services.export_service import ExportService
from apps.reports.services.scope import can_see_device_cost
from apps.reports.throttles import ReportExportThrottle

_COMMON_PARAMETERS = [
    OpenApiParameter("page", int, description="Page number"),
    OpenApiParameter("page_size", int, description="Page size (max 100)"),
    OpenApiParameter("search", str),
    OpenApiParameter("ordering", str, description="Whitelisted ordering field"),
]


class ReportPagination(StandardPagination):
    def get_paginated_response(self, data):
        response = super().get_paginated_response(data)
        response.data["message"] = "Report generated successfully."
        return response


def require_report_company(request):
    ctx = get_tenant_context(request)
    if ctx.company is None:
        raise PermissionDenied("You do not have access to this company.")
    return ctx


class ReportListAPIView(GenericAPIView):
    permission_classes = (IsAuthenticatedUser, HasPermission(REPORTS_VIEW))
    pagination_class = ReportPagination
    http_method_names = ["get", "head", "options"]

    def get(self, request, *args, **kwargs):
        require_report_company(request)
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)


class ExportFormatMixin:
    """Capture ?format= before DRF treats it as a renderer suffix."""

    export_format_param = "csv"

    def initialize_request(self, request, *args, **kwargs):
        self.export_format_param = request.GET.get("format") or "csv"
        query = request.GET.copy()
        query.pop("format", None)
        request.GET = query
        return super().initialize_request(request, *args, **kwargs)


class ReportExportAPIView(ExportFormatMixin, GenericAPIView):
    permission_classes = (IsAuthenticatedUser, HasPermission(REPORTS_EXPORT))
    throttle_classes = (ReportExportThrottle,)
    pagination_class = None
    http_method_names = ["get", "head", "options"]
    report_type = ""
    report_title = ""
    filename_stem = ""
    prefetch_for_export = False

    def get_columns(self, request):
        raise NotImplementedError

    def get(self, request, *args, **kwargs):
        require_report_company(request)
        queryset = self.filter_queryset(self.get_queryset())
        return ExportService().export(
            request=request,
            queryset=queryset,
            title=self.report_title,
            filename_stem=self.filename_stem,
            columns=self.get_columns(request),
            export_format=self.export_format_param,
            report_type=self.report_type,
            prefetch=self.prefetch_for_export,
        )


def list_schema(*, tags, description, parameters, responses):
    return extend_schema(
        tags=tags,
        description=description,
        parameters=_COMMON_PARAMETERS + parameters,
        responses={
            200: responses,
            401: OpenApiResponse(description="Unauthenticated."),
            403: OpenApiResponse(description="Missing reports.view."),
        },
    )


def export_schema(*, tags, description, parameters):
    return extend_schema(
        tags=tags,
        description=description,
        parameters=parameters
        + [
            OpenApiParameter(
                "format",
                str,
                enum=["csv", "xlsx", "pdf"],
                description="Export format. Defaults to csv.",
            )
        ],
        responses={
            200: OpenApiResponse(description="Exported file."),
            400: OpenApiResponse(description="Validation error."),
            401: OpenApiResponse(description="Unauthenticated."),
            403: OpenApiResponse(description="Missing reports.export."),
        },
    )


def device_sensitive_context(view, context: dict) -> dict:
    context["show_sensitive"] = can_see_device_cost(get_tenant_context(view.request))
    return context
