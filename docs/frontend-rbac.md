# Frontend RBAC (Flutter)

Flutter authorization is a **UX layer**. Django remains the security boundary. Hiding a button or route does not grant or deny access on the server.

```
Backend RBAC (permission codes on the membership role)
        ↓
POST /api/v1/auth/login/  and  GET /api/v1/auth/me/
        ↓
Current User (id, company, role, permissions[])
        ↓
Authorization (Riverpod `authorizationProvider`)
        ↓
RoleRoutePolicy + AuthRedirect
        ↓
Home navigation, screens, tabs, PermissionGate / *Access helpers
        ↓
Optional API skip (no call when the UI already knows it will 403)
        ↓
Django HasPermission still enforces every request
```

## Permission source

Login and `/auth/me/` return `permissions` as the exact codes from `apps.accounts.rbac_catalog.PERMISSION_CODES`.

Platform admins (`SUPER_ADMIN`) receive the full catalog list so the app stays permission-primary. Company users receive the codes on their active membership role. Missing or empty lists **deny**.

Do not invent Flutter-only codes. Add a constant to `lib/core/auth/permissions.dart` only when the backend catalog already has it.

## Where to add a permission-aware action

1. Confirm the backend code exists (for example `devices.assign`).
2. Use `Permissions.devicesAssign` — never a raw string in a widget.
3. Gate UI with `PermissionGate` or the feature `*Access` helper (`EmployeeAccess`, `LeaveAccess`, …).
4. Skip the client API call when the session lacks the code.
5. Keep handling `403` via Dio / `ForbiddenException`. A frontend allow does not prove the server will accept the request.

**Do not** write `if (user.role == UserRole.companyAdmin)` for actions. Role is for labels, dashboard kind, and self-service navigation (own profile vs directory).

## Route guards

`RoleRoutePolicy` maps paths to permissions. `AuthRedirect` requires an authenticated session **and** that policy. Unauthorized deep links go to `/access-denied`. Self-service users with `employees.view` but no directory mutation codes are sent to `/employees/me` instead of a 403 page.

## Tenant / session

On login and `/me` restore, `AuthController` persists `UserSession` (`userId`, `companyId`, `role`, `permissions`) when a company is present. Logout and 401 session invalidation clear it. Reports already reload when `companyId` changes.

## 401 vs 403

Existing Dio interceptors: **401** refreshes or signs out. **403** maps to `ForbiddenException` and does not refresh. Access-denied UI must not reveal which permission was missing.
