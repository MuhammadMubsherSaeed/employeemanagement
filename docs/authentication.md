# Authentication

JWT authentication for the HRMS API. Tenant and RBAC live in [`docs/multi-tenancy-and-rbac.md`](multi-tenancy-and-rbac.md). JWT authenticates the **user** only; company context is resolved from `CompanyMembership`, never from token claims or a client-supplied `company_id`.

Base path: `/api/v1/auth/`

---

## 1. Architecture

| Piece | Role |
| --- | --- |
| `LoginSerializer` / other serializers | Input validation |
| `AuthenticationService` | Login, token issue/refresh/blacklist, current user |
| `PasswordResetService` | Django `PasswordResetTokenGenerator` + email |
| SimpleJWT | Access/refresh JWTs signed with Django `SECRET_KEY` |
| `token_blacklist` | Outstanding refresh tokens; logout and rotation |

Views stay thin. Passwords and tokens are never logged.

---

## 2. Login

`POST /api/v1/auth/login/`

Body: `{ "email", "password" }`. Email is normalized (`UserManager.normalize_email` + case-insensitive lookup).

- Wrong email or password → `401 INVALID_CREDENTIALS` with the **same** message (no account enumeration).
- Correct password, inactive user → `403 ACCOUNT_INACTIVE`.
- Success → access + refresh + public user (`id`, `email`, names, `full_name`, `role`, `company`). `last_login` is updated.

`role` is the active membership role, or `SUPER_ADMIN` for platform operators. `company` is `{id, name, slug}` or `null`. Role codes are always uppercase (`EMPLOYEE`, `MANAGER`, `COMPANY_ADMIN`, `SUPER_ADMIN`).

---

## 3. JWT configuration

From env: `JWT_ACCESS_MINUTES` (default 15), `JWT_REFRESH_DAYS` (default 7).

| Setting | Value |
| --- | --- |
| Algorithm | HS256 |
| Signing key | Django `SECRET_KEY` |
| Header | `Authorization: Bearer <access>` |
| `ROTATE_REFRESH_TOKENS` | `True` |
| `BLACKLIST_AFTER_ROTATION` | `True` |

Access tokens cannot be revoked immediately. Treat them as short-lived.

---

## 4. Refresh

`POST /api/v1/auth/refresh/` `{ "refresh" }`

Because rotation is on, the response includes a **new** `access` and a **new** `refresh`. The previous refresh is blacklisted.

Invalid → `TOKEN_INVALID`. Expired → `TOKEN_EXPIRED` when SimpleJWT reports expiry, otherwise `TOKEN_INVALID`. Blacklisted → `TOKEN_BLACKLISTED`.

---

## 5. Token rotation strategy

Each successful refresh:

1. Blacklist the presented refresh (JTI).
2. Issue a new refresh with a new JTI and expiry window.
3. Return both new access and new refresh.

Flutter must **replace** the stored refresh token after every refresh. Reusing the old refresh fails.

---

## 6. Logout

`POST /api/v1/auth/logout/`

Requires a valid **access** token (`Authorization: Bearer …`) and `{ "refresh" }` in the body.

The refresh is blacklisted. The access token remains valid until it expires (typically 15 minutes). Logout is **idempotent**: an already-blacklisted refresh still returns success.

Missing refresh → `VALIDATION_ERROR`. Malformed refresh → `TOKEN_INVALID`.

If access has already expired, call refresh first (if the refresh is still valid), then logout — or wait for access expiry.

---

## 7. Password reset

1. `POST /api/v1/auth/forgot-password/` `{ "email" }`  
   Always the same 200 message. If an **active** user exists, Django’s `PasswordResetTokenGenerator` builds `uid` + `token` (not stored raw). Email is sent.
2. Email contains `FRONTEND_PASSWORD_RESET_URL?uid=…&token=…` for Flutter deep links.
3. `POST /api/v1/auth/reset-password/` `{ "uid", "token", "new_password", "confirm_password" }`  
   UID/token failures share `PASSWORD_RESET_FAILED`. Mismatch/weak passwords are `VALIDATION_ERROR` (Django validators, min length 8).
4. On success, `set_password` runs and **all outstanding refresh tokens** for that user are blacklisted. Access tokens may remain valid until expiry.

`PASSWORD_RESET_TIMEOUT` default 24 hours.

Development: `EMAIL_BACKEND` console (or locmem in tests). Production: SMTP from env (`EMAIL_HOST`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, `DEFAULT_FROM_EMAIL`). No SMTP secrets in source.

---

## 8. Security decisions

- Email login only; Django password hashing.
- No user-existence leak on login (unknown vs wrong password) or forgot-password.
- Inactive accounts rejected.
- No custom JWT crypto.
- HTTPS and secure cookies enforced in `config.settings.production`.
- `/me/` uses `request.user` only.
- Throttles (development is looser): login 10/min, refresh 30/min, password 5/min in production-oriented defaults.

Recommended later: stricter per-IP limits, lockout after repeated failures, and optional access-token denylist if a gateway can enforce it.

---

## 9. Flutter integration

| Step | Client |
| --- | --- |
| Login | Store `access` and `refresh` in secure storage. |
| API calls | `Authorization: Bearer <access>` |
| 401 | Refresh once; on failure, clear session and go to login. |
| After refresh | Persist the **new** refresh (rotation). |
| Logout | Send access header + refresh body; then delete local tokens. |
| Reset | Open `FRONTEND_PASSWORD_RESET_URL` with `uid` and `token` query params; POST them with the new password. |

Do not put API secrets in the Flutter app.

---

## 10. Company context on `/me/` and login

`GET /api/v1/auth/me/` and the login `user` object include the authenticated user's **active** company:

```json
{
  "success": true,
  "message": "User retrieved successfully.",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "User",
    "last_name": "Name",
    "full_name": "User Name",
    "role": "EMPLOYEE",
    "is_active": true,
    "company": {
      "id": "…uuid…",
      "name": "Example Company",
      "slug": "example-company"
    }
  }
}
```

Users without an active membership (and all `SUPER_ADMIN` operators) receive `"company": null`. Membership internals are not exposed. `PATCH /me/` is not implemented (no self-service role change). Flutter may ignore `company` until a later integration prompt; do not send `company_id` to select a tenant.

---

## Endpoints

| Method | Path | Auth |
| --- | --- | --- |
| POST | `/api/v1/auth/login/` | No |
| POST | `/api/v1/auth/refresh/` | No (refresh body) |
| POST | `/api/v1/auth/logout/` | Bearer + refresh body |
| GET | `/api/v1/auth/me/` | Bearer |
| POST | `/api/v1/auth/forgot-password/` | No |
| POST | `/api/v1/auth/reset-password/` | No |
