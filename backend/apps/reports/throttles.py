from rest_framework.throttling import ScopedRateThrottle


class ReportExportThrottle(ScopedRateThrottle):
    scope = "reports_export"
