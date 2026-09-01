from rest_framework.routers import SimpleRouter

from apps.documents.views import DocumentViewSet, EmployeeDocumentViewSet

router = SimpleRouter()
router.register("documents", DocumentViewSet, basename="document")
router.register(
    r"employees/(?P<employee_id>[^/.]+)/documents",
    EmployeeDocumentViewSet,
    basename="employee-document",
)

urlpatterns = router.urls
