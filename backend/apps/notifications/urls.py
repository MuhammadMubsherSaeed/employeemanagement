from rest_framework.routers import SimpleRouter

from apps.notifications.views import DeviceTokenViewSet, NotificationViewSet

router = SimpleRouter()
router.register(
    "notifications/device-tokens",
    DeviceTokenViewSet,
    basename="device-token",
)
router.register("notifications", NotificationViewSet, basename="notification")

urlpatterns = router.urls
