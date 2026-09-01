"""Company settings constants. Attendance stores weekdays as Python 0=Mon…6=Sun."""

from datetime import time
from pathlib import Path

from django.conf import settings as django_settings

WEEKDAY_MONDAY = 0
WEEKDAY_SUNDAY = 6
WEEKDAY_NAMES = (
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday",
)
WEEKDAY_INDEX = {name: index for index, name in enumerate(WEEKDAY_NAMES)}
DEFAULT_WORKING_DAYS = [0, 1, 2, 3, 4]
DEFAULT_WORK_START = time(9, 0)
DEFAULT_WORK_END = time(17, 0)
DEFAULT_GRACE_MINUTES = 15
DEFAULT_MINIMUM_WORKING_MINUTES = 480
MAX_GRACE_MINUTES = 240
MAX_MINIMUM_WORKING_MINUTES = 1440
MAX_COMPANY_NAME_LENGTH = 255
LOGO_MAX_BYTES = 2 * 1024 * 1024
LOGO_ALLOWED_EXTENSIONS = ("png", "jpg", "jpeg", "webp")
BLOCKED_LOGO_EXTENSIONS = frozenset(
    {".exe", ".bat", ".cmd", ".com", ".msi", ".js", ".sh", ".ps1", ".dll", ".svg"}
)


def default_timezone() -> str:
    return getattr(django_settings, "TIME_ZONE", "UTC") or "UTC"


def default_working_days() -> list[int]:
    return list(DEFAULT_WORKING_DAYS)


def working_day_names(days) -> list[str]:
    names = []
    for day in days or ():
        if isinstance(day, int) and WEEKDAY_MONDAY <= day <= WEEKDAY_SUNDAY:
            names.append(WEEKDAY_NAMES[day])
    return names


def normalize_working_days(days) -> list[int]:
    if not isinstance(days, list) or not days:
        raise ValueError("Select at least one working day.")
    normalized: list[int] = []
    for day in days:
        if isinstance(day, bool):
            raise ValueError("Invalid working day.")
        if isinstance(day, int):
            if day < WEEKDAY_MONDAY or day > WEEKDAY_SUNDAY:
                raise ValueError(
                    "Days must be weekday names or integers "
                    "0 (Monday) through 6 (Sunday)."
                )
            normalized.append(day)
            continue
        if isinstance(day, str):
            key = day.strip().lower()
            if key not in WEEKDAY_INDEX:
                raise ValueError(
                    "Days must be weekday names or integers "
                    "0 (Monday) through 6 (Sunday)."
                )
            normalized.append(WEEKDAY_INDEX[key])
            continue
        raise ValueError("Invalid working day.")
    return sorted(set(normalized))


def settings_logo_path(instance, filename: str) -> str:
    suffix = Path(filename).suffix.lower()
    company_id = instance.company_id or "unknown"
    from uuid import uuid4

    return f"company-settings/{company_id}/logo/{uuid4().hex}{suffix}"
