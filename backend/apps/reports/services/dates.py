from datetime import date, datetime

from rest_framework.exceptions import ValidationError

from apps.attendance.services import MAX_DATE_RANGE_DAYS


def parse_report_date(params, field: str) -> date | None:
    raw = params.get(field)
    if raw in (None, ""):
        return None
    if isinstance(raw, datetime):
        return raw.date()
    if isinstance(raw, date):
        return raw
    try:
        return date.fromisoformat(str(raw).strip())
    except ValueError:
        raise ValidationError({field: ["Enter a valid date."]}) from None


def validate_report_date_range(params) -> tuple[date | None, date | None]:
    date_from = parse_report_date(params, "date_from")
    date_to = parse_report_date(params, "date_to")
    if date_from and date_to and date_from > date_to:
        raise ValidationError(
            {"date_from": ["date_from cannot be after date_to."]}
        )
    if date_from and date_to:
        span = (date_to - date_from).days + 1
        if span > MAX_DATE_RANGE_DAYS:
            raise ValidationError(
                {
                    "date_to": [
                        f"Date range cannot exceed {MAX_DATE_RANGE_DAYS} days."
                    ]
                }
            )
    return date_from, date_to
