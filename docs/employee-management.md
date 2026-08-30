# Employee management

Company-scoped Employee, Department, and Position APIs. Identity, membership, and RBAC are unchanged; this module consumes them. See [`docs/multi-tenancy-and-rbac.md`](multi-tenancy-and-rbac.md).

Base path: `/api/v1/`. JWT required except where noted.

---

## 1. Employee model

`apps.employees.models.Employee` — UUID primary key.

| Field | Notes |
| --- | --- |
| `company` | Set from tenant context. Never from the client. |
| `user` | Optional FK to `accounts.User`. `SET_NULL` on user delete. No password, no duplicate email. |
| `employee_code` | Unique **per company** |
| `first_name`, `last_name` | Required |
| `profile_image` | Optional path/URL string |
| `gender` | `MALE`, `FEMALE`, `OTHER`, `PREFER_NOT_TO_SAY` |
| `date_of_birth`, `phone`, `address`, emergency contact fields | Private (see §10) |
| `department`, `position`, `manager` | Optional, same company |
| `joining_date` | Optional |
| `employment_type` | `FULL_TIME`, `PART_TIME`, `CONTRACT`, `INTERN`, `TEMPORARY` |
| `status` | `ACTIVE`, `INACTIVE`, `ON_LEAVE`, `TERMINATED` |
| timestamps | `created_at`, `updated_at` |

An Employee may exist **without** a User (HR record before login). Linking a User does not create accounts. The linked user must already have an active `CompanyMembership` in the same company.

`status` is not changed automatically by other modules.

---

## 2. Department model

UUID PK. Fields: `company`, `name`, `description`, `manager` (Employee, `SET_NULL`), `status` (`ACTIVE` / `INACTIVE`), timestamps.

`name` is unique per company. Manager must be an employee of the same company.

---

## 3. Position model

UUID PK. Fields: `company`, `department`, `title`, `description`, `status`, timestamps.

`title` is unique per `(company, department)`. Department must belong to the same company. Deleting a department that still has positions is **rejected** (`PROTECT` → HTTP 409).

---

## 4. Relationships

```
Company
  ├── Department.manager → Employee
  ├── Position.department → Department
  └── Employee
        ├── user → User (membership is the tenant authority)
        ├── department → Department (SET_NULL)
        ├── position → Position (SET_NULL)
        └── manager → Employee (SET_NULL, not self)
```

Company FKs use `CASCADE` (tenant data belongs to the company). Employee deletion does **not** cascade to User, Department, Position, or Company.

---

## 5. Company ownership

On create, `company = request.user`’s active membership company. Body keys `company`, `company_id`, `tenant_id`, `membership_id` are ignored. Company is immutable through these APIs. SUPER_ADMIN has no company context and cannot create tenant rows here.

---

## 6. Tenant isolation

`TenantAwareQuerySetMixin` filters by `current_company`. Cross-company IDs return **404**. Unauthenticated **401**. Missing permission / inactive membership **403**.

---

## 7. Employee permissions

| Action | Permission |
| --- | --- |
| List, retrieve, `GET /employees/me/` | `employees.view` |
| Create | `employees.create` |
| Update | `employees.update` |
| Delete | `employees.delete` |

Department/position **reads** use `employees.view`. **Writes** use `settings.manage` so a manager cannot rename the org chart with `employees.update`.

Do not branch on `role == COMPANY_ADMIN` in views.

---

## 8. Manager authorization

A manager’s employee visibility is **not** company-wide.

Interim policy (no department-wide or transitive tree):

- Their own Employee row (`Employee.user == request.user`)
- Direct reports (`Employee.manager` points at that row)

They may `PATCH` those rows (`employees.update`). They cannot create or delete employees, cannot see `emp_a2` if that person does not report to them, and cannot access another company.

`TeamScope.is_in_team` uses the same direct-report rule for other private tenant objects.

---

## 9. Employee self-access

`GET /api/v1/employees/me/` resolves `Employee` for `request.user` in the current company. No ID is accepted. List for the EMPLOYEE role returns only that row. They cannot view/update/delete others. They do not have `employees.update` / `employees.delete`, so they cannot PATCH even their own row through this API.

---

## 10. Private fields

List responses omit: `date_of_birth`, `phone`, `address`, `emergency_contact_*`.

Detail / `/me/` include them only for rows the actor can retrieve (company admin: all in tenant; manager: self + reports; employee: self).

---

## 11. Search

`?search=` on employees: `employee_code`, `first_name`, `last_name`, `phone`, `user__email`. Runs on the tenant-filtered queryset.

---

## 12. Filtering

Employees: `department`, `position`, `status`, `employment_type`, `manager` (UUIDs).

Departments: `status`. Positions: `department`, `status`.

Filters cannot escape the tenant queryset.

---

## 13. Pagination

Global `StandardPagination` (`count` / `next` / `previous` / `results` inside `data`). `page_size` up to 100.

---

## 14. Ordering

Employees: `first_name`, `last_name`, `joining_date`, `created_at`, `employee_code`.

Departments: `name`, `created_at`. Positions: `title`, `created_at`.

Unknown `ordering` fields are ignored by DRF’s OrderingFilter.

---

## 15. Delete strategy

Hard delete on Employee. Prefer setting `status=TERMINATED` for historical HR data; DELETE is available to company admins. Related User/Department/Position remain. Department delete is blocked while positions exist.

---

## 16. Security considerations

- Never trust `company_id`, `user_id`, `department_id`, `position_id`, `manager_id` without same-company checks.
- User link must match active membership.
- Position must match the employee’s department when both are set.
- Self-manager and one-level cycles are rejected.
- Frontend filtering is not security.

---

## 17. API examples

```http
GET /api/v1/employees/
Authorization: Bearer <access>
```

```http
GET /api/v1/employees/me/
```

```http
POST /api/v1/employees/
{
  "employee_code": "EMP-010",
  "first_name": "Ada",
  "last_name": "Lovelace",
  "user": 42,
  "department": "<uuid>",
  "position": "<uuid>",
  "employment_type": "FULL_TIME",
  "status": "ACTIVE"
}
```

`company_id` in that body is ignored.

```http
GET /api/v1/departments/
GET /api/v1/positions/?department=<uuid>&ordering=title
```

OpenAPI: `/api/schema/` and `/api/docs/` (tags Employees, Departments, Positions).
