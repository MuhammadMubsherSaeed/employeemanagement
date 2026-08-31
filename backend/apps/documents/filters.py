from datetime import timedelta

from django.utils import timezone
from django_filters import rest_framework as filters

from apps.accounts.models import UserRole
from apps.common.tenancy import get_tenant_context
from apps.documents.models import EmployeeDocument, expiring_soon_days


class DocumentFilter(filters.FilterSet):
    employee = filters.UUIDFilter(method="filter_employee")
    document_type = filters.CharFilter(lookup_expr="iexact")
    expired = filters.BooleanFilter(method="filter_expired")
    expiring_soon = filters.BooleanFilter(method="filter_expiring_soon")
    expiry_date_from = filters.DateFilter(
        field_name="expiry_date",
        lookup_expr="gte",
    )
    expiry_date_to = filters.DateFilter(
        field_name="expiry_date",
        lookup_expr="lte",
    )

    class Meta:
        model = EmployeeDocument
        fields = (
            "status",
            "document_type",
            "employee",
            "expired",
            "expiring_soon",
            "expiry_date_from",
            "expiry_date_to",
        )

    def filter_employee(self, queryset, name, value):
        ctx = get_tenant_context(self.request) if self.request else None
        if ctx is None or ctx.role_code == UserRole.EMPLOYEE:
            return queryset
        return queryset.filter(employee_id=value)

    def filter_expired(self, queryset, name, value):
        today = timezone.localdate()
        if value:
            return queryset.filter(expiry_date__lt=today)
        return queryset.exclude(expiry_date__lt=today)

    def filter_expiring_soon(self, queryset, name, value):
        if not value:
            return queryset
        today = timezone.localdate()
        until = today + timedelta(days=expiring_soon_days())
        return queryset.filter(
            expiry_date__gte=today,
            expiry_date__lte=until,
        )
