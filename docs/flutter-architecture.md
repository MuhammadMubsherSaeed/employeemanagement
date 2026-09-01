# Flutter architecture — HRMS foundation

This document describes the **mobile client foundation** under `mobile/`. It is the client half of the multi-tenant SaaS HRMS. Authentication is implemented; employees, attendance, and other business modules are **not**.

Package name remains `flutter_base` until a later rename. Entry point: `lib/main.dart` → `bootstrap()`.

---

## 1. Folder structure

```
mobile/lib/
├── main.dart
├── bootstrap.dart
├── app.dart
├── core/
│   ├── app_initialization.dart
│   ├── config/          # AppEnvironment + AppConfig
│   ├── constants/       # App name, routes keys, storage keys, headers
│   ├── errors/          # AppException + ErrorMapper
│   ├── extensions/
│   ├── network/         # ApiClient, interceptors, token refresh
│   ├── presentation/   # Shared error screen
│   ├── router/          # GoRouter + auth redirect
│   ├── session/         # UserSession + SessionStore + SessionInvalidator
│   ├── storage/         # SecureStorageService + TokenStorage + SharedPrefs
│   ├── theme/           # AppTheme, AppColors, AppTypography, AppSpacing
│   ├── utils/           # Logger, dates
│   └── widgets/         # Shared UI
└── features/
    └── auth/            # Login, session, password reset
```

Legacy internship/event-tracking code (`lib/views`, `lib/widgets`, `lib/models`, …) is **not part of the foundation**. It is excluded from `flutter analyze`. Do not extend it. New work belongs under `lib/core/` and later `lib/features/<name>/`.

---

## 2. State management strategy

Use **Riverpod**.

| Kind | When |
| --- | --- |
| `Provider` | Config, services, `ApiClient` |
| `Notifier` / generated `@riverpod` class | Theme mode, initialization |
| `AsyncNotifier` (`AppInitialization`) | Startup that can fail |
| `FutureProvider` | One-shot reads such as `currentSessionProvider` |

Providers that would benefit from `@riverpod` (`AppInitialization`, `ThemeModeController`, `goRouter`) are written as classic `Notifier` / `Provider` types so the app compiles on Dart 3.13 without a working `build_runner`. `riverpod_annotation` and `riverpod_generator` remain in `pubspec.yaml` for when the codegen stack matches the SDK. Do not generate a provider for every service.

**Do not** keep global mutable singletons outside Riverpod. Override `sharedPreferencesProvider` and `flutterSecureStorageProvider` in `bootstrap()`.

There is **no hardcoded authentication state**. `currentSessionProvider` reads storage and returns `null` until auth persists a backend-issued session.

---

## 3. Networking strategy

All HTTP goes through **one** `ApiClient` (Dio 4.x).

- Base URL comes from `AppConfig` (never hardcode hosts in screens or feature services).
- Connect / receive / send timeouts: 20s.
- `CancelToken` is accepted on each verb.
- JSON `Accept` / `Content-Type`.
- Interceptors (order, Dio 4 FIFO): request id → auth header (skips public auth paths) → logging → token refresh → error mapping.

`TokenRefreshInterceptor` sits **before** error mapping so it sees raw 401s. It coordinates a single refresh, stores rotated tokens, and retries once. See [`docs/flutter-authentication.md`](flutter-authentication.md).

The UI must catch **`AppException`**, never `DioError`.

Logging (development only) records method, URI, status, and request id. It never logs access/refresh tokens, passwords, or employee PII. Do not log `Authorization` headers.

Connectivity (`connectivity_plus`) distinguishes **device offline** (`NetworkException` / `NetworkStatus.isOnline`) from **timeouts** and **HTTP/server errors**. There is no offline sync.

---

## 4. Storage strategy

| Store | Use for | Do not use for |
| --- | --- | --- |
| `SecureStorageService` | Access token, refresh token, session JSON | Passwords |
| `SharedPrefsService` | Theme mode, onboarding, UI prefs | Tokens |

Call these services only. Do not instantiate `FlutterSecureStorage` or `SharedPreferences` in widgets.

---

## 5. Environment configuration

`AppConfig.fromEnvironment()` reads compile-time `--dart-define` values:

| Define | Default |
| --- | --- |
| `APP_ENV` | `development` |
| `API_BASE_URL_DEV` | `http://127.0.0.1:8000/api/v1/` |
| `API_BASE_URL_STAGING` | `https://staging.example.com/api/v1/` |
| `API_BASE_URL_PROD` | `https://api.example.com/api/v1/` |

`APP_ENV` values: `development` | `staging` | `production`.

Replace staging/production URLs at build time. **Android emulator** must use `http://10.0.2.2:8000/api/v1/` to reach Django on the host.

Anything compiled into the app is public. Do **not** ship API secrets, app keys, or signing credentials in Flutter.

---

## 6. Routing strategy

`GoRouter` lives in `lib/core/router/`. `rootNavigatorKey` stays in the router layer for the navigator; do not call `Navigator` from providers.

Implemented routes:

- `/splash` — wait for `AuthController` restore
- `/login`, `/forgot-password`, `/reset-password`
- `/home` — temporary authenticated shell (logout + user)
- `/error` — friendly error page
- unknown paths → error builder (no stack traces)

Placeholder **names only** (no screens): `/dashboard`, `/employees`, `/attendance`, `/leaves`, `/devices`, `/reports`, `/ai`, `/settings`.

`redirect` is `AuthRedirect` driven by `authControllerProvider`. Details: [`docs/flutter-authentication.md`](flutter-authentication.md).

---

## 7. Theme architecture

Material 3. `ThemeMode.system | light | dark` via `ThemeModeController` (persisted).

| Type | Role |
| --- | --- |
| `AppColors` | ColorScheme + semantic colors |
| `AppTypography` | Display, headline, title, body, label, caption (`bodySmall`) |
| `AppSpacing` | `xs` … `xxl` |
| `AppRadius` / `AppElevation` | Shared shape and elevation |
| `AppTheme` | Light/dark `ThemeData` |

Widgets must use the theme / these tokens. Company branding later = override schemes, not scatter hex values.

No custom font package in the foundation (platform typography).

---

## 8. Error handling

`ErrorMapper` maps Dio failures to:

`NetworkException` · `TimeoutException` · `UnauthorizedException` · `ForbiddenException` · `NotFoundException` · `ValidationException` · `ServerException` · `UnknownException`

`ApiErrorBody.fromJson` is defensive. It understands `{ success, message, code, errors }` and also `detail`, plain strings, and missing fields. It does not assume a rigid schema.

Startup: if bootstrap or `AppInitialization` fails, the user sees a short message and **Retry**. Raw exceptions are not shown.

Reusable UI states: `AppLoader`, `AppErrorWidget`, `AppEmptyState`. Success is the feature’s own content.

---

## 9. Code generation

Configured in `pubspec.yaml`:

- `freezed` + `json_serializable`
- `riverpod_generator` + `riverpod_annotation`
- `build_runner`

```bash
cd mobile
dart run build_runner build --delete-conflicting-outputs
```

`build.yaml` excludes legacy Drift/envied trees so generation stays on the foundation. **Do not edit** `*.g.dart` / `*.freezed.dart` by hand.

**Limitation (Dart 3.13 / Flutter 3.47):** `build_runner` 2.4.8 looks for `frontend_server.dart.snapshot`, which this SDK does not ship (AOT-only). Newer `build_runner` needs `web ^1.1` and `source_gen` 2.x, which conflict with `freezed` 2.5.2, `package_info_plus` 5.x, and `upgrader` 9.x already in the project. Do not hand-write `*.g.dart` files. Re-enable `@riverpod` / Freezed parts after a coordinated upgrade of Freezed, build_runner, and transitive `web` constraints.

---

## 10. Future feature structure

Add features only when they have real work. Suggested layout:

```
features/employees/
├── data/           # API DTOs, ApiClient calls, mappers
├── domain/         # entities, repository interfaces (if they pull their weight)
└── presentation/   # screens, feature providers
```

Skip empty layers. A small feature can be `presentation/` + a single data source.

Planned feature names (do not create empty folders now):

`auth` · `dashboard` · `employees` · `attendance` · `leaves` · `devices` · `notifications` · `reports` · `ai` · `subscriptions` · `settings`

`features/auth/` implements login, session restore, logout, and password reset. `UserSession` / `SessionStore` remain for future tenant context and must not be filled with a fake `companyId`.

---

## 11. Multi-tenant readiness

`UserSession` can represent `userId`, `companyId`, `role`, and `permissions`. The **backend** owns company context. Flutter must not pick another company or invent a user.

`SessionStore` persists JSON in secure storage. It returns `null` when missing or incomplete. No company-switcher UI.

---

## How to add a future feature

1. Create `lib/features/<name>/` with only the layers you need.
2. Put endpoints on a small data source that takes `ApiClient` (inject via `apiClientProvider`).
3. Map HTTP errors with `ErrorMapper` / `AppException`.
4. Register GoRouter routes in `app_router.dart` using constants in `AppRoutes`.
5. Guard routes later via `redirect`, using `currentSessionProvider` — not by branching on hardcoded companies.
6. Use `AppButton`, `AppTextField`, spacing, and theme tokens. Do not add a second Dio instance.

---

## Logging

`AppLog` / `ConsoleAppLogger` / `AppLogger`. Levels: debug, info, warning, error. Verbose network logs only when `AppConfig.enableVerboseLogging` is true (development). Swap the implementation later for Sentry or Crashlytics; do not add those SDKs in this phase.
