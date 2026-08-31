# Attendance management

Company-scoped Attendance and Holiday APIs. Company-wide work rules live on `CompanySettings` in the companies app — attendance consumes them, it does not own tenant settings.

Identity, membership, and RBAC are unchanged. See [`multi-tenancy-and-rbac.md`](multi-tenancy-and-rbac.md) and [`employee-management.md`](employee-management.md).

Base path: `/api/v1/`. JWT required.

---

## 1. Attendance model

`apps.attendance.models.Attendance` — UUID primary key.

| Field | Notes |
| --- | --- |
| `company` | Set from tenant context. Never from the client. |
| `employee` | Must belong to the same company. Check-in/out resolve this from `request.user`. |
| `date` | Company-local working date (see §4). |
| `check_in`, `check_out` | Timezone-aware datetimes. Server clock only. |
| `total_minutes` | Integer minutes from `check_out - check_in`. Server-calculated. |
| `status` | `PRESENT`, `ABSENT`, `LATE`, `HALF_DAY`, `LEAVE`, `HOLIDAY`, `WEEKEND` |
| `check_in_ip`, `check_out_ip` | From `REMOTE_ADDR` only. |
| latitude / longitude | Optional, validated. |
| timestamps | `created_at`, `updated_at` |

Unique per `(company, employee, date)`. Check-out cannot precede check-in (application + `CheckConstraint`).

---

## 2. Holiday model

`apps.attendance.models.Holiday` — UUID PK. Fields: `company`, `name`, `date`, `description`, `is_active`, timestamps.

Unique `(company, date)`. Company A holidays never affect Company B. Inactive holidays are ignored by status calculation.

Reads: `attendance.view`. Writes: `settings.manage` (company calendar, same as departments).

---

## 3. Company settings

`apps.companies.models.CompanySettings` — OneToOne with `Company`. Not an attendance-owned model.

| Field | Meaning |
| --- | --- |
| `timezone` | IANA name (example `Asia/Karachi`). Invalid names are rejected. |
| `work_start_time` / `work_end_time` | Expected day bounds. |
| `grace_period_minutes` | Lateness allowed before `LATE`. |
| `minimum_working_minutes` | Below this after checkout → `HALF_DAY`. |
| `overtime_enabled` | Reserved. Summary returns `overtime_minutes: 0`. |
| `working_days` | JSON list of weekday integers. **0 = Monday … 6 = Sunday.** Not hardcoded Mon–Fri. |

`work_end_time` must be **after** `work_start_time`. Overnight shifts are **not supported**; that configuration is rejected so minutes cannot be calculated incorrectly.

Missing settings are created with defaults (`UTC`, 09:00–18:00, 15-minute grace, 480-minute day, Monday–Friday) via `get_company_settings`.

`GET /api/v1/tenancy/settings/` (still `settings.manage`) now includes these fields for the current company.

---

## 4. Timezone behavior

Database timestamps stay UTC (`USE_TZ`). Attendance **date** is the calendar date in `CompanySettings.timezone`.

Example: company timezone `Asia/Karachi` (UTC+5). A check-in at `00:30 UTC` is `05:30` local — the attendance date is that local date, not the server's date.

`CompanyClock` converts `timezone.now()` with `ZoneInfo`. Naive datetimes are not used.

---

## 5. Check-in

`POST /api/v1/attendance/check-in/`

Requires `attendance.check_in`. Employee is `request.user`'s profile in the current company. Body may include `latitude` and `longitude` together. Timestamps, `status`, `date`, `company_id`, and `employee` in the body are ignored.

Flow: authenticate → membership/company → employee profile → settings → company-local now/date → weekend/holiday → create or reject duplicate → store IP from `REMOTE_ADDR` and optional GPS.

The default **MANAGER** role has `attendance.view` / `attendance.manage` but **not** `attendance.check_in` / `attendance.check_out` (see `rbac_catalog`). Managers punch the clock only if those codes are granted.

---

## 6. Check-out

`POST /api/v1/attendance/check-out/`

Requires `attendance.check_out`. Loads today's row with `select_for_update`. Errors:

- No row / no check-in → 400, does **not** auto-create check-in.
- Already checked out → 400; original checkout is kept.
- Server now before check-in → 400.

Then stores checkout instant, `total_minutes`, optional IP/GPS, and recalculates status.

---

## 7. Late calculation

`allowed_start = work_start_time + grace_period_minutes` on the attendance local date.

If `check_in` (in company TZ) is after `allowed_start` → `LATE`, unless a higher-precedence status applies.

---

## 8. Half-day calculation

After checkout, if `total_minutes < minimum_working_minutes` → `HALF_DAY`, unless weekend/holiday/leave apply.

---

## 9. Weekend handling

If `local_date.weekday()` is **not** in `working_days` → `WEEKEND`. Saturday/Sunday are weekends only when they are omitted from that list.

Check-in on a weekend still creates a row; status stays `WEEKEND` after checkout.

---

## 10. Holiday handling

An **active** holiday on that company date → `HOLIDAY`. Check-in is stored but does not override the holiday. Inactive holidays are ignored.

If a date is both a non-working weekday and a holiday, **WEEKEND wins** (working-day check first). Put holidays on configured working days to get `HOLIDAY`.

---

## 11. Leave integration point

`apps.attendance.services.leave_covers_date(employee, on_date)` currently returns `False`. A future Leave module should return `True` for approved leave covering that date; `AttendanceStatusService` will then emit `LEAVE`. Attendance must not invent leave rows.

---

## 12. Absence integration point

`AttendanceService.is_absent_on` returns whether a date would be `ABSENT` (working day, not holiday/leave, no check-in). It does **not** insert rows. No Celery job in this module. Summaries may count those dates as `absent_days`. Future jobs can materialize `ABSENT` records.

---

## 13. Tenant isolation

Every Attendance and Holiday queryset is company-scoped via `TenantAwareQuerySetMixin` / `ObjectAuthorization`. `company_id` from query, body, or URL is ignored for tenancy. Cross-company IDs return **404**.

---

## 14. RBAC

Existing codes only:

| Action | Permission |
| --- | --- |
| List, retrieve, `/me/`, `/summary/`, holiday reads | `attendance.view` |
| Check-in | `attendance.check_in` |
| Check-out | `attendance.check_out` |
| Holiday writes | `settings.manage` |
| Manual attendance edit | `attendance.manage` — **not exposed** (no PUT/PATCH on attendance) |

SUPER_ADMIN follows the platform rules: all permission checks pass; no company context so check-in/summary for a tenant are denied; list is unscoped like other HR list endpoints.

---

## 15. Manager access

Same direct-report rule as employees (`Employee.manager`, `TeamScope` / `ObjectAuthorization._filter_attendance`). Managers see their own attendance plus reports. They do not see the rest of the company. They cannot check in unless the role gains `attendance.check_in`.

---

## 16. Employee access

Employees check in/out (if permitted), list/retrieve/`/me/`/summary for **themselves** only. `employee_id` cannot select someone else (404). They do not receive IP or coordinates in API responses.

---

## 17. Status calculation (centralized)

`AttendanceStatusService.calculate` precedence:

1. `WEEKEND` — weekday not in `working_days`
2. `HOLIDAY` — active company holiday
3. `LEAVE` — `leave_covers_date` (always false today)
4. `ABSENT` — no check-in (helper / future jobs only)
5. `HALF_DAY` — checkout exists and minutes below minimum
6. `LATE` — check-in after start + grace
7. `PRESENT`

---

## 18. Summary

`GET /api/v1/attendance/summary/?start_date=&end_date=&employee_id=`

Both dates required unless both omitted (defaults to the current company-local month). `start_date <= end_date`. Maximum **366** days.

Counts `present_days` / `late_days` / … from stored statuses. `absent_days` applies the same `ABSENT` rules as `is_absent_on` over the range (not invented DB rows), using one attendance query and one holiday query rather than per-day lookups. `overtime_minutes` is always `0` for now.

Employees: own summary. Managers: self + reports (or one authorized `employee_id`). Admins: company (or one employee in the company).

---

## 19. Privacy

IP and GPS are sensitive. List responses never include them. Detail / check-in / check-out include them only for `COMPANY_ADMIN`, `MANAGER`, and `SUPER_ADMIN`. Employees do not see IP/coordinates even on their own detail. Capture uses `REMOTE_ADDR` only — no `X-Forwarded-For` spoofing.

---

## 20. Concurrency

Unique `(company, employee, date)` plus `transaction.atomic` and `select_for_update` on check-in/out. Duplicate check-in races surface as `IntegrityError` mapped to a 400 validation error.

---

## 21. Filters, ordering, pagination

List: `employee`, `department`, `status`, `start_date`, `end_date`, `search`, `ordering` (`date`, `check_in`, `check_out`, `created_at`). Standard pagination (`page_size` up to 100). Filters run on the tenant- and role-scoped queryset.

---

## 22. API examples

```http
POST /api/v1/attendance/check-in/
{"latitude": 31.5204, "longitude": 74.3587}

POST /api/v1/attendance/check-out/

GET /api/v1/attendance/
GET /api/v1/attendance/me/
GET /api/v1/attendance/{id}/
GET /api/v1/attendance/summary/?start_date=2026-03-01&end_date=2026-03-31
GET /api/v1/holidays/
```

OpenAPI: `/api/schema/` and `/api/docs/` (tags Attendance, Holidays).

---

## 23. Known limitations

- Overnight shifts are rejected on `CompanySettings`.
- Leave is a stub (`leave_covers_date` → false).
- Absences are not materialized daily.
- Overtime is a placeholder field on summaries.
- Default MANAGER role cannot self check-in/out (catalog).
- Platform SUPER_ADMIN has no company, so cannot punch attendance.
- One holiday per company date (extend later for types).
- Reverse-proxy client IP requires Django `SECURE_PROXY_SSL_HEADER` / trusted proxy setup; this module does not parse `X-Forwarded-For`.
