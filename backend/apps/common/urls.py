from django.urls import include, path

from apps.common.views import health

urlpatterns = [
    path("health/", health, name="health"),
    path("auth/", include("apps.accounts.urls")),
    path("tenancy/", include("apps.companies.urls")),
    path("", include("apps.employees.urls")),
    path("", include("apps.attendance.urls")),
    path("", include("apps.leave.urls")),
]
