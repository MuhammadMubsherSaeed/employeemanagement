from django.urls import path

from apps.reports.views import (
    AttendanceReportExportView,
    AttendanceReportView,
    DeviceReportExportView,
    DeviceReportView,
    EmployeeReportExportView,
    EmployeeReportView,
    LeaveReportExportView,
    LeaveReportView,
)

urlpatterns = [
    path(
        "reports/attendance/",
        AttendanceReportView.as_view(),
        name="reports-attendance",
    ),
    path(
        "reports/attendance/export/",
        AttendanceReportExportView.as_view(),
        name="reports-attendance-export",
    ),
    path(
        "reports/leaves/",
        LeaveReportView.as_view(),
        name="reports-leaves",
    ),
    path(
        "reports/leaves/export/",
        LeaveReportExportView.as_view(),
        name="reports-leaves-export",
    ),
    path(
        "reports/employees/",
        EmployeeReportView.as_view(),
        name="reports-employees",
    ),
    path(
        "reports/employees/export/",
        EmployeeReportExportView.as_view(),
        name="reports-employees-export",
    ),
    path(
        "reports/devices/",
        DeviceReportView.as_view(),
        name="reports-devices",
    ),
    path(
        "reports/devices/export/",
        DeviceReportExportView.as_view(),
        name="reports-devices-export",
    ),
]
