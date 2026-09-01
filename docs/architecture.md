# HRMS Architecture

Employee Management / HRMS — Flutter mobile client + Django REST API.

UI/UX reference:
[Employee Management UIUX Page Template Design](https://www.behance.net/gallery/162879483/Employee-Management-UIUX-Page-Template-Design)

This document records the **as-is repository**, the **target architecture**, and the **initialization completed in this phase**. Business features (login flows, employee CRUD, attendance, leave) are intentionally not implemented yet.

---

## 1. Current repository assessment

Inspected on 2026-08-29. The repository was **not empty**. It was a Flutter boilerplate at the repo root (`flutter_base`), previously used for internships / event-tracking style apps. There was **no Django backend**, **no Docker**, and **no docs**.

### 1.1 Existing Flutter project

**Yes.** Relocated intact to `mobile/` (git history preserved).

| Item | Value |
| --- | --- |
| Package name | `flutter_base` |
| Android applicationId | `pk.pitb.gov.internship_attendance` |
| Android namespace | `com.example.flutter_base` |
| Platforms | Android, iOS, Linux |
| Entry | `mobile/lib/main.dart` |
| Navigation | Navigator 1.0 + `RouteGenerator` (not GoRouter) |
| State | Riverpod (`flutter_riverpod`) |
| HTTP | Dio 4.x |
| Local DB | Drift / SQLite (`db.sqlite`) |
| Push | Firebase Messaging + Crashlytics + Analytics (already wired) |

Existing `lib/` layout (legacy, kept):

```
mobile/lib/
  main.dart
  theme.dart
  database/          Drift tables, DAOs
  env/               envied
  models/            login, sync, unsent
  network/           EnvironmentConfig, Dio helpers
  providers/         ApiAuthNotifier
  repository/        auth (mostly commented), network
  route/             Routes + RouteGenerator
  views/             splash, login, pagination, diffutill
  widgets/
  utils/
```

### 1.2 Existing Django project

**None.** Added in this phase under `backend/`.

### 1.3 Existing dependencies

Flutter (already present, still used):

- Riverpod, Dio, Flutter Secure Storage, JSON Serializable, Freezed annotation (unversioned), Drift, envied, Firebase suite, localization, ScreenUtil

Flutter (added for the target stack, not wired into `MyApp` yet):

- GoRouter, Freezed (dev), `json_annotation`

Missing vs target stack before this phase:

- GoRouter
- Proper Freezed setup
- Django, DRF, PostgreSQL, JWT

### 1.4 Existing folder structure (before)

Flutter-at-root: `lib/`, `android/`, `ios/`, `linux/`, `pubspec.yaml`. No `mobile/`, `backend/`, `docs/`, or `docker/`. No Dart `test/` directory (only `ios/RunnerTests`).

### 1.5 Existing database configuration

- **Mobile:** Drift SQLite. Tables: `DistrictTable`, `UnsentTable`. Schema version 1. Constants still named `QuaidReceptionDB`.
- **Server:** none. Target is PostgreSQL 16 via Docker Compose.

### 1.6 Existing environment configuration

- `mobile/.env` + `envied` (`lib/env/env.dart`)
- `EnvironmentConfig` with compile-time `String.fromEnvironment` defaults pointing at **external** Punjab / event-tracking APIs, not this backend
- API keys were present in source and `.env` (must be rotated and kept out of git)

New env templates: `mobile/.env.example`, `backend/.env.example`, root `.env.example`.

### 1.7 Existing authentication

- Login **UI** exists (`views/login/login_screen.dart`)
- Login **API calls are commented out** in `auth_repository.dart` and `api_auth_notifier.dart`
- Tokens stored in **SharedPreferences**, not Flutter Secure Storage (the package is a dependency but unused for tokens)
- Dio attaches `Authorization: Bearer <token>` when `isAuthorization` is true
- Splash always navigates to login regardless of `isLoggedIn`

No Django JWT, no roles, no permission matrix.

### 1.8 Existing API structure

Custom Dio wrapper (`network_repository.dart`): GET/POST only; PUT/DELETE empty. Endpoints in `EnvironmentConfig`: `login`, `sync`, `events`, `attendance`, `verifyotp`, `signup`. Headers: `DEVICE_TYPE`, `APP_VERSION_NO`, `HEADER_API_KEY`, `HEADER_APP_KEY`.

This is a **legacy client for another API**. The HRMS API is new: `/api/health/` and `/api/v1/` only.

### 1.9 Existing tests

- No Dart unit/widget tests
- Default iOS `RunnerTests.swift` only

Added: `mobile/test/smoke_test.dart`, `backend/apps/core/tests/test_health.py`.

### 1.10 Git branches / status

- Branch: `main`, tracking `origin/main`
- Remote: `https://github.com/MuhammadMubsherSaeed/employeemanagement.git`
- Recent history: Flutter base / internship attendance identity, pagination, Crashlytics, upgrade dialog

---

## 2. Overall architecture

Monorepo. The mobile app is the only client in v1. The backend is the system of record.

```
┌──────────────────────┐         HTTPS / JSON          ┌─────────────────────────┐
│  Flutter (mobile/)   │  Dio + JWT Bearer             │  Django + DRF           │
│  Riverpod + GoRouter │ ─────────────────────────────►│  config + modular apps  │
│  feature CA layers   │                               │  PostgreSQL             │
└──────────────────────┘                               └───────────┬─────────────┘
        │                                                          │
        │ local cache (future)                                     │
        ▼                                                          ▼
   Secure Storage / Drift                               Redis / Celery / S3 (later)
   FCM (already present; expand later)
```

**Principles**

1. Mobile never talks to PostgreSQL. All mutations go through the API.
2. Backend apps own a bounded context. Cross-app access is via services, not random model imports.
3. Existing Flutter screens stay on Navigator 1.0 until auth is rebuilt. New features land under `lib/features/<name>/`.
4. JWT access + refresh. Role claims drive UI and API authorization.
5. Do not implement domain features until the architecture (this document) is agreed.

### Target repo layout

```
/
├── mobile/                 Flutter application
├── backend/                Django project
├── docs/                   Architecture and later ADRs
├── docker/                 Image definitions
├── README.md
├── .gitignore
├── .env.example
└── docker-compose.yml
```

---

## 3. Flutter architecture

Feature-based Clean Architecture.

```
mobile/lib/
├── main.dart                 existing entry (unchanged behavior)
├── core/                     shared infrastructure
│   ├── constants/
│   ├── error/
│   ├── network/              target Dio client
│   ├── router/               target GoRouter (not wired to MyApp)
│   ├── storage/              token contract (Secure Storage later)
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── employees/
│   ├── attendance/
│   ├── leave/
│   ├── organization/
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── <legacy views, repository, …>   keep until migrated
```

### Layer rules (per feature)

| Layer | Contains | Depends on |
| --- | --- | --- |
| **domain** | Entities, use cases, repository *interfaces*. Pure Dart. | Nothing in data/presentation |
| **data** | DTOs (Freezed + json_serializable), Dio data sources, repository *implementations*, local cache | domain |
| **presentation** | Widgets, GoRouter pages, Riverpod notifiers/controllers | domain (+ Riverpod DI for data impls) |

**Riverpod** is the composition root: providers bind data sources → repositories → use cases → UI.

**GoRouter** will replace `RouteGenerator`. Redirects will encode auth + role (admin / manager / employee). `createAppRouter()` exists but is **not** attached to `MaterialApp` yet.

**Dio** interceptors (later): attach Bearer access token from secure storage; on 401, refresh once; on refresh failure, send the user to login.

**Tokens:** move from SharedPreferences to Flutter Secure Storage when auth is implemented.

**Legacy code policy:** do not delete `views/`, `repository/`, or Drift tables in this phase. New HRMS screens go under `features/`. Remove leftover Punjab/event-tracking endpoints when the first real API feature lands.

### UI/UX direction (Behance)

The reference is a dense HR dashboard: left navigation, KPI cards, employee directory, profile, attendance/leave surfaces, light canvas, rounded cards, strong heading contrast, teal/blue accent.

Role shells:

- **Admin** — org-wide KPIs, employee directory, configuration
- **Manager** — team directory, attendance, leave approvals
- **Employee** — personal profile, own attendance, own leave

Do not pixel-copy the Behance file. Use it for hierarchy, density, and navigation.

---

## 4. Backend architecture

Django project package: `config`. Settings split:

- `config.settings.base`
- `config.settings.development`
- `config.settings.production`

Modular apps (initialized, domain logic not implemented except identity foundation):

| App | Responsibility (later) |
| --- | --- |
| `apps.core` | Health, API root, shared helpers |
| `apps.accounts` | Custom user, JWT, roles |
| `apps.employees` | Employee profiles, directory |
| `apps.organization` | Departments, reporting lines |
| `apps.attendance` | Check-in / timesheets |
| `apps.leave` | Leave types, requests, approvals |

**Why a custom user now:** Django cannot swap `AUTH_USER_MODEL` after the first migration without a painful rebuild. `accounts.User` extends `AbstractUser` and adds `role`. **No login, register, or token views** are exposed yet.

Future apps (not created): `payroll`. Employee documents live in `apps.documents`. In-app notifications live in `apps.notifications`.

HTTP:

```
/admin/
/api/health/          public liveness
/api/v1/              versioned API root (empty of domain routes)
```

---

## 5. Database architecture

PostgreSQL 16 is the source of truth.

**Now**

- `accounts.User` (AbstractUser + `role`)
- No employee / attendance / leave tables yet

**Planned (do not create until the matching feature)**

```
User 1──1 EmployeeProfile
Department 1──* EmployeeProfile
EmployeeProfile *──1 User (manager)     optional reporting line
AttendanceRecord *──1 EmployeeProfile
LeaveRequest *──1 EmployeeProfile
```

Rules:

- UUID or BigAutoField PKs (BigAutoField default for now)
- Soft delete only where audit requires it
- All tables: `created_at`, `updated_at`
- Migrations live with each app
- Mobile Drift is **offline cache**, not a second source of truth

---

## 6. API architecture

REST, JSON, `/api/v1/` prefix.

Conventions (when features start):

- Resource nouns: `/api/v1/employees/`, `/api/v1/leave-requests/`
- Pagination: DRF page number, default 20
- Errors: DRF exception handler; consistent `{ "detail": ... }` or field errors
- Auth: `Authorization: Bearer <access>`
- Version in the path, not headers

**Planned resources (not implemented)**

| Method | Path | Roles |
| --- | --- | --- |
| POST | `/api/v1/auth/token/` | public |
| POST | `/api/v1/auth/token/refresh/` | public |
| GET | `/api/v1/me/` | authenticated |
| GET/POST | `/api/v1/employees/` | admin, manager (scoped) |
| GET/PATCH | `/api/v1/employees/{id}/` | role-scoped |
| GET/POST | `/api/v1/attendance/` | role-scoped |
| GET/POST | `/api/v1/leave-requests/` | role-scoped |

SimpleJWT is **installed and configured**. Obtain/refresh routes are **not** included in `urls.py` yet.

---

## 7. Authentication architecture

**Later implementation (not this phase)**

1. `POST /api/v1/auth/token/` with username/email + password → access + refresh
2. Access ~15 minutes, refresh ~7 days, rotation on
3. Flutter stores tokens in Flutter Secure Storage
4. Dio interceptor attaches access token; refresh on 401
5. FCM device token registered after login (Firebase already in the app)

**Now**

- `AUTH_USER_MODEL = accounts.User`
- `REST_FRAMEWORK` default auth = JWT
- Default permission = `IsAuthenticated`
- Health and `/api/v1/` root are `AllowAny`
- Django admin can still create users via `createsuperuser` after migrate

**Do not keep** SharedPreferences tokens or hardcoded third-party API keys for the HRMS API.

---

## 8. Role / permission architecture

Implemented on the Django API. Details: [`docs/multi-tenancy-and-rbac.md`](multi-tenancy-and-rbac.md).

| Role | Scope |
| --- | --- |
| `SUPER_ADMIN` | Platform. Not a company tenant. |
| `COMPANY_ADMIN` | Full access within one company (via membership). |
| `MANAGER` | Team operations. No `settings.manage`. Team graph comes later. |
| `EMPLOYEE` | Self-service codes; object-level rules restrict private data. |

Enforcement:

1. **API:** `HasPermission("code")` + `TenantAwareQuerySetMixin` + `ObjectAuthorization`
2. **Mobile:** hide nav items the role cannot use (UI is not security)
3. **Object level:** managers are not granted every colleague’s private records until reporting exists

Do not use a generic `ADMIN` label. Flutter company/RBAC UI is a later prompt.

---

## 9. Future scalability strategy

Not built now; compose file comments and this section are the placeholders.

| Concern | Approach |
| --- | --- |
| **FCM** | Already in the Flutter app. Backend: store device tokens, send via FCM HTTP v1 from Celery |
| **Redis** | Cache, JWT blacklist (optional), Celery broker |
| **Celery** | Leave emails, attendance reminders, report exports, push |
| **S3-compatible storage** | Profile photos, documents (`django-storages`) |
| **Docker** | `docker-compose` today: `db` + `backend`. Later: redis, celery worker/beat, nginx |
| **Horizontal scale** | Stateless API behind a load balancer; Postgres primary; Redis for shared session/cache |
| **Read load** | Read replicas only if directory/search needs it |
| **API growth** | Keep `/api/v1/`; add `/api/v2/` rather than breaking clients |
| **Mobile** | Feature modules stay independent; Drift only for true offline paths |

---

## 10. Initialization decisions

1. **Moved Flutter to `mobile/`** instead of a second app, so existing code is not duplicated or deleted.
2. **Did not rename** `flutter_base` or `applicationId` (would touch every import and Firebase/store identity). Rename in a dedicated change.
3. **Did not wire GoRouter into `MyApp`** so splash/login keep working.
4. **Custom user + role only** — no JWT login endpoints, no employee models.
5. **PostgreSQL in settings from day one.** `manage.py check` does not need a running database; migrate does.
6. **Health endpoint** is infrastructure, not a business feature.

### Next phase (do not start until asked)

1. JWT obtain/refresh + Flutter auth feature (Clean Architecture)
2. Employee profile + directory
3. Switch `MyApp` to `MaterialApp.router`
4. Point mobile env at this backend; remove third-party API defaults
5. `makemigrations` / `migrate` against Compose Postgres
6. Rename Dart package and Android applicationId when product identity is final
