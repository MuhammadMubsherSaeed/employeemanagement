from django.urls import path

from apps.dashboard.views import (
    AdminDashboardView,
    EmployeeDashboardView,
    ManagerDashboardView,
)

urlpatterns = [
    path(
        "dashboard/admin/",
        AdminDashboardView.as_view(),
        name="dashboard-admin",
    ),
    path(
        "dashboard/manager/",
        ManagerDashboardView.as_view(),
        name="dashboard-manager",
    ),
    path(
        "dashboard/employee/",
        EmployeeDashboardView.as_view(),
        name="dashboard-employee",
    ),
]
