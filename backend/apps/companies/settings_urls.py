from django.urls import path

from apps.companies.views import CompanySettingsView

urlpatterns = [
    path("", CompanySettingsView.as_view(), name="settings"),
]
