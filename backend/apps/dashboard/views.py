from drf_spectacular.utils import extend_schema
from rest_framework.views import APIView

from apps.common.permissions import HasPermission, IsAuthenticatedUser
from apps.common.responses import success_response
from apps.dashboard.permissions import (
    DASHBOARD_ADMIN_VIEW,
    DASHBOARD_EMPLOYEE_VIEW,
    DASHBOARD_MANAGER_VIEW,
)
from apps.dashboard.serializers import (
    AdminDashboardSerializer,
    EmployeeDashboardSerializer,
    ManagerDashboardSerializer,
)
from apps.dashboard.services import DashboardService

_MESSAGE = "Dashboard data retrieved successfully."


class AdminDashboardView(APIView):
    permission_classes = (
        IsAuthenticatedUser,
        HasPermission(DASHBOARD_ADMIN_VIEW),
    )

    @extend_schema(
        tags=["Dashboard"],
        responses=AdminDashboardSerializer,
        description=(
            "Company-wide dashboard for the authenticated tenant. "
            "Requires dashboard.admin.view. Company is taken from membership, "
            "never from company_id."
        ),
    )
    def get(self, request, **_kwargs):
        data = DashboardService().admin_dashboard(request=request)
        return success_response(data=data, message=_MESSAGE)


class ManagerDashboardView(APIView):
    permission_classes = (
        IsAuthenticatedUser,
        HasPermission(DASHBOARD_MANAGER_VIEW),
    )

    @extend_schema(
        tags=["Dashboard"],
        responses=ManagerDashboardSerializer,
        description=(
            "Team dashboard for the authenticated manager. "
            "Requires dashboard.manager.view. Scope is the manager's "
            "direct-report team, never the whole company or another tenant."
        ),
    )
    def get(self, request, **_kwargs):
        data = DashboardService().manager_dashboard(request=request)
        return success_response(data=data, message=_MESSAGE)


class EmployeeDashboardView(APIView):
    permission_classes = (
        IsAuthenticatedUser,
        HasPermission(DASHBOARD_EMPLOYEE_VIEW),
    )

    @extend_schema(
        tags=["Dashboard"],
        responses=EmployeeDashboardSerializer,
        description=(
            "Self-service dashboard for the authenticated employee. "
            "Requires dashboard.employee.view. employee_id is ignored; "
            "the profile is resolved from the current user."
        ),
    )
    def get(self, request, **_kwargs):
        data = DashboardService().employee_dashboard(request=request)
        return success_response(data=data, message=_MESSAGE)
