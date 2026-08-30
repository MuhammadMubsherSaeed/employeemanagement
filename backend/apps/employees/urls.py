from rest_framework.routers import SimpleRouter

from apps.employees.views import DepartmentViewSet, EmployeeViewSet, PositionViewSet

router = SimpleRouter()
router.register("employees", EmployeeViewSet, basename="employee")
router.register("departments", DepartmentViewSet, basename="department")
router.register("positions", PositionViewSet, basename="position")

urlpatterns = router.urls
