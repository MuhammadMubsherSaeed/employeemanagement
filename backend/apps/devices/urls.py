from rest_framework.routers import SimpleRouter

from apps.devices.views import DeviceViewSet

router = SimpleRouter()
router.register("devices", DeviceViewSet, basename="device")

urlpatterns = router.urls
