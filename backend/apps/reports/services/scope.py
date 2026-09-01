from django.db.models import Prefetch

from apps.attendance.selectors import attendance_queryset
from apps.common.authorization import ObjectAuthorization
from apps.common.tenancy import TenantContext, get_tenant_context
from apps.devices.models import Device, DeviceAssignment
from apps.devices.selectors import device_queryset
from apps.employees.selectors import employee_queryset
from apps.leave.selectors import leave_request_queryset

_authz = ObjectAuthorization()

_ATTENDANCE_DEFER = (
    "check_in_ip",
    "check_out_ip",
    "check_in_latitude",
    "check_in_longitude",
    "check_out_latitude",
    "check_out_longitude",
)
_EMPLOYEE_DEFER = (
    "phone",
    "address",
    "date_of_birth",
    "emergency_contact_name",
    "emergency_contact_relationship",
    "emergency_contact_phone",
    "gender",
    "profile_image",
)
_LEAVE_DEFER = ("reason", "attachment", "rejection_reason")


def scoped_report_queryset(request, queryset):
    """Tenant + manager/employee object scope. Never uses company_id from the client."""
    ctx = get_tenant_context(request)
    if ctx.company is None:
        return queryset.none()
    queryset = queryset.filter(company_id=ctx.company.id)
    return _authz.filter_queryset(queryset, ctx)


def attendance_report_queryset(request):
    return scoped_report_queryset(
        request, attendance_queryset().defer(*_ATTENDANCE_DEFER)
    )


def leave_report_queryset(request):
    return scoped_report_queryset(
        request,
        leave_request_queryset()
        .select_related("employee__department")
        .defer(*_LEAVE_DEFER),
    )


def employee_report_queryset(request):
    return scoped_report_queryset(
        request, employee_queryset().defer(*_EMPLOYEE_DEFER)
    )


def device_report_queryset(request):
    active = DeviceAssignment.objects.filter(returned_at__isnull=True).select_related(
        "employee",
        "employee__department",
    )
    queryset = (
        device_queryset()
        .defer("notes")
        .prefetch_related(
            Prefetch("assignments", queryset=active, to_attr="active_assignment_rows")
        )
    )
    return scoped_report_queryset(request, queryset)


def active_assignment(device: Device):
    rows = getattr(device, "active_assignment_rows", None)
    if rows is not None:
        return rows[0] if rows else None
    return next(
        (row for row in device.assignments.all() if row.returned_at is None),
        None,
    )


def can_see_device_cost(ctx: TenantContext) -> bool:
    return ctx.has_any_permission(
        ("devices.create", "devices.update", "devices.delete")
    )
