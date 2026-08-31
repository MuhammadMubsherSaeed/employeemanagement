# Device / Asset Management

Company-scoped device inventory, assignment history, and return workflow in `apps.devices`. Status changes that affect assignment go through the service layer with transactions and row locks. Tenant is taken from `CompanyMembership`, never from the client.

Python 3.12 · Django 5.2 · DRF. App label: `devices` (`apps.devices`).

---

## 1. Models

| Model | Purpose |
| --- | --- |
| `Device` | Company asset (asset code unique per company) |
| `DeviceAssignment` | Historical assignment row; never overwritten |

All rows have `company`. `DeviceAssignment.company` is copied from the device when omitted.

---

## 2. Device fields

`asset_code`, `type`, `manufacturer`, `model`, `serial_number`, `purchase_date`, `warranty_expiry`, `cost`, `status`, `notes`.

- `asset_code` is stored uppercase. Pattern: letter or number, then letters, numbers, hyphens, or underscores. Unique with `company`.
- `serial_number` is optional. Empty values are stored as `NULL`. Unique with `company` only when not null, so multiple blanks are allowed.
- `type` is a trimmed string (Laptop, Mobile, …). There is no `DeviceType` catalog.
- `cost` is `DecimalField` (≥ 0). Not a float.
- `warranty_expiry` must be on or after `purchase_date` when both are set. No expiry notifications in this module.

---

## 3. Device status

`AVAILABLE`, `ASSIGNED`, `MAINTENANCE`, `RETIRED`, `LOST`.

Allowed **update/status** transitions:

| From | To |
| --- | --- |
| AVAILABLE | MAINTENANCE, RETIRED, LOST |
| ASSIGNED | LOST (closes the active assignment) |
| MAINTENANCE | AVAILABLE, RETIRED |
| RETIRED | none |
| LOST | none |

`ASSIGNED` is set only by `POST …/assign/`. `AVAILABLE` from `ASSIGNED` is set only by `POST …/return/`. A normal `PATCH` cannot force those.

Returned devices become `AVAILABLE`. They are not silently marked `MAINTENANCE`.

---

## 4. Assignment history

Every assign creates a **new** `DeviceAssignment` row. Previous rows stay. Active assignment means `returned_at IS NULL`. PostgreSQL enforces at most one active row per device.

Assign and employee must belong to the same company as the device.

---

## 5. Assign

`POST /api/v1/devices/{id}/assign/`

Body: `employee_id`, optional `condition_on_assignment`, `notes`. `company_id`, `device_id`, and `status` are ignored or stripped.

Only `AVAILABLE` devices with no active assignment can be assigned. Maintenance, retired, and lost devices are not auto-changed to available.

`transaction.atomic()` plus `select_for_update()` on the device row. Concurrent assigns: one succeeds, the other gets a validation error.

---

## 6. Return

`POST /api/v1/devices/{id}/return/`

Body: optional `condition_on_return`, `notes`. The backend finds the active assignment. There is no client `assignment_id`.

No active assignment → 400, no fake row. `returned_at` is server time and must be ≥ `assigned_at`. Status becomes `AVAILABLE`. Employees cannot self-return (`devices.return` required).

---

## 7. History

`GET /api/v1/devices/{id}/history/`

Newest `assigned_at` first. Paginated. Employees only see **their own** assignment rows on a device they can view (currently assigned to them). Managers/admins see history for devices in their authorization scope.

---

## 8. Delete

Devices **with any assignment history** cannot be deleted. Retire them instead. Devices with no history may be deleted with `devices.delete`.

---

## 9. Sensitive fields

`cost` and device `notes` are omitted unless the caller has `devices.create`, `devices.update`, or `devices.delete` (company admins). Employees viewing an assigned device do not receive those fields.

---

## 10. Permissions

| Code | Typical use |
| --- | --- |
| `devices.view` | List/retrieve devices in scope; history |
| `devices.create` | Create inventory |
| `devices.update` | Update fields and allowed status transitions |
| `devices.assign` | Assign to an authorized employee |
| `devices.return` | Close the active assignment |
| `devices.delete` | Delete a device with no assignment history |

Default `EMPLOYEE`: view only (own currently assigned devices). Default `MANAGER`: view, assign, return (team + available inventory; **not** create/update/delete). Default `COMPANY_ADMIN`: all device codes.

---

## 11. Manager authorization

Same direct-report rule as employees: `Employee.manager`. Managers may assign/return only for employees they manage. They see `AVAILABLE` company devices (needed to assign) plus devices currently assigned to themselves or direct reports. They do **not** see the rest of inventory (maintenance/retired/lost, or devices assigned to other teams). Unauthorized employee or device IDs return **404**.

---

## 12. Employee authorization

Employees see only devices currently assigned to them. They cannot create, update, delete, assign, return, or list company inventory. They cannot view another employee's device or another company's asset.

---

## 13. Tenant isolation

Querysets use `TenantAwareQuerySetMixin` / `ObjectAuthorization`. Cross-company IDs return **404**, not 403. `company_id` from query, body, or URL is ignored.

---

## 14. Transactions and concurrency

`transaction.atomic()` wraps create, update (with status change), delete, assign, and return. Assign and return lock the `Device` row with `select_for_update()`. The partial unique index on active assignments is a second integrity line.

---

## 15. Known limitations

- No procurement, vendors, repair tickets, MDM, or warranty notifications.
- No employee self-service return.
- Device `type` is a free controlled string, not a configurable catalog.
- Django Admin can still set non-assignment statuses; it cannot choose `ASSIGNED`, and assignment `clean()` rejects a second active row.
- Email/push is not sent; only in-process events + `AuditEvent`.

---

## API

Base: `/api/v1/devices/`

| Method | Path | Permission |
| --- | --- | --- |
| GET, POST | `/` | view / create |
| GET, PUT, PATCH, DELETE | `/{id}/` | view / update / delete |
| POST | `/{id}/assign/` | assign |
| POST | `/{id}/return/` | return |
| GET | `/{id}/history/` | view |

List filters: `status`, `type`, `manufacturer`, `assigned`, `employee` (ignored for employees), `purchase_date_after`, `purchase_date_before`, `warranty_expiry_after`, `warranty_expiry_before`, `search`, `ordering`. Search: `asset_code`, `manufacturer`, `model`, `serial_number`, `type`. Pagination: `StandardPagination` (`page`, `page_size` ≤ 100).

Envelope: existing `success` / `message` / `data` and error `code` / `errors`. OpenAPI: `/api/schema/`, `/api/docs/` (tag **Devices**).

Unauthenticated: 401. Missing permission: 403. Out of tenant or team scope: 404. Business/validation: 400.

After adding the app to an existing database, run migrations and `python manage.py seed_rbac` so `devices.delete` and manager assign/return bindings exist.
