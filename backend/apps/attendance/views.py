from calendar import monthrange
from datetime import date

from drf_spectacular.utils import (
    OpenApiParameter,
    OpenApiResponse,
    extend_schema,
    extend_schema_view,
)
from rest_framework.decorators import action
from rest_framework.exceptions import NotFound, ValidationError
from rest_framework.mixins import ListModelMixin, RetrieveModelMixin
from rest_framework.viewsets import GenericViewSet, ModelViewSet

from apps.attendance.filters import AttendanceFilter, HolidayFilter
from apps.attendance.permissions import (
    ATTENDANCE_CHECK_IN,
    ATTENDANCE_CHECK_OUT,
    ATTENDANCE_VIEW,
    HOLIDAY_WRITE_PERMISSION,
)
from apps.attendance.selectors import attendance_queryset, holiday_queryset
from apps.attendance.serializers import (
    AttendanceDetailSerializer,
    AttendanceListSerializer,
    AttendanceSummarySerializer,
    CheckInSerializer,
    CheckOutSerializer,
    HolidaySerializer,
    SummaryQuerySerializer,
)
from apps.attendance.services import (
    AttendanceService,
    CompanyClock,
    resolve_summary_employees,
    validate_date_range,
)
from apps.common.authorization import ObjectAuthorization
from apps.common.mixins import EnvelopeMixin, TenantAwareQuerySetMixin
from apps.common.permissions import HasPermission, IsAuthenticatedUser
from apps.common.responses import success_response
from apps.common.tenancy import get_tenant_context
from apps.companies.services import get_company_settings
from apps.employees.selectors import employee_for_user, employee_queryset

_ATTENDANCE_PERMISSIONS = {
    "list": ATTENDANCE_VIEW,
    "retrieve": ATTENDANCE_VIEW,
    "me": ATTENDANCE_VIEW,
    "summary": ATTENDANCE_VIEW,
    "check_in": ATTENDANCE_CHECK_IN,
    "check_out": ATTENDANCE_CHECK_OUT,
}

_HOLIDAY_WRITE = {
    "create": HOLIDAY_WRITE_PERMISSION,
    "update": HOLIDAY_WRITE_PERMISSION,
    "partial_update": HOLIDAY_WRITE_PERMISSION,
    "destroy": HOLIDAY_WRITE_PERMISSION,
}


@extend_schema_view(
    list=extend_schema(
        tags=["Attendance"],
        description=(
            "List attendance in the authenticated company. "
            "Employees see only their own rows. Managers see self and direct reports."
        ),
        parameters=[
            OpenApiParameter("employee", type=str, description="Employee UUID"),
            OpenApiParameter("department", type=str, description="Department UUID"),
            OpenApiParameter("status", type=str),
            OpenApiParameter("start_date", type=str),
            OpenApiParameter("end_date", type=str),
            OpenApiParameter("ordering", type=str),
            OpenApiParameter("search", type=str),
        ],
    ),
    retrieve=extend_schema(
        tags=["Attendance"],
        description="Fetch one attendance row. Unauthorized or other-company IDs return 404.",
    ),
)
class AttendanceViewSet(
    EnvelopeMixin,
    TenantAwareQuerySetMixin,
    ListModelMixin,
    RetrieveModelMixin,
    GenericViewSet,
):
    queryset = attendance_queryset()
    permission_classes = (IsAuthenticatedUser,)
    filterset_class = AttendanceFilter
    search_fields = (
        "employee__employee_code",
        "employee__first_name",
        "employee__last_name",
        "status",
    )
    ordering_fields = ("date", "check_in", "check_out", "created_at")
    ordering = ("-date", "-check_in")
    http_method_names = ["get", "post", "head", "options"]

    def get_permissions(self):
        code = _ATTENDANCE_PERMISSIONS.get(self.action, ATTENDANCE_VIEW)
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_serializer_class(self):
        if self.action == "list" or self.action == "me":
            return AttendanceListSerializer
        if self.action == "check_in":
            return CheckInSerializer
        if self.action == "check_out":
            return CheckOutSerializer
        if self.action == "summary":
            return SummaryQuerySerializer
        return AttendanceDetailSerializer

    def get_read_serializer(self, instance):
        return AttendanceDetailSerializer(
            instance, context=self.get_serializer_context()
        )

    def create(self, request, *args, **kwargs):
        from rest_framework.exceptions import MethodNotAllowed

        raise MethodNotAllowed("POST")

    @extend_schema(
        tags=["Attendance"],
        description=(
            "Attendance rows for the authenticated employee. Ignores employee_id. "
            "Requires attendance.view."
        ),
        responses={
            200: AttendanceListSerializer,
            401: OpenApiResponse(description="Unauthenticated."),
            404: OpenApiResponse(description="No employee profile."),
        },
    )
    @action(detail=False, methods=["get"], url_path="me")
    def me(self, request, **_kwargs):
        ctx = get_tenant_context(request)
        employee = employee_for_user(user=request.user, company=ctx.company)
        if employee is None:
            raise NotFound()
        queryset = self.filter_queryset(self.get_queryset().filter(employee=employee))
        page = self.paginate_queryset(queryset)
        serializer = AttendanceListSerializer(
            queryset if page is None else page,
            many=True,
            context=self.get_serializer_context(),
        )
        if page is not None:
            return self.get_paginated_response(serializer.data)
        return success_response(data=serializer.data)

    @extend_schema(
        tags=["Attendance"],
        request=CheckInSerializer,
        responses={
            200: AttendanceDetailSerializer,
            400: OpenApiResponse(
                description="Validation or business rule error (duplicate check-in)."
            ),
            401: OpenApiResponse(description="Unauthenticated."),
            403: OpenApiResponse(description="Missing attendance.check_in."),
        },
        description=(
            "Check in for the company-local date. Employee is taken from "
            "request.user. Client timestamps are ignored. Requires "
            "attendance.check_in."
        ),
    )
    @action(detail=False, methods=["post"], url_path="check-in")
    def check_in(self, request, **_kwargs):
        serializer = CheckInSerializer(
            data=request.data, context=self.get_serializer_context()
        )
        serializer.is_valid(raise_exception=True)
        attendance = AttendanceService().check_in(
            request=request,
            latitude=serializer.validated_data.get("latitude"),
            longitude=serializer.validated_data.get("longitude"),
        )
        body = self.get_read_serializer(attendance)
        return success_response(data=body.data, message="Checked in.")

    @extend_schema(
        tags=["Attendance"],
        request=CheckOutSerializer,
        responses={
            200: AttendanceDetailSerializer,
            400: OpenApiResponse(
                description="No check-in, duplicate check-out, or check-out before check-in."
            ),
            401: OpenApiResponse(description="Unauthenticated."),
            403: OpenApiResponse(description="Missing attendance.check_out."),
        },
        description=(
            "Check out against today's company-local attendance row. "
            "Requires attendance.check_out. Client timestamps are ignored."
        ),
    )
    @action(detail=False, methods=["post"], url_path="check-out")
    def check_out(self, request, **_kwargs):
        serializer = CheckOutSerializer(
            data=request.data, context=self.get_serializer_context()
        )
        serializer.is_valid(raise_exception=True)
        attendance = AttendanceService().check_out(
            request=request,
            latitude=serializer.validated_data.get("latitude"),
            longitude=serializer.validated_data.get("longitude"),
        )
        body = self.get_read_serializer(attendance)
        return success_response(data=body.data, message="Checked out.")

    @extend_schema(
        tags=["Attendance"],
        parameters=[
            OpenApiParameter("start_date", type=str, required=False),
            OpenApiParameter("end_date", type=str, required=False),
            OpenApiParameter("employee_id", type=str, required=False),
        ],
        responses={
            200: AttendanceSummarySerializer,
            400: OpenApiResponse(description="Invalid or unbounded date range."),
            401: OpenApiResponse(description="Unauthenticated."),
            403: OpenApiResponse(description="Missing attendance.view."),
            404: OpenApiResponse(description="Unauthorized employee_id."),
        },
        description=(
            "Date-range summary. Employees are scoped to self; managers to "
            "self and direct reports; company admins to the company. "
            "Requires attendance.view. Maximum range is 366 days. "
            "Omitting both dates uses the current company-local month."
        ),
    )
    @action(detail=False, methods=["get"], url_path="summary")
    def summary(self, request, **_kwargs):
        ctx = get_tenant_context(request)
        if ctx.company is None:
            raise ValidationError(
                {"non_field_errors": ["You do not have access to this company."]}
            )
        query = SummaryQuerySerializer(data=request.query_params)
        query.is_valid(raise_exception=True)
        settings = get_company_settings(ctx.company)
        clock = CompanyClock(settings)
        start, end = _summary_bounds(
            query.validated_data.get("start_date"),
            query.validated_data.get("end_date"),
            clock,
        )
        validate_date_range(start, end)
        employees_qs = ObjectAuthorization().filter_queryset(employee_queryset(), ctx)
        employees = resolve_summary_employees(
            ctx=ctx,
            employee_id=query.validated_data.get("employee_id"),
            queryset=employees_qs,
        )
        payload = AttendanceService().summarize(
            company=ctx.company,
            employees=employees,
            start=start,
            end=end,
            settings=settings,
        )
        return success_response(data=AttendanceSummarySerializer(payload).data)


def _summary_bounds(start: date | None, end: date | None, clock: CompanyClock):
    today = clock.local_date()
    if start is None and end is None:
        last_day = monthrange(today.year, today.month)[1]
        return date(today.year, today.month, 1), date(today.year, today.month, last_day)
    if start is None or end is None:
        raise ValidationError(
            {"non_field_errors": ["start_date and end_date are both required."]}
        )
    return start, end


@extend_schema_view(
    list=extend_schema(tags=["Holidays"]),
    retrieve=extend_schema(tags=["Holidays"]),
    create=extend_schema(tags=["Holidays"]),
    update=extend_schema(tags=["Holidays"]),
    partial_update=extend_schema(tags=["Holidays"]),
    destroy=extend_schema(tags=["Holidays"]),
)
class HolidayViewSet(EnvelopeMixin, TenantAwareQuerySetMixin, ModelViewSet):
    queryset = holiday_queryset()
    serializer_class = HolidaySerializer
    permission_classes = (IsAuthenticatedUser,)
    filterset_class = HolidayFilter
    search_fields = ("name", "description")
    ordering_fields = ("date", "name", "created_at")
    ordering = ("-date",)

    def get_permissions(self):
        if self.action in _HOLIDAY_WRITE:
            code = _HOLIDAY_WRITE[self.action]
        else:
            code = ATTENDANCE_VIEW
        return [IsAuthenticatedUser(), HasPermission(code)()]

    def get_read_serializer(self, instance):
        return HolidaySerializer(instance, context=self.get_serializer_context())
