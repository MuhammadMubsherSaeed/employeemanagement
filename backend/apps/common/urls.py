from django.urls import include, path

from apps.common.views import health

urlpatterns = [
    path("health/", health, name="health"),
    path("accounts/", include("apps.accounts.urls")),
    path("companies/", include("apps.companies.urls")),
]
