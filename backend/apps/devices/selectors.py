from apps.common.authorization import ObjectAuthorization
from apps.common.tenancy import get_tenant_context
from apps.devices.models import Device, DeviceAssignment


def device_queryset():
    return Device.objects.select_related("company")


def assignment_queryset():
    return DeviceAssignment.objects.select_related(
        "company",
        "device",
        "employee",
        "employee__user",
        "employee__manager",
    )


def get_company_devices(*, company):
    if company is None:
        return device_queryset().none()
    return device_queryset().filter(company=company)


def get_visible_devices_for_user(*, request):
    ctx = get_tenant_context(request)
    return ObjectAuthorization().filter_queryset(device_queryset(), ctx)


def get_device_history(*, device):
    return assignment_queryset().filter(device=device).order_by(
        "-assigned_at",
        "-created_at",
    )


def active_assignment(*, device) -> DeviceAssignment | None:
    return (
        assignment_queryset()
        .filter(device=device, returned_at__isnull=True)
        .first()
    )
