from django_filters import rest_framework as filters

from apps.notifications.models import Notification


class NotificationFilter(filters.FilterSet):
    is_read = filters.BooleanFilter()
    type = filters.CharFilter(lookup_expr="iexact")
    created_at_after = filters.IsoDateTimeFilter(
        field_name="created_at",
        lookup_expr="gte",
    )
    created_at_before = filters.IsoDateTimeFilter(
        field_name="created_at",
        lookup_expr="lte",
    )

    class Meta:
        model = Notification
        fields = ("is_read", "type", "created_at_after", "created_at_before")
