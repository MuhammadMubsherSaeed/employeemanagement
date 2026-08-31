from datetime import date, timedelta

from apps.attendance.models import Holiday
from apps.attendance.services import CompanyClock
from apps.companies.services import get_company_settings


class LeaveCalendarService:
    """Working-day counts using CompanySettings + active Holiday rows.

    Does not duplicate attendance status rules. Weekends are days not listed
    in ``working_days`` (0=Monday … 6=Sunday). Holidays are company-scoped
    and inactive holidays are ignored.
    """

    def working_days_between(self, *, company, start: date, end: date) -> int:
        if start > end:
            return 0
        settings = get_company_settings(company)
        holidays = set(
            Holiday.objects.filter(
                company=company,
                is_active=True,
                date__gte=start,
                date__lte=end,
            ).values_list("date", flat=True)
        )
        count = 0
        cursor = start
        while cursor <= end:
            if settings.is_working_weekday(cursor.weekday()) and cursor not in holidays:
                count += 1
            cursor += timedelta(days=1)
        return count

    def company_today(self, company) -> date:
        settings = get_company_settings(company)
        return CompanyClock(settings).local_date()
