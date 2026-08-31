from django_filters import rest_framework as filters

from apps.accounts.models import UserRole
from apps.common.tenancy import get_tenant_context
from apps.devices.models import Device


class DeviceFilter(filters.FilterSet):
    type = filters.CharFilter(lookup_expr="iexact")
    manufacturer = filters.CharFilter(lookup_expr="icontains")
    employee = filters.UUIDFilter(method="filter_employee")
    assigned = filters.BooleanFilter(method="filter_assigned")
    purchase_date_after = filters.DateFilter(
        field_name="purchase_date",
        lookup_expr="gte",
    )
    purchase_date_before = filters.DateFilter(
        field_name="purchase_date",
        lookup_expr="lte",
    )
    warranty_expiry_after = filters.DateFilter(
        field_name="warranty_expiry",
        lookup_expr="gte",
    )
    warranty_expiry_before = filters.DateFilter(
        field_name="warranty_expiry",
        lookup_expr="lte",
    )

    class Meta:
        model = Device
        fields = (
            "status",
            "type",
            "manufacturer",
            "employee",
            "assigned",
            "purchase_date_after",
            "purchase_date_before",
            "warranty_expiry_after",
            "warranty_expiry_before",
        )

    def filter_employee(self, queryset, name, value):
        ctx = get_tenant_context(self.request) if self.request else None
        if ctx is None or ctx.role_code == UserRole.EMPLOYEE:
            return queryset
        return queryset.filter(
            assignments__employee_id=value,
            assignments__returned_at__isnull=True,
        ).distinct()

    def filter_assigned(self, queryset, name, value):
        if value:
            return queryset.filter(assignments__returned_at__isnull=True).distinct()
        return queryset.exclude(assignments__returned_at__isnull=True).distinct()
