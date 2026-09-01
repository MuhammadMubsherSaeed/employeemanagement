from datetime import datetime, time, timedelta

from django.utils.dateparse import parse_date
from django_filters import rest_framework as filters
from rest_framework.exceptions import ValidationError

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.models import AuditLog
from apps.companies.services import get_company_settings


class AuditLogFilter(filters.FilterSet):
    date_from = filters.DateFilter(method="filter_date_from")
    date_to = filters.DateFilter(method="filter_date_to")
    user = filters.NumberFilter(field_name="user_id")
    action = filters.ChoiceFilter(choices=AuditAction.choices)
    entity_type = filters.ChoiceFilter(choices=AuditEntityType.choices)
    entity_id = filters.CharFilter(field_name="entity_id", lookup_expr="exact")

    class Meta:
        model = AuditLog
        fields = (
            "date_from",
            "date_to",
            "user",
            "action",
            "entity_type",
            "entity_id",
        )

    def is_valid(self):
        self._validate_choices()
        self._validate_date_range()
        return super().is_valid()

    def filter_date_from(self, queryset, name, value):
        start = datetime.combine(value, time.min, tzinfo=self._company_timezone())
        return queryset.filter(created_at__gte=start)

    def filter_date_to(self, queryset, name, value):
        end = datetime.combine(
            value + timedelta(days=1),
            time.min,
            tzinfo=self._company_timezone(),
        )
        return queryset.filter(created_at__lt=end)

    def _company_timezone(self):
        company = getattr(getattr(self.request, "tenant", None), "company", None)
        if company is None:
            from django.utils import timezone

            return timezone.get_current_timezone()
        return get_company_settings(company).zoneinfo()

    def _validate_choices(self):
        errors = {}
        action = self.data.get("action")
        if action not in (None, "") and action not in AuditAction.values:
            errors["action"] = ["Invalid audit action."]
        entity_type = self.data.get("entity_type")
        if entity_type not in (None, "") and entity_type not in AuditEntityType.values:
            errors["entity_type"] = ["Invalid entity type."]
        if errors:
            raise ValidationError(errors)

    def _validate_date_range(self):
        date_from = self._parse_date("date_from")
        date_to = self._parse_date("date_to")
        if date_from and date_to and date_from > date_to:
            raise ValidationError(
                {"date_from": ["date_from cannot be after date_to."]}
            )

    def _parse_date(self, field: str):
        raw = self.data.get(field)
        if raw in (None, ""):
            return None
        if hasattr(raw, "year") and not hasattr(raw, "hour"):
            return raw
        parsed = parse_date(str(raw).strip())
        if parsed is None:
            raise ValidationError({field: ["Enter a valid date."]})
        return parsed
