from apps.common.authorization import ObjectAuthorization
from apps.common.tenancy import get_tenant_context
from apps.notifications.models import DeviceToken, Notification


def notification_queryset():
    return Notification.objects.select_related("company", "recipient")


def device_token_queryset():
    return DeviceToken.objects.select_related("company", "user")


def get_inbox(*, request):
    ctx = get_tenant_context(request)
    return ObjectAuthorization().filter_queryset(notification_queryset(), ctx)


def get_own_device_tokens(*, request):
    ctx = get_tenant_context(request)
    return ObjectAuthorization().filter_queryset(device_token_queryset(), ctx)
