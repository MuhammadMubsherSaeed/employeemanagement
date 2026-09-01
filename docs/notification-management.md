# Notification Management

In-app inbox and FCM device-token registration in `apps.notifications`. Push delivery is optional and isolated from inbox persistence. `AuditEvent` remains a separate audit trail.

Python 3.12 · Django 5.2 · DRF. App label: `notifications` (`apps.notifications`).

---

## 1. Models

| Model | Purpose |
| --- | --- |
| `Notification` | Recipient-specific in-app row |
| `DeviceToken` | FCM registration for one device |

Both have `company`. Inbox rows are **not** company-wide: a user only sees `recipient = self`.

---

## 2. Notification types

`LEAVE_SUBMITTED`, `LEAVE_APPROVED`, `LEAVE_REJECTED`, `LEAVE_CANCELLED`, `DEVICE_ASSIGNED`, `DEVICE_RETURNED`, `ATTENDANCE_REMINDER`, `ATTENDANCE_LATE`, `DOCUMENT_EXPIRING`, `SYSTEM`.

Entity refs: `entity_type` + `entity_id` (`leave_request`, `device`, `attendance`, `employee_document`).

`ATTENDANCE_*` and `DOCUMENT_EXPIRING` are supported types. Scheduled jobs are **not** implemented (no Celery in this module).

---

## 3. APIs

Base: `/api/v1/notifications/`

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/` | `notifications.view` |
| GET | `/{id}/` | `notifications.view` |
| GET | `/unread-count/` | `notifications.view` |
| POST | `/{id}/mark-read/` | `notifications.mark_read` |
| POST | `/mark-all-read/` | `notifications.mark_read` |
| POST | `/device-tokens/` | `notifications.view` |
| PATCH | `/device-tokens/{id}/` | `notifications.view` |
| DELETE | `/device-tokens/{id}/` | `notifications.view` |

List filters: `is_read`, `type`, `created_at_after`, `created_at_before`. Newest first. Pagination: `StandardPagination`.

`company_id` / `user_id` in the body are ignored. Device tokens are registered to the authenticated membership.

DELETE deactivates the current device token (`is_active=false`). It does not remove other devices.

---

## 4. Isolation

Querysets use `ObjectAuthorization`: company + recipient (or token `user`). Cross-user and cross-company IDs return **404**. Company admins do **not** see other people's inboxes.

---

## 5. Business events

| Event | Recipient |
| --- | --- |
| Leave submitted | Direct manager, or company admins if there is no manager |
| Leave approved / rejected | Submitting employee |
| Leave cancelled | The other party (manager if the employee cancelled; employee if a manager/admin cancelled) |
| Device assigned / returned | Assigned employee |

The actor is not notified of their own action. Duplicates for the same event/recipient use `event_key`.

---

## 6. Push

`PushNotificationService` looks up active `DeviceToken` rows and calls a `PushBackend`. Default: `DisabledPushBackend` (no Firebase Admin SDK). Inbox create **does not** roll back if push fails. Invalid tokens can be deactivated when a real backend reports them.

Set `FIREBASE_CREDENTIALS_PATH` when wiring firebase-admin later. Until then, push is skipped.

Payload data: `notification_id`, `notification_type`, `entity_type`, `entity_id`. No sensitive employee fields.

---

## 7. Permissions

| Code | Typical use |
| --- | --- |
| `notifications.view` | Own inbox, unread count, register own device token |
| `notifications.mark_read` | Mark own notifications read |
| `notifications.manage` | Reserved (company admin); no extra inbox APIs in this module |

Default employee/manager: view + mark_read. Company admin: all three. Recipient ownership still applies.

After migrate, run `python manage.py seed_rbac`.

---

## 8. Known limitations

- No email/SMS/WhatsApp, campaigns, preferences UI, WebSockets, or Celery schedulers.
- Attendance reminders and document-expiry scans are not scheduled.
- FCM send requires Firebase Admin credentials that are **not** configured.
- Django Admin is for platform operators and is not tenant-scoped. Token values are hidden/truncated in admin.

OpenAPI: `/api/schema/`, `/api/docs/` (tag **Notifications**).

---

## 9. Flutter client

Inbox, unread badge, mark-read, and FCM token registration live in `mobile/lib/features/notifications/`. Routes: `/notifications`, `/notifications/:id`. Device-token register body is `token`, `platform`, `device_name` only. Push payload keys: `notification_id`, `notification_type`, `entity_type`, `entity_id`. Actual FCM delivery still requires backend Firebase Admin credentials; the app still registers tokens and reads the inbox.
