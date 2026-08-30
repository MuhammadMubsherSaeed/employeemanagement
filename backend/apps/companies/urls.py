from django.urls import path
from rest_framework.routers import SimpleRouter

from apps.companies.views import (
    CompanySettingsView,
    PlatformScopeView,
    TenantOwnedRecordViewSet,
)

router = SimpleRouter()
router.register("records", TenantOwnedRecordViewSet, basename="tenant-record")

urlpatterns = [
    path("settings/", CompanySettingsView.as_view(), name="company-settings"),
    path("platform/", PlatformScopeView.as_view(), name="platform-scope"),
    *router.urls,
]
