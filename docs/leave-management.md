# Leave Management

Company-scoped leave types, balances, and requests in `apps.leave`. Working days use the same company calendar as Attendance (`CompanySettings.working_days` and `Holiday`). Status transitions and balance updates run in the service layer with transactions and row locks.

Python 3.12 · Django 5.2 · DRF. App label: `leave` (`apps.leave`).

---

## 1. Models

| Model | Purpose |
| --- | --- |
| `LeaveType` | Company leave catalog (code unique per company) |
| `LeaveBalance` | Per employee, type, and calendar year |
| `LeaveRequest` | Dated request with workflow status |

All rows have `company`. Tenant is taken from `CompanyMembership`, never from the client.

---

## 2. Leave types

Fields: `name`, `code`, `days_allowed`, `is_paid`, `carry_forward`, `status` (`ACTIVE` / `INACTIVE`).

- `code` is stored uppercase (`A-Z`, `0-9`, `_`). Unique with `company`.
- `days_allowed >= 0`.
- There is no DELETE endpoint. Historical balances and requests use `PROTECT` on the type FK. Prefer `INACTIVE`.

`carry_forward` is stored only. Year-end carry is **not** automated.

---

## 3. Leave balances

Unique: `(employee, leave_type, year)`. Year is calendar `YYYY` (not fiscal).

`remaining_days = allocated_days - used_days`. Clients cannot write `used_days` or `remaining_days`. `used_days` cannot exceed `allocated_days`.

Employee and leave type must belong to the same company (model `clean()` plus service checks). `company` is copied from the employee when omitted.

Balances are **not** created on every request. Use:

```bash
python manage.py initialize_leave_balances --year 2026
python manage.py initialize_leave_balances --year 2026 --company acme
```

Creates missing rows for **active** types. Does not overwrite existing allocated/used values. Allocated amount for new rows is `LeaveType.days_allowed`.

Admins with `leave.manage` may `PATCH /api/v1/leave/balances/{id}/` with `allocated_days` only. Allocation cannot drop below `used_days`.

---

## 4. Leave requests

Fields: `employee`, `leave_type`, `start_date`, `end_date`, `total_days`, `reason`, `attachment`, `status`, `approved_by`, `approved_at`, `rejection_reason`.

Statuses: `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`.

Create always uses the authenticated user's employee profile in the current company. `employee_id`, `company_id`, `status`, `total_days`, and approval fields in the body are ignored or stripped.

---

## 5. Working-day calculation

`LeaveCalendarService.working_days_between` counts company-local calendar dates where:

1. The weekday is in `CompanySettings.working_days` (0 = Monday … 6 = Sunday).
2. The date is **not** an **active** `Holiday` for that company.

`total_days` is computed on create. It is never trusted from the client.

---

## 6. Holiday integration

Uses `attendance.Holiday`. Inactive holidays are ignored. Company B holidays never affect company A.

---

## 7. Weekend / non-working days

Weekends are days **not** listed in `working_days`. The service does not assume Saturday/Sunday.

---

## 8. Overlap detection

A new request overlaps an existing one when:

`existing.start_date <= new.end_date` AND `existing.end_date >= new.start_date`

Scoped to the same company and employee. Only `PENDING` and `APPROVED` block. `REJECTED` and `CANCELLED` do not. Adjacent ranges (end Monday, start Tuesday) are allowed.

Create locks the employee row (`select_for_update`) before the overlap query so two simultaneous creates cannot both succeed.

---

## 9. Balance calculation

On **approve**: `used_days += total_days`, then remaining is recalculated.

On **cancel of APPROVED**: `used_days` is reduced by `total_days` (capped so it cannot go negative).

`PENDING` / `REJECTED` never change balances.

---

## 10. Approval workflow

`POST /api/v1/leave/requests/{id}/approve/`

Requires `leave.approve`. Self-approval is rejected (403). The actor must be company admin (or platform super admin) or the employee's direct manager.

Atomic steps: lock request, require `PENDING`, lock balance, require `remaining_days >= total_days`, deduct, set `APPROVED`, record `approved_by` / `approved_at`. Retrying approval does not deduct twice.

**Policy:** past dates are rejected (`start_date` before company-local today). Retrospective leave is not supported. Multi-year ranges (`start_date.year != end_date.year`) are rejected so a request is never charged to a single year incorrectly.

Zero working days (weekends and/or holidays only) are rejected.

---

## 11. Rejection workflow

`POST /api/v1/leave/requests/{id}/reject/` with `rejection_reason`.

Requires `leave.reject` and the same authorization as approve. Reason must be non-blank after strip, at least 3 characters, max 500. Status must be `PENDING`. Balance is unchanged. `approved_by` / `approved_at` record the decision.

---

## 12. Cancellation workflow

`POST /api/v1/leave/requests/{id}/cancel/`

Employees with `leave.create` can cancel their own `PENDING` or `APPROVED` requests. Managers (`leave.approve` / `leave.manage`) can cancel requests they are authorized to see. Company admins can cancel within the company.

| From | To | Balance |
| --- | --- | --- |
| `PENDING` | `CANCELLED` | unchanged |
| `APPROVED` | `CANCELLED` | restore `total_days` |
| `REJECTED` | — | rejected |
| `CANCELLED` | — | rejected (no second restore, no second audit) |

---

## 13. Attendance integration

Approved leave is **not** materialized as `Attendance` rows.

`apps.attendance.services.leave_covers_date` calls `apps.leave.selectors.approved_leave_covers_date`. Attendance status precedence is unchanged: **WEEKEND → HOLIDAY → LEAVE → ABSENT / punch statuses**.

Cancelled (or never approved) leave no longer covers the date. A later check-in on an approved leave day stores `LEAVE`, not `ABSENT`.

---

## 14. Notification events

`apps.common.events.emit` (in-process; no email):

| Event | When |
| --- | --- |
| `leave.request.created` | Request saved as `PENDING` |
| `leave.request.approved` | After successful approve |
| `leave.request.rejected` | After successful reject |
| `leave.request.cancelled` | After successful cancel |
| `leave.balance.changed` | Deduct, restore, or allocate |

---

## 15. Audit logs

The same `emit` writes `common.AuditEvent` (`actor`, `company`, `action`, `resource`, `resource_id`, `timestamp` via `created_at`, `metadata`). Do not add a second audit table in leave.

---

## 16. RBAC

Existing catalog codes (no parallel permission system):

| Code | Typical use |
| --- | --- |
| `leave.view` | List/retrieve types, balances, requests in scope |
| `leave.create` | Create own request; cancel own eligible request |
| `leave.approve` | Approve (and cancel if authorized) |
| `leave.reject` | Reject |
| `leave.manage` | Create/update types; allocate balances |

Default `EMPLOYEE`: view + create. Default `MANAGER`: view, approve, reject, manage (**not** create). Default `COMPANY_ADMIN`: all leave codes.

---

## 17. Manager authorization

Same direct-report rule as employees and attendance: `Employee.manager`. Managers see their own rows plus employees who report to them. They do **not** see the rest of the company. Approving or rejecting an unauthorized employee returns **404**.

---

## 18. Employee authorization

Employees see and create only their own requests and balances. They cannot approve, reject, create types, allocate balances, or address another employee/company in the payload.

---

## 19. Tenant isolation

Querysets are filtered by `TenantAwareQuerySetMixin` / `ObjectAuthorization`. Cross-company IDs return **404**, not 403. `company_id` from query, body, or URL is ignored.

---

## 20. Transactions

`transaction.atomic()` wraps create (employee lock + insert), approve, reject, cancel, and allocate.

---

## 21. Concurrency

Approve and cancel lock the `LeaveRequest` and the matching `LeaveBalance` with `select_for_update()`. Concurrent approvals of the same pending row: one succeeds, the other gets a validation error; balance is deducted once.

---

## 22. Attachments

Optional `FileField`. Allowed: pdf, png, jpg, jpeg, webp, doc, docx. Executables and other extensions are rejected. Max size: `LEAVE_ATTACHMENT_MAX_BYTES` (5 MiB). Stored under `MEDIA_ROOT/leave/<company_id>/<uuid>.<ext>` — not in git.

**Limitation:** in `DEBUG`, Django may serve `/media/` publicly. Production must keep leave attachments behind authenticated storage or a signed-download view (not implemented here).

---

## 23. Known limitations

- No fiscal-year allocation; calendar year only.
- No automated carry-forward at year end.
- No retrospective leave; no multi-year single request.
- No half-day leave; `total_days` is a whole working-day count.
- Managers cannot create leave requests unless given `leave.create`.
- Self-approval is always denied.
- Email/push is not sent; only in-process events + `AuditEvent`.
- Media files are not private object storage.
- Leave types cannot be deleted via API while balances/requests exist (`PROTECT`).

---

## API

Base: `/api/v1/leave/`

| Method | Path | Permission |
| --- | --- | --- |
| GET, POST | `/types/` | view / manage |
| GET, PATCH | `/types/{id}/` | view / manage |
| GET | `/balances/` | view |
| GET, PATCH | `/balances/{id}/` | view / manage |
| GET, POST | `/requests/` | view / create |
| GET | `/requests/{id}/` | view |
| POST | `/requests/{id}/approve/` | approve |
| POST | `/requests/{id}/reject/` | reject |
| POST | `/requests/{id}/cancel/` | create **or** manage **or** approve |

Request list filters: `status`, `employee`, `leave_type`, `start_date` (gte), `end_date` (lte), `search`, `ordering`. Pagination: `StandardPagination` (`page`, `page_size` ≤ 100).

Envelope: existing `success` / `message` / `data` and error `code` / `errors`. OpenAPI: `/api/schema/`, `/api/docs/` (tag **Leave**).

Unauthenticated: 401. Missing permission: 403. Out of tenant or team scope: 404. Business/validation: 400.
