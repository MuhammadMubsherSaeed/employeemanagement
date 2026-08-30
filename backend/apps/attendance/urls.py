from rest_framework.routers import SimpleRouter

from apps.attendance.views import AttendanceViewSet, HolidayViewSet

router = SimpleRouter()
router.register("attendance", AttendanceViewSet, basename="attendance")
router.register("holidays", HolidayViewSet, basename="holiday")

urlpatterns = router.urls
