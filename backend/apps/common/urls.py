from django.urls import include, path

from apps.common.views import health

urlpatterns = [
    path("health/", health, name="health"),
    path("auth/", include("apps.accounts.urls")),
    path("tenancy/", include("apps.companies.urls")),
    path("", include("apps.employees.urls")),
    path("", include("apps.attendance.urls")),
    path("", include("apps.leave.urls")),
    path("", include("apps.devices.urls")),
    path("", include("apps.documents.urls")),
    path("", include("apps.notifications.urls")),
    path("", include("apps.dashboard.urls")),
    path("", include("apps.reports.urls")),
    path("", include("apps.audit_logs.urls")),
]
