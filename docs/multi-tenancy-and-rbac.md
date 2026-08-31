# Multi-tenancy and RBAC

Backend foundation for the multi-tenant SaaS HRMS. Employees, attendance, leave, and devices are implemented. Reports, billing, and company/super-admin UIs are **not** implemented here. This document describes how company isolation and authorization work so those modules can adopt the same pattern.

Related: [`docs/authentication.md`](authentication.md), [`docs/backend-architecture.md`](backend-architecture.md).

---

## 1. Multi-tenant architecture

```
Platform (SUPER_ADMIN)
│
├── Company A
│   ├── COMPANY_ADMIN
│   ├── MANAGER
│   └── EMPLOYEE
├── Company B
│   └── …
└── Company C
    └── …
```

Identity and tenancy are separate:

```
User
  → CompanyMembership (active)
    → Company
    → Role
      → Permission (codes)
```

A user from Company A must never read, update, delete, or relate to Company B data. Flutter hiding a menu item is not security. Every protected API operation enforces this on the server.

There is **one** authoritative company relationship: `CompanyMembership`. There is no `User.company` foreign key. Platform `SUPER_ADMIN` users have no company membership.

Current product behavior: at most **one active membership per user**. Company switching is not implemented. JWT does not carry a company object; the backend resolves the tenant from membership after authentication.

---

## 2. Company model

`apps.companies.models.Company`

| Field | Notes |
| --- | --- |
| `id` | UUID primary key |
| `name` | Required |
| `slug` | Unique, indexed with `is_active` |
| `email`, `phone`, `website`, `logo` | Optional. `logo` is a path/URL string (no ImageField) |
| `is_active` | Inactive companies deny normal company access |
| `created_at`, `updated_at` | From `TimeStampedModel` |

No HR-specific settings live on Company yet.

---

## 3. CompanyMembership model

`apps.companies.models.CompanyMembership`

| Field | Notes |
| --- | --- |
| `id` | UUID |
| `user` | FK to `accounts.User` |
| `company` | FK to `Company` |
| `role` | FK to `accounts.Role` (company-scoped only) |
| `is_active` | Inactive memberships grant no company access |
| timestamps | `created_at`, `updated_at` |

Constraints:

- Unique `(user, company)` — one membership row per pair.
- Partial unique: one **active** membership per user (`uniq_one_active_membership_per_user`).
- Indexes on `(user, is_active)` and `(company, is_active)`.
- Membership role must be `scope=COMPANY`. `SUPER_ADMIN` cannot be granted through membership.

Writes go through `MembershipService` (assign / deactivate). There is **no** public API to change role, join another company, or reactivate a membership. Django admin is a trusted operator surface.

---

## 4. Role model

`apps.accounts.models.Role`

| Field | Notes |
| --- | --- |
| `code` | Stable string (`SUPER_ADMIN`, `COMPANY_ADMIN`, `MANAGER`, `EMPLOYEE`) |
| `scope` | `PLATFORM` or `COMPANY` |
| `is_system_role` | System roles raise `ProtectedError` on delete |
| `permissions` | M2M to `Permission` |

Unique on `(code, scope)`. Never hardcode role IDs; use `code` + `scope`.

`User.role` remains a choices field for Django admin and users **without** membership. For company users, **membership.role.code** is authoritative (`User.resolve_role_code()`).

The generic `ADMIN` label is not used.

---

## 5. Permission model

`apps.accounts.models.Permission`

Application permissions, **not** Django `ContentType` / `auth.Permission`.

| Field | Notes |
| --- | --- |
| `code` | Unique stable code, e.g. `employees.view` |
| `name`, `description`, `module` | Human metadata |

Authorization checks `code` strings.

---

## 6. Role-permission relationship

`Role.permissions` is a many-to-many. Views check permission codes via `HasPermission("employees.view")`, not `if user.role == "ADMIN"`.

Default bindings are seeded by `python manage.py seed_rbac` (`apps.accounts.rbac_catalog`).

| Role | Default permissions |
| --- | --- |
| `COMPANY_ADMIN` | All company permission codes currently defined |
| `MANAGER` | `employees.view`, `employees.update`, `attendance.view`, `attendance.manage`, `leave.view`, `leave.approve`, `leave.reject`, `leave.manage`, `devices.view`, `devices.assign`, `devices.return`, `documents.view`, `documents.create`, `documents.update`, `documents.download`, `reports.view`. **Not** `settings.manage` or `documents.delete` |
| `EMPLOYEE` | `employees.view`, `attendance.view`, `attendance.check_in`, `attendance.check_out`, `leave.view`, `leave.create`, `devices.view`, `documents.view`, `documents.create`, `documents.download` |
| `SUPER_ADMIN` | Platform bypass in `TenantContext`. The role row has **no** company permission M2M rows |

`employees.view` on EMPLOYEE does **not** mean every employee row. Object-level rules further restrict private data.

---

## 7. Tenant context

`apps.common.tenancy.TenantContext` / `get_tenant_context(request)`

Resolved from `request.user` after JWT authentication:

1. Unauthenticated → empty context.
2. `User.is_platform_admin` (`role == SUPER_ADMIN` or `is_superuser`) → platform context, `company=None`.
3. Else active membership where `membership.is_active` and `company.is_active`.
4. Permission codes loaded from that membership’s role.

The client must **never** select a tenant with `company_id` / `tenant_id` in the body or query string. Those keys are ignored on writes. JWT claims are not the source of tenant authorization (tokens currently carry `user_id` only). If tenant claims are added later, they must still be checked against current membership.

Cached on `request.tenant` for the request lifetime.

---

## 8. Tenant isolation

Company-scoped ViewSets inherit `TenantAwareQuerySetMixin` (`apps.common.mixins`):

- `get_queryset()` filters to `company_id=current_company` (super admin sees all rows for platform operations).
- `perform_create()` sets `company` and `owner` from context, not from the payload.
- Cross-company object IDs that miss the queryset return **404** (no existence leak).
- Missing permission or no active membership returns **403**. Unauthenticated returns **401**.

Pattern for future HR ViewSets:

```python
class EmployeeViewSet(TenantAwareQuerySetMixin, ModelViewSet):
    queryset = Employee.objects.all()  # mixin restricts to the current company
    permission_classes = (IsAuthenticatedUser,)

    def get_permissions(self):
        return [IsAuthenticatedUser(), HasPermission("employees.view")()]
```

The mixin name is intentional: tenant filtering is visible on the class, not hidden in a global manager.

Reference CRUD for tests (not a product module): `GET/POST/PATCH/PUT/DELETE /api/v1/tenancy/records/`.

---

## 9. Object-level authorization

`apps.common.authorization.ObjectAuthorization`

| Question | Rule |
| --- | --- |
| Belongs to tenant? | `obj.company_id == ctx.company.id` (super admin: yes) |
| Can view? | Same tenant. `PRIVATE` rows: owner, or `COMPANY_ADMIN`, or manager **if** `TeamScope.is_in_team` |
| Can change? | Must be viewable. `COMPANY_ADMIN` / super admin: yes. Manager: own rows or team. Employee: own rows only |
| Filter queryset | Tenant + visibility (`COMPANY` or own `PRIVATE`) |

Models without a `visibility` field are tenant-filtered only.

---

## 10. Manager restrictions

`TeamScope.is_in_team` uses **direct reports** on `Employee.manager`: the actor’s employee row plus employees whose manager FK points at that row. There is no department-wide or transitive hierarchy.

Managers are **not** treated as having access to every colleague’s private records.

When richer org rules exist, extend `TeamScope` (assigned team, allowed departments). Do not grant managers `settings.manage` or unrestricted company administration.

---

## 11. Employee restrictions

Employees may hold `employees.view` but object-level rules limit `PRIVATE` rows to `owner_id == request.user.id`. Future `GET /employees/another-user` must 404/403 using the same helpers. Do not assume list permissions imply company-wide PII.

---

## 12. SUPER_ADMIN behavior

- Platform-level. `current_company` is `None`. `/me/` returns `"company": null` and `"role": "SUPER_ADMIN"`.
- Not assigned via `CompanyMembership`. `MembershipService.assign` rejects platform admins and platform roles.
- `TenantContext.has_permission` is True for platform operators (bypass). Company roles do not receive this bypass.
- Ordinary users cannot become `SUPER_ADMIN` through `/me/` (GET only) or membership APIs (none exposed).
- Query parameters such as `?role=SUPER_ADMIN` are ignored.
- Super admins may still reach tenant-owned rows for platform operations. They cannot **create** a tenant-owned record without a company context (`perform_create` requires `ctx.company`).

---

## 13. API permission classes

`apps.common.permissions`

| Class / factory | Meaning |
| --- | --- |
| `IsAuthenticatedUser` | 401 if anonymous |
| `IsSuperAdmin` | Platform operator |
| `IsCompanyMember` | Active membership in an active company |
| `IsCompanyAdmin` / `IsManager` / `IsEmployee` | Role code + company access |
| `HasPermission("code")` | One permission |
| `HasAnyPermission(...)` / `HasAllPermissions(...)` | Combinators |

Example:

```python
permission_classes = [IsAuthenticatedUser, HasPermission("employees.view")]
```

`HasPermission("settings.manage")` in a class body returns a DRF permission **class**.

---

## 14. Cross-company security

**Incorrect (must fail):**

- `GET /api/v1/tenancy/records/<company-b-uuid>/` as a Company A user → **404**
- `PATCH` / `PUT` / `DELETE` the same ID → **404**; row unchanged
- `POST` with `"company_id": "<company-b>"` → object still belongs to Company A
- `assigned_to` a user who belongs to Company B → **400**
- Inactive membership or inactive company → **403** on company resources

**Correct:**

- Company A admin lists only Company A rows
- Tenant from `get_tenant_context(request)`, never `request.data["company_id"]`

---

## 15. Database constraints

| Constraint | Purpose |
| --- | --- |
| `Permission.code` unique | Stable codes |
| `uniq_role_code_scope` | Role code unique per scope |
| `uniq_membership_user_company` | One membership row per user+company |
| `uniq_one_active_membership_per_user` | One active tenant at a time (PostgreSQL partial unique index) |
| Role FK `PROTECT` on membership | Cannot delete a role still in use |
| System role `delete()` | `ProtectedError` |

Serializer validation is extra; uniqueness is enforced in the database.

---

## 16. Migration strategy

Existing `accounts.0001_initial` (custom `User`, no `company` FK) is kept. No database reset, no dropped user tables.

Forward migrations:

1. `accounts` — `Role`, `Permission`, M2M `Role.permissions` (User.role help_text only if generated).
2. `companies` — `Company`, `CompanyMembership`, `TenantOwnedRecord` (depends on accounts Role).

Existing users keep their rows. They have no membership until assigned. `/me/` then returns `"company": null`.

After migrate: `python manage.py seed_rbac` (idempotent).

---

## 17. Future employee / team authorization

When `Employee` exists:

1. Inherit timestamps; add `company` FK; **never** take company from the client on create.
2. Use `TenantAwareQuerySetMixin` + `HasPermission("employees.*")`.
3. Implement `TeamScope` using reporting/department fields.
4. Map “own profile” to `owner` / `user` on the employee row and `ObjectAuthorization.can_view`.
5. Validate related FKs with `ObjectAuthorization.assert_same_tenant`.

Do not add a second company FK on `User`.

---

## 18. Security testing strategy

Tests live under `apps.companies.tests` and `apps.accounts.tests.test_seed_rbac`.

Fixtures: Company A / B, admin/manager/employee on each, plus `SUPER_ADMIN`, a user with no membership, and an inactive company.

Covered:

- Isolation: GET/POST/PATCH/PUT/DELETE and list leakage
- IDOR by UUID
- Payload cannot override tenant; cross-company `assigned_to` rejected
- Permission matrix and DRF `HasPermission` / any / all
- Inactive membership and inactive company
- COMPANY_ADMIN cannot hit platform routes; query-param impersonation fails
- `/me/` company context; PATCH `/me/` is 405 (no self-escalation)
- `seed_rbac` twice: no duplicates; custom roles/permissions survive

---

## Soft delete (future)

No soft-delete framework yet. Isolation already excludes other tenants and inactive memberships/companies. When soft delete is added, default managers must exclude deleted rows so inactive records cannot leak across tenants. Prefer a `deleted_at` filter on tenant querysets rather than exposing deleted IDs as 403 (which can confirm existence).

---

## Audit-ready writes (future)

Do not log full audit events yet. Route membership and role changes through `MembershipService` (and later a permission-admin service) so events can be recorded:

- User added to / removed from a company
- Role changed
- Company suspended (`is_active=False`)
- Permission set on a role changed

---

## Seed command

```bash
python manage.py seed_rbac
```

Creates/updates default roles, permissions, and bindings. Safe to run repeatedly. Does not delete custom (non-catalog) roles or permissions. Re-running **does** reset system role permission M2M sets to the catalog (including clearing `SUPER_ADMIN` company permissions).
