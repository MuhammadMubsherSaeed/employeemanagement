# Flutter authentication

Client authentication for the HRMS Flutter app against `POST/GET /api/v1/auth/*`. The API now returns `company` (`{id, name, slug}` or `null`) and a membership-resolved `role` on login and `/me/`. Flutter does not yet map company/RBAC UI; ignore extra fields until that prompt. Never send `company_id` to pick a tenant.

See also [`docs/authentication.md`](authentication.md) (Django) and [`docs/flutter-architecture.md`](flutter-architecture.md).

---

## 1. Architecture

`AuthController` (`authControllerProvider`) is the only global session state.

| Layer | Responsibility |
| --- | --- |
| Screens | Forms, operation-specific loading, user-safe errors |
| `AuthController` | Restore, login, logout, session state |
| Use cases | Login, logout, restore, forgot/reset |
| `AuthRepository` | Domain API; maps models → `User`; persists tokens |
| `AuthRemoteDataSource` | HTTP via the shared `ApiClient` |
| `TokenStorage` | Access/refresh in Flutter Secure Storage |
| `TokenRefreshInterceptor` | 401 → one refresh → retry |

Views never construct Dio. Passwords and tokens are never logged.

---

## 2. Login flow

1. `LoginScreen` validates email + password.
2. `LoginUseCase` → `POST auth/login/` `{ email, password }`.
3. Tokens are saved in secure storage. The user is kept in memory (`AuthState.authenticated`).
4. GoRouter sees the new state and sends the user to `/home`.

The user object is not written to SharedPreferences. `/me/` is the source of truth on the next launch.

---

## 3. Token storage

`SecureTokenStorage` (interface `TokenStorage`) wraps `SecureStorageService`.

| Method | Notes |
| --- | --- |
| `saveTokens` | Writes access; writes refresh only when non-empty (never overwrites with null) |
| `getAccessToken` / `getRefreshToken` | Secure storage only |
| `clearTokens` | Deletes access, refresh, and any session JSON |
| `hasTokens` / `hasRefreshToken` | Used by restore |

Tokens are **not** stored in SharedPreferences, Drift, or files.

---

## 4. Token refresh

`POST auth/refresh/` `{ refresh }` is public (no `Authorization` header).

Triggered when an authenticated request returns **401**, except:

- login, refresh, forgot-password, reset-password
- requests flagged `skipAuthRefresh`
- a request that already retried once (`authRetried`)

---

## 5. Refresh-token rotation

The backend rotates refresh tokens. If the response includes `refresh`, it **replaces** the stored refresh. If only `access` is present, the existing refresh is kept.

Flutter must not reuse a blacklisted refresh token.

---

## 6. Logout

1. User confirms on `HomeScreen`.
2. `LogoutUseCase` calls `POST auth/logout/` with the refresh body when possible (Bearer access is attached by the interceptor).
3. **Local tokens are always cleared**, including when the API fails (offline, timeout, 401, 5xx).
4. `AuthState.unauthenticated` → router shows `/login`.

---

## 7. Session restoration

```
Splash (/splash)
  → AuthController.restoreSession
  → no refresh token? unauthenticated
  → GET auth/me/ (interceptor refreshes access if it gets 401)
  → authenticated or clear tokens + unauthenticated
```

Restore never stays on splash. Failures become `unauthenticated`, not a stuck loader.

---

## 8. 401 handling

1. Attach `Authorization: Bearer <access>` unless the path is a public auth endpoint.
2. On 401, run a single refresh (see below).
3. Store new tokens, retry the original request once.
4. If refresh fails or the retry is still 401: clear tokens, notify `SessionInvalidator`, fail the request. The controller becomes `unauthenticated` and the router shows login.

No session-expired dialogs. One redirect to login is enough.

---

## 9. Concurrent refresh

`TokenRefreshCoordinator` holds at most one in-flight refresh `Future`. Parallel 401s wait on that future, then retry with the new access token. They do not start three refresh POSTs.

---

## 10. Router guards

`AuthRedirect.resolve` + `GoRouter.refreshListenable` (auth state).

| State | Behavior |
| --- | --- |
| `initial` / `loading` | Stay on `/splash` |
| `unauthenticated` / `error` | Allow `/login`, `/forgot-password`, `/reset-password`; otherwise `/login` |
| `authenticated` | `/login`, `/forgot-password`, `/splash` → `/home` |

`/reset-password` remains reachable when authenticated so an email link can still open. Redirects never return the current location (no loops).

Implemented routes: `/splash`, `/login`, `/forgot-password`, `/reset-password`, `/home`. Future names (`/dashboard`, `/employees`, …) are constants only.

---

## 11. Role-aware routing foundation

`UserRole` parses `SUPER_ADMIN`, `COMPANY_ADMIN`, `MANAGER`, `EMPLOYEE`. Anything else is `UserRole.unknown` (the raw string is kept on `User.roleValue`).

`RoleRoutePolicy.canAccess` currently returns **true** for every implemented route. Later: Role → permissions → route access. Do not hardcode HRMS module permissions yet.

---

## 12. Password reset

- Forgot: `POST auth/forgot-password/` `{ email }`. Always show the generic success copy. Do not say whether the account exists.
- Reset: `POST auth/reset-password/` `{ uid, token, new_password, confirm_password }`.
- `/reset-password?uid=&token=` is ready for a future deep link. This app has no production deep-link URL configured; fields can also be filled manually.

---

## 13. Security

- Base URL comes from `AppConfig` / `--dart-define`, never hardcoded in screens.
- No passwords in storage or logs. Logging interceptor redacts `Authorization` and token/password keys.
- JWT is not decoded on the client.
- Access tokens remain valid until expiry after logout (backend behavior).

---

## Error copy

Mapped in `AuthErrorMapper` on top of `ErrorMapper` / `{ success, message, code, errors }`:

- `INVALID_CREDENTIALS` → Invalid email or password.
- `ACCOUNT_INACTIVE` → Your account is inactive. Please contact your administrator.
- Network → Unable to connect to the server. Please check your internet connection.
- Token expiry/blacklist/invalid → Your session has expired. Please log in again.
