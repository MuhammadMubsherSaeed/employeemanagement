# Backend architecture — HRMS foundation

This document describes the Django REST backend under `backend/`. Employees, attendance, leave, devices, employee documents, notifications, and dashboard APIs are implemented; billing and AI are not.

Python 3.12 · Django 5.2 · DRF 3.16 · PostgreSQL 16.

---

## 1. Project structure

```
backend/
├── config/
│   ├── settings/
│   │   ├── env.py            # django-environ loader
│   │   ├── base.py
│   │   ├── development.py
│   │   └── production.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
├── apps/
│   ├── common/               # timestamps, errors, pagination, health, audit events
│   ├── accounts/             # custom User, Role, Permission, JWT auth
│   ├── companies/            # Company, CompanyMembership, CompanySettings
│   ├── employees/            # Employee, Department, Position
│   ├── attendance/           # Attendance, Holiday
│   ├── leave/                # LeaveType, LeaveBalance, LeaveRequest
│   ├── devices/              # Device, DeviceAssignment
│   ├── documents/            # EmployeeDocument
│   ├── notifications/        # Notification, DeviceToken
│   ├── dashboard/            # Admin / manager / employee dashboard APIs
│   ├── reports/              # Attendance, leave, employee, and device reports
│   └── audit_logs/           # Immutable company-scoped AuditLog query API

├── requirements/
│   ├── base.txt
│   ├── development.txt
│   └── production.txt
├── manage.py
└── .env.example
```

`apps.employees`, `apps.attendance`, `apps.leave`, `apps.devices`, `apps.documents`, `apps.notifications`, `apps.dashboard`, `apps.reports`, and `apps.audit_logs` are implemented. Remaining planned apps: `ai`, `subscriptions`. Leave details: [`docs/leave-management.md`](leave-management.md). Device details: [`docs/device-management.md`](device-management.md). Document details: [`docs/employee-documents.md`](employee-documents.md). Notification details: [`docs/notification-management.md`](notification-management.md).

---

## 2. Settings architecture

| Module | Role |
| --- | --- |
| `config.settings.base` | Apps, middleware, DRF, JWT, Spectacular, logging, static/media, Postgres engine |
| `config.settings.development` | Local defaults, browsable API, public schema, `CONN_MAX_AGE=0` |
| `config.settings.production` | Required secrets, HTTPS cookies, no wildcard hosts/CORS, `CONN_MAX_AGE=60` |

Set `DJANGO_SETTINGS_MODULE` to `config.settings.development` or `config.settings.production`. `manage.py` defaults to development.

Production **raises** `ImproperlyConfigured` if `DJANGO_SECRET_KEY` is missing or still a `dev-` placeholder, if `DJANGO_ALLOWED_HOSTS` is empty/`*`, if `POSTGRES_PASSWORD` is empty, or if `CORS_ALLOWED_ORIGINS` is empty. It never enables `CORS_ALLOW_ALL_ORIGINS`.

---

## 3. Environment configuration

Copy `backend/.env.example` to `backend/.env`. Required names:

- `DJANGO_SETTINGS_MODULE`, `DJANGO_SECRET_KEY`, `DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS`, `DJANGO_TIME_ZONE`
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT`
- `CORS_ALLOWED_ORIGINS`
- `JWT_ACCESS_MINUTES`, `JWT_REFRESH_DAYS`

Do not commit `.env`. Values compiled or shipped to Flutter are public; Django secrets stay on the server.

---

## 4. Database configuration

Create a local Postgres role and database that match `backend/.env`, then migrate:

```sql
CREATE USER hrms WITH PASSWORD 'your-password';
CREATE DATABASE hrms OWNER hrms;
```

Persistent connections (`CONN_MAX_AGE`) are used in production only. UTF-8 is expected at the database encoding level (Postgres default).

---

## 5. Accounts architecture

`apps.accounts` owns identity, JWT authentication (`/api/v1/auth/`), and the RBAC catalog (`Role`, `Permission`). See [`docs/authentication.md`](authentication.md) and [`docs/multi-tenancy-and-rbac.md`](multi-tenancy-and-rbac.md).

There is **no** `company` foreign key on `User`. Tenant access is `CompanyMembership`. Platform `SUPER_ADMIN` users are not company members.

---

## 6. User model

`AUTH_USER_MODEL = "accounts.User"`.

`User` extends `AbstractBaseUser` + `PermissionsMixin` + `TimeStampedModel`:

| Field | Notes |
| --- | --- |
| `id` | `BigAutoField` |
| `email` | Unique, required, `USERNAME_FIELD`, normalized via `UserManager` |
| `first_name`, `last_name` | Optional |
| `role` | See below |
| `is_active`, `is_staff`, `is_superuser` | Django auth flags |
| `last_login` | From `AbstractBaseUser` |
| `created_at`, `updated_at` | Abstract timestamps |

`UserManager.create_user()` / `create_superuser()` follow Django conventions. Superusers default to `SUPER_ADMIN`.

---

## 7. Role architecture

```text
SUPER_ADMIN     PLATFORM (User.role / is_superuser; not a company membership)
COMPANY_ADMIN   COMPANY (CompanyMembership → Role)
MANAGER         COMPANY
EMPLOYEE        COMPANY
```

Company authorization uses Role ↔ Permission codes. `User.role` stays for admin and users without membership; membership role is authoritative when present. Seed with `python manage.py seed_rbac`.

---

## 8. JWT configuration

`djangorestframework-simplejwt` is installed and listed as the default authentication class.

- Header: `Authorization: Bearer <access>`
- Access / refresh lifetimes from env (defaults 15 minutes / 7 days)
- Refresh rotation on, blacklist after rotation (`token_blacklist` app)
- Obtain/refresh **views are not mounted**

---

## 9. API response format

Helpers in `apps.common.responses`.

Success (health):

```json
{ "success": true, "message": "API is healthy." }
```

Success with payload:

```json
{ "success": true, "message": "Request successful.", "data": {} }
```

Error:

```json
{
  "success": false,
  "message": "Validation failed.",
  "code": "VALIDATION_ERROR",
  "errors": {}
}
```

List endpoints will use `StandardPagination`, which wraps `count` / `next` / `previous` / `results` inside `data` so pagination stays compatible with the envelope.

---

## 10. Exception handling

`apps.common.exception_handler.api_exception_handler` maps DRF and selected Django errors to the envelope. Codes include `VALIDATION_ERROR`, `AUTHENTICATION_ERROR`, `PERMISSION_DENIED`, `NOT_FOUND`, `METHOD_NOT_ALLOWED`, `PARSE_ERROR`, `CONFLICT`, `SERVER_ERROR`.

Unhandled exceptions are logged. Responses never include stack traces, SQL, or secrets. In production the 500 message is generic; development may include `str(exc)`.

Default DRF permission is `IsAuthenticated`. Health (and development schema) opt in to `AllowAny`.

---

## 11. API documentation

- Schema: `GET /api/schema/`
- Swagger UI: `GET /api/docs/`
- Versioned API prefix: `/api/v1/` (`URLPathVersioning`, allowed version `v1`)
- JWT documented as HTTP bearer

Development: schema is public. Production: schema requires an admin user.

---

## 12. Logging

Console logging at DEBUG/INFO/WARNING/ERROR/CRITICAL. Development is more verbose. Do not log passwords, JWT tokens, secrets, or employee PII. Unexpected API exceptions use `logger.exception`. Wire Sentry/Crashlytics later by swapping handlers — do not add those services now.

---

## 13. Multi-tenant readiness

Implemented. See [`docs/multi-tenancy-and-rbac.md`](multi-tenancy-and-rbac.md).

`apps.companies` owns `Company`, `CompanyMembership`, and `CompanySettings` (one row per company). Product settings: `GET` / `PATCH` `/api/v1/settings/`. Company-scoped isolation probes also live under `/api/v1/tenancy/`. Future apps should use `TenantAwareQuerySetMixin` and `HasPermission("…")`.

`TimeStampedModel` remains the shared abstract base. Put `company` on membership and resource models, not on `User`.

---

## How to add a future Django app

1. `python manage.py startapp <name> apps/<name>` (or copy `apps/companies` as a template).
2. Set `name = "apps.<name>"` and a unique `label` in `AppConfig`.
3. Add it to `LOCAL_APPS` in `config/settings/base.py`.
4. Include `path("<name>/", include("apps.<name>.urls"))` from `apps/common/urls.py` so the public path is `/api/v1/<name>/`.
5. Inherit domain models from `TimeStampedModel`. Add a `company` FK and `TenantAwareQuerySetMixin`; never take `company_id` from the client.
6. Use `ApiClient` on Flutter against `/api/v1/…`. Catch `AppException` shapes that match this envelope.

`apps.employees`, `apps.attendance`, `apps.leave`, `apps.devices`, `apps.documents`, `apps.notifications`, `apps.dashboard`, `apps.reports`, and `apps.audit_logs` are implemented. Remaining planned apps: `ai`, `subscriptions`. Notification details: [`docs/notification-management.md`](notification-management.md).
 