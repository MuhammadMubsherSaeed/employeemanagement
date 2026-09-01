from django.urls import path

from apps.audit_logs.views import AuditLogListView

urlpatterns = [
    path("audit-logs/", AuditLogListView.as_view(), name="audit-logs"),
]
